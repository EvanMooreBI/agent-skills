"""Retain independently reviewable Brigade fixture artifacts. Test-only runner."""
import argparse
import csv
import hashlib
import json
import subprocess
import sys
from pathlib import Path

sys.dont_write_bytecode = True
import pymupdf as fitz
from find_browser import find_browser

ROOT = Path(__file__).resolve().parents[1]
HEADERS = 'Sequence,RecordType,Step,Side,FormationId,UnitId,RawRoll,Modifiers,AdjustedRoll,Result,Substitution,SourceTable,Notes'.split(',')


def run(args):
    result = subprocess.run([str(a) for a in args], capture_output=True, text=True, timeout=45,
                            creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0))
    if result.returncode:
        raise RuntimeError(f'{args[0]} failed: {result.stdout}\n{result.stderr}')
    return result.stdout


def write_json(path, data):
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding='utf-8')


def boundary(count, corps=True, cavalry=False, standalone=0):
    data = dict(corps=[], divisions=[], brigades=[], artillery=[], standaloneArtillery=[])
    for side, units in [('USA', count), ('CSA', 1)]:
        cid, did = f'{side} Test Corps', f'{side} Division'
        data['corps'].append({'Side': side, 'Corps Name': cid, 'Corps Commander': f'{side} Corps' if corps or side == 'CSA' else '', 'Exceptional Leader': 'No', 'Theatre': 'Eastern', 'Period': 'Mid War'})
        data['divisions'].append({'Corps Name': cid, 'Division Name': did, 'Commander': f'{side} Division', 'Exceptional Leader': 'No', 'Side': side})
        for index in range(units):
            data['brigades'].append({'Division Name': did, 'Brigade Name': f'{side} Unit {index+1}', 'Type': 'Cavalry' if cavalry and side == 'USA' else 'Infantry', 'Stands': 9, 'Experience': 'Veteran', 'Morale': 'Reliable', 'Weapon': 'Rifle Musket', 'Exceptional Leader': 'No'})
    for index in range(standalone):
        data['standaloneArtillery'].append(dict(side='USA', corpsId='USA Test Corps', name=f'Battery {index+1}', experience='Veteran', weapon='Light Rifle'))
    return data


def synthetic_fixtures(directory):
    cases = {'continuation': json.loads((ROOT/'tests/fixtures/render-continuation.json').read_text())}
    for count in (8,9): cases[f'corps-{count}'] = boundary(count)
    for count in (56,57): cases[f'rows-{count}'] = boundary(count)
    for count in (70,71):
        cases[f'dismounted-{count}'] = boundary(count, cavalry=True)
        cases[f'standalone-{count}'] = boundary(1, standalone=count)
    for count in (24,25): cases[f'pairs-{count}'] = boundary(count,cavalry=True)
    for count in (56,57): cases[f'unassigned-{count}'] = boundary(1,standalone=count)
    mixed=boundary(56)
    for row in mixed['brigades'][48:56]: row['Type']='Cavalry'
    cases['last-row-pair']=mixed
    mixed=boundary(9);mixed['brigades'][1]['Type']='Cavalry';cases['mixed-row-holes']=mixed
    for name, data in cases.items():
        target = directory/name
        target.mkdir()
        write_json(target/'model.json', dict(RenderData=data))
        write_json(target/'request.json', dict(testOnlyFixture=name))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path)
    parser.add_argument('--capture-baseline', action='store_true')
    parser.add_argument('--baseline-directory', type=Path)
    args = parser.parse_args()
    synthetic_fixtures(args.directory)
    browser = find_browser()
    results = []
    for directory in sorted(p for p in args.directory.iterdir() if p.is_dir()):
        model = json.loads((directory/'model.json').read_text(encoding='utf-8-sig'))
        compared=bool(args.baseline_directory and (args.baseline_directory/directory.name/'model.json').exists())
        comparison='exact' if compared else 'new-fixture'
        if compared:
            baseline = json.loads((args.baseline_directory/directory.name/'model.json').read_text(encoding='utf-8-sig'))
            # Older synthetic standalone fixtures lacked their now-required owner.
            if directory.name.startswith('standalone-'):
                comparison='synthetic-owner-added'
                for row in baseline['RenderData']['standaloneArtillery']: row['corpsId']='USA Test Corps'
            if model != baseline: raise ValueError(f'Baseline model/log parity changed: {directory.name}')
        write_json(directory/'render-data.json', model['RenderData'])
        run(['node', ROOT/'scripts/render-labels.js', directory/'render-data.json', directory/'labels.html', directory/'render-manifest.json'])
        pdf = directory/'labels.pdf'
        run([browser, '--headless=new', '--disable-gpu', '--disable-extensions', '--no-pdf-header-footer', f'--user-data-dir={directory.resolve()/"browser-profile"}', f'--print-to-pdf={pdf.resolve()}', (directory/'labels.html').resolve().as_uri()])
        validation = json.loads(run([sys.executable, '-B', ROOT/'scripts/validate_pdf.py', pdf, directory/'render-manifest.json', directory/'previews']))
        if 'RollLog' in model:
            supplement = directory/'generation-log.csv'
            with supplement.open('w', encoding='utf-8', newline='') as stream:
                writer = csv.DictWriter(stream, fieldnames=HEADERS)
                writer.writeheader(); writer.writerows(model['RollLog'])
            with supplement.open(encoding='utf-8', newline='') as stream:
                rows = list(csv.DictReader(stream))
            expected = [{k: '' if r.get(k) is None else str(r.get(k,'')) for k in HEADERS} for r in model['RollLog']]
            if rows != expected: raise ValueError('CSV round-trip changed model logs')
        else:
            supplement = directory/'normalized-roster.json'
            write_json(supplement, model.get('NormalizedRoster', model['RenderData']))
        if not args.capture_baseline:
            from verify_fixture_pdf import verify
            validation['independent'] = verify(directory)
        with fitz.open(pdf) as document:
            for i, page in enumerate(document,1):
                for name, scale in [('actual-size',1),('closeup',3)]:
                    page.get_pixmap(matrix=fitz.Matrix(scale,scale), alpha=False).save(directory/'previews'/f'{name}-{i:03d}.png')
        validation.update(fixture=directory.name, sha256=hashlib.sha256(pdf.read_bytes()).hexdigest(), supplementSha256=hashlib.sha256(supplement.read_bytes()).hexdigest(), baselineParity=compared,baselineComparison=comparison)
        write_json(directory/'validation.json', validation)
        results.append(validation)
        print(f'FIXTURE|{directory.name}|PASS|pages={validation["pages"]} labels={validation["labelCount"]}', flush=True)
    write_json(args.directory/'suite-results.json', results)
    print(f'FIXTURE-SUMMARY|PASS|{len(results)} retained Brigade PDFs')


if __name__ == '__main__': main()
