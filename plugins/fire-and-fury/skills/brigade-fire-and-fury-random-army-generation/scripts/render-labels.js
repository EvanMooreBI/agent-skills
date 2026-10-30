"use strict";

const fs = require("fs");
const path = require("path");
const vm = require("vm");
const { formationPages } = require("./formation-layout.js");

const MM_TO_PT = 72 / 25.4;
const LOCAL_LABEL_CONFIG = Object.freeze({
  widthPt: 24 * MM_TO_PT,
  heightPt: 25 * MM_TO_PT,
  dividerYPt: 0.28 * (25 * MM_TO_PT),
  textInsetPt: 4,
  pageWidthPt: 756,
  pageHeightPt: 576,
  pageHeaderYPt: 14,
  firstRowYPt: 28,
  gapPt: 6,
  rowGapPt: 6,
  preferredFontPt: 9,
  minimumNameFontPt: 7,
  textRowBaselineGapPt: 14,
  lowerTextTopPaddingPt: 5,
  lowerTextBottomPaddingPt: 5,
  lowerTextUsageLimit: 0.9,
  geometryName: "local-24mm-by-25mm",
});

function fail(message) {
  process.stderr.write(`${message}\n`);
  process.exit(1);
}

function value(input) {
  return String(input ?? "").trim();
}

function xml(input) {
  return value(input)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

function truthy(input) {
  return /^(yes|true|1)$/i.test(value(input));
}

function fitLabelText() {
  for (const text of document.querySelectorAll(".label text[data-max-width]")) {
    const available = Number(text.dataset.maxWidth);
    const preferred = Number(text.dataset.preferredFontSize);
    const minimum = Number(text.dataset.minFontSize);
    text.removeAttribute("textLength");
    text.removeAttribute("lengthAdjust");
    text.setAttribute("font-size", preferred);
    const naturalWidth = text.getComputedTextLength();
    if (naturalWidth <= available) continue;
    text.setAttribute("font-size", Math.max(minimum, preferred * available / naturalWidth));
    if (text.getComputedTextLength() > available) {
      text.setAttribute("textLength", available);
      text.setAttribute("lengthAdjust", "spacingAndGlyphs");
    }
  }
}

function textLine(text, x, y, options = {}) {
  const line = value(text);
  if (!line) return "";
  const preferred = options.preferred ?? LOCAL_LABEL_CONFIG.preferredFontPt;
  const minimum = options.minimum ?? preferred;
  const available = LOCAL_LABEL_CONFIG.widthPt - 2 * LOCAL_LABEL_CONFIG.textInsetPt;
  const row = options.row ? ` data-text-row="${xml(options.row)}"` : "";
  return `<text${row} x="${x + LOCAL_LABEL_CONFIG.widthPt / 2}" y="${y}" text-anchor="middle" font-family="Helvetica, Arial, sans-serif" font-size="${preferred}" font-weight="700" fill="white" data-max-width="${available}" data-preferred-font-size="${preferred}" data-min-font-size="${minimum}">${xml(line)}</text>`;
}

function lowerTextBand() {
  const lowerBandHeight = LOCAL_LABEL_CONFIG.heightPt - LOCAL_LABEL_CONFIG.dividerYPt;
  const paddedHeight = lowerBandHeight - LOCAL_LABEL_CONFIG.lowerTextTopPaddingPt - LOCAL_LABEL_CONFIG.lowerTextBottomPaddingPt;
  const height = Math.min(lowerBandHeight * LOCAL_LABEL_CONFIG.lowerTextUsageLimit, paddedHeight);
  return {
    topPt: LOCAL_LABEL_CONFIG.dividerYPt + LOCAL_LABEL_CONFIG.lowerTextTopPaddingPt + (paddedHeight - height) / 2,
    heightPt: height,
  };
}

function lowerTextBaselines(lineCount) {
  if (!Number.isInteger(lineCount) || lineCount < 1) return [];
  const band = lowerTextBand();
  const textBlockHeight = LOCAL_LABEL_CONFIG.preferredFontPt + (lineCount - 1) * LOCAL_LABEL_CONFIG.textRowBaselineGapPt;
  if (textBlockHeight > band.heightPt) fail(`Lower label text cannot fit ${lineCount} rows.`);
  const firstBaseline = band.topPt + (band.heightPt - textBlockHeight) / 2 + LOCAL_LABEL_CONFIG.preferredFontPt * 0.75;
  return Array.from({ length: lineCount }, (_, index) => firstBaseline + index * LOCAL_LABEL_CONFIG.textRowBaselineGapPt);
}

function label(labelData, x, y, attributes = "") {
  const divider = y + LOCAL_LABEL_CONFIG.dividerYPt;
  const role = value(labelData.role);
  const name = value(labelData.name);
  const exceptional = labelData.exceptional ? " E" : "";
  const rows = [];
  if (role === "corps") {
    rows.push({ text: name, row: "name", minimum: LOCAL_LABEL_CONFIG.minimumNameFontPt });
    if (labelData.exceptional) rows.push({ text: "E", row: "exceptional" });
  } else {
    if (value(labelData.parent)) rows.push({ text: labelData.parent, row: "parent", minimum: LOCAL_LABEL_CONFIG.minimumNameFontPt });
    rows.push({ text: `${name}${exceptional}`, row: "name", minimum: LOCAL_LABEL_CONFIG.minimumNameFontPt });
    if (value(labelData.ratings)) rows.push({ text: labelData.ratings, row: "ratings" });
  }
  const baselines = lowerTextBaselines(rows.length);
  const lines = rows.map((row, index) => textLine(row.text, x, y + baselines[index], row)).join("");
  return `<g class="label" data-label-role="${xml(role)}" data-text-row-count="${rows.length}"${attributes}><rect x="${x}" y="${y}" width="${LOCAL_LABEL_CONFIG.widthPt}" height="${LOCAL_LABEL_CONFIG.heightPt}" fill="black" stroke="white" stroke-width="1"/><line x1="${x}" y1="${divider}" x2="${x + LOCAL_LABEL_CONFIG.widthPt}" y2="${divider}" stroke="white" stroke-width="1" stroke-dasharray="4 3"/>${lines}</g>`;
}

function rowPitch() {
  return LOCAL_LABEL_CONFIG.heightPt + LOCAL_LABEL_CONFIG.rowGapPt;
}

function sideColumns(hasCorpsLabel) {
  const pitch = LOCAL_LABEL_CONFIG.widthPt + LOCAL_LABEL_CONFIG.gapPt;
  return hasCorpsLabel
    ? { corps: 0, division: pitch, unit: pitch * 2 }
    : { corps: null, division: 0, unit: pitch };
}

function unitsPerRow(firstX) {
  return Math.floor((LOCAL_LABEL_CONFIG.pageWidthPt - firstX + LOCAL_LABEL_CONFIG.gapPt) /
    (LOCAL_LABEL_CONFIG.widthPt + LOCAL_LABEL_CONFIG.gapPt));
}

function rowsPerPage() {
  return Math.floor((LOCAL_LABEL_CONFIG.pageHeightPt - LOCAL_LABEL_CONFIG.firstRowYPt + LOCAL_LABEL_CONFIG.rowGapPt) / rowPitch());
}

function toRows(items, capacity) {
  const rows = [];
  for (let index = 0; index < items.length; index += capacity) rows.push(items.slice(index, index + capacity));
  return rows;
}

function renderFormationPage(page) {
  const connectors = `<g class="connectors" stroke="#8a8a8a" stroke-width="1.5" fill="none">${page.connectors.map(([x1,y1,x2,y2]) => `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}"/>`).join("")}</g>`;
  const headings = page.headings.map(heading => `<text x="${heading.x}" y="${heading.y}" font-family="Helvetica, Arial, sans-serif" font-size="10" font-weight="700">${xml(heading.text)}</text>`).join("");
  const labels = page.labels.map(item => {
    const context = item.role === "corps" ? ` data-corps-key="${xml(item.rootKey)}"` : item.role === "division" ? ` data-division-key="${xml(item.id)}"` : "";
    return label(item, item.x, item.y, `${context} data-id="${xml(item.id)}" data-root-key="${xml(item.rootKey)}" data-group-key="${xml(item.groupKey || "")}"${item.mountedId ? ` data-mounted-id="${xml(item.mountedId)}"` : ""}`);
  }).join("");
  return `<svg class="page" data-page-kind="formation" width="756pt" height="576pt" viewBox="0 0 756 576" xmlns="http://www.w3.org/2000/svg"><text x="0" y="14" font-family="Helvetica, Arial, sans-serif" font-size="14" font-weight="700">${xml(page.header)}</text>${connectors}${headings}${labels}</svg>`;
}

function renderPage(page) { return renderFormationPage(page); }

function abbreviation(map, input) {
  return map[value(input)] || value(input);
}

function makeBrigadeLabel(row, division, dismounted = false) {
  const effectiveness = (sourceContext.api.CONFIG.effectiveness[value(row.Morale)] || {})[Number(row.Stands)] || value(row.Morale);
  return {
    role: "brigade",
    parent: `(${division.commander})`,
    name: `${dismounted ? "Dismounted " : ""}${value(row["Brigade Name"])}`,
    exceptional: truthy(row["Exceptional Leader"]),
    ratings: [
      abbreviation(sourceContext.api.CONFIG.abbreviations.experience, row.Experience),
      effectiveness,
      abbreviation(sourceContext.api.CONFIG.abbreviations.weapon, row.Weapon),
    ].filter(Boolean).join(" "),
  };
}

function makeArtilleryLabel(row, division) {
  return {
    role: "artillery",
    parent: `(${division.commander})`,
    name: value(row["Battery Name"]),
    ratings: [
      abbreviation(sourceContext.api.CONFIG.abbreviations.experience, row.Experience),
      abbreviation(sourceContext.api.CONFIG.abbreviations.weapon, row.Weapon),
    ].filter(Boolean).join(" "),
  };
}

function makeStandaloneArtilleryLabel(row) {
  const name = value(row.name);
  const experience = abbreviation(sourceContext.api.CONFIG.abbreviations.experience, row.experience);
  const weapon = abbreviation(sourceContext.api.CONFIG.abbreviations.weapon, row.weapon);
  if (!name || !experience || !weapon) fail("Standalone artillery requires name, experience, and weapon.");
  return { role: "artillery", parent: "", name, ratings: `${experience} ${weapon}` };
}

function validateLocalUnits(input) {
  const config = sourceContext.api.CONFIG;
  for (const row of [...(input.unassignedBrigades || []), ...(input.standaloneArtillery || [])]) {
    const corps = (input.corps || []).find(c => value(c.Side) === row.side && value(c["Corps Name"]).toLowerCase() === value(row.corpsId).toLowerCase());
    if (!corps || !value(row.name)) throw new Error("Unassigned unit requires a name and matching Corps/side");
    const brigade = (input.unassignedBrigades || []).includes(row);
    if (!config.lookups.Experience.includes(row.experience) || !config.lookups[brigade ? "Brigade Weapon" : "Artillery Weapon"].includes(row.weapon)) throw new Error("Invalid unassigned unit experience or weapon");
    if (brigade && (!["Infantry","Cavalry"].includes(row.type) || !Number.isInteger(row.stands) || row.stands < 2 || row.stands > 25 || !config.lookups.Morale.includes(row.morale) || row.effectiveness !== config.effectiveness[row.morale][row.stands] || typeof row.exceptionalLeader !== "boolean")) throw new Error("Invalid unassigned brigade ratings or leader flag");
  }
}

function buildLocalSideModels(input) {
  const divisionsByName = new Map();
  for (const row of input.divisions || []) divisionsByName.set(value(row["Division Name"]), {
    key: value(row["Division Name"]), corpsName: value(row["Corps Name"]), side: value(row.Side), commander: value(row.Commander), exceptional: truthy(row["Exceptional Leader"]), brigades: [], artillery: [],
  });
  for (const row of input.brigades || []) divisionsByName.get(value(row["Division Name"]))?.brigades.push(row);
  for (const row of input.artillery || []) divisionsByName.get(value(row["Division Name"]))?.artillery.push(row);
  return ["USA","CSA"].map(side => {
    const first = (input.corps || []).find(row => value(row.Side) === side);
    const corps = [];
    for (const row of input.corps || []) {
      if (value(row.Side) !== side) continue;
      const name = value(row["Corps Name"]), commander = value(row["Corps Commander"]), key = `${side}--${name}`;
      const divisions = [...divisionsByName.values()].filter(d => d.side === side && d.corpsName === name && (d.brigades.length || d.artillery.length)).map(d => {
        const units = d.brigades.map((b,i) => {
          const id = `${d.key}:brigade:${i}`;
          return { ...makeBrigadeLabel(b,d), id, ...(value(b.Type) === "Cavalry" ? { dismounted: { ...makeBrigadeLabel(b,d,true), id: `${id}:dismounted` } } : {}) };
        }).concat(d.artillery.map((a,i) => ({ ...makeArtilleryLabel(a,d), id: `${d.key}:artillery:${i}` })));
        return { ...d, label: { id: d.key, role: "division", parent: commander ? `(${commander})` : "", name: d.commander, exceptional: d.exceptional }, unitRows: toRows(units,unitsPerRow(sideColumns(Boolean(commander)).unit)) };
      });
      const belongs = unit => unit.side === side && value(unit.corpsId).toLowerCase() === name.toLowerCase();
      const unassigned = (input.unassignedBrigades || []).filter(belongs).map((unit,i) => {
        const b = {"Brigade Name":unit.name, Type:unit.type, Stands:unit.stands, Experience:unit.experience, Morale:unit.morale, Weapon:unit.weapon, "Exceptional Leader":unit.exceptionalLeader};
        const id = `${key}:unassigned:${i}`;
        return { ...makeBrigadeLabel(b,{commander}), id, ...(unit.type === "Cavalry" ? {dismounted: {...makeBrigadeLabel(b,{commander},true),id:`${id}:dismounted`}} : {}) };
      }).concat((input.standaloneArtillery || []).filter(belongs).map((unit,i) => ({...makeStandaloneArtilleryLabel(unit),id:`${key}:standalone:${i}`})));
      if (divisions.length || unassigned.length) corps.push({key, commander, label:{id:key,role:"corps",name:commander,exceptional:truthy(row["Exceptional Leader"])}, divisions, unassigned});
    }
    return {side,header:first ? `${side} - ${value(first.Theatre)} - ${value(first.Period)}` : "",corps};
  }).filter(side => side.corps.length);
}

function paginateFormation(model) {
  const roots = model.corps.map(corps => ({id:corps.key,label:corps.commander ? (corps.label || {id:corps.key,role:"corps",name:corps.commander}) : null,groups:[
    ...corps.divisions.map(division => ({id:division.key,label:division.label,units:division.unitRows.flat()})),
    ...(corps.unassigned?.length ? [{id:`${corps.key}:unassigned`,heading:"Unassigned units",units:corps.unassigned}] : []),
  ]}));
  return formationPages({...model,roots},LOCAL_LABEL_CONFIG.widthPt,LOCAL_LABEL_CONFIG.heightPt);
}

const sourceContext = {};
const code = fs.readFileSync(path.join(__dirname,"..","assets","Code.gs"),"utf8");
vm.runInNewContext(`${code}\nthis.api={CONFIG:CONFIG,buildLabelGroups_:buildLabelGroups_};`, sourceContext);

function main() {
const inputPath = process.argv[2];
const outputPath = process.argv[3];
const manifestPath = process.argv[4];
if (!inputPath || !outputPath || !manifestPath) fail("Usage: node render-labels.js <input.json> <output.html> <manifest.json>");

const input = JSON.parse(fs.readFileSync(inputPath, "utf8"));
let rowNumber = 2;
function table(rows) {
  return { rows: rows.map((values) => Object.assign({ _rowNumber: rowNumber++ }, values)) };
}
const sourceValidation = sourceContext.api.buildLabelGroups_({
  corps: table(input.corps || []),
  divisions: table(input.divisions || []),
  brigades: table(input.brigades || []),
  artillery: table(input.artillery || []),
});
validateLocalUnits(input);
const errors = sourceValidation.errors.filter(error => !(error === "No Brigade or Artillery rows were found to render." && !(input.brigades || []).length && !(input.artillery || []).length && ((input.unassignedBrigades || []).length || (input.standaloneArtillery || []).length)));
if (errors.length) fail(errors.join("\n"));

const models = buildLocalSideModels(input);
const pages = [];
for (const model of models) pages.push(...paginateFormation(model));
if (!pages.length) throw new Error("No populated formations or unassigned units");
const labelCount = pages.reduce((sum,page) => sum + page.labels.length,0);

const html = `<!doctype html><html><head><meta charset="utf-8"><style>
@page{size:Letter landscape;margin:0.25in}
html,body{margin:0;padding:0}
.page{display:block;width:10.5in;height:8in;break-after:page;page-break-after:always}
.page:last-child{break-after:auto;page-break-after:auto}
</style></head><body>${pages.map(renderPage).join("\n")}<script>
${fitLabelText.toString()}
fitLabelText();
document.fonts.ready.then(fitLabelText);
window.addEventListener("beforeprint", fitLabelText);
</script></body></html>`;
fs.writeFileSync(outputPath, html, "utf8");
fs.writeFileSync(manifestPath, JSON.stringify({
  pageCount: pages.length,
  rendererVersion: sourceContext.api.CONFIG.scriptVersion,
  rendererMode: LOCAL_LABEL_CONFIG.geometryName,
  textFittingMode: "browser-measured-shrink-only",
  labelWidthPt: LOCAL_LABEL_CONFIG.widthPt,
  labelHeightPt: LOCAL_LABEL_CONFIG.heightPt,
  labelWidthMm: 24,
  labelHeightMm: 25,
  dividerYPt: LOCAL_LABEL_CONFIG.dividerYPt,
  textRowBaselineGapPt: LOCAL_LABEL_CONFIG.textRowBaselineGapPt,
  lowerTextTopPaddingPt: LOCAL_LABEL_CONFIG.lowerTextTopPaddingPt,
  lowerTextBottomPaddingPt: LOCAL_LABEL_CONFIG.lowerTextBottomPaddingPt,
  lowerTextUsageLimit: LOCAL_LABEL_CONFIG.lowerTextUsageLimit,
  lowerTextUsableHeightPt: lowerTextBand().heightPt,
  labelCount,
  standaloneArtilleryCount: (input.standaloneArtillery || []).length,
}, null, 2), "utf8");
process.stdout.write(`Rendered ${pages.length} local-layout pages.\n`);

}
if (require.main === module) { try { main(); } catch (error) { fail(error.message); } }
module.exports = {LOCAL_LABEL_CONFIG,unitsPerRow,sideColumns,rowsPerPage,toRows,paginateFormation,buildLocalSideModels,renderPage,validateLocalUnits};
