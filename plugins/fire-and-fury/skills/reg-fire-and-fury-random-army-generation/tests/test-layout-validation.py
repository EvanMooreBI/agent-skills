"""Mutate real pair/group exports while retaining correct physical label sizes."""
import argparse
import copy
import json
from pathlib import Path
import re
import subprocess
import sys

sys.dont_write_bytecode = True
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
import pymupdf as fitz
from find_browser import find_browser
from validate_pdf import validate


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('fixtures',type=Path);parser.add_argument('output',type=Path)
    args=parser.parse_args();args.output.mkdir(parents=True,exist_ok=False)
    browser=find_browser()
    results=[]
    def reject(name,pdf,manifest,model):
        try:validate(pdf,copy.deepcopy(manifest),model)
        except (ValueError,KeyError,IndexError,TypeError) as error:
            results.append(dict(test=name,rejected=True,reason=str(error)));print(f'TEST|{name}|PASS|{error}')
        else:raise AssertionError(f'Accepted {name}')
    def render(name,source,transform,manifest,model,manifest_change=None):
        html=source.read_text(encoding='utf-8');changed=transform(html)
        assert changed!=html,'Mutation did not change HTML'
        target=args.output/name;target.mkdir()
        (target/'labels.html').write_text(changed,encoding='utf-8')
        pdf=target/'labels.pdf'
        subprocess.run([str(browser),'--headless=new','--disable-gpu','--no-pdf-header-footer',f'--user-data-dir={target.resolve()/"profile"}',f'--print-to-pdf={pdf.resolve()}',(target/'labels.html').resolve().as_uri()],check=True,capture_output=True,timeout=30,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
        altered=copy.deepcopy(manifest)
        if manifest_change:manifest_change(altered)
        reject(name,pdf,altered,model)
    text=args.fixtures/'text-fitting';group=args.fixtures/'mixed-overrides'
    model=json.loads((text/'resolved-model.json').read_text());manifest=json.loads((text/'render-manifest.json').read_text())
    pair=next(l for l in manifest['pages'][0]['labels'] if l['role']=='dismounted')
    def move_pair(html):
        pattern=rf'(<g class="label" data-id="{re.escape(pair["id"])}" transform="translate\([^ ]+ )([^)]+)'
        return re.sub(pattern,lambda m:m[1]+str(float(m[2])-1),html,count=1)
    def move_manifest(m):next(l for l in m['pages'][0]['labels'] if l['id']==pair['id'])['y']-=1
    render('displaced-pair-with-matching-manifest',text/'labels.html',move_pair,manifest,model,move_manifest)
    altered=copy.deepcopy(manifest);next(l for l in altered['pages'][0]['labels'] if l['id']==pair['id'])['mountedId']='wrong'
    reject('wrong-pair-owner',text/'labels.pdf',altered,model)
    def drop_pair_link(html):
        for match in re.finditer(r'<line x1="([^"]+)" y1="([^"]+)" x2="([^"]+)" y2="([^"]+)"/>',html):
            x1,y1,x2,y2=map(float,match.groups())
            if abs(x1-x2)<.001 and abs(y2-y1-6)<.001 and x1>150:return html[:match.start()]+html[match.end():]
        raise AssertionError('No pair link')
    render('missing-pair-link',text/'labels.html',drop_pair_link,manifest,model)
    render('unequal-visible-gaps',text/'labels.html',lambda h:h.replace('text.setAttribute("y",baselines[i])','text.setAttribute("y",baselines[i]+(i===0?2:0))'),manifest,model)
    for name,dy in [('star-over-divider',-4),('star-at-previous-position',-2),('star-too-close-to-text',4)]:
        def star_move(html,dy=dy):return re.sub(r'(<polygon transform="translate\([^ ]+ )([^)]+)',lambda m:m[1]+str(float(m[2])+dy),html)
        render(name,text/'labels.html',star_move,manifest,model)
    pdf=args.output/'missing-pair.pdf'
    with fitz.open(text/'labels.pdf') as document:
        box=fitz.Rect(pair['x']+18,pair['y']+18,pair['x']+18+24*72/25.4,pair['y']+18+25*72/25.4)
        document[0].add_redact_annot(box,fill=(1,1,1));document[0].apply_redactions();document.save(pdf)
    reject('missing-pair',pdf,manifest,model)
    duplicate=args.output/'duplicate-pair.pdf'
    with fitz.open(text/'labels.pdf') as source,fitz.open(text/'labels.pdf') as document:
        document[0].show_pdf_page(fitz.Rect(650,520,650+box.width,520+box.height),source,0,clip=box);document.save(duplicate)
    reject('duplicated-pair',duplicate,manifest,model)
    model=json.loads((group/'resolved-model.json').read_text());manifest=json.loads((group/'render-manifest.json').read_text())
    render('missing-unassigned-heading',group/'labels.html',lambda h:h.replace('>Unassigned units</text>','>Incorrect group</text>'),manifest,model)
    altered=copy.deepcopy(manifest)
    next(l for l in altered['pages'][0]['labels'] if l.get('groupKey')=='USA-IU1')['groupKey']='USA-DA1'
    reject('wrong-unassigned-owner',group/'labels.pdf',altered,model)
    (args.output/'results.json').write_text(json.dumps(results,indent=2))
    print(f'TEST-SUMMARY|PASS|{len(results)} pair/group corruption cases rejected')


if __name__=='__main__':main()
