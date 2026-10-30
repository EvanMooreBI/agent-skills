"""Guard the actual new-map gate against omitted and conflicting legacy modes."""
import copy
import json
import unittest

from validate_presentation import PRESET, validate_source


class V32PresentationTests(unittest.TestCase):
    def setUp(self):
        self.preset = json.loads(PRESET.read_text(encoding='utf-8'))
        self.source = {'title': 'New scenario', 'presentation': copy.deepcopy(self.preset),
                       'table': {'width': 96, 'height': 60}, 'grid_stroke_scale': 2, 'grid_opacity': 0.25}

    def test_accepted_grid_settings_are_required(self):
        for key, legacy in [('grid_stroke_scale', 1), ('grid_opacity', 0.22)]:
            for missing in (True, False):
                with self.subTest(key=key, missing=missing):
                    source = copy.deepcopy(self.source)
                    if missing:
                        del source[key]
                    else:
                        source[key] = legacy
                    self.assertTrue(validate_source(source))

    def test_grid_weight_tracks_reference_print_size(self):
        for width, height, scale in [(96, 60, 2), (72, 48, 1.5), (60, 96, 3)]:
            with self.subTest(table=(width, height)):
                source = copy.deepcopy(self.source)
                source.update(table={'width': width, 'height': height}, grid_stroke_scale=scale)
                self.assertEqual(validate_source(source), [])
                source['grid_stroke_scale'] = scale + 0.1
                self.assertTrue(validate_source(source))

    def test_invalid_grid_values_and_table_are_rejected(self):
        for key in ('grid_stroke_scale', 'grid_opacity'):
            for value in (True, False, None, '0.25', float('nan'), float('inf')):
                with self.subTest(key=key, value=value):
                    source = copy.deepcopy(self.source)
                    source[key] = value
                    self.assertTrue(validate_source(source))
        for table in (None, {}, {'width': True, 'height': 60}, {'width': 0, 'height': 60},
                      {'width': 96, 'height': float('inf')}):
            with self.subTest(table=table):
                source = copy.deepcopy(self.source)
                source['table'] = table
                self.assertTrue(validate_source(source))

    def test_new_source_conforms_without_mutation(self):
        before = copy.deepcopy(self.source)
        self.assertEqual(validate_source(self.source), [])
        self.assertEqual(self.source, before)

    def test_every_omitted_setting_is_rejected(self):
        for key in self.preset:
            with self.subTest(key=key):
                source = copy.deepcopy(self.source)
                del source['presentation'][key]
                self.assertTrue(validate_source(source))

    def test_every_changed_setting_is_rejected(self):
        for key in self.preset:
            with self.subTest(key=key):
                source = copy.deepcopy(self.source)
                source['presentation'][key] = None
                self.assertTrue(validate_source(source))

    def test_legacy_omissions_and_overrides_are_rejected(self):
        self.assertTrue(validate_source({}))
        self.assertTrue(validate_source({'presentation': []}))
        for key, value in [('objective_guide_style', 'Semibold'),
                           ('text_shadow', 'strong'), ('italic_text', 'shadow-only')]:
            with self.subTest(key=key):
                source = copy.deepcopy(self.source)
                source['presentation'][key] = value
                self.assertTrue(validate_source(source))

    def test_existing_regular_and_italic_font_configuration_is_allowed(self):
        self.source['presentation']['font_files'] = {'regular': 'times.ttf', 'italic': 'timesi.ttf'}
        self.assertEqual(validate_source(self.source), [])
        self.source['presentation']['font_files']['bold'] = 'timesbd.ttf'
        self.assertTrue(validate_source(self.source))

    def test_invalid_font_configuration_and_numeric_boolean_are_rejected(self):
        self.source['presentation']['font_files'] = {'regular': ''}
        self.assertTrue(validate_source(self.source))
        self.source['presentation'].pop('font_files')
        self.source['presentation']['offset_arrow_clearance_mm'] = True
        self.assertTrue(validate_source(self.source))


if __name__ == '__main__':
    unittest.main()
