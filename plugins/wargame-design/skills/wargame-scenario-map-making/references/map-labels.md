---
title: Terrain labels and objective markings
type: skill-reference
tags: [scenario-maps, typography, objectives]
related: ["../SKILL.md", "map-markings.md"]
---
# Terrain labels and objective markings

Use the [V32 map standard](scenario-map-style.md). Its lettering, artwork and frame rules apply to every map. Preserve scenario geography and native rules.

## Typeface and contrast

Use Times New Roman throughout, with matching regular and regular-italic files for measurement and export. Nothing is bold or semibold, including measurements, rulers, objectives, deployment names, title and N. Preserve established text sizes and guide/arrow stroke weights; regular font weight does not change line geometry. Start terrain names at 7 pt, objective names at 8 pt and deployment names at 9 pt in the reference PDF. White is the selected non-snow color for upright battlefield-interior names and numbers. Italic terrain names use the selected contrast exception below. Outside lettering remains black on the white surround. Snow/pale terrain requires a separate contrast assessment.

All displayed terrain names are italic, including named hills, woods, orchards, roads, waterways, individual buildings and built-up areas. Objective names are always upright and follow the objective rules below. Measurements, rulers, deployment names, unit names and permission notes remain upright. No label or number may have a background box, panel or patch, including measurements and deployment names. A transparent deployment-area overlay is terrain-independent game geometry, not a text backing.

Use plain charcoal `#1b1b17` italic names on pale roads, with no outline or drop shadow. Use white italic names on water, with only a fine 0.12 pt charcoal outline and no offset shadow. Other italic terrain names use black/charcoal or white according to their actual background; avoid displaced shadows and unnecessary outlines. Retain Times New Roman regular italic. This selected simplification supersedes the earlier all-white italic and combined-effect trials. Continue trying 7 pt before the 6.5 pt lower limit, with full path containment and reviewed anchors; do not enlarge or widen terrain merely to reproduce the study's straight 7 pt samples.

Upright white interior text retains v23's 0.38 pt dark outline and close 0.24 mm right/down shadow at 90 percent opacity. SVG uses a 0.06 mm shadow blur; native PDF uses the offset shadow. Paint opaque white fill after the dark stroke to preserve thin stems. Keep outside text and the north arrow black on white without effects. Inspect actual PNG and PDF at reference size, including pale roads, woods and water. The V32 treatment is accepted; new maps still require their own readability review.

## Dynamic unboxed annotations

Position text using its complete font extent and nearby terrain/labels. For a vertical objective guide, evaluate both sides, reverse its text orientation when moving to the other side, and slide along the guide to find open, readable ground. Horizontal captions may slide along the guide or move above/below it. Keep at least 1 mm from other names and important symbols. Keep the entire caption beside its measured span; its wording, distance, reference edge and guide endpoints remain unchanged. Never invent an easier distance to suit the text.

Center deployment names on both axes of their zone. Other area names use the same centering rule below. Preserve exterior dimension placement and labels above inset arrows. Movable guide captions still seek quiet ground, but they must not force centered area names away from their centers. Reserve fixed terrain names before placing movable captions. If a centered name cannot fit, resolve wrapping or another explicit presentation change; do not add a backing or silently move it toward an edge.

## Objective precedence

Objective rules always take precedence over terrain and building rules. A point objective uses a five-point white star centered on its exact coordinate, with a thin dark outline. Use a 2.5 mm circumdiameter and approximately 0.2 pt outline. Its upright name is horizontally centered above the star, with 0.8 mm between the star's top and the text's measured bottom. Reposition lower-priority annotation text if necessary; do not move the objective or its guide endpoints.

For an objective occupying an entire area, center its upright name within that area. It uses the area name rather than a point star through the text. The designated setup center and any required guides remain as established by the scenario. Avoid duplicate terrain/building names. A point objective on a building still uses its upright name above the star. Objective placement takes precedence even for a built-up-area objective.

## Terrain placement

Center area names horizontally and vertically. Rectangles use their geometric midpoint; irregular footprints use their area centroid. Keep complete text and clearance within the feature. If the centroid/text falls outside a concave footprint or the centered name conflicts, report the fit problem rather than silently searching for a quieter off-center location. Built-up areas are the only area-label exception and retain dynamic association with their whole cluster. Linear names follow their paths; individual-building names remain nearby point labels under the building rules.

Label scenario-important proper names, objectives and explicitly requested names. Do not label a generic terrain type merely because it affects play. Generic names such as Low rise, Orchard, Woods or Field are omitted by default, while the actual terrain and its setup/rules remain. A generic type used as an objective still follows objective labeling. Explicitly requested generic names are allowed. Keep displayed area names inside their footprint, except for ordinary buildings and built-up areas below, with complete letter shapes and at least 0.2 mm clearance. When additional names are requested, resolve primary versus secondary prominence without overriding italic terrain styling.

Place road, pike and waterway names along their paths. Search positions dynamically, reject overlap and containment failures, and favor stretches with fewer nearby labels. A quiet end of a road is preferable to a crowded junction. Preserve the complete name. Retain reviewed overrides, subject to the same fit and readability checks.

Gently curved labels are allowed. Keep lettering upright, limit adjacent-letter rotation changes to 10 degrees and total rotation within each word to 45 degrees. Vertical labels read bottom to top. Reject sharp bends and illegible rotation. Use a straighter path segment or another contained placement first.

Linear labels may reduce from 7 pt to 6.5 pt, never smaller. If necessary, the user permits a small local illustrative widening around the name, targeting no more than 3 mm at reference size. Finish both terrain boundaries, material texture, bank/roadside shading and smooth transitions into the original terrain. Do not deliver flat overlay strips, detached water, duplicate banks or rectangular width changes. Use the imagegen skill for raster repair and retain original artwork, edit prompts and the new version. Preserve centerline, connections and gameplay footprint. Inspect actual illustrated banks and full text extents, not just the nominal geometry. A separate label-only trace may refine sub-inch visual registration without changing source/gameplay geometry. Report unresolved fit instead of detaching, abbreviating or shrinking further without direction.

## Buildings and built-up areas

Place an ordinary distinct building's italic name dynamically around its actual footprint. Favor readable backgrounds and avoid nearby labels. Keep a preferred 1 to 2 mm gap, permitting up to 3 mm. Do not force every label above or inside its building. Keep the association obvious and avoid an intervening unrelated feature.

For a cluster, relate its name to the entire supported cluster or approximate settlement footprint. Do not anchor a village name to an arbitrary roof. A readable open space within the cluster is also eligible, provided the label does not obscure roofs. Apply nearby placement and gap rules to the group boundary. Store known membership or footprint explicitly. Naming a cluster does not authorize invented roofs or a new built-up terrain rule.

These rules do not change scale-aware building selection. Naming a building as an objective gives it a scenario role, not a verified historical use, and adds no building effect. The objective exception governs its label.

## Hill marking and verification

Use one dark-brown dashed hill footprint line, `#5b4028`, approximately 0.6 pt, preserving gaps. Remove the broad white backing that creates a doubled ring. Preserve the separate crest and recorded gameplay interpretation. Do not invent relief through styling.

Keep labels and markings independently editable and linked to source features. Resolve placements deterministically and retain results, font identities and overrides. Embed matching fonts in delivery exports. Inspect PNG and freshly rendered PDF at reference size for names, italics, contrast, curvature, star readability, crowding, containment and hill clarity. Exercise individual buildings, whole clusters, point objectives and area objectives. Earlier approvals do not imply approval of a new typography revision.
