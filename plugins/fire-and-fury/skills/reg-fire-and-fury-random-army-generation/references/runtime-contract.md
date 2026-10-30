---
title: Regimental Fire and Fury runtime contract
type: reference
related:
  - "[[../SKILL]]"
  - "[[label-contract]]"
  - "[[generation-log]]"
---

# Regimental Fire and Fury runtime contract

Generate-RegimentalFireAndFuryLabels.ps1 accepts RequestPath and an optional
existing OutputDirectory. The default directory is Downloads. It has no seed,
test-roll, overwrite, or skip-validation switch. Request choices and validation
retain the existing Regimental behavior. The file request-schema.json remains a
request example, not a JSON Schema.

Check dependencies and destination collisions before rolling. The game engine
finishes its model before the adapter renders any labels. Production rolls and
name selection use operating-system cryptographic randomness.

The adapter keeps stable formation and unit identities. Artillery labels use
unitId:gun:n. Dismounted labels use unitId:dismounted. Divisions use side-DIV1,
matching the existing roll-log convention. Parent labels may repeat once per
continuation page. Unit copies must not repeat or disappear.

The local renderer writes fixed-point SVG and HTML. Chrome, Chromium or Edge prints it to
landscape Letter PDF with 0.25 inch margins. Fitting runs on load, font readiness,
and before printing. It measures widths and ink bounds to preserve equal visible
gaps on three-row labels. Four-row artillery retains its original baselines. Impossible fits produce a validation failure.
The isolated browser has a 30 second rendering timeout.

PyMuPDF checks every final label's approved physical dimensions, text, rows,
font height, fitting limits, geometry, markers, connectors, side order, and identity
multiplicity against the resolved model. The validator supports one side and one
page. It does not accept the render manifest as the authority for dimensions or
unit content. Geometry tolerance is 0.25 point. Text overlap tolerance is 0.02 point. High-resolution ink checks allow 0.2 point
for visible gap comparisons and 0.1 point for star-clearance measurement.
Embedded PDF subset font advances may omit browser kerning. Reduced names must
fill the available width; short regression names must retain their natural size.

The CSV uses Brigade's exact header and preserves every former roster-sheet field
and original roll record. Both files must pass validation before publication.
If CSV publication fails after the PDF move, remove only that run's PDF.
An existing or concurrently created destination must remain unchanged.

Production delivers only the PDF and CSV. Test builds retain requests, resolved
models, manifests, reports, and rasterized pages for visual review.
Print the PDF at Actual size or 100 percent. File validation establishes PDF
geometry, not the accuracy of a printer or its driver.

PowerShell 7, Node.js, Chrome, Chromium or Edge, and Python with PyMuPDF are required.
The browser is found through `CHROME_PATH`, then `PATH`, then the default install
folders for Windows, macOS and Linux. Excel is not required. The source XLSX files
are an optional local resource for maintainers and are not distributed. They must
not be edited or used as output templates.
