#!/usr/bin/env python3
"""Check this repository before release.

Checks skill frontmatter against the Agent Skills spec, plugin and marketplace
manifests, local-resource manifests, relative Markdown links, file types and
sizes, and markers of personal or third-party material that must not ship.

Usage: python tools/validate_repo.py [--root DIR] [--private DIR]

--private names a folder of restricted files. Any file in the repository with
the same SHA-256 as one of them is a finding.

Exit codes: 0 clean, 1 findings, 2 bad arguments.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
MAX_FILE_BYTES = 2 * 1024 * 1024
BLOCKED_SUFFIXES = {".pdf", ".ttf", ".otf", ".woff", ".woff2", ".zip", ".xlsx", ".xlsm", ".docx", ".pptx", ".epub"}
TEXT_SUFFIXES = {".md", ".json", ".py", ".ps1", ".psm1", ".yml", ".yaml", ".txt", ".csv", ".js", ".gs", ".html", ".sh"}
# Personal paths, private repository names, and retired third-party references.
DENY_PATTERNS = [
    re.compile(r"[A-Za-z]:\\Users\\", re.I),
    re.compile(r"\bcrazy\b", re.I),
    re.compile(r"\bdev-center\b", re.I),
    re.compile(r"\bknowledge-center\b", re.I),
    re.compile(r"private-skill-resources", re.I),
    re.compile(r"\bWilkinson\b"),
    re.compile(r"\bASL\b"),
    re.compile(r"@gmail\.com", re.I),
]
RESOURCE_KEYS = {"id": str, "purpose": str, "required": bool, "whenMissing": str,
                 "howToObtain": str, "expectedFiles": list, "license": str}
SKIP_DIRS = {".git", "dist", "__pycache__", "node_modules", ".worktrees"}
SENSITIVE_NAME_RE = re.compile(r"^(\.env(\..*)?|.*\.(pem|key|p12|pfx)|id_(rsa|ed25519|ecdsa)(\.pub)?|credentials(\.json)?)$", re.I)
# A plain (unquoted) YAML scalar cannot start with these or contain ": " or " #".
PLAIN_SCALAR_BAD_START = tuple("[]{}&*!|>'\"%@`,#")

try:
    import yaml  # optional: full YAML syntax check when PyYAML is installed
except ImportError:  # pragma: no cover
    yaml = None


def frontmatter_syntax_errors(text: str) -> list[str]:
    """Return YAML syntax problems in the frontmatter block."""
    lines = text.splitlines()
    try:
        end = next(i for i, line in enumerate(lines[1:], start=1) if line.strip() == "---")
    except StopIteration:
        return ["frontmatter is not closed"]
    block = "\n".join(lines[1:end])
    if yaml is not None:
        try:
            data = yaml.safe_load(block)
        except yaml.YAMLError as exc:
            return [f"invalid YAML: {str(exc).splitlines()[0]}"]
        return [] if isinstance(data, dict) else ["frontmatter is not a mapping"]
    errors = []
    for number, line in enumerate(lines[1:end], start=2):
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        _, sep, value = line.strip().partition(":")
        value = value.strip()
        if not sep or not value or value[0] in "\"'":
            continue
        if value.startswith(PLAIN_SCALAR_BAD_START) or ": " in value or " #" in value or value.endswith(":"):
            errors.append(f"line {number}: quote this value; it is not a valid plain YAML scalar")
    return errors


def files_under(root: Path):
    for path in sorted(root.rglob("*")):
        if path.is_file() and not SKIP_DIRS.intersection(path.relative_to(root).parts):
            yield path


def parse_frontmatter(text: str) -> dict | None:
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    fields: dict = {}
    parent = None
    for line in lines[1:]:
        if line.strip() == "---":
            return fields
        if not line.strip():
            continue
        indented = line.startswith((" ", "\t"))
        key, sep, value = line.strip().partition(":")
        if not sep:
            continue
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        if indented and parent is not None:
            fields[parent][key.strip()] = value
        elif not indented:
            if value == "":
                fields[key.strip()] = {}
                parent = key.strip()
            else:
                fields[key.strip()] = value
                parent = None
    return None


def check_skill(skill_dir: Path, rel, findings: list[str]) -> None:
    skill_md = skill_dir / "SKILL.md"
    skill_text = skill_md.read_text(encoding="utf-8")
    for error in frontmatter_syntax_errors(skill_text):
        findings.append(f"{rel(skill_md)}: frontmatter {error}")
    fm = parse_frontmatter(skill_text)
    if fm is None:
        findings.append(f"{rel(skill_md)}: missing or unclosed frontmatter")
        return
    name = fm.get("name", "")
    if not isinstance(name, str) or not NAME_RE.match(name) or len(name) > 64:
        findings.append(f"{rel(skill_md)}: invalid name {name!r}")
    elif name != skill_dir.name:
        findings.append(f"{rel(skill_md)}: name {name!r} does not match folder {skill_dir.name!r}")
    description = fm.get("description", "")
    if not isinstance(description, str) or not 1 <= len(description) <= 1024:
        findings.append(f"{rel(skill_md)}: description must be 1-1024 characters")
    compatibility = fm.get("compatibility")
    if compatibility is not None and (not isinstance(compatibility, str) or not 1 <= len(compatibility) <= 500):
        findings.append(f"{rel(skill_md)}: compatibility must be 1-500 characters")
    if fm.get("license") != "MIT":
        findings.append(f"{rel(skill_md)}: license must be MIT")
    metadata = fm.get("metadata")
    if not isinstance(metadata, dict) or not metadata.get("version"):
        findings.append(f"{rel(skill_md)}: metadata.version is required")

    manifest = skill_dir / "local-resources.json"
    if manifest.exists():
        check_resources(manifest, skill_dir.name, rel, findings)
        if "## Local resources" not in skill_md.read_text(encoding="utf-8"):
            findings.append(f"{rel(skill_md)}: has local-resources.json but no '## Local resources' section")


def check_resources(manifest: Path, skill_name: str, rel, findings: list[str]) -> None:
    try:
        data = json.loads(manifest.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        findings.append(f"{rel(manifest)}: invalid JSON: {exc}")
        return
    if data.get("skill") != skill_name:
        findings.append(f"{rel(manifest)}: skill must be {skill_name!r}")
    resources = data.get("resources")
    if not isinstance(resources, list) or not resources:
        findings.append(f"{rel(manifest)}: resources must be a non-empty list")
        return
    seen = set()
    for i, res in enumerate(resources):
        for key, kind in RESOURCE_KEYS.items():
            if not isinstance(res.get(key), kind):
                findings.append(f"{rel(manifest)}: resources[{i}].{key} must be {kind.__name__}")
        rid = res.get("id")
        if isinstance(rid, str):
            if not NAME_RE.match(rid):
                findings.append(f"{rel(manifest)}: resources[{i}].id {rid!r} must be lowercase with hyphens")
            if rid in seen:
                findings.append(f"{rel(manifest)}: duplicate resource id {rid!r}")
            seen.add(rid)


def check_plugins(root: Path, rel, findings: list[str]) -> list[Path]:
    skills: list[Path] = []
    market_path = root / ".claude-plugin" / "marketplace.json"
    listed = set()
    if not market_path.exists():
        findings.append(".claude-plugin/marketplace.json is missing")
    else:
        market = json.loads(market_path.read_text(encoding="utf-8"))
        for key in ("name", "owner", "plugins"):
            if key not in market:
                findings.append(f"{rel(market_path)}: missing {key}")
        for entry in market.get("plugins", []):
            source = entry.get("source", "")
            if not isinstance(source, str) or not source.startswith("./plugins/"):
                findings.append(f"{rel(market_path)}: plugin {entry.get('name')!r} source must be ./plugins/<name>")
                continue
            listed.add(entry.get("name"))
            if Path(source).name != entry.get("name"):
                findings.append(f"{rel(market_path)}: plugin {entry.get('name')!r} source folder name differs")
    for plugin_dir in sorted(p for p in (root / "plugins").glob("*") if p.is_dir()):
        manifest = plugin_dir / ".claude-plugin" / "plugin.json"
        if not manifest.exists():
            findings.append(f"{rel(plugin_dir)}: missing .claude-plugin/plugin.json")
        else:
            data = json.loads(manifest.read_text(encoding="utf-8"))
            if data.get("name") != plugin_dir.name:
                findings.append(f"{rel(manifest)}: name must be {plugin_dir.name!r}")
        if plugin_dir.name not in listed:
            findings.append(f"{rel(plugin_dir)}: not listed in marketplace.json")
        skill_dirs = sorted(p.parent for p in (plugin_dir / "skills").glob("*/SKILL.md"))
        if not skill_dirs:
            findings.append(f"{rel(plugin_dir)}: has no skills")
        skills.extend(skill_dirs)
    names = [s.name for s in skills]
    for dup in sorted({n for n in names if names.count(n) > 1}):
        findings.append(f"skill name {dup!r} appears in more than one plugin")
    return skills


def check_files(root: Path, rel, findings: list[str], private_hashes: dict[str, str]) -> None:
    self_path = Path(__file__).resolve()
    for path in files_under(root):
        if path.stat().st_size > MAX_FILE_BYTES:
            findings.append(f"{rel(path)}: larger than {MAX_FILE_BYTES // (1024 * 1024)} MB")
        if SENSITIVE_NAME_RE.match(path.name):
            findings.append(f"{rel(path)}: looks like a secret or credential file")
        if path.suffix.lower() in BLOCKED_SUFFIXES:
            findings.append(f"{rel(path)}: file type {path.suffix} is not allowed; declare it as a local resource")
        if private_hashes:
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            if digest in private_hashes:
                findings.append(f"{rel(path)}: identical to restricted file {private_hashes[digest]}")
        if path.suffix.lower() not in TEXT_SUFFIXES or path.resolve() == self_path:
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        for number, line in enumerate(text.splitlines(), start=1):
            for pattern in DENY_PATTERNS:
                if pattern.search(line):
                    findings.append(f"{rel(path)}:{number}: matches blocked marker {pattern.pattern!r}")
        if path.suffix.lower() == ".md":
            check_links(path, text, root, rel, findings)


def check_links(path: Path, text: str, root: Path, rel, findings: list[str]) -> None:
    in_fence = False
    for number, line in enumerate(text.splitlines(), start=1):
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        for target in LINK_RE.findall(line):
            if re.match(r"^[a-z][a-z0-9+.-]*:", target, re.I) or target.startswith("#"):
                continue
            resolved = (path.parent / target.split("#", 1)[0]).resolve()
            if not resolved.exists():
                findings.append(f"{rel(path)}:{number}: broken link {target}")
            elif root.resolve() not in resolved.parents and resolved != root.resolve():
                findings.append(f"{rel(path)}:{number}: link leaves the repository: {target}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--private", type=Path, help="folder of restricted files that must not appear here")
    args = parser.parse_args(argv)
    root = args.root.resolve()
    if not root.is_dir():
        parser.error(f"not a folder: {root}")
    private_hashes: dict[str, str] = {}
    if args.private:
        if not args.private.is_dir():
            parser.error(f"not a folder: {args.private}")
        for path in files_under(args.private):
            private_hashes[hashlib.sha256(path.read_bytes()).hexdigest()] = path.name

    def rel(path: Path) -> str:
        return path.resolve().relative_to(root).as_posix()

    findings: list[str] = []
    for skill_dir in check_plugins(root, rel, findings):
        check_skill(skill_dir, rel, findings)
    check_files(root, rel, findings, private_hashes)
    for finding in findings:
        print(finding)
    print(f"{len(findings)} finding(s)", file=sys.stderr)
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
