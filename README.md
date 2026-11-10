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

### Career Workbench (`job-search` plugin)

[Career Workbench](plugins/job-search/README.md) contains 23 connected career skills: guided background discovery, skills and evidence records, resumes, job reviews, application/outreach drafts, interview practice, and offer/negotiation preparation. It supports qualitative evidence, existing records and AI-guided setup. Start with its [setup prompt](plugins/job-search/START-HERE.md).

Download the committed [complete repository-install bundle](bundles/career-workbench.zip). Install **all 23 sibling skill folders** together; individual folders may have dependencies. The archive is regenerated from the same release sources and CI rejects stale contents. It is not a single-skill web upload.

## Install

### Claude Code plugin marketplace

```text
claude plugin marketplace add EvanMooreBI/agent-skills
claude plugin install agent-workflow@evanmoorebi-agent-skills
claude plugin install wargame-design@evanmoorebi-agent-skills
claude plugin install fire-and-fury@evanmoorebi-agent-skills
claude plugin install job-search@evanmoorebi-agent-skills
```

Plugin skills are namespaced, for example `/agent-workflow:codex-plan-files`.

### Copy a skill folder

Skills live under `plugins/<plugin>/skills/`. For Career Workbench, copy **all 23** folders from `plugins/job-search/skills/` together into the chosen root below, preserving sibling names and notices. For the other plugins, copy the individual folder you want:

| Agent | For you | For one project |
|---|---|---|
| Claude Code | `~/.claude/skills/<name>/` | `<project>/.claude/skills/<name>/` |
| Codex | `~/.agents/skills/<name>/` | `<project>/.agents/skills/<name>/` |

Commit the project folder if collaborators should get the skill too.

Each skill checks its own requirements the first time it runs. When something is missing, such as the Codex CLI, Python, or a local resource folder, the agent tells you what it affects, sets up what it safely can, and asks before installing software or changing environment variables.

### Claude Cowork and claude.ai

Build upload ZIPs with `./scripts/Build-SkillZips.ps1 -Target portable`, then upload
them under Skills in Claude's settings. Cowork can use the skills turned on there.
The builder validates all inputs before creating archives and rejects Code-only
fields without stripping them. The two Fire and Fury packages currently contain
`effort`, and `claude-subagent-orchestration` uses a reserved upload name. The
portable build is blocked until those packages are deliberately adapted for
uploads. CI and the default `-Target repo` build produce Claude Code
source ZIPs; those artifacts are not upload-certified. Career Workbench is distributed as its complete repository bundle instead of individual career ZIPs; do not upload that combined bundle as a single skill.

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
| Career Workbench | All 23 sibling skills; host web/document capabilities as needed; authenticated Drive access only for selected cloud storage. No custom agent or consumer Python requirement. |
| wargame-scenario-designer | No extra tools |
| wargame-scenario-map-making | Python 3.9 or later for the validator, and an image or SVG tool for rendering |
| brigade-fire-and-fury-random-army-generation and reg-fire-and-fury-random-army-generation | PowerShell 7, Node.js, Chrome, Chromium or Microsoft Edge, and Python with PyMuPDF. CI checks the PDFs on Windows. |

On Windows, some paths in this repository are up to 150 characters long. If a clone fails with "Filename too long", run `git config --global core.longpaths true`, or clone into a shorter folder such as `C:\src`.

## Contributing and license

See [CONTRIBUTING.md](CONTRIBUTING.md) for the layout, the local-resource rules, and the checks. Released under the [MIT License](LICENSE). See [NOTICE.md](NOTICE.md) for trademarks and third-party material.

## Development and production

Dev Center owns development, maintenance, provenance, tests and release tooling. This repository is the production output. Implement fixes in Dev Center and promote them through its publisher; do not maintain a separate source copy here. The publisher builds `bundles/career-workbench.zip` before validating and committing each release. `python tools/build_career_bundle.py --check` verifies its freshness.
