---
title: Scenario output template
type: skill-reference
tags: [wargame-scenario-designer, scenario-template]
related:
  - "SKILL.md"
  - "design-checklist.md"
---
# Scenario Output Template

For Brigade Fire and Fury 2nd Edition, use [the mandatory system reference and templates](references/brigade-fire-and-fury.md) instead of this generic format. Its map-complete/map-pending prerequisite overrides every measured-terrain, grid, text-only setup and precise-entry requirement below. Other systems retain these conventions.

Every scenario produced by this skill should contain the following sections in order. Sections marked **[OPTIONAL]** may be omitted when not applicable. Sections marked **[CONDITIONAL]** are included only for specific scenario types noted in brackets.

Adapt section depth to the scenario's scale and complexity. A squad skirmish scenario needs a lighter touch than a grand tactical historical recreation.

Include player-facing instructions only where players need them. Keep source uncertainty, calibration reasoning, and command-allocation analysis in designer or umpire notes. Preserve any system-specific presentation overrides.

---

## 1. Title and Header

```
# [Evocative Scenario Title]

**Period:** [e.g., Normandy, June 1944 | Frostgrave | Horus Heresy]
**Scale:** [e.g., Platoon | Company | Grand Tactical]
**Rules System:** [e.g., Chain of Command | Bolt Action | System-agnostic]
**Players:** [e.g., 2 | 2-4 | 2-6 with umpire]
**Estimated Play Time:** [e.g., 2-3 hours. State whether setup and briefing are included]
**Table Size:** [e.g., 6' x 4' | 3' x 3']
```

---

## 2. Historical or Narrative Background

2-4 paragraphs establishing context. Structure as:

1. **Strategic situation** — What is happening in the broader conflict? Why does this engagement matter?
2. **Immediate situation** — What has led to this specific moment? What are the forces doing here?
3. **The tactical problem** — End with the decision point the players will resolve. This is the scenario's "hook."

For historical scenarios, name real units, commanders, dates, and locations. For fictional scenarios, establish the world, stakes, and what makes this engagement distinctive.

---

## 3. Terrain Layout and Map

### Table Map (Highly Recommended)

Map artwork and all labels, north arrows, symbols, frame and measurement logic follow the V32 map standard in the `wargame-scenario-map-making` skill, across systems and seasons. Keep native scenario rules and geography separate from presentation.

If the AI tool supports image generation or simple sketching, include a **top-down sketch of the game table** showing:
- Table outline with dimensions
- External right-margin north arrow preserving actual north
- Major terrain features (approximate shapes and positions)
- Deployment zones (shaded or labeled areas with measurements)
- Objective locations
- Entry points for reserves/reinforcements
- Key reference points (labeled A, B, C or named landmarks)

If image generation is not available, fall back on a detailed text description precise enough to set up the table from description alone. All terrain positions and deployment zones MUST use **inch measurements** from table edges.

### Format

1. **Table dimensions and orientation** — State dimensions (e.g., 6' x 4' / 72" x 48") and which edge is North. All subsequent directions reference this.
2. **Optional prose sectors** — Maps use V32 faint 12-inch grid lines and complete bottom/left rulers. Use broad named sectors only to help setup prose, without adding a labeled tactical grid or smaller subdivisions. Prose sectors may use:
   - Quadrants: NW, NE, SW, SE
   - Sixths: numbered 1-6 or named
   - Compass sectors: "the northern third," "the eastern half"
3. **Terrain feature list** — Every terrain piece MUST include: position in inches from table edges, approximate dimensions in inches, and gameplay-relevant attributes. "A woods 24" from the NE edge" is NOT sufficient.

```
**[Feature Name]** — [Terrain type] ([attributes]). Located [X]" from [edge], [Y]" from [edge].
Approximately [W]" x [D]". Game effect: [movement, LOS, cover specifics].
```

**Examples:**
- **Stone Farmhouse** — Building (stone, hard cover). Located 24" from the southern edge, 18" from the western edge. Approximately 4" x 3". Blocks LOS, holds one squad.
- **Dense Woods** — Woods (tall — blocks LOS, can only see 2" into terrain). Located 16" from the northern edge, centered on the table. Approximately 10" x 8".
- **Wheat Field** — Crops (tall — blocks LOS for infantry, vehicles can see over). Located 36" from the southern edge, 24" from the western edge. Approximately 6" x 8".

4. **[OPTIONAL] Terrain substitutions** — Suggest alternatives for pieces the user may not own.

### Terrain Description Conventions

- **Declare which table edge is North first** — before any terrain description. Every directional reference depends on this. Without it, the scenario is ambiguous.
- Use compass directions consistently (not "left" or "right")
- **All measurements in inches** from table edges: "12" from the southern edge", not "about a third of the way up"
- Describe linear features by endpoints with measurements: "A stone wall runs east-west from 18" to 36" from the western edge, along the 30" line from the southern edge"
- For dense terrain, describe the overall character first, then individual features

### Terrain Attribute Specification

Every terrain feature must have its gameplay-relevant attributes explicitly defined. Do not assume the player knows whether a field blocks LOS or a hill is gentle.

| Terrain Type | Attribute | Effect |
|---|---|---|
| **Fields/Crops** | Tall (wheat, corn) | Blocks LOS for infantry; vehicles see over |
| | Short (grass, stubble) | Concealment only, does not block LOS |
| | Ploughed/Bare | Open ground, no cover or concealment |
| **Hills** | Level 1 (gentle) | Standard hill; no movement penalty unless specified |
| | Level 2 (commanding) | Models see over most other terrain; use sparingly |
| | Rough/Steep slope | Movement penalty, possible difficult terrain |
| **Woods** | Dense/Tall | Blocks LOS beyond 2" in; difficult terrain for vehicles |
| | Open/Scattered | Limited visibility (e.g., 24" max), light cover |
| **Hedges** | Tall/Bocage | Blocks LOS, hard cover (typical Normandy) |
| | Low | Concealment only |
| **Buildings** | Stone/Brick/Wood/Thatch | Material determines cover value; specify stories for elevated LOS |
| **Fortifications** | Earth Bunker | Hard cover, destructible |
| | Concrete Bunker | Very hard cover, extremely hard to destroy |
| | Trenches | Hard cover for infantry; specify length and orientation |
| | Foxholes | Individual hard cover positions |
| | Barbed Wire | Obstacle slowing/stopping infantry; specify length |
| | Minefields | Specify type (AP, AT, mixed) and area |

**Battlefront systems (FOW/NAM/Team Yankee/Checkpoint Charlie/Fate of a Nation):** Use official taxonomy — **Tall** (blocks LOS, see only 2" in) and **Short** (concealment only). These replace generic height descriptions.

---

## 4. Forces

Present one section per side. Within each side, follow this structure:

### Side [A/B]: [Force Name]

**Commander:** [Name] — [Quality/Command rating if applicable]

**Force Organization:**

Organize hierarchically matching the game scale. **Always name specific equipment** — consult `oob-equipment-conventions.md` for the full taxonomy of team types, weapon names, and vehicle designations.

- **Skirmish (5-15 models):** List each model individually with name, specific weapons (e.g., "Kar98k", "Thompson M1A1", not "rifle" or "SMG"), stats, and any special abilities.
- **Platoon (20-60 models):** Group by squad/section. Name weapons per squad: primary weapon type, automatic weapon (e.g., "Bren Mk I", "BAR M1918A2"), and special weapons (e.g., "PIAT", "Panzerfaust"). Name all transport vehicles by specific type (e.g., "Sdkfz 251/1 Hanomag", not "half-track").
- **Company/Battalion:** Group by platoon/company. Use FOW-style team type labels (Rifle team, Rifle/MG team, MG team, SMG team, Pioneer team, HMG team, Mortar team, etc.). Name gun teams by specific weapon (e.g., "7.5cm PaK 40 Anti-Tank Gun", "25-pdr Field Gun"). Name all vehicles by specific variant (e.g., "Sherman V 75mm", "Panzer IV H", not "Sherman" or "Panzer IV").
- **Grand Tactical:** Group by brigade/regiment. Use stat-line tables when the rules system calls for them. Armament column uses aggregate weapon types (e.g., "Rifled Musket", "6-pdr Smoothbore"):

```
| Unit | Type | Armament | Hand-to-Hand | Shooting | Morale | Stamina | Special |
|------|------|----------|--------------|----------|--------|---------|---------|
```

**[OPTIONAL] Variable Forces:**
Units whose availability is determined randomly or by scenario card. Present as a table:

```
| Roll | Result | Details |
|------|--------|---------|
| 1-2  | [Option A] | [Composition and where they deploy] |
| 3-4  | [Option B] | [Composition and where they deploy] |
| 5-6  | [Option C] | [Composition and where they deploy] |
```

When the user specifies a rules system, format OOBs using that system's conventions. When system-agnostic, use descriptive force organization with quality ratings (Elite / Veteran / Experienced / Trained / Green).

### [CONDITIONAL: Solo/Coop/Multiplayer] Side C: Neutral or AI Forces

For non-player forces, specify the AI activation system they use and any behavior rules.

---

## 5. Deployment

Deployment zones MUST be detailed with precise measurements and any restrictions or additional rules.

- **Deployment order** — Which side deploys first? Simultaneous? Hidden?
- **Deployment zones** — Each zone must specify:
  - **Boundaries in inches** from table edges (e.g., "within 12" of the southern table edge" or "in the NE table quarter, at least 8" from both centerlines")
  - **Dimensions** of the zone (e.g., "a 24" x 12" strip along the northern edge")
  - **Restrictions** on what can deploy there (e.g., "infantry and gun teams only; no vehicles", "up to 60% of force")
  - **Starting status** of deployed units (e.g., "all infantry start in foxholes", "vehicles start with engines off")
  - **Facing/formation restrictions** if any (e.g., "all units deploy in line formation facing north")
- **Hidden deployment rules** — If applicable, how hidden units are recorded and revealed.
- **[CONDITIONAL: hidden deployment] Preparation** - Provide native recording and reveal instructions. If private maps are needed, match them to the table. Identify any umpire role. Separate player and umpire information.
- **Pre-game mechanics** — Patrol phases, bidding, scouting, or reconnaissance steps.
- **Reinforcement schedule** — Which units arrive on which turn, at which entry point, under what conditions.
- **[CONDITIONAL: multiplayer] Command assignments** - Identify opening commands and reserve-control assignments on arrival. Keep any communication restrictions explicit.

Format reinforcements as a table when there are multiple entries:

```
| Turn | Unit | Entry Point | Conditions |
|------|------|-------------|------------|
```

---

## 6. Victory Conditions

### Primary Objective(s)

State each objective clearly with its VP value (if using points) or pass/fail criteria.

For an exit objective, state the qualifying units, number required, permitted exits, and scoring time. For casualty constraints, define counted losses. Follow native rules and avoid ambiguous thresholds.

### [OPTIONAL] Secondary Objectives

Additional goals worth fewer points or providing tiebreakers.

### Victory Threshold

Present as a table for clarity:

```
| Victory Level | Side A Condition | Side B Condition |
|---------------|------------------|------------------|
| Total Victory | [condition] | [condition] |
| Major Victory | [condition] | [condition] |
| Minor Victory | [condition] | [condition] |
| Draw | [condition] | [condition] |
```

For simpler scenarios, a single pass/fail condition per side is sufficient.

### Game End

State how the game ends. The method must match the rules system:

- **Fixed turn limit:** "The game ends after Turn 8." Use when the system has predictable turn structure (e.g., Flames of War, Black Powder).
- **Random ending:** "From Turn 6 onward, roll a d6 at the end of each turn; the game ends on a 4+." Use for systems with variable game length.
- **Card/dice-driven ending:** "The game ends when the Turn End card is drawn for the third time" or "when one side's Force Morale reaches 0." Use for systems like Chain of Command, Sharp Practice, or Bolt Action where turns end unpredictably.
- **Break-point:** "The game ends when one side has lost 50% of its units." Use for attrition-focused scenarios.
- **Objective-triggered:** "The game ends immediately when [condition] is achieved." Use for time-pressure scenarios.

**For systems with random or card-driven turn endings**, victory conditions must work regardless of *when* the game ends. Use "at end of game" or "when the game ends" rather than "on Turn 6." Design objectives that create tension at any point — not conditions that only matter on a specific turn.

State how the result is scored if the real session ends early. Preserve native mechanics where possible. Allow a draw when appropriate.

---

## 7. Special Rules

Maximum 3 rules. Each rule follows this format:

**[Rule Name]:** [Clear mechanical description of how it works — what triggers it, what it changes, any dice rolls involved.]

*Design intent: [One sentence explaining WHY this rule exists — what player decision or period flavor it creates that the base rules cannot provide.]*

---

## 8. Player Briefings [OPTIONAL — recommended for asymmetric scenarios]

Produce a separate briefing per side. Each briefing contains only what that side would know. Written in second person ("You are Captain Williams, commanding B Company...") or first person from the commander's perspective.

### Briefing Structure

1. **Situation** — What the commander knows about the strategic and tactical situation
2. **Enemy** — What intelligence (accurate or not) the commander has about opposing forces
3. **Mission** — What the commander has been ordered to accomplish
4. **Own forces** — The units under the commander's control (reference the Forces section)
5. **Special instructions** — Any constraints, rules of engagement, or additional orders

For scenarios with hidden information, mark umpire-only details clearly: **[UMPIRE ONLY: ...]**

---

## 9. Designer's Notes [OPTIONAL]

- **Intended dynamics** — How the scenario is expected to play out and what makes it interesting
- **Historical outcome** — What actually happened (for historical scenarios), so players can compare
- **Balance adjustments** — Suggestions for tilting the scenario if one side wins consistently
- **Adaptation notes** — How to adapt the scenario for different rules systems, scales, or figure collections
- **Playtesting observations** — If the scenario has been tested, what was learned
- **Source limits** - Distinguish supported facts, historical estimates, model substitutions, and deliberate terrain adaptations.
- **Calibration** - Separate session duration, simulated duration, and task opportunities. Note early-contact assumptions and exit/casualty feasibility. Mark untested duration and balance as estimates. Record observed timings when available.
- **[CONDITIONAL] Preparation and participation** - List required maps, data sheets, player aids, and equipment. Record setup/briefing allowances and multiplayer activation or sector-coordination arrangements. Keep hidden information in umpire notes.

---

## 10. Quick Reference Card [CONDITIONAL: convention and large multiplayer games]

A single-page summary for each player containing:

- Turn sequence reminder (scenario-relevant steps only)
- Scenario-specific modifiers pre-calculated
- Victory conditions summary (2-3 sentences)
- Special rules summary (one line each)
- Key stats for the player's units (condensed from the Forces section)
