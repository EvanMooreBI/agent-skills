"""Require maintained real names and retained source evidence in the PDF suite."""
import argparse
import csv
import hashlib
import json
from pathlib import Path


def check(directory):
    source = directory / 'real-name-source.csv'
    provenance = json.loads((directory / 'real-name-provenance.json').read_text(encoding='utf-8-sig'))
    assert hashlib.sha256(source.read_bytes()).hexdigest() == provenance['sha256'].lower(), 'Real-name source hash mismatch'
    with source.open(encoding='utf-8-sig', newline='') as stream:
        rows = list(csv.DictReader(stream))
    model = json.loads((directory / 'resolved-model.json').read_text(encoding='utf-8-sig'))
    assert not model['FallbackNamesUsed'], 'Invented fallback in a real-name fixture'
    assert {d['Side'] for d in model['Divisions']} == {'USA', 'CSA'}, 'Real names must cover both sides'
    arms = set()
    for division in model['Divisions']:
        side_rows = [r for r in rows if r['Faction'] == division['Side']]
        commanders = {r['Commander'] for r in side_rows if r['Label_Type'] == 'Leader'}
        commanders.update(r['Unit_Name'].split()[-1] for r in side_rows if r['Label_Type'] == 'Gun')
        assert division['Commander'] in commanders, 'Division commander absent from source'
        for brigade in division['Brigades']:
            assert brigade['Commander'] in commanders, 'Parent commander absent from source'
            for unit in brigade['Units']:
                assert unit['Name'] in {r['Unit_Name'] for r in side_rows if r['Unit_Type'] == unit['Arm'] and r['Label_Type'] != 'Leader'}, 'Unit name absent from source'
                assert unit['Commander'] in commanders, 'Unit commander absent from source'
                assert unit['NameProvenance'] == 'User override', 'Unit did not use the source override'
                assert unit['CommanderProvenance'] == 'User override', 'Commander did not use the source override'
                if unit['Arm'] == 'Artillery':
                    assert unit['Commander'] == unit['Name'].split()[-1], 'Battery commander differs from source name'
                arms.add(unit['Arm'])
    assert arms == {'Infantry', 'Cavalry', 'Artillery'}, 'Real-name arm coverage changed'
    manifest = json.loads((directory / 'render-manifest.json').read_text(encoding='utf-8-sig'))
    labels = [label for page in manifest['pages'] for label in page['labels']]
    assert any(l['brave'] for l in labels), 'Missing real-name Brave Colonel coverage'
    if directory.name == 'real-names-assigned':
        assert any(l['role'] == 'cavalry' and l['brave'] for l in labels), 'Missing real-name mounted star'
        assert any(l['role'] == 'dismounted' and l['brave'] for l in labels), 'Missing real-name dismounted star'
    assert any(l['role'] == 'dismounted' for l in labels), 'Missing real-name dismounted coverage'
    return len(labels)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('fixtures', type=Path)
    args = parser.parse_args()
    for name in ('real-names-assigned', 'real-names-unassigned'):
        count = check(args.fixtures / name)
        print(f'TEST|{name}-source-reconciliation|PASS|{count} labels')


if __name__ == '__main__':
    main()
