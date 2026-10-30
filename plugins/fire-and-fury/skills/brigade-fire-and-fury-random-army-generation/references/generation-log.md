---
title: Brigade Fire and Fury generation log contract
---

# Generation log

The CSV has these columns in order:

`Sequence,RecordType,Step,Side,FormationId,UnitId,RawRoll,Modifiers,AdjustedRoll,Result,Substitution,SourceTable,Notes`

`RecordType` identifies configuration, rolls, structure decisions, name selection, house rules, naming rules, balance measures, the balance decision, and validation. `RawRoll` is populated only for actual d10 events. `Modifiers` explains arithmetic or a fixed user choice. `Substitution` records caps, house-rule resolution, or fallback behavior. `SourceTable` identifies the controlling local source.

Rows remain in execution order. The sequence is continuous and starts at one. The final records include the two side balance summaries, the no-adjustment decision, PDF validation, and CSV validation.
