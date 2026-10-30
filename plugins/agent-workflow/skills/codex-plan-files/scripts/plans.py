#!/usr/bin/env python3
"""Create, update, find, and index Codex plan files.

Plan files are the single source of truth. INDEX.md is regenerated from their
frontmatter after every change and is never edited by hand.

Exit codes: 0 success, 1 not found or no match, 2 refused or invalid input.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import unicodedata
from datetime import datetime
from pathlib import Path

ENV_ROOT = "CODEX_PLANS_ROOT"
FALLBACK_ROOT = Path("~") / ".codex" / "plans"
TEMPLATE = Path(__file__).resolve().parent.parent / "assets" / "plan-template.md"
INDEX_NAME = "INDEX.md"
STATUSES = ("draft", "approved", "in-progress", "done", "superseded", "abandoned")
OPEN_STATUSES = {"draft", "approved", "in-progress"}
QUOTED_FIELDS = ("title", "thread_name", "repo", "supersedes")
UUID_RE = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", re.I)


class PlanError(Exception):
    def __init__(self, message: str, code: int = 2):
        super().__init__(message)
        self.code = code


def default_root() -> Path:
    """The plans folder: CODEX_PLANS_ROOT if set, else ~/.codex/plans."""
    env = os.environ.get(ENV_ROOT, "").strip()
    return Path(env).expanduser() if env else FALLBACK_ROOT.expanduser()


def now() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def warn(message: str) -> None:
    print(f"warning: {message}", file=sys.stderr)


def yaml_value(key: str, value: str) -> str:
    # JSON strings are valid YAML double-quoted scalars, so titles with colons
    # or Windows paths with backslashes stay parseable.
    return json.dumps(value, ensure_ascii=False) if key in QUOTED_FIELDS else value


def parse_value(raw: str) -> str:
    raw = raw.strip()
    if raw.startswith('"'):
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            return raw.strip('"')
    return raw


def valid_thread_id(value: str) -> str:
    value = value.strip()
    if not UUID_RE.match(value):
        raise PlanError(f"not a valid thread ID (expected a UUID): {value!r}")
    return value.lower()


def resolve_thread_id(arg: str | None) -> str:
    if arg:
        return valid_thread_id(arg)
    env = os.environ.get("CODEX_THREAD_ID", "").strip()
    if env:
        if UUID_RE.match(env):
            return env.lower()
        warn(f"ignoring CODEX_THREAD_ID, not a valid UUID: {env!r}")
    warn("thread ID unknown; the plan was created without one. Add it later with: set PLAN_ID --thread-id ID")
    return ""


def resolve_repo(arg: str | None) -> str:
    if arg:
        return str(Path(arg).resolve())
    try:
        out = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, timeout=10, check=True,
        ).stdout.strip()
        return str(Path(out).resolve()) if out else ""
    except (OSError, subprocess.SubprocessError):
        return ""


def repo_label(repo: str) -> str:
    if not repo:
        return ""
    parts = Path(repo).parts
    # Show the parent repository for a .worktrees/<name> checkout.
    if ".worktrees" in parts:
        i = parts.index(".worktrees")
        if i > 0:
            return parts[i - 1]
    return parts[-1]


def slugify(text: str, limit: int = 60) -> str:
    ascii_text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode("ascii")
    slug = re.sub(r"[^a-z0-9]+", "-", ascii_text.lower()).strip("-")
    if len(slug) > limit:
        slug = slug[:limit].rsplit("-", 1)[0] or slug[:limit]
    return slug or "plan"


def atomic_write(path: Path, text: str) -> None:
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}.", suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8", newline="") as handle:
            handle.write(text)
        os.replace(tmp, path)
    except BaseException:
        Path(tmp).unlink(missing_ok=True)
        raise


def split_frontmatter(text: str) -> tuple[list[str], int]:
    """Return the frontmatter lines and the offset where the body starts."""
    lines = text.splitlines(keepends=True)
    if not lines or lines[0].strip() != "---":
        raise ValueError("no frontmatter")
    offset = len(lines[0])
    for i, line in enumerate(lines[1:], start=1):
        if line.strip() == "---":
            return lines[: i + 1], offset + len(line)
        offset += len(line)
    raise ValueError("frontmatter is not closed")


def read_fields(fm_lines: list[str]) -> dict[str, str]:
    fields = {}
    for line in fm_lines[1:-1]:
        key, sep, raw = line.partition(":")
        if sep and key.strip() and not key.startswith((" ", "\t")):
            fields[key.strip()] = parse_value(raw)
    return fields


def load_plans(root: Path) -> tuple[list[dict], list[tuple[Path, str]]]:
    plans, errors = [], []
    if not root.is_dir():
        return plans, errors
    for path in sorted(root.glob("*.md")):
        if path.name == INDEX_NAME:
            continue
        try:
            fm_lines, _ = split_frontmatter(path.read_text(encoding="utf-8"))
            fields = read_fields(fm_lines)
        except (OSError, UnicodeDecodeError, ValueError) as exc:
            errors.append((path, str(exc)))
            continue
        missing = [k for k in ("plan_id", "status", "title") if not fields.get(k)]
        if missing:
            errors.append((path, "missing " + ", ".join(missing)))
            continue
        fields["path"] = str(path)
        plans.append(fields)
    plans.sort(key=lambda p: sort_key(p.get("updated", "")), reverse=True)
    return plans, errors


def sort_key(stamp: str) -> float:
    try:
        return datetime.fromisoformat(stamp).timestamp()
    except ValueError:
        return 0.0


def md_cell(text: str) -> str:
    return text.replace("|", "\\|").replace("\n", " ")


def write_index(root: Path) -> Path:
    plans, errors = load_plans(root)
    lines = [
        "---",
        "title: Codex plan index",
        "type: index",
        "tags: [codex-plan]",
        "---",
        "# Codex plan index",
        "",
        "Generated by `plans.py index` from the `codex-plan-files` skill. Do not edit by hand.",
        "",
        "| Plan | Status | Repo | Thread | Updated |",
        "| --- | --- | --- | --- | --- |",
    ]
    for p in plans:
        name = Path(p["path"]).name
        thread = f"`{p['thread_id']}`" if p.get("thread_id") else ""
        lines.append(
            f"| [{md_cell(p['title'])}]({name}) | {p['status']} | {md_cell(repo_label(p.get('repo', '')))} "
            f"| {thread} | {p.get('updated', '')[:10]} |"
        )
    if errors:
        lines += ["", "## Unreadable plan files", ""]
        lines += [f"- `{path.name}`: {md_cell(reason)}" for path, reason in errors]
    index = root / INDEX_NAME
    atomic_write(index, "\n".join(lines) + "\n")
    return index


def find_plan(root: Path, plan_id: str) -> Path:
    candidate = Path(plan_id)
    if candidate.suffix == ".md" and candidate.is_file():
        return candidate
    path = root / f"{plan_id}.md"
    if path.is_file():
        return path
    raise PlanError(f"plan not found: {plan_id}", code=1)


def cmd_new(args: argparse.Namespace) -> int:
    root: Path = args.root
    thread_id = resolve_thread_id(args.thread_id)
    if thread_id and not args.force_new:
        plans, _ = load_plans(root)
        for p in plans:
            if p.get("thread_id") == thread_id and p["status"] in OPEN_STATUSES:
                print(p["path"])
                raise PlanError(
                    f"an open plan already exists for this thread ({p['plan_id']}, {p['status']}). "
                    "Update it, close it with set --status, or pass --force-new."
                )
    if args.supersedes:
        find_plan(root, args.supersedes)

    root.mkdir(parents=True, exist_ok=True)
    stamp = now()
    base = f"{stamp[:10]}-{slugify(args.slug or args.title)}"
    if thread_id:
        base += f"--{thread_id[-8:]}"
    plan_id, n = base, 2
    while (root / f"{plan_id}.md").exists():
        plan_id, n = f"{base}-{n}", n + 1

    values = {
        "title": args.title,
        "plan_id": plan_id,
        "thread_id": thread_id,
        "thread_name": args.thread_name or "",
        "repo": resolve_repo(args.repo),
        "created": stamp,
        "updated": stamp,
        "supersedes": args.supersedes or "",
    }
    text = TEMPLATE.read_text(encoding="utf-8")
    fm_lines, body_start = split_frontmatter(text)
    front, body = "".join(fm_lines), text[body_start:]
    for key, value in values.items():
        front = front.replace(f"{{{key}}}", yaml_value(key, value))
    body = body.replace("{title}", args.title).replace("{created_date}", stamp[:10])

    path = root / f"{plan_id}.md"
    try:
        with open(path, "x", encoding="utf-8", newline="") as handle:
            handle.write(front + body)
    except FileExistsError as exc:
        raise PlanError(f"{path.name} was created by another process; run new again") from exc
    write_index(root)
    print(path)
    return 0


def cmd_set(args: argparse.Namespace) -> int:
    root: Path = args.root
    path = find_plan(root, args.plan_id)
    updates: dict[str, str] = {}
    if args.status:
        updates["status"] = args.status
    if args.thread_id:
        updates["thread_id"] = valid_thread_id(args.thread_id)
    if args.thread_name is not None:
        updates["thread_name"] = args.thread_name
    if args.supersedes:
        find_plan(root, args.supersedes)
        updates["supersedes"] = args.supersedes
    if not updates:
        raise PlanError("nothing to set; pass --status, --thread-id, --thread-name, or --supersedes")
    updates["updated"] = now()

    with open(path, encoding="utf-8", newline="") as handle:
        text = handle.read()
    try:
        fm_lines, body_start = split_frontmatter(text)
    except ValueError as exc:
        raise PlanError(f"{path.name}: {exc}") from exc
    newline = "\r\n" if fm_lines[0].endswith("\r\n") else "\n"
    pending = dict(updates)
    out = [fm_lines[0]]
    for line in fm_lines[1:-1]:
        key = line.partition(":")[0].strip()
        if key in pending:
            out.append(f"{key}: {yaml_value(key, pending.pop(key))}{newline}")
        else:
            out.append(line)
    out += [f"{k}: {yaml_value(k, v)}{newline}" for k, v in pending.items()]
    out.append(fm_lines[-1])
    # The body is copied byte for byte; only frontmatter lines change.
    atomic_write(path, "".join(out) + text[body_start:])
    write_index(root)
    print(path)
    return 0


def cmd_find(args: argparse.Namespace) -> int:
    plans, errors = load_plans(args.root)
    for path, reason in errors:
        warn(f"unreadable plan {path.name}: {reason}")
    query = (args.query or "").lower()
    thread = (args.thread_id or "").lower()
    repo = (args.repo or "").lower()
    hits = []
    for p in plans:
        haystack = " ".join(p.get(k, "") for k in ("plan_id", "title", "thread_id", "thread_name")).lower()
        if query and query not in haystack:
            continue
        if thread and thread not in p.get("thread_id", "").lower():
            continue
        if args.status and p["status"] != args.status:
            continue
        if repo and repo not in p.get("repo", "").lower():
            continue
        hits.append(p)
    for p in hits:
        print("\t".join((p["plan_id"], p["status"], p.get("updated", "")[:10], p["path"])))
    return 0 if hits else 1


def cmd_index(args: argparse.Namespace) -> int:
    args.root.mkdir(parents=True, exist_ok=True)
    print(write_index(args.root))
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", type=Path, help=f"plans folder (default: ${ENV_ROOT}, else {FALLBACK_ROOT})")
    sub = parser.add_subparsers(dest="command", required=True)

    new = sub.add_parser("new", help="create a plan file from the template and print its path")
    new.add_argument("--title", required=True)
    new.add_argument("--thread-id", help="current Codex thread ID; falls back to CODEX_THREAD_ID if set")
    new.add_argument("--thread-name")
    new.add_argument("--repo", help="repository the plan changes (default: git top level of the current folder)")
    new.add_argument("--slug", help="filename slug (default: from the title)")
    new.add_argument("--supersedes", help="plan ID this plan replaces")
    new.add_argument("--force-new", action="store_true", help="create even if this thread already has an open plan")
    new.set_defaults(func=cmd_new)

    setp = sub.add_parser("set", help="change frontmatter fields of a plan; the body is never touched")
    setp.add_argument("plan_id", help="plan ID (filename without .md) or a path to the plan file")
    setp.add_argument("--status", choices=STATUSES)
    setp.add_argument("--thread-id")
    setp.add_argument("--thread-name")
    setp.add_argument("--supersedes")
    setp.set_defaults(func=cmd_set)

    find = sub.add_parser("find", help="list plans that match; exit 1 when nothing matches")
    find.add_argument("query", nargs="?", help="substring of plan ID, title, thread ID, or thread name")
    find.add_argument("--thread-id", help="full or partial thread ID")
    find.add_argument("--status", choices=STATUSES)
    find.add_argument("--repo", help="substring of the repository path")
    find.set_defaults(func=cmd_find)

    index = sub.add_parser("index", help="regenerate INDEX.md from the plan files")
    index.set_defaults(func=cmd_index)
    return parser


def main(argv: list[str] | None = None) -> int:
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8")
        except (AttributeError, ValueError):
            pass
    args = build_parser().parse_args(argv)
    args.root = args.root.expanduser() if args.root else default_root()
    try:
        return args.func(args)
    except PlanError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return exc.code


if __name__ == "__main__":
    sys.exit(main())
