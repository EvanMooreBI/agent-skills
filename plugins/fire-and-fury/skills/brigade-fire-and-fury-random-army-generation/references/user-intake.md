---
title: Brigade Fire and Fury random army intake
---

# User intake

Ask for the player split before offering matchups. Read the matchups from `01_force_balance_matchups.csv` in the user's generator tables folder (see `## Local resources` in SKILL.md). Offer only the rows whose `usa_players` and `csa_players` accept both side counts, and show each row's commands. If the tables are missing, set them up before collecting the rest of the request.

The total player count must equal the USA and CSA counts. Both sides require at least one player. This makes the supported total range 2-10, but not every split is valid.

The generator builds these command structures for each matchup:

| Matchup | USA corps (divisions in each) | CSA corps (divisions in each) |
|---|---|---|
| M1 | 3, 3 | 2, 2 or 4 |
| M2 | 3, 2 | 2, 2 or 4 |
| M3 | 3, 2 | 3 |
| M4 | 2, 2 | 3 |
| M5 | 2, 2 | 2 |
| M6 | 3 | 2 |
| M7 | 3 | one independent division |
| M8 | 2 | one independent division |

Explain that M1 and M2 require a Confederate structure choice:

- `twoCorps`: two corps with two divisions each.
- `oneCorps`: one corps with four divisions.

Then ask whether period and theater are fixed or random. If fixed, collect their values. If the user gives a year, explain that 1862 can be Early or Mid War and 1864 can be Mid or Late War. Finally, ask whether to include optional cavalry.

Example request:

```json
{
  "players": { "total": 8, "USA": 4, "CSA": 4 },
  "matchup": { "id": "M1", "csaVariant": "twoCorps" },
  "period": { "mode": "fixed", "value": "Mid War" },
  "theater": { "mode": "fixed", "value": "Eastern" },
  "year": 1863,
  "includeCavalry": true
}
```
