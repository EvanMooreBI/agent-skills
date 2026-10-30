"use strict";

// Kept byte-identical in both self-contained skill packages.
function formationPages(model, width, height, emptyRoot = false) {
  const gap = 6, pitch = height + gap, headingHeight = 14;
  const available = 576 - 28 + gap;
  const pages = [];
  let page;
  function fresh() {
    page = { side: model.side, kind: "main", header: model.header + (pages.length ? " - Continued" : ""), labels: [], connectors: [], headings: [], segments: [], used: 0 };
    pages.push(page);
  }
  fresh();
  for (const root of model.roots) {
    const hasRoot = Boolean(root.label);
    const groupX = hasRoot ? width + gap : 0;
    const unitX = groupX + width + gap;
    const capacity = Math.floor((756 - unitX + gap) / (width + gap));
    const groups = root.groups.filter(group => group.units.length).map(group => {
      const bands = [];
      for (let i = 0; i < group.units.length; i += capacity) {
        const units = group.units.slice(i, i + capacity);
        const rows = units.some(unit => unit.dismounted) ? 2 : 1;
        bands.push({ units, rows, height: rows * pitch });
      }
      return { ...group, bands, prefix: group.heading ? headingHeight : 0 };
    });
    const whole = groups.reduce((sum, group) => sum + group.prefix + group.bands.reduce((n, band) => n + band.height, 0), 0);
    if (whole <= available && page.used && page.used + whole > available + 1e-8) fresh();
    for (const group of groups) {
      const wholeGroup = group.prefix + group.bands.reduce((n, band) => n + band.height, 0);
      if (wholeGroup <= available && page.used && page.used + wholeGroup > available + 1e-8) fresh();
      for (let offset = 0; offset < group.bands.length;) {
        if (page.used + group.prefix + group.bands[offset].height > available + 1e-8) fresh();
        const bands = [];
        let consumed = group.prefix;
        while (offset < group.bands.length && page.used + consumed + group.bands[offset].height <= available + 1e-8) {
          consumed += group.bands[offset].height;
          bands.push(group.bands[offset++]);
        }
        if (!bands.length) throw new Error("A complete unit band cannot fit on a page");
        page.segments.push({ root, group, bands, groupX, unitX, y: 28 + page.used, consumed });
        page.used += consumed;
      }
    }
    if (!groups.length && emptyRoot && root.label) {
      page.segments.push({ root, empty: true });
    }
  }
  for (const p of pages) {
    const line = (x1, y1, x2, y2) => { if (Math.abs(x1-x2) + Math.abs(y1-y2) > 1e-8) p.connectors.push([x1,y1,x2,y2]); };
    const roots = new Map();
    function place(label, x, y, segment, extra = {}) {
      const { dismounted, ...record } = label;
      p.labels.push({ ...record, x, y, rootKey: segment.root.id, groupKey: segment.group?.id, ...extra });
    }
    for (const segment of p.segments) {
      const { root, group, groupX, unitX } = segment;
      if (!roots.has(root.id)) roots.set(root.id, { root, centers: [], targets: [] });
      const context = roots.get(root.id);
      if (segment.empty) continue;
      const firstY = segment.y + group.prefix;
      const center = firstY + (segment.consumed - group.prefix - gap) / 2;
      context.centers.push(center);
      context.targets.push({ center, x: group.label ? groupX : unitX - gap / 2 });
      if (group.heading) p.headings.push({ text: group.heading, x: unitX, y: segment.y + 10, rootKey: root.id, groupKey: group.id });
      if (group.label) place(group.label, groupX, center - height/2, segment);
      const trunk = unitX - gap / 2;
      const rowCenters = [];
      let y = firstY;
      for (const band of segment.bands) {
        rowCenters.push(y + height/2);
        line(trunk, y + height/2, unitX, y + height/2);
        band.units.forEach((unit, column) => {
          const x = unitX + column * (width + gap);
          place(unit, x, y, segment);
          if (unit.dismounted) {
            place(unit.dismounted, x, y + pitch, segment, { mountedId: unit.id });
            line(x + width/2, y + height, x + width/2, y + pitch);
          }
        });
        y += band.height;
      }
      if (group.label) line(groupX + width, center, trunk, center);
      line(trunk, Math.min(center, ...rowCenters), trunk, Math.max(center, ...rowCenters));
    }
    // Root command context occurs once per visible root on each page.
    for (const { root, centers, targets } of roots.values()) {
      if (!root.label) continue;
      const center = centers.length ? (centers[0] + centers.at(-1))/2 : 28 + height/2;
      p.labels.unshift({ ...root.label, x: 0, y: center - height/2, rootKey: root.id });
      if (targets.length) {
        const trunk = width + gap/2;
        line(width, center, trunk, center);
        line(trunk, Math.min(center, ...centers), trunk, Math.max(center, ...centers));
        targets.forEach(target => line(trunk, target.center, target.x, target.center));
      }
    }
    delete p.segments;
    delete p.used;
  }
  return pages.filter(p => p.labels.length);
}

module.exports = { formationPages };
