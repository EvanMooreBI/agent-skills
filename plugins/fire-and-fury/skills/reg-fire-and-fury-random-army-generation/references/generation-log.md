---
title: Regimental Fire and Fury CSV generation log
type: reference
related:
  - "[[../SKILL]]"
  - "[[runtime-contract]]"
---

# Regimental Fire and Fury CSV generation log

Use UTF-8 CSV with Brigade's exact columns and order:

```text
Sequence,RecordType,Step,Side,FormationId,UnitId,RawRoll,Modifiers,AdjustedRoll,Result,Substitution,SourceTable,Notes
```

Sequences start at one and remain continuous. Records appear in this order:

1. Configuration contains the original request, effective context, model and CSV
   versions, geometry, and fallback summary as compact JSON in Result.
2. Roll and Override records preserve every original log entry in execution order.
3. Formation and Unit records contain the complete final roster as compact JSON
   in Result, in side, hierarchy, and display order.
4. PDF and CSV Validation records finish the file.

Map original Table to Step, CapOrSubstitution to Substitution, and NameProvenance
to Notes. Use army-generation-rules.json:<table> as SourceTable for source-table
events. Keep actual dice, modifiers, adjusted results, raw weapon outcomes, and
cap explanations unchanged. Override dice fields are blank. They are not rolls.

Formation records contain IDs and parent IDs, names, commanders, talents, types,
theatre and period, display order, pseudo-formation flags, notes, and commander
provenance. Unit records contain every former regiment or artillery roster field,
including stands or guns, experience, morale, full weapon name, final weapon code,
effectiveness, Brave Colonel status, ordering, notes, and name/commander provenance.
One Unit record describes a battery and its gun count. The PDF expands its guns.

Reimport must reconstruct the former roster sheets and the original log. Preserve
raw rolled weapons separately from final substituted weapons. Do not add Brigade
balance calculations or game rules. No separate roster JSON is delivered.
