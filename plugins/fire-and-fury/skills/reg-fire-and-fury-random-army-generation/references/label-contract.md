---
title: Regimental Fire and Fury label contract
type: reference
related:
  - "[[../SKILL]]"
  - "[[runtime-contract]]"
---

# Regimental Fire and Fury label contract

## Page and physical geometry

Use landscape US Letter, 792 x 612 points, with 18 point margins. The content
rectangle is 756 x 576 points. Each label is exactly 24 mm wide and 25 mm high.
Convert millimetres to points with 72 / 25.4. Never use Excel or page auto-fitting.

Labels have a black background, white border and text, and a white dashed divider
28 percent down the label. Keep the space above the divider blank.
The white Brave Colonel marker sits below it.

Use 6 point horizontal, vertical and division-to-brigade gaps, with 1.5 point grey
connectors behind labels. The page header is at y14 and the first row at y28 in
content coordinates. Main rows hold eight primary units. A page holds at most
seven physical label rows, including dismounted counterparts.

## Label rows

Preserve these rows, including empty slots:

| Role | Rows in order |
|---|---|
| Division | Division name; division leader; leader talent |
| Brigade | Brigade name; commander; leader talent |
| Regiment | Brigade commander in parentheses; regiment name; experience, effectiveness, weapon |
| Artillery | Brigade commander in parentheses; battery name; battery commander; experience and weapon |
| Dismounted Cavalry | Regiment format, with Dismounted before the regiment name |

Use Crk, Vet, Trn, and Grn experience codes and the weapon codes in
[army-generation-rules.json](army-generation-rules.json). Preserve the complete
effectiveness result. Each artillery gun receives a label.

## Text and marker placement

Use bold Helvetica or Arial at a preferred 9 points, with 4 point side insets.
Measure actual browser widths. Only overflowing names and parent commanders may
shrink to 7 points. Talents and rating rows retain 9 point vertical size.
If text still overflows, compress its width. Never enlarge, wrap, truncate, or
drop label text. Do not apply unconditional horizontal scaling.

Let H be label height in points and D be 0.28H. Four-row text uses the band
[D+5,H-5]. Three-row text uses [D+8,H-5] to reserve marker clearance on all labels.
Measure the selected font's natural 9 point ascent and descent. The original
reference baseline gap is min(14,floor(4*(bandHeight-L)/(n-1))/4), where L is the
font line height. Preserve the bottom reference baseline. Four-row artillery
keeps its original placement, with 10.25 point spacing for the inspected Arial font.

For three rows, fit widths first and measure ink bounds at 100 times the fitted
font size. Divide those metrics by 100. Use equal visible gaps no larger than
the smaller original visible gap. Choose the largest gap that preserves the
text band, at least 0.1 point between font boxes, and marker clearance. Empty
rows retain a logical slot using the original font metrics. Reset all fitting
before each load, font-ready and print pass. Natural names and ratings retain
9 point vertical size under the existing fitting policy.

Keep the white Brave Colonel polygon at x=labelWidth-10, y=D+3.5. Its top is
3 points below the divider's visible stroke edge. This moves only the polygon
2 points down from its previous position. Preserve the text fitting and baselines,
including the existing minimum first-ink reservation at D+9.927 on three-row labels.
Require at least 1 point from the marker's bottom to the first visible text row.
If the fixed margins cannot satisfy these constraints, fail validation and
discuss the case with the user. Do not change margins or the marker to force fit.
Add the marker to the regiment and matching dismounted label.
Its polygon is unchanged:

```text
3,0 3.735,1.989 5.853,2.073 4.189,3.386 4.763,5.427 3,4.25 1.237,5.427 1.811,3.386 0.147,2.073 2.265,1.989
```

## Hierarchy and PDF sections

Render Division, Brigade or Division Artillery, then connected unit rows. Center
an intermediate command over its allocated unit block, including paired rows.
Center the Division between its first and last immediate group centers. Branch
only to the first primary label in each row; do not link adjacent unit labels.
Trunks span the parent entry and primary-row centers.

Independent units have an Unassigned units subheader instead of a command box.
Use 10 point upright bold text in a 14 point heading band, aligned to the unit
column. Connect the group directly to the Division. Keep Division Artillery's
command box. Display actual brigades and Division Artillery first, followed by
independents. Preserve order within each group and all existing unit label text.
The independent formation and commander records remain in the model and CSV.

Place each dismounted cavalry label directly below its mounted label, with the
same column and a 6 point gap. Connect their border centers vertically. A primary
row containing cavalry reserves a second row; leave other lower slots empty.
Keep complete row bands together across page breaks. Three cavalry bands use
six physical rows. Do not create separate dismounted pages or headings.

Use actual heights, including heading bands, to paginate. Keep a complete group
together when it fits fresh. Repeat command context once per continuation and
repeat the unassigned heading with its first band. Never leave a heading alone.
One combined PDF contains requested USA pages before CSA pages. Do not add corps
labels or unrequested sides. A requested empty side in an otherwise valid request
has a division-only page. Do not invent units.
