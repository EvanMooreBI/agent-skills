"""Validate the final Regimental PDF against independently resolved army records."""
import argparse
from collections import Counter
from contextlib import ExitStack
import hashlib
import json
import math
from pathlib import Path
import re
import sys

import pymupdf as fitz

sys.dont_write_bytecode = True
from rff_expected import label_expectations

W, H = 24*72/25.4, 25*72/25.4
D = .28*H
MARGIN, GEOMETRY_EPS, TEXT_EPS = 18, .25, .02
BRIGADE_X, UNIT_X = W+6, 2*W+12
PITCH = H+6


def require(condition, message):
    if not condition:
        raise ValueError(message)


def close(a, b, tolerance=GEOMETRY_EPS):
    return abs(a-b) <= tolerance


def point_close(a, b):
    return close(a[0],b[0]) and close(a[1],b[1])


def match_lines(actual, expected, name):
    pending=list(actual)
    for target in expected:
        index=next((i for i,line in enumerate(pending) if (point_close(line[:2],target[:2]) and point_close(line[2:],target[2:])) or (point_close(line[:2],target[2:]) and point_close(line[2:],target[:2]))),None)
        require(index is not None,f'Missing or displaced {name}: {target}')
        pending.pop(index)
    require(not pending,f'Unexpected {name} lines')


def drawing_lines(drawings, color):
    return [(item[1].x,item[1].y,item[2].x,item[2].y) for draw in drawings
            if draw.get('color') and all(close(c,v,.01) for c,v in zip(draw['color'],color))
            for item in draw['items'] if item[0]=='l']


def page_layout(labels, expected, division, offsets, group_pages, page_index):
    root_id=f"{division['Side']}-DIV1"
    groups=sorted((b for b in division['Brigades'] if b['Units']),key=lambda b:(bool(b['IsIndependent']),b['DisplayOrder']))
    lines=[];headings=[];centers=[];targets=[];cursor=28;physical_rows=0
    by_id={l['id']:l for l in labels}
    parent_ids={root_id}
    for group in groups:
        primary_ids=[identity for identity,truth in expected.items() if truth.get('group')==group['Id'] and truth['role']!='dismounted']
        primary=[by_id[i] for i in primary_ids if i in by_id]
        if not primary:continue
        group_pages.setdefault(group['Id'],set()).add(page_index)
        independent=group['IsIndependent']
        if independent:
            headings.append(dict(text='Unassigned units',x=UNIT_X,y=cursor+10,rootKey=root_id,groupKey=group['Id']))
            cursor+=14
        first=cursor;ys=[]
        for row_y in sorted(set(l['y'] for l in primary)):
            row=sorted((l for l in primary if close(l['y'],row_y,.01)),key=lambda l:l['x'])
            start=offsets[group['Id']];wanted=primary_ids[start:start+8]
            require([l['id'] for l in row]==wanted,'Primary row order, ownership or capacity changed')
            require(close(row_y,cursor,.02),'Incorrect row pitch, heading reservation or group position')
            for col,label in enumerate(row):
                require(close(label['x'],UNIT_X+col*(W+6),.02),'Incorrect unit column')
                pair_id=label['id']+':dismounted'
                if pair_id in expected:
                    require(pair_id in by_id,'Missing paired dismounted label')
                    pair=by_id[pair_id]
                    require(close(pair['x'],label['x'],.02) and close(pair['y'],row_y+PITCH,.02),'Dismounted pair displaced or split')
                    lines.append((label['x']+W/2,row_y+H,label['x']+W/2,row_y+PITCH))
            paired=any(i+':dismounted' in expected for i in wanted)
            physical_rows+=2 if paired else 1
            offsets[group['Id']]+=len(row);ys.append(row_y+H/2)
            lines.append((UNIT_X-3,row_y+H/2,UNIT_X,row_y+H/2))
            cursor+=(2 if paired else 1)*PITCH
        center=(first+cursor-6)/2;centers.append(center)
        trunk=UNIT_X-3
        if not independent:
            parent_ids.add(group['Id']);require(group['Id'] in by_id,'Missing command context')
            command=by_id[group['Id']]
            require(close(command['x'],BRIGADE_X,.02) and close(command['y']+H/2,center,.02),'Intermediate command not centered over allocated block')
            lines.append((BRIGADE_X+W,center,trunk,center))
        if max(center,*ys)-min(center,*ys)>.00001:lines.append((trunk,min(center,*ys),trunk,max(center,*ys)))
        targets.append((center,trunk if independent else BRIGADE_X))
    require(physical_rows<=7 and cursor-6<=576+.02,'Physical page capacity exceeded')
    require({l['id'] for l in labels if l['role'] in ('division','brigade')}==parent_ids,'Missing, extra or orphan command context')
    root=by_id[root_id];center=(centers[0]+centers[-1])/2 if centers else 28+H/2
    require(close(root['x'],0,.02) and close(root['y']+H/2,center,.02),'Division command not centered between immediate groups')
    if targets:
        lines.append((W,center,W+3,center))
        if max(centers)-min(centers)>.00001:lines.append((W+3,min(centers),W+3,max(centers)))
        lines.extend((W+3,y,x,y) for y,x in targets)
    return [(x1+18,y1+18,x2+18,y2+18) for x1,y1,x2,y2 in lines],headings


def text_ink_document(page):
    """Rasterize original text without a nearby marker contaminating its ink."""
    document=fitz.open()
    document.insert_pdf(page.parent,from_page=page.number,to_page=page.number)
    text_page=document[0]
    for xref in text_page.get_contents():
        stream=document.xref_stream(xref)
        # Chromium emits path-paint operators on separate lines. End those
        # paths without painting; retain text operators and clipping exactly.
        stream=re.sub(rb'(?m)^[ \t]*(?:S|s|f\*?|F|B\*?|b\*?)[ \t]*\r?$',b'n',stream)
        document.update_stream(xref,stream)
    require(not text_page.get_drawings(),'Unsupported path painting in text-ink measurement')
    require(text_page.get_text('rawdict')==page.get_text('rawdict'),'Text-ink isolation changed PDF text')
    text_page.draw_rect(text_page.rect,color=None,fill=(0,0,0),overlay=False)
    return document


def ink_bounds(page,rect,group):
    box=fitz.Rect(group[0]['bbox'])
    for char in group[1:]:box |= fitz.Rect(char['bbox'])
    clip=fitz.Rect(rect.x0+4,box.y0,rect.x1-4,box.y1)
    scale=24
    pix=page.get_pixmap(matrix=fitz.Matrix(scale,scale),clip=clip,colorspace=fitz.csGRAY,alpha=False)
    pixels=pix.samples
    rows=[y for y in range(pix.height) if max(pixels[y*pix.stride:y*pix.stride+pix.width])>128]
    require(rows,'No visible ink for a text row')
    return (pix.y+min(rows))/scale-rect.y0,(pix.y+max(rows)+1)/scale-rect.y0


def characters(page):
    result=[]
    for block in page.get_text('rawdict')['blocks']:
        for line in block.get('lines',[]):
            for span in line['spans']:
                for char in span['chars']:
                    result.append(dict(char, font=span['font'],ascender=span['ascender'],descender=span['descender'],color=span['color']))
    return result


def check_text(label, expected, rect, chars, fonts, page):
    inside=[c for c in chars if rect.x0-TEXT_EPS <= c['origin'][0] <= rect.x1+TEXT_EPS and rect.y0 <= c['origin'][1] <= rect.y1]
    require(all(c['color']==0xffffff for c in inside),'Label text is not white')
    groups=[]
    for char in inside:
        group=next((g for g in groups if close(g[0]['origin'][1],char['origin'][1],TEXT_EPS)),None)
        if group is None:groups.append([char])
        else:group.append(char)
    groups.sort(key=lambda g:g[0]['origin'][1])
    nonempty=[(i,text) for i,text in enumerate(expected['rows']) if text]
    require(len(groups)==len(nonempty),f"Missing or extra text rows on {label['id']}")
    metrics=[];boxes=[];vertical_sizes=[]
    for group,(row_index,text) in zip(groups,nonempty):
        group.sort(key=lambda c:c['origin'][0])
        actual=''.join(c['c'] for c in group)
        require(actual==text,f"Label text mismatch on {label['id']}: {actual!r} != {text!r}")
        bbox=fitz.Rect(group[0]['bbox'])
        for char in group[1:]:bbox |= fitz.Rect(char['bbox'])
        require(bbox.x0>=rect.x0+4-TEXT_EPS and bbox.x1<=rect.x1-4+TEXT_EPS,f"Text exceeds side insets on {label['id']}")
        require(close((bbox.x0+bbox.x1)/2,(rect.x0+rect.x1)/2),f"Uncentered text on {label['id']}")
        char=group[0]; height=char['ascender']-char['descender']
        require('bold' in char['font'].lower() and any(name in char['font'].lower() for name in ('arial','helvetica')),'Unexpected label font')
        require(height>0,'Invalid embedded font metrics')
        sizes=[(c['bbox'][3]-c['bbox'][1])/(c['ascender']-c['descender']) for c in group]
        size=sum(sizes)/len(sizes)
        require(max(sizes)-min(sizes)<.03,'Inconsistent vertical glyph scaling within a row')
        kind=expected['kinds'][row_index]
        require(size<=9.02 and size>=(7 if kind=='name' else 9)-.02,f"Unexpected vertical font size on {label['id']}: {size}")
        font=fonts[char['font']]
        natural=font.text_length(text,fontsize=9)
        available=W-8
        # Embedded subset advances omit browser kerning. A short row must keep
        # its natural size; a reduced row must fill its available width, so a
        # character-count heuristic or excessive reduction cannot pass.
        if natural<=available-.5:
            require(close(size,9,.02),f"Text that fits was scaled: {text}")
        if kind=='name' and size<8.98:
            require(close(bbox.width,available,.25),f"Overflow text was reduced too far on {label['id']}")
        if text in ('iiiiiiiiiiii','(Ricketts)','(Hatch)','MMMMMMMM'):
            require(close(size,9,.02) and close(bbox.width,natural,.1),'Natural-width regression text was scaled')
        require(bbox.width<=font.text_length(text,fontsize=size)+.25,'Text was horizontally enlarged')
        require(all(rect.contains(fitz.Rect(c['bbox'])) for c in group),'A glyph escapes its label')
        metrics.append((char['ascender']*9,-char['descender']*9))
        boxes.append(bbox);vertical_sizes.append(size)
    if not groups:return 0
    ascent=max(x[0] for x in metrics);descent=max(x[1] for x in metrics);line_height=ascent+descent
    top=D+(8 if len(expected['rows'])==3 else 5);bottom=H-5;n=len(expected['rows'])
    gap=min(14,math.floor(4*(bottom-top-line_height)/(n-1))/4)
    require(gap>=line_height+.1-TEXT_EPS,'Font cannot preserve the minimum row clearance')
    first=top+(bottom-top-line_height-(n-1)*gap)/2+ascent
    originals=[first+i*gap for i in range(n)]
    baselines={i:group[0]['origin'][1]-rect.y0 for group,(i,_) in zip(groups,nonempty)}
    if n==3:
        inks={i:ink_bounds(page,rect,group) for group,(i,_) in zip(groups,nonempty)}
        asc=[baselines[i]-inks[i][0] if i in inks else ascent for i in range(n)]
        desc=[inks[i][1]-baselines[i] if i in inks else descent for i in range(n)]
        old_gaps=[originals[i+1]-asc[i+1]-originals[i]-desc[i] for i in range(2)]
        target=max(top,D+1.5+5.427+3)
        visible=min(*old_gaps,(originals[2]+desc[2]-target-sum(a+d for a,d in zip(asc,desc)))/2)
        wanted=[0,0,originals[2]]
        for i in (1,0):wanted[i]=wanted[i+1]-asc[i+1]-visible-desc[i]
        for i,base in baselines.items():require(close(base,wanted[i],.2),f"Incorrect equal-ink-gap positioning on {label['id']}: row={i} actual={base:.3f} expected={wanted[i]:.3f} ink={inks}")
        if 0 in inks:require(inks[0][0]>=D+3.5+5.427+1-.1,'Insufficient star-to-text clearance')
        if len(inks)==3:
            gaps=[inks[i+1][0]-inks[i][1] for i in (0,1)]
            require(close(gaps[0],gaps[1],.2),'Unequal visible text gaps')
    else:
        for i,base in baselines.items():require(close(base,originals[i],TEXT_EPS),'Four-row baseline changed')
    for bbox in boxes:require(bbox.y0>=rect.y0+top-TEXT_EPS and bbox.y1<=rect.y0+bottom+TEXT_EPS,'Text exceeds its lower band')
    require(all(a.y1<=b.y0-.1+TEXT_EPS for a,b in zip(boxes,boxes[1:])),'Text rows overlap')
    return len(groups)


def validate(pdf, manifest, model, previews=None):
    expected=label_expectations(model)
    pages=manifest['pages'];seen=Counter();unit_order=[];stars=0;text_rows=0;offsets=Counter();group_pages={}
    require(manifest.get('labelWidthMm')==24 and manifest.get('labelHeightMm')==25,'Wrong manifest geometry')
    expected_sides=[d['Side'] for d in model['Divisions']]
    page_sides=[p['side'] for p in pages]
    require(list(dict.fromkeys(page_sides))==expected_sides,'Wrong side order')
    require(page_sides==sorted(page_sides,key=expected_sides.index),'Interleaved sides')
    with fitz.open(pdf) as document, ExitStack() as ink_documents:
        require(len(document)==len(pages) and len(document)>0,'PDF page count mismatch')
        for page_index,(page,contract) in enumerate(zip(document,pages)):
            require(close(page.rect.width,792) and close(page.rect.height,612),'PDF is not landscape US Letter')
            drawings=page.get_drawings();rectangles=[]
            for trace in page.get_texttrace():
                require(trace['type']==0 and trace.get('opacity',1)>.99,'Hidden or transparent PDF text')
            for drawing in drawings:
                if drawing.get('fill') and max(drawing['fill'])<.01:
                    for item in drawing['items']:
                        if item[0]=='re':
                            rect=item[1]
                            require(close(rect.width,W) and close(rect.height,H),'Incorrect physical label dimensions')
                            require(drawing.get('color') and min(drawing['color'])>.99 and close(drawing['width'],1,.02),'Incorrect label border')
                            rectangles.append(rect)
            labels=contract['labels'];require(len(rectangles)==len(labels),'Missing or extra label rectangles')
            require(labels,'Empty PDF page')
            ink_page=ink_documents.enter_context(text_ink_document(page))[0]
            require(len({x['id'] for x in labels})==len(labels),'Duplicate label on page')
            fonts={name.split('+')[-1]:fitz.Font(fontbuffer=document.extract_font(xref)[3]) for xref,_,_,name,_,_ in page.get_fonts()}
            chars=characters(page)
            header=f"{contract['side']} - {model['Theatre']} - {model['Period']}"
            require(contract['kind']=='main','Obsolete separate PDF section')
            earlier=[p for p in pages[:page_index] if p['side']==contract['side'] and p['kind']==contract['kind']]
            if earlier:header+=' - Continued'
            require(contract['header']==header and header in page.get_text(),'Wrong or missing page header')
            header_chars=[c for c in chars if c['color']!=0xffffff and close(c['origin'][1],32,.02)]
            require(''.join(c['c'] for c in header_chars)==header,'Unexpected text outside labels')
            require(all(close(c['origin'][1],32) for c in header_chars),'Incorrect header position')
            dividers=[];star_boxes=[];local=[]
            for label in labels:
                identity=label['id'];require(identity in expected,f'Unknown label {identity}')
                truth=expected[identity]
                require(truth['side']==contract['side'] and truth['role']==label['role'],'Label side or role mismatch')
                require([r['text'] for r in label['rows']]==truth['rows'] and [r['kind'] for r in label['rows']]==truth['kinds'],'Renderer changed label content')
                require(label['brave']==truth['brave'],'Incorrect Brave Colonel flag')
                require(label.get('groupKey')==truth.get('group',identity if truth['role']=='brigade' else None),'Wrong group ownership metadata')
                require(label.get('mountedId')==(identity[:-len(':dismounted')] if truth['role']=='dismounted' else None),'Incorrect mounted/dismounted ownership metadata')
                seen[identity]+=1
                target=fitz.Rect(label['x']+18,label['y']+18,label['x']+18+W,label['y']+18+H)
                index=next((i for i,r in enumerate(rectangles) if all(close(a,b) for a,b in zip(r,target))),None)
                require(index is not None,'Displaced or scaled label rectangle')
                actual=rectangles.pop(index)
                require(actual.x0>=18-GEOMETRY_EPS and actual.y0>=18-GEOMETRY_EPS and actual.x1<=774+GEOMETRY_EPS and actual.y1<=594+GEOMETRY_EPS,'Label exceeds printable content')
                for other in local:require((actual & other).get_area()<.01,'Label rectangles overlap')
                local.append(actual)
                label['expectedParent']=truth['parent']
                text_rows+=check_text(label,truth,actual,chars,fonts,ink_page)
                dividers.append((actual.x0,actual.y0+D,actual.x1,actual.y0+D))
                if truth['brave']:
                    star_boxes.append(fitz.Rect(actual.x0+W-10+.147,actual.y0+D+3.5,actual.x0+W-10+5.853,actual.y0+D+3.5+5.427))
                    stars+=1
                if truth['role'] not in ('division','brigade'):
                    unit_order.append(identity)
            for char in chars:
                if char['color']==0xffffff:
                    require(sum(r.x0-TEXT_EPS<=char['origin'][0]<=r.x1+TEXT_EPS and r.y0<=char['origin'][1]<=r.y1 for r in local)==1,'Unclaimed or hidden label text outside its rectangle')
            # Chromium expands dashed strokes to filled paths in the PDF.
            white_paths=[d for d in drawings if d.get('fill') and min(d['fill'])>.99]
            # The last 4/3 dash may end before the label edge when W ends in a gap.
            visible_width=min(W,(math.ceil(W/7)-1)*7+4)
            dashed=[d for d in white_paths if close(d['rect'].width,visible_width,.04) and close(d['rect'].height,1,.04)]
            actual_dividers=drawing_lines(drawings,(1,1,1))
            for draw in dashed:
                segments=[i for i in draw['items'] if i[0]=='l' and close(i[1].y,i[2].y,.02)]
                r=draw['rect']
                intervals=sorted((min(i[1].x,i[2].x)-r.x0,max(i[1].x,i[2].x)-r.x0) for i in segments)
                expected_intervals=sorted((start,min(start+4,W)) for start in range(0,math.ceil(W),7) for _ in range(2))
                require(len(intervals)==len(expected_intervals) and all(close(a,c,.02) and close(b,d,.02) for (a,b),(c,d) in zip(intervals,expected_intervals)),'Divider is not the required 4/3 dashed line')
                actual_dividers.append((r.x0,(r.y0+r.y1)/2,r.x0+W,(r.y0+r.y1)/2))
            match_lines(actual_dividers,dividers,'divider')
            actual_stars=[d['rect'] for d in white_paths if d not in dashed and any(i[0]=='l' for i in d['items'])]
            require(len(actual_stars)==len(star_boxes),'Incorrect number of white stars')
            for box in star_boxes:
                require(any(all(close(a,b,.04) for a,b in zip(box,actual)) for actual in actual_stars),'Missing or displaced Brave Colonel star')
            division=next(d for d in model['Divisions'] if d['Side']==contract['side'])
            connectors,headings=page_layout(labels,expected,division,offsets,group_pages,page_index)
            require(contract.get('headings',[])==headings,'Missing or incorrect group subheader metadata')
            black=[c for c in chars if c['color']!=0xffffff and c not in header_chars]
            for heading in headings:
                owned=[c for c in black if close(c['origin'][1],heading['y']+18,.02)]
                require(''.join(c['c'] for c in owned)==heading['text'],'Missing or incorrect group subheader')
                require(owned and close(owned[0]['origin'][0],heading['x']+18,.02),'Subheader position changed')
                require(all('bold' in c['font'].lower() and 'italic' not in c['font'].lower() and close((c['bbox'][3]-c['bbox'][1])/(c['ascender']-c['descender']),10,.02) for c in owned),'Subheader style changed')
                black=[c for c in black if c not in owned]
            require(not black,'Unclaimed PDF text outside labels and headings')
            match_lines(drawing_lines(drawings,(138/255,)*3),connectors,'connector')
            for draw in drawings:
                if draw.get('color') and all(close(c,138/255,.01) for c in draw['color']):
                    require(close(draw['width'],1.5,.02),'Incorrect connector stroke width')
            require(len(contract['connectors'])==len(connectors),'Connector manifest differs from hierarchy')
            if previews:
                directory=Path(previews);directory.mkdir(parents=True,exist_ok=True)
                page.get_pixmap(matrix=fitz.Matrix(1.5,1.5),alpha=False).save(directory/f'page-{page_index+1:03d}.png')
                # Full-size and close-up evidence of every page, including all labels.
                page.get_pixmap(matrix=fitz.Matrix(1,1),alpha=False).save(directory/f'actual-size-{page_index+1:03d}.png')
                page.get_pixmap(matrix=fitz.Matrix(3,3),alpha=False).save(directory/f'closeup-{page_index+1:03d}.png')
        require(set(seen)==set(expected),'Missing expected formation, unit, gun, or dismounted labels')
        for identity,truth in expected.items():
            if truth['role'] not in ('division','brigade'):require(seen[identity]==1,f'Duplicate unit or gun copy: {identity}')
        for division in model['Divisions']:
            for group in division['Brigades']:
                ids=[identity for identity,truth in expected.items() if truth.get('group')==group['Id'] and truth['role']!='dismounted']
                require(offsets[group['Id']]==len(ids),'Missing primary unit rows')
                row_count=sum(2 if any(i+':dismounted' in expected for i in ids[start:start+8]) else 1 for start in range(0,len(ids),8))
                whole=row_count*PITCH+(14 if group['IsIndependent'] else 0)
                if whole<=554:require(len(group_pages.get(group['Id'],set()))<=1,'Group that fits fresh was split')
        return dict(pages=len(document),labels=sum(seen.values()),uniqueLabels=len(seen),stars=stars,textRows=text_rows,widthMm=24,heightMm=25,sha256=hashlib.sha256(Path(pdf).read_bytes()).hexdigest())


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    for name in ('pdf','manifest','model','previews'):parser.add_argument(name,type=Path)
    args=parser.parse_args()
    try:
        proof=validate(args.pdf,json.loads(args.manifest.read_text(encoding='utf-8-sig')),json.loads(args.model.read_text(encoding='utf-8-sig')),args.previews)
        print(json.dumps(proof));return 0
    except (ValueError,KeyError,TypeError,IndexError,OSError,RuntimeError) as error:
        print(f'PDF validation failed: {error}',file=sys.stderr);return 1


if __name__=='__main__':raise SystemExit(main())
