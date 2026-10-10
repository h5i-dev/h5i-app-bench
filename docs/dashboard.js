"use strict";

const DATA = "./data";
const $ = (sel, root = document) => root.querySelector(sel);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const fmt = (n) => (n == null ? "–" : Number(n).toLocaleString("en"));
const kLines = (n) => (n >= 10000 ? `${(n / 1000).toFixed(1)}k` : fmt(n));
const pct = (a, b) => (b ? (a / b) * 100 : 0);
const pctText = (a, b, digits = 0) => `${pct(a, b).toFixed(digits)}%`;
const median = (xs) => {
  if (!xs.length) return null;
  const s = [...xs].sort((a, b) => a - b);
  const m = s.length >> 1;
  return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2;
};
const ratioText = (r) => (r >= 10 ? `${r.toFixed(0)}×` : r >= 0.1 ? `${r.toFixed(2)}×` : `${r.toPrecision(2)}×`);
const bar = (a, b, cls = "") => `<div class="bar-track" aria-hidden="true"><div class="bar-fill ${cls}" style="width:${pct(a, b).toFixed(1)}%"></div></div>`;
const barRow = (a, b, cls = "") =>
  `<div class="bar-row">${bar(a, b, cls)}<span class="bar-label"><span class="pct">${pctText(a, b)}</span> <span class="of">${fmt(a)} / ${fmt(b)}</span></span></div>`;

let INDEX = null;
const cache = new Map();

// ---- Theme ------------------------------------------------------------------

function currentTheme() {
  return document.documentElement.dataset.theme || "dark";
}
function setTheme(t) {
  document.documentElement.dataset.theme = t;
  try { localStorage.setItem("theme", t); } catch (e) { /* private mode */ }
  for (const b of document.querySelectorAll("[data-theme-set]")) b.setAttribute("aria-pressed", String(b.dataset.themeSet === t));
}

// ---- Syntax highlighting ----------------------------------------------------

const KEYWORDS = {
  rust: "as async await break const continue crate else enum false fn for if impl in let loop match mod move mut pub ref return self Self static struct super trait true type unsafe use where while dyn",
  lean: "theorem lemma def abbrev structure inductive where with match fun let in if then else do by have show from at open namespace end section variable instance class deriving termination_by decreasing_by noncomputable private protected partial mutual return calc exact intro intros apply simp simp_all rw cases rcases obtain induction unfold omega constructor refine use rfl sorry fun_prop decide",
};
const KW = Object.fromEntries(Object.entries(KEYWORDS).map(([k, v]) => [k, new Set(v.split(" "))]));
const TOKEN = {
  rust: /(\/\/[^\n]*|\/\*[\s\S]*?\*\/)|("(?:\\.|[^"\\])*"|b"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])')|(\b\d[\w.]*\b)|([A-Za-z_]\w*)/g,
  lean: /(--[^\n]*|\/-[\s\S]*?-\/)|("(?:\\.|[^"\\])*")|(\b\d[\w#.]*\b)|([A-Za-z_][\w'.]*)/g,
};

function highlight(code, lang) {
  const re = TOKEN[lang];
  const kw = KW[lang];
  let out = "";
  let last = 0;
  code.replace(re, (m, com, str, num, word, at) => {
    out += esc(code.slice(last, at));
    if (com) out += `<span class="tok-com">${esc(m)}</span>`;
    else if (str) out += `<span class="tok-str">${esc(m)}</span>`;
    else if (num) out += `<span class="tok-num">${esc(m)}</span>`;
    else if (kw.has(m)) out += `<span class="tok-kw">${esc(m)}</span>`;
    else if (/^[A-Z]/.test(m)) out += `<span class="tok-type">${esc(m)}</span>`;
    else out += esc(m);
    last = at + m.length;
    return m;
  });
  return out + esc(code.slice(last));
}

function codeBlock({ title, sub, url, code, lang }) {
  const link = url ? `<a href="${esc(url)}" target="_blank" rel="noreferrer">source ↗</a>` : "";
  return `<div class="code"><div class="code-head"><strong>${esc(title)}</strong>${sub ? `<span>${esc(sub)}</span>` : ""}${link}</div>
    <pre><code>${highlight(code, lang)}</code></pre></div>`;
}

// ---- Shared status helpers --------------------------------------------------

const STATUS = {
  accepted: ["good", "✓", "accepted"],
  open: ["", "·", "open"],
  stale: ["warn", "!", "recheck"],
};
function statusChip(t) {
  const [cls, icon, word] = STATUS[t.status] || STATUS.open;
  const fix = t.correction ? `<span class="chip warn" title="${esc(t.correction.change)}">± corrected</span>` : "";
  return `<span class="chip ${cls}"><span aria-hidden="true">${icon}</span>${word}</span>${fix}`;
}
function passMark(v, label) {
  if (v == null) return `<span class="mark none" title="${label}: not measured">·<span class="sr"> not measured</span></span>`;
  return v.passed
    ? `<span class="mark good" title="${label}: passed ${esc(v.when || "")}">✓</span>`
    : `<span class="mark bad" title="${label}: failing ${esc(v.when || "")}">✗</span>`;
}
const proverLabel = (p) => p ?? "–";

// ---- Sortable tables ----------------------------------------------------------

const SORT = {};
function sortable(id, render) {
  const table = $(`#${id}`);
  table.querySelector("thead").addEventListener("click", (e) => {
    const th = e.target.closest("th[data-sort]");
    if (!th) return;
    const cur = SORT[id];
    const dir = cur && cur.key === th.dataset.sort && cur.dir === "descending" ? "ascending" : "descending";
    SORT[id] = { key: th.dataset.sort, dir };
    for (const h of table.querySelectorAll("th[data-sort]")) h.removeAttribute("aria-sort");
    th.setAttribute("aria-sort", dir);
    render();
  });
}
function applySort(id, rows, keys) {
  const s = SORT[id];
  if (!s || !keys[s.key]) return rows;
  const f = keys[s.key];
  const sign = s.dir === "ascending" ? 1 : -1;
  return [...rows].sort((a, b) => {
    const x = f(a), y = f(b);
    if (x == null && y == null) return 0;
    if (x == null) return 1;
    if (y == null) return -1;
    return (typeof x === "string" ? x.localeCompare(y) : x - y) * sign;
  });
}

// ---- Overview -----------------------------------------------------------------

function matchedPerf() {
  return INDEX.performance.filter((p) => p.matched);
}

function renderHeader() {
  const s = INDEX.stats;
  const parts = [
    `[ snapshot <b>${esc(INDEX.generated)}</b> ]`,
    `[ <b>${s.accepted}/${s.properties}</b> specs accepted ]`,
    `[ <b>${Object.keys(INDEX.apps).length}</b> servers ]`,
    `<span class="live">[ interim: proofs and measurements still running ]</span>`,
  ];
  $("#status-line").innerHTML = parts.map((p) => `<span>${p}</span>`).join("");
  $("#footer-snapshot").textContent = `Snapshot ${INDEX.generated} · Apache 2.0`;
}

function renderTiles() {
  const s = INDEX.stats;
  const apps = Object.values(INDEX.apps);
  const scope = apps.reduce((n, a) => n + (a.scope_lines || 0), 0);
  const m = matchedPerf().map((p) => p.ratio);
  const med = median(m);
  const proofs = INDEX.tasks.filter((t) => t.status === "accepted" && t.proof_loc != null).map((t) => t.proof_loc);
  const tiles = [
    [`${s.accepted}<small>/${s.properties}</small>`, "specs verified", `independently re-checked · ${pctText(s.accepted, s.properties)}`, [s.accepted, s.properties]],
    [kLines(s.upstream_reached), "upstream lines reached", `${pctText(s.upstream_reached, s.upstream_selected)} of the code selected specs are about; ${pctText(s.upstream_reached, scope, 2)} of the ${kLines(scope)}-line module scope`, [s.upstream_reached, s.upstream_selected]],
    [med == null ? "–" : ratioText(med), "median runtime ratio", `kernel ÷ upstream over ${m.length} matched workloads${m.length ? `, ${ratioText(Math.min(...m))}–${ratioText(Math.max(...m))}` : ""}`],
    [kLines(s.proof_loc), "lines of Lean proof", `for ${fmt(s.accepted)} specs · median ${fmt(median(proofs))} per spec · ${fmt(s.rust_loc)} lines of ported Rust`],
  ];
  $("#tiles").innerHTML = tiles.map(([v, l, sub, frac]) =>
    `<div class="tile"><span class="v">${v}</span><span class="l">${l}</span>${frac ? bar(...frac) : ""}<span class="s">${sub}</span></div>`).join("");
}

function appRows() {
  return Object.entries(INDEX.apps).map(([app, a]) => ({ app, ...a }));
}

function renderApps() {
  const rows = applySort("apps-table", appRows(), {
    app: (r) => r.app,
    specs: (r) => r.accepted / r.specs,
    reach: (r) => (r.upstream_selected ? r.upstream_reached / r.upstream_selected : 0),
    ported: (r) => (r.scope_lines ? r.ported_span_lines / r.scope_lines : null),
  });
  $("#apps-table tbody").innerHTML = rows.map((a) => {
    const gate = INDEX.gates[a.app] || {};
    const eq = INDEX.equivalence[a.app];
    const ported = a.scope_lines
      ? `${pctText(a.ported_span_lines, a.scope_lines, 1)}<span class="sub">${kLines(a.ported_span_lines)} / ${kLines(a.scope_lines)}</span>`
      : "–";
    return `<tr><td>${esc(a.app)}<span class="sub"><a href="https://github.com/${esc(a.repo)}/tree/${esc(a.commit)}" target="_blank" rel="noreferrer">${esc(a.repo)} @ ${esc(a.commit)}</a></span></td>
      <td>${barRow(a.accepted, a.specs)}</td>
      <td>${barRow(a.upstream_reached, a.upstream_selected, "alt")}</td>
      <td class="num">${ported}</td>
      <td class="c">${passMark(gate.extract, "extract --check")}</td>
      <td class="c">${passMark(eq, "differential tests")}</td>
      <td class="c">${passMark(gate.check, "h5i app check")}</td></tr>`;
  }).join("");
}

// ---- Performance chart --------------------------------------------------------

const SVGNS = "http://www.w3.org/2000/svg";
const TICKS = [0.001, 0.01, 0.1, 0.25, 0.5, 1, 2, 4, 10, 100];

function renderPerf() {
  const onlyMatched = $("#p-scope").value === "matched";
  const rows = INDEX.performance.filter((p) => !onlyMatched || p.matched);
  const fig = $("#perf-chart");
  if (!rows.length) {
    fig.innerHTML = `<p class="empty">No measurement yet.</p>`;
    return;
  }
  const ratios = rows.map((r) => r.ratio);
  let lo = Math.min(0.5, ...ratios) / 1.25;
  let hi = Math.max(2, ...ratios) * 1.25;
  const ticks = TICKS.filter((t) => t >= lo && t <= hi);
  const W = 920, left = 230, right = 30, rowH = 24, groupGap = 22, top = 24;
  const x = (v) => left + ((Math.log(v) - Math.log(lo)) / (Math.log(hi) - Math.log(lo))) * (W - left - right);
  let y = top;
  let body = "";
  let app = null;
  rows.forEach((r, i) => {
    if (r.app !== app) {
      if (app !== null) y += groupGap - rowH / 2;
      app = r.app;
      body += `<text class="app-lbl" x="8" y="${y + 4}">${esc(app)}</text>`;
      y += rowH * 0.85;
    }
    const cx = x(r.ratio);
    const x1 = x(1);
    body += `<line class="stem" x1="${Math.min(cx, x1)}" x2="${Math.max(cx, x1)}" y1="${y}" y2="${y}"/>`;
    body += `<text class="bench-lbl" x="18" y="${y + 4}">${esc(r.benchmark.length > 28 ? r.benchmark.slice(0, 27) + "…" : r.benchmark)}</text>`;
    body += `<circle class="hit" data-i="${i}" cx="${cx}" cy="${y}" r="12"/>`;
    body += `<circle class="dot${r.matched ? "" : " hollow"}" cx="${cx}" cy="${y}" r="5"/>`;
    body += `<text class="lbl" x="${cx + (r.ratio >= 1 ? 10 : -10)}" y="${y + 4}" text-anchor="${r.ratio >= 1 ? "start" : "end"}">${ratioText(r.ratio)}</text>`;
    y += rowH;
  });
  const H = y + 26;
  const grid = ticks.map((t) => `<line x1="${x(t)}" x2="${x(t)}" y1="${top - 12}" y2="${H - 24}"/>`).join("");
  const axis = ticks.map((t) => `<text x="${x(t)}" y="${H - 8}" text-anchor="middle">${t}×</text>`).join("");
  const zone = `<rect class="zone" x="${x(lo)}" y="${top - 12}" width="${x(1) - x(lo)}" height="${H - top - 12}"/>`;
  const words = `<text class="lbl" x="${x(1) - 8}" y="${top - 2}" text-anchor="end">kernel faster</text><text class="lbl" x="${x(1) + 8}" y="${top - 2}">kernel slower</text>`;
  fig.innerHTML = `<svg viewBox="0 0 ${W} ${H}" role="img" aria-label="Kernel time over upstream time per benchmark, log scale">
    ${zone}<g class="grid">${grid}</g><line class="ref" x1="${x(1)}" x2="${x(1)}" y1="${top - 12}" y2="${H - 24}"/>${words}
    <g class="axis">${axis}</g>${body}</svg>`;
  const svg = fig.querySelector("svg");
  svg.addEventListener("mousemove", (e) => {
    const hit = e.target.closest(".hit");
    if (!hit) return hideTip();
    const r = rows[+hit.dataset.i];
    showTip(e, `<b>${esc(r.app)} · ${esc(r.benchmark)}</b>${ratioText(r.ratio)} kernel ÷ upstream<br>
      <span class="r">${r.upstream_ns != null ? `${r.upstream_ns.toFixed(1)} → ${r.kernel_ns.toFixed(1)} ns` : ""} · ${r.matched ? "matched boundary" : "unequal boundary"}</span><br><span class="r">${esc(r.scope)}</span>`);
  });
  svg.addEventListener("mouseleave", hideTip);
  const unequal = INDEX.performance.filter((p) => !p.matched).length;
  $("#perf-caption").textContent = onlyMatched
    ? `${rows.length} matched workloads in ${new Set(rows.map((r) => r.app)).size} applications. ${unequal} more measurements include unequal work on one side; choose "All measurements" to see them. Pilot runs on one host (${INDEX.performance[0]?.measured ?? ""}).`
    : `Hollow marks are not kernel-only comparisons: read their boundary in the tooltip or the table.`;
  $("#perf-table tbody").innerHTML = rows.map((r) => `<tr><td>${esc(r.app)}</td><td>${esc(r.benchmark)}</td>
    <td class="num">${r.upstream_ns != null ? r.upstream_ns.toFixed(1) : "–"}</td><td class="num">${r.kernel_ns != null ? r.kernel_ns.toFixed(1) : "–"}</td>
    <td class="num">${ratioText(r.ratio)}</td><td class="scope">${r.matched ? "matched" : "unequal"}: ${esc(r.scope)}</td></tr>`).join("");
}

// ---- Effort -----------------------------------------------------------------

function renderEffort() {
  const rows = applySort("effort-table", appRows().map((a) => {
    const proofs = INDEX.tasks.filter((t) => t.app === a.app && t.status === "accepted" && t.proof_loc != null).map((t) => t.proof_loc);
    return { ...a, per: median(proofs), ratio: a.lean_loc / a.rust_loc };
  }), {
    app: (r) => r.app, rust: (r) => r.rust_loc, lean: (r) => r.lean_loc, ratio: (r) => r.ratio,
    spec: (r) => r.spec_loc, proof: (r) => r.proof_loc, per: (r) => r.per,
  });
  $("#effort-table tbody").innerHTML = rows.map((a) => `<tr><td>${esc(a.app)}</td>
    <td class="num">${fmt(a.rust_loc)}</td><td class="num">${fmt(a.lean_loc)}</td><td class="num">${a.ratio.toFixed(1)}×</td>
    <td class="num">${fmt(a.spec_loc)}</td><td class="num">${fmt(a.proof_loc)} <span class="of">· ${a.accepted} specs</span></td>
    <td class="num">${a.per == null ? "–" : fmt(a.per)}</td></tr>`).join("");
  renderEffortChart();
}

function renderEffortChart() {
  const pts = INDEX.tasks.filter((t) => t.status === "accepted" && t.proof_loc > 0 && t.loc > 0);
  const fig = $("#effort-chart");
  if (!pts.length) return (fig.innerHTML = `<p class="empty">No accepted spec yet.</p>`);
  const W = 920, H = 340, l = 60, r = 24, t = 16, b = 40;
  const xs = pts.map((p) => p.loc), ys = pts.map((p) => p.proof_loc);
  const dom = (v) => [Math.pow(10, Math.floor(Math.log10(Math.min(...v)))), Math.pow(10, Math.ceil(Math.log10(Math.max(...v))))];
  const [x0, x1] = dom(xs), [y0, y1] = dom(ys);
  const sx = (v) => l + ((Math.log10(v) - Math.log10(x0)) / (Math.log10(x1) - Math.log10(x0))) * (W - l - r);
  const sy = (v) => H - b - ((Math.log10(v) - Math.log10(y0)) / (Math.log10(y1) - Math.log10(y0))) * (H - t - b);
  const dec = (a, z) => { const o = []; for (let v = a; v <= z; v *= 10) o.push(v); return o; };
  const gx = dec(x0, x1), gy = dec(y0, y1);
  let s = `<g class="grid">${gx.map((v) => `<line x1="${sx(v)}" x2="${sx(v)}" y1="${t}" y2="${H - b}"/>`).join("")}${gy.map((v) => `<line x1="${l}" x2="${W - r}" y1="${sy(v)}" y2="${sy(v)}"/>`).join("")}</g>`;
  s += `<g class="axis">${gx.map((v) => `<text x="${sx(v)}" y="${H - b + 16}" text-anchor="middle">${fmt(v)}</text>`).join("")}${gy.map((v) => `<text x="${l - 8}" y="${sy(v) + 4}" text-anchor="end">${fmt(v)}</text>`).join("")}</g>`;
  s += `<text class="lbl" x="${(l + W - r) / 2}" y="${H - 6}" text-anchor="middle">upstream lines the spec is about</text>`;
  s += `<text class="lbl" transform="translate(14 ${(t + H - b) / 2}) rotate(-90)" text-anchor="middle">proof lines</text>`;
  pts.forEach((p, i) => {
    s += `<circle class="hit" data-i="${i}" cx="${sx(p.loc)}" cy="${sy(p.proof_loc)}" r="10"/><circle class="dot" cx="${sx(p.loc)}" cy="${sy(p.proof_loc)}" r="4.5"/>`;
  });
  fig.innerHTML = `<svg viewBox="0 0 ${W} ${H}" role="img" aria-label="Proof lines against upstream lines per accepted spec">${s}</svg>`;
  const svg = fig.querySelector("svg");
  svg.addEventListener("mousemove", (e) => {
    const hit = e.target.closest(".hit");
    if (!hit) return hideTip();
    const p = pts[+hit.dataset.i];
    showTip(e, `<b>${esc(p.id)}</b>${fmt(p.proof_loc)} proof lines · ${fmt(p.loc)} upstream lines<br><span class="r">${esc(p.property)}</span>`);
  });
  svg.addEventListener("click", (e) => {
    const hit = e.target.closest(".hit");
    if (hit) openTask(pts[+hit.dataset.i].id);
  });
  svg.addEventListener("mouseleave", hideTip);
}

// ---- Specs table --------------------------------------------------------------

function filteredTasks() {
  const app = $("#f-app").value;
  const st = $("#f-status").value;
  const q = $("#f-q").value.trim().toLowerCase();
  return INDEX.tasks.filter((t) => {
    if (app && t.app !== app) return false;
    if (st === "corrected" && !t.correction) return false;
    if (st && st !== "corrected" && t.status !== st) return false;
    if (q && !`${t.id} ${t.property} ${t.theorem}`.toLowerCase().includes(q)) return false;
    return true;
  });
}

const STATUS_ORDER = { accepted: 2, stale: 1, open: 0 };
function renderMatrix() {
  const all = filteredTasks();
  const sorted = SORT.matrix;
  const tasks = applySort("matrix", all, {
    id: (t) => t.id, status: (t) => STATUS_ORDER[t.status], loc: (t) => t.loc, proof: (t) => t.proof_loc, prover: (t) => t.prover,
  });
  let html = "";
  let app = null;
  for (const t of tasks) {
    if (!sorted && t.app !== app) {
      app = t.app;
      const a = INDEX.apps[app];
      html += `<tr class="group"><td colspan="6">${esc(app)} · ${esc(a.repo)} · ${a.accepted}/${a.specs}</td></tr>`;
    }
    html += `<tr class="task" tabindex="0" data-id="${esc(t.id)}"><td class="t-name">${esc(t.id)}</td><td class="t-prop">${esc(t.property)}</td>
      <td>${statusChip(t)}</td><td class="num">${t.loc ? fmt(t.loc) : "–"}</td><td class="num">${t.proof_loc ?? "–"}</td><td class="prover">${esc(proverLabel(t.prover))}</td></tr>`;
  }
  if (!tasks.length) html = `<tr><td class="count" colspan="6">No spec matches the filters.</td></tr>`;
  $("#matrix tbody").innerHTML = html;
  $("#matrix-count").textContent = `${tasks.length} of ${INDEX.tasks.length} specs · ${tasks.filter((t) => t.status === "accepted").length} accepted`;
}

// ---- Tooltip ----------------------------------------------------------------

function showTip(ev, html) {
  const tip = $("#tooltip");
  tip.innerHTML = html;
  tip.hidden = false;
  const x = Math.min(ev.clientX + 14, window.innerWidth - tip.offsetWidth - 8);
  const y = ev.clientY + 16 + tip.offsetHeight > window.innerHeight ? ev.clientY - tip.offsetHeight - 12 : ev.clientY + 16;
  tip.style.left = `${x}px`;
  tip.style.top = `${y}px`;
}
function hideTip() {
  $("#tooltip").hidden = true;
}

// ---- Spec drawer ------------------------------------------------------------

const TABS = [
  ["statement", "Statement"],
  ["rust", "Rust"],
  ["equivalence", "Equivalence"],
  ["lean", "Lean"],
  ["proof", "Proof"],
];

async function loadTask(id) {
  if (!cache.has(id)) cache.set(id, fetch(`${DATA}/tasks/${encodeURIComponent(id)}.json`).then((r) => r.json()));
  return cache.get(id);
}

const ticks = (s) => esc(s).replace(/`([^`]+)`/g, "<code>$1</code>");
function correctionNote(c) {
  return c ? `<div class="correction"><strong>Statement corrected · ${esc(c.date)}</strong>${ticks(c.change)}. ${ticks(c.reason)}</div>` : "";
}

function tabStatement(d) {
  let h = correctionNote(d.verification.correction);
  h += `<h3>Theorem</h3>`;
  h += codeBlock({ title: d.theorem.split(".").pop(), sub: "Properties.lean", code: d.statement, lang: "lean" });
  h += d.target.loc
    ? `<p class="note">The property is about ${fmt(d.target.loc)} lines of upstream Rust: ${d.target.fns.map((f) => `<code>${esc(f)}</code>`).join(", ")} and what they call.</p>`
    : `<p class="note">The property is about code that exists only in the port, so no upstream lines are counted.</p>`;
  h += `<h3>Spec definitions it uses</h3>`;
  h += d.spec.length
    ? d.spec.map((s) => codeBlock({ title: s.name, code: s.code, lang: "lean" })).join("")
    : `<p class="empty">The statement refers only to definitions of the ported code.</p>`;
  return h;
}

function tabRust(d) {
  if (!d.kernel.length) return `<p class="empty">No ported function is referenced directly by this statement.</p>`;
  let h = `<p class="note">Each ported function next to the upstream function of the same name at the pinned commit. Helpers that exist only in the port replace iterator chains and library calls that Aeneas does not support.</p>`;
  for (const k of d.kernel) {
    const up = d.upstream.find((u) => u.fn === k.fn);
    h += `<p class="fn-title">${esc(k.fn)}</p><div class="pair">`;
    h += up
      ? codeBlock({ title: "upstream", sub: `${up.file}:${up.line}`, url: up.url, code: up.code, lang: "rust" })
      : `<div class="missing">No upstream function of this name: a helper introduced by the port.</div>`;
    h += codeBlock({ title: "h5i-app port", sub: `${k.file}:${k.line}`, url: k.url, code: k.code, lang: "rust" });
    h += `</div>`;
  }
  return h;
}

function tabEquivalence(d) {
  const app = INDEX.apps[d.app];
  const eq = INDEX.equivalence[d.app];
  let h = eq
    ? `<p class="note">Latest differential run for ${esc(d.app)}: ${eq.passed ? "<span class=\"mark good\">✓</span> passed" : "<span class=\"mark bad\">✗</span> failed"} on ${esc(eq.when)} in ${eq.seconds} s. ${esc(eq.evidence || "")}</p>`
    : "";
  h += `<p class="note">The differential test runs upstream and the h5i-app port on the same generated inputs and compares results; a mutated port must fail it. These are the tests that call the functions above.</p>`;
  h += d.difftest.length
    ? d.difftest.map((t) => codeBlock({ title: t.fn, sub: `${t.file}:${t.line}`, url: t.url, code: t.code, lang: "rust" })).join("")
    : `<p class="empty">No test names these functions directly; they are covered through their callers.</p>`;
  h += `<h3>Deviations from upstream</h3><p class="note">Upstream: <a href="https://github.com/${esc(app.repo)}/tree/${esc(app.commit)}" target="_blank" rel="noreferrer">${esc(app.repo)} @ ${esc(app.commit)}</a> · <a href="${esc(app.port)}" target="_blank" rel="noreferrer">port</a></p>`;
  h += `<details class="dev"><summary>Show the port's deviations file</summary><div class="dev-body">${app.deviations}</div></details>`;
  return h;
}

function tabLean(d) {
  if (!d.lean.length) return `<p class="empty">No generated definition is referenced by this statement.</p>`;
  return `<p class="note">Extracted from the h5i-app port by Aeneas. The bracket in each comment names the Rust item it came from.</p>` +
    d.lean.map((l) => codeBlock({ title: l.name, sub: l.rust, code: l.code, lang: "lean" })).join("");
}

function tabProof(d) {
  const v = d.verification;
  let h = correctionNote(v.correction);
  if (v.status === "open") {
    h += `<p class="empty">No accepted proof yet.</p>`;
  } else {
    h += `<dl class="kv"><dt>status</dt><dd>${statusChip({ status: v.status })}</dd>
      <dt>prover</dt><dd>${esc(proverLabel(v.prover))}</dd>
      <dt>re-checked</dt><dd>${esc(v.checked_at)} UTC${v.check_s ? ` · ${v.check_s} s` : ""}</dd>
      <dt>axioms</dt><dd>${(v.axioms || []).map((a) => `<code>${esc(a)}</code>`).join(", ")}</dd>
      <dt>proof lines</dt><dd>${fmt(v.proof_loc)}</dd></dl>`;
    if (INDEX.proofs && v.code) h += codeBlock({ title: "Solution.lean", sub: "accepted proof", code: v.code, lang: "lean" });
  }
  if (d.runs.length) {
    const rows = [...d.runs].sort((a, b) => b.passed - a.passed || a.minutes - b.minutes).map((r) =>
      `<tr><td>${esc(r.model)}</td><td>${r.passed ? `<span class="mark good">✓</span> built` : `<span class="mark bad">✗</span> ${esc(r.reason || "")}`}</td><td class="num">${r.minutes}</td><td class="num">${r.proof_loc ?? "–"}</td></tr>`).join("");
    h += `<h3>Agent attempts</h3><div class="table-wrap"><table class="runs"><thead><tr><th>Model</th><th>Outcome</th><th class="num">Minutes</th><th class="num">Proof lines</th></tr></thead><tbody>${rows}</tbody></table></div>`;
  }
  return h;
}

const RENDER = { statement: tabStatement, rust: tabRust, equivalence: tabEquivalence, lean: tabLean, proof: tabProof };
let current = null;
let lastFocus = null;

function selectTab(name) {
  for (const b of $("#d-tabs").children) b.setAttribute("aria-selected", String(b.dataset.tab === name));
  $("#d-body").innerHTML = RENDER[name](current);
  $("#d-body").scrollTop = 0;
}

async function openTask(id, tab) {
  const t = INDEX.tasks.find((x) => x.id === id);
  if (!t) return;
  lastFocus = document.activeElement;
  const drawer = $("#drawer");
  drawer.hidden = false;
  document.body.style.overflow = "hidden";
  $("#d-app").textContent = `${t.app} · ${INDEX.apps[t.app].repo}`;
  $("#d-title").textContent = t.id;
  $("#d-property").textContent = t.property;
  $("#d-body").innerHTML = `<p class="empty">Loading…</p>`;
  current = await loadTask(id);
  $("#d-tabs").innerHTML = TABS.map(([k, label]) =>
    `<button role="tab" type="button" data-tab="${k}">${label}${k === "proof" && t.status === "accepted" ? " ✓" : ""}</button>`).join("");
  selectTab(tab || "statement");
  $(".close", drawer).focus();
  if (location.hash.slice(1) !== id) history.replaceState(null, "", `#${id}`);
}

function closeTask() {
  $("#drawer").hidden = true;
  document.body.style.overflow = "";
  history.replaceState(null, "", location.pathname + location.search);
  if (lastFocus) lastFocus.focus();
}

// ---- Wiring -------------------------------------------------------------------

async function main() {
  setTheme(currentTheme());
  for (const b of document.querySelectorAll("[data-theme-set]")) b.addEventListener("click", () => setTheme(b.dataset.themeSet));

  INDEX = await fetch(`${DATA}/index.json`).then((r) => r.json());
  renderHeader();
  renderTiles();
  sortable("apps-table", renderApps);
  renderApps();
  $("#p-scope").addEventListener("input", renderPerf);
  renderPerf();
  sortable("effort-table", renderEffort);
  renderEffort();

  const sel = $("#f-app");
  for (const app of Object.keys(INDEX.apps)) sel.insertAdjacentHTML("beforeend", `<option value="${esc(app)}">${esc(app)}</option>`);
  sortable("matrix", renderMatrix);
  renderMatrix();
  for (const id of ["#f-app", "#f-status", "#f-q"]) $(id).addEventListener("input", renderMatrix);

  const tbody = $("#matrix tbody");
  tbody.addEventListener("click", (e) => {
    const tr = e.target.closest("tr.task");
    if (tr) openTask(tr.dataset.id);
  });
  tbody.addEventListener("keydown", (e) => {
    const tr = e.target.closest("tr.task");
    if (tr && (e.key === "Enter" || e.key === " ")) {
      e.preventDefault();
      openTask(tr.dataset.id);
    }
  });
  $("#d-tabs").addEventListener("click", (e) => {
    const b = e.target.closest("button[data-tab]");
    if (b) selectTab(b.dataset.tab);
  });
  $("#drawer").addEventListener("click", (e) => {
    if (e.target.closest("[data-close]")) closeTask();
  });
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && !$("#drawer").hidden) closeTask();
  });
  const fromHash = () => {
    const id = decodeURIComponent(location.hash.slice(1));
    if (id && INDEX.tasks.some((t) => t.id === id)) openTask(id);
  };
  window.addEventListener("hashchange", fromHash);
  fromHash();
}

main().catch((err) => {
  $("#tiles").innerHTML = `<p class="empty">Could not load the results (${esc(err.message)}). The page must be served over HTTP.</p>`;
});
