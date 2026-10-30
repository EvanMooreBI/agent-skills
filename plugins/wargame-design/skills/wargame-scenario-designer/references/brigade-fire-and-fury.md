---
title: Brigade Fire and Fury scenario presentation
type: skill-reference
tags: [wargame-scenario-designer, brigade-fire-and-fury, scenario-template]
related:
  - "../SKILL.md"
---
# Brigade Fire and Fury 2nd Edition

Read this reference before drafting or editing a Brigade Fire and Fury 2nd Edition scenario. It takes precedence over the generic output template, geometry requirements, and checklist for this rules system. Preserve the user's current document edits and explicitly selected terminology. Other systems retain their own formats and rules.

## Player document

Use the full name **Brigade Fire and Fury 2nd Edition**, never its shorthand. Call reinforcements a **group** or **reinforcing group**, never a packet. Preserve historical names, OOB values, arrival turns, VP values, exceptional status, and source links unless a change is authorized.

Default section order: Scale; The scenario; Terrain; Setup; Deployment; Reinforcements; Game length; Union order of battle; Confederate order of battle; Miniatures required; Victory conditions; Objective control; Rating and artillery notes; Sources. Match a supplied example's typography and retained sections. Never add a Project References section. Sources is the historical bibliography and must remain distinct from internal authoring references.

Use feet for overall table dimensions, such as **8 × 5 feet**. Use inches for supported on-table distances and dimensions. Use bold sentence lead-ins for explanatory paragraphs, such as **Union cavalry.** or **Greater Losses Victory Condition.** Bold only the subject and its terminal period, not the entire paragraph.

Use this playing-time sentence with the scenario's values:

> Target playing time is {duration} hours with {player range} players familiar with Brigade Fire and Fury 2nd Edition, not including setup.

When the scenario is unplaytested, put the following in an **actual repeating document footer**, centered, italic, 8-point text. Do not place it at the end of Game length or simulate a footer with body text. Check every page, including the first page. If native footer formatting is unavailable, report that limitation explicitly. Replace the status only when playtest evidence warrants it.

> This is an unplaytested scenario; the duration and balance remain design estimates.

## Map prerequisite

Determine whether an accepted, completed map exists before finalizing Terrain or any map-dependent deployment, entry, orientation, objective-location, or contact-timing detail.

- **Map complete:** derive feature sizes, deployment areas and entries from that map. Each table-edge location or entry measurement names the table edge, starting reference and measuring direction. For example, an entry can be on the north edge, measured 30 inches eastward from the northwest corner, toward the center. Use named features and edge-based prose; never raw x/y coordinates or an invented coordinate grid. Verify that the wording matches the map and its sources.
- **Map pending:** leave exact geometry for the map-making agent. Do not create a map or substitute an invented measured battlefield. Give only source-supported relative relationships needed to understand the scenario. Label counterfactual approaches as scenario intentions. Retain table dimensions and non-spatial rules. Do not assert a table compass orientation, precise entry sector, separation, objective spacing, or movement/contact timing that depends on an unfinished map.
- Record a separate map-agent handoff in the task's planning/research artifact, outside the player document. Include source links and relevant pages/passages, supported relationships, deliberate counterfactuals and unresolved placement questions. Preserve the player's Sources bibliography. Do not reintroduce map details the user removed.

A map-pending draft can pass content review with the handoff complete, but cannot be described as a fully mapped, setup-ready scenario. Geometry-dependent QA remains deferred, not passed by assumption.

## Division and independent-command template

Use this block for every division or equivalent independent command. Preserve any genuine higher-command hierarchy in the heading. The commander line precedes the table; all division-specific notes follow it as native bullets. Put leader arrival information in those notes when needed.

### {Parent command} • {Division or independent command}

Division Commander: {Name}, {Ordinary or Exceptional}

| Commander / unit | Type | Quality | Effectiveness | Weapon | Arrival |
|---|---|---|---|---|---|
| {Commander and E if applicable} | {Type} | {Quality} | {Full rating} | {Official weapon code} | {Arrival} |

- {Division-specific note.}
- {Additional division-specific note.}

Keep Effectiveness as one paragraph in its header cell, with no extra blank paragraph. Adjust column widths rather than inserting manual line breaks into the label. Preserve full rating values and machine-readable label content. Do not invent an infantry-style effectiveness profile for batteries.

After the side's OOB, use these summary labels. Keep its existing composition and total; Heavy Casualties has only the numeric threshold after the colon.

**Combat Strength:** {composition and total}

**Heavy Casualties:** {threshold}

In Miniatures required, list gun stands with numeric side counts only. Do not add limbers as +N or include a second limber count; they are assumed markers. Preserve required infantry, mounted cavalry, dismounted cavalry, horseholder and leader counts without explaining their routine replacement mechanics.

## Victory templates

Write one native bullet per VP condition, followed by the win/draw rule. Put any condition-specific explanation below the list with a bold sentence lead-in. Parameterize objective names, scoring turn and VP values; do not copy them from another battle.

### Heavy Casualties Modifier

Preserve this user-approved template's wording and formatting. **Greater Casualties** is the selected modifier wording; do not silently substitute **Greater Losses**. The distinct scoring lead-in **Greater Losses Victory Condition.** may remain. Parameterize side names and thresholds. This template does not prescribe a universal casualty percentage.

**Heavy Casualties Modifier.** Once a side reaches Heavy Casualties, apply the Heavy Casualties modifier to its brigades. If a side with Heavy Casualties also has more total casualties overall than their opponent, they suffer from Greater Casualties modifier.

- **{Side A} losses**: {threshold A} stands.
- **{Side B} losses**: {threshold B} stands.

### Objective control

Use the following template, substituting the objective count, last player side and control radius. Preserve explicitly approved scenario variations. Check timing against that scenario's turn order. Do not add a geometry-dependent claim that control areas do not overlap unless a completed map establishes it.

All {objective count} objective points start neutral. Check control after the {last player side} player turn, when both sides have completed the turn. A brigade qualifies if it is not broken and at least one complete troop stand lies wholly within {control radius} inches of the objective point.

Infantry and both mounted and dismounted cavalry qualify. A horseholder marker alone does not. Artillery and leaders cannot capture or contest. Disorder does not prevent an otherwise eligible brigade from doing so.

If only one side has qualifying troops in the control area, it captures the objective. If both sides qualify, the objective is contested and ownership does not change. If neither qualifies, ownership also remains unchanged.

A captured objective remains controlled after its owner leaves. An objective contested while still neutral remains neutral. At the final check, a contested objective awards its VP to its previous owner; a neutral objective awards none. A complete stand can qualify for only one objective.

## Remove core-rule repetition

Players know the core rules. Omit the following explanations, including paraphrases, from the scenario:

- Routine one-gun-stand-per-battery, limber-marker and brigade-command-stand counting explanations.
- Statements that leaders, replacement models or horseholders are not extra combat strength, and arithmetic explaining cavalry replacement or effectiveness on dismounting.
- Reminders that units cannot overlap or pass through enemy stands, or that delayed units keep assigned frontages.
- Generic reminders about ordinary mounted/dismounted tactics or absent special rules.

Keep actual scenario exceptions and decisions: temporary battery attachments, unusual command representation, off-table commanders, starting status, first player, arrival availability, and evidence-based rating judgments. The casualty and objective templates above are intentional approved inclusions.

## Review before delivery

Verify all command blocks, native bullets and bold lead-ins, Effectiveness headers, gun counts, and totals against the approved OOB. Review the whole document for redundant core-rule explanations, shorthand and stale map claims. Confirm map-complete or map-pending acceptance explicitly. Inspect the native footer object and a fresh rendered export on every page. A text-only check does not prove formatting.
