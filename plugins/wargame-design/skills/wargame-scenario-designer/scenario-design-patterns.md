---
title: Scenario design patterns
type: skill-reference
tags: [wargame-scenario-designer, scenario-design]
related:
  - "SKILL.md"
  - "references/further-reading.md"
---
# Scenario Design Patterns

Comprehensive reference for design decisions during Phase 2 (Design Framework). Use the rules-of-thumb table at the end as a quick-reference lookup.

## Source and applicability

The Test of Battle article *Scenario Design Notes* (see [further reading](references/further-reading.md)) supplies experienced design advice, with 20th-century examples. The adaptations below are summarized in original words. They separate general design tests from the author's preferences. Other guidance in this file has separate origins.

- Apply the general tests for meaningful decisions, player involvement, understandable objectives, credible assumptions, and feasible missions.
- Match pacing to the mission and players. Immediate contact, high destruction, aggressive play, dense terrain, and decisive outcomes are preferences.
- Reconnaissance, delay, withdrawal, and deliberate attacks can reward patience, concealment, or force preservation. Draws can be legitimate outcomes.
- Keep engineering vehicles, tank and infantry coordination, and hull-down effects within their period and rules context.
- Treat the article's named-system turn estimates as the author's observations. Do not use them as verified rules or universal timings.
- Preserve native rules and historical constraints. Numerical guidelines elsewhere in this file are not established by this article.

| Article pages | Adopted design test | Guidance location |
| --- | --- | --- |
| 1-2 | Distinguish supported facts, estimates, and model substitutions. Preserve credible player assumptions | Core principles and workflow |
| 2-3 | Give both sides choices. Test dominant positions, bottlenecks, and terrain representation | Objectives and terrain |
| 3-4 | Budget unfamiliar rules, deployment, maps, and information handling | Deployment and workflow |
| 4-5 | Allocate useful commands, reserve control, activation opportunities, and player aids | Multiplayer and workflow |
| 5 | Separate session time, simulated time, and achievable actions | Turn structure |
| 6-7 | Test single extended objectives, exit thresholds, and casualty incentives | Objectives and checklist |

---

## Core Design Principles

**The "3 Fs" framework:** Every scenario must deliver:
- **Fun** — Engaging decisions at every turn
- **Fair** — Both sides can win with good play
- **Flavour** — Feels like the period or setting

**The mutually exclusive priorities test:** A good scenario forces players to balance three competing goals that pull against each other: destroy enemies, protect your own forces, and achieve the objective. When all three demand different actions, meaningful decisions emerge.

**METT-TC as design checklist:** Mission, Enemy, Terrain, Troops, Time, Civil Considerations. If you can explain what each side is trying to accomplish and *why*, the scenario will work.

Assess each side's choices separately. Give defenders decisions about repositioning, counterattack, withdrawal, or reserve commitment where the mission permits. Avoid making one side an automatic firing procedure. Disclose historical estimates and model substitutions. Brief players on assumptions their commanders could reasonably know, while preserving legitimate hidden information.

---

## Objectives and Victory Conditions

- **Objective-based > elimination.** Pure "kill them all" is historically unrealistic and promotes static play.
- Prefer objectives that create allocation and maneuver decisions. Several spaced objectives can help. A single road, ridge, or extended village can also work.
- For a compact objective such as a bridge, test choices in approach, timing, support, demolition, or withdrawal. Do not add ahistorical objectives solely to increase their number.
- Effective objective types: capture-and-hold terrain, exit/breakthrough, timed objectives, progressive scoring (accumulate points per turn), survival/endurance.
- **Simple objectives consistently outperform complex ones** — complex VCs create frustration when misunderstood.
- Explain scoring and control conditions before play. Keep legitimate hidden missions separate from ambiguous scoring or undisclosed adjudication.
- For exit missions, test required units, routes, arrival times, and movement opportunities against plausible opposition. Check early completion and impossible thresholds.
- For casualty limits, test whether preserving forces supports the mission or rewards inactivity. Define counted losses and scoring timing using native rules.
- Use historical performance as a benchmark when appropriate. Identify the evidence and uncertainty behind that benchmark.

---

## Asymmetry and Force Balance

- **Asymmetric scenarios are strongly preferred** over mirrored forces. Unbalanced forces make better games — tip victory conditions toward the weaker side rather than equalizing forces.
- The attacker:defender ratio depends on defender advantages. The 3:1 "rule" is a rough planning heuristic; historically, most successful attacks occurred at **1.5:1 to 2:1**. At 2.7:1+, the attacker almost always advances.
- Quality factors (training, equipment, morale) outweigh raw numbers. Well-trained forces regularly succeed against numerical superiority.

---

## Deployment

- Close deployment can suit short combat-focused sessions. Reconnaissance, approach, and delayed-contact missions may need more space or time.
- Fixed historical deployment saves time; best for convention games.
- Free deployment increases planning time significantly; budget accordingly.
- System-specific deployment mechanics (CoC Patrol Phase, TFL Blinds, Mustafa's bidding) should be used when available — do not override with generic fixed zones.
- Use native records and reveal procedures for hidden deployment. If private maps are needed, match them to the table. Budget setup and adjudication time.
- Limit unfamiliar subsystems as well as new special rules. Avoid combining several first-use mechanics in a short introductory game.

---

## Turn Structure

**No community consensus exists** on fixed vs. variable game length:
- **Fixed turns** — Force aggressive play, create urgency, but hard to calibrate.
- **Variable/random ending** — Prevent gamey last-turn behavior, add genuine uncertainty, but can frustrate players who achieved objectives.
- **Card-driven endings** (TFL "Tea Break") — Create friction that mirrors real command uncertainty.

Match turn structure to the rules system. Design victory conditions that work regardless of when the game ends if using variable length.

Distinguish the available session, simulated battle duration, and actions possible under the chosen rules. Allow for setup, briefing, planning, and adjudication. State what the playing-time estimate includes. Preserve any required system-specific wording.

Check travel, deployment, task completion, and opposition before choosing deadlines. Calibrate for player experience and preferred pace. Define how an actual session cutoff is scored. Do not replace native game endings with a wall-clock deadline by default. Mark untested duration and balance as estimates. Record observed timings when playtested.

---

## Points vs. Scenario-Based Balance

Three approaches form a spectrum: **points** (accessibility, pickup play), **scenarios** (meaning, context), **campaigns** (pinnacle experience). No single method should exclude the others. Points systems are inherently imprecise but enable accessibility. Scenarios provide meaning. Use whichever the rules system expects.

---

## Terrain Density and Placement

Terrain is scenario design — density, type, and placement shape tactical decisions more than any other factor.

**Density targets by scale:**
- Platoon/company games (most popular scales): **45-70%** coverage. Lower end for open battlefields (desert, steppe), higher end for bocage, jungle, dense European villages.
- Urban/cityfight: **70%+**
- Squad skirmish (Infinity, Kill Team): pieces every ~4"; 5-6 LOS-blocking elements on a Kill Team board.
- Grand tactical: less terrain per piece, but each represents a larger area.

Terrain needs useful differences between positions. Varied cover and open ground can support movement. Test whether a dominant firing position removes the opponent's feasible choices. Match density to the mission, period, scale, and rules.

For rivers and other bottlenecks, test fire coverage, crossing capacity, and the time available. Possible remedies include supported crossings, a starting bridgehead, or several routes. Choose remedies justified by the mission, period, and native rules. A single-crossing scenario can remain valid if its task is feasible and offers meaningful decisions.

Simplify physical hills only when tactical effects remain intact. Check observation, movement, cover, and objectives under the chosen rules. Do not assume woods cancel elevation effects. Label deliberate departures from historical terrain.

**OAKOC post-placement checklist:** Observation & Fields of Fire, Avenues of Approach, Key terrain, Obstacles, Cover & Concealment.

**Period-specific terrain:**
- **Napoleonic:** Open areas for maneuver; subtle terrain (gentle ridges) had enormous tactical importance
- **WWII:** Dense terrain with cover positions and fire lanes
- **Sci-fi skirmish:** Densest terrain of any genre; 5-6 LOS-blocking pieces for Kill Team; pieces every 4" for Infinity

---

## Scale-Specific Design

### Squad Skirmish (5-15 models)
- Tables: 22"×30" to 3'×3'. Games: 45-90 min.
- Every model matters — losing one is a significant fraction of your force.
- Terrain must be extremely dense; multiple scattered objectives with different values.
- Hidden/secret secondary objectives add decision layers (Infinity classified system, Kill Team Tac Ops).
- Terrain pattern: Gap → Ring of Buildings → Gap → Taller Central Building. Best positions require movement.

### Platoon Tactical (20-60 models)
- Tables: 6'×4'. Games: 2-3 hours.
- Fire-and-maneuver tactics are central. Command mechanics gate player actions.
- Support assets (tanks, heavy weapons, artillery observers) layer onto the core platoon.
- Terrain density directly correlates with the balance between luck and tactics.

### Company/Battalion (multi-based)
- Tables: 6'×4'. Games: 2-4 hours.
- Elements represent squads or platoons.
- Core mission types: Meeting Engagement, Attack variants, Breakthrough, Raid/Recce.
- Attackers typically receive **1.5:1 to 3:1** numerical superiority.

### Regimental through Army Level
- Tables: 6'×4' minimum, 8'×6'+ preferred (or 4'×3' at 6mm).
- Command distance/radius constrains all action.
- Army structure requires at least **3 brigades (preferably 5)** with 3-6 units each.
- 6mm figures favored for visual appearance and proportional ground scale.

---

## Historical Period Guidance

### Horse and Musket
- Column vs. line decisions represent real tactical trade-offs: columns = mobility/shock; lines = firepower but vulnerable to cavalry.
- Reserves are critical — committing too early or too late must carry consequences.
- For scaling historical battles: pick a single corps engagement rather than the full battle. Use smaller figure scales (6mm, 10mm) for grand battles.

### 20th Century (World Wars through Vietnam)
- Combined arms integration is the central challenge. Terrain determines when infantry is better than tanks, not the designer.
- Artillery is essential — attacks rarely succeed without supporting fire.
- The Patrol Phase (Chain of Command) eliminates static deployment by having patrol markers jockey for position before play.

### Modern and Asymmetric
- Troop Quality Dice (Force on Force) model asymmetry: regulars roll D8-D12, irregulars roll D6-D8.
- Hot Spots where irregular reinforcements appear capture the feeling that the enemy can appear anywhere.
- IEDs integrate as hidden markers requiring route clearance.
- Rules of engagement function as scenario constraints limiting when regular forces can engage.

---

## Fantasy Scenario Design

- Magic systems as objectives (disrupt rituals, charge artifacts), monsters as neutral third forces, heroes driving narrative arcs.
- Quest-driven narratives: find the artifact, rescue the prisoner, seal the portal.
- Wandering monsters turn every game into a three-way contest (Frostgrave innovation).
- Treasure-hunting as core risk/reward mechanic.
- Narrative vs. matched play tension: true narrative emerges from meaningful choices, not heavy randomization.

---

## Sci-Fi Scenario Design

- Card-based mission systems combining deployment zones, primary missions, and secondary missions create list diversity (40K 10th edition).
- Classified/semi-secret objectives forcing specialist diversity are a masterclass in mission design (Infinity ITS).
- Zone Mortalis / boarding actions: 50-60% terrain coverage, Reaction Fire in corridors, blip counters for fog of war.

---

## Multiplayer Scenarios (3+ Players)

- Check how native activation distributes decisions among players. One-unit activation, command-point allocation, and unreliable troops can leave a commander inactive. Do not replace the activation system to solve this.
- The **kingmaker problem** is the central design challenge. Mitigate with: hidden scoring, racing-style objectives, formal alliance mechanics, catch-up bonuses, fixed turn counts.
- Table layouts: radial deployment, central objective clusters, multiple fronts (team), free-for-all with scattered objectives.
- Give each player useful decisions from the opening phase. Avoid assigning a player only late reserves. Allocate an initial command, then assign reserves on arrival.
- Where historically and mechanically appropriate, review the mix of reliable and unreliable troops across commands. Do not alter historical ratings solely to equalize activity.
- Allocate likely opposing commands together where practical. Permit parallel sector play only when native rules and cross-sector interactions allow it. Keep a shared timing and adjudication process.
- Use communication limits only when justified by the scenario. Explain permitted messages and umpire handling without imposing modern coordination assumptions on other periods.
- Prepare scenario-relevant data and reference sheets. Provide dice, measures, and counters for each player or active sector as needed.

---

## AI Activation Systems (Solo/Coop)

| System | How It Works | Best For |
|--------|-------------|----------|
| **Simple Aggression (ICUIATTACKU)** | Enemies with LOS move toward and attack | Zombies, feral opponents |
| **Random Action Tables** | Roll on behavior chart each activation | Maximum surprise; can produce illogical behavior |
| **Decision Trees (If/Then)** | Flowchart of criteria and responses | Most intelligent-feeling; requires careful design |
| **Pre-Programmed** | Fixed scripts tied to turn numbers | High replay value with randomized configurations |
| **Node-Based** | Objective markers with weighted priority | Naturalistic objective-seeking behavior |
| **Card-Driven** | Event deck controls enemy actions | High unpredictability |
| **Combination** | Mood roll + decision tree | Most naturalistic behavior |

**Fog of war:** Blinds or PEF markers represent potential enemy positions, revealed on spotting. Event-triggered spawning creates escalating danger.

---

## Historical OOB Research

The **Nafziger Collection** (7,985 orders of battle, 1600-1945) is the gold standard for historical OOBs, freely accessible through the U.S. Army's Combined Arms Research Library. Napoleonic OOBs (1,600+) also hosted at napoleon-series.org. Most break down to regimental level.

**C.S. Grant's scenario books** remain the foundational scenario design references:
- *Scenarios for Wargames* (1981): 52 scenarios in 8 categories using generic forces adaptable to any period
- *Programmed Wargame Scenarios* (1983): ~30 scenarios with programmed enemy responses for solo play
- *Table Top Teasers*: 17 two-page tactical problem scenarios

---

## Rules of Thumb Reference Table

| Parameter | Guideline |
|-----------|-----------|
| Terrain coverage (platoon/company) | 45-70% of table surface |
| Terrain coverage (urban) | 70%+ |
| Terrain coverage (squad skirmish) | Pieces every ~4" |
| Terrain features (small game, 8 units) | 3-6 pieces |
| Kill Team terrain | 5-6 LOS-blocking + scatter |
| Attacker:Defender ratio | 1.5:1 to 3:1 (2:1 historically most common) |
| Skirmish table (28mm, 5-15 models) | 22"×30" to 3'×3' |
| Platoon table (28mm, 20-60 models) | 4'×4' to 6'×4' |
| Company/Battalion (15mm) | 6'×4' |
| Grand tactical (28mm) | 6'×4' minimum, 8'×6'+ preferred |
| Grand tactical (6mm) | 4'×3' to 6'×4' |
| Game length: skirmish | 45-90 minutes |
| Game length: platoon | 2-3 hours |
| Game length: company/battalion | 2-4 hours |
| Game length: grand tactical | 4+ hours |
| Special scenario rules | 2-3 maximum |
| Convention intro time | ≤5 min per hour of play |
| Objective layout | Create meaningful choices. Multiple points or one extended objective can work |
| Ground scale at 28mm on 6'×4' | ~144 scale yards |
| Ground scale at 6mm on 6'×4' | ~600 scale yards |
