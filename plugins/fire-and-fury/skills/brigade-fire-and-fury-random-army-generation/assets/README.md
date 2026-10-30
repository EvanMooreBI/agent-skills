---
title: "Renderer assets"
related:
  - "[[brigade-fire-and-fury-random-army-generation/SKILL]]"
---

# Renderer assets

`Code.gs` and `LabelPdf.html` are exact copies of the Brigade Fire and Fury Google Sheets renderer. Do not edit them locally. [the renderer test](../tests/Test-Renderer.ps1) compares both files with their owning source by SHA-256 before it exercises local rendering.

The test always checks the recorded hashes. Pass the owning Brigade project's `apps-script` directory through `-SourceRoot` to also compare the source text.

`table-templates/` holds header-only CSV files for the generator tables. See [the table format](../references/table-format.md).
The [source provenance](../references/source-provenance.json) records asset hashes.
