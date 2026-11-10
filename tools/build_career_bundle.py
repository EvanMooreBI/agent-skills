#!/usr/bin/env python3
"""Build/check Career Workbench from the staged public tree, never Dev Center paths."""

import argparse
import hashlib
import io
import json
import posixpath
import re
import stat
import tempfile
import zipfile
from pathlib import Path, PurePosixPath
from urllib.parse import unquote, urlsplit

from skill_frontmatter import parse_skill, validate_fields


ROOT = Path(__file__).resolve().parents[1]
PLUGIN = "plugins/job-search"
ARCHIVE = "bundles/career-workbench.zip"
SKILLS = frozenset({
    "application-form-filler", "career-changer-translator", "career-context-builder",
    "cold-email-writer", "cover-letter-generator", "creative-portfolio-resume",
    "interview-prep-generator", "job-description-analyzer", "job-market-pay-research",
    "job-posting-review", "linkedin-profile-optimizer", "offer-comparison-analyzer",
    "portfolio-case-study-writer", "reference-list-builder", "resume-ats-optimizer",
    "resume-bullet-writer", "resume-formatter", "resume-quantifier", "resume-section-builder",
    "resume-tailor", "resume-version-manager", "salary-negotiation-prep", "tech-resume-optimizer",
})
PRIVATE = re.compile(r"(?<![A-Za-z])[A-Za-z]:[\\/]|/Users/|/home/[^/]+/|skill-runner-(?:haiku|sonnet)|\bScreenr\b")


def safe_source(root, relative):
    """Refuse aliases, traversal, links and Windows junction ancestors."""
    if not isinstance(relative, str) or "\\" in relative or ":" in relative:
        raise ValueError(f"Invalid export path: {relative!r}")
    parts = PurePosixPath(relative)
    if parts.is_absolute() or not parts.parts or ".." in parts.parts or str(parts) != relative:
        raise ValueError(f"Export path escapes its root: {relative}")
    current = root
    for part in parts.parts:
        current = current / part
        try:
            attributes = current.lstat()
        except FileNotFoundError as exc:
            raise ValueError(f"Missing export source: {relative}") from exc
        reparse = getattr(attributes, "st_file_attributes", 0) & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0)
        if current.is_symlink() or reparse:
            raise ValueError(f"Linked export source refused: {relative}")
    if not current.is_file():
        raise ValueError(f"Missing export source: {relative}")
    return current


def prose(text):
    text = re.sub(r"^```.*?^```[^\n]*$", "", text, flags=re.M | re.S)
    return re.sub(r"`[^`\n]+`", "", text)


def anchor(heading):
    return re.sub(r"\s", "-", re.sub(r"[^\w\-\s]", "", heading.lower().strip()))


def validate_links(files):
    """Resolve links in the extracted namespace, including headings."""
    for name, data in files.items():
        if not name.endswith(".md"):
            continue
        for target in re.findall(r"\[[^\]\n]*\]\(([^)\n]+)\)", prose(data.decode("utf-8"))):
            url = urlsplit(target)
            if url.scheme in {"http", "https", "mailto"}:
                continue
            if url.scheme or url.netloc or url.path.startswith("/") or "\\" in target:
                raise ValueError(f"Nonportable link in {name}: {target}")
            resolved = posixpath.normpath(posixpath.join(posixpath.dirname(name), unquote(url.path))) if url.path else name
            if resolved not in files:
                raise ValueError(f"Missing exported link in {name}: {target}")
            if url.fragment:
                headings = re.findall(r"^#{1,6}\s+(.+)$", files[resolved].decode("utf-8"), re.M)
                if unquote(url.fragment) not in {anchor(h) for h in headings}:
                    raise ValueError(f"Missing exported anchor in {name}: {target}")


def collect(root):
    root = Path(root).resolve()
    manifest = json.loads(safe_source(root, f"{PLUGIN}/bundle.json").read_text(encoding="utf-8"))
    entries = manifest["skills"]
    names = [item["name"] for item in entries]
    if manifest["schemaVersion"] != 1 or manifest["name"] != "career-workbench" or set(names) != SKILLS or len(names) != len(SKILLS):
        raise ValueError("Manifest must declare exactly the 23 Career Workbench skills")
    if manifest["assets"] != ["README.md", "START-HERE.md", "NOTICE.md", "provenance.json"]:
        raise ValueError("Only reviewed guide, start prompt, notices and provenance may be exported as assets")
    plugin_names = {p.parent.name for p in (root / PLUGIN / "skills").glob("*/SKILL.md")}
    if plugin_names != SKILLS:
        raise ValueError("Public plugin skill set differs from bundle dependencies")
    files = {}

    def add(source, target):
        if target in files or PurePosixPath(target).suffix not in {".md", ".txt", ".json", ""}:
            raise ValueError(f"Duplicate or unsupported export: {target}")
        text = safe_source(root, source).read_text(encoding="utf-8")
        if target == "README.md":
            text = text.replace("(../../LICENSE)", "(LICENSE)")
        if PRIVATE.search(text):
            raise ValueError(f"Private path, example identity, or custom runner in {source}")
        if "/templates/" in target:
            expected = manifest["blankTemplateSha256"].get(target)
            if hashlib.sha256(text.encode("utf-8")).hexdigest() != expected:
                raise ValueError(f"Unreviewed or populated blank template: {target}")
        files[target] = text.encode("utf-8")

    for item in entries:
        name = item["name"]
        if not isinstance(item["requires"], list) or not set(item["requires"]).issubset(SKILLS) or name in item["requires"]:
            raise ValueError(f"Missing or invalid dependency for {name}")
        if "SKILL.md" not in item["files"]:
            raise ValueError(f"Missing skill entrypoint for {name}")
        for relative in item["files"]:
            add(f"{PLUGIN}/skills/{name}/{relative}", f"skills/{name}/{relative}")
        metadata, body = parse_skill(files[f"skills/{name}/SKILL.md"].decode("utf-8"))
        errors = validate_fields(metadata, name, "portable")
        if errors or not body or metadata.get("license") != "MIT" or not metadata.get("metadata", {}).get("version"):
            raise ValueError(f"Invalid portable skill {name}: {errors or 'missing body/license/version'}")
        for referenced in re.findall(r"`([a-z][a-z0-9-]+)` skill\b", files[f"skills/{name}/SKILL.md"].decode("utf-8")):
            if referenced != name and referenced not in item["requires"]:
                raise ValueError(f"Undeclared skill dependency for {name}: {referenced}")
    for asset in manifest["assets"]:
        add(f"{PLUGIN}/{asset}", asset)
    add("LICENSE", "LICENSE")
    if set(manifest["blankTemplateSha256"]) != {name for name in files if "/templates/" in name}:
        raise ValueError("Reviewed blank-template hashes must match exported templates")
    provenance = json.loads(files["provenance.json"])
    if {x["name"] for x in provenance["skills"]} != SKILLS or len(provenance["skills"]) != len(SKILLS):
        raise ValueError("Provenance must cover all 23 skills")
    for entry in provenance["skills"]:
        if entry["origin"] == "ResumeSkills derivative":
            prefix = f"skills/{entry['name']}/"
            if prefix + "NOTICE.md" not in files or prefix + "LICENSES/ResumeSkills-MIT.txt" not in files:
                raise ValueError(f"Missing upstream attribution for {entry['name']}")
            license_text = files[prefix + "LICENSES/ResumeSkills-MIT.txt"].decode("utf-8")
            if hashlib.sha256(license_text.encode("utf-8")).hexdigest() != manifest["upstreamLicenseSha256"]:
                raise ValueError(f"Changed upstream license for {entry['name']}")
    for path, data in files.items():
        for reference in re.findall(r"`([a-z][a-z0-9-]+)` skill\b", data.decode("utf-8")):
            if reference not in SKILLS:
                raise ValueError(f"Unbundled skill dependency in {path}: {reference}")
    validate_links(files)
    exported = {
        "schemaVersion": 1, "name": manifest["name"], "version": manifest["version"],
        "skills": [{"name": x["name"], "path": f"skills/{x['name']}", "requires": x["requires"]} for x in entries],
        "files": {name: hashlib.sha256(data).hexdigest() for name, data in sorted(files.items())},
    }
    files["manifest.json"] = (json.dumps(exported, indent=2) + "\n").encode("utf-8")
    return files


def archive_bytes(root):
    files = collect(root)
    stream = io.BytesIO()
    with zipfile.ZipFile(stream, "w", compression=zipfile.ZIP_STORED) as archive:
        for name, data in sorted(files.items()):
            info = zipfile.ZipInfo(f"career-workbench/{name}", date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_STORED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data)
    return stream.getvalue()


def build(root=ROOT, output=None, check=False):
    selected_root = Path(root).absolute()
    root = selected_root.resolve()
    expected = archive_bytes(root)
    output = Path(output).absolute() if output else root / ARCHIVE
    if output.suffix.lower() != ".zip":
        raise ValueError("Output must have the .zip extension")
    try:
        relative = output.relative_to(selected_root)
    except ValueError:
        try:
            relative = output.relative_to(root)
        except ValueError as exc:
            raise ValueError("Archive output must stay inside the selected public root") from exc
    if ".." in relative.parts:
        raise ValueError("Archive output must stay inside the selected public root")
    # Normalize only the explicitly selected root alias (macOS /var, Windows 8.3).
    # Do not resolve descendant links before the source/output guards inspect them.
    output = root / relative
    if check:
        actual = safe_source(root, relative.as_posix())
        if actual.read_bytes() != expected:
            raise ValueError("Career Workbench archive is missing or stale; regenerate it from these sources")
        return output
    cursor = root
    for part in relative.parts:
        cursor = cursor / part
        if cursor.exists() or cursor.is_symlink():
            attributes = cursor.lstat()
            if cursor.is_symlink() or getattr(attributes, "st_file_attributes", 0) & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0):
                raise ValueError("Linked archive output refused")
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=output.parent, prefix=".career-bundle-", suffix=".tmp", delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(expected)
        with zipfile.ZipFile(temporary) as archive:
            if archive.testzip() is not None:
                raise ValueError("Archive integrity check failed")
        temporary.replace(output)
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=ROOT)
    parser.add_argument("--check", action="store_true", help="Reject a stale/missing committed archive without writing")
    args = parser.parse_args()
    try:
        output = build(args.root, check=args.check)
    except (OSError, UnicodeError, ValueError, KeyError, TypeError) as exc:
        parser.exit(1, f"Career Workbench packaging refused: {exc}\n")
    print(output)


if __name__ == "__main__":
    main()
