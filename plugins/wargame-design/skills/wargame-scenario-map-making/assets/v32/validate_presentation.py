"""Check new finished sources against accepted V32; never rewrite historical sources."""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

PRESET = Path(__file__).with_name('presentation-v32.json')
GRID_PRESET = Path(__file__).with_name('grid-style.json')


def grid_settings(table: dict) -> dict:
    """Return source grid settings at the approved reference-print stroke weight."""
    if not isinstance(table, dict):
        raise ValueError('table must contain finite positive width and height')
    width, height = table.get('width'), table.get('height')
    if not all(isinstance(v, (int, float)) and not isinstance(v, bool)
               and math.isfinite(v) and v > 0 for v in (width, height)):
        raise ValueError('table must contain finite positive width and height')
    grid = json.loads(GRID_PRESET.read_text(encoding='utf-8'))
    reference_scale = min(240 / (20 * width), 160 / (20 * height)) * 72 / 25.4
    return {'grid_stroke_scale': grid['reference_stroke_pt'] / reference_scale,
            'grid_opacity': grid['opacity']}


def validate_source(source: dict) -> list[str]:
    """Return conformance failures without changing source or renderer defaults."""
    required = json.loads(PRESET.read_text(encoding='utf-8'))
    if not isinstance(source, dict) or not isinstance(source.get('presentation'), dict):
        return ['presentation must be an object containing the V32 preset']
    actual = source['presentation']
    failures = []
    for key, expected in required.items():
        if key not in actual:
            failures.append(f'presentation.{key} is required: {expected!r}')
        elif actual[key] != expected or isinstance(actual[key], bool) != isinstance(expected, bool):
            failures.append(f'presentation.{key} must be {expected!r}; found {actual[key]!r}')
    for key in actual.keys() - required.keys() - {'font_files'}:
        failures.append(f'presentation.{key} is outside the accepted V32 preset')
    if 'font_files' in actual:
        faces = actual['font_files']
        if not isinstance(faces, dict) or set(faces) - {'regular', 'italic'}:
            failures.append('presentation.font_files may configure regular and italic faces only')
        elif any(not isinstance(path, str) or not path.strip() for path in faces.values()):
            failures.append('presentation.font_files paths must be nonempty strings')
    try:
        required_grid = grid_settings(source.get('table'))
    except ValueError as exc:
        failures.append(str(exc))
    else:
        for key, expected in required_grid.items():
            value = source.get(key)
            if not isinstance(value, (int, float)) or isinstance(value, bool) or not math.isclose(value, expected, rel_tol=1e-9, abs_tol=1e-9):
                failures.append(f'{key} must be {expected!r} for the accepted V32 grid; found {value!r}')
    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    args = parser.parse_args()
    try:
        failures = validate_source(json.loads(args.source.read_text(encoding='utf-8-sig')))
    except (OSError, ValueError) as exc:
        parser.exit(2, f'Cannot check source: {exc}\n')
    if failures:
        for failure in failures:
            print(failure)
        return 1
    print('V32 presentation and grid conform; geometry and artistic fidelity require separate checks.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
