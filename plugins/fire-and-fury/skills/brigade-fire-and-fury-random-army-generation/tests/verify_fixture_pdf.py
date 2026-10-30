"""Reconcile complete Brigade fixture text against models, independently of SVG text."""
import argparse
from collections import Counter, defaultdict
import csv
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

sys.dont_write_bytecode = True
import pymupdf as fitz

ROOT = Path(__file__).resolve().parents[1]
W, H, MARGIN, EPS = 24*72/25.4, 25*72/25.4, 18, .25
EXPERIENCE = dict(Crack='Crk', Veteran='Vet', Experienced='Exp', Green='Grn')
WEAPONS = dict(zip(['Rifle Musket','Mixed Muskets','Rifle & Carbine','Repeater','Breechloader','Smoothbore Musket','Shotgun & Hunting Rifle','Fortress Gun','Siege Gun','Naval Gun','Heavy Rifle','Light Rifle','Rifle & Napoleon','Rifle & Smoothbore','Napoleon','Smoothbore'], ['RM','MM','RC','RP','BL','SM','SH','FG','SG','NG','HR','LR','RN','RS','NP','SB']))


def require(condition, message):
    if not condition: raise ValueError(message)


def near(a,b,eps=EPS): return abs(a-b) <= eps
def value(x): return str(x or '').strip()
def exceptional(row): return value(row.get('Exceptional Leader')).lower() in ('yes','true','1')


def expected(data):
    with (ROOT/'references/tables/07_brigade_effectiveness_table.csv').open(encoding='utf-8-sig',newline='') as stream:
        effectiveness={int(r['starting_stands']):r for r in csv.DictReader(stream)}
    records={}; models=[]
    def put(identity,role,rows,side,root,group=None,mounted=None):
        require(identity not in records,'Duplicate expected identity')
        records[identity]=dict(role=role,rows=rows,side=side,root=root,group=group,mounted=mounted)
        return identity
    def brigade(row,parent,identity,side,root,group):
        name=value(row['Brigade Name'])+(' E' if exceptional(row) else '')
        ratings=f"{EXPERIENCE[row['Experience']]} {effectiveness[int(row['Stands'])][row['Morale']]} {WEAPONS[row['Weapon']]}"
        prefix=[f'({parent})']
        put(identity,'brigade',prefix+[name,ratings],side,root,group)
        if value(row['Type']).lower()=='cavalry':put(identity+':dismounted','brigade',prefix+['Dismounted '+name,ratings],side,root,group,identity)
        return identity
    for side in ['USA','CSA']:
        roots=[]; header=None
        for corps in data['corps']:
            if corps['Side']!=side:continue
            cid=value(corps['Corps Name']);rid=f'{side}--{cid}';commander=value(corps['Corps Commander']);groups=[]
            header=header or f"{side} - {value(corps['Theatre'])} - {value(corps['Period'])}"
            for division in data['divisions']:
                if division['Corps Name']!=cid or division['Side']!=side:continue
                did=division['Division Name'];ids=[]
                for index,row in enumerate(r for r in data['brigades'] if r['Division Name']==did):
                    ids.append(brigade(row,value(division['Commander']),f'{did}:brigade:{index}',side,rid,did))
                for index,row in enumerate(r for r in data['artillery'] if r['Division Name']==did):
                    identity=f'{did}:artillery:{index}'
                    ids.append(put(identity,'artillery',[f"({value(division['Commander'])})",value(row['Battery Name']),f"{EXPERIENCE[row['Experience']]} {WEAPONS[row['Weapon']]}"] ,side,rid,did))
                if ids:
                    put(did,'division',([f'({commander})'] if commander else [])+[value(division['Commander'])+(' E' if exceptional(division) else '')],side,rid,did)
                    groups.append(dict(id=did,ids=ids,command=did,heading=False))
            belongs=lambda row:row['side']==side and value(row['corpsId']).casefold()==cid.casefold()
            uid=rid+':unassigned';ids=[]
            for index,row in enumerate(r for r in data.get('unassignedBrigades',[]) if belongs(r)):
                converted={'Brigade Name':row['name'],'Type':row['type'],'Stands':row['stands'],'Experience':row['experience'],'Morale':row['morale'],'Weapon':row['weapon'],'Exceptional Leader':row['exceptionalLeader']}
                ids.append(brigade(converted,commander,f'{rid}:unassigned:{index}',side,rid,uid))
            for index,row in enumerate(r for r in data.get('standaloneArtillery',[]) if belongs(r)):
                identity=f'{rid}:standalone:{index}'
                ids.append(put(identity,'artillery',[value(row['name']),f"{EXPERIENCE[row['experience']]} {WEAPONS[row['weapon']]}"] ,side,rid,uid))
            if ids:groups.append(dict(id=uid,ids=ids,command=None,heading=True))
            if groups:
                if commander:put(rid,'corps',[commander]+(['E'] if exceptional(corps) else []),side,rid)
                roots.append(dict(id=rid,command=rid if commander else None,groups=groups,capacity=8 if commander else 9))
        if roots:models.append(dict(side=side,header=header,roots=roots))
    return records,models


def layout_index(html):
    pages=[]
    for svg in re.findall(r'<svg\b.*?</svg>',html,re.S):
        tree=ET.fromstring(svg);labels=[]
        for group in tree.findall('.//{*}g'):
            if group.get('class')!='label':continue
            rect=group.find('{*}rect')
            labels.append(dict(id=group.get('data-id'),role=group.get('data-label-role'),root=group.get('data-root-key'),group=group.get('data-group-key') or None,mounted=group.get('data-mounted-id'),x=float(rect.get('x')),y=float(rect.get('y')),width=float(rect.get('width')),height=float(rect.get('height'))))
        pages.append(dict(kind=tree.get('data-page-kind'),labels=labels))
    return pages


def characters(page):
    chars=[]
    for block in page.get_text('rawdict')['blocks']:
        for line in block.get('lines',[]):
            for span in line['spans']:
                for char in span['chars']:
                    chars.append(dict(char,font=span['font'],color=span['color'],ascender=span['ascender'],descender=span['descender']))
    return chars


def text_rows(rect,chars):
    inside=[c for c in chars if rect.x0-.02<=c['origin'][0]<=rect.x1+.02 and rect.y0<=c['origin'][1]<=rect.y1]
    groups=[]
    for char in inside:
        group=next((g for g in groups if near(g[0]['origin'][1],char['origin'][1],.02)),None)
        if group is None: group=[];groups.append(group)
        group.append(char)
    groups.sort(key=lambda g:g[0]['origin'][1])
    for group in groups: group.sort(key=lambda c:c['origin'][0])
    return groups


def check_text(rect,rows,chars,fonts,role):
    groups=text_rows(rect,chars)
    actual=[''.join(c['c'] for c in g) for g in groups]
    require(actual==rows,f'Complete PDF text mismatch: {actual!r} != {rows!r}')
    band_top=.28*H+5; band_height=H-.28*H-10
    first=band_top+(band_height-(9+(len(rows)-1)*14))/2+9*.75
    for index,group in enumerate(groups):
        require(all(c['color']==0xffffff for c in group),'Nonwhite label text')
        bbox=fitz.Rect(group[0]['bbox'])
        for c in group[1:]: bbox |= fitz.Rect(c['bbox'])
        require(bbox.x0>=rect.x0+4-.02 and bbox.x1<=rect.x1-4+.02,'Text exceeds side insets')
        require(bbox.y0>=rect.y0+band_top-.02 and bbox.y1<=rect.y0+H-5+.02,'Text exceeds lower band')
        require(near((bbox.x0+bbox.x1)/2,(rect.x0+rect.x1)/2),'Text is not centered')
        require(near(group[0]['origin'][1]-rect.y0,first+index*14,.02),'Vertical baseline changed')
        sizes=[(c['bbox'][3]-c['bbox'][1])/(c['ascender']-c['descender']) for c in group]
        size=sum(sizes)/len(sizes)
        require(max(sizes)-min(sizes)<.03,'Inconsistent glyph height in row')
        is_name=not (rows[index]=='E' or (role not in ('corps','division') and index==len(rows)-1))
        require((7 if is_name else 9)-.02<=size<=9.02,f'Incorrect vertical font size: {rows[index]}: {size}')
        char=group[0]
        require('bold' in char['font'].lower() and any(n in char['font'].lower() for n in ['arial','helvetica']),'Font changed')
        font=fonts[char['font']]; natural=font.text_length(rows[index],fontsize=9)
        if natural<W-8-.5: require(near(size,9,.02),'A fitting line was shrunk')
        require(bbox.width<=font.text_length(rows[index],fontsize=size)+.25,'Text was horizontally enlarged')
        if is_name and size<8.98: require(near(bbox.width,W-8,.25),'Overflow text reduced too far')
        if rows[index] in ['(Ricketts)','(Hatch)','iiiiiiiiiiii','MMMMMMM']:
            require(near(size,9,.02) and near(bbox.width,natural,.1),'Natural-width regression text scaled')
        require(all(rect.contains(fitz.Rect(c['bbox'])) for c in group),'Clipped or overflowing glyph')
    return len(groups)


def check_lines(page,expected_lines):
    actual=[]
    for drawing in page.get_drawings():
        if drawing.get('color') and all(near(v,138/255,.01) for v in drawing['color']):
            require(near(drawing['width'],1.5,.02),'Connector stroke changed')
            for item in drawing['items']:
                if item[0]=='l': actual.append(tuple(item[1])+tuple(item[2]))
    for target in expected_lines:
        target=tuple(v+MARGIN for v in target)
        index=next((i for i,line in enumerate(actual) if all(near(a,b) for a,b in zip(line,target)) or all(near(a,b) for a,b in zip(line,target[2:]+target[:2]))),None)
        require(index is not None,f'Missing/displaced connector {target}')
        actual.pop(index)
    require(not actual,'Extra connectors')


def verify(directory,pdf_override=None):
    directory=Path(directory)
    model=json.loads((directory/'model.json').read_text(encoding='utf-8-sig'))
    records,models=expected(model['RenderData'])
    indexed=layout_index((directory/'labels.html').read_text(encoding='utf-8'))
    (directory/'qa-layout-index.json').write_text(json.dumps(indexed,indent=2),encoding='utf-8')
    offsets=Counter();seen=Counter();side_pages=Counter();group_pages=defaultdict(set);root_pages=defaultdict(set);sides=[];total=0;row_total=0
    with fitz.open(pdf_override or directory/'labels.pdf') as document:
        require(len(document)==len(indexed),'PDF/layout page count mismatch')
        for pi,(page,index) in enumerate(zip(document,indexed)):
            require(near(page.rect.width,792) and near(page.rect.height,612),'Page scaled')
            require(index['kind']=='formation','Obsolete flat section')
            require(all(t['type']==0 and t.get('opacity',1)>.99 for t in page.get_texttrace()),'Hidden or transparent PDF text')
            chars=characters(page);header_chars=[c for c in chars if c['color']!=0xffffff and near(c['origin'][1],32,.02)]
            header=''.join(c['c'] for c in header_chars);side=header[:3]
            source=next((m for m in models if m['side']==side),None);require(source is not None,'Unknown side')
            require(header==source['header']+(' - Continued' if side_pages[side] else ''),'Incorrect page header')
            side_pages[side]+=1;sides.append(side)
            by_id={l['id']:l for l in index['labels']};require(len(by_id)==len(index['labels']),'Duplicate page label identity')
            rectangles=[item[1] for d in page.get_drawings() if d.get('fill') and max(d['fill'])<.01 for item in d['items'] if item[0]=='re']
            require(len(rectangles)==len(by_id),'Missing/extra PDF labels')
            fonts={name.split('+')[-1]:fitz.Font(fontbuffer=document.extract_font(xref)[3]) for xref,_,_,name,_,_ in page.get_fonts()}
            occupied=[]
            for identity,label in by_id.items():
                require(identity in records,'Unknown unit identity')
                truth=records[identity]
                require(truth['side']==side and all(label[k]==truth[k] for k in ('role','root','group','mounted')),'Wrong unit ownership, role or pairing')
                require(near(label['width'],W,.02) and near(label['height'],H,.02),'Index dimensions changed')
                rect=fitz.Rect(label['x']+18,label['y']+18,label['x']+18+W,label['y']+18+H)
                match=next((i for i,r in enumerate(rectangles) if all(near(a,b,.02) for a,b in zip(r,rect))),None)
                require(match is not None,'PDF label displaced or wrong dimensions');rectangles.pop(match)
                require(rect.x0>=18-.02 and rect.x1<=774+.02 and rect.y0>=18-.02 and rect.y1<=594+.02,'Label outside content')
                require(all((rect&r).get_area()<.01 for r in occupied),'Overlapping labels');occupied.append(rect)
                row_total+=check_text(rect,truth['rows'],chars,fonts,truth['role']);seen[identity]+=1;total+=1
            for char in chars:
                if char['color']==0xffffff:require(sum(r.x0-.02<=char['origin'][0]<=r.x1+.02 and r.y0<=char['origin'][1]<=r.y1 for r in occupied)==1,'Unclaimed label text')
            cursor=28;physical_rows=0;lines=[];headings=[];commands=set()
            for root in source['roots']:
                centers=[];targets=[];capacity=root['capacity'];unit_x=(2 if root['command'] else 1)*(W+6);group_x=unit_x-W-6
                for group in root['groups']:
                    primary=[by_id[i] for i in group['ids'] if i in by_id]
                    if not primary:continue
                    group_pages[group['id']].add(pi);root_pages[root['id']].add(pi)
                    if group['heading']:
                        headings.append((unit_x+18,cursor+10+18,'Unassigned units'));cursor+=14
                    first=cursor;ys=[]
                    for y in sorted(set(l['y'] for l in primary)):
                        row=sorted((l for l in primary if near(l['y'],y,.01)),key=lambda l:l['x'])
                        offset=offsets[group['id']];wanted=group['ids'][offset:offset+capacity]
                        require([l['id'] for l in row]==wanted,'Changed primary row order or capacity')
                        require(near(y,cursor,.02),'Changed row spacing or group heading reservation')
                        paired=False
                        for col,label in enumerate(row):
                            require(near(label['x'],unit_x+col*(W+6),.02),'Unit column changed')
                            pair_id=label['id']+':dismounted'
                            if pair_id in records:
                                paired=True;require(pair_id in by_id,'Missing or split cavalry counterpart')
                                pair=by_id[pair_id]
                                require(near(pair['x'],label['x'],.02) and near(pair['y'],y+H+6,.02),'Cavalry counterpart displaced')
                                lines.append((label['x']+W/2,y+H,label['x']+W/2,y+H+6))
                        ys.append(y+H/2);lines.append((unit_x-3,y+H/2,unit_x,y+H/2))
                        rows=2 if paired else 1;cursor+=rows*(H+6);physical_rows+=rows;offsets[group['id']]+=len(row)
                    center=(first+cursor-6)/2;centers.append(center);trunk=unit_x-3
                    if group['command']:
                        commands.add(group['command']);require(group['command'] in by_id,'Missing division context')
                        parent=by_id[group['command']]
                        require(near(parent['x'],group_x,.02) and near(parent['y']+H/2,center,.02),'Division centering changed')
                        lines.append((group_x+W,center,trunk,center))
                    targets.append((center,group_x if group['command'] else trunk))
                    if max(center,*ys)-min(center,*ys)>.00001:lines.append((trunk,min(center,*ys),trunk,max(center,*ys)))
                if centers and root['command']:
                    commands.add(root['command']);require(root['command'] in by_id,'Missing Corps context')
                    center=(centers[0]+centers[-1])/2;parent=by_id[root['command']]
                    require(near(parent['x'],0,.02) and near(parent['y']+H/2,center,.02),'Corps context not centered')
                    lines.append((W,center,W+3,center))
                    if max(centers)-min(centers)>.00001:lines.append((W+3,min(centers),W+3,max(centers)))
                    lines.extend((W+3,y,x,y) for y,x in targets)
            require(physical_rows<=7 and cursor-6<=576+.02,'Physical page capacity exceeded')
            require({i for i,l in by_id.items() if l['role'] in ('corps','division')}==commands,'Extra/orphan command context')
            black=[c for c in chars if c['color']!=0xffffff and c not in header_chars]
            for x,y,text in headings:
                owned=[c for c in black if near(c['origin'][1],y,.02)]
                require(''.join(c['c'] for c in owned)==text and near(owned[0]['origin'][0],x,.02),'Missing/misplaced group heading')
                require(all('bold' in c['font'].lower() and 'italic' not in c['font'].lower() and near((c['bbox'][3]-c['bbox'][1])/(c['ascender']-c['descender']),10,.02) for c in owned),'Heading font changed')
                black=[c for c in black if c not in owned]
            require(not black,'Unclaimed page text');check_lines(page,lines)
    require(set(seen)==set(records),'Missing expected command/unit labels')
    for identity,truth in records.items():
        if truth['role'] not in ('corps','division'):require(seen[identity]==1,'Duplicated unit/counterpart')
    for model in models:
        for root in model['roots']:
            whole=0
            for group in root['groups']:
                require(offsets[group['id']]==len(group['ids']),'Missing primary units')
                rows=sum(2 if any(i+':dismounted' in records for i in group['ids'][start:start+root['capacity']]) else 1 for start in range(0,len(group['ids']),root['capacity']))
                height=rows*(H+6)+(14 if group['heading'] else 0);whole+=height
                if height<=554:require(len(group_pages[group['id']])==1,'Intact group split unnecessarily')
            if whole<=554:require(len(root_pages[root['id']])==1,'Intact Corps split unnecessarily')
    require(sides==sorted(sides,key=['USA','CSA'].index),'Changed side order')
    if directory.name in ('historical','exceptional','text-fitting'):require(total==52 and len(indexed)==2,'Historical fixture must retain52labels on2pages')
    return dict(pages=len(indexed),labels=total,textRows=row_total,completeModelReconciliation=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('directory',type=Path)
    print(json.dumps(verify(parser.parse_args().directory)))
