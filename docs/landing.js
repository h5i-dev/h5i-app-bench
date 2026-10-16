"use strict";

const $ = (sel) => document.querySelector(sel);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const fmt = (n) => Number(n).toLocaleString("en");
const kLines = (n) => (n >= 10000 ? `${(n / 1000).toFixed(1)}k` : fmt(n));
const fact = (v, l) => `<div><span class="v">${v}</span><span class="l">${esc(l)}</span></div>`;

function setTheme(t) {
  document.documentElement.dataset.theme = t;
  try { localStorage.setItem("theme", t); } catch (e) { /* private mode */ }
  for (const b of document.querySelectorAll("[data-theme-set]")) b.setAttribute("aria-pressed", String(b.dataset.themeSet === t));
}

async function prove() {
  const d = await fetch("./prove/data/index.json").then((r) => r.json());
  const s = d.stats;
  $("#prove-facts").innerHTML =
    fact(`${s.accepted}<small>/${s.properties}</small>`, "specs verified") +
    fact(Object.keys(d.apps).length, "Rust servers") +
    fact(kLines(s.upstream_reached), "upstream lines covered") +
    fact(kLines(s.proof_loc), "lines of Lean proof");
}

// At 64 clients: in how many scenarios an h5i-app server has the highest
// requests/s of all implementations.
async function performance() {
  const d = await fetch("./performance/data.json").then((r) => r.json());
  const h5i = new Set(d.apps.flatMap((a) => a.impls.filter((i) => i.h5i).map((i) => i.id)));
  let wins = 0, total = 0, impls = new Set();
  for (const a of d.apps) {
    for (const i of a.impls) impls.add(i.id);
    for (const s of a.scenarios) {
      const rows = a.rows.filter((r) => r.scenario === s.id && r.concurrency === 64);
      if (!rows.length) continue;
      total += 1;
      const best = rows.reduce((x, y) => (y.rps > x.rps ? y : x));
      if (h5i.has(best.impl)) wins += 1;
    }
  }
  $("#perf-facts").innerHTML =
    fact(d.apps.length, "applications") +
    fact(impls.size, "implementations") +
    fact(total, "load scenarios") +
    fact(`${wins}<small>/${total}</small>`, "fastest is h5i-app, at 64 clients");
}

setTheme(document.documentElement.dataset.theme || "dark");
for (const b of document.querySelectorAll("[data-theme-set]")) b.addEventListener("click", () => setTheme(b.dataset.themeSet));
prove().catch(() => {});
performance().catch(() => {});
