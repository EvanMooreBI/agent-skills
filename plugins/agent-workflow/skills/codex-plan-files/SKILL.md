---
name: codex-plan-files
description: Use when Codex writes, updates, resumes, or looks up a plan. Codex only. Keeps each plan as a Markdown file in one plans folder with a generated index.
license: MIT
compatibility: Codex with Python 3.9 or later.
metadata:
  author: EvanMooreBI
  version: "1.0.0"
---
# Codex Plan Files

Keep every plan in one Markdown file that you build up during planning, update as decisions change, and reread during execution. `INDEX.md` in the plans folder lists them all.

Run the helper as `python <skill-dir>/scripts/plans.py`, where `<skill-dir>` is the folder that holds this file.

## Plans folder

The helper picks the plans folder in this order:

1. `--root PATH`, passed before the command.
2. The `CODEX_PLANS_ROOT` environment variable.
3. `~/.codex/plans/`.

Two setups work well:

- **One central folder.** Set `CODEX_PLANS_ROOT` once, for example to a notes repository, so plans from every project share one index.
- **One folder per repository.** Add a line to the repository's `AGENTS.md` that tells Codex to pass `--root .codex/plans`. Commit the folder if the team should see the plans.

## Setup

Check these the first time the skill runs in a session:

1. **Python.** Run `python --version`, or `python3 --version` where `python` is missing. The helper needs Python 3.9 or later. If neither works, tell the user that plan files cannot be created until Python is installed, and point them to https://www.python.org/downloads/. Stop until it is installed.
2. **Plans folder.** If `--root` is not in use and `CODEX_PLANS_ROOT` is not set, tell the user that plans will go to `~/.codex/plans/`, and ask whether they want a central folder or one per repository instead.
   - For a central folder, offer to set `CODEX_PLANS_ROOT` for them and set it only after they agree. On Windows, run `[Environment]::SetEnvironmentVariable('CODEX_PLANS_ROOT', '<folder>', 'User')` in PowerShell. On macOS or Linux, add `export CODEX_PLANS_ROOT='<folder>'` to the user's shell profile. New sessions pick it up. Pass `--root <folder>` for the rest of this one.
   - For one folder per repository, offer to add the `--root .codex/plans` line to the repository's `AGENTS.md`.
3. The helper creates the plans folder itself on first use.

## Workflow

1. **Look up first.** Before you create a plan, run `find` with the thread ID or keywords, or read `INDEX.md`. If this thread already has an open plan for the same task, update that file. A different task gets a new plan.
2. **Check the active mode.** Read the instructions of the mode you are in. If they forbid writing files, do not write the plan file. Present the plan the way the mode requires, for example in a `<proposed_plan>` block, and save it to a plan file as your first action once writing is allowed.
3. **Create.** Run `new --title "..."` and pass every thread fact you have. The command prints the new path. Fill in the sections of the body with normal file edits as you learn things. Do not wait until the end.
4. **Write the content.** Follow the template sections. Record only the approach you recommend, not every alternative. List what is in scope and what is out of scope. Name the files to change and the existing code to reuse. Give verification steps that can be run.
5. **Track status.** Statuses are `draft`, `approved`, `in-progress`, `done`, `superseded`, and `abandoned`. Change status only with `set`. At each milestone, add a dated line to the Progress log. When a new plan replaces an old one, create it with `--supersedes OLD_ID` and set the old plan to `superseded`.
6. **Resume.** When a thread continues earlier work, after context compaction, or when the user names an earlier plan, find the plan and reread it before you act.
7. **Report.** Give the plan path in every reply that presents, approves, or finishes a plan.

## Thread ID

The full thread ID goes in the frontmatter and the index. The last 8 characters go in the filename.

- Pass `--thread-id` when you know the current thread ID from your context, your environment, or the user. The script also reads `CODEX_THREAD_ID` if that variable is set.
- If you have no thread ID, create the plan without one and tell the user. Add it later with `set PLAN_ID --thread-id ID`.
- Never guess or invent a thread ID.

## Commands

```text
plans.py new --title "Title" [--thread-id ID] [--thread-name NAME] [--repo PATH] [--slug SLUG] [--supersedes PLAN_ID] [--force-new]
plans.py set PLAN_ID [--status STATUS] [--thread-id ID] [--thread-name NAME] [--supersedes PLAN_ID]
plans.py find [QUERY] [--thread-id ID] [--status STATUS] [--repo TEXT]
plans.py index
```

- `new` exits 2 and prints the existing path when the thread already has an open plan. Update that plan, or pass `--force-new` for a separate task.
- `set` changes frontmatter only. Edit the body yourself.
- `find` prints the plan ID, status, update date, and path, separated by tabs. It exits 1 when nothing matches.
- Every command that writes rebuilds `INDEX.md`. Never edit `INDEX.md` by hand. Run `index` if a plan file was changed outside the script.

The template is [assets/plan-template.md](assets/plan-template.md). After changing the script, run its tests with `python -m unittest discover -s <skill-dir>/scripts`.
