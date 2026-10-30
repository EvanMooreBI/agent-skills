---
name: wargame-scenario-designer
description: Use when creating, adapting, or critiquing miniature wargame scenarios, including historical battles, convention or solo games, OOBs, terrain, deployment, victory conditions, special rules, and force balance.
license: MIT
metadata:
  author: EvanMooreBI
  version: "1.0.0"
---

# Wargame Scenario Designer

## Purpose

Produce complete, playable miniature wargaming scenarios with narrative context, terrain setup, orders of battle, victory conditions, special rules, and design notes. Prefer playable tactical problems over point-balanced force lists.

## Required Workflow

1. Check local resources as described in Local resources below.
2. Intake: identify rules system, period, battle or premise, available miniatures, terrain, table size, players, session length, experience level, scenario type, and campaign/solo/convention context.
3. Ask only for critical missing information. Always ask for the rules system if it is not provided and cannot be inferred. Never ask more than 3 questions at once.
4. Infer reasonable defaults from context and state assumptions explicitly.
5. Read source/applicability, core principles, and relevant context in [the design patterns](scenario-design-patterns.md). Design the mission, OOB, terrain, deployment, victory conditions, asymmetry, special rules, and time structure. Check both sides' decisions, player participation, and objective feasibility.
6. Research historical TO&E, specific units, geography, and named rules-system conventions when needed. Do not guess historical OOBs, equipment, terrain, or official game terminology.
7. For Brigade Fire and Fury 2nd Edition, first read [its required reference and templates](references/brigade-fire-and-fury.md). For other systems, use `scenario-output-template.md`, adapting depth to scenario scale.
8. Run `design-checklist.md` before delivering and fix issues found.

For the full phase-by-phase process, context-specific guidance, system adaptation rules, and anti-pattern table, read `references/scenario-workflow.md`.

## Resource Routing

Read only the files needed for the task:

Map appearance follows the V32 map standard in the `wargame-scenario-map-making` skill, including terrain, labels, frame, north arrow and dimension logic. That skill applies the presentation without changing geography or native rules.

- `references/brigade-fire-and-fury.md`: mandatory Brigade Fire and Fury 2nd Edition presentation, OOB/victory templates, map prerequisite, footer and redundancy rules. These override conflicting generic instructions for that system.
- `references/scenario-workflow.md`: detailed workflow, context-specific guidance, rules-system adaptation, presentation matching, and anti-patterns.
- `scenario-design-patterns.md`: design theory, scale and period guidance, terrain density, solo AI options, and rules-of-thumb.
- `references/further-reading.md`: the source articles behind the design guidance, with links. Their preferences and period examples are not universal requirements.
- `scenario-output-template.md`: required scenario document structure.
- `design-checklist.md`: final QA checklist.
- `oob-equipment-conventions.md`: equipment naming, troop quality, and routing to period equipment references.
- `references/equipment-wwii.md`: WWII weapons, FOW team types, and vehicle designations by nation.
- `references/equipment-horse-and-musket.md`: ACW and Horse & Musket weapon codes, labels, and grand tactical stat tables.
- `references/equipment-modern.md`: post-WWII and modern individual weapons.
- `scenario-examples/*.md`: layouts of publisher and community scenario formats, described in original words. Prefer a publisher format over the generic template when one matches.

## Local resources

This skill can use files it cannot ship because others hold their copyright. [local-resources.json](local-resources.json) lists them. Both are optional.

At the start of a task, look for each resource in `$AGENT_SKILLS_LOCAL/wargame-scenario-designer/<id>/`, then in `~/.agent-skills/local/wargame-scenario-designer/<id>/`. Tell the user which resources are missing and what the manifest's `whenMissing` says will change, then continue.

- `rules-quick-reference`: the user's own quick-reference sheet or rule summary for the target rules system. Read it before using rules terminology, ratings, or terrain effects.
- `design-articles`: the user's saved copies of the articles in `references/further-reading.md`.

Set up a missing resource with the user:

1. If neither folder exists, create `~/.agent-skills/local/wargame-scenario-designer/<id>/` for each resource, or the same layout under `AGENT_SKILLS_LOCAL` when it is set. Tell the user the full path of each folder.
2. Tell the user what to put in each folder, using the manifest's `purpose`, `howToObtain` and `expectedFiles`. Never download or copy third-party material for the user. They supply their own copies.
3. If the user keeps these files somewhere else, offer to set `AGENT_SKILLS_LOCAL` to that folder and set it only after they agree. On Windows, run `[Environment]::SetEnvironmentVariable('AGENT_SKILLS_LOCAL', '<folder>', 'User')` in PowerShell. On macOS or Linux, add `export AGENT_SKILLS_LOCAL='<folder>'` to the shell profile. The folder must keep the `<skill-name>/<id>/` layout.
4. Check the folders again once the user says the files are in place.

## Rules-System Matching

When the user names a rules system, use that system's official terminology, activation method, deployment method, OOB format, quality/morale ratings, terrain taxonomy, and victory framing.

Use these primary examples when relevant:

- Brigade Fire and Fury 2nd Edition: `references/brigade-fire-and-fury.md` before the generic template or period examples.
- Regimental Fire and Fury: `scenario-examples/acw-regimental_fire-and-fury_official.md`
- FOW, NAM, Team Yankee, Checkpoint Charlie, Fate of a Nation: relevant `scenario-examples/wwii-company_flames-of-war_*.md`
- Fireball Forward: `scenario-examples/wwii-company_fireball-forward_official.md`
- Battlefront WWII: `scenario-examples/wwii-battalion_battlefront-wwii_unofficial.md`
- Black Powder / Hail Caesar: `scenario-examples/horse-and-musket_black-powder_unofficial.md`
- TFL-style games: `scenario-examples/vietnam-platoon_any-system_unofficial.md`

If no matching system or period exists, use `scenario-output-template.md`.

## Non-Negotiables

- Victory conditions must be objective-based, not only elimination-based.
- The historically losing side must have a viable path to victory.
- For Brigade Fire and Fury 2nd Edition, follow the reference's map-complete/map-pending acceptance; do not invent text-only geometry while its map is pending. Other systems retain text-only setup with orientation, measurements and game effects.
- Provide meaningful tactical choices for both sides. If the mission requires a single approach or chokepoint, provide feasible choices in timing, support, reserves, or objectives.
- OOBs must name specific equipment at the right scale.
- Use no more than 3 special rules unless the user explicitly requests complexity.
- Do not override a rules system's native deployment or turn-ending mechanics.
- Do not use FOW mission format as a universal default for all WWII or modern scenarios.
