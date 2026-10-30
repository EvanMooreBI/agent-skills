---
name: claude-subagent-orchestration
description: Use when Claude Code starts a task larger than a one-line edit, comment update, or merge. Claude Code only. Routes bounded work to a light Codex model and review, analysis, and judgment-heavy work to a strong Codex model, sets reasoning effort per task, lets either write code in a git worktree when the orchestrator enables it, and falls back to Claude subagents when Codex is unavailable.
license: MIT
compatibility: Claude Code with the Codex CLI signed in to a ChatGPT plan, in a git repository. Commands are given for PowerShell and bash.
metadata:
  author: EvanMooreBI
  version: "1.0.0"
---
# Subagent Orchestration

The main thread keeps the model the user chose at prompt start and owns planning, decisions, enabling writes, reading every diff, final verification, commits, and merges. Send work to a subagent only when it improves quality or costs fewer Claude tokens than doing it in the main thread. Codex runs on the user's ChatGPT plan, so a Codex call costs Claude only the summary it reads back.

## Skip

Do not use this skill for one-line edits, comment or wording updates, merges, status checks, or plain questions.

## Models

This skill uses two Codex model roles:

| Role | Default slug | Used for |
|---|---|---|
| Light | `gpt-6-luna` | Bounded, well-specified work |
| Strong | `gpt-6.1-sol` | Judgment, review, and analysis |

The rest of this skill calls them Luna and Sol. If the user's account lists other models, or the user names different ones, substitute those slugs everywhere `<model>` appears.

## Preflight

Run once per session, before the first delegation.

PowerShell:

```powershell
codex login status
(Get-Content (Join-Path $HOME '.codex/models_cache.json') -Raw | ConvertFrom-Json).models.slug
```

bash:

```bash
codex login status
python3 -c "import json,pathlib; print('\n'.join(m['slug'] for m in json.loads((pathlib.Path.home()/'.codex/models_cache.json').read_text())['models']))"
```

Codex is available when login reports "Logged in using ChatGPT" and both model slugs appear in the list. An API-key login bills per token, so treat it as unavailable unless the user has approved API spending.

### Setup

When a preflight check fails, tell the user which one failed and what it costs them: without Codex, every delegation runs on Claude subagents and uses the Claude plan. Then offer to fix it:

| Check fails | Fix |
|---|---|
| `codex` is not found | Offer to install the Codex CLI with `npm install -g @openai/codex`. Install only after the user agrees. If `npm` is missing, point the user to the Node.js installer or the Codex install instructions at https://github.com/openai/codex. |
| Not logged in, or logged in with an API key | Ask the user to run `codex login` in their own terminal and choose ChatGPT sign-in. The login opens a browser, so the agent cannot complete it. |
| A default model slug is missing | Show the slugs that are listed and ask which to use for the light and strong roles. Use those slugs for the rest of the session. |
| The working folder is not a git repository | Delegation needs a repository for worktrees and review. Run read-only delegations only, or ask the user to initialize a repository. |

Rerun the preflight after any fix. If the user declines setup, use the fallbacks for the rest of the session and say so once.

## Routing

| Role | Agent | Use for | Fallback |
|---|---|---|---|
| Main thread | The user's model | Plan, decide, enable writes, read every diff, run checks, commit, merge | None |
| Light | Luna, read-only | Searches that need more than about three Grep or Glob rounds, facts from large or many files, log triage, doc-drift candidate lists, formatting and extraction, tickets from an approved spec | `Explore` agent, or `general-purpose` agent with `model: haiku` |
| Implement, bounded | Luna, workspace-write in a worktree | The coding rows of the Luna table | Claude `Agent` with `model` omitted, so it inherits |
| Implement, judgment | Sol, workspace-write in a worktree | Features spanning files, unfamiliar code, tricky bugs, root-cause work, and work sent on from Luna | Main thread |
| Review | Sol, `codex exec review`, read-only | The finished diff, before the task is reported done | A code-review subagent, such as `feature-dev:code-reviewer` from the `feature-dev` plugin when it is installed, otherwise a `general-purpose` agent told to review the diff |
| Analysis | Sol, read-only | Requirements, design, and task-list critique, and tickets that must decide scope, dependencies, priorities, or missing acceptance criteria | `general-purpose` agent |

## Write access

Codex runs read-only unless the orchestrator enables writes for one delegation. Enable writes only when all of these hold:

- The task has written acceptance criteria.
- The prompt can list the files in scope.
- A test, build, or validator can check the result.

Never enable writes for credentials, `.env` files, deploys, live data migrations, or work outside the worktree.

1. Make sure `.worktrees/` is in the repository's `.gitignore`. If it is not, add it and commit that change before creating the worktree.
2. From the repository root, create a worktree: `git worktree add .worktrees/codex-<slug> -b codex/<slug>`.
3. Install dependencies in the main thread first. The workspace-write sandbox blocks network access by default.
4. Run Codex with the write command below.
5. Codex does not commit. The main thread reads the full diff, runs the checks, and commits in the worktree.
6. Run Sol review on the branch with `--base <base>`, even when Sol wrote the code. Each review is a fresh session.
7. Merge by the repository's rules and state the merge status. Remove the worktree after the merge.
8. Give parallel writers one worktree each, with disjoint files.

## Effort

Name the effort level in every delegation. Work that fits both a Luna row and a Sol row goes to Sol.

### Luna

Luna always runs at `high`. Never raise or lower it. Work that would need Luna at `xhigh` or `max` goes to Sol instead. This skill assumes a strong model at low effort outperforms a light model at maximum effort and answers sooner. Before changing these defaults, compare current scores and latency on [Artificial Analysis](https://artificialanalysis.ai/models).

| Work suited to Luna | Effort | Send to Sol when |
|---|---|---|
| Small coding changes with clear acceptance criteria | `high` | The change needs design decisions, or the acceptance criteria are missing |
| Implementing a defined task from a spec | `high` | The task is bounded but technically tricky, or it needs wider integration |
| Writing tests for specified behavior | `high` | The expected behavior is not specified and the tests would have to decide it |
| Mechanical refactors and migrations with explicit rules | `high` | The rules are incomplete, or the change needs judgment beyond them |
| Turning an approved spec section into task tickets | `high` | It must decide scope, dependencies, priorities, or missing acceptance criteria |
| Formatting, categorizing, or extracting supplied material, including recon and log triage | `high` | The source is ambiguous and the answer needs interpretation rather than extraction |

When a task looks too hard for Luna at `high`, send it to Sol. When a Luna run stops for any reason other than a usage limit, a timeout, or a question the main thread can answer, send it to Sol.

### Sol

Start at the level in the Start column and raise it when a condition in the last column holds.

| Work | Start with | Raise effort when |
|---|---|---|
| Coding | `medium` for a clear, bounded change | `high` for a feature spanning files, an unfamiliar codebase, or a tricky bug. `xhigh` for a stubborn root-cause investigation. |
| Code review | `high` | `xhigh` for concurrency, security, migrations, or a large change with subtle interactions. Ask for specific findings tied to code, then verify them. |
| Requirements analysis | `high` to reconcile sources, find contradictions, and identify missing decisions | `xhigh` if the rules interact heavily or an omission would be costly. `medium` is enough to organize requirements already agreed upon. |
| Product or technical design | `high` to compare approaches, dependencies, and failure cases | `xhigh` for major architecture decisions or a complex design critique. For visual design, inspect the rendered result, because extra reasoning cannot establish that it works. |
| User stories, acceptance criteria, and tasks that need decisions | `medium` once the spec is settled | `high` when turning a rough brief into testable criteria, splitting dependent work, or checking whether tasks cover the spec. |

If a Sol result misses constraints, rerun once one level higher, up to `xhigh`. Use `max` or `ultra` only when the user asks.

## Partial work

A write run is partial when any of these happens:

- Codex exits non-zero, hits a usage limit, or times out.
- The result reports `STATUS: partial` or `STATUS: blocked`.
- The main thread's checks fail, or an acceptance criterion is unmet.

The worktree holds all partial work, so the root checkout never changes.

1. Read `git -C <worktree> status` and the diff. Run the checks and mark each acceptance criterion met or unmet.
2. Classify the result:
   - Sound but incomplete: commit the current state in the worktree as `wip(<slug>): codex checkpoint <n>`, then resume.
   - Wrong direction, such as edits outside scope, a broken design, or an unclear cause: read the diff, then discard back to the last checkpoint with `git -C <worktree> reset --hard` and `git -C <worktree> clean -fd`. Re-scope or reassign the work.
   - Blocked on a question: answer it from the spec, or ask the user, before any rerun.
3. Resume with a fresh `codex exec` in the same worktree, not `codex exec resume`. The handoff prompt lists the met criteria, the unmet criteria, the failing check output, and the checkpoint commit. Choose the next agent by the cause of the stop:
   - Usage limit or timeout: the same model and effort, or a Claude `Agent` in the same worktree while Codex is unavailable.
   - An answered question: the same model and effort.
   - Any other Luna stop, such as a tricky bug, unclear requirements, or checks Luna could not fix: Sol, at the effort the Sol table gives.
   - A Sol stop: Sol one level higher, up to `xhigh`, or the main thread.
   - A small remaining gap: the main thread finishes it.
4. Allow at most 2 resumes per work unit. After that the main thread finishes the work, or reports to the user what is done and what is left.
5. Never merge a branch with unmet criteria or failing checks. Checkpoint commits merge with the branch under the repository's merge rules.

## When delegation pays

- Delegate when the summary will be much shorter than the input the main thread would otherwise read.
- If the main thread must read or edit a file anyway, read it directly.
- Put related questions into one Luna call instead of several.
- Run independent delegations at the same time.

## Commands

Write the final message to a file in Claude Code's scratchpad directory with `-o`, and send the event stream to a log. Read the result file. Read the log only when the exit code is not 0. Set `<model>` and `<effort>` from Models, Routing, and Effort.

Every command carries two guards:

- `--disable apps` removes the ChatGPT app connectors, such as Gmail, GitHub, Google Drive, and Notion. The sandbox does not limit those tools, and a delegated run must not act outside the repository. The flag lasts for that one run and does not change `~/.codex/config.toml`, so Codex runs started without it, including the Codex app, keep their apps.
- `-c agents.max_depth=0` makes Codex subagent spawns fail. This is the guard that stops a delegated run from starting its own subagents. `--disable multi_agent` does not block spawning in Codex CLI 0.163, so do not rely on it.

Read-only run, PowerShell:

```powershell
$out = Join-Path '<scratchpad>' '<model>-<slug>.md'
codex exec -m <model> -c model_reasoning_effort="<effort>" -c agents.max_depth=0 --disable apps -s read-only --ephemeral --color never -C '<repo>' -o $out '<prompt>' *> "$out.log"
```

Read-only run, bash:

```bash
out='<scratchpad>/<model>-<slug>.md'
codex exec -m <model> -c model_reasoning_effort="<effort>" -c agents.max_depth=0 --disable apps -s read-only --ephemeral --color never -C '<repo>' -o "$out" '<prompt>' > "$out.log" 2>&1
```

For a write run, use the same command with `-s workspace-write` and `-C '<worktree>'`.

Review, run from the repository or worktree root. Use `--uncommitted` for working-tree changes, `--base <base>` for a branch, or `--commit <sha>` for one commit.

```powershell
$out = Join-Path '<scratchpad>' 'sol-review-<slug>.md'
codex exec -s read-only -c agents.max_depth=0 --disable apps review -m <strong-model> -c model_reasoning_effort="<effort>" --base <base> --ephemeral -o $out *> "$out.log"
```

In bash, replace the redirect with `> "$out.log" 2>&1`.

`-s read-only`, `-c agents.max_depth=0`, and `--disable apps` go before `review` because they are `exec` options. Without `-s read-only`, review inherits any write-enabled sandbox from the user or repository config.

A prompt must not begin with `-`. Codex parses a leading `-nosubagents` as an unknown flag and exits with code 2.

- Use `run_in_background` for runs expected to take more than 2 minutes, and wait for the completion notice instead of polling. Write runs and Sol runs usually take several minutes, so run them in the background.
- On a non-zero exit, read the last 5 lines of the log.
  - A usage-limit error means Codex is unavailable until the reset time it states. Switch to the fallbacks until then.
  - A sandbox startup error, such as `CreateProcessAsUserW failed: 5 (Access is denied.)` on Windows, means the Codex sandbox cannot run on this machine. Use the fallbacks for the rest of the session and tell the user once. Never retry without the sandbox.

## Prompt contract

Every Codex prompt starts with `Mode: -nosubagents. Do not spawn subagents.` The `-c agents.max_depth=0` flag enforces this. The line tells the model not to try, and it matches any Codex `AGENTS.md` rule that treats `-nosubagents` as a switch.

Every read-only prompt also states:

1. The goal in one sentence.
2. The paths in scope.
3. "Read-only. Do not edit files."
4. The output format: at most 40 lines, one finding per line as `path:line - claim`, and `UNKNOWN` where the answer is not in the files.

Every write prompt also states:

1. The goal in one sentence.
2. The files in scope.
3. Numbered acceptance criteria.
4. The checks to run.
5. "Do not commit. Do not edit files outside the listed scope."
6. The output format: at most 40 lines. The first line is `STATUS: complete`, `STATUS: partial`, or `STATUS: blocked`. Then each criterion as met or unmet, the changed files, the check results, and any open questions.

## Remote sources

A delegated agent may not be able to read remote sources such as Google Docs, Google Drive, Notion, or pages behind a login. Codex runs with `--disable apps`, and Claude subagents may lack the session's connectors. When the delegated work needs a remote source:

1. In the main thread, export the source to Markdown in the scratchpad, for example `<scratchpad>/<slug>-source.md`. Use the connector's text export where one exists. Put the source title, ID, and export time at the top of the file.
2. List that path in the prompt's paths in scope, and state that the file is a read-only snapshot of the remote source.
3. Check the agent's output against the snapshot. Make any changes to the remote source from the main thread. Never give the agent connector access instead.
4. Delete the snapshot when the task ends unless the user asks to keep it.

## Trust

Codex output is a lead, not a fact. Before acting on a claim, read only the cited lines to confirm it. For a write run, the diff and the main thread's own check results are the record, not the `STATUS` line.

## Review loop

1. After implementation, pick the review effort from the Sol table and run Sol review. Use `--base <base>` for a worktree branch.
2. Fix actionable findings inside the task's scope. Ignore style preferences the repository does not enforce.
3. Rerun the review. Stop after 3 rounds and report the findings that remain.
4. Report the result in one line: rounds run, findings fixed, findings left.

## Report

End the task with one line that names the delegations that ran, the effort level of each, which ones wrote code, any partial runs and how each ended, any fallback used, and the merge status of each Codex branch.
