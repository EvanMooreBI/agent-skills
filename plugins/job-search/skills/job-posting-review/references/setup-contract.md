---
title: AI-guided job-search setup
type: procedure
tags: [job-search, setup, portability]
related:
  - "[[workspace-contract]]"
---
# AI-guided setup contract

Run this only when the user asks to set up, reconnect, or update their job-search workspace. Read the [workspace contract](workspace-contract.md). Conduct a conversation, then create or connect the selected resources; the user need not hand-edit configuration or run an installer.

## 1. Locate the repository and install the bundle

Ask for the target repository and which agent(s) will use it if they are not already identified. Keep all 23 sibling skill folders and their references intact. For a repo-local install, Codex uses `.agents/skills/` and Claude Code uses `.claude/skills/`. If both are requested, install all 23 in both locations. Identify conflicting existing versions before changing them; preserve unrelated files and do not follow a junction to overwrite a global installation. In a managed source checkout, retain its existing synchronization workflow rather than copying over it.

Verify the installed files and dependency references. Check discovery in the host; if a refresh or new session is needed, say so. A file copy alone does not prove host discovery. No custom agent, global configuration, hook, API key, or connector is installed by this package.

Installation locations were checked on 2026-11-10 against [OpenAI's local skill guidance](https://learn.chatgpt.com/docs/build-skills#where-codex-loads-local-skills) and [Claude Code's skill guidance](https://code.claude.com/docs/en/skills#choose-where-skills-load). Recheck the host's official guidance if its discovery behavior differs.

## 2. Choose or connect each area

First read existing repository routing. Offer to reuse it. Ask the user where to create or connect each area below, using their chosen local directories or Google Drive folders/documents. Mixed storage is supported. Group related questions and reuse answers; do not force an existing user through a fresh interview.

| Area | New workspace content | Starting template |
|---|---|---|
| Career facts | History/education, skills and usage limits, and records for relevant projects | [Career record](../../career-context-builder/references/templates/career-record.md) |
| Supporting evidence | User-supplied source documents, with an index of their provenance and scope | [Evidence index](../../career-context-builder/references/templates/evidence-index.md) |
| Preferences | Location, work arrangements, mileage limit, pay, target work, relocation, and dealbreakers | [Preferences](templates/preferences.md) |
| Resume catalog | References to actual resumes with role targets and last verified dates | [Resume catalog](templates/resume-catalog.md) |
| Application log | Existing log, or a blank history table when none exists | [Application log](templates/application-log.md) |

For each area persist the selected path or verified Drive URL/ID and the entry document in the [workspace map](templates/workspace.md). Never create a second copy merely because a name differs. For a new Drive area, create it in the selected parent and verify its returned location; populate native documents using the host's document workflow. An existing Sheet log or catalog stays a Sheet. Missing Drive capability blocks only that portion; ask the user to connect access or explicitly choose another destination.

For a new application log use the template's fields; keep an existing schema and map its employer, role, posting identifier/URL, application date/status, and update date. Do not import fabricated application history. Existing rows are not rewritten by setup.

## 3. Discover career context and confirm preferences

After career/evidence storage is selected, use the `career-context-builder` skill for users who need to discover, organize or enrich their history. Its reviewed batches own this interview and reusable fact writes; do not run a second intake here. Users with sufficient established context skip discovery. Read only supplied or routed sources. Ask for genuine interests or motivation only when needed for a requested answer.

Present the proposed defaults together: USA, USD, remote plus local on-site/hybrid, and US citizenship. Confirm citizenship explicitly before saving it as a fact; refusal or no answer leaves it unknown. Ask for target roles, pay floor/target, relocation, and dealbreakers without inventing values. Preserve existing values unless the user requests a change.

Ask for the maximum one-way driving miles and a local home-address file. There is no default number. Ensure `.job-search.local/` is ignored before creating a new local locator or address file. Use the [private-address template](templates/home-address.md); do not put the address in the Drive preferences or shared repository instructions. Show unresolved local-eligibility inputs if the user chooses not to supply them.

## 4. Persist routing and verify

Use the selected repository's `.job-search.local/workspace.md` as the default locator, or reuse existing repository routing when sufficient. The five mapped areas can live anywhere the user selected; this local locator does not determine their storage.

For a new routing setup, add or update one bounded job-search section in the host's existing instruction file, using this template and preserving other content:

```text
For career and job-search tasks, read .job-search.local/workspace.md and follow
the job-posting-review skill's workspace contract. Use the routed factual owners
and external-use restrictions. Keep personal addresses in their private local file.
```

Use `AGENTS.md` for Codex and `CLAUDE.md` for Claude Code; if one links to the other, update the shared file once. Do not place private values in that section. The 23 skills remain normally discoverable; this routing is not an always-on invocation of all 23.

Read back the final map, created/updated document contents and locations, privacy exclusion, catalog targets, and log mapping. Report installed versus actually discovered skills separately. Summarize confirmed defaults, unknowns, and inaccessible sources. Do not report completion for a cloud write without readback.

## 5. Subsequent prompts

Support requests such as "Change my commute limit to 20 miles", "Use this Drive folder for evidence", or "Add this resume to my catalog" by updating the corresponding existing owner. Do not recreate the workspace or move existing documents unless specifically requested. For ordinary job-review or writing prompts, use the saved routing and do not run setup again.
