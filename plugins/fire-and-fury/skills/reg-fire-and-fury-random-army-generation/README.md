---
title: Regimental Fire and Fury generator validation
type: runbook
related:
  - "[[SKILL]]"
  - "[[references/runtime-contract]]"
  - "[[references/generation-log]]"
---

# Regimental Fire and Fury generator validation

This package generates 24 x 25 mm labels through local SVG and headless browser
printing. The game engine retains its previous rules and request behavior.
The Brigade technical source hashes and protected Regimental baseline hashes are in
[render provenance](references/render-provenance.json).

Run from this skill directory. Use a new absolute or relative output directory
for every test run. The examples below keep review artifacts in a repository's
ignored worktree folder.

```powershell
pwsh -NoProfile -File tests/Test-Rules.ps1
node tests/test-renderer.js
pwsh -NoProfile -File tests/Test-ProtectedSources.ps1
pwsh -NoProfile -File tests/Test-PdfFixtures.ps1 -OutputDirectory <new-suite-directory>
pwsh -NoProfile -File tests/Test-LargeArmies.ps1 -OutputDirectory <new-large-directory>
python -B tests/test-validation.py <suite-directory>/text-fitting <new-negative-directory>
python -B tests/test-layout-validation.py <suite-directory> <new-layout-negative-directory>
pwsh -NoProfile -File tests/Test-EndToEnd.ps1 -OutputDirectory <new-e2e-directory>
```

The seven original fixture models and logs are captured in
[golden armies](tests/fixtures/golden-armies.json). They use the old engine with
test-only deterministic roll and name choices. PDF tests compare complete resolved
models, names, provenance, and roll order before rendering. The test-only name
override does not change production randomness.

When real-name data is available, the PDF suite also builds assigned and
unassigned USA/CSA fixtures with real unit and commander names. It reads the
first CSV in the optional `real-name-label-data` local resource (see
[local-resources.json](local-resources.json)), or the file passed with
`-RealNameDataPath <csv-path>`. Without either, it prints `SKIP` for these two
fixtures. With data, the suite fails if a fixture uses invented fallback names
or its names do not reconcile to the source. Each case retains the source CSV
and its SHA-256 provenance. Both cases exercise infantry, cavalry pairs, artillery
and Brave Colonels. These are name and layout tests. Their organization and ratings
come from the existing generation rules and are not a historical order of battle.
Retain the original golden and synthetic width/escaping fixtures for regression
and deliberate typography stress.

Each build retains its resolved model, request, render manifest, PDF, CSV, validation
report, and preview images in its test directory. Inspect every page and close-up.
The negative suite changes actual PDFs as well as manifests, model expectations, and
CSV fields. It must reject every corruption.

The physical-width cases cover 20, 23 and 25 mm rectangles with correct metadata,
correct 24 mm PDFs with false metadata, and matching false pairs. A divider test
preserves the 4 point dash and 3 point gap even when the label ends in a gap.
The text fixture includes a name that fits naturally at 24 mm but overflowed at
23 mm. The seven original golden armies remain unchanged. Pair/group cases also check
missing and displaced counterparts, vertical links, heading ownership, equal
visible text gaps, and clearance around the Brave Colonel star.

The public command publishes only the combined PDF and CSV. Its temporary review
files are removed after validation. Rasterize the delivered PDF again for visual
review and retain its hash in the review record. Preserve existing output files.

The reference workbooks are not distributed. Maintainers keep them in the
optional `source-workbooks` local resource, and `Test-ProtectedSources.ps1`
checks their recorded bytes when they are present. They are not runtime
templates. Protected text files are hashed with LF line endings, so the check
gives the same result on Windows and Unix checkouts. Google Sheets project specifications describe their own products
and are not changed by this local skill update.
