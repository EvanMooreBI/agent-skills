---
title: Brigade generator table format
related:
  - "[[brigade-fire-and-fury-random-army-generation/SKILL]]"
---

# Generator table format

Random armies need ten CSV files built from the Fictional Army Generator for Pick-up Games in the user's own rulebook. This file describes their columns and allowed values. It holds no values from the book. Header-only templates are in [assets/table-templates](../assets/table-templates/). [scripts/Test-BrigadeTables.ps1](../scripts/Test-BrigadeTables.ps1) checks a finished folder.

## Conventions

- Write UTF-8 CSV with the template's header row, in the template's column order.
- The book prints die results as ranges. Write one row for each d10 result, so a range of 1-3 becomes rows 1, 2 and 3. Every lookup must cover results 1-10 exactly once.
- Spell periods `Early War`, `Mid-War` and `Late War`, with a hyphen in `Mid-War`. Spell theaters `Eastern Theater` and `Western Theater`. Sides are `USA` and `CSA`.
- Use `true` and `false` in lowercase.
- Copy values exactly as printed. Do not fix, smooth or guess a value. If a cell is unreadable, ask the user for a clearer photo.

## Tables

| File | One row for each | Columns and values |
|---|---|---|
| `01_force_balance_matchups.csv` | Matchup M1-M8 | `matchup_id`; `usa_players` and `csa_players` as printed, in the form `4`, `2-4` or `2 or 3`; `usa_command` and `csa_command` as short text. |
| `02_time_period_rolls.csv` | d10 result | `d10_roll`; `period`. |
| `02_theater_rolls.csv` | d10 result | `d10_roll`; `theater`. |
| `03_brigades_per_division.csv` | Side and d10 result | `side`; `d10_roll`; `brigades_in_division` as a whole number. |
| `03_batteries_per_division.csv` | Brigade count and d10 result | `brigades_in_division`; `d10_roll`; `batteries_in_division`. Cover every brigade count that the previous table can produce. |
| `04_exceptional_leader_rolls.csv` | Period, side and d10 result | `period`; `side`; `d10_roll`; `exceptional_leader` as `true` or `false`. |
| `05_brigade_strength.csv` | Unit type (`Infantry`, `Cavalry`), period, side and d10 result | `unit_type`; `period`; `side`; `d10_roll`; `stands_in_brigade`, which must be a starting strength in the bundled effectiveness table. |
| `06_experience_rating.csv` | Unit type (`Infantry`, `Cavalry`, `Artillery`), period, side and modified roll | `unit_type`; `period`; `side`; `modified_roll`; `experience_rating` (`Crack`, `Veteran`, `Experienced`, `Green`). Infantry covers modified rolls -1 to 10, because large brigades roll with a modifier. The other types cover 1 to 10. |
| `07_morale_rating_ranges.csv` | Period, side and morale rating | `period`; `side`; `morale_rating` (`Spirited`, `Reliable`, `Unreliable`, `Dispirited`); `modified_roll_min`; `modified_roll_max`; `open_ended_above`; `available`. Each period and side has all four ratings. A rating the book does not offer has `available` set to `false` and empty roll columns. The available bands must be contiguous. Only the highest band is open-ended, with an empty `modified_roll_max`. |
| `08_weapon_type.csv` | Unit type, theater, period, side and d10 result | `unit_type`; `theater`; `period`; `side`; `d10_roll`; `weapon_code`; `weapon_type`; `special_limit_applies` (`repeater_limit` for RP, `heavy_rifle_limit` for HR, otherwise empty). |

Weapon codes by unit type, with the exact `weapon_type` name for each. The labels print the code that the bundled renderer maps from the name, so the checker rejects a name that does not match its code.

| Unit type | Codes and names |
|---|---|
| Infantry | SM Smoothbore Musket, MM Mixed Muskets, RM Rifle Musket, RP Repeater |
| Cavalry | SH Shotgun & Hunting Rifle, RC Rifle & Carbine, BL Breechloader, RP Repeater |
| Artillery | SB Smoothbore, NP Napoleon, RS Rifle & Smoothbore, RN Rifle & Napoleon, LR Light Rifle, HR Heavy Rifle |
 RM, BL and LR must appear at least once, because the repeater and Heavy Rifle caps substitute them.

The effectiveness table, `references/tables/07_brigade_effectiveness_table.csv`, ships with the skill. Do not copy it into the local folder.
