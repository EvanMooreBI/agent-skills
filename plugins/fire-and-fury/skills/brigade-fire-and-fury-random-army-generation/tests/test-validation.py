"""Prove independent Brigade physical geometry and complete-text checks reject corruption."""
import argparse
import copy
import importlib.util
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path
sys.dont_write_bytecode=True
import pymupdf as fitz
from find_browser import find_browser
from verify_fixture_pdf import verify

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('bff_pdf',ROOT/'scripts/validate_pdf.py')
validator=importlib.util.module_from_spec(spec);spec.loader.exec_module(validator)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('fixture',type=Path);parser.add_argument('output',type=Path)
    args=parser.parse_args();args.output.mkdir(parents=True,exist_ok=False)
    pdf=args.fixture/'labels.pdf';manifest=json.loads((args.fixture/'render-manifest.json').read_text())
    results=[]
    def validate(path,data):
        with validator.validate_source(path,data) as document:
            return validator.validate_pages(document,data,args.output/'previews')
    validate(pdf,manifest);verify(args.fixture)
    def rejected(name,call,reason=None):
        try:call()
        except ValueError as error:
            if reason and reason not in str(error):raise AssertionError(f'Wrong rejection path for {name}: {error}')
            results.append(dict(test=name,rejected=True,reason=str(error)))
            print(f'TEST|{name}|PASS|{error}')
        else:raise AssertionError(f'Corruption accepted: {name}')
    def transformed(name,sx=1,sy=1):
        target=args.output/f'{name}.pdf'
        with fitz.open(pdf) as source,fitz.open() as output:
            for index in range(len(source)):
                page=output.new_page(width=792,height=612)
                page.show_pdf_page(fitz.Rect(0,0,792*sx,612*sy),source,index,keep_proportion=False)
            output.save(target)
        return target
    for width in (20,23,25):
        target=transformed(f'width-{width}',sx=width/24)
        rejected(f'physical-width-{width}',lambda target=target:validate(target,copy.deepcopy(manifest)),'physical label dimensions')
        wrong=copy.deepcopy(manifest);wrong.update(labelWidthMm=width,labelWidthPt=width*72/25.4,rendererMode=f'local-{width}mm-by-25mm')
        rejected(f'manifest-width-{width}',lambda wrong=wrong:validate(pdf,copy.deepcopy(wrong)),'Manifest geometry')
        rejected(f'matching-false-width-{width}',lambda target=target,wrong=wrong:validate(target,copy.deepcopy(wrong)),'Manifest geometry')
    target=transformed('wrong-height',sy=26/25)
    rejected('physical-height',lambda:validate(target,copy.deepcopy(manifest)),'physical label dimensions')
    wrong=copy.deepcopy(manifest);wrong.update(labelHeightMm=26,labelHeightPt=26*72/25.4)
    rejected('manifest-height',lambda:validate(pdf,wrong),'Manifest geometry')
    scaled=args.output/'page-scale.pdf'
    with fitz.open(pdf) as document:
        document[0].set_mediabox(fitz.Rect(0,0,712.8,550.8));document.save(scaled)
    rejected('page-auto-fit',lambda:validate(scaled,copy.deepcopy(manifest)),'not landscape US Letter')
    def changed_text(name,transform):
        target=args.output/f'{name}.pdf'
        with fitz.open(pdf) as document:
            page=document[0];stream=b'\n'.join(document.xref_stream(x) for x in page.get_contents())
            changed=transform(stream)
            assert stream!=changed,'Mutation did not change content'
            xref=document.get_new_xref();document.update_object(xref,'<<>>');document.update_stream(xref,changed);page.set_contents(xref)
            document.save(target,garbage=4,deflate=True)
        rejected(name,lambda:verify(args.fixture,target))
    def drop_row(stream):
        match=list(re.finditer(rb'BT\s.*?ET',stream,re.S))[1]
        return stream[:match.start()]+stream[match.end():]
    changed_text('missing-complete-row',drop_row)
    changed_text('vertical-font-shrink',lambda s:s.replace(b'1 0 0 -1 ',b'1 0 0 -.8 '))
    changed_text('horizontal-font-stretch',lambda s:s.replace(b'BT\n',b'BT\n125 Tz\n'))
    changed_text('missing-connectors',lambda s:s.replace(b'.5412 .5412 .5412 RG',b'0 0 0 RG'))
    extra=args.output/'unclaimed-glyphs.pdf'
    with fitz.open(pdf) as document:
        document[0].insert_text((750,600),'EXTRA',fontsize=9,color=(1,1,1));document.save(extra)
    rejected('unclaimed-outside-text',lambda:verify(args.fixture,extra))
    hidden=args.output/'transparent-text.pdf'
    with fitz.open(pdf) as document:
        document[0].insert_text((18,35),'HIDDEN',fontsize=9,color=(1,1,1),fill_opacity=0)
        document.save(hidden)
    rejected('transparent-text',lambda:verify(args.fixture,hidden),'Hidden or transparent')
    # The mixed fixture exercises both pairs and Corps-owned unassigned headings.
    layout=json.loads((args.fixture/'qa-layout-index.json').read_text())
    pair=next(l for l in layout[0]['labels'] if l.get('mounted'))
    browser=find_browser()
    def render_bad(name,change):
        folder=args.output/name;folder.mkdir()
        shutil.copyfile(args.fixture/'model.json',folder/'model.json')
        original=(args.fixture/'labels.html').read_text();altered=change(original)
        assert altered!=original,'Mutation did not change HTML'
        (folder/'labels.html').write_text(altered)
        target=folder/'labels.pdf'
        subprocess.run([str(browser),'--headless=new','--disable-gpu','--no-pdf-header-footer',f'--user-data-dir={folder.resolve()/"profile"}',f'--print-to-pdf={target.resolve()}',(folder/'labels.html').resolve().as_uri()],check=True,capture_output=True,timeout=30,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
        rejected(name,lambda:verify(folder,target))
    def move_pair(html):
        pattern=rf'(<g class="label"[^>]*data-id="{re.escape(pair["id"])}"[^>]*>)(.*?)(</g>)'
        def move(match):
            body=re.sub(r'( y(?:1|2)?=")([^"]+)',lambda m:m[1]+str(float(m[2])-1),match[2])
            return match[1]+body+match[3]
        return re.sub(pattern,move,html,count=1,flags=re.S)
    render_bad('displaced-pair-with-correct-index',move_pair)
    render_bad('wrong-pair-owner',lambda h:h.replace(f'data-mounted-id="{pair["mounted"]}"','data-mounted-id="wrong"',1))
    render_bad('missing-group-heading',lambda h:h.replace('>Unassigned units</text>','>Incorrect group</text>',1))
    def drop_pair_link(html):
        for match in re.finditer(r'<line x1="([^"]+)" y1="([^"]+)" x2="([^"]+)" y2="([^"]+)"/>',html):
            x1,y1,x2,y2=map(float,match.groups())
            if abs(x1-x2)<.001 and abs(y2-y1-6)<.001 and x1>150:return html[:match.start()]+html[match.end():]
        raise AssertionError('No pair connector')
    render_bad('missing-pair-connector',drop_pair_link)
    render_bad('wrong-group-owner',lambda h:h.replace(f'data-root-key="{pair["root"]}"','data-root-key="wrong"',1))
    missing=args.output/'missing-dismount.pdf'
    with fitz.open(pdf) as document:
        box=fitz.Rect(pair['x']+18,pair['y']+18,pair['x']+18+24*72/25.4,pair['y']+18+25*72/25.4)
        document[0].add_redact_annot(box,fill=(1,1,1));document[0].apply_redactions();document.save(missing)
    rejected('missing-dismount',lambda:verify(args.fixture,missing))
    duplicate=args.output/'duplicate-dismount.pdf'
    with fitz.open(pdf) as source,fitz.open(pdf) as document:
        document[0].show_pdf_page(fitz.Rect(650,520,650+box.width,520+box.height),source,0,clip=box);document.save(duplicate)
    rejected('duplicate-dismount',lambda:verify(args.fixture,duplicate))
    (args.output/'results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
    print(f'TEST-SUMMARY|PASS|{len(results)} Brigade corruption cases rejected')


if __name__=='__main__':main()
