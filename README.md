# agent-skills

Agent skills for Claude Code, Codex, and Claude Cowork. Each skill is a folder with a `SKILL.md` that tells the agent when to use it and what to do, plus any scripts, tests, and reference files it needs. The skills follow the [Agent Skills specification](https://agentskills.io/specification).

## Skills

### agent-workflow plugin

| Skill | What it does |
|---|---|
| [claude-subagent-orchestration](plugins/agent-workflow/skills/claude-subagent-orchestration/SKILL.md) | Lets Claude Code hand well-defined tasks to Codex, so less of the Claude plan is spent. Codex is billed to your ChatGPT plan unless you lock your computer to API billing; see [Billing for Codex](#billing-for-codex). Codex runs read-only by default and writes only in an isolated git worktree. Claude reads every diff, and a fresh Codex review runs before merge. Falls back to Claude subagents when Codex is unavailable. Tested only on Windows 11; see [What was tested](#what-was-tested). |
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
| [reg-fire-and-fury-random-army-generation](plugins/fire-and-fury/skills/reg-fire-and-fury-random-army-generation/SKILL.md) | Rolls random Regimental Fire and Fury USA and CSA forces and prints 24 x 25 mm unit labels as a PDF with a CSV generation log. Everything it needs ships with the skill. |

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

> **Tested only on Windows 11.** The whole claude-subagent-orchestration skill, including this billing setup, has been run only on Windows 11 with Codex CLI 0.163.0. On Linux and macOS only its unit tests run, in CI. See [What was tested](#what-was-tested).

The claude-subagent-orchestration skill lets Claude hand tasks to Codex. Every Codex run that Claude starts goes through the skill's wrapper, `scripts/codex_guard.py`, and is paid for in one of two ways:

| Mode | Who pays | When it applies |
|---|---|---|
| ChatGPT plan (default) | Your ChatGPT plan, within its usage limits. No per-token charges. | Always, unless the computer is locked to API billing |
| OpenAI API | Your OpenAI API account, per token | Only when an administrator locks the computer to API billing |

### Who decides

One file decides, and only an administrator can change it: Codex's machine requirements file, `%ProgramData%\OpenAI\Codex\requirements.toml` on Windows or `/etc/codex/requirements.toml` on Linux and macOS. When it contains `allowed_login_methods = ["api"]`, Claude's Codex runs bill the API. With any other content, or no file, they bill the ChatGPT plan.

The lock decides who pays. Your sign-in, a ChatGPT login or an API key, only has to match it: the wrapper refuses to start Codex when it does not. The skill never reads the mode from your home folder, a project, or an environment variable. Anything running as you can write those, including an agent following instructions hidden in a web page or a file. Codex itself also enforces this file, for every Codex app and command on the computer.

Before every run, the skill's wrapper prints who pays, for example `Billing: ChatGPT plan` or `Billing: OpenAI API, per token, key ending abcd`. To check at any time, ask Claude to run `scripts/codex_guard.py --status` from the skill folder.

In the commands below, `<skill folder>` is where the skill is installed, for example `~/.claude/skills/claude-subagent-orchestration` if you copied it there. Ask Claude for the exact path if you are not sure.

### Use the ChatGPT plan

Nothing to set up. Sign in once with `codex login` in your own terminal and choose ChatGPT.

To make sure no Codex run on the computer can ever bill an API key, also lock it to ChatGPT:

- Windows, in PowerShell opened with Run as Administrator: `powershell -NoProfile -ExecutionPolicy Bypass -File "<skill folder>\scripts\Set-CodexBillingLock.ps1" -Mode chatgpt`
- Linux or macOS: run the commands under [Lock commands for Linux and macOS](#lock-commands-for-linux-and-macos) with `chatgpt`.

### Use the OpenAI API

1. **Cap your spending first.** In the OpenAI dashboard, create a project for Codex. Under Project settings, Limits, Spend, turn on "Enforce a hard limit" and set a monthly amount. Requests are then refused once the project reaches the limit, though a small amount can get through before the limit takes effect ([OpenAI spend limits](https://developers.openai.com/api/docs/guides/spend-limits)). This limit is the only thing that bounds spending if the key ever leaks: any program running as you can read a key stored on your computer.
2. **Create an API key in that project.**
3. **Lock the computer to API billing.** Windows, as administrator: `powershell -NoProfile -ExecutionPolicy Bypass -File "<skill folder>\scripts\Set-CodexBillingLock.ps1" -Mode api`. Linux or macOS: the commands below with `api`. Codex then ignores your ChatGPT sign-in everywhere on the computer, including the Codex app. Until you finish step 5, `codex login status` shows `Not logged in`. That is expected: your ChatGPT sign-in stays on the computer, unused.
4. **Choose where the key is kept.** See [Where to keep the API key](#where-to-keep-the-api-key). For the recommended system keyring, add this line to `~/.codex/config.toml`, above any line in square brackets: `cli_auth_credentials_store = "keyring"`
5. **Sign in with the key, in your own terminal.** `codex login --with-api-key` reads the key from standard input, not from a prompt. These commands ask for the key without showing it or saving it in your shell history:
   - PowerShell 7: `Read-Host -MaskInput 'OpenAI API key' | codex login --with-api-key`
   - bash or zsh: `read -rs KEY && printf '%s' "$KEY" | codex login --with-api-key; unset KEY`

   Never paste the key into a chat with Claude.
6. **Check:** ask Claude to run `codex_guard.py --status`. It should end with `Billing: OpenAI API, per token, key ending` and the last four characters of your key.

### Where to keep the API key

You choose. The skill never asks for the key, reads it, or stores it.

| Where | How | Who can read the key |
|---|---|---|
| The system keyring (recommended) | Add `cli_auth_credentials_store = "keyring"` to `~/.codex/config.toml`, then sign in as in step 5 | Programs running as you that ask the keyring for it. Programs that only read files, such as an agent's file tools, a backup, or a synced home folder, cannot. |
| Codex's sign-in file | Sign in as in step 5 with no other setting. Codex writes the key in plain text to `~/.codex/auth.json`. | Any program that can read your files |
| The `CODEX_API_KEY` environment variable | Set it in the shell you start Claude Code from | Every command Claude runs, because each one inherits the variable. The wrapper prints a warning on every run. |

- Use `keyring`, not `auto`. `auto` falls back to the plain-text file without telling you when the keyring is unavailable, and `keyring` stops with an error instead.
- The keyring is Credential Manager on Windows, where Codex keeps an encrypted file and stores its key in Credential Manager. On macOS it is the Keychain. On Linux it is the Secret Service, which needs an unlocked keyring, as in a desktop session.
- The setting applies to every Codex sign-in, including ChatGPT. Codex does not move an existing sign-in into the keyring, so sign in again after you add the line. When Codex saves a sign-in to the keyring, it deletes `~/.codex/auth.json`.
- If you use `CODEX_API_KEY`, load it from your password manager into that one shell. Never put it in your shell profile or a saved user environment variable, because every program you start would get it.
- Whichever you choose, use a key that only Codex uses, in the project with the hard limit, and revoke it in the OpenAI dashboard when you stop using API mode. No storage choice stops a program that runs as you and goes looking for the key. The hard limit is what bounds the cost.

### Switch back to the ChatGPT plan

- If you signed in with the key in step 5, run `codex logout` in your own terminal first. It deletes the key from the keyring or `~/.codex/auth.json`. On Windows, a Credential Manager entry named `secrets|<id>.codex` stays behind. It holds the encryption key for Codex's secrets file, not your API key. Then lock the computer to `chatgpt` as above, run `codex login`, and choose ChatGPT. Codex keeps one sign-in at a time, so the key had replaced your ChatGPT sign-in.
- If you used only `CODEX_API_KEY`, lock the computer to `chatgpt` as above. Your ChatGPT sign-in is still there, and `codex login status` shows `Logged in using ChatGPT`. Codex ignores the variable under the ChatGPT lock, but remove it so the key does not stay in your environment.

Revoke the key in the OpenAI dashboard if you no longer need it.

### If you want both

Leave out the lock file, or allow both methods in it with `allowed_login_methods = ["chatgpt", "api"]`. Claude's runs then use the ChatGPT plan, and you can still use your API key yourself in your own terminal.

### Lock commands for Linux and macOS

Replace `MODE` with `chatgpt` or `api`:

```bash
sudo mkdir -p /etc/codex
printf 'allowed_login_methods = ["MODE"]\n' | sudo tee /etc/codex/requirements.toml > /dev/null
sudo chown root /etc/codex /etc/codex/requirements.toml
sudo chmod 755 /etc/codex
sudo chmod 644 /etc/codex/requirements.toml
```

If `/etc/codex/requirements.toml` already holds other settings, add or change the `allowed_login_methods` line by hand instead.

### What protects you, and what does not

| Guard | What it does | What it does not cover |
|---|---|---|
| The lock file | Codex refuses the other sign-in method, for every Codex app and command on the computer | Without a lock, your own Codex use in a terminal is not restricted |
| The wrapper | Removes stray API keys, pins the sign-in, refuses risky options, checks that an `api` lock is owned by an administrator, and prints who pays | Codex started some other way |
| The optional Claude Code hook | Blocks Claude from starting Codex without the wrapper, setting an API key, running `codex login`, or changing the lock or Codex's sign-in file | It reads command text only, so it does not see a script that starts Codex or writes those files itself |
| OpenAI's hard spend limit | Stops API requests at your monthly cap | ChatGPT plan usage, which your plan's own limits cover |

The guards exist because of two Codex behaviors:

- `codex exec` uses `CODEX_API_KEY` ahead of your ChatGPT sign-in, but `codex login status` does not show that variable. A sign-in check alone cannot stop API billing.
- When Codex is told to require one sign-in method but finds the other kind of credential, it deletes every stored sign-in and exits. The wrapper never gives Codex that combination.

To turn on the hook, add this to `~/.claude/settings.json`, with the full path to the hook file in your copy of the skill. On Linux and macOS, use `python3` as the command if your system has no `python`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash|PowerShell|Write|Edit|MultiEdit|NotebookEdit",
        "hooks": [
          { "type": "command", "command": "python", "args": ["<skill folder>/scripts/codex_billing_guard_hook.py"] }
        ]
      }
    ]
  }
}
```

If the hook file moves or is deleted, Claude Code blocks every matched action until you fix the path.

### What was tested

Everything below ran on one Windows 11 computer with Codex CLI 0.163.0, Python 3.14, and PowerShell 7.6, in October and November 2026. On Linux and macOS, only the unit tests run, in this repository's CI.

Tested:

- The wrapper and hook unit tests, on this computer and in CI on Ubuntu, macOS, and Windows. They use a stand-in for Codex. The test of the Linux and macOS ownership check runs only in CI, against a lock file owned by a normal user.
- Both lock modes, switched with `Set-CodexBillingLock.ps1`, using fake API keys. The API rejected every fake key with a 401, so nothing was billed.
- A fake key from `CODEX_API_KEY`, and a fake key stored in the Windows keyring with `cli_auth_credentials_store = "keyring"` and the PowerShell 7 sign-in command above.
- Switching back to the ChatGPT plan, with the ChatGPT sign-in unchanged.

Not tested:

- Anything on Linux or macOS beyond the unit tests: Codex itself, the lock commands, the ownership check against a real root-owned lock, the bash sign-in command, and the hook run with `python3`.
- The macOS Keychain and the Linux Secret Service.
- Codex deleting an existing `~/.codex/auth.json` when it saves a sign-in to the keyring. This statement comes from the Codex source code.
- A key stored with `codex login --with-api-key` replacing a real ChatGPT sign-in. This statement also comes from the Codex source code.
- A real API key, real per-token billing, and OpenAI's hard spend limit.
- Codex CLI versions other than 0.163.0.

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
