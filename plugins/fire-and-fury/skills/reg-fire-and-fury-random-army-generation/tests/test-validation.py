"""Prove validators reject corrupted PDFs and CSVs, using real exported fixtures."""
import argparse
import copy
import csv
import json
from pathlib import Path
import re
import subprocess
import sys

sys.dont_write_bytecode=True
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
import pymupdf as fitz
from find_browser import find_browser
from validate_pdf import validate as validate_pdf
from validate_csv import validate as validate_csv, HEADERS


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('fixture',type=Path);parser.add_argument('output',type=Path)
    args=parser.parse_args();args.output.mkdir(parents=True,exist_ok=False)
    folder=args.fixture
    model=json.loads((folder/'resolved-model.json').read_text(encoding='utf-8-sig'))
    manifest=json.loads((folder/'render-manifest.json').read_text(encoding='utf-8-sig'))
    request=json.loads((folder/'request.json').read_text(encoding='utf-8-sig'))
    pdf=folder/'labels.pdf';csv_path=folder/'generation-log.csv'
    validate_pdf(pdf,copy.deepcopy(manifest),model);validate_csv(csv_path,model,request,pdf)
    results=[]

    def rejected(name,call):
        try:call()
        except (ValueError,KeyError,IndexError,TypeError,RuntimeError) as error:
            results.append(dict(test=name,rejected=True,reason=str(error)))
            print(f'TEST|{name}|PASS|{error}')
        else:raise AssertionError(f'Validator accepted corruption: {name}')

    def changed_pdf(name,change):
        target=args.output/f'{name}.pdf'
        with fitz.open(pdf) as document:
            change(document)
            document.save(target,garbage=4,deflate=True)
        rejected(name,lambda:validate_pdf(target,copy.deepcopy(manifest),model))

    def transform_stream(document,transform):
        page=document[0]
        stream=b'\n'.join(document.xref_stream(x) for x in page.get_contents())
        changed=transform(stream)
        assert changed!=stream,'Mutation did not alter PDF content'
        xref=document.get_new_xref();document.update_object(xref,'<<>>');document.update_stream(xref,changed);page.set_contents(xref)

    changed_pdf('wrong-label-dimensions',lambda doc:transform_stream(doc,lambda s:b'q\n1.02 0 0 1 0 0 cm\n'+s+b'\nQ'))
    changed_pdf('whole-page-auto-fit-scaling',lambda doc:transform_stream(doc,lambda s:b'q\n.9 0 0 .9 0 0 cm\n'+s+b'\nQ'))
    for width in (20,23,25):
        name=f'physical-width-{width}'
        changed_pdf(name,lambda doc,scale=width/24:transform_stream(doc,lambda s:f'q\n{scale:.12f} 0 0 1 0 0 cm\n'.encode()+s+b'\nQ'))
        wrong=copy.deepcopy(manifest);wrong['labelWidthMm']=width
        rejected(f'manifest-width-{width}',lambda wrong=wrong:validate_pdf(pdf,copy.deepcopy(wrong),model))
        rejected(f'matching-false-width-{width}',lambda wrong=wrong,name=name:validate_pdf(args.output/f'{name}.pdf',copy.deepcopy(wrong),model))
    changed_pdf('physical-height-26',lambda doc:transform_stream(doc,lambda s:b'q\n1 0 0 1.04 0 0 cm\n'+s+b'\nQ'))
    changed_pdf('horizontal-text-stretch',lambda doc:transform_stream(doc,lambda s:s.replace(b'BT\n',b'BT\n125 Tz\n')))
    changed_pdf('vertical-text-shrink',lambda doc:transform_stream(doc,lambda s:s.replace(b'1 0 0 -1 ',b'1 0 0 -.8 ')))
    def drop_row(stream):
        match=list(re.finditer(rb'BT\s.*?ET',stream,re.S))[1]
        return stream[:match.start()]+stream[match.end():]
    changed_pdf('dropped-label-row',lambda doc:transform_stream(doc,drop_row))
    def overlap_rows(stream):
        matches=list(re.finditer(rb'1 0 0 -1 ([\d.-]+) ([\d.-]+) Tm',stream))
        first,second=matches[1:3]
        return stream[:second.start(2)]+first.group(2)+stream[second.end(2):]
    changed_pdf('overlapping-text-rows',lambda doc:transform_stream(doc,overlap_rows))
    changed_pdf('missing-brave-star',lambda doc:transform_stream(doc,lambda s:re.sub(rb'3 0 m\s+3\.735.*?\nf\s',b'',s,count=1,flags=re.S)))
    changed_pdf('missing-connectors',lambda doc:transform_stream(doc,lambda s:s.replace(b'.5412 .5412 .5412 RG',b'0 0 0 RG')))
    changed_pdf('page-overflow',lambda doc:transform_stream(doc,lambda s:b'q\n1 0 0 1 100 0 cm\n'+s+b'\nQ'))

    def redact_label(document):
        label=next(l for l in manifest['pages'][0]['labels'] if l['role']=='artillery')
        box=fitz.Rect(label['x']+18,label['y']+18,label['x']+18+24*72/25.4,label['y']+18+25*72/25.4)
        document[0].add_redact_annot(box,fill=(1,1,1));document[0].apply_redactions()
    changed_pdf('missing-gun-copy',redact_label)

    def duplicate_label(document):
        label=next(l for l in manifest['pages'][0]['labels'] if l['role']=='artillery')
        box=fitz.Rect(label['x']+18,label['y']+18,label['x']+18+24*72/25.4,label['y']+18+25*72/25.4)
        with fitz.open(pdf) as source:document[0].show_pdf_page(fitz.Rect(650,520,650+box.width,520+box.height),source,0,clip=box)
    changed_pdf('duplicate-gun-copy',duplicate_label)

    def wrong_header(document):
        document[0].add_redact_annot(fitz.Rect(18,18,774,38),fill=(1,1,1));document[0].apply_redactions()
        document[0].insert_text((18,32),'CSA - Eastern - Mid War',fontsize=14)
    changed_pdf('wrong-side-header',wrong_header)

    invalid_html=args.output/'invalid-fit.html'
    html=(folder/'labels.html').read_text(encoding='utf-8')
    assert 'const lineHeight = ascent + descent;' in html
    invalid_html.write_text(html.replace('const lineHeight = ascent + descent;','const lineHeight = 100;'),encoding='utf-8')
    browser=find_browser()
    invalid_pdf=args.output/'invalid-fit.pdf'
    subprocess.run([str(browser),'--headless=new','--disable-gpu','--no-pdf-header-footer',f'--user-data-dir={args.output.resolve()/"invalid-profile"}',f'--print-to-pdf={invalid_pdf.resolve()}',invalid_html.resolve().as_uri()],check=True,capture_output=True,timeout=30,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
    rejected('impossible-fit-rejected',lambda:validate_pdf(invalid_pdf,copy.deepcopy(manifest),model))

    bad_dashes=args.output/'wrong-dash-pattern.html'
    bad_dashes.write_text(html.replace('stroke-dasharray="4 3"','stroke-dasharray="3 3"'),encoding='utf-8')
    bad_pdf=args.output/'wrong-dash-pattern.pdf'
    subprocess.run([str(browser),'--headless=new','--disable-gpu','--no-pdf-header-footer',f'--user-data-dir={args.output.resolve()/"dash-profile"}',f'--print-to-pdf={bad_pdf.resolve()}',bad_dashes.resolve().as_uri()],check=True,capture_output=True,timeout=30,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
    rejected('wrong-dash-pattern',lambda:validate_pdf(bad_pdf,copy.deepcopy(manifest),model))

    altered=copy.deepcopy(manifest);altered['labelWidthMm']=23
    rejected('manifest-cannot-approve-wrong-dimensions',lambda:validate_pdf(pdf,altered,model))
    altered=copy.deepcopy(manifest);altered['pages'][0]['labels'].pop()
    rejected('missing-label-identity',lambda:validate_pdf(pdf,altered,model))
    altered=copy.deepcopy(manifest);altered['pages'][0]['labels'][0]['y']+=1
    rejected('row-misalignment',lambda:validate_pdf(pdf,altered,model))
    altered=copy.deepcopy(manifest);altered['pages'][0]['labels'][0]['rows'][0]['text']='Omitted real name'
    rejected('manifest-cannot-rewrite-content',lambda:validate_pdf(pdf,altered,model))
    altered_model=copy.deepcopy(model)
    altered_model['Divisions'][0]['Brigades'][0]['Units'][0]['BraveColonel']=False
    rejected('independent-model-checks-brave-status',lambda:validate_pdf(pdf,copy.deepcopy(manifest),altered_model))

    with csv_path.open(encoding='utf-8-sig',newline='') as stream:original=list(csv.DictReader(stream))
    def changed_csv(name,change,headers=HEADERS):
        rows=copy.deepcopy(original);change(rows);target=args.output/f'{name}.csv'
        with target.open('w',encoding='utf-8',newline='') as stream:
            writer=csv.DictWriter(stream,fieldnames=headers);writer.writeheader();writer.writerows(rows)
        rejected(name,lambda:validate_csv(target,model,request,pdf))
    changed_csv('csv-header-order',lambda rows:None,list(reversed(HEADERS)))
    changed_csv('csv-missing-record',lambda rows:rows.pop(3))
    changed_csv('csv-lost-naming-provenance',lambda rows:next(r for r in rows if r['Notes']).__setitem__('Notes',''))
    def change_weapon(rows):
        row=next(r for r in rows if r['RecordType']=='Unit');record=json.loads(row['Result']);record['WeaponCode']='WRONG';row['Result']=json.dumps(record)
    changed_csv('csv-final-weapon-corruption',change_weapon)
    changed_csv('csv-sequence-corruption',lambda rows:rows[2].__setitem__('Sequence','999'))
    changed_csv('csv-request-corruption',lambda rows:rows[0].__setitem__('Result','{}'))
    def corrupt_pdf_identity(rows):
        proof=json.loads(rows[-2]['Result']);proof['sha256']='0'*64;rows[-2]['Result']=json.dumps(proof)
    changed_csv('csv-pdf-identity-corruption',corrupt_pdf_identity)
    (args.output/'results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
    print(f'TEST-SUMMARY|PASS|{len(results)} corruption cases rejected')


if __name__=='__main__':main()
