"use strict";

const $ = (sel) => document.querySelector(sel);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const fmt = (n) => Number(n).toLocaleString("en");
const pct = (a, b) => (b ? (100 * a) / b : 0);

function setTheme(t) {
  document.documentElement.dataset.theme = t;
  try { localStorage.setItem("theme", t); } catch (e) { /* private mode */ }
  for (const b of document.querySelectorAll("[data-theme-set]")) b.setAttribute("aria-pressed", String(b.dataset.themeSet === t));
}

// Share of identical scenarios as a bar; "–" when the run does not exist.
function shareBar(run) {
  if (!run) return `<span class="dim">–</span>`;
  const p = pct(run.identical, run.scenarios);
  return `<div class="bar-row"><div class="bar-track"><div class="bar-fill" style="width:${p.toFixed(1)}%"></div></div>` +
    `<span class="bar-label"><span class="pct">${p.toFixed(1)}%</span> <span class="of">${fmt(run.identical)}/${fmt(run.scenarios)}</span></span></div>`;
}

function tiles(d) {
  const ps = d.projects;
  const isas = new Set(ps.map((p) => p.isa));
  const thms = ps.reduce((s, p) => s + p.theorems, 0);
  const scen = ps.reduce((s, p) => s + p.mixed.scenarios + (p.normal ? p.normal.scenarios : 0), 0);
  const unex = ps.reduce((s, p) => s + p.mixed.unexplained + (p.normal ? p.normal.other : 0), 0);
  const tile = (v, l, s) => `<div class="tile"><span class="v">${v}</span><span class="l">${esc(l)}</span>${s ? `<span class="s">${esc(s)}</span>` : ""}</div>`;
  $("#tiles").innerHTML =
    tile(ps.length, "firmwares ported", `${d.not_ported.length} audited and not ported`) +
    tile(fmt(thms), "theorems proved", "accepted by h5i app check") +
    tile(isas.size, "instruction sets", [...isas].join(", ")) +
    tile(fmt(scen), "scenarios run in Renode", `${unex} unexplained`);
}

let sortKey = "name", sortDir = 1;
function overview(d) {
  const key = {
    name: (p) => p.name.toLowerCase(),
    chip: (p) => p.chip,
    theorems: (p) => p.theorems,
    normal: (p) => (p.normal ? pct(p.normal.identical, p.normal.scenarios) : -1),
    mixed: (p) => pct(p.mixed.identical, p.mixed.scenarios),
  }[sortKey];
  const rows = [...d.projects].sort((a, b) => (key(a) < key(b) ? -1 : key(a) > key(b) ? 1 : 0) * sortDir);
  $("#overview-table tbody").innerHTML = rows.map((p) =>
    `<tr><th scope="row"><a href="${esc(p.url)}">${esc(p.name)}</a> <span class="dim">@${esc(p.pin)}</span></th>` +
    `<td>${esc(p.chip)} <span class="dim">${esc(p.isa)}</span></td><td>${esc(p.interface)}</td>` +
    `<td class="num">${fmt(p.theorems)}</td><td>${shareBar(p.normal)}</td><td>${shareBar(p.mixed)}</td></tr>`).join("");
  for (const th of document.querySelectorAll("#overview-table th[data-sort]")) {
    th.setAttribute("aria-sort", th.dataset.sort === sortKey ? (sortDir > 0 ? "ascending" : "descending") : "none");
  }
}

function detail(d) {
  const row = (p, label, r, explained, other, first) =>
    `<tr>${first ? `<th scope="row" rowspan="2">${esc(p.name)}</th>` : ""}<td>${label}</td>` +
    (r ? `<td class="num">${fmt(r.scenarios)}</td><td class="num">${fmt(r.identical)}</td><td class="num">${fmt(explained)}</td>` +
         `<td class="num">${other ? `<span class="chip warn">${fmt(other)}</span>` : "0"}</td>`
       : `<td class="num dim">–</td><td class="num dim">–</td><td class="num dim">–</td><td class="num dim">–</td>`) + `</tr>`;
  $("#detail-table tbody").innerHTML = d.projects.map((p) =>
    row(p, "normal", p.normal, p.normal?.cosmetic, p.normal?.other, true) +
    row(p, "mixed", p.mixed, p.mixed.explained, p.mixed.unexplained, false)).join("");
}

function props(d) {
  const q = ($("#f-q").value || "").toLowerCase();
  const ps = d.projects.filter((p) => !q || p.name.toLowerCase().includes(q) || p.properties.some((s) => s.toLowerCase().includes(q)));
  $("#props").innerHTML = ps.map((p) =>
    `<article class="emb-prop"><h3>${esc(p.name)} <span class="chip">${fmt(p.theorems)} theorems</span></h3>` +
    `<p class="dim">${esc(p.chip)} · ${esc(p.interface)}</p><ul>${p.properties.map((s) => `<li>${esc(s)}</li>`).join("")}</ul></article>`).join("") ||
    `<p class="count">No match.</p>`;
}

async function main() {
  const d = await fetch("./data.json").then((r) => r.json());
  tiles(d);
  overview(d);
  detail(d);
  props(d);
  $("#not-ported").textContent = `Audited and not ported (no input-driven logic to verify): ${d.not_ported.join(", ")}. Data as of ${d.updated}.`;
  for (const th of document.querySelectorAll("#overview-table th[data-sort]")) {
    th.addEventListener("click", () => {
      sortDir = sortKey === th.dataset.sort ? -sortDir : 1;
      sortKey = th.dataset.sort;
      overview(d);
    });
  }
  $("#f-q").addEventListener("input", () => props(d));
}

setTheme(document.documentElement.dataset.theme || "dark");
for (const b of document.querySelectorAll("[data-theme-set]")) b.addEventListener("click", () => setTheme(b.dataset.themeSet));
main().catch(() => { $("#tiles").innerHTML = `<p class="count">Could not load data.json.</p>`; });
