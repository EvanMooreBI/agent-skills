---
title: Career Workbench
type: guide
tags: [career, job-search, skills]
related:
  - "[[START-HERE]]"
---
# Career Workbench

Build a usable career background from conversation or scattered documents, then use it for job reviews, resumes, applications, outreach drafts, interview preparation and offer comparisons. All 23 skills share factual authority, qualitative-evidence acceptance and the same user-selected workspace. Start with the [AI setup prompt](START-HERE.md).

## Install and start

Install the complete `job-search` plugin, or extract `bundles/career-workbench.zip` from this repository and give its location and setup prompt to your AI agent. For a manual repository installation, copy **all 23 folders** under `skills/` together into `.agents/skills/` for Codex or `.claude/skills/` for Claude Code. Keep sibling names, references, templates and license notices intact. A single career folder may have missing dependencies. The combined ZIP is a repository installation bundle, not a single-skill upload for Claude's web settings.

The AI conducts setup; you do not need to edit configuration or run an installer. Python is not needed to use these prompt workflows. Web/Drive/document capabilities come from the host; no connector, credentials, custom Claude agent or hook is included.

Choose local or Google Drive storage independently for career facts, supporting evidence, preferences, the resume catalog and application history. Mixed storage and existing repository routing are supported without migration, a mandatory master resume or renamed documents. Authenticated Drive access and readback are required for cloud writes.

## Discover and use career context

Try "Help me untangle my work history; I do not have a current resume." The `career-context-builder` skill starts with one experience, proposes skills linked to actual examples, and reviews small batches before saving. It accepts attributed recollection, preserves uncertain dates, and can resume from an approved checkpoint. The [workspace contract](skills/job-posting-review/references/workspace-contract.md) defines authority and storage; the [setup contract](skills/job-posting-review/references/setup-contract.md) connects them.

Other prompts can include:

- "Add this project to my career context, separating my work from team and AI contributions."
- "Rewrite this bullet using the qualitative evidence; I have no measurements."
- "Review these jobs against my records and existing application history."
- "Practice an interview story from this experience without inventing a result."
- "Change my maximum one-way driving distance to 20 miles."

Specific qualitative contributions or outcomes are sufficient. Numbers are optional and must be supported; estimates need a documented basis and explicit confirmation. Current factual owners and user corrections outrank resumes and drafts. Specialists retain focused questions without starting a full interview. Drafting does not send outreach, submit an application, approve an artifact or authorize unrelated factual writes.

Setup proposes USA, USD, remote plus local on-site/hybrid and US citizenship; citizenship requires explicit confirmation. The user chooses a one-way driving-mile limit. The home address stays in a private local file even when the other records use Drive. Existing confirmed preferences override defaults.

## Maintenance and attribution

Dev Center is the development and maintenance source. Its publisher stages tested sources into the production agent-skills repository and generates the committed archive from that same tree. Source updates and fixes follow that release path. In a public checkout, `python tools/build_career_bundle.py --check` verifies exact archive freshness; `python tools/build_career_bundle.py` regenerates it after an intentional source change. Building needs Python 3.9+ and PyYAML; consumers do not need them.

The archive uses uncompressed ZIP entries and normalized text for reproducibility across platforms. Its manifest hashes every payload file. Reviewed blank-template hashes prevent accidentally shipping populated records; template changes require review before updating those pins. CI rejects stale/missing archives and unsafe inputs. File copies and structural checks do not prove host discovery or live Drive behavior.

See [provenance](provenance.json), [third-party notices](NOTICE.md), and the [MIT license](../../LICENSE). Derived skill folders retain the upstream notices so copying a folder preserves attribution.
