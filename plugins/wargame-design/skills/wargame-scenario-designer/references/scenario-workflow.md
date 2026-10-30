---
title: Scenario workflow reference
type: skill-reference
tags: [wargame-scenario-designer, scenario-workflow]
related:
  - "../SKILL.md"
  - "../scenario-design-patterns.md"
---
# Scenario Workflow Reference

Detailed phase guidance for `wargame-scenario-designer`. Use this after reading `SKILL.md` when a scenario task needs more than the compact workflow.

For Brigade Fire and Fury 2nd Edition, read [the required system reference](brigade-fire-and-fury.md) first. Its presentation and map prerequisite override the generic geometry and output requirements below. A map-pending draft uses sourced relative descriptions and a separate research handoff, not invented coordinates or a substitute text-only map.


## Workflow

### Phase 1: Intake

Gather the information needed to design the scenario. Determine:

1. **Rules system** - Which game? Or system-agnostic? **Always ask this if not provided.** The rules system determines the scenario's entire presentation format, OOB structure, deployment conventions, and victory condition framing. See "Matching Presentation to Rules System" below.
2. **Period and genre** - Historical era, fantasy setting, or sci-fi universe
3. **Specific battle** - Is the user recreating a historical engagement? Which one?
4. **Available miniatures** - What does the user actually own? (Forces must be buildable)
5. **Available terrain** - What terrain pieces does the user have?
6. **Table size** - Physical table dimensions
7. **Number of players** - Including whether an umpire is needed
8. **Time available** - How long will the session last? Determine whether setup and briefing are included.
9. **Player experience** - Are the players veterans or newcomers to the system?
10. **Scenario type preference** - Attack/defense, meeting engagement, raid, breakthrough, patrol, etc.
11. **Context** - Convention game? Part of a campaign? Solo play?

**Do not interrogate the user.** Most users will provide only 2-4 of these details upfront. Handle missing information as follows:

- **Infer reasonable defaults** from what the user did provide. If they name a WWII platoon game, assume 6'x4' table, 2 players, 2-3 hours, platoon-scale forces.
- **State your assumptions explicitly** so the user can correct them: "I'm assuming a 6'x4' table and approximately 2.5 hours of play time - let me know if that's different."
- **Ask only for critical missing information** that you cannot reasonably infer - typically the rules system (if ambiguous) and available miniatures (if designing for a specific collection).
- **Never ask more than 3 questions at once.**

### Phase 2: Design Framework

Before writing, work through these design decisions internally. These form the scenario's skeleton.

Read source/applicability, core principles, and relevant context in [the design patterns](../scenario-design-patterns.md). Its source table identifies the adapted PDF lessons and their limits. Use the tests below to apply them, without loading the full source for every scenario.

1. **Mission (METT-TC).** What is each side trying to accomplish and why? The mission must create mutually exclusive priorities: destroying the enemy, protecting your own forces, and achieving the objective should pull in different directions.
   - Identify meaningful choices for each side. Include defender repositioning, counterattack, reserve commitment, or withdrawal where appropriate.
   - Preserve credible player knowledge. Separate supported history, disclosed estimates, collection substitutions, and legitimate hidden information.

2. **Force structure.** Determine the order of battle. This step requires active research - do it now, during Phase 2, before writing anything.
   - **Research historical TO&E via web search.** Look up the actual Table of Organization and Equipment for the specific nation, branch, time period, and theater. Search for terms like "[nation] [branch] TO&E [year]" or "[unit name] order of battle [battle]." Squad sizes, weapon distributions per fire team, and support weapon allocation varied significantly - a 1944 British Para section is organized differently from a 1944 British rifle section, and both differ from 1943 equivalents. Do not guess or assume. For historical recreations, also research the specific units involved to determine actual strengths and equipment at the time of the battle.
   - The user's collection (if specified) - build forces from what they own
   - Genre conventions and the rules system's force organization
   - Appropriate attacker:defender ratio - typically 1.5:1 to 3:1 depending on the defender's advantages (consult the rules-of-thumb table in `scenario-design-patterns.md`)

3. **Terrain concept.** Design a terrain layout that creates meaningful tactical decisions:
   - **Research the geography of the battle area.** Terrain must be historically and geographically appropriate for the region. Search for terrain characteristics of the specific location.
   - Match density to period and scale (consult the rules-of-thumb table in `scenario-design-patterns.md`)
   - Apply the OAKOC checklist: Observation & Fields of Fire, Avenues of Approach, Key Terrain, Obstacles, Cover & Concealment
   - Prefer several viable approaches. For a mission-defined chokepoint, test choices in timing, support, reserves, or objectives.
   - Create terrain texture: varied types separated by open ground, not uniform coverage
   - Test dominant firing positions and obstacle capacity against the mission. Avoid automatic outcomes caused by the layout.
   - Simplify physical terrain only when native observation, movement, cover, and objective effects remain intact.
   - For Brigade Fire and Fury 2nd Edition, finalize feature geometry only from a completed map. Other systems use terrain dimensions and attributes from `scenario-output-template.md` Section 3.

4. **Deployment method.** Not all scenarios use fixed deployment zones. Determine the deployment method based on the rules system and scenario type:
   - **Fixed zones** - Traditional: each side deploys in a defined area. Best for convention games and grand tactical scenarios.
   - **Patrol Phase** (Chain of Command) - No fixed zones. Design terrain with natural locking points where opposing patrol markers will clash. Ensure terrain density allows patrol markers to advance meaningfully before locking. The scenario specifies starting patrol marker positions and any restrictions, not deployment zones.
   - **Blinds / Hidden deployment** (Too Fat Lardies, Force on Force) - Units represented by markers until spotted. Specify spotting rules and how/when blinds are revealed. Use native records and reveal procedures. If private maps are needed, match them to the table. Specify information handling and budget setup/adjudication time.
   - **Scattered / Drop zone** (airborne, amphibious) - Units arrive in a designated area but may scatter. Specify the drop/landing zone, scatter mechanics, and rally/regroup rules. Separated units should need 1-2 turns to reform.
   - **Off-table entry** - Units enter from a table edge on a specific turn. Specify entry point, turn, and formation.
   - **Bidding** (Sam Mustafa systems) - Deployment advantages earned through pre-game bidding.
   
   If the rules system has a specific deployment mechanic (like CoC's Patrol Phase), use it - do not override it with fixed zones.

5. **Victory conditions.** Design objective-based victory conditions:
   - Test allocation and maneuver choices. Several spaced objectives or one extended road, ridge, or village can work.
   - For a compact objective, test choices in approach, timing, support, or withdrawal. Preserve historical constraints.
   - Consider tiered victory (Total / Major / Minor) for richer outcomes
   - Ensure the historically losing side has a viable path to victory
   - Keep conditions simple enough to explain in two sentences
   - State scoring, control, and adjudication before play. Separate hidden missions from unclear victory conditions.
   - For exit missions, check required units and timing against arrival, travel, opposition, and possible early completion.
   - For casualty limits, define counted losses and test whether the scoring rewards inactivity over the intended mission.

6. **Asymmetry.** Determine what makes each side's experience different:
   - Different objectives (attacker must take, defender must hold)
   - Different force compositions (quality vs. quantity)
   - Different information (hidden deployment, uncertain reinforcements)
   - Different timing (one side must act before the other is ready)

7. **Special rules.** Maximum 3. Each must earn its place by creating a player decision or period flavor that the base rules cannot provide. If a rule doesn't create a meaningful choice, cut it. Do not write rules that duplicate mechanics already in the base rules system.
   - Account for unfamiliar core subsystems too. Avoid combining several first-use mechanics in a short introductory game.

8. **Turn and time structure.** Determine based on the rules system:
   - **Fixed turns** - Calibrate the number of turns to the scenario's scope. Creates urgency.
   - **Random/variable ending** (CoC Chain of Command dice, Bolt Action turn 7+ roll, etc.) - Do not specify a fixed turn count. Instead, design victory conditions that work regardless of when the game ends. Use "at end of game" or "when X condition is met" rather than "on Turn 6."
   - **Card-driven** (Too Fat Lardies "Tea Break" card, Sharp Practice) - Turns end randomly. Design for uncertainty - reinforcement triggers should be event-based ("when the reinforcement card is drawn") not turn-based.

   - Separate session duration, simulated battle duration, and achievable actions. Include setup, briefing, planning, and adjudication allowances where applicable.
   - Check travel, deployment, and task-completion opportunities before setting deadlines. Account for opposition and player experience.
   - Preserve native ending mechanics. State the scoring procedure if the real session must end early.
   - Label untested duration and balance as estimates. Record observed timings after playtests.

9. **Player participation and preparation.** For multiple players per side, allocate useful opening decisions to each commander.
   - Avoid assigning anyone only late reserves. Give an initial command and assign reserves when they arrive.
   - Check native activation and command-point allocation for idle players. Preserve historical ratings and native mechanics.
   - Allow parallel sector activity only when native rules and cross-sector interactions permit it. Maintain shared timing and adjudication.
   - If communication is restricted, define permitted messages and umpire handling. Give a period-appropriate scenario reason.
   - Prepare relevant unit data, maps, player aids, dice, measures, and counters. Keep hidden information with its intended audience.

### Phase 3: Output

For Brigade Fire and Fury 2nd Edition, use [the system reference and templates](brigade-fire-and-fury.md). For other systems, follow `scenario-output-template.md`. Adapt section depth to the scenario - a 3-model skirmish needs less than a 200-figure historical recreation.

#### Narrative Voice

- **Background narrative:** Third person, past tense, establishing context. Vivid but concise - 2-4 paragraphs maximum.
- **Player briefings:** Second person ("You are...") or first person from the commander's perspective. Include only what that side would know.
- **Rules and mechanics:** Clear imperative instructional voice. No ambiguity.

#### OOB Presentation

**Always name specific equipment** - not "a tank" but "Panzer IV H." Consult `oob-equipment-conventions.md` for scale-appropriate specificity levels and period-specific reference files, and follow the formatting in `scenario-output-template.md` (Section 4: Forces).

#### Terrain Description

For Brigade Fire and Fury 2nd Edition, the system reference's map prerequisite governs: an unfinished map requires a handoff and sourced relative descriptions; a completed map permits supported edge measurements without x/y coordinates. The following text-only layout conventions apply to other systems:

- **Declare which table edge is North first** - before any other terrain description. Every directional reference (NE, "12" from the SE edge", etc.) depends on this declaration. Without it, the scenario is ambiguous.
- Use compass directions consistently (North/South/East/West) - never "left" or "right"
- Divide the table into a grid or zones and reference positions by grid
- Describe each terrain feature with: type, approximate size, position (measured from table edges), and game effect
- Specify deployment zones with precise measurements
- Suggest terrain substitutions for pieces the user may not have

### Phase 4: Quality Check

Run through `design-checklist.md` before delivering. Fix any identified issues. Pay particular attention to:

- Are victory conditions truly objective-based, not just "kill them all"?
- Does meaningful activity begin at the intended pace? For a short combat-focused game, target contact in turns 1-2.
- Does each player have useful decisions, including commanders with unreliable troops or late reserves?
- Are exit thresholds, casualty incentives, and deadlines feasible under the chosen rules and layout?
- For Brigade Fire and Fury 2nd Edition, does geometry match the completed map, or is the pending-map handoff complete with exact layout deferred? For other systems, can terrain be set up from the description alone?
- Are there more than 3 special rules? (Cut the weakest.)

---

## Context-Specific Guidance

### Historical Battle Recreation

- Research the battle's OOB, terrain, timeline, and key command decisions
- Scale appropriately: pick a single sector or a 2-3 hour phase rather than attempting the full battle
- The historically losing side **must** have a viable path to victory - through scenario conditions (perform better than the historical commander), variable objectives, hidden information, or "what-if" branches
- Include historical context that helps players understand why commanders made the decisions they did
- Note the historical outcome in Designer's Notes so players can compare
- When scaling forces, maintain proportional relationships between unit types rather than cutting uniformly

### Original or Fictional Scenario

- Apply the "hook" concept: what single element makes this scenario distinctive and worth playing?
- Use the 3 Fs framework: **Fun** (engaging decisions at every turn), **Fair** (both sides can win with good play), **Flavour** (feels like the period or setting)
- Start from an interesting tactical problem, not from a force list - "What if a patrol stumbles into a supply dump?" not "I have 500 points of Germans"
- Create a situation where killing enemies, protecting your forces, and achieving the objective demand different actions

### Convention and Participation Games

- One-page briefing maximum per player
- Pre-calculate all modifiers on unit cards - show only scenario-relevant numbers
- Design for variable player count: assign multiple commands to single players when numbers are low, split commands when more arrive
- Choose units with the fewest special rules for accessibility
- Build in a "cut to the chase" plan to accelerate toward a climactic conclusion if running behind on time
- Visual spectacle matters: suggest terrain centerpieces and visually distinctive units
- Allow 4-5 minutes of introduction per hour of game time, maximum
- Define an understandable ending and a scoring procedure for the session cutoff. Allow a draw when appropriate.

### Solo and Cooperative

- Specify the AI activation system for the non-player force. Options (detailed in `scenario-design-patterns.md`):
  - Simple aggression (ICUIATTACKU) - enemies with LOS move toward and attack
  - Random action tables - dice-driven behavior charts
  - Decision trees - if/then flowcharts
  - Pre-programmed orders - fixed scripts by turn
  - Node-based - objective markers with weighted priority
  - Card-driven - event deck controls enemy actions
  - Combination systems - mood roll + decision tree
- Include escalation mechanics: tension should increase over time (spawning enemies, depleting resources, ticking clocks)
- Use blinds or PEF markers for fog of war
- Provide event tables or random encounter triggers

### Campaign Scenarios

- Note consequences that carry forward to the next game: casualties, captured objectives, morale shifts, supply status
- Design scenarios that create meaningful campaign-level decisions, not just isolated fights
- Consider how the outcome changes the strategic situation

---

## Adapting to Specific Rules Systems

The skill cannot pre-load guidance for every rules system. When the user names a specific system, research and adapt to that system's conventions rather than applying generic defaults. Before writing, determine these four things about the named system:

1. **Activation method.** How do units activate? (IGOUGO, alternating activation, dice bag, card-driven, random turn ending?) This determines turn structure and victory condition framing. If the system uses random turn endings, do not write fixed turn-count victory conditions.

2. **Deployment method.** Does the system have its own deployment mechanic? (Chain of Command's Patrol Phase, Blinds in TFL games, free deployment in Bolt Action?) If so, use it - do not override with generic fixed deployment zones.

3. **Force organization and stat format.** How does the system present units? (Individual stat lines per model? Unit cards? Points-based army lists? Historical TO&E with no points?) Format the OOB to match the system's conventions. If the system uses army lists with points, provide point costs. If it uses unit cards, format as unit cards.

4. **Quality/morale ratings.** What rating system does the game use? (Bolt Action: Inexperienced / Regular / Veteran. CoC: Command Initiative rating + Force Morale. FOW: Skill + Motivation. Black Powder: Command Rating + Stamina + Morale Save.) Use the system's own terms, not the generic five-tier scale.

**Use official taxonomy.** When the user specifies a rules system, use that system's official terminology for terrain types, unit types, quality ratings, and game terms. Do not invent terminology or use generic labels when official terms exist. Examples: FOW uses "Tall" and "Short" for terrain height attributes, not "dense" and "light." RFF uses "Crack/Vet/Trn/Grn", not "Elite/Veteran/Trained/Green." Research the system's official terms if unsure.

If you are unfamiliar with the named system, say so and offer to design a system-agnostic scenario that the user can adapt, rather than producing output that misuses the system's mechanics.

### Matching Presentation to Rules System

When a rules system has an associated example file in `scenario-examples/`, use that example's structure and conventions as the primary template for the scenario output. Official publisher formats take priority over generic or unofficial formats. Read the relevant example before writing to understand the correct structure, OOB format, and presentation conventions.

For Brigade Fire and Fury 2nd Edition, use [the required reference](brigade-fire-and-fury.md), including the user's approved document and modifier wording, before selecting a generic horse-and-musket example.

| Rules System | Example File | Priority | What It Teaches |
|---|---|---|---|
| **Regimental Fire and Fury** | `acw-regimental_fire-and-fury_official.md` | **Mandatory** | Hierarchical label tree OOB, weapon codes, footnote deployment, asymmetric starting conditions |
| **FOW, NAM, Team Yankee, Checkpoint Charlie, Fate of a Nation** | `wwii-company_flames-of-war_official-standard-missions.md` (standard) or `wwii-company_flames-of-war_official-historical.md` (historical) | **Mandatory** | Deployment diagrams (inch/cm), reserve mechanics, two-column OOB, Skill/Motivation ratings |
| **FOW (supplement scenarios)** | `wwii-company_flames-of-war_official-special-mission.md` | Official | Bridge between standard missions and full historical scenarios |
| **Fireball Forward** | `wwii-company_fireball-forward_official.md` | Official | Compact 2-page format, VP by unit type, variable forces, pre-game commitment |
| **Battlefront WWII** | `wwii-battalion_battlefront-wwii_unofficial.md` | Guide | First-person briefings, NATO symbol OOB tree, tiered victory, fortification rules |
| **Black Powder / Hail Caesar** | `horse-and-musket_black-powder_unofficial.md` | Guide | Stat tables by brigade, terrain with mechanical effects, deployment as narrative |
| Any TFL game (CoC, CDS, IABSM, Sharp Practice) | `vietnam-platoon_any-system_unofficial.md` | Guide | Asymmetric objectives, hidden deployment with player-placed defenses, umpire's notes |
| **Any Horse & Musket (no named system)** | `acw-regimental_fire-and-fury_official.md` | **Default fallback** | Use RFF taxonomy, layout, and label format |
| **Any 20th/21st century (not Battlefront systems)** | `wwii-battalion_battlefront-wwii_unofficial.md` | **Default fallback** | Use Battlefront WWII structure; `wwii-company_fireball-forward_official.md` as supplementary reference |
| No matching system or period | `scenario-output-template.md` | Generic template | - |

**Important:** The FOW mission format is ONLY for Battlefront systems. It is not a universal default for all WWII or modern scenarios. Official examples take priority - emulate their structure exactly. Unofficial examples show acceptable alternative approaches.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Objective without tactical choices | Forces converge without meaningful allocation, timing, or support decisions | Use spaced objectives, an extended objective, or viable options around the mission's compact objective |
| Elimination-only victory | Historically unrealistic; promotes static play | Use objective-based victory conditions |
| More than 3 special rules | Cognitive overload; rules forgotten mid-game | Cut to the 3 most impactful; each must create a decision |
| Mirrored forces and objectives | Static, predictable play with no dramatic tension | Make forces, objectives, or information asymmetric |
| Terrain-bare table | No tactical decisions; firepower dominates | Consult rules-of-thumb table for terrain density targets |
| Complex victory conditions | Players misunderstand them; frustration replaces fun | Simplify until explainable in 2 sentences |
| Railroading | Predetermined outcome regardless of player decisions | Ensure multiple viable strategies for each side |
| Unproductive opening | Travel consumes time without decisions relevant to the mission | Use close deployment for short combat games. Retain purposeful reconnaissance or approach phases |
| Rivers without crossings | Movement gridlock; half the table becomes unusable | Add fords, bridges, or starting bridgeheads |

