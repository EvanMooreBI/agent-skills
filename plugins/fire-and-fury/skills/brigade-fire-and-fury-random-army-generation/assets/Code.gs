const CONFIG = {
  scriptVersion: "2026-09-06-bff-single-battery-labels",
  menuName: "Brigade Fire and Fury",
  sheets: {
    corps: "Corps",
    divisions: "Divisions",
    brigades: "Brigades",
    artillery: "Artillery",
    labelTemplate: "Label Template",
    lookups: "Lookups",
  },
  headers: {
    corps: [
      "Side",
      "Corps Name",
      "Corps Commander",
      "Exceptional Leader",
      "Theatre",
      "Period",
      "User Notes",
    ],
    divisions: [
      "Corps Name",
      "Division Name",
      "Commander",
      "Exceptional Leader",
      "Side",
      "Notes",
    ],
    brigades: [
      "Division Name",
      "Brigade Name",
      "Type",
      "Stands",
      "Experience",
      "Morale",
      "Weapon",
      "Exceptional Leader",
      "Notes",
    ],
    artillery: [
      "Division Name",
      "Battery Name",
      "Experience",
      "Weapon",
      "Notes",
    ],
    labelTemplate: ["Setting", "Value", "Notes"],
    lookups: ["Category", "Value"],
  },
  ignoredDataHeaders: ["User Notes", "Notes"],
  lookups: {
    Side: ["USA", "CSA"],
    Theatre: ["Eastern", "Western"],
    Period: ["Early War", "Mid War", "Late War"],
    Type: ["Infantry", "Cavalry"],
    Experience: ["Green", "Experienced", "Veteran", "Crack"],
    Morale: ["Spirited", "Reliable", "Unreliable", "Dispirited"],
    "Brigade Weapon": [
      "Rifle Musket",
      "Mixed Muskets",
      "Rifle & Carbine",
      "Repeater",
      "Breechloader",
      "Smoothbore Musket",
      "Shotgun & Hunting Rifle",
    ],
    "Artillery Weapon": [
      "Fortress Gun",
      "Siege Gun",
      "Naval Gun",
      "Heavy Rifle",
      "Light Rifle",
      "Rifle & Napoleon",
      "Rifle & Smoothbore",
      "Napoleon",
      "Smoothbore",
    ],
    "Exceptional Leader": ["Yes", "No"],
  },
  abbreviations: {
    experience: {
      Crack: "Crk",
      Veteran: "Vet",
      Experienced: "Exp",
      Green: "Grn",
    },
    weapon: {
      "Rifle Musket": "RM",
      "Mixed Muskets": "MM",
      "Rifle & Carbine": "RC",
      Repeater: "RP",
      Breechloader: "BL",
      "Smoothbore Musket": "SM",
      "Shotgun & Hunting Rifle": "SH",
      "Fortress Gun": "FG",
      "Siege Gun": "SG",
      "Naval Gun": "NG",
      "Heavy Rifle": "HR",
      "Light Rifle": "LR",
      "Rifle & Napoleon": "RN",
      "Rifle & Smoothbore": "RS",
      Napoleon: "NP",
      Smoothbore: "SB",
    },
  },
  effectiveness: {
    Spirited: {
      2: "2/-/1",
      3: "3/-/1",
      4: "4/2/1",
      5: "5/3/2",
      6: "6/4/2",
      7: "7/5/3",
      8: "8/5/3",
      9: "9/6/4",
      10: "10/7/4",
      11: "11/8/5",
      12: "12/8/5",
      13: "13/9/6",
      14: "14/10/6",
      15: "15/11/7",
      16: "16/11/7",
      17: "17/12/8",
      18: "18/13/8",
      19: "19/14/9",
      20: "20/14/9",
      21: "21/15/10",
      22: "22/16/10",
      23: "23/17/11",
      24: "24/17/11",
      25: "25/18/12",
    },
    Reliable: {
      2: "2/-/1",
      3: "3/2/1",
      4: "4/3/2",
      5: "5/4/3",
      6: "6/5/3",
      7: "7/6/4",
      8: "8/6/4",
      9: "9/7/5",
      10: "10/8/5",
      11: "11/9/6",
      12: "12/9/6",
      13: "13/10/7",
      14: "14/11/7",
      15: "15/12/8",
      16: "16/12/8",
      17: "17/13/9",
      18: "18/14/9",
      19: "19/15/10",
      20: "20/15/10",
      21: "21/16/11",
      22: "22/17/11",
      23: "23/18/12",
      24: "24/18/12",
      25: "25/19/13",
    },
    Unreliable: {
      2: "2/-/1",
      3: "3/-/2",
      4: "4/-/3",
      5: "5/-/4",
      6: "6/5/4",
      7: "7/6/5",
      8: "8/7/6",
      9: "9/8/7",
      10: "10/9/7",
      11: "11/10/8",
      12: "12/10/8",
      13: "13/11/9",
      14: "14/12/9",
      15: "15/13/10",
      16: "16/13/10",
      17: "17/14/11",
      18: "18/15/11",
      19: "19/16/12",
      20: "20/16/12",
      21: "21/17/13",
      22: "22/18/13",
      23: "23/19/14",
      24: "24/19/14",
      25: "25/20/15",
    },
    Dispirited: {
      2: "2/-/1",
      3: "3/-/2",
      4: "4/-/3",
      5: "5/-/4",
      6: "6/-/5",
      7: "7/-/6",
      8: "8/-/7",
      9: "9/-/8",
      10: "10/-/9",
      11: "11/-/10",
      12: "12/11/10",
      13: "13/12/11",
      14: "14/13/12",
      15: "15/14/13",
      16: "16/15/14",
      17: "17/16/15",
      18: "18/17/16",
      19: "19/18/17",
      20: "20/19/18",
      21: "21/20/19",
      22: "22/21/20",
      23: "23/22/21",
      24: "24/23/22",
      25: "25/24/23",
    },
  },
  label: {
    widthPt: 72,
    heightPt: 90,
    dividerYPt: 25.2,
    textMaxWidthPt: 64,
    horizontalTextScale: 0.9,
    defaultFontPt: 9,
    minimumNameFontPt: 7,
    pageWidthPt: 756,
    pageHeightPt: 576,
    titleHeightPt: 32,
    rowGapPt: 9,
  },
};

function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu(CONFIG.menuName)
    .addItem("Set up workbook tabs", "setupArmyBuilderWorkbook")
    .addSeparator()
    .addItem("Generate Unit Labels PDF", "generateUnitLabelsPdf")
    .addSeparator()
    .addItem("Clear User Entries", "clearUserEntries")
    .addSeparator()
    .addItem("Show Script Version", "showScriptVersion")
    .addToUi();
}
function setupArmyBuilderWorkbook() {
  const ss = SpreadsheetApp.getActive(),
    ui = SpreadsheetApp.getUi();
  if (!migrateRegimentalTabs_(ss, ui)) return;
  Object.keys(CONFIG.headers).forEach((k) =>
    setupSheet_(ss, CONFIG.sheets[k], CONFIG.headers[k], k),
  );
  applyWorkbookFormatting_(ss);
  applyDataValidation_(ss);
  ui.alert(
    "Brigade Fire and Fury workbook tabs are ready. Complete Corps and Division assignments before generating labels.",
  );
}
function migrateRegimentalTabs_(ss, ui) {
  if (ss.getSheetByName(CONFIG.sheets.corps)) return true;
  const c = ss.getSheetByName("Division"),
    d = ss.getSheetByName("Brigades"),
    b = ss.getSheetByName("Regiments");
  if (!c && !d && !b) return true;
  if (!c || !d || !b || ss.getSheetByName(CONFIG.sheets.divisions)) {
    ui.alert(
      "Workbook setup stopped. The Regimental tab migration is incomplete or conflicts with an existing Brigade tab.",
    );
    return false;
  }
  d.setName("__BFF Divisions Migration");
  b.setName(CONFIG.sheets.brigades);
  c.setName(CONFIG.sheets.corps);
  ss.getSheetByName("__BFF Divisions Migration").setName(
    CONFIG.sheets.divisions,
  );
  return true;
}
function setupSheet_(ss, name, headers, key) {
  const s = ss.getSheetByName(name) || ss.insertSheet(name),
    data = s.getLastRow() > 1;
  if (!data || key === "lookups" || key === "labelTemplate") {
    s.clearContents();
    s.getRange(1, 1, 1, headers.length).setValues([headers]);
    const rows =
      key === "lookups"
        ? getLookupRows_()
        : key === "labelTemplate"
          ? getLabelTemplateRows_()
          : [];
    if (rows.length)
      s.getRange(2, 1, rows.length, rows[0].length).setValues(rows);
  } else s.getRange(1, 1, 1, headers.length).setValues([headers]);
  if (key === "corps" && s.getMaxRows() < 11)
    s.insertRowsAfter(s.getMaxRows(), 11 - s.getMaxRows());
  s.setFrozenRows(1);
  s.getRange(1, 1, 1, headers.length).setFontWeight("bold");
}
function generateUnitLabelsPdf() {
  const ui = SpreadsheetApp.getUi();
  try {
    const build = buildLabelGroups_(loadWorkbook_(SpreadsheetApp.getActive()));
    if (build.errors.length) {
      ui.alert(
        "Cannot generate labels until these issues are fixed:\n\n" +
          build.errors.join("\n"),
      );
      return;
    }
    const t = HtmlService.createTemplateFromFile("LabelPdf");
    t.pages = build.pages;
    t.labelConfig = CONFIG.label;
    const blob = HtmlService.createHtmlOutput(t.evaluate().getContent())
        .getAs("application/pdf")
        .setName(makePdfFileName_()),
      file = getSpreadsheetFolder_(SpreadsheetApp.getActive()).createFile(blob);
    ui.alert(["Created PDF:", file.getName(), file.getUrl()].join("\n"));
  } catch (error) {
    ui.alert("Label generation failed:\n\n" + error.message);
    throw error;
  }
}
function clearUserEntries() {
  const ui = SpreadsheetApp.getUi();
  if (
    ui.alert(
      "Clear user entries?",
      "This clears Corps, Division, Brigade, and Artillery data while preserving Notes and User Notes.",
      ui.ButtonSet.YES_NO,
    ) !== ui.Button.YES
  )
    return;
  const n = ["corps", "divisions", "brigades", "artillery"].reduce(
    (x, k) =>
      x +
      clearSheetDataEntries_(
        SpreadsheetApp.getActive().getSheetByName(CONFIG.sheets[k]),
      ),
    0,
  );
  ui.alert(`Cleared ${n} data-entry columns.`);
}
function showScriptVersion() {
  SpreadsheetApp.getUi().alert(
    [
      `Brigade Fire and Fury script version: ${CONFIG.scriptVersion}`,
      "Corps rows: up to five USA and five CSA corps",
      "Hierarchy: Corps, Divisions, Brigades, and Division Artillery",
      "Labels: fixed Letter continuation pages",
    ].join("\n"),
  );
}

function loadWorkbook_(ss) {
  return {
    corps: readTableSheet_(requiredSheet_(ss, CONFIG.sheets.corps)),
    divisions: readTableSheet_(requiredSheet_(ss, CONFIG.sheets.divisions)),
    brigades: readTableSheet_(requiredSheet_(ss, CONFIG.sheets.brigades)),
    artillery: readTableSheet_(requiredSheet_(ss, CONFIG.sheets.artillery)),
  };
}
function buildLabelGroups_(workbook) {
  const errors = [],
    corpsByKey = {},
    divisionsByName = {},
    sides = { USA: [], CSA: [] };
  workbook.corps.rows.forEach((r) => {
    const side = v_(r.Side),
      name = v_(r["Corps Name"]),
      commander = v_(r["Corps Commander"]),
      theatre = v_(r.Theatre),
      period = v_(r.Period);
    [
      ["Side", side],
      ["Corps Name", name],
      ["Corps Commander", commander],
      ["Theatre", theatre],
      ["Period", period],
    ].forEach((x) => {
      if (!x[1]) errors.push(`Corps row ${r._rowNumber}: ${x[0]} is required.`);
    });
    if (CONFIG.lookups.Side.indexOf(side) < 0)
      errors.push(`Corps row ${r._rowNumber}: Side must be USA or CSA.`);
    if (!inList_(theatre, CONFIG.lookups.Theatre))
      errors.push(`Corps row ${r._rowNumber}: Theatre is not valid.`);
    if (!inList_(period, CONFIG.lookups.Period))
      errors.push(`Corps row ${r._rowNumber}: Period is not valid.`);
    const key = side + "\u0000" + name;
    if (corpsByKey[key])
      errors.push(
        `Corps row ${r._rowNumber}: duplicate Corps Name for ${side}.`,
      );
    else if (side && name) {
      const e = {
        row: r,
        side,
        name,
        commander,
        theatre,
        period,
        divisions: [],
      };
      corpsByKey[key] = e;
      sides[side].push(e);
    }
  });
  CONFIG.lookups.Side.forEach((side) => {
    if (sides[side].length > 5)
      errors.push(`Corps: ${side} supports at most five populated rows.`);
    if (
      sides[side].length > 1 &&
      sides[side].some(
        (c) =>
          c.theatre !== sides[side][0].theatre ||
          c.period !== sides[side][0].period,
      )
    )
      errors.push(`Corps: ${side} rows must use the same Theatre and Period.`);
  });
  workbook.divisions.rows.forEach((r) => {
    const name = v_(r["Division Name"]),
      corps = v_(r["Corps Name"]),
      side = v_(r.Side),
      commander = v_(r.Commander);
    [
      ["Corps Name", corps],
      ["Division Name", name],
      ["Commander", commander],
      ["Side", side],
    ].forEach((x) => {
      if (!x[1])
        errors.push(`Divisions row ${r._rowNumber}: ${x[0]} is required.`);
    });
    if (!inList_(side, CONFIG.lookups.Side))
      errors.push(`Divisions row ${r._rowNumber}: Side must be USA or CSA.`);
    if (divisionsByName[name])
      errors.push(
        `Divisions row ${r._rowNumber}: Division Name "${name}" must be globally unique.`,
      );
    const parent = corpsByKey[side + "\u0000" + corps];
    if (!parent)
      errors.push(
        `Divisions row ${r._rowNumber}: Side and Corps Name do not match Corps.`,
      );
    else {
      const e = { row: r, name, commander, brigades: [], artillery: [] };
      divisionsByName[name] = e;
      parent.divisions.push(e);
    }
  });
  workbook.brigades.rows.forEach((r) => {
    const d = v_(r["Division Name"]),
      n = v_(r["Brigade Name"]),
      type = v_(r.Type),
      stands = v_(r.Stands),
      experience = v_(r.Experience),
      morale = v_(r.Morale),
      weapon = v_(r.Weapon);
    if (!d || !n || !type || !stands || !experience || !morale || !weapon)
      errors.push(
        `Brigades row ${r._rowNumber}: Division Name, Brigade Name, Type, Stands, Experience, Morale, and Weapon are required.`,
      );
    else if (!inList_(type, CONFIG.lookups.Type))
      errors.push(`Brigades row ${r._rowNumber}: Type is not valid.`);
    else if (!validStand_(stands))
      errors.push(
        `Brigades row ${r._rowNumber}: Stands must be a whole number from 2 to 25.`,
      );
    else if (!inList_(experience, CONFIG.lookups.Experience))
      errors.push(`Brigades row ${r._rowNumber}: Experience is not valid.`);
    else if (!inList_(morale, CONFIG.lookups.Morale))
      errors.push(`Brigades row ${r._rowNumber}: Morale is not valid.`);
    else if (!inList_(weapon, CONFIG.lookups["Brigade Weapon"]))
      errors.push(
        `Brigades row ${r._rowNumber}: Weapon is not valid for Brigades.`,
      );
    else if (!divisionsByName[d])
      errors.push(
        `Brigades row ${r._rowNumber}: Division Name "${d}" does not match Divisions.`,
      );
    else divisionsByName[d].brigades.push(r);
  });
  workbook.artillery.rows.forEach((r) => {
    const d = v_(r["Division Name"]),
      n = v_(r["Battery Name"]),
      experience = v_(r.Experience),
      weapon = v_(r.Weapon);
    if (!d && !n && !experience && !weapon) return;
    if (!d || !n || !experience || !weapon)
      errors.push(
        `Artillery row ${r._rowNumber}: Division Name, Battery Name, Experience, and Weapon are required.`,
      );
    else if (!inList_(experience, CONFIG.lookups.Experience))
      errors.push(`Artillery row ${r._rowNumber}: Experience is not valid.`);
    else if (!inList_(weapon, CONFIG.lookups["Artillery Weapon"]))
      errors.push(
        `Artillery row ${r._rowNumber}: Weapon is not valid for Artillery.`,
      );
    else if (!divisionsByName[d])
      errors.push(
        `Artillery row ${r._rowNumber}: Division Name "${d}" does not match Divisions.`,
      );
    else divisionsByName[d].artillery.push(r);
  });
  const models = CONFIG.lookups.Side.map((side) => ({
    side,
    corps: sides[side].filter((c) =>
      c.divisions.some((d) => d.brigades.length || d.artillery.length),
    ),
    header: sides[side].length
      ? `${side} - ${sides[side][0].theatre} - ${sides[side][0].period}`
      : "",
  })).filter((x) => x.corps.length);
  if (!models.length && !errors.length)
    errors.push("No Brigade or Artillery rows were found to render.");
  return {
    errors,
    pages: models.reduce((a, m) => a.concat(paginateSide_(m)), []),
  };
}
function paginateSide_(model) {
  const cap = 5,
    pages = [];
  let page = newPage_(model.header, false),
    used = 0;
  model.corps.forEach((c) => {
    const divisions = c.divisions.map((d) => ({
        division: d,
        rows: divisionRows_(d),
      })),
      total = divisions.reduce((n, x) => n + x.rows.length, 0);
    if (total <= cap && used && used + total > cap) {
      pages.push(page);
      page = newPage_(model.header, true);
      used = 0;
    }
    divisions.forEach((x) => {
      for (let i = 0; i < x.rows.length;) {
        if (used === cap) {
          pages.push(page);
          page = newPage_(model.header, true);
          used = 0;
        }
        const take = Math.min(cap - used, x.rows.length - i);
        page.segments.push({
          corps: corpsLabel_(c),
          division: divisionLabel_(c, x.division),
          rows: x.rows.slice(i, i + take),
        });
        used += take;
        i += take;
      }
    });
  });
  if (page.segments.length) pages.push(page);
  const cav = [];
  model.corps.forEach((c) =>
    c.divisions.forEach((d) =>
      d.brigades.forEach((b) => {
        if (armClass_(b.Type) === "cavalry")
          cav.push(brigadeLabel_(b, d, true));
      }),
    ),
  );
  for (let i = 0; i < cav.length; i += 7) {
    const p = newPage_(model.header, true);
    p.dismounted = cav.slice(i, i + 7);
    p.dismountedContinued = i > 0;
    pages.push(p);
  }
  return pages;
}
function newPage_(header, continued) {
  return {
    header: header + (continued ? " - Continued" : ""),
    segments: [],
    dismounted: [],
    dismountedContinued: false,
  };
}
function divisionRows_(d) {
  const u = d.brigades
    .map((b) => brigadeLabel_(b, d, false))
    .concat(d.artillery.reduce((a, r) => a.concat(artilleryLabels_(r, d)), []));
  const rows = [];
  for (let i = 0; i < u.length; i += 7)
    rows.push({
      units: u.slice(i, i + 7),
    });
  return rows;
}
function corpsLabel_(c) {
  return {
    role: "corps",
    name: c.commander,
    exceptional: truthy_(c.row["Exceptional Leader"]),
  };
}
function divisionLabel_(c, d) {
  return {
    role: "division",
    parent: paren_(c.commander),
    name: d.commander,
    exceptional: truthy_(d.row["Exceptional Leader"]),
  };
}
function brigadeLabel_(b, d, dismounted) {
  return {
    role: "brigade",
    parent: paren_(d.commander),
    name:
      (dismounted ? "Dismounted " : "") +
      v_(b["Brigade Name"]) +
      (truthy_(b["Exceptional Leader"]) ? " E" : ""),
    ratings: ratings_(
      b.Experience,
      effectiveness_(b.Stands, b.Morale),
      b.Weapon,
    ),
  };
}
function artilleryLabels_(r, d) {
  return [
    {
      role: "artillery",
      parent: paren_(d.commander),
      name: v_(r["Battery Name"]),
      ratings: ratings_(r.Experience, "", r.Weapon),
    },
  ];
}
function ratings_(e, m, w) {
  return [abbrExperience_(e), m, abbrWeapon_(w)].filter(Boolean).join(" ");
}
function effectiveness_(stands, morale) {
  return (
    (CONFIG.effectiveness[v_(morale)] || {})[parseInt(v_(stands), 10)] ||
    v_(morale)
  );
}
function abbrExperience_(x) {
  return CONFIG.abbreviations.experience[v_(x)] || v_(x);
}
function abbrWeapon_(x) {
  return CONFIG.abbreviations.weapon[v_(x)] || v_(x);
}
function armClass_(x) {
  return v_(x).toLowerCase().indexOf("cav") >= 0 ? "cavalry" : "infantry";
}
function applyWorkbookFormatting_(ss) {
  Object.keys(CONFIG.sheets).forEach((k) => {
    const s = ss.getSheetByName(CONFIG.sheets[k]);
    if (s) s.autoResizeColumns(1, s.getLastColumn());
  });
}
function applyDataValidation_(ss) {
  const c = requiredSheet_(ss, CONFIG.sheets.corps),
    d = requiredSheet_(ss, CONFIG.sheets.divisions),
    b = requiredSheet_(ss, CONFIG.sheets.brigades),
    a = requiredSheet_(ss, CONFIG.sheets.artillery);
  setList_(c, "Side", CONFIG.lookups.Side);
  setList_(c, "Theatre", CONFIG.lookups.Theatre);
  setList_(c, "Period", CONFIG.lookups.Period);
  setList_(c, "Exceptional Leader", CONFIG.lookups["Exceptional Leader"]);
  setList_(d, "Side", CONFIG.lookups.Side);
  setList_(d, "Exceptional Leader", CONFIG.lookups["Exceptional Leader"]);
  setRange_(d, "Corps Name", c, "Corps Name");
  ["Type", "Experience", "Morale", "Exceptional Leader"].forEach((h) =>
    setList_(b, h, CONFIG.lookups[h]),
  );
  setList_(b, "Weapon", CONFIG.lookups["Brigade Weapon"]);
  setRange_(b, "Division Name", d, "Division Name");
  setList_(a, "Experience", CONFIG.lookups.Experience);
  setList_(a, "Weapon", CONFIG.lookups["Artillery Weapon"]);
  setRange_(a, "Division Name", d, "Division Name");
}
function setList_(s, h, values) {
  const c = column_(s, h);
  if (c)
    s.getRange(2, c, Math.max(1, s.getMaxRows() - 1), 1).setDataValidation(
      SpreadsheetApp.newDataValidation()
        .requireValueInList(values, true)
        .setAllowInvalid(false)
        .build(),
    );
}
function setRange_(s, h, source, sh) {
  const c = column_(s, h),
    sc = column_(source, sh);
  if (c && sc)
    s.getRange(2, c, Math.max(1, s.getMaxRows() - 1), 1).setDataValidation(
      SpreadsheetApp.newDataValidation()
        .requireValueInRange(
          source.getRange(2, sc, Math.max(1, source.getMaxRows() - 1), 1),
          true,
        )
        .setAllowInvalid(false)
        .build(),
    );
}
function clearSheetDataEntries_(s) {
  if (!s) return 0;
  const hs = s.getRange(1, 1, 1, s.getLastColumn()).getValues()[0].map(v_);
  let n = 0;
  hs.forEach((h, i) => {
    if (h && CONFIG.ignoredDataHeaders.indexOf(h) < 0) {
      s.getRange(2, i + 1, Math.max(1, s.getMaxRows() - 1), 1).clearContent();
      n++;
    }
  });
  return n;
}
function readTableSheet_(s) {
  const v = s.getDataRange().getValues(),
    h = (v[0] || []).map(v_);
  return {
    rows: v
      .slice(1)
      .map((r, i) => {
        const o = { _rowNumber: i + 2 };
        h.forEach((x, j) => (o[x] = r[j]));
        return o;
      })
      .filter((r) =>
        h.some((x) => CONFIG.ignoredDataHeaders.indexOf(x) < 0 && v_(r[x])),
      ),
  };
}
function requiredSheet_(ss, n) {
  const s = ss.getSheetByName(n);
  if (!s)
    throw new Error(`Missing sheet "${n}". Run "Set up workbook tabs" first.`);
  return s;
}
function column_(s, h) {
  const i = s
    .getRange(1, 1, 1, s.getLastColumn())
    .getValues()[0]
    .map(v_)
    .indexOf(h);
  return i < 0 ? 0 : i + 1;
}
function validStand_(x) {
  const value = parseInt(v_(x), 10);
  return String(value) === v_(x) && value >= 2 && value <= 25;
}
function inList_(value, allowed) {
  return allowed.indexOf(value) >= 0;
}
function truthy_(x) {
  return (
    ["true", "yes", "y", "1", "e", "exceptional"].indexOf(
      v_(x).toLowerCase(),
    ) >= 0
  );
}
function paren_(x) {
  return v_(x) ? `(${v_(x)})` : "";
}
function v_(x) {
  return x === null || x === undefined ? "" : String(x).trim();
}
function getSpreadsheetFolder_(ss) {
  const p = DriveApp.getFileById(ss.getId()).getParents();
  return p.hasNext() ? p.next() : DriveApp.getRootFolder();
}
function makePdfFileName_() {
  return `BFF Labels - ${Utilities.formatDate(
    new Date(),
    Session.getScriptTimeZone(),
    "yyyy-MM-dd HH:mm",
  )}.pdf`;
}
function getLookupRows_() {
  return Object.keys(CONFIG.lookups).reduce(
    (a, k) => a.concat(CONFIG.lookups[k].map((v) => [k, v])),
    [],
  );
}
function getLabelTemplateRows_() {
  return [
    ["Page", "US Letter landscape", "Fixed 10.5 by 8 in SVG pages."],
    [
      "Hierarchy",
      "Corps to Division to Brigade",
      "Continuation pages repeat active command labels.",
    ],
    [
      "Exceptional Leader",
      "E",
      "Corps and Division: below commander. Brigade: appended to name.",
    ],
    [
      "Ratings",
      "Experience Effectiveness Weapon",
      "Brigades use effectiveness. Artillery uses Experience Weapon.",
    ],
    ["Divider", "0.35 in from top", "The upper label area remains blank."],
  ];
}
