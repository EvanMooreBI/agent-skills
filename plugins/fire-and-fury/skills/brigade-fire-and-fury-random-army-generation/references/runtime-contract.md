---
title: Brigade Fire and Fury generator runtime contract
related:
  - "[[brigade-fire-and-fury-random-army-generation/SKILL]]"
---

# Runtime contract

The public entry point accepts a request JSON path, an optional existing
output directory, and an optional generator tables folder. It has no seed,
deterministic-roll, overwrite, or skip-validation switch. Random runs read the
generator tables from `-TablesPath`, then from the local resource folders, and
check them before the first roll. Fixed runs need only the bundled
effectiveness table. The [request schema](request-schema.json) defines both
random-army and fixed-roster inputs.

Fixed requests use `mode: "fixedRoster"` and supply their names and ratings.
Corps, divisions, and brigades accept an optional `exceptionalLeader` boolean.
Omitted flags default to false. Strings, numbers, and null flags are invalid.
The rendered tables convert booleans to `Yes` or `No`. The normalized manifest
stores explicit booleans for every corps, division, and brigade.

Fixed generation normalizes commander surnames and division ordinals. It checks
supplied effectiveness against the bundled table. It never rolls, substitutes
weapons, changes ratings, or adjusts force balance. Standalone artillery labels
have no parent commander. Each fixed run publishes a PDF and normalized-roster
JSON in a new timestamped folder. Optional unassignedBrigades accepts Corps-owned
infantry/cavalry. It is omitted from legacy normalized outputs when absent from
the request. Unassigned-only Corps need no synthetic Division. Publication
requires valid Corps and at least one unit across the supported collections.

Random generation uses `System.Security.Cryptography.RandomNumberGenerator.GetInt32(1, 11)`
for every source d10. Historical commander selection uses a secure random index
and does not record that index as a d10 roll. Random runs publish a dated PDF
and CSV generation log.

The generator finishes all table lookups before rendering. The renderer validates
the four table-shaped arrays and local unassigned collections before browser printing.
Only the original validator's exact no-units result can be bypassed when the
assigned collections are empty and valid local unassigned units supply content.
Other source errors remain fatal. Bundled source assets are unchanged.
PyMuPDF confirms the manifest page count, landscape Letter geometry, side headers,
24 mm by 25 mm label rectangles, and successful rasterization of every page.

The browser measures each label line at its preferred 9 pt size after layout.
Text that fits keeps its natural size and width. Only overflowing text shrinks.
Names and parent commanders can shrink to 7 pt. Ratings stay at 9 pt.
If text still overflows at its minimum size, SVG fitting compresses its width.
The renderer never stretches glyphs to fill unused space. Fitting runs when the
page loads, when fonts are ready, and before printing.

Every cavalry unit has one matching dismounted label directly below it with a
vertical connector. A paired row is indivisible across page breaks. Mixed rows
retain empty lower slots. Unassigned units branch to their owning Corps beneath
a repeated Unassigned units subheader. Separate flat sections are not produced.

Publishing is all-or-nothing. Both targets are checked before rendering.
Both temporary files must pass validation before the first move. If supplement
publication fails after the PDF move, the script removes only that run's PDF.
