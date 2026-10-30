---
title: Scenario map measurement and north-marker standard
type: reference
status: current
related:
  - ../SKILL.md
  - scenario-map-style.md
---
# Scenario map measurement and north-marker standard

Use [terrain labels and objective markings](map-labels.md) for regular-weight white upright interior text, contrast-aware italic proper/requested terrain names, upright objective precedence and white stars. Center area names except for dynamic built-up-area labels. Guide captions remain movable and unboxed. Omit generic type names. Selected terrain italics use charcoal on pale roads and white on water, without offset shadows. The V32 composition is accepted as the reusable standard.

Apply these defaults to all scenario maps. Preserve the playable rectangle's dimensions, aspect ratio, and accepted geometry. Keep markings editable and separate from terrain artwork. Print-space measurements below describe the reference export, not tabletop distances.

## Accepted compact white surround

The [V32 map standard](scenario-map-style.md) sets the complete appearance, frame, markings and grid format.

Use a pure white external surround, `#ffffff`. Keep approved terrain edge-to-edge inside the playable rectangle. Put the single compact scenario title, table rulers, necessary entry/exit permission notes and external north arrow in this surround. Keep labels, grid, zones, guides and arrows as editable elements. No sidebar, decorative paper mat, development revision/status line, research footer or repeated rules summary belongs in the composed player map. Record candidate identity and technical notes in filenames, metadata and supporting records. A requested date may accompany the title on its single row.

Use these print-space dimensions for the accepted north-up frame:

| Element | Accepted placement and appearance |
|---|---|
| Playable rectangle | Fit proportionally within 240 mm width and 160 mm height; never stretch or change table geometry |
| White surround | 10 mm left, 10 mm right, 18 mm top, 15 mm bottom, measured from playable border to component edge |
| Outer clearance | At least 3 mm between any outside text/marker extent and the component edge |
| Table border | Black, 1 pt |
| Title | Black regular serif, 10 pt, centered over playable width; baseline 11 mm above top border |
| Ruler text | Black serif, 7.5 pt; bottom baseline 3.5 mm below border; left labels right-aligned 2 mm left of border, baseline 1 mm below tick |
| Ruler ticks | Black, 0.5 pt, extend 1 mm outward |
| Deployment width text | 7 pt, baseline 1.5 mm above zone's top boundary; no duplicate dimension line |
| North marker | Existing specification below, with 5 mm centerline offset and 9 pt regular N |
| Top entry frontage | Side-colored 0.8 pt bracket, 4.5 mm above border; black 7.5 pt note baseline 6.5 mm above border |
| Bottom entry frontage | Side-colored 0.8 pt bracket, 7 mm below border; black 7.5 pt note baseline 11 mm below border |
| Frontage end caps | 1.5 mm total length, 0.5 pt; match the frontage color |

For a 96 by 60-inch reference table, the printed playable rectangle is 240 by 150 mm and the complete component is 260 by 183 mm. The single-page PDF uses those complete component bounds directly, with no second page mat or extra padding. Its PNG and editable SVG use the same composition and proportions. These are reference-print sizes, not a tabletop mat or extra table space. Tabletop placement labels still use whole inches.

Use the default margins only when all required content fits. The renderer expands a side gutter to 18 mm for vertical whole-edge/bounded-frontage notes; place that bracket 10 mm and its rotated 7.5 pt note baseline 14 mm outside the border. A side point-entry dimension reserves a 22 mm gutter. Side point-arrow tails stop 3 mm outside the table so they do not cross the north shaft. A rotated true-bearing marker reserves at least 28 mm on the right; a bottom point-exit label reserves 18 mm below. Retain the actual bearing. Record expanded dimensions and the reason. If long titles, several permissions or labels still collide, expand or rearrange that frame explicitly rather than shrink text, omit permissions, stretch the table or silently change accepted geometry.

The machine-readable preset in `assets/v32/presentation-v32.json` names this composition `compact-white`. A frame-style change must never alter the terrain bitmap. Approval of terrain does not approve new frame dimensions automatically.

## Objective placement guides

Locate each objective center with one horizontal guide and one vertical guide. Select their reference edges independently. The horizontal guide starts at the nearer left or right edge. The vertical guide starts at the nearer top or bottom edge. For equal distances, use left and bottom respectively.

Label each guide with the actual distance from its selected edge to the objective center and name that edge. A guide from the right reports distance from the right, rather than the objective's coordinate from the left. Both guides must terminate at the same objective center. Preserve the approved line weight and text treatment while keeping terrain, objectives, and deployment labels readable.

For a table of width W and height H with an objective at x from the left and y from the bottom, compare x with W minus x for the horizontal guide. Compare y with H minus y for the vertical guide. The smaller distance determines each reference edge. These calculations describe guide construction, not raw coordinate labels for the scenario prose.

Keep deployment dimensions and offsets, objective measurements, and table rulers on the map. Retain terrain dimensions, boundaries, crests, and placement references in editable geometry and reproducible setup prose. Do not add terrain dimension lines or terrain reference guides to the map unless the user requests them. This restriction does not remove playable terrain boundaries or elevation markings needed to identify a tabletop feature.

## Grid format

Use solid 12-inch square grid lines in effective grey `#484c43`, at 25 percent opacity and approximately 0.71 pt in the reference print. This is V32's approved format. Preserve its print weight across table sizes. Keep the grid editable, below labels and other measured markings, and lower in contrast than objective guides. No dashes or smaller subdivisions. Use the shared standard's grid preset and new-source gate.

## External north arrow

Use a bold black north arrow in the external right margin instead of a compass rose. North-up is the default when orientation is not already fixed. In a north-up map, the arrow extends alongside the full playable height. Its bottom endpoint aligns with the bottom table edge and its tip aligns with the top table edge.

Use these dimensions in the printed reference:

| Element | Required treatment |
|---|---|
| Arrow centerline | 5 mm outside the playable rectangle's right border |
| Shaft | Black, 1 pt stroke |
| Head | Solid black, 4 mm long and 3 mm wide |
| North label | N, black, 9 pt regular, horizontally centered over the arrow tip |
| Label baseline | 3 mm above the arrow tip |
| Page clearance | At least 3 mm from every marker or label extent to the page edge |

Reserve enough right and top margin for the arrowhead, label, and page clearance. Widen the export margin or page as needed. Do not stretch the map or change its playable geometry to fit the marker. Keep the exported map at equal horizontal and vertical scale.

Preserve actual north. If an accepted map has another orientation, point the marker toward true north and shorten or reposition it within the right gutter as needed. Do not use an upright arrow that misstates the bearing. Record the orientation exception and any marker placement or length change in the revision record.

## Verification

- Recalculate each objective guide from its selected edge and verify that both guides end at the objective center. Check each axis separately, including left/bottom ties.
- Confirm that terrain remains reproducible from the geometry and setup prose without unrequested terrain measurement lines on the map.
- Inspect the reference export for north-arrow alignment, true bearing, print-space dimensions, label clearance, and minimum page clearance. Inspect the PNG for the same placement and legibility.
- Verify that the margin change leaves playable aspect ratio, scale, deployment measurements, and objective locations unchanged.
- For the compact white frame, measure the complete PDF component, each surround width, border/ruler text and title/permission baselines. Check pure white corners, at least 3 mm outer clearances, no text collisions and matching PNG/SVG/PDF composition. Check that revision/research notes stay in records and approved raster bytes remain unchanged.
