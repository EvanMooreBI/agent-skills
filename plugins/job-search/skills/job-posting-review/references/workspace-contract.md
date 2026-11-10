---
title: Job-search workspace contract
type: reference
tags: [job-search, evidence, portability]
related:
  - "[[../SKILL]]"
  - "[[setup-contract]]"
---
# Workspace and evidence contract

Read this contract before using personal context in any Career Workbench skill. For pay-only research, read only the supplied role, location, currency, and pay preferences; do not open career records or the application log.

## Context and source authority

Use the current request, then the sources repository instructions route to. A workspace map is an optional locator, not a replacement for existing repository instructions. If both exist, use established owners; ask about a material unresolved conflict rather than silently changing storage or facts. Do not scan unrelated directories or Drive folders.

For a new setup the local locator is `.job-search.local/workspace.md` in the selected repository. It names each area's exact local path or verified Drive folder/document URL and ID, its factual owner, and the location of preferences. Existing setups need no new locator when routing already names those sources.

Resolve factual conflicts in this order: explicit user correction about the same claim; owning maintained career record; its supporting evidence; then resumes and other writing drafts. Preserve uncertainty and channel restrictions. Do not use modification time as factual authority. A user with only a CV can receive a bounded draft from that CV; label missing evidence and do not pretend a project was independently verified.

Keep personal contribution, team results, AI assistance, demonstrated proficiency, historical use, and learning goals distinct. Never invent a metric, title, credential, ownership, motivation, or outcome. A copied resume claim retains its original evidence status. A specific qualitative contribution or outcome is sufficient when there is no supported number. Estimates need a stated basis and user confirmation before external reuse.

## Storage and capabilities

Map these independently: career facts, supporting evidence, preferences, resume catalog, application log. Each may be local or in Google Drive. Use existing names and formats, including existing Docs or Sheets; do not require a `Resume_` naming convention. Read the catalog's referenced resumes rather than inventing filenames. Missing access or an unreadable source stays unknown, not empty or nonexistent.

Drive work requires the host's authenticated read/write capabilities for the selected resources; the package supplies neither a connector nor credentials. Read verified URLs/IDs returned by those tools. For new documents, follow the host's supported document-creation/import workflow and verify completed writes by readback. Never invent an ID or change sharing. If access is absent, explain the missing capability and wait on that portion; continue independent work without silently switching storage.

## Preferences and commuting

Seed defaults only during explicitly requested setup: country USA, currency USD, remote and local on-site/hybrid allowed, and US citizen proposed for confirmation. Until confirmed, citizenship remains unknown. Existing confirmed values override defaults. Never infer citizenship or authorization from employment history.

Ask the user for their home address and maximum one-way driving miles; there is no guessed mileage default. Keep the address only in a chosen local file, by default `.job-search.local/home-address.md`. Ensure the containing directory is Git-ignored before writing personal values. For a file outside a Git repository, keep it outside shared/exported folders. Never copy the address into Drive preferences, repository instructions, public outputs, or shared packages.

For local on-site/hybrid eligibility:

- Use a verified one-way driving route from the supplied home address to the actual workplace. Record the distance, route source, and check date; include only necessary location information in a route lookup.
- Distance at or below the user's limit passes the commute check; above it fails unless the user explicitly accepts relocation. Preserve other location/residency checks and stated dealbreakers.
- Missing address, limit, exact workplace, or verifiable route gives `Confirm First` for local eligibility. Do not substitute city centers, straight-line distance, or unsupported estimates.
- Remote-only work needs no driving-distance check, but residency, work authorization, travel, and other stated conditions still apply.

Keep the address local even if all five mapped areas use Drive. Do not rerequest an address already available in the routed private file. User prompts can change limits, location, work arrangements, pay preferences, and mappings. Persist a change when the user requests a saved preference change; a one-off comparison does not silently replace standing preferences. A new address, workplace, or limit requires reassessing affected commute results.

## Application history and action boundaries

Retain the review skill's prior-application check: an earlier application gives `Confirm First`; an explicit employer prohibition on reapplying gives `Don't Apply`; a tailored resume newer than the log is evidence to confirm. Consult the mapped log in its existing format. Unavailable history is unverified, never proof that the user has not applied.

Ordinary reviews read career context and return recommendations. They do not create records, edit resumes, start setup, submit applications, or write an application entry. For an explicit discovery/update request, the `career-context-builder` skill may write user-confirmed batches to the selected career/evidence owners and save an approved checkpoint. Ordinary task clarification does not authorize that persistence. Other skills draft or edit only as requested and preserve the identified target and source restrictions. A recommendation or draft is not an approved artifact or a submitted application.

For an explicit request to set up or reconnect a workspace, follow the [setup contract](setup-contract.md). Setup may create the selected workspace and routing; this does not authorize unrelated configuration changes, external publishing, or applications.

## Bundle dependencies

Install all 23 Career Workbench skills together. This shared workspace/setup contract belongs to the `job-posting-review` skill. The `career-context-builder` skill owns whole-career discovery, reviewed factual updates, and career/evidence templates; specialist skills retain focused task questions. Its entrypoint links here for source authority and storage, without starting setup again when routing is sufficient. The public bundle manifest declares the complete dependency set. The `resume-tailor` skill also needs the `job-description-analyzer` skill. The `job-description-analyzer` skill uses the review skill's audit, scoring, and retrieval references. The `job-posting-review` skill uses the `job-market-pay-research` skill when its pay trigger applies. A missing dependency must be reported; do not invent its method or install it during an ordinary review. No custom agent or paid scraper is required.
