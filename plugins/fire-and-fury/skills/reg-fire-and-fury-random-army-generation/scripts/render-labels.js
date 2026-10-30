"use strict";

const fs = require("node:fs");
const { formationPages } = require("./formation-layout.js");
const CFG = Object.freeze({
  width: 24 * 72 / 25.4, height: 25 * 72 / 25.4,
  pageWidth: 756, pageHeight: 576, headerY: 14, firstY: 28,
  gap: 6, rowGap: 6, commandGap: 6, inset: 4,
  preferred: 9, minimumName: 7, baselineGap: 14,
});
const divider = .28 * CFG.height;
const brigadeX = CFG.width + CFG.commandGap;
const unitX = brigadeX + CFG.width + CFG.gap;
const pitch = CFG.height + CFG.rowGap;
const rowCapacity = Math.floor((CFG.pageHeight - CFG.firstY + CFG.rowGap) / pitch);
const columns = x => Math.floor((CFG.pageWidth - x + CFG.gap) / (CFG.width + CFG.gap));
const xml = value => String(value ?? "").replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&apos;"}[c]));

// This function is serialized into the local HTML. Fit only overflow, as Brigade does.
function fitLabelText() {
  try {
    const canvas = document.createElement("canvas");
    const context = canvas.getContext("2d");
    context.font = "700 900px Helvetica, Arial, sans-serif";
    const metrics = context.measureText("Hg");
    const ascent = metrics.fontBoundingBoxAscent / 100;
    const descent = metrics.fontBoundingBoxDescent / 100;
    const lineHeight = ascent + descent;
    if (!(lineHeight > 0)) throw new Error("Font metrics unavailable");
    for (const group of document.querySelectorAll("g.label")) {
      const texts = [...group.querySelectorAll("text")];
      const count = texts.length;
      const top = CFG.height * .28 + (count === 3 ? 8 : 5);
      const bottom = CFG.height - 5;
      const gap = count > 1 ? Math.min(CFG.baselineGap, Math.floor(4 * (bottom - top - lineHeight) / (count - 1)) / 4) : 0;
      if (count > 1 && gap < lineHeight + .1) throw new Error("Font cannot fit the preserved label rows");
      const blockHeight = lineHeight + (count - 1) * gap;
      const firstBaseline = top + (bottom - top - blockHeight) / 2 + ascent;
      const baselines = texts.map((_, index) => firstBaseline + index * gap);
      texts.forEach((text, index) => {
        const available = CFG.width - 2 * CFG.inset;
        const minimum = text.dataset.kind === "name" ? CFG.minimumName : CFG.preferred;
        text.setAttribute("y", firstBaseline + index * gap);
        text.setAttribute("font-size", CFG.preferred);
        text.removeAttribute("textLength");
        text.removeAttribute("lengthAdjust");
        const naturalWidth = text.getComputedTextLength();
        if (naturalWidth > available) {
          text.setAttribute("font-size", Math.max(minimum, CFG.preferred * available / naturalWidth));
          if (text.getComputedTextLength() > available) {
            text.setAttribute("textLength", available);
            text.setAttribute("lengthAdjust", "spacingAndGlyphs");
          }
        }
      });
      if (count === 3) {
        const bounds = texts.map(text => {
          const size = Number(text.getAttribute("font-size"));
          context.font = `700 ${size * 100}px Helvetica, Arial, sans-serif`;
          const measured = context.measureText(text.textContent);
          const occupied = text.textContent.trim().length > 0;
          return {
            ascent: occupied ? measured.actualBoundingBoxAscent / 100 : ascent,
            descent: occupied ? measured.actualBoundingBoxDescent / 100 : descent,
            fontAscent: measured.fontBoundingBoxAscent / 100,
            fontDescent: measured.fontBoundingBoxDescent / 100,
          };
        });
        const oldGaps = bounds.slice(0, 2).map((b,i) => baselines[i+1] - bounds[i+1].ascent - baselines[i] - b.descent);
        const heights = bounds.reduce((sum,b) => sum + b.ascent + b.descent, 0);
        const lastBottom = baselines[2] + bounds[2].descent;
        const minimumTop = Math.max(top, CFG.height * .28 + 1.5 + 5.427 + 3);
        const visibleGap = Math.min(...oldGaps, (lastBottom - minimumTop - heights)/2);
        for (let i=1;i>=0;i--) baselines[i] = baselines[i+1] - bounds[i+1].ascent - visibleGap - bounds[i].descent;
        const fits = visibleGap >= 0 && bounds.every((b,i) =>
          baselines[i] - b.fontAscent >= top - .00001 && baselines[i] + b.fontDescent <= bottom + .00001 &&
          (i === 2 || baselines[i+1] - bounds[i+1].fontAscent - baselines[i] - b.fontDescent >= .1 - .00001));
        if (!fits) throw new Error("Equal text gaps and Brave Colonel clearance cannot fit the preserved margins");
        texts.forEach((text,i) => text.setAttribute("y",baselines[i]));
      }
    }
    document.documentElement.dataset.fitted = "true";
  } catch (error) {
    document.documentElement.dataset.fitError = error.message;
    // A failed fit must not produce an apparently valid partial PDF.
    document.querySelectorAll(".page").forEach(page => { page.style.display = "none"; });
  }
}

function validateInput(input) {
  if (!Array.isArray(input.sides) || !input.sides.length) throw new Error("No requested sides");
  const ids = new Set();
  for (const side of input.sides) {
    if (!["USA", "CSA"].includes(side.side) || ids.has(side.side)) throw new Error("Invalid or duplicate side");
    ids.add(side.side);
    for (const label of [side.division, ...side.groups.flatMap(g => [g.label, ...g.units]), ...side.dismounted]) {
      if (!label.id || !Array.isArray(label.rows) || ![3, 4].includes(label.rows.length)) throw new Error("Invalid label record");
      if (label.brave && label.rows.length !== 3) throw new Error("A four-row label cannot carry a Brave Colonel marker");
      if (ids.has(label.id)) throw new Error(`Duplicate label ID ${label.id}`);
      ids.add(label.id);
    }
  }
}

function paginate(input) {
  validateInput(input);
  const pages = [];
  for (const sideName of ["USA", "CSA"]) {
    const side = input.sides.find(s => s.side === sideName);
    if (!side) continue;
    const dismounts = new Map(side.dismounted.map(label => [label.id, label]));
    const groups = [...side.groups.filter(g => !g.independent), ...side.groups.filter(g => g.independent)].map(group => ({
      id: group.id,
      label: group.independent ? null : group.label,
      heading: group.independent ? "Unassigned units" : "",
      units: group.units.map(unit => ({ ...unit, dismounted: dismounts.get(`${unit.id}:dismounted`) })),
    }));
    const used = groups.flatMap(g => g.units).filter(u => u.dismounted).map(u => u.dismounted.id);
    if (used.length !== dismounts.size) throw new Error("Missing mounted cavalry for a dismounted label");
    pages.push(...formationPages({ side: side.side, header: side.header, roots: [{ id: side.division.id, label: side.division, groups }] }, CFG.width, CFG.height, true));
  }
  return pages;
}

function labelSvg(label) {
  const rows = label.rows.map((row,i) => `<text data-kind="${xml(row.kind)}" data-row="${i}" x="${CFG.width / 2}" y="${40+i*10}" text-anchor="middle" font-family="Helvetica, Arial, sans-serif" font-weight="700" font-size="9" fill="white">${xml(row.text)}</text>`).join("");
  const star = label.brave ? `<polygon transform="translate(${CFG.width-10} ${divider+3.5})" points="3,0 3.735,1.989 5.853,2.073 4.189,3.386 4.763,5.427 3,4.25 1.237,5.427 1.811,3.386 0.147,2.073 2.265,1.989" fill="white"/>` : "";
  return `<g class="label" data-id="${xml(label.id)}" transform="translate(${label.x} ${label.y})"><rect width="${CFG.width}" height="${CFG.height}" fill="black" stroke="white" stroke-width="1"/><line x1="0" y1="${divider}" x2="${CFG.width}" y2="${divider}" stroke="white" stroke-width="1" stroke-dasharray="4 3"/>${star}${rows}</g>`;
}

function htmlDocument(pages) {
  const svgs = pages.map(page => `<svg class="page" xmlns="http://www.w3.org/2000/svg" width="756pt" height="576pt" viewBox="0 0 756 576"><text x="0" y="14" font-family="Helvetica, Arial, sans-serif" font-size="14" font-weight="700">${xml(page.header)}</text><g stroke="#8a8a8a" stroke-width="1.5" fill="none">${page.connectors.map(([x1,y1,x2,y2]) => `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}"/>`).join("")}</g>${page.headings.map(h => `<text x="${h.x}" y="${h.y}" font-family="Helvetica, Arial, sans-serif" font-size="10" font-weight="700">${xml(h.text)}</text>`).join("")}${page.labels.map(labelSvg).join("")}</svg>`);
  return `<!doctype html><html><head><meta charset="utf-8"><style>@page{size:Letter landscape;margin:0.25in}html,body{margin:0;padding:0}.page{display:block;width:10.5in;height:8in;break-after:page;page-break-after:always}.page:last-child{break-after:auto;page-break-after:auto}</style></head><body>${svgs.join("\n")}<script>const CFG=${JSON.stringify(CFG)};${fitLabelText.toString()};fitLabelText();document.fonts.ready.then(fitLabelText);window.addEventListener("beforeprint",fitLabelText);</script></body></html>`;
}

if (require.main === module) {
  try {
    const [input, output, manifest] = process.argv.slice(2);
    if (!input || !output || !manifest) throw new Error("Usage: node render-labels.js input.json labels.html manifest.json");
    const pages = paginate(JSON.parse(fs.readFileSync(input,"utf8")));
    fs.writeFileSync(output,htmlDocument(pages),"utf8");
    fs.writeFileSync(manifest,JSON.stringify({version:1,labelWidthMm:24,labelHeightMm:25,mainColumns:columns(unitX),flatColumns:columns(0),rowsPerPage:rowCapacity,pages},null,2),"utf8");
    process.stdout.write(`Rendered ${pages.length} Regimental label pages.\n`);
  } catch (error) { process.stderr.write(`${error.message}\n`);process.exitCode=1; }
}
module.exports = { CFG, paginate, htmlDocument, unitX, brigadeX, rowCapacity, columns };
