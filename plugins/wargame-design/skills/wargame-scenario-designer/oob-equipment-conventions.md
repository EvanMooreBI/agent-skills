# OOB Equipment and Naming Conventions

This reference defines how to name and describe weapons, vehicles, and team types in scenario OOBs. Equipment specificity is critical — "an infantry platoon" is not a useful OOB entry. Players need to know exactly what is on the table.

---

## General Principles

**Always name the specific equipment.** Not "a tank" but "Panzer IV H." Not "an anti-tank gun" but "6-pdr Anti-Tank Gun." Not "rifles" but "M1 Garand" or "Kar98k" (at skirmish scale) or "Rifle team" (at company scale using Flames of War conventions).

**Always follow historical Tables of Organization and Equipment (TO&E).** Do not guess squad sizes, weapon distributions, or equipment loadouts. Before writing any OOB, research the actual TO&E for the specific nation, branch, and time period using web search. Squad composition, weapon distribution per fire team, and support weapon allocation varied significantly by nation, year, and branch — a 1944 US Army rifle squad is organized very differently from a 1944 British rifle section or a 1943 German Panzergrenadier Gruppe. Getting these details right is what separates a credible scenario from a generic one. When uncertain, research first — never default to assumptions or "typical" compositions.

The level of specificity scales with game scale:
- **Skirmish (individual models, 5-15 figures):** Name individual weapons per model. Every figure gets a primary weapon and any special equipment listed. See Skirmish Equipment Assignment below.
- **Platoon (squad-based, 20-60 figures):** List each squad's composition with specific weapon types — not generic labels. For example: "NCO (Sten Mk II), Bren Gun team (Bren Mk I + No.2), 7 Riflemen (Lee-Enfield No.4), 1 PIAT team." Name the specific LMG, rifle, and any AT/special weapons in each squad. Name transport vehicles by specific variant. Do NOT use FOW-style team type labels at this scale — platoon games use individually-based figures, not multi-figure stands.
- **Company/Battalion (element-based, multi-figure stands):** Use FOW-style team type labels per base/stand: Rifle team, Rifle/MG team, MG team, etc. Name gun teams and vehicles by specific type. See the period-specific reference files for the full team type taxonomy.
- **Grand tactical (regiment/brigade):** Use aggregate armament descriptions per unit (e.g., "Rifled Musket", "Smoothbore Musket")

---

## Skirmish Equipment Assignment

At skirmish scale, every individual model must have its specific weapon and special equipment listed. This is not just a weapon name — it is the full loadout for that figure, assigned by the model's role within its squad or team.

### Assign Weapons by Role

Each model in a skirmish OOB has a tactical role that determines its weapon. Common roles and their typical loadouts:

| Role | Primary Weapon | Notes |
|------|---------------|-------|
| **Squad Leader / NCO** | SMG or Rifle (often upgraded) | May carry pistol as sidearm. Typically has radio or whistle. |
| **Rifleman** | Standard rifle of the period | The bulk of the squad. |
| **Automatic Rifleman / Gunner** | LMG or SAW | Often paired with an Assistant Gunner. |
| **Assistant Gunner** | Rifle or Carbine | Carries extra ammo for the gunner. |
| **Grenadier** | Rifle + underslung grenade launcher | Or dedicated grenade launcher (e.g., M79). |
| **Machine Gunner** | GPMG or MMG | Crew-served; may need loader/ammo bearer. |
| **Sniper** | Sniper rifle | Usually paired with a Spotter (rifle + binoculars). |
| **Medic / Corpsman** | Pistol or Rifle | Carries medical kit. May be unarmed in some systems. |
| **RTO / Radioman** | Rifle | Carries radio (enables off-board support calls). |
| **Anti-tank specialist** | AT weapon + sidearm | e.g., Bazooka, PIAT, Panzerfaust, RPG-7, Javelin |
| **Engineer / Pioneer** | Rifle or SMG | Carries demolition charges, wire cutters, mine detectors |
| **Officer / Commander** | Pistol, SMG, or Rifle | May carry binoculars, map case, compass |
| **Point man / Scout** | Rifle or Carbine | May carry suppressed weapon |
| **Dog handler / Specialist** | Pistol or Rifle | Carries role-specific equipment |

### Special Equipment

Beyond primary weapons, skirmish scenarios must specify special equipment that affects gameplay — especially items required to accomplish scenario objectives. **If a scenario requires something to be destroyed, someone must carry the demolition charges.**

| Equipment | Who Carries It | When to Include |
|-----------|---------------|-----------------|
| **Fragmentation grenades** | Most combat troops (2-3 each) | Default for assault-oriented troops |
| **Smoke grenades** | Squad leaders, designated models | When smoke is a tactical option or scenario mechanic |
| **Demolition charges / Satchel charges** | Engineers, designated specialists | When objectives involve destroying structures, bridges, bunkers |
| **Anti-tank mines** | Engineers | When objectives involve mining roads or blocking armor |
| **Wire cutters** | Engineers, point men | When barbed wire or obstacles are on the table |
| **Mine detectors** | Engineers | When minefields are a scenario element |
| **Radio** | RTO, officers, FO | When calling off-board fire support, reinforcements, or extraction |
| **Binoculars** | Officers, snipers, FOs | When spotting/observation is a mechanic |
| **Flares / Signal equipment** | Officers, designated models | When signaling is a scenario objective or mechanic |
| **Medical kit** | Medics, corpsmen | When casualty treatment is a game mechanic |
| **Grappling hooks / Ladders** | Assault troops | When scaling walls or obstacles |
| **Documents / Intel** | Designated model (often officer) | When intel retrieval is a scenario objective |
| **Prisoners** | Escorting model | When prisoner escort/rescue is an objective |

### Skirmish OOB Format

List each model individually. Group by fire team or squad, with each model on its own line showing role, name (if characterful), primary weapon, and any special equipment.

**This example shows the format, not a specific TO&E. Always research the actual TO&E for your scenario's nation/period/branch before writing.**

```
Example format (illustrative — verify actual TO&E via research):

FIRE TEAM ALPHA
  Team Leader — Sgt. Williams: M16A1, smoke grenades (x2), compass
  Automatic Rifleman: M60 LMG
  Assistant Gunner: M16A1, extra M60 ammo belt
  Rifleman: M16A1, fragmentation grenades (x2)
  Grenadier: M16A1 + M203 grenade launcher

FIRE TEAM BRAVO
  Team Leader — Cpl. Jackson: M16A1, smoke grenades (x2)
  Rifleman: M16A1, fragmentation grenades (x2)
  Rifleman: M16A1, fragmentation grenades (x2)
  Rifleman (RTO): M16A1, PRC-25 radio
```

The key principle: **if a piece of equipment matters for gameplay or for accomplishing a scenario objective, it must appear on a specific model in the OOB.** Don't just say "the squad has demo charges" — say which specific model carries them. Similarly, if a radio is needed to call in air support, the OOB must show exactly which model has the radio.

---

## Troop Quality Ratings

Every unit in an OOB must have a quality/experience rating. The rating system varies by period and rules system.

### 20th/21st Century (General / System-Agnostic)

Use this five-tier scale for any 20th or 21st century scenario not designed for Flames of War, NAM, or Team Yankee. Ranked worst to best:

| Rating | Description |
|--------|-------------|
| **Green** | Newly raised, poorly trained, no combat experience |
| **Trained** | Adequately drilled, minimal combat experience |
| **Experienced** | Competent troops with some combat exposure |
| **Veteran** | Battle-hardened, reliable under pressure |
| **Elite** | Best-of-the-best (e.g., Fallschirmjäger, Guards, Rangers, Waffen-SS panzer divisions) |

### Flames of War / NAM / Team Yankee Specific

These three Battlefront systems split troop quality into two independent axes. Both must be specified for every unit.

**Skill:** Green, Trained, Veteran
**Motivation:** Reluctant, Confident, Fearless

A unit is described as both, e.g., "Veteran / Fearless" or "Trained / Confident." Common historical pairings:
- Late-war Volksgrenadier: Green / Reluctant
- Regular US Infantry: Trained / Confident
- British Paras: Veteran / Fearless
- Waffen-SS Panzer: Veteran / Fearless

### Horse & Musket (Regimental Fire and Fury Specific)

When designing for Regimental Fire and Fury, use the RFF-specific quality ratings in `references/equipment-horse-and-musket.md` (Crack / Veteran / Trained / Green, Gallant / Able / Poor leader ratings). These are RFF-specific.

### Fantasy and Sci-Fi

Use the system's own rating terms (e.g., Warhammer uses Weapon Skill / Ballistic Skill / Leadership; Bolt Action uses Inexperienced / Regular / Veteran).

---

## Period-Specific Equipment References

Consult the appropriate reference file for weapon names, team types, and vehicle designations:

| Period | Reference File | Contents |
|--------|---------------|----------|
| WWII | `references/equipment-wwii.md` | Individual weapons, FOW team type taxonomy, tank/vehicle designations by nation, transport, aircraft |
| Horse & Musket / ACW | `references/equipment-horse-and-musket.md` | RFF weapon codes, artillery codes, label format, unit designation conventions, grand tactical stat-table conventions |
| Modern / Cold War | `references/equipment-modern.md` | Individual weapons, squad compositions, team types, vehicles by nation, helicopters |
| Fantasy / Sci-Fi | Use the game system's own equipment names | — |
