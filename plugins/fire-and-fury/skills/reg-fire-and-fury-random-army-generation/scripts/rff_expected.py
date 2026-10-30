"""Independent expectations from the resolved Regimental model, not render output."""

def formations_and_units(model):
    result = []
    for division in model['Divisions']:
        division_id = f"{division['Side']}-DIV1"
        result.append(('Formation', dict(Kind='Division', Side=division['Side'], Id=division_id,
            ParentId='', Name=division['Name'], Commander=division['Commander'], Talent=division['Talent'],
            Theatre=division['Theatre'], Period=division['Period'], DisplayOrder=0,
            Notes=division['Notes'], CommanderProvenance=division['CommanderProvenance'])))
        for brigade in sorted(division['Brigades'], key=lambda b: b['DisplayOrder']):
            fields = ('Id','Type','Name','Commander','Talent','DisplayOrder','IsActual','IsIndependent','IsDivisionArtillery','Notes','CommanderProvenance')
            record = {k: brigade[k] for k in fields}
            record.update(Kind='Brigade', Side=division['Side'], ParentId=division_id, Theatre=model['Theatre'], Period=model['Period'])
            result.append(('Formation', record))
            for unit in sorted(brigade['Units'], key=lambda u: u['DisplayOrder']):
                fields = ('BrigadeId','Id','Name','Commander','Arm','Stands','Guns','Experience','Morale','WeaponCode','BraveColonel','DisplayOrder','Notes','NameProvenance','CommanderProvenance')
                record = {k: unit[k] for k in fields}
                record.update(Side=division['Side'], Weapon=model['Rules']['weapons'][unit['WeaponCode']], Effectiveness=effectiveness(model,unit))
                result.append(('Unit', record))
    return result


def effectiveness(model, unit):
    if unit['Arm'] == 'Artillery':
        return f"{unit['Guns']} guns"
    return model['Rules']['effectiveness'][str(unit['Stands'])][unit['Morale']]


def label_expectations(model):
    expected = {}
    for division in model['Divisions']:
        side = division['Side']
        division_id = f'{side}-DIV1'
        expected[division_id] = dict(role='division', side=side, parent='', brave=False,
            rows=[division['Name'], division['Commander'], division['Talent']], kinds=['name','name','rating'])
        for brigade in sorted(division['Brigades'], key=lambda b:b['DisplayOrder']):
            if not brigade['Units']:
                continue
            if not brigade['IsIndependent']:
                expected[brigade['Id']] = dict(role='brigade', side=side, parent=division_id, brave=False,
                    rows=[brigade['Name'],brigade['Commander'],brigade['Talent']], kinds=['name','name','rating'])
            for unit in sorted(brigade['Units'], key=lambda u:u['DisplayOrder']):
                experience = model['Rules']['experienceCodes'][unit['Experience']]
                if unit['Arm'] == 'Artillery':
                    rows = [f"({brigade['Commander']})",unit['Name'],unit['Commander'],f"{experience} {unit['WeaponCode']}"]
                    ids = [f"{unit['Id']}:gun:{i}" for i in range(1,int(unit['Guns'])+1)]
                    kinds = ['name','name','name','rating']
                else:
                    rows = [f"({brigade['Commander']})",unit['Name'],f"{experience} {effectiveness(model,unit)} {unit['WeaponCode']}"]
                    ids = [unit['Id']]
                    kinds = ['name','name','rating']
                for identity in ids:
                    expected[identity] = dict(role=unit['Arm'].lower(),side=side,parent=division_id if brigade['IsIndependent'] else brigade['Id'],group=brigade['Id'],brave=unit['BraveColonel'],rows=rows,kinds=kinds)
                if unit['Arm'] == 'Cavalry':
                    expected[f"{unit['Id']}:dismounted"] = dict(role='dismounted', side=side, parent=division_id if brigade['IsIndependent'] else brigade['Id'], group=brigade['Id'], brave=unit['BraveColonel'],
                        rows=[rows[0],f"Dismounted {unit['Name']}",rows[2]], kinds=kinds)
    return expected
