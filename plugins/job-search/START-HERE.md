---
title: Career Workbench AI setup prompt
type: procedure
tags: [career, setup]
related:
  - "[[README]]"
---
# Start with your AI agent

Open the repository where you want to use Career Workbench. Supply the extracted bundle location, or identify the installed plugin, with this prompt:

```text
Set up Career Workbench in my selected repository. Read its guide and the
job-posting-review skill's setup and workspace contracts. For an extracted
bundle, these are skills/job-posting-review/references/setup-contract.md and
workspace-contract.md. Install all 23 sibling skills together for the agents
I use. Keep their references and license notices. Do not install a custom agent.

Guide me through choosing or connecting career facts, evidence, preferences,
a resume catalog and an application log. Let me choose local or Google Drive
locations independently, including mixed storage. Reuse existing routing and
records without migration. Do not make me edit configuration.

If I need help building my background, use the career-context-builder skill.
I may start with scattered documents, conversation, no resume or no target job.
Explore one experience at a time; review small batches before saving facts or
skill interpretations. Preserve sources, uncertainty, team/AI attribution,
proficiency boundaries and restrictions. Accept specific qualitative evidence.
Never invent a number or an outcome. Save an approved checkpoint if we stop.

Propose USA, USD, US citizenship and remote plus local on-site/hybrid work.
Confirm citizenship before treating it as a fact. Ask for my maximum one-way
driving miles. Keep my home address in a private local file.

Verify installed files, dependency references, available host discovery and
saved locations/documents by readback. Report unknowns and unavailable access.
Do not modify live resumes, send outreach or submit applications during setup.
```

Existing users can skip discovery when their maintained context is sufficient. Later prompts can enrich an existing record or change a preference without repeating setup. Managed Dev Center installations use their existing synchronization process.
