---
name: reg-fire-and-fury-random-army-generation
description: Use when generating random Regimental Fire and Fury USA or CSA armies, printable unit-label PDFs, and auditable generation logs.
effort: medium
license: MIT
compatibility: Requires PowerShell 7, Node.js, Chrome, Chromium or Microsoft Edge, and Python with PyMuPDF.
metadata:
  author: EvanMooreBI
  version: "1.0.0"
---

# Regimental Fire and Fury random army generation

Generate a combined label PDF and CSV generation log. Labels are 24 mm wide and
25 mm high. Use the local renderer. Do not generate or export Excel workbooks.

## Intake

Collect the existing Regimental choices:

1. Year from 1861 through 1865, or Early War, Mid War, or Late War.
2. Eastern or Western Theatre.
3. USA, CSA, or both sides.
4. Zero to five brigades per side, each Infantry or Cavalry.
5. Independent infantry regiment, cavalry regiment, and artillery battery counts.
6. Whether eligible Western Early or Mid War Light Howitzers may become Mountain Howitzers.
7. Optional formation names, commanders, talents, regiment names, and battery names.

Require at least one brigade or independent unit across the request. Use one division
per requested side. Preserve existing names, overrides, historical pools, and fallback
disclosures. The [request example](references/request-schema.json) shows the accepted
shape. It is an example, not a JSON Schema.

## Usage

Save the confirmed request as UTF-8 JSON, then run from this skill directory:

```powershell
pwsh -NoProfile -File scripts/Generate-RegimentalFireAndFuryLabels.ps1 -RequestPath <request.json> -OutputDirectory <existing-directory>
```

OutputDirectory defaults to the user's Downloads folder. A run publishes:

- Regimental Fire and Fury Unit Labels yyyy-MM-dd.pdf
- Regimental Fire and Fury Unit Labels yyyy-MM-dd - Generation Log.csv

Existing targets cause an error. Select a new directory rather than overwrite them.
Production uses operating-system cryptographic randomness. The public command has no
seed, test-roll, overwrite, or skip-validation option.

## Rules and label content

Use [army-generation-rules.json](references/army-generation-rules.json) as executable
truth. Preserve global table order 1, 2, 2.1, 3, 3.1, 4, 5, 6, and 7, then optional
Mountain Howitzer checks. Within each table, process USA before CSA and display order.
Apply modifiers before resolution. Preserve Crack +2, the one-brigade artillery
column, open-ended bands, and the Brave Colonel, Repeater, and Heavy Rifle caps.

Do not add Brigade game rules, balance adjustments, or unsupported scenario rules.
Follow the [label contract](references/label-contract.md). Keep all label rows and
compact codes, one label per artillery gun, and one dismounted label per cavalry
regiment, directly below its mounted label with a vertical connector. Keep the
white Brave Colonel star on both. Independent units branch directly from the
Division under an Unassigned units subheader. Division Artillery retains its command label.

## Proof and delivery

The command validates the final PDF and reimports the CSV before publishing either
file. The [runtime contract](references/runtime-contract.md) defines geometry, fitting,
dependencies, and failure behavior. The [CSV contract](references/generation-log.md)
defines Brigade's column layout and the retained Regimental roster data.

Before delivery, rasterize and inspect every final PDF page, including close-ups of
artillery, stars, wrapped unit rows, and continuation pages. Confirm exact artifact
identity. Check names, ratings, gun copies, parent labels, connectors, and margins.
Print at Actual size or 100 percent. Do not select Fit to page.

Report both paths, requested sides, page and label counts, brigade and unit counts,
gun-label counts, and fallback-name use. Repair failed criteria before delivery.

## Dependencies and maintenance

Use PowerShell 7, Node.js, Chrome, Chromium or Edge, and Python with PyMuPDF. Excel and
network services are not required. The script looks for the browser in `CHROME_PATH`,
then on `PATH`, then in the usual install folders for Windows, macOS and Linux.

Before the first run, check each tool. If one is missing, tell the user what it is for,
offer the install command for their platform, and run it only after they agree. Examples:
`winget install Microsoft.PowerShell OpenJS.NodeJS.LTS` on Windows, `brew install powershell node`
on macOS, and `python -m pip install pymupdf` everywhere.

Follow the [test instructions](README.md) before changing this skill. Preserve rule
and name data and inspect every affected PDF page after changes. When real-name data
is available, the standard PDF suite also builds fixtures with real unit and commander
names, alongside the golden and synthetic stress fixtures.

## Local resources

The generator needs no local resources. Everything it reads ships with the skill.
[local-resources.json](local-resources.json) lists two optional resources for maintainers:

- `source-workbooks`: the Excel workbooks that `army-generation-rules.json` came from.
  `tests/Test-ProtectedSources.ps1` checks their hashes when they are present.
- `real-name-label-data`: a CSV of real unit and commander names for two extra PDF fixtures.

Tests look for each resource in `$AGENT_SKILLS_LOCAL/reg-fire-and-fury-random-army-generation/<id>/`,
then in `~/.agent-skills/local/reg-fire-and-fury-random-army-generation/<id>/`. A missing
resource prints `SKIP` with the reason. Do not ask a user who only generates armies to set them up.

## Troubleshooting

- Existing output: select a new directory. Preserve the existing PDF and CSV.
- Missing browser or PyMuPDF: install the named dependency and rerun the request. If the
  browser is installed in an unusual place, set `CHROME_PATH` to its executable.
- Font or geometry failure: retain the error and reproduce it with the PDF fixtures.
  Do not bypass validation or change rules to make a label fit.
- Incorrect print size: select Actual size or 100 percent in the printer dialog.
