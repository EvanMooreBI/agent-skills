---
name: brigade-fire-and-fury-random-army-generation
description: Use when a user asks for Brigade Fire and Fury 2nd Edition random armies, pickup-game forces, fixed historical rosters, or printable unit-label PDFs.
effort: medium
license: MIT
compatibility: Requires PowerShell 7, Node.js, Chrome, Chromium or Microsoft Edge, and Python with PyMuPDF. Random armies also need generator tables made from the user's own rulebook.
metadata:
  author: EvanMooreBI
  version: "1.0.0"
---

# Brigade Fire and Fury Random Army Generation

## Description

Generate randomized forces from the Fictional Army Generator tables in the user's own rulebook, or labels from a validated fixed roster. Do not produce a workbook.

The implementation uses cryptographically secure d10 rolls in production. It
uses the bundled Brigade assets for validation, while a local renderer creates
the printable 24 mm by 25 mm labels.

## Local resources

The generator tables come from the rulebook, so this skill cannot ship them. [local-resources.json](local-resources.json) lists the one resource, `generator-tables`. Random armies require it. Fixed rosters do not, because they use only the bundled effectiveness table.

Before a random-army request, look for the tables in `$AGENT_SKILLS_LOCAL/brigade-fire-and-fury-random-army-generation/generator-tables/`, then in `~/.agent-skills/local/brigade-fire-and-fury-random-army-generation/generator-tables/`. If neither folder holds `01_force_balance_matchups.csv`, tell the user that random armies need the tables and offer the setup below. Run `pwsh -NoProfile -File scripts/Test-BrigadeTables.ps1` to check a folder.

### Set up your rulebook tables

Make this quick for the user. They only take photos. You do the transcription.

1. Ask the user for photos or scans of the Fictional Army Generator for Pick-up Games pages in their own copy of Brigade Fire and Fury 2nd Edition, including the force matchup table. Phone photos, image files or a PDF all work. Never download the tables or copy them from another source.
2. Create the folder `~/.agent-skills/local/brigade-fire-and-fury-random-army-generation/generator-tables/`, or the same layout under `AGENT_SKILLS_LOCAL` when it is set. Tell the user the full path.
3. Read the photos and fill each template from [assets/table-templates](assets/table-templates/) into that folder. Follow [the table format](references/table-format.md): one row per d10 result, exact spellings, and values copied as printed.
4. Run `pwsh -NoProfile -File scripts/Test-BrigadeTables.ps1 -Path <folder>`. Each problem names the table, the context and the roll. Re-read that part of the photo and fix it. If a table is unreadable, ask the user for a closer, sharper photo of that table only.
5. Show the user a short summary of each table, such as the period for each roll and the brigade counts, so they can check it against the page.
6. If the user keeps the tables somewhere else, offer to set `AGENT_SKILLS_LOCAL` to the parent folder and set it only after they agree. On Windows, run `[Environment]::SetEnvironmentVariable('AGENT_SKILLS_LOCAL', '<folder>', 'User')` in PowerShell. On macOS or Linux, add `export AGENT_SKILLS_LOCAL='<folder>'` to the shell profile. The folder must keep the `<skill-name>/generator-tables/` layout.

## Features

- Validates player splits against all eight printed force matchups.
- Supports fixed or random period and theater choices.
- Generates corps, divisions, brigades, batteries, leaders, strengths, experience, morale, effectiveness, and weapons in source order.
- Applies approved cavalry-container, morale-clamp, repeater-cap, and Heavy Rifle rules.
- Selects only source-backed historical commander names.
- Creates mounted and dismounted cavalry pairs in the same column, with a vertical connector.
- Creates local labels that are 24 mm wide by 25 mm high, with one Corps parent
  for each visible Corps group.
- Records every roll, modifier, substitution, name source, balance measure, and validation result.
- Accepts a fixed roster with supplied ratings and a normalized-roster manifest instead of a generation log.
- Refuses to overwrite existing deliverables.

## Usage

### Fixed historical rosters

Use a request with `mode: "fixedRoster"` that matches
[request schema](references/request-schema.json). Fixed requests use the supplied names,
ratings, and weapons. They do not roll, select names, substitute weapons, or
apply balance adjustments.

The script normalizes commander names to surnames, converts written division
ordinals to numeric ordinals, and checks each supplied effectiveness value
against `07_brigade_effectiveness_table.csv`. A fixed run creates a timestamped
folder below the selected output directory. It contains the combined PDF and a
normalized-roster JSON manifest.

Corps, divisions, and brigades accept an optional `exceptionalLeader` boolean.
Omitted flags default to false. The PDF marks exceptional leaders with `E`, and
the normalized manifest preserves every flag. Do not collect random-army intake
choices for a supplied fixed roster.

`standaloneArtillery` creates labels without a parent commander. These labels
join a Corps-connected Unassigned units group. Optional `unassignedBrigades`
records add infantry or cavalry directly under a Corps, using its commander
as the parent row. Each record requires side, corpsId, name, type, stands,
experience, morale, effectiveness and weapon, with optional exceptionalLeader.
See the [unassigned example](examples/example-unassigned-fixed-roster.json).
The source Google Sheets renderer still accepts only Division-assigned units.

### 1. Collect the request

For random-army requests, confirm the generator tables first (see Local resources). Then ask for all missing choices before generation:

1. Total players and the USA/CSA split.
2. One valid force matchup.
3. The Confederate command variant when matchup M1 or M2 is selected.
4. Fixed or random period.
5. Fixed or random theater.
6. Whether to include cavalry.

Use [user intake](references/user-intake.md) to present valid random-army choices.
Use the [request schema](references/request-schema.json) as the data contract.

If the user gives a year, require a fixed compatible period. The years 1862 and 1864 cross period boundaries, so confirm which permitted period the user intends.

### 2. Prepare the request JSON

Save the confirmed choices in a temporary JSON file. Do not add a seed or deterministic roll stream.

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

### 3. Run the generator

Usage:

```powershell
pwsh -NoProfile -File scripts/Generate-BrigadeFireAndFuryLabels.ps1 -RequestPath <request.json>
```

To use a different existing directory:

```powershell
pwsh -NoProfile -File scripts/Generate-BrigadeFireAndFuryLabels.ps1 -RequestPath <request.json> -OutputDirectory <directory>
```

To use tables outside the local resource folders, add `-TablesPath <folder>`. Random runs check the tables before rolling and stop with the first problem.

The default output directory is the current user's Downloads folder. Random runs create:

- `Brigade Fire and Fury Unit Labels yyyy-MM-dd.pdf`
- `Brigade Fire and Fury Unit Labels yyyy-MM-dd - Generation Log.csv`

Fixed runs create a timestamped folder containing the combined PDF and a
normalized-roster JSON manifest. They do not create a generation log.

The public script has no test-roll or seed parameter. The internal deterministic provider exists only for automated tests.

### 4. Review the balance records

For fixed rosters, compare the normalized manifest with the supplied units and
ratings. Skip the random balance-log review below.

For random armies, read both `BalanceMetric` rows and the `BalanceDecision` row in the CSV. Compare:

- real and display-only formations;
- infantry and cavalry brigade counts and stands;
- battery counts;
- exceptional leaders;
- experience, morale, and weapon distributions.

Do not score, reroll, add, remove, or change a unit. No approved rule defines a permitted adjustment. State that no adjustment was applied and that automatic balance adjustment remains a planned improvement.

### 5. Deliver

Confirm the PDF and its matching supplement only after validation succeeds.
If a target exists, choose a new output directory or timestamp without overwriting it.
Rasterize and visually inspect every PDF page before delivery.

## Architecture

`scripts/BrigadeFireAndFury.psm1` executes the generation algorithm from the CSV tables in the local `generator-tables` folder and the bundled `references/tables/07_brigade_effectiveness_table.csv`. `scripts/render-labels.js` uses bundled `assets/Code.gs` validation and rule abbreviations, then creates local 24 mm by 25 mm SVG labels. Its lower text band uses a 14 pt baseline gap and centers one-, two-, and three-row labels. It reserves at least 5 pt above and below the text region. The region uses no more than 90 percent of the area below the dashed divider. Chrome, Chromium or Edge prints the resulting fixed-page HTML to PDF. `scripts/validate_pdf.py` verifies page count, landscape Letter geometry, USA and CSA headers, rasterization, label count, and label rectangles.

The browser measures actual text width before printing. Lines that fit retain
their natural 9 pt appearance. Only overflow causes font reduction or horizontal
compression. The renderer never stretches text to fill unused width.

Generation is transactional. The script creates and validates both files in a temporary directory. It publishes them only after both pass. If the second move fails, it removes only the PDF created by that run.

The integration boundary is a four-table JSON object:

```json
{
  "corps": [],
  "divisions": [],
  "brigades": [],
  "artillery": []
}
```

The renderer validates this API-shaped data before it paginates labels. It groups local output as Side, Corps, Division, and unit labels. One Corps label branches to each visible Division and its Unassigned units group.
Unassigned infantry/cavalry precede standalone artillery, preserving each input
array order. A dismounted cavalry label sits directly below its mounted label
with a 6 pt gap and vertical connector. Mixed primary rows reserve sparse second
rows. Complete bands stay together across pages, with no separate dismounted
or standalone-artillery section. The PowerShell implementation keeps source-table terms such as `Mid-War` separate from renderer configuration terms such as `Mid War`.

Security depends on local validation and a closed production interface. Request values select known CSV rows. The script does not evaluate request text as PowerShell or JavaScript. Browser rendering uses generated local HTML in an isolated temporary profile.

## Rules

- A below-table morale result clamps to the lowest printed band. The CSV records the house rule and every use.
- Allow one infantry repeater and one cavalry repeater per corps.
- Allow `floor(total battery stands on the side / 10)` Heavy Rifle batteries. Horse batteries count. Each battery is one stand.
- Early-war corps cavalry uses a display-only `Corps Cavalry` division. It receives no commander and no leader roll.
- Mid- and late-war cavalry uses a display-only `Independent Cavalry` corps. It receives no commander and no corps roll. Its real cavalry division receives a commander and leader roll.
- A source command of one independent division uses a display-only renderer parent. It receives no corps commander and no corps roll.
- Historical commander selection uses the selected period, then prefers the selected theater and uses a documented cross-theater fallback only within that period. A supplied year is scenario context because the roster contains dated battle snapshots rather than a complete command chronology. It never invents a person.
- Confederate possessive-name collisions use the full commander name and are recorded in the CSV.
- The complete Fresh/Worn/Spent value is one atomic lookup result.

## Examples

- `examples/example-fixed-request.json` shows a fixed Mid War Eastern game.
- `examples/example-random-request.json` shows random period and theater selection.
- `examples/example-generation-log.csv` shows the audit-log columns and representative record types.
- `examples/example-output-summary.txt` shows the fields returned after a successful run.

Expected output contracts are in `expected_outputs`. These small text fixtures describe deliverables without storing a generated army or a stale PDF.

## Installation

Required local tools:

- PowerShell 7 (`pwsh`)
- Node.js
- Google Chrome, Chromium or Microsoft Edge
- Python with PyMuPDF (`pymupdf`)

The script looks for the browser in `CHROME_PATH`, then on `PATH`, then in the usual install folders for Windows, macOS and Linux. The generator does not call a network service at runtime.

Before the first run, check each tool. If one is missing, tell the user what it is for, offer the install command for their platform, and run it only after they agree. Examples: `winget install Microsoft.PowerShell OpenJS.NodeJS.LTS` on Windows, `brew install powershell node` on macOS, and `python -m pip install pymupdf` everywhere.

## Troubleshooting

- `Random armies need the Brigade generator tables`: set up the tables. See Local resources.
- `The generator tables ... have ... problem(s)`: run `scripts/Test-BrigadeTables.ps1` and fix each listed row from the user's photos.
- `Player split ... is not valid`: select a matchup that accepts both side counts. See `references/user-intake.md`.
- `Historical commander pool exhausted`: verify that `commander-command-history.csv` is complete and unchanged.
- `Chrome, Chromium, or Microsoft Edge is required`: install one supported browser, or set `CHROME_PATH` to its executable.
- `Refusing to overwrite existing output`: move the existing dated files or select another output directory.
- `PDF validation failed`: preserve the error text. Check browser availability, PyMuPDF, and renderer asset parity before retrying.

## Contributing

Preserve the recorded original bytes of `assets/Code.gs` and `assets/LabelPdf.html`. Verify their recorded hashes and compare source-project text after CRLF normalization. The local renderer must not reuse the source pagination or SVG geometry. Update the recorded asset hashes only when the owning Brigade renderer changes. Add or change a house rule only after the user approves its gameplay effect. Run every test in [the validation instructions](README.md) before delivery. The tests use invented tables by default. Also run the rules suite with `-TablesPath` against real generator tables when you have them.
