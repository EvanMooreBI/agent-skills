"""Exercise the actual builder and extracted bundle with isolated source fixtures."""

import copy
import hashlib
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path


TOOLS = Path(__file__).resolve().parents[1]
SOURCE = TOOLS.parent
sys.path.insert(0, str(TOOLS))
import build_career_bundle as builder


def fixture_source(relative):
    public = SOURCE / relative
    if public.is_file():
        return public
    # Development scaffold has no maintained second copy of canonical skills.
    prefix = "plugins/job-search/skills/"
    if relative.startswith(prefix):
        return SOURCE.parents[1] / "skills/job-finding" / relative[len(prefix):]
    return public


class PackageTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="job-pack-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.manifest = json.loads((SOURCE / "plugins/job-search/bundle.json").read_text(encoding="utf-8"))
        paths = ["plugins/job-search/bundle.json", "LICENSE"]
        paths += [f"plugins/job-search/{x}" for x in self.manifest["assets"]]
        paths += [f"plugins/job-search/skills/{item['name']}/{x}" for item in self.manifest["skills"] for x in item["files"]]
        for relative in paths:
            destination = self.root / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(fixture_source(relative), destination)

    def change_manifest(self, change):
        manifest = copy.deepcopy(self.manifest)
        change(manifest)
        (self.root / "plugins/job-search/bundle.json").write_text(json.dumps(manifest), encoding="utf-8")

    def test_archive_exact_contents_hashes_and_reproducibility(self):
        one = builder.build(self.root, self.root / "one.zip")
        two = builder.build(self.root, self.root / "two.zip")
        self.assertEqual(one.read_bytes(), two.read_bytes())
        with zipfile.ZipFile(one) as archive:
            self.assertIsNone(archive.testzip())
            self.assertTrue(all(x.compress_type == zipfile.ZIP_STORED for x in archive.infolist()))
            manifest = json.loads(archive.read("career-workbench/manifest.json"))
            expected = {f"career-workbench/{name}" for name in manifest["files"]} | {"career-workbench/manifest.json"}
            self.assertEqual(set(archive.namelist()), expected)
            for path, digest in manifest["files"].items():
                self.assertEqual(hashlib.sha256(archive.read(f"career-workbench/{path}")).hexdigest(), digest)
            self.assertEqual({x["name"] for x in manifest["skills"]}, builder.SKILLS)
            self.assertNotIn(b"../../LICENSE", archive.read("career-workbench/README.md"))
            self.assertNotIn(b"evals/cases.md", archive.read("career-workbench/README.md"))

    def test_extracted_repo_local_install_keeps_sibling_dependencies(self):
        archive = builder.build(self.root)
        with zipfile.ZipFile(archive) as bundle:
            bundle.extractall(self.root / "extracted")
        package = self.root / "extracted/career-workbench"
        for host in (".agents", ".claude"):
            destination = self.root / "recipient" / host / "skills"
            shutil.copytree(package / "skills", destination)
            exported = {f"skills/{p.relative_to(destination).as_posix()}": p.read_bytes() for p in destination.rglob("*") if p.is_file()}
            builder.validate_links(exported)
            for name in builder.SKILLS:
                self.assertTrue((destination / name / "SKILL.md").is_file())
            self.assertFalse((destination.parent / "agents").exists())

    def test_unlisted_personal_files_and_agents_are_not_collected(self):
        for relative in (".job-search.local/home-address.md", "agents/claude/custom.md", "plugins/job-search/skills/resume-tailor/private.md"):
            p = self.root / relative
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text("PRIVATE FIXTURE", encoding="utf-8")
        files = builder.collect(self.root)
        self.assertFalse(any(b"PRIVATE FIXTURE" in data for data in files.values()))

    def test_missing_dependency_and_missing_skill_are_refused(self):
        self.change_manifest(lambda m: m["skills"][0]["requires"].append("unavailable-skill"))
        with self.assertRaisesRegex(ValueError, "Missing or invalid dependency"):
            builder.collect(self.root)
        self.change_manifest(lambda m: m["skills"].pop())
        with self.assertRaisesRegex(ValueError, "exactly the 23"):
            builder.collect(self.root)

    def test_traversal_export_is_refused(self):
        self.change_manifest(lambda m: m["skills"][0]["files"].append("../private.md"))
        with self.assertRaisesRegex(ValueError, "escapes its root"):
            builder.collect(self.root)

    def test_absolute_paths_and_aliases_are_refused(self):
        for path in ("C:/private.md", "/private.md", "a/./b.md", "a//b.md"):
            with self.subTest(path=path), self.assertRaises(ValueError):
                builder.safe_source(self.root, path)

    def test_missing_relative_link_is_refused(self):
        p = self.root / "plugins/job-search/skills/resume-tailor/SKILL.md"
        with p.open("a", encoding="utf-8") as file:
            file.write("\nRead [missing](../missing/reference.md).\n")
        with self.assertRaisesRegex(ValueError, "Missing exported link"):
            builder.collect(self.root)

    def test_missing_heading_anchor_is_refused(self):
        files = {"a.md": b"[link](b.md#missing)", "b.md": b"# Present"}
        with self.assertRaisesRegex(ValueError, "Missing exported anchor"):
            builder.validate_links(files)

    def test_linked_ancestor_is_refused(self):
        original = self.root / "plugins/job-search/skills/resume-tailor"
        moved = self.root / "outside"
        original.rename(moved)
        try:
            original.symlink_to(moved, target_is_directory=True)
        except OSError as exc:
            self.skipTest(f"Host cannot create a test symlink: {exc}")
        with self.assertRaisesRegex(ValueError, "Linked export source"):
            builder.collect(self.root)

    def test_custom_runner_frontmatter_is_refused(self):
        p = self.root / "plugins/job-search/skills/job-market-pay-research/SKILL.md"
        text = p.read_text(encoding="utf-8").replace("---\n", "---\nagent: custom-runner\n", 1)
        p.write_text(text, encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Invalid portable skill"):
            builder.collect(self.root)

    @unittest.skipUnless(os.name == "nt", "Windows junction behavior")
    def test_windows_junction_ancestor_is_refused(self):
        original = self.root / "plugins/job-search/skills/resume-tailor"
        moved = self.root / "outside"
        original.rename(moved)
        subprocess.run(["cmd", "/c", "mklink", "/J", str(original), str(moved)], capture_output=True, check=True)
        with self.assertRaisesRegex(ValueError, "Linked export source"):
            builder.collect(self.root)

    def test_private_path_leak_is_refused_but_public_urls_are_allowed(self):
        self.assertIsNone(builder.PRIVATE.search("https://example.org/api/jobs"))
        p = self.root / "plugins/job-search/skills/resume-tailor/SKILL.md"
        with p.open("a", encoding="utf-8") as file:
            file.write("\nRead C:/Users/private/profile.md\n")
        with self.assertRaisesRegex(ValueError, "Private path"):
            builder.collect(self.root)

    def test_populated_address_template_is_refused(self):
        p = self.root / "plugins/job-search/skills/job-posting-review/references/templates/home-address.md"
        p.write_text(p.read_text(encoding="utf-8").replace("Home address:", "Home address: PRIVATE FIXTURE"), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "populated blank template"):
            builder.collect(self.root)

    def test_unbundled_named_skill_reference_is_refused(self):
        p = self.root / "plugins/job-search/skills/resume-tailor/SKILL.md"
        with p.open("a", encoding="utf-8") as file:
            file.write("\nUse the `unbundled-skill` skill.\n")
        with self.assertRaisesRegex(ValueError, "Undeclared skill dependency"):
            builder.collect(self.root)


    def test_stale_archive_is_refused_and_regeneration_matches(self):
        builder.build(self.root)
        builder.build(self.root, check=True)
        p = self.root / "plugins/job-search/skills/resume-tailor/SKILL.md"
        p.write_text(p.read_text(encoding="utf-8") + "\nClarified supported wording.\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "stale"):
            builder.build(self.root, check=True)
        builder.build(self.root)
        builder.build(self.root, check=True)

    def test_missing_archive_is_refused_without_creating_it(self):
        with self.assertRaisesRegex(ValueError, "Missing export source"):
            builder.build(self.root, check=True)
        self.assertFalse((self.root / builder.ARCHIVE).exists())

    def test_every_exported_skill_change_requires_regeneration(self):
        builder.build(self.root)
        for name in builder.SKILLS:
            with self.subTest(skill=name):
                p = self.root / f"plugins/job-search/skills/{name}/SKILL.md"
                original = p.read_bytes()
                p.write_bytes(original + b"\nUpdated supported guidance.\n")
                try:
                    with self.assertRaisesRegex(ValueError, "stale"):
                        builder.build(self.root, check=True)
                finally:
                    p.write_bytes(original)

    def test_archive_output_cannot_escape_public_root(self):
        with self.assertRaisesRegex(ValueError, "stay inside"):
            builder.build(self.root, self.root / "../escaped.zip")

    def test_linked_archive_output_is_refused(self):
        outside = self.root / "outside-output"
        outside.mkdir()
        link = self.root / "bundles"
        try:
            link.symlink_to(outside, target_is_directory=True)
        except OSError as exc:
            self.skipTest(f"Host cannot create a test symlink: {exc}")
        with self.assertRaisesRegex(ValueError, "Linked archive output"):
            builder.build(self.root)
        self.assertEqual(list(outside.iterdir()), [])

    def test_missing_attribution_is_refused(self):
        self.change_manifest(lambda m: next(x for x in m["skills"] if x["name"] == "resume-tailor")["files"].remove("NOTICE.md"))
        with self.assertRaisesRegex(ValueError, "Missing upstream attribution"):
            builder.collect(self.root)

    def test_changed_upstream_license_is_refused(self):
        p = self.root / "plugins/job-search/skills/resume-tailor/LICENSES/ResumeSkills-MIT.txt"
        p.write_text("MIT without required notice", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Changed upstream license"):
            builder.collect(self.root)

    def test_newline_normalization_is_platform_independent(self):
        before = builder.archive_bytes(self.root)
        p = self.root / "plugins/job-search/skills/resume-tailor/SKILL.md"
        normalized = p.read_bytes().replace(b"\r\n", b"\n")
        for newline in (b"\n", b"\r\n"):
            p.write_bytes(normalized.replace(b"\n", newline))
            self.assertEqual(before, builder.archive_bytes(self.root))

    def test_undeclared_dependency_is_refused(self):
        self.change_manifest(lambda m: next(x for x in m["skills"] if x["name"] == "resume-tailor")["requires"].remove("job-description-analyzer"))
        with self.assertRaisesRegex(ValueError, "Undeclared skill dependency"):
            builder.collect(self.root)

    def test_extra_plugin_skill_is_refused(self):
        p = self.root / "plugins/job-search/skills/unlisted/SKILL.md"
        p.parent.mkdir()
        p.write_text("unlisted", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "skill set differs"):
            builder.collect(self.root)

    def test_populated_context_template_is_refused(self):
        p = self.root / "plugins/job-search/skills/career-context-builder/references/templates/skills-inventory.md"
        p.write_text(p.read_text(encoding="utf-8") + "\nPRIVATE FILLED CLAIM\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "populated blank template"):
            builder.collect(self.root)


    def test_archive_exception_does_not_allow_other_zips(self):
        import validate_repo
        builder.build(self.root)
        (self.root / "other.zip").write_bytes(b"unapproved")
        findings = []
        validate_repo.check_files(self.root, lambda p: p.relative_to(self.root).as_posix(), findings, {}, [])
        archive_findings = [x for x in findings if "file type .zip" in x]
        self.assertEqual(len(archive_findings), 1, findings)
        self.assertIn("other.zip", archive_findings[0])


if __name__ == "__main__":
    unittest.main()
