"""Tests for plans.py. Run: python -m unittest discover -s <skill-dir>/scripts"""
from __future__ import annotations

import contextlib
import io
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import plans  # noqa: E402

THREAD = "01a1293e-ecd5-72e0-adb3-8b5a6c532c3b"
OTHER_THREAD = "01a12963-6935-7062-8f3f-d80d85ea716f"


class PlansTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name) / "plans"
        env = {k: v for k, v in os.environ.items() if k not in ("CODEX_THREAD_ID", "CODEX_PLANS_ROOT")}
        patcher = mock.patch.dict(os.environ, env, clear=True)
        patcher.start()
        self.addCleanup(patcher.stop)

    def tearDown(self):
        self.tmp.cleanup()

    def run_cli(self, *args: str) -> tuple[int, str, str]:
        out, err = io.StringIO(), io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = plans.main(["--root", str(self.root), *args])
        return code, out.getvalue().strip(), err.getvalue()

    def new(self, *args: str) -> Path:
        code, out, err = self.run_cli("new", "--repo", self.tmp.name, *args)
        self.assertEqual(code, 0, err)
        return Path(out.splitlines()[-1])

    def fields(self, path: Path) -> dict[str, str]:
        fm_lines, _ = plans.split_frontmatter(path.read_text(encoding="utf-8"))
        return plans.read_fields(fm_lines)

    def test_new_names_file_with_thread_suffix_and_indexes_it(self):
        path = self.new("--title", "Build: café plan | test", "--thread-id", THREAD.upper())
        self.assertRegex(path.name, r"^\d{4}-\d{2}-\d{2}-")
        self.assertTrue(path.stem.endswith("-build-cafe-plan-test--6c532c3b"))
        f = self.fields(path)
        self.assertEqual(f["title"], "Build: café plan | test")
        self.assertEqual(f["thread_id"], THREAD)
        self.assertEqual(f["status"], "draft")
        index = (self.root / "INDEX.md").read_text(encoding="utf-8")
        self.assertIn(THREAD, index)
        self.assertIn("café plan \\| test", index)

    def test_new_without_thread_warns_and_omits_suffix(self):
        code, out, err = self.run_cli("new", "--title", "No thread")
        self.assertEqual(code, 0)
        self.assertIn("thread ID unknown", err)
        self.assertTrue(Path(out).stem.endswith("-no-thread"))
        self.assertEqual(self.fields(Path(out))["thread_id"], "")

    def test_env_thread_id_used_and_invalid_env_ignored(self):
        with mock.patch.dict(os.environ, {"CODEX_THREAD_ID": OTHER_THREAD}):
            self.assertEqual(self.fields(self.new("--title", "Env"))["thread_id"], OTHER_THREAD)
        with mock.patch.dict(os.environ, {"CODEX_THREAD_ID": "junk"}):
            code, out, err = self.run_cli("new", "--title", "Env bad")
        self.assertEqual(code, 0)
        self.assertIn("ignoring CODEX_THREAD_ID", err)

    def test_duplicate_open_plan_for_thread_is_refused(self):
        first = self.new("--title", "One", "--thread-id", THREAD)
        code, out, err = self.run_cli("new", "--title", "Two", "--thread-id", THREAD)
        self.assertEqual(code, 2)
        self.assertEqual(out, str(first))
        self.new("--title", "Two", "--thread-id", THREAD, "--force-new")
        self.run_cli("set", first.stem, "--status", "done")
        self.new("--title", "Three", "--thread-id", THREAD, "--force-new")

    def test_same_title_same_day_gets_numeric_suffix(self):
        a = self.new("--title", "Same")
        b = self.new("--title", "Same")
        self.assertEqual(b.stem, a.stem + "-2")

    def test_invalid_thread_id_rejected(self):
        code, _, err = self.run_cli("new", "--title", "x", "--thread-id", "nope")
        self.assertEqual(code, 2)
        self.assertIn("not a valid thread ID", err)

    def test_set_changes_frontmatter_only(self):
        path = self.new("--title", "Body test")
        raw = path.read_bytes()
        body = raw[raw.index(b"\n---", 3) + 5:] + b"\nCodex notes.\r\n"
        path.write_bytes(raw[: raw.index(b"\n---", 3) + 5] + body)
        code, _, err = self.run_cli("set", path.stem, "--status", "in-progress", "--thread-id", THREAD)
        self.assertEqual(code, 0, err)
        after = path.read_bytes()
        self.assertEqual(after[after.index(b"\n---", 3) + 5:], body)
        f = self.fields(path)
        self.assertEqual((f["status"], f["thread_id"]), ("in-progress", THREAD))

    def test_set_errors(self):
        path = self.new("--title", "x")
        self.assertEqual(self.run_cli("set", path.stem)[0], 2)
        self.assertEqual(self.run_cli("set", "missing", "--status", "done")[0], 1)
        self.assertEqual(self.run_cli("set", path.stem, "--supersedes", "missing")[0], 1)

    def test_find_filters(self):
        a = self.new("--title", "Alpha plan", "--thread-id", THREAD)
        self.new("--title", "Beta plan")
        self.run_cli("set", a.stem, "--status", "approved")
        code, out, _ = self.run_cli("find", "--thread-id", "6c532c")
        self.assertEqual((code, out.split("\t")[0]), (0, a.stem))
        self.assertEqual(len(self.run_cli("find", "PLAN")[1].splitlines()), 2)
        self.assertEqual(self.run_cli("find", "--status", "approved")[1].split("\t")[0], a.stem)
        self.assertEqual(self.run_cli("find", "zzz")[0], 1)

    def test_index_lists_unreadable_files(self):
        self.new("--title", "Good")
        self.root.joinpath("broken.md").write_text("no frontmatter\n", encoding="utf-8")
        self.root.joinpath("partial.md").write_text("---\ntitle: x\n---\n", encoding="utf-8")
        self.assertEqual(self.run_cli("index")[0], 0)
        index = (self.root / "INDEX.md").read_text(encoding="utf-8")
        self.assertIn("`broken.md`: no frontmatter", index)
        self.assertIn("`partial.md`: missing plan_id, status", index)

    def test_repo_label_uses_parent_of_worktree(self):
        base = Path(self.tmp.name)
        self.assertEqual(plans.repo_label(str(base / "app-repo" / ".worktrees" / "feature")), "app-repo")
        self.assertEqual(plans.repo_label(str(base / "docs-repo")), "docs-repo")

    def test_root_comes_from_env_when_no_root_flag(self):
        env_root = Path(self.tmp.name) / "env-plans"
        with mock.patch.dict(os.environ, {"CODEX_PLANS_ROOT": str(env_root)}):
            self.assertEqual(plans.default_root(), env_root)
            out = io.StringIO()
            with contextlib.redirect_stdout(out), contextlib.redirect_stderr(io.StringIO()):
                code = plans.main(["new", "--title", "Env root", "--repo", self.tmp.name])
        self.assertEqual(code, 0)
        self.assertEqual(Path(out.getvalue().strip()).parent, env_root)

    def test_root_falls_back_to_home_codex_plans(self):
        self.assertEqual(plans.default_root(), Path.home() / ".codex" / "plans")

    def test_name_clash_during_create_exits_2(self):
        first = self.new("--title", "Clash")
        with mock.patch.object(plans.Path, "exists", return_value=False):
            code, _, err = self.run_cli("new", "--title", "Clash", "--repo", self.tmp.name)
        self.assertEqual(code, 2)
        self.assertIn(f"{first.name} was created by another process", err)


if __name__ == "__main__":
    unittest.main()
