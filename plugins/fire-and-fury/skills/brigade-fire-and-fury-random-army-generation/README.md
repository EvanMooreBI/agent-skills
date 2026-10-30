---
title: "Brigade Fire and Fury random army generation"
related:
  - "[[brigade-fire-and-fury-random-army-generation/SKILL]]"
---

# Brigade Fire and Fury random army generation

This skill converts a confirmed pickup-game request into randomized Brigade Fire and Fury 2nd Edition forces. It can also create labels from a fixed historical roster. It does not create a workbook.

## Usage

Random armies need the generator tables from your own rulebook. The skill does not include them. Photograph the Fictional Army Generator pages and let the agent build the tables, as described in `## Local resources` in [SKILL.md](SKILL.md). The [table format](references/table-format.md) lists the files, and `scripts/Test-BrigadeTables.ps1` checks them.

Collect the player split, force matchup, period, theater, and cavalry choice described in [user intake](references/user-intake.md) for random armies. Save those values as JSON that matches [the request schema](references/request-schema.json).

Run:

```powershell
pwsh -NoProfile -File scripts/Generate-BrigadeFireAndFuryLabels.ps1 -RequestPath <request.json>
```

Example: use `examples/example-fixed-request.json` to exercise the fixed-choice request contract in a temporary output directory.

Use `-OutputDirectory <directory>` to override Downloads. The directory must already exist. The generator refuses to overwrite its dated PDF or CSV.

## Fixed roster input

Set `mode` to `fixedRoster` and use the fixed-roster branch of
[the request schema](references/request-schema.json). The request supplies Corps, Divisions,
Brigades, Division artillery, and `standaloneArtillery` records. Use empty arrays
for unused collections. Optional `unassignedBrigades` records support Corps-owned
infantry and cavalry with the same ratings as assigned brigades. Each record
requires side and corpsId instead of divisionId. Corps references retain the
existing case-insensitive convention. The [unassigned example](examples/example-unassigned-fixed-roster.json)
shows forces without assigned Divisions.

Corps, Divisions, and Brigades accept an optional `exceptionalLeader` boolean.
Omitted values default to false. The PDF prints `E` for exceptional leaders,
and the normalized manifest retains the flags. Fixed rosters do not require
player counts, matchups, cavalry choices, or random balance-log review.

The fixed path validates every brigade's supplied effectiveness value against
the bundled table. It removes ranks, initials, and given names from commander
and brigade names, while preserving surname particles such as `von Steinwehr`.
It also converts written division ordinals to values such as `1st Division`.

Fixed runs create a timestamped subfolder under the selected output directory.
It contains the PDF and a normalized-roster JSON manifest. They never create a
roll log, change a supplied rating, or apply balance adjustment.

Standalone artillery labels omit the parent commander. This behavior exists in
the local skill wrapper only. The maintained Google Sheets source still requires
Division artillery.

## Local label layout

The local PDF renderer creates labels that are 24 mm wide by 25 mm high. It
keeps the black face, white border, dashed divider, and upper blank area from
the Brigade design. The lower text band uses a 14 pt baseline gap and centers
one-, two-, and three-row labels within the usable region. It reserves at least
5 pt above and below that region and uses no more than 90 percent of the area
below the divider. It renders one Corps commander label for each visible Corps
group and branches that label to its Division labels. A Corps label repeats only
when that Corps continues on a new page. Unassigned units branch directly from
their Corps, after its Divisions, under a 10 pt upright bold Unassigned units
subheader in a 14 pt heading band. Unassigned brigades precede standalone
artillery, preserving each collection's order. Empty Corps are omitted.

Cavalry counterparts sit directly below their mounted labels in the same column,
with a 6 pt gap and vertical grey connector. Mixed rows leave unused counterpart
positions empty. Complete row bands stay together across pages. There are no
separate dismounted or standalone-artillery sections. A page holds at most seven
physical rows, including counterparts and real space for subheaders. Main rows
have eight primary columns, or nine in the existing no-Corps layout branch.
Three all-cavalry bands occupy six physical rows.

The bundled Google Sheets assets retain their recorded original bytes. The
parity check also compares source-project text after CRLF normalization because
Git can use different checkout line endings for the source files.
They still create 25.4 mm-wide labels and repeat a Corps label for each Division
segment. The maintained Google Sheets project documents these open issues. The
local renderer does not inherit those layout rules.

Label text starts at 9 pt. The browser measures the actual rendered width and
shrinks only lines that overflow. Names can shrink to 7 pt. Remaining overflow
uses horizontal compression. Text that already fits is never stretched.

## Output

Random runs use this base name:

`Brigade Fire and Fury Unit Labels yyyy-MM-dd`

Fixed runs use a timestamped `Brigade Fire and Fury Fixed Unit Labels` folder.

The PDF uses local 24 mm by 25 mm label geometry. It uses bundled Google Sheets
assets only for input validation and rule abbreviations. The CSV records
configuration, random d10 rolls, modifiers, adjusted rolls, table results,
weapon substitutions, historical-name sources, balance measures, and validation
results.

## Requirements

- PowerShell 7
- Node.js
- Chrome, Chromium or Microsoft Edge (set `CHROME_PATH` if it is not found)
- Python with PyMuPDF

All generation is local. Production dice use `RandomNumberGenerator.GetInt32(1, 11)`. Deterministic rolls are available only through the internal module test interface.

## Validation

Run the package tests from this skill's folder:

```powershell
pwsh -NoProfile -File tests/Test-Rules.ps1
pwsh -NoProfile -File tests/Test-Renderer.ps1
pwsh -NoProfile -File tests/Test-EndToEnd.ps1
pwsh -NoProfile -File tests/Test-TextFitting.ps1
node tests/test-layout.js
pwsh -NoProfile -File tests/Test-PdfFixtures.ps1 -OutputDirectory <new-absolute-QA-directory>
python -B tests/test-validation.py <QA-directory>/mixed-unassigned <new-negative-directory>
```

The tests use the invented tables in `tests/fixtures/synthetic-tables`, so they
run without the rulebook. To test your own generator tables, add
`-TablesPath <folder>` to `Test-Rules.ps1`, `Test-Renderer.ps1`,
`Test-EndToEnd.ps1` and `Test-PdfFixtures.ps1`.

The renderer test always verifies the recorded raw asset SHA-256 hashes. When
you maintain the Google Sheets project, pass its `apps-script` directory through
`-SourceRoot` to also check source text parity with `Code.gs` and
`LabelPdf.html` after CRLF normalization. The end-to-end
test creates both deliverables in a temporary directory, validates the PDF,
checks the CSV, verifies collision handling, and removes its output.

The retained PDF fixtures cover six period/theater contexts, historical and
exceptional leaders, text fitting, continuation, unassigned-only forces, mixed
paired rows and 24 mm packing boundaries. The historical fixture retains 52 labels
on two pages.
Their test-only name selector does not change production randomness. Capture
baseline artifacts before a dimensional change with `-CaptureBaseline`, then
use `-BaselineDirectory <baseline-directory>` to compare complete resolved models
and logs. The candidate independently checks every label's complete text against
the model using whole-page glyph extraction, effective vertical font sizes,
bounds, baselines, hierarchy, connectors and exact physical dimensions. The
private QA layout index uses SVG coordinates and parent keys, not SVG text as
its content oracle. Inspect every accepted PDF page and close-up before delivery.

Empty Corps commanders remain invalid production inputs. The no-Corps layout
branch is covered directly by the layout tests. The corruption suite separately
checks physical dimensions and manifest claims, including incorrect matching
pairs, and proves that missing text, font scaling and broken connectors fail.

The text-fitting test checks the printed PDF. It confirms that `(Ricketts)` and
a long narrow name retain 9 pt, while a wide name shrinks without clipping.

Automatic force adjustment is intentionally disabled. The log reports descriptive balance measures and the decision `No adjustment applied: balance rules not yet approved.` See the [balance policy](references/balance-policy.md).
