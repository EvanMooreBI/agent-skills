---
title: Regimental generation output expectations
type: reference
related:
  - "[[../references/runtime-contract]]"
  - "[[../references/generation-log]]"
---

# Regimental generation output expectations

A successful public run publishes exactly one combined PDF and one CSV.
The [expected CSV header](expected-generation-log-header.csv) fixes column order.
PDF pages use landscape US Letter, 18 point margins, and 24 x 25 mm labels.
They hold up to seven physical rows. Each dismounted label sits beneath and
connects to its mounted label. Independent units form a Division-connected
Unassigned units group; no separate dismounted section is produced.

The CSV must end with PDF and CSV validation records. Its resolved formation and
unit records preserve the former workbook roster fields. The report includes
both artifact paths, requested sides, PDF pages, labels, and fallback-name use.

Generated PDFs and reports belong in a new ignored QA directory. They are not
static expected-output files because production generation uses fresh randomness.
The [golden armies](../tests/fixtures/golden-armies.json) instead fix deterministic
gameplay and naming expectations for regression tests.
