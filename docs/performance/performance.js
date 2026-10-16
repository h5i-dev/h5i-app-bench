"use strict";

const $ = (sel, root = document) => root.querySelector(sel);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const num = (n, d = 0) => (n == null ? "–" : Number(n).toLocaleString("en", { maximumFractionDigits: d, minimumFractionDigits: d }));
const rps = (n) => num(n, n < 100 ? 1 : 0);
const ms = (n) => num(n, n < 10 ? 2 : n < 100 ? 1 : 0);

let DATA = null;
let CONC = 64;
const pick = {}; // app id -> scenario id

function currentTheme() {
  return document.documentElement.dataset.theme || "dark";
}
function setTheme(t) {
  document.documentElement.dataset.theme = t;
  try { localStorage.setItem("theme", t); } catch (e) { /* private mode */ }
  for (const b of document.querySelectorAll("[data-theme-set]")) b.setAttribute("aria-pressed", String(b.dataset.themeSet === t));
}

const row = (app, impl, scenario, conc) =>
  app.rows.find((r) => r.impl === impl && r.scenario === scenario && r.concurrency === conc);

const implName = (i) => `<span class="impl${i.h5i ? " h5i" : ""}">${esc(i.id)}</span>`;

// Scenario x implementation, requests/s at one concurrency, shaded per row
// against that scenario's fastest implementation.
function renderOverview() {
  for (const el of document.querySelectorAll(".conc-label")) el.textContent = CONC;
  $("#overview-tables").innerHTML = DATA.apps.map((app) => {
    const head = app.impls.map((i) => `<th scope="col" class="num">${implName(i)}</th>`).join("");
    const body = app.scenarios.map((s) => {
      const vals = app.impls.map((i) => row(app, i.id, s.id, CONC)?.rps ?? null);
      const best = Math.max(...vals.filter((v) => v != null));
      const cells = vals.map((v, k) => {
        if (v == null) return `<td class="num">–</td>`;
        const f = v / best;
        const top = v === best ? " best" : "";
        return `<td class="num heat${top}" style="--f:${f.toFixed(3)}" title="${esc(app.impls[k].id)} · ${esc(s.id)}: ${rps(v)} req/s, ${Math.round(f * 100)}% of the fastest">${rps(v)}</td>`;
      }).join("");
      return `<tr><th scope="row"><a href="#${esc(app.id)}" data-app="${esc(app.id)}" data-scenario="${esc(s.id)}">${esc(s.id)}</a></th>${cells}</tr>`;
    }).join("");
    return `<h3 class="sub-head">${esc(app.title)}</h3>
      <div class="table-wrap"><table class="perf-matrix"><thead><tr><th scope="col">Scenario</th>${head}</tr></thead><tbody>${body}</tbody></table></div>`;
  }).join("");
}

// One application: pick a scenario, then requests/s at every concurrency and
// latency / memory at the selected one.
function renderApp(app) {
  const sc = pick[app.id];
  const s = app.scenarios.find((x) => x.id === sc);
  const tabs = app.scenarios.map((x) =>
    `<button type="button" role="tab" aria-selected="${x.id === sc}" data-app="${esc(app.id)}" data-scenario="${esc(x.id)}">${esc(x.id)}</button>`).join("");
  const max = Math.max(...app.rows.filter((r) => r.scenario === sc).map((r) => r.rps));
  const concHead = app.concurrency.map((c) => `<th scope="col" class="w-conc${c === CONC ? " on" : ""}">${c} clients</th>`).join("");
  const bars = app.impls.map((i) => {
    const cells = app.concurrency.map((c) => {
      const r = row(app, i.id, sc, c);
      if (!r) return `<td>–</td>`;
      const w = ((r.rps / max) * 100).toFixed(1);
      const err = r.errors > 0 ? ` <span class="err" title="mean failed requests">${num(r.errors, 1)} err</span>` : "";
      return `<td${c === CONC ? ' class="on"' : ""}><div class="bar-row" title="${esc(i.id)} at ${c} clients: ${rps(r.rps)} req/s ± ${rps(r.rps_stdev)}"><div class="bar-track" aria-hidden="true"><div class="bar-fill${i.h5i ? "" : " other"}" style="width:${w}%"></div></div><span class="bar-label">${rps(r.rps)}${err}</span></div></td>`;
    }).join("");
    return `<tr><th scope="row">${implName(i)}</th>${cells}</tr>`;
  }).join("");
  const detail = app.impls.map((i) => {
    const r = row(app, i.id, sc, CONC);
    if (!r) return "";
    return `<tr><th scope="row">${implName(i)}<span class="sub">${esc(i.stack)}</span></th>
      <td class="num">${rps(r.rps)}</td><td class="num">${ms(r.p50_ms)}</td><td class="num">${ms(r.p90_ms)}</td><td class="num">${ms(r.p99_ms)}</td>
      <td class="num">${num(r.rss_peak_mb, 0)}</td><td class="num">${num(r.cpu_peak_pct, 0)}</td><td class="num">${num(r.errors, 1)}</td></tr>`;
  }).join("");
  return `<div class="tabs scenario-tabs" role="tablist" aria-label="${esc(app.title)} scenario">${tabs}</div>
    <p class="caption"><code>${esc(sc)}</code>: ${esc(s.requests)}</p>
    <div class="table-wrap"><table class="perf-bars"><thead><tr><th scope="col">Requests/s</th>${concHead}</tr></thead><tbody>${bars}</tbody></table></div>
    <h3 class="sub-head">At ${CONC} clients</h3>
    <div class="table-wrap"><table class="perf-detail"><thead><tr><th scope="col">Implementation</th><th scope="col" class="num">req/s</th><th scope="col" class="num">p50 ms</th><th scope="col" class="num">p90 ms</th><th scope="col" class="num">p99 ms</th><th scope="col" class="num">RSS MiB</th><th scope="col" class="num">CPU peak %</th><th scope="col" class="num">Errors</th></tr></thead><tbody>${detail}</tbody></table></div>`;
}

function renderApps() {
  $("#apps").innerHTML = DATA.apps.map((app, k) => `
    <section id="${esc(app.id)}" class="block">
      <div class="block-head">
        <h2 class="term" data-n="${String(k + 2).padStart(2, "0")}">${esc(app.title)}</h2>
        <p>${esc(app.about)} Seed: ${esc(app.seed)} <a href="${esc(app.upstream)}" target="_blank" rel="noreferrer">Upstream</a> · <a href="${esc(app.source)}" target="_blank" rel="noreferrer">implementations and raw results</a>${app.measured ? ` · measured ${esc(app.measured)}` : ""}</p>
      </div>
      <div class="app-body" data-app="${esc(app.id)}">${renderApp(app)}</div>
    </section>`).join("");
}

function rerender() {
  renderOverview();
  for (const app of DATA.apps) $(`.app-body[data-app="${app.id}"]`).innerHTML = renderApp(app);
}

async function main() {
  setTheme(currentTheme());
  for (const b of document.querySelectorAll("[data-theme-set]")) b.addEventListener("click", () => setTheme(b.dataset.themeSet));

  DATA = await fetch("./data.json").then((r) => r.json());
  const concs = [...new Set(DATA.apps.flatMap((a) => a.concurrency))].sort((a, b) => a - b);
  if (!concs.includes(CONC)) CONC = concs[concs.length - 1];
  $("#f-conc").innerHTML = concs.map((c) => `<option value="${c}"${c === CONC ? " selected" : ""}>${c} clients</option>`).join("");
  $("#f-conc").addEventListener("input", (e) => { CONC = Number(e.target.value); rerender(); });

  for (const app of DATA.apps) pick[app.id] = app.scenarios.some((s) => s.id === "mixed") ? "mixed" : app.scenarios[0].id;
  const nav = $("#app-nav");
  nav.querySelector('a[href="#method"]').insertAdjacentHTML("beforebegin",
    DATA.apps.map((a) => `<a href="#${esc(a.id)}">${esc(a.title.split(" ")[0])}</a>`).join(""));

  renderOverview();
  renderApps();

  document.addEventListener("click", (e) => {
    const t = e.target.closest("[data-app][data-scenario]");
    if (!t) return;
    pick[t.dataset.app] = t.dataset.scenario;
    const app = DATA.apps.find((a) => a.id === t.dataset.app);
    $(`.app-body[data-app="${app.id}"]`).innerHTML = renderApp(app);
  });
}

main().catch((err) => {
  $("#overview-tables").innerHTML = `<p class="empty">Could not load the results (${esc(err.message)}). The page must be served over HTTP.</p>`;
});
