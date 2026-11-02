# agent-skills

[![CI](https://github.com/EvanMooreBI/agent-skills/actions/workflows/ci.yml/badge.svg)](https://github.com/EvanMooreBI/agent-skills/actions/workflows/ci.yml)

Agent skills for Claude Code, Codex, and Claude Cowork. Each skill is a folder with a `SKILL.md` that tells the agent when to use it and what to do, plus any scripts, tests, and reference files it needs. The skills follow the [Agent Skills specification](https://agentskills.io/specification).

## Skills

### agent-workflow plugin

| Skill | What it does |
|---|---|
| [claude-subagent-orchestration](plugins/agent-workflow/skills/claude-subagent-orchestration/SKILL.md) | Lets Claude Code hand well-defined tasks to Codex, so less of the Claude plan is spent. Codex is billed to your ChatGPT plan unless you lock your computer to API billing; see [Billing for Codex](plugins/agent-workflow/skills/claude-subagent-orchestration/references/billing.md). Codex runs read-only by default and writes only in an isolated git worktree. Claude reads every diff, and a fresh Codex review runs before merge. Falls back to Claude subagents when Codex is unavailable. Tested only on Windows 11; see [What was tested](plugins/agent-workflow/skills/claude-subagent-orchestration/references/billing.md#what-was-tested). |
| [codex-plan-files](plugins/agent-workflow/skills/codex-plan-files/SKILL.md) | Keeps each Codex plan in its own Markdown file with a status, thread ID, and progress log. A Python helper creates, updates, and finds plans and rebuilds an index. Includes unit tests. |

### wargame-design plugin

| Skill | What it does |
|---|---|
| [wargame-scenario-designer](plugins/wargame-design/skills/wargame-scenario-designer/SKILL.md) | Designs complete, playable miniature wargame scenarios: narrative, terrain, orders of battle, deployment, victory conditions, and special rules. It matches the layout conventions of common rules systems and runs a design checklist before delivery. |
| [wargame-scenario-map-making](plugins/wargame-design/skills/wargame-scenario-map-making/SKILL.md) | Produces measured scenario maps that treat the map as a rules artifact: true table scale, exact deployment zones, preserved historical topology, and a written map style with a bundled conformance validator. |

### fire-and-fury plugin

| Skill | What it does |
|---|---|
| [brigade-fire-and-fury-random-army-generation](plugins/fire-and-fury/skills/brigade-fire-and-fury-random-army-generation/SKILL.md) | Rolls random Brigade Fire and Fury 2nd Edition pickup-game armies, or takes a fixed historical roster, and prints 24 x 25 mm unit labels as a PDF with a CSV log of every roll. Random armies need the generator tables from your own rulebook. You photograph the pages and the agent builds and checks the tables. |
| [reg-fire-and-fury-random-army-generation](plugins/fire-and-fury/skills/reg-fire-and-fury-random-army-generation/SKILL.md) | Rolls random Regimental Fire and Fury USA and CSA forces and prints 24 x 25 mm unit labels as a PDF with a CSV generation log. Its army-generation tables are original to this skill, so everything it needs ships with it. |

## Install

### Claude Code plugin marketplace

```text
claude plugin marketplace add EvanMooreBI/agent-skills
claude plugin install agent-workflow@evanmoorebi-agent-skills
claude plugin install wargame-design@evanmoorebi-agent-skills
claude plugin install fire-and-fury@evanmoorebi-agent-skills
```

Plugin skills are namespaced, for example `/agent-workflow:codex-plan-files`.

### Copy a skill folder

Each skill is a self-contained folder under `plugins/<plugin>/skills/`. Copy the folder you want into the agent's skill folder:

| Agent | For you | For one project |
|---|---|---|
| Claude Code | `~/.claude/skills/<name>/` | `<project>/.claude/skills/<name>/` |
| Codex | `~/.agents/skills/<name>/` | `<project>/.agents/skills/<name>/` |

Commit the project folder if collaborators should get the skill too.

Each skill checks its own requirements the first time it runs. When something is missing, such as the Codex CLI, Python, or a local resource folder, the agent tells you what it affects, sets up what it safely can, and asks before installing software or changing environment variables.

### Claude Cowork and claude.ai

Download a skill zip from the latest CI run, or build the zips with `./scripts/Build-SkillZips.ps1`. Then upload the zip under Skills in Claude's settings. Cowork can use the skills that are turned on there.

## Billing for Codex

Codex runs that the claude-subagent-orchestration skill starts bill your ChatGPT plan by default. They bill an OpenAI API key only after an administrator locks the computer to API billing. The skill's wrapper prints who pays before every run. Setup steps, key storage choices, the guards, and what was tested are in [Billing for Codex](plugins/agent-workflow/skills/claude-subagent-orchestration/references/billing.md).

## Local resources

Some skills can use material that the repository cannot include because someone else holds the copyright, such as your rules system's quick-reference sheet. Each such skill lists that material in its `local-resources.json`, says whether each item is required or optional, and explains what changes without it. Only one resource is required: the Brigade generator tables, and only for random armies.

Put your own copies in `~/.agent-skills/local/<skill-name>/<resource-id>/`, or set `AGENT_SKILLS_LOCAL` to another folder with the same layout. The skill reports what it finds and can create the folders for you.

| Skill | Resource | Purpose |
|---|---|---|
| wargame-scenario-designer | `rules-quick-reference` | Your rules system's quick-reference sheet, so terms and effects match the rules |
| wargame-scenario-designer | `design-articles` | Your saved copies of the articles in [further reading](plugins/wargame-design/skills/wargame-scenario-designer/references/further-reading.md) |
| wargame-scenario-map-making | `map-fonts` | Times New Roman regular and italic, or Liberation Serif or Tinos |
| wargame-scenario-map-making | `v32-reference-art` | A finished map in the V32 style to compare against |
| brigade-fire-and-fury-random-army-generation | `generator-tables` | Required for random armies. The d10 tables from your rulebook's Fictional Army Generator for Pick-up Games. Give the agent photos of the pages and it fills in and checks the tables for you. Fixed rosters work without them. |
| reg-fire-and-fury-random-army-generation | `source-workbooks`, `real-name-label-data` | Maintainers only. Source workbooks and real-name test data. |

## Requirements

| Skill | Needs |
|---|---|
| claude-subagent-orchestration | Claude Code, Python 3, a git repository, and the Codex CLI signed in to a ChatGPT plan, or to an OpenAI API key after you lock the computer to API billing |
| codex-plan-files | Codex and Python 3.9 or later |
| wargame-scenario-designer | No extra tools |
| wargame-scenario-map-making | Python 3.9 or later for the validator, and an image or SVG tool for rendering |
| brigade-fire-and-fury-random-army-generation and reg-fire-and-fury-random-army-generation | PowerShell 7, Node.js, Chrome, Chromium or Microsoft Edge, and Python with PyMuPDF. CI checks the PDFs on Windows. |

On Windows, some paths in this repository are up to 150 characters long. If a clone fails with "Filename too long", run `git config --global core.longpaths true`, or clone into a shorter folder such as `C:\src`.

## Contributing and license

See [CONTRIBUTING.md](CONTRIBUTING.md) for the layout, the local-resource rules, and the checks. Released under the [MIT License](LICENSE). See [NOTICE.md](NOTICE.md) for trademarks and third-party material.
