"use strict";

const $ = (sel, root = document) => root.querySelector(sel);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const num = (n, d = 0) => (n == null ? "–" : Number(n).toLocaleString("en", { maximumFractionDigits: d, minimumFractionDigits: d }));
const rps = (n) => num(n, n < 100 ? 1 : 0);
const ms = (n) => num(n, n < 10 ? 2 : n < 100 ? 1 : 0);

const COMPARISON_ORDER = ["rust-h5i", "rust-h5i-optimized", "rust-h5i-gpu", "fastapi", "go", "fastify"];

let DATA = null;
let CONC = 16;
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

// Scenario x implementation, requests/s at one concurrency, drawn as a length
// bar per row against that scenario's fastest implementation.
function renderOverview() {
  for (const el of document.querySelectorAll(".conc-label")) el.textContent = CONC;
  $("#overview-tables").innerHTML = DATA.apps.map((app) => {
    const impls = COMPARISON_ORDER.map((id) => app.impls.find((i) => i.id === id) || {id, h5i: id.startsWith("rust-h5i")});
    const head = impls.map((i) => `<th scope="col" class="num">${implName(i)}</th>`).join("");
    const body = app.scenarios.map((s) => {
      const vals = impls.map((i) => row(app, i.id, s.id, CONC)?.rps ?? null);
      const ranked = [...new Set(vals.filter((v) => v != null))].sort((a, b) => b - a);
      const [best, second] = ranked;
      const cells = vals.map((v, k) => {
        if (v == null) return `<td class="num ov-cell">–</td>`;
        const f = v / best;
        const top = v === best;
        const win = top ? ` <span class="win" aria-hidden="true">●</span>` : "";
        const measured = row(app, impls[k].id, s.id, CONC)?.measured;
        return `<td class="num ov-cell${top ? " best" : v === second ? " second" : ""}" style="--f:${f.toFixed(3)}" title="${esc(impls[k].id)} · ${esc(s.id)}: ${rps(v)} req/s, ${Math.round(f * 100)}% of the fastest · ${esc(measured || '')}"><span class="ov-bar" aria-hidden="true"></span><span class="ov-val">${rps(v)}${win}</span></td>`;
      }).join("");
      return `<tr><th scope="row"><a href="#${esc(app.id)}" data-app="${esc(app.id)}" data-scenario="${esc(s.id)}">${esc(s.id)}</a></th>${cells}</tr>`;
    }).join("");
    return `<h3 class="sub-head">${esc(app.title)}</h3>
      ${app.measurement_note ? `<p class="caption">${esc(app.measurement_note)}</p>` : ""}
      <div class="table-wrap"><table class="perf-matrix" style="--perf-columns:${impls.length}"><thead><tr><th scope="col">Scenario</th>${head}</tr></thead><tbody>${body}</tbody></table></div>`;
  }).join("");
}

// One application: pick a scenario, then requests/s at every concurrency and
// latency / memory at the selected one.
function renderApp(app) {
  const sc = pick[app.id];
  const s = app.scenarios.find((x) => x.id === sc);
  const tabs = app.scenarios.map((x) =>
    `<button type="button" role="tab" tabindex="${x.id === sc ? 0 : -1}" aria-selected="${x.id === sc}" data-app="${esc(app.id)}" data-scenario="${esc(x.id)}">${esc(x.id)}</button>`).join("");
  const max = Math.max(0, ...app.rows.filter((r) => r.scenario === sc).map((r) => r.rps));
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
    if (!r) return `<tr><th scope="row">${implName(i)}<span class="sub">${esc(i.stack)}</span></th>${'<td class="num">–</td>'.repeat(8)}</tr>`;
    return `<tr><th scope="row">${implName(i)}<span class="sub">${esc(i.stack)}</span></th>
      <td class="num">${rps(r.rps)}</td><td class="num">${ms(r.p50_ms)}</td><td class="num">${ms(r.p90_ms)}</td><td class="num">${ms(r.p99_ms)}</td>
      <td class="num">${num(r.rss_peak_mb, 0)}</td><td class="num">${num(r.cpu_peak_pct, 0)}</td><td class="num">${num(r.errors, 1)}</td><td>${r.source ? `<a href="${esc(r.source)}" target="_blank" rel="noreferrer">${esc(r.measured || 'CSV')}</a>` : "–"}</td></tr>`;
  }).join("");
  const batchRows = app.impls.map((i) => {
    const r = row(app, i.id, sc, CONC);
    return r?.mean_batch == null ? "" : `<tr><th scope="row">${implName(i)}</th><td class="num">${num(r.mean_batch, 2)}</td><td class="num">${ms(r.mean_queue_wait_ms)}</td><td class="num">${num(r.sql_queries)}</td><td class="num">${num(r.gpu_launches)}</td></tr>`;
  }).join("");
  const batches = batchRows ? `<h3 class="sub-head">Observed request batching</h3><p class="caption">Means across repetitions at ${CONC} clients. Batch size = completed requests / SQL queries. Queue wait includes time behind the active batch; the 1 ms collection window is not a latency bound. SQL calls and GPU launches cover each measured run.</p><div class="table-wrap"><table class="perf-detail"><thead><tr><th scope="col">Implementation</th><th scope="col" class="num">Requests / batch</th><th scope="col" class="num">Queue ms</th><th scope="col" class="num">SQL / run</th><th scope="col" class="num">GPU launches / run</th></tr></thead><tbody>${batchRows}</tbody></table></div>` : "";
  const phaseRows = app.impls.map((i) => {
    const r = row(app, i.id, sc, CONC);
    return r?.compute_ms_per_batch == null ? "" : `<tr><th scope="row">${implName(i)}</th><td class="num">${num(r.sql_fetch_ms_per_batch, 4)}</td><td class="num">${num(r.pack_ms_per_batch, 4)}</td><td class="num">${num(r.compute_ms_per_batch, 4)}</td></tr>`;
  }).join("");
  const phases = phaseRows ? `<h3 class="sub-head">Rust batch phases</h3><p class="caption">Mean milliseconds per batch at ${CONC} clients. Fetch includes PostgreSQL execution, transfer and decoding. Pack constructs the input snapshot. Compute includes CPU pricing, or CUDA transpose, allocation, upload, kernel, synchronization and full download. Queueing, HTTP and reply handling are outside these phases. Batch sizes above can differ between implementations.${app.diagnostic_url ? ` <a href="${esc(app.diagnostic_url)}" target="_blank" rel="noreferrer">GPU allocation, upload and residency diagnostic</a>.` : ""}</p><div class="table-wrap"><table class="perf-detail"><thead><tr><th scope="col">Implementation</th><th scope="col" class="num">Fetch ms</th><th scope="col" class="num">Pack ms</th><th scope="col" class="num">Compute ms</th></tr></thead><tbody>${phaseRows}</tbody></table></div>` : "";
  return `<div class="tabs scenario-tabs" role="tablist" aria-label="${esc(app.title)} scenario">${tabs}</div>
    <p class="caption"><code>${esc(sc)}</code>: ${esc(s.requests)}</p>
    <div class="table-wrap"><table class="perf-bars" style="--perf-columns:${app.concurrency.length}"><thead><tr><th scope="col">Requests/s</th>${concHead}</tr></thead><tbody>${bars}</tbody></table></div>
    <h3 class="sub-head">At ${CONC} clients</h3>
    <div class="table-wrap"><table class="perf-detail"><thead><tr><th scope="col">Implementation</th><th scope="col" class="num">req/s</th><th scope="col" class="num">p50 ms</th><th scope="col" class="num">p90 ms</th><th scope="col" class="num">p99 ms</th><th scope="col" class="num">RSS MiB</th><th scope="col" class="num">CPU peak %</th><th scope="col" class="num">Errors</th><th scope="col">Measured</th></tr></thead><tbody>${detail}</tbody></table></div>${batches}${phases}`;
}

function renderApps() {
  const app = DATA.apps.find((a) => a.id === $("#f-app").value);
  $("#app-detail").innerHTML = `
    <div class="block-head">
      <h3>${esc(app.title)}</h3>
      <p>${esc(app.about)} <a href="${esc(app.upstream)}" target="_blank" rel="noreferrer">Upstream</a> · <a href="${esc(app.source)}" target="_blank" rel="noreferrer">Source and results</a>${app.measured ? ` · ${esc(app.measured)}` : ""}</p>
      <p class="caption">Seed: ${esc(app.seed)}</p>
    </div>
    ${app.measurement_note ? `<p class="caption">${esc(app.measurement_note)}</p>` : ""}
    <div class="app-body" data-app="${esc(app.id)}">${renderApp(app)}</div>`;
}

function rerender() {
  renderOverview();
  renderApps();
}

// Preserve application deep links without adding an entry to the global nav.
function revealHashTarget() {
  const app = DATA.apps.find((a) => a.id === decodeURIComponent(location.hash.slice(1)));
  if (!app) return;
  $("#f-app").value = app.id;
  renderApps();
  $("#comparison").scrollIntoView();
}

async function main() {
  setTheme(currentTheme());
  for (const b of document.querySelectorAll("[data-theme-set]")) b.addEventListener("click", () => setTheme(b.dataset.themeSet));

  const response = await fetch("./data.json");
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  DATA = await response.json();
  const concs = [...new Set(DATA.apps.flatMap((a) => a.concurrency))].sort((a, b) => a - b);
  if (!concs.includes(CONC)) CONC = concs[concs.length - 1];
  for (const id of ["#f-conc", "#f-detail-conc"]) {
    $(id).innerHTML = concs.map((c) => `<option value="${c}"${c === CONC ? " selected" : ""}>${c} clients</option>`).join("");
    $(id).addEventListener("change", (e) => {
      CONC = Number(e.target.value);
      $("#f-conc").value = $("#f-detail-conc").value = String(CONC);
      rerender();
    });
  }
  $("#f-app").innerHTML = DATA.apps.map((a) => `<option value="${esc(a.id)}">${esc(a.title)}</option>`).join("");
  $("#f-app").addEventListener("change", () => {
    renderApps();
    history.replaceState(null, "", `#${encodeURIComponent($("#f-app").value)}`);
  });
  for (const app of DATA.apps) pick[app.id] = app.scenarios.some((s) => s.id === "mixed") ? "mixed" : app.scenarios[0].id;
  rerender();
  window.addEventListener("hashchange", revealHashTarget);
  revealHashTarget();

  document.addEventListener("click", (e) => {
    const t = e.target.closest("[data-app][data-scenario]");
    if (!t) return;
    pick[t.dataset.app] = t.dataset.scenario;
    $("#f-app").value = t.dataset.app;
    renderApps();
    if (t.tagName === "A") {
      e.preventDefault();
      history.replaceState(null, "", `#${encodeURIComponent(t.dataset.app)}`);
      $("#comparison").scrollIntoView();
    } else {
      $("#app-detail").querySelector(`[data-scenario="${CSS.escape(t.dataset.scenario)}"]`).focus();
    }
  });
  document.addEventListener("keydown", (e) => {
    const tab = e.target.closest('[role="tab"]');
    if (!tab || !["ArrowLeft", "ArrowRight", "Home", "End"].includes(e.key)) return;
    e.preventDefault();
    const tabs = [...tab.parentElement.querySelectorAll('[role="tab"]')];
    const next = e.key === "Home" ? 0 : e.key === "End" ? tabs.length - 1 :
      (tabs.indexOf(tab) + (e.key === "ArrowRight" ? 1 : -1) + tabs.length) % tabs.length;
    const scenario = tabs[next].dataset.scenario;
    pick[tab.dataset.app] = scenario;
    renderApps();
    $("#app-detail").querySelector(`[data-scenario="${CSS.escape(scenario)}"]`).focus();
  });
}

main().catch((err) => {
  $("#overview-tables").innerHTML = `<p class="empty">Could not load the results (${esc(err.message)}). <a href="https://github.com/h5i-dev/h5i-app-bench/tree/main/performance">Read the benchmark reports</a>.</p>`;
});
