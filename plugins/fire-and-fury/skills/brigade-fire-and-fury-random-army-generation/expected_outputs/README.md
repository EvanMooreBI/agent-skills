---
title: "Expected output contract"
related:
  - "[[brigade-fire-and-fury-random-army-generation/SKILL]]"
---

# Expected output contract

Every successful run publishes one combined landscape Letter PDF with USA pages
before CSA pages. Each cavalry brigade has a matching dismounted label directly
below it, joined vertically. Paired bands remain together. Corps-owned unassigned
units follow that Corps's Divisions under an Unassigned units subheader.
There are no separate dismounted or standalone-artillery sections.

Random runs publish a UTF-8 CSV generation log beside the PDF. Both use the
requested dated base filename. The CSV uses the columns in
[the expected header](expected-generation-log-header.csv).

Fixed runs publish the PDF and a normalized-roster JSON manifest in a new
timestamped folder. The manifest preserves supplied ratings and explicit
exceptional-leader booleans. Standalone artillery labels omit parent commanders.
Fixed runs do not create a generation log.

The [render manifest contract](expected-render-manifest.json) describes label
geometry and counts for both modes.
