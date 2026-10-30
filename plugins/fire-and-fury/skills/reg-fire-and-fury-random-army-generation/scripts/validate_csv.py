"""Reconcile the delivered Brigade-format CSV with the original Regimental model."""
import argparse
import csv
import hashlib
import json
import sys
from pathlib import Path

sys.dont_write_bytecode = True
from rff_expected import formations_and_units

HEADERS = 'Sequence,RecordType,Step,Side,FormationId,UnitId,RawRoll,Modifiers,AdjustedRoll,Result,Substitution,SourceTable,Notes'.split(',')


def validate(path, model, request, pdf):
    with Path(path).open(encoding='utf-8-sig', newline='') as stream:
        reader = csv.DictReader(stream)
        if reader.fieldnames != HEADERS:
            raise ValueError('CSV column names or order changed')
        rows = list(reader)
    if [r['Sequence'] for r in rows] != [str(i) for i in range(1,len(rows)+1)]:
        raise ValueError('CSV sequence is not continuous')
    if any(None in r or any(v is None for v in r.values()) for r in rows):
        raise ValueError('Malformed CSV row')
    configuration = json.loads(rows[0]['Result'])
    if rows[0]['RecordType'] != 'Configuration' or configuration != dict(request=request, period=model['Period'], theatre=model['Theatre'], year=model['Year'], modelVersion=model['Version'],csvVersion=1,labelWidthMm=24,labelHeightMm=25,fallbackNamesUsed=model['FallbackNamesUsed']):
        raise ValueError('CSV request or configuration differs from source')
    cursor = 1
    for original in model['RollLog']:
        row = rows[cursor]
        override = original['Modifiers'] == 'Override'
        expected = dict(RecordType='Override' if override else 'Roll', Step=original['Table'], Side=original['Side'], FormationId=original['FormationId'], UnitId=original['UnitId'], RawRoll='' if override else str(original['RawRoll']), Modifiers=original['Modifiers'], AdjustedRoll='' if override else str(original['AdjustedRoll']), Result=original['Result'], Substitution=original['CapOrSubstitution'], SourceTable=f"army-generation-rules.json:{original['Table']}", Notes=original['NameProvenance'])
        if any(row[k] != v for k,v in expected.items()):
            raise ValueError(f'CSV roll/provenance mismatch at sequence {cursor+1}')
        cursor += 1
    roster = formations_and_units(model)
    for kind, expected in roster:
        row = rows[cursor]
        if row['RecordType'] != kind or row['Step'] != 'ROSTER' or json.loads(row['Result']) != expected:
            raise ValueError(f'CSV resolved roster mismatch for {expected["Id"]}')
        if row['Side'] != expected['Side'] or row['FormationId'] != (expected['BrigadeId'] if kind == 'Unit' else expected['Id']) or row['UnitId'] != (expected['Id'] if kind == 'Unit' else ''):
            raise ValueError('CSV roster identity mismatch')
        if row['RawRoll'] or row['AdjustedRoll'] or row['Modifiers'] or row['Substitution'] or row['Notes'] or row['SourceTable'] != 'New-RegimentalFireAndFuryArmy':
            raise ValueError('Unexpected CSV roster metadata')
        cursor += 1
    if len(rows) != cursor+2 or [r['RecordType'] for r in rows[cursor:]] != ['Validation','Validation'] or [r['Step'] for r in rows[cursor:]] != ['PDF','CSV']:
        raise ValueError('CSV validation records missing or unexpected records present')
    if rows[-1]['Result'] != f'Validated {len(rows)} records':
        raise ValueError('CSV validation count mismatch')
    proof=json.loads(rows[-2]['Result'])
    if proof.get('pages',0)<1 or proof.get('labels',0)<1:
        raise ValueError('CSV lacks PDF validation proof')
    if proof.get('sha256')!=hashlib.sha256(Path(pdf).read_bytes()).hexdigest():
        raise ValueError('CSV validation proof does not match the delivered PDF')
    return dict(records=len(rows),rosterRecords=len(roster),rolls=len(model['RollLog']))


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ('csv','model','request','pdf'):parser.add_argument(name,type=Path)
    args=parser.parse_args()
    try:
        result=validate(args.csv,json.loads(args.model.read_text(encoding='utf-8-sig')),json.loads(args.request.read_text(encoding='utf-8-sig')),args.pdf)
        print(json.dumps(result));return 0
    except (ValueError,KeyError,IndexError,TypeError,OSError) as error:
        print(f'CSV validation failed: {error}',file=sys.stderr);return 1


if __name__=='__main__':
    raise SystemExit(main())
