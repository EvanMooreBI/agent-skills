---
title: Fire and Fury stands required table
type: skill-reference
tags: [wargame-scenario-designer, brigade-fire-and-fury, regimental-fire-and-fury, scenario-template]
related:
  - "../SKILL.md"
  - "brigade-fire-and-fury.md"
  - "../scenario-examples/acw-regimental_fire-and-fury_official.md"
---
# Fire and Fury stands required table

Every generated Brigade Fire and Fury 2nd Edition or Regimental Fire and Fury scenario includes a **Stands required** section with this table. It tells players how many stands of each type to put on the table for each side. Other rules systems do not use it.

## Template

Replace the side names with the scenario's sides, in the order the OOBs appear.

```markdown
## Stands required

The following number of stands is needed:

| Stand | {Side A} | {Side B} |
|---|---|---|
| {Stand type} | {count} | {count} |
| Total | {sum} | {sum} |
```

## Rows

- Include a row when at least one side has a stand of that type. Write 0 for a side with none, never "-" or a blank.
- Drop a row when both sides have 0.
- Keep rows in the order listed below for the scenario's rules system.
- The Total row sums every row shown for that side.
- Take every count from the scenario's OOB. Recount after any OOB change.

Artillery is one row of gun stands. Never add a limber row, a "+N" limber count, or a split into gun-with-limber and gun-only rows. Limbers are assumed markers. Use the Artillery (off-table) row only when the scenario places guns off the table.

Do not explain routine core-rule mechanics under the table, such as horseholder or replacement-model handling.

### Regimental Fire and Fury row order

1. Infantry
2. Infantry command
3. Cavalry
4. Dismounted cavalry
5. Artillery
6. Artillery (off-table)
7. Army/Corps leader
8. Division leader
9. Brigade leader
10. Brave Colonel
11. Artillery leader

### Brigade Fire and Fury 2nd Edition row order

1. Infantry
2. Mounted cavalry
3. Dismounted cavalry
4. Horseholder
5. Artillery
6. Artillery (off-table)
7. Army/Corps leader
8. Division leader
9. Brigade leader

## Example

An illustrative Regimental Fire and Fury scenario, not taken from any published scenario, with no cavalry and no army or corps leaders:

| Stand | Union | Confederate |
|---|---|---|
| Infantry | 96 | 88 |
| Infantry command | 16 | 14 |
| Artillery | 12 | 8 |
| Artillery (off-table) | 0 | 2 |
| Division leader | 2 | 1 |
| Brigade leader | 4 | 4 |
| Brave Colonel | 0 | 1 |
| Artillery leader | 1 | 1 |
| Total | 131 | 119 |
