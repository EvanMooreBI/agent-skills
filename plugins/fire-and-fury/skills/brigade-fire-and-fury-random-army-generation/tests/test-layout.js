"use strict";
const assert=require("node:assert/strict"),fs=require("node:fs"),path=require("node:path");
const {LOCAL_LABEL_CONFIG:cfg,unitsPerRow,sideColumns,rowsPerPage,toRows,paginateFormation}=require("../scripts/render-labels.js");
let checks=0;function check(name,run){run();checks++;console.log(`TEST|${name}|PASS`);}
function model(count,root=true,cavalry=false){return {side:"USA",header:"USA",corps:[{key:"C",commander:root?"Commander":"",label:{id:"C",role:"corps"},divisions:[{key:"D",label:{id:"D",role:"division"},unitRows:toRows(Array.from({length:count},(_,i)=>({id:`U${i}`,role:"brigade",...(cavalry?{dismounted:{id:`U${i}:dismounted`,role:"brigade"}}:{})})),root?8:9)}]}]};}
check("24x25-and-vertical-constants",()=>{assert.equal(cfg.widthPt,24*72/25.4);assert.equal(cfg.heightPt,25*72/25.4);assert.equal(cfg.rowGapPt,6);assert.equal(cfg.textRowBaselineGapPt,14);assert.equal(rowsPerPage(),7);});
for(const [root,capacity] of [[true,8],[false,9]]){
 check(`columns-${root}`,()=>assert.equal(unitsPerRow(sideColumns(root).unit),capacity));
 for(const count of [capacity,capacity+1])check(`wrap-${root}-${count}`,()=>{const page=paginateFormation(model(count,root))[0];assert.equal(new Set(page.labels.filter(l=>l.role==='brigade').map(l=>l.y)).size,count===capacity?1:2);});
 for(const rows of [7,8])check(`pages-${root}-${rows}`,()=>assert.equal(paginateFormation(model(capacity*rows,root)).length,rows===7?1:2));
 for(const count of [3*capacity,3*capacity+1])check(`pairs-${root}-${count}`,()=>{const pages=paginateFormation(model(count,root,true));assert.equal(pages.length,count===3*capacity?1:2);for(const p of pages){for(const mounted of p.labels.filter(l=>l.id.startsWith('U')&&!l.mountedId)){const d=p.labels.find(l=>l.id===mounted.id+':dismounted');assert.equal(d.x,mounted.x);assert.ok(Math.abs(d.y-mounted.y-cfg.heightPt-6)<1e-9);}}});
}
check("layout-helper-package-parity",()=>assert.equal(fs.readFileSync(path.join(__dirname,'../scripts/formation-layout.js'),'utf8'),fs.readFileSync(path.join(__dirname,'../../reg-fire-and-fury-random-army-generation/scripts/formation-layout.js'),'utf8')));
check("no-flat-sections",()=>assert.ok(paginateFormation(model(2,true,true)).every(p=>p.kind==='main'&&!p.header.includes('Dismounted'))));
check("parent-entry-connected-for-one-paired-row",()=>{const p=paginateFormation(model(1,true,true))[0];const d=p.labels.find(l=>l.id==='D');const center=d.y+cfg.heightPt/2;const trunk=2*(cfg.widthPt+6)-3;assert.ok(p.connectors.some(l=>l[0]===trunk&&l[2]===trunk&&Math.abs(l[3]-center)<1e-9));});
check("unassigned-heading-seven-row-boundary",()=>{for(const count of [56,57]){const a=model(0);a.corps[0].divisions=[];a.corps[0].unassigned=Array.from({length:count},(_,i)=>({id:`A${i}`,role:'artillery'}));const p=paginateFormation(a);assert.equal(p.length,count===56?1:2);p.forEach(x=>{assert.equal(x.headings.length,1);assert.equal(x.labels.filter(l=>l.role==='division').length,0);});}});
check("local-extensions-do-not-bypass-source-errors",()=>{
 const os=require('node:os'),cp=require('node:child_process');const dir=fs.mkdtempSync(path.join(os.tmpdir(),'bff-source-guard-'));
 const data={corps:[{Side:'USA','Corps Name':'Case Corps','Corps Commander':'Commander',Theatre:'Eastern',Period:'Mid War'}],divisions:[],brigades:[],artillery:[],standaloneArtillery:[{side:'USA',corpsId:'CASE CORPS',name:'Battery',experience:'Veteran',weapon:'Light Rifle'}]};
 function run(input){const file=path.join(dir,'input.json');fs.writeFileSync(file,JSON.stringify(input));return cp.spawnSync(process.execPath,[path.join(__dirname,'../scripts/render-labels.js'),file,path.join(dir,'labels.html'),path.join(dir,'manifest.json')],{encoding:'utf8',windowsHide:true});}
 try {
  assert.equal(run(data).status,0);
  const bad=structuredClone(data);bad.corps[0].Theatre='Unknown';const rejected=run(bad);assert.equal(rejected.status,1);assert.match(rejected.stderr,/Theatre is not valid/);
  const missing=structuredClone(data);missing.corps[0]['Corps Commander']='';assert.equal(run(missing).status,1);
  const wrong=structuredClone(data);wrong.standaloneArtillery[0].corpsId='missing';assert.equal(run(wrong).status,1);
  const empty=structuredClone(data);empty.standaloneArtillery=[];const absent=run(empty);assert.equal(absent.status,1);assert.match(absent.stderr,/No Brigade or Artillery/);
 } finally {assert.ok(path.resolve(dir).startsWith(path.resolve(os.tmpdir())+path.sep));fs.rmSync(dir,{recursive:true,force:true});}
});
console.log(`TEST-SUMMARY|PASS|${checks} Brigade layout scenarios`);
