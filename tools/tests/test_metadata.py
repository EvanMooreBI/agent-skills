"""Standalone release-validator regressions; also run in the published layout."""

import importlib.util
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
SPEC = importlib.util.spec_from_file_location("release_validator", TOOLS / "validate_repo.py")
validator = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(validator)


class ReleaseMetadataTests(unittest.TestCase):
    def validate(self, fields, target="repo"):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "sample-skill"
            root.mkdir()
            (root / "SKILL.md").write_text(f"---\nname: sample-skill\n{fields}\n---\nVerify output.\n", encoding="utf-8")
            findings = []
            validator.check_skill(root, lambda p: p.name, findings, target)
            return findings

    def test_folded_description_is_validated_as_its_actual_value(self):
        for size in [500, 501, 1024, 1025]:
            fields = "description: >-\n  " + "A" * size + "\nlicense: MIT\nmetadata:\n  version: '1.0'"
            self.assertEqual(size > 1024, bool(self.validate(fields)))

    def test_invalid_yaml_types_and_duplicates_fail(self):
        for value in ["true", "[]", "bad: yaml", "First\ndescription: Second"]:
            self.assertTrue(self.validate(f"description: {value}\nlicense: MIT\nmetadata:\n  version: '1.0'"))

    def test_public_release_requirements_are_preserved(self):
        self.assertTrue(self.validate("description: Valid\nlicense: Apache-2.0\nmetadata:\n  version: '1.0'"))
        self.assertTrue(self.validate("description: Valid\nlicense: MIT\nmetadata: {}"))
        self.assertFalse(self.validate("description: Valid\nlicense: MIT\nmetadata:\n  version: '1.0'"))

    def test_code_plugin_extensions_are_not_silently_removed(self):
        fields = "description: Valid\nlicense: MIT\nmetadata:\n  version: '1.0'\ncontext: fork"
        self.assertFalse(self.validate(fields))
        self.assertTrue(self.validate(fields, "portable"))

    def test_relative_and_file_restrictions_remain_active(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            doc = root / "README.md"
            doc.write_text("[Missing](missing.md)", encoding="utf-8")
            findings = []
            validator.check_links(doc, doc.read_text(encoding="utf-8"), root, lambda p: p.name, findings)
            self.assertTrue(any("broken link" in item for item in findings), findings)


@unittest.skipUnless(shutil.which("pwsh"), "PowerShell required for ZIP builder integration")
class UploadBuilderTests(unittest.TestCase):
    def test_target_validation_precedes_archive_creation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "release"
            shutil.copytree(TOOLS, root / "tools", ignore=shutil.ignore_patterns("__pycache__"))
            (root / "scripts").mkdir()
            builder = root / "scripts/Build-SkillZips.ps1"
            shutil.copy2(TOOLS.parent / "scripts/Build-SkillZips.ps1", builder)
            (root / ".claude-plugin").mkdir()
            (root / ".claude-plugin/marketplace.json").write_text(json.dumps({
                "name": "fixture", "owner": {"name": "Fixture"},
                "plugins": [{"name": "sample", "source": "./plugins/sample"}],
            }), encoding="utf-8")
            plugin = root / "plugins/sample"
            (plugin / ".claude-plugin").mkdir(parents=True)
            (plugin / ".claude-plugin/plugin.json").write_text('{"name":"sample"}', encoding="utf-8")
            skill = plugin / "skills/sample-skill"
            skill.mkdir(parents=True)
            skill_md = skill / "SKILL.md"
            portable = "---\nname: sample-skill\ndescription: Valid fixture\nlicense: MIT\nmetadata:\n  version: '1.0'\n---\nVerify output.\n"
            skill_md.write_text(portable.replace("license: MIT", "effort: medium\nlicense: MIT"), encoding="utf-8")

            def build(target, output):
                return subprocess.run([
                    shutil.which("pwsh"), "-NoProfile", "-File", str(builder),
                    "-Target", target, "-OutputPath", str(output),
                ], capture_output=True, text=True, timeout=30)

            rejected = root / "dist/rejected"
            run = build("portable", rejected)
            self.assertNotEqual(run.returncode, 0, run.stdout + run.stderr)
            self.assertFalse(rejected.exists())
            repo_output = root / "dist/repo"
            run = build("repo", repo_output)
            self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
            with zipfile.ZipFile(repo_output / "sample-skill.zip") as archive:
                self.assertIn(b"effort: medium", archive.read("sample-skill/SKILL.md"))
            skill_md.write_text(portable, encoding="utf-8")
            accepted = root / "dist/portable"
            run = build("portable", accepted)
            self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
            self.assertTrue((accepted / "sample-skill.zip").is_file())


if __name__ == "__main__":
    unittest.main()
