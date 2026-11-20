"use strict";

const $ = (sel, root = document) => root.querySelector(sel);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const fmt = (n) => Number(n).toLocaleString("en");
const pct = (a, b) => (b ? (100 * a) / b : 0);
let D = null;
const cache = new Map();

function setTheme(t) {
  document.documentElement.dataset.theme = t;
  try { localStorage.setItem("theme", t); } catch (e) { /* private mode */ }
  for (const b of document.querySelectorAll("[data-theme-set]")) b.setAttribute("aria-pressed", String(b.dataset.themeSet === t));
}

// ---- Code highlighting (same rules as /prove) ---------------------------------

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
  const re = TOKEN[lang], kw = KW[lang];
  let out = "", last = 0;
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
function codeBlock({ title, sub, code, lang }) {
  return `<div class="code"><div class="code-head"><strong>${esc(title)}</strong>${sub ? `<span>${esc(sub)}</span>` : ""}</div>
    <pre><code>${highlight(code || "", lang)}</code></pre></div>`;
}

// ---- Overview -------------------------------------------------------------------

function shareBar(run) {
  if (!run) return `<span class="chip">pending</span>`;
  const p = pct(run.identical, run.scenarios);
  return `<div class="bar-row"><div class="bar-track"><div class="bar-fill" style="width:${p.toFixed(1)}%"></div></div>` +
    `<span class="bar-label"><span class="pct">${p.toFixed(1)}%</span> <span class="of">${fmt(run.identical)}/${fmt(run.scenarios)}</span></span></div>`;
}

function tiles() {
  const ps = D.projects;
  const isas = new Set(ps.map((p) => p.isa));
  const props = ps.reduce((s, p) => s + p.theorems, 0);
  const runs = ps.flatMap((p) => [p.mixed, p.normal].filter(Boolean));
  const scen = runs.reduce((s, r) => s + r.scenarios, 0);
  const unex = ps.reduce((s, p) => s + p.mixed.unexplained + (p.normal ? p.normal.other : 0), 0);
  const tile = (v, l, s) => `<div class="tile"><span class="v">${v}</span><span class="l">${esc(l)}</span>${s ? `<span class="s">${esc(s)}</span>` : ""}</div>`;
  $("#tiles").innerHTML =
    tile(ps.length, "firmwares ported", `${D.not_ported.length} more audited, not ported`) +
    tile(fmt(props), "properties proved", "gated by h5i app check") +
    tile(isas.size, "instruction sets", [...isas].join(", ")) +
    tile(fmt(scen), "scenarios run in Renode", `${unex} unexplained`);
}

let sortKey = "name", sortDir = 1;
function overview() {
  const key = {
    name: (p) => p.name.toLowerCase(), chip: (p) => p.chip, theorems: (p) => p.theorems,
    normal: (p) => (p.normal ? pct(p.normal.identical, p.normal.scenarios) : -1),
    mixed: (p) => pct(p.mixed.identical, p.mixed.scenarios),
  }[sortKey];
  const rows = [...D.projects].sort((a, b) => (key(a) < key(b) ? -1 : key(a) > key(b) ? 1 : 0) * sortDir);
  $("#overview-table tbody").innerHTML = rows.map((p) =>
    `<tr><th scope="row"><a href="${esc(p.url)}" target="_blank" rel="noreferrer">${esc(p.name)}</a> <span class="dim">@${esc(p.pin)}</span></th>` +
    `<td>${esc(p.chip)} <span class="dim">${esc(p.isa)}</span></td><td>${esc(p.interface)}</td>` +
    `<td class="num"><button type="button" class="spec-link" data-app="${esc(p.slug)}">${fmt(p.theorems)}</button></td><td>${shareBar(p.normal)}</td><td>${shareBar(p.mixed)}</td></tr>`).join("");
  for (const th of document.querySelectorAll("#overview-table th[data-sort]")) {
    th.setAttribute("aria-sort", th.dataset.sort === sortKey ? (sortDir > 0 ? "ascending" : "descending") : "none");
  }
}

// ---- Equivalence ------------------------------------------------------------------

function detail() {
  const cells = (r, a, b) => r
    ? `<td class="num">${fmt(r.scenarios)}</td><td class="num">${fmt(r.identical)}</td><td class="num">${fmt(r[a])}</td>` +
      `<td class="num">${r[b] ? `<span class="chip warn">${fmt(r[b])}</span>` : "0"}</td>`
    : `<td colspan="4" class="pending"><span class="chip">pending</span></td>`;
  $("#detail-table tbody").innerHTML = D.projects.map((p) =>
    `<tr><th scope="row" rowspan="2">${esc(p.name)}</th><td>Normal input</td>${cells(p.normal, "cosmetic", "other")}</tr>` +
    `<tr><td>Mixed input</td>${cells(p.mixed, "explained", "unexplained")}</tr>`).join("");
  $("#normal-notes").innerHTML = D.projects.filter((p) => p.normal_note)
    .map((p) => `<li><strong>${esc(p.name)}</strong> (normal input): ${esc(p.normal_note)}</li>`).join("");
}

// ---- Properties -------------------------------------------------------------------

function propRows() {
  const app = $("#f-app").value;
  const ty = $("#f-type").value;
  const q = $("#f-q").value.trim().toLowerCase();
  const out = [];
  for (const p of D.projects) {
    if (app && p.slug !== app) continue;
    for (const t of p.theorem_list || []) {
      if (ty && t.type !== ty) continue;
      if (q && !`${p.name} ${t.name} ${t.doc} ${t.type}`.toLowerCase().includes(q)) continue;
      out.push({ p, t });
    }
  }
  return out;
}

function renderMatrix() {
  const rows = propRows();
  let html = "", cur = null;
  for (const { p, t } of rows) {
    if (p !== cur) {
      cur = p;
      html += `<tr class="group"><td colspan="4">${esc(p.name)} · ${esc(p.chip)} · ${esc(p.interface)} · ${fmt(p.theorems)} properties</td></tr>`;
    }
    html += `<tr class="task" tabindex="0" data-app="${esc(p.slug)}" data-thm="${esc(t.name)}"><td class="t-name"><button type="button" class="spec-link">${esc(t.name)}</button></td>` +
      `<td><span class="chip type">${esc(t.type)}</span></td><td class="t-prop">${esc(t.doc || "")}</td><td><span class="chip good">✓ verified</span></td></tr>`;
  }
  if (!rows.length) html = `<tr><td class="count" colspan="4">No property matches the filters.</td></tr>`;
  $("#matrix tbody").innerHTML = html;
  const total = D.projects.reduce((s, p) => s + (p.theorem_list || []).length, 0);
  $("#matrix-count").textContent = `${rows.length} of ${total} properties`;
}

// ---- Property drawer ------------------------------------------------------------

const TABS = [["statement", "Statement"], ["rust", "Rust comparison"], ["lean", "Extracted Lean"], ["proof", "Proof"]];

async function loadProject(slug) {
  if (!cache.has(slug)) cache.set(slug, fetch(`./projects/${encodeURIComponent(slug)}.json`).then((r) => {
    if (!r.ok) throw new Error(`Could not load ${slug} (${r.status})`);
    return r.json();
  }).catch((e) => { cache.delete(slug); throw e; }));
  return cache.get(slug);
}

// Functions first (they carry the logic), then types and constants.
const declOrder = (P, names) => [...names].sort((a, b) => {
  const fa = /\bfn\s/.test(P.decls[a].kernel_code || "") ? 0 : 1, fb = /\bfn\s/.test(P.decls[b].kernel_code || "") ? 0 : 1;
  return fa - fb;
});

function tabStatement(c) {
  const { P, t } = c;
  let h = codeBlock({ title: t.name, sub: t.file, code: t.statement, lang: "lean" });
  if (t.spec.length) {
    h += `<h3>Specification definitions</h3>` + t.spec.map((s) => codeBlock({ title: s, sub: P.specs[s].file, code: P.specs[s].code, lang: "lean" })).join("");
  }
  return h + `<p class="note">Reaches ${t.deps.length} extracted declaration(s). Open Rust comparison for the kernel code beside the upstream code it ports, or Proof for the full proof.</p>`;
}

function tabRust(c) {
  const { P, t } = c;
  let h = `<p class="note">Left: upstream at <code>${esc(P.pin)}</code>, unmodified. Right: the h5i-app kernel item the theorem reaches, as extracted. The mapping is recorded by hand per port (<code>upstream-map.toml</code>); it does not by itself establish equivalence — that is what the Renode runs test.</p>`;
  if (!P.mapped) h += `<p class="note"><span class="chip warn">upstream mapping not recorded yet for this firmware</span></p>`;
  const names = declOrder(P, t.deps);
  const first = names.find((n) => P.decls[n].upstream.length) || names[0];
  for (const n of names) {
    const d = P.decls[n];
    const ups = d.upstream;
    h += `<details class="source-item"${n === first ? " open" : ""}><summary>${esc(d.rust_path)} · ${ups.length ? `${ups.length} upstream range(s)` : "no upstream mapping"}</summary>`;
    if (d.upstream_note) h += `<p class="note">${esc(d.upstream_note)}</p>`;
    h += `<div class="pair">`;
    h += ups.length ? `<div>${ups.map((u) => codeBlock({ title: "Upstream Rust", sub: `${u.file}:${u.line}`, code: u.code, lang: "rust" })).join("")}</div>`
      : `<div class="missing">${P.mapped ? "Port-only item: no upstream counterpart." : "Not mapped yet."}</div>`;
    h += codeBlock({ title: "h5i-app kernel Rust", sub: `${d.kernel_file}:${d.kernel_line}`, code: d.kernel_code || "(source not found)", lang: "rust" }) + `</div></details>`;
  }
  return h + (names.length ? "" : `<p class="empty">The statement reaches no extracted declaration.</p>`);
}

function tabLean(c) {
  const { P, t } = c;
  return `<p class="note">Aeneas extraction of the kernel items this property's statement reaches, with their dependencies.</p>` +
    declOrder(P, t.deps).map((n) => `<details class="source-item"><summary>${esc(n)}</summary>${codeBlock({ title: n, sub: P.decls[n].rust_path, code: P.decls[n].lean, lang: "lean" })}</details>`).join("");
}

function tabProof(c) {
  const { P, t } = c;
  return `<dl class="kv"><dt>status</dt><dd><span class="chip good">✓ verified</span> gated by <code>h5i app check</code></dd>
    <dt>upstream revision</dt><dd><code>${esc(P.pin)}</code></dd><dt>file</dt><dd><code>proofs/${esc(t.file)}</code></dd></dl>` +
    codeBlock({ title: t.name, sub: t.file, code: t.proof, lang: "lean" });
}

const RENDER = { statement: tabStatement, rust: tabRust, lean: tabLean, proof: tabProof };
let current = null, lastFocus = null, req = 0;

function selectTab(name) {
  if (!current) return;
  for (const b of $("#d-tabs").children) b.setAttribute("aria-selected", String(b.dataset.tab === name));
  $("#d-body").innerHTML = RENDER[name](current);
  $("#d-body").scrollTop = 0;
}

async function openProp(slug, thm, tab) {
  const p = D.projects.find((x) => x.slug === slug);
  const t0 = p && (p.theorem_list || []).find((x) => x.name === thm);
  if (!t0) return;
  const r = ++req;
  lastFocus = document.activeElement;
  $("#drawer").hidden = false;
  document.body.style.overflow = "hidden";
  $("#d-app").textContent = `${p.name} · ${p.chip} · ${t0.type}`;
  $("#d-title").textContent = thm;
  $("#d-property").textContent = t0.doc || "";
  $("#d-body").innerHTML = `<p class="empty">Loading…</p>`;
  $("#d-tabs").innerHTML = "";
  current = null;
  $("#drawer .close").focus();
  try {
    const P = await loadProject(slug);
    if (r !== req) return;
    const t = P.theorems.find((x) => x.name === thm);
    current = { P, t };
    $("#d-tabs").innerHTML = TABS.map(([k, label]) => `<button role="tab" type="button" data-tab="${k}">${label}${k === "proof" ? " ✓" : ""}</button>`).join("");
    selectTab(tab || "statement");
    history.replaceState(null, "", `#${encodeURIComponent(slug)}/${encodeURIComponent(thm)}`);
  } catch (e) {
    if (r === req) $("#d-body").innerHTML = `<p class="empty">${esc(e.message)}</p>`;
  }
}

function closeProp() {
  ++req;
  current = null;
  $("#drawer").hidden = true;
  document.body.style.overflow = "";
  history.replaceState(null, "", location.pathname + location.search);
  if (lastFocus) lastFocus.focus();
}

// ---- Wiring -----------------------------------------------------------------------

async function main() {
  D = await fetch("./data.json").then((r) => r.json());
  tiles();
  overview();
  detail();
  const types = [...new Set(D.projects.flatMap((p) => (p.theorem_list || []).map((t) => t.type)))].sort();
  $("#f-type").innerHTML += types.map((t) => `<option value="${esc(t)}">${esc(t)}</option>`).join("");
  $("#f-app").innerHTML += D.projects.map((p) => `<option value="${esc(p.slug)}">${esc(p.name)}</option>`).join("");
  renderMatrix();
  $("#not-ported").textContent = `Audited and not ported (no input-driven logic to verify): ${D.not_ported.join(", ")}. Data as of ${D.updated}.`;

  for (const th of document.querySelectorAll("#overview-table th[data-sort]")) {
    th.addEventListener("click", () => {
      sortDir = sortKey === th.dataset.sort ? -sortDir : 1;
      sortKey = th.dataset.sort;
      overview();
    });
  }
  $("#overview-table").addEventListener("click", (e) => {
    const b = e.target.closest("button[data-app]");
    if (!b) return;
    $("#f-app").value = b.dataset.app;
    renderMatrix();
    $("#properties").scrollIntoView({ behavior: "smooth" });
  });
  $("#f-app").addEventListener("change", renderMatrix);
  $("#f-type").addEventListener("change", renderMatrix);
  $("#f-q").addEventListener("input", renderMatrix);
  const open = (e) => {
    const tr = e.target.closest("tr.task");
    if (tr) openProp(tr.dataset.app, tr.dataset.thm);
  };
  $("#matrix").addEventListener("click", open);
  $("#matrix").addEventListener("keydown", (e) => { if (e.key === "Enter") open(e); });
  $("#d-tabs").addEventListener("click", (e) => { const b = e.target.closest("[data-tab]"); if (b) selectTab(b.dataset.tab); });
  for (const el of document.querySelectorAll("[data-close]")) el.addEventListener("click", closeProp);
  document.addEventListener("keydown", (e) => { if (e.key === "Escape" && !$("#drawer").hidden) closeProp(); });
  const m = decodeURIComponent(location.hash.slice(1)).split("/");
  if (m.length === 2) openProp(m[0], m[1]);
}

setTheme(document.documentElement.dataset.theme || "dark");
for (const b of document.querySelectorAll("[data-theme-set]")) b.addEventListener("click", () => setTheme(b.dataset.themeSet));
main().catch(() => { $("#tiles").innerHTML = `<p class="count">Could not load data.json.</p>`; });
