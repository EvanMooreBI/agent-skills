---
name: wargame-scenario-map-making
description: Use when creating, regenerating, or revising a tabletop miniature wargame scenario map.
license: MIT
compatibility: The bundled validator needs Python 3.9 or later.
metadata:
  author: EvanMooreBI
  version: "1.0.0"
---

# Wargame Scenario Map Making

## Core Principle

A scenario map is a **rules artifact first, illustration second**. The current scenario document and researched terrain topology are authoritative. Do not let image generation invent geometry, measurements, rules, roads, or force placement.

Use the [V32 scenario map standard](references/scenario-map-style.md) for all terrain art, typography, markings, frame and measurement logic, across systems and seasons. It overrides conflicting generic presentation defaults. Never use another publisher's map art as a style reference or image-generation input.

Read [terrain labels and objective markings](references/map-labels.md) and [measurements and north marker](references/map-markings.md). If the optional `v32-reference-art` resource is present, inspect it before production. Adapt seasonal vegetation within this style; derive geography and native effects from the scenario. Types absent from V32 need explicit V32-consistent resolution.

For a renderer that reads a JSON map source, apply the [V32 presentation preset](assets/v32/presentation-v32.json) and run the [conformance validator](assets/v32/validate_presentation.py) before export and delivery. Other renderers must show equivalent output. The validator needs Python 3.9 or later. If `python --version` and `python3 --version` both fail, tell the user the conformance check cannot run, point them to https://www.python.org/downloads/, and review the presentation settings by hand against the preset until Python is installed.

## Local resources

[local-resources.json](local-resources.json) lists files this skill can use but does not ship. Both are optional. At the start of a task, look for each one in `$AGENT_SKILLS_LOCAL/wargame-scenario-map-making/<id>/`, then in `~/.agent-skills/local/wargame-scenario-map-making/<id>/`. Tell the user which resources are missing and what the manifest's `whenMissing` says will change, then continue.

- `map-fonts`: Times New Roman regular and italic, or a documented fallback.
- `v32-reference-art`: a finished map drawn to V32, used as a visual reference. A README in the folder may point to where the files are kept.

Set up a missing resource with the user:

1. If neither folder exists, create `~/.agent-skills/local/wargame-scenario-map-making/<id>/` for each resource, or the same layout under `AGENT_SKILLS_LOCAL` when it is set. Tell the user the full path of each folder.
2. Tell the user what to put in each folder, using the manifest's `purpose`, `howToObtain` and `expectedFiles`. Never download or copy third-party material for the user. They supply their own copies.
3. If the user keeps these files somewhere else, offer to set `AGENT_SKILLS_LOCAL` to that folder and set it only after they agree. On Windows, run `[Environment]::SetEnvironmentVariable('AGENT_SKILLS_LOCAL', '<folder>', 'User')` in PowerShell. On macOS or Linux, add `export AGENT_SKILLS_LOCAL='<folder>'` to the shell profile. The folder must keep the `<skill-name>/<id>/` layout.
4. Check the folders again once the user says the files are in place.

## Workflow

1. **Source-lock first.** Re-read the current scenario/OOB immediately before mapping. Record exact table size, orientation, ruleset scale, turns, force totals, starting formations, reserves, reinforcement turns/edges, victory objectives, terrain rules, and the latest accepted historical/visual map baseline.
2. **Separate evidence levels.** Keep historical facts, scenario design decisions, and cosmetic abstractions distinct. Never present an abstraction as documented history.
3. **Freeze terrain topology.** Once roads, lanes, streams, crossings, settlements, major clearings, and objectives are researched and accepted, treat them as immutable unless new evidence or an explicit user change requires otherwise. A text/OOB correction is not permission to redesign the road network.
4. **Build a true-scale battlefield viewport.** The playable rectangle must have the physical table's exact aspect ratio. Use the accepted compact white surround without sidebars or repeated rule summaries.
5. **Place zones by scenario logic, not graphic convenience.** A road is not automatically a deployment boundary. If a formation operates astride it, its zone must straddle it.
6. **Distinguish deployment from reinforcement.** Starting formations get deployment/support zones. Later off-table formations get entry arrows/frontages, not shaded starting zones. Forces that never enter get no map zone.
7. **Render last.** Prefer deterministic SVG/Python/vector overlays for rulers, zone polygons, measurements, labels, legends, and entry arrows; use image generation primarily for terrain artwork/style. For a localized correction, edit the existing image rather than regenerating the entire map.
8. **Validate against the scenario before handoff.** Any mismatch is a specification failure, not a cosmetic issue.

## Scale and Measurement Contract

For table `TW × TH` inches and battlefield viewport `PW × PH` pixels:

`PW / TW = PH / TH`

Pixels per table inch must be equal horizontally and vertically.

**Example: 72" × 60" = 6:5.** A 1200 px-wide battlefield viewport must be 1000 px high. On that table:

| Measurement | Required visual proportion |
|---|---:|
| 18" horizontal | 25% of battlefield width |
| 24" vertical | 40% of battlefield depth |
| 8–10" gap | 11.1–13.9% of width |
| 4–6" gap | 5.6–8.3% of width |

Never eyeball a dimension and then label it as measured.

Use whole-inch setup geometry. Put zone width above and depth left of its outline; omit interior dimension crosshairs. Use detached double-headed inset arrows with 2 mm reference-print tip clearance. Objective guides use the nearest edge independently per axis, with left/bottom ties. Irregular zones need reproducible measured vertices; a bounding box alone is insufficient.

## Historical Terrain Rules

- Preserve accepted road/stream topology across revisions.
- Do not add plausible-sounding roads, turnpikes, farms, streams, or place names.
- Do not merge distinct historical roads because they run similarly.
- Preserve relationships such as a church/objective being on or adjacent to a specific road.
- Scattered small clearings are appropriate only when consistent with the historical terrain character; they should not turn dense terrain into open country.
- For historical changes, verify against authoritative sources such as NPS/battlefield maps, Official Records, or official scenario/rules publications.

## Scenario Integrity

The map inherits the finalized scenario. Do not guess or silently change:

- turn limit or represented time;
- OOB/stand totals;
- reinforcement schedule;
- casualty thresholds;
- VP values;
- ruleset terrain effects.

If a shorter game is required, scenario design should deliberately reduce formations, stagger arrivals, shorten objective distances, or narrow the represented sector rather than falsifying map scale.

Only print rules that are verified. Never invent a realistic-sounding restriction (for example, an artillery-unlimber prohibition) unless it is actually a normal rule or an explicit scenario special rule.

**Ratio is not ration.** Aspect ratios, proportions, and measurements must never become supply/ration/ammunition rules. Do not add logistics panels unless the scenario actually uses them.

## Recommended Map Content

Show the compact title, solid 12-inch grid at 25 percent opacity and approximately 0.71 pt reference-print weight, bottom/left rulers, external true-bearing north arrow, relevant terrain names, objective stars/guides, deployment dimensions/offsets and permitted entry/exit markings. Keep rule summaries, OOBs and development notes in supporting records. Preserve editable markings.

## Pre-Handoff Checklist

- [ ] Battlefield viewport has exact table aspect ratio; horizontal/vertical pixels-per-inch match.
- [ ] Edge rulers/dimensions are correct.
- [ ] Road/lane/stream topology matches the approved baseline; no phantom named features.
- [ ] Zones are on the correct side(s) of terrain and straddle roads when intended.
- [ ] Exterior zone dimensions, inset arrows and objective guides mathematically match their labels.
- [ ] Reinforcement formations use correct arrows, turns, and entry edges; non-participants have no zones.
- [ ] Turn count, play-time text, force totals, stand scale, casualty thresholds, objectives, and VP values match the current scenario.
- [ ] Terrain notes contain no invented rules and no accidental ration/ammunition/logistics text.
- [ ] Labels are legible and mutually consistent.
- [ ] Seasonal vegetation and depicted snow match the scenario/player brief within V32; appearance establishes no native rule.
- [ ] All artwork and markings follow V32; presentation conformance and actual PNG/PDF readability are checked. No other publisher's map art was used as input.

## Common Failure Modes

| Failure | Required correction |
|---|---|
| Map claims 72" × 60" but viewport is not 6:5 | Rebuild the battlefield viewport at true ratio. |
| Dimensions were visually estimated | Recalculate from table inches and viewport scale. |
| Roads change during regeneration | Restore approved topology; edit only requested elements. |
| Zones all fall on one side of a road | Re-check whether formations should straddle it. |
| Reinforcement receives a deployment zone | Replace it with an entry arrow/frontage. |
| Old turn/OOB/VP data survives a rewrite | Re-read current scenario, then update every dependent label. |
| Generator invents a rule or named feature | Remove it unless verified. |
| “Ratio” becomes “ration” | Remove logistics text and restore scale terminology. |
| Fixing one item breaks several others | Use localized editing or deterministic overlays. |

## Worked Example Pattern

On a 72" × 60" west-east battlefield, an 18" × 24" starting zone must occupy 25% of width and 40% of depth. An opposing 18" × 18" zone separated by 8–10" must visually preserve those proportions. If both formations deploy astride the main road, both zones cross it. A later reserve entering from the east gets an east-edge reinforcement arrow, not another shaded zone. An objective historically adjacent to the main road remains adjacent through every revision.
