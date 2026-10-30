---
title: V32 scenario map standard
type: style-standard
tags: [scenario-maps, terrain, typography, measurements]
related:
  - ../SKILL.md
  - map-labels.md
  - map-markings.md
---
# V32 scenario map standard

V32 is one standard covering terrain artwork, labels, typography, symbols, north arrow, frame, dimensions, placement logic and grids. It applies across rules systems and seasons. Adapt vegetation, crops and depicted snow to the scenario within its illustration style.

## Terrain artwork

Use image generation for raster terrain artwork, and keep the vector markings editable and separate.

| Material | Artistic treatment |
|---|---|
| Open ground | Muted sage and khaki grass, fine quiet texture and restrained natural variation. Extra contrast must not imply new terrain or relief. |
| Woods | Full, irregular interlocking crowns in muted olive, yellow-green and darker shaded detail, with natural projecting fringes and identifiable extents. Avoid flat ink canopies. |
| Fields | Distinct muted brown ploughed parcels and lighter tan harvested or stubble parcels, restrained cultivation rows and established edges. Match the state to the scenario. Do not impose standing crops. |
| Orchard | Separated small trees in readable rows over a moderately darker muted-green floor, visibly distinct from woods. Add foliage to suit the season while keeping the illustration style and spacing. |
| Roads | Pale peach or buff textured surfaces, coherent shaded edges, smooth connections and finished transitions where labels sit. |
| Waterways | Dark slate-blue water with subtle variation, coherent irregular banks and continuous main and tributary connections. |
| Relief | Restrained natural shading within the defined footprints, a single dark-brown dashed footprint and a distinct crest. Add no unlisted levels or decorative ridges. |
| Structures and crossings | Small overhead roofs, bridges and partial rail boundaries at a consistent scale, texture and shading. Preserve selected structures, material distinctions and openings. |

V32 has no universal numeric raster palette. Do not sample one shaded pixel as a mandatory fill. Compare whole materials at reference print size. A terrain type not covered above, such as explicit dense woods or a new boundary material, needs an explicit resolution consistent with V32.

Geography, terrain classifications, native effects, table size, bearing, scale, forces and objectives all come from each scenario. Preserve source evidence and accepted geometry. Appearance creates no terrain rule.

## Lettering, symbols and measured composition

Follow the [label standard](map-labels.md) and the [marking standard](map-markings.md). They cover the regular Times New Roman lettering, white upright interior lettering, plain charcoal road italics, white fine-outlined water italics, objective stars, label precedence, centered area names and dynamic unboxed guide captions.

Use a compact white surround, an external north arrow on the right, a solid 12-inch grid, bottom and left rulers, nearest-edge objective guides and exterior deployment dimensions. Use whole-inch setup geometry. Measure each objective axis independently, and break ties toward left and bottom. Detached inset-arrow tips keep 2 mm of clearance in the reference print without changing the labeled tabletop distance. Preserve true north and proportional scale. Widen gutters only when the content or bearing needs it, as the marking standard describes.

## Grid format

Use solid square grid lines at 12-inch tabletop intervals, effective grey `#484c43`, 25 percent opacity and a stroke of approximately 0.71 pt in the reference print. Keep the exact weight of 0.7086614173 pt when calculating another export scale. Grid lines sit below labels and measurement markings and have less contrast than objective guides. Do not dash them or copy the guide styling. Keep complete bottom and left rulers. Add no smaller subdivisions.

[grid-style.json](../assets/v32/grid-style.json) records these values. For a renderer that takes a scale factor, call `grid_settings(table)` from [validate_presentation.py](../assets/v32/validate_presentation.py). It returns the `grid_stroke_scale` and `grid_opacity` that keep the printed weight for that table size.

## Renderer settings and checks

[presentation-v32.json](../assets/v32/presentation-v32.json) is the machine-readable form of this standard. A renderer that reads a JSON source can use it as the source's `presentation` object. Keep its required values when adding font-file configuration. Run the validator before rendering and again before delivery:

```text
python <skill-dir>/assets/v32/validate_presentation.py path/to/map-source.json
```

The validator requires every V32 presentation setting, the grid opacity and the correct grid weight for the source table. It rejects conflicting presentation switches and does not change the source. A renderer that does not read this JSON must produce equivalent typography, markings, measurements and reference-print composition. Run the validator's tests with `python -m unittest discover -s <skill-dir>/assets/v32 -p test_presentation.py`.

Validate the geometry separately. Keep numbered candidates. Check terrain registration, and review the PNG and a freshly rendered PDF at reference size. Check the fonts, full labels, contrast, clipping, true bearing, frame dimensions and measurements. Passing the numeric checks does not approve new artwork or a new scenario's geography.
