"use strict";

const $ = (sel, root = document) => root.querySelector(sel);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const num = (n, d = 0) => (n == null ? "–" : Number(n).toLocaleString("en", { maximumFractionDigits: d, minimumFractionDigits: d }));
const rps = (n) => num(n, n < 100 ? 1 : 0);
const ms = (n) => num(n, n < 10 ? 2 : n < 100 ? 1 : 0);

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
    const impls = app.impls.filter((i) => i.id !== "upstream" && i.id !== "rust-h5i-cpu-scan");
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
  $("#apps").innerHTML = DATA.apps.map((app, k) => `
    <section id="${esc(app.id)}" class="block">
      <div class="block-head">
        <h2 class="term" data-n="${String(k + 2).padStart(2, "0")}">${esc(app.title)}</h2>
        <p>${esc(app.about)} <a href="${esc(app.upstream)}" target="_blank" rel="noreferrer">Upstream</a> · <a href="${esc(app.source)}" target="_blank" rel="noreferrer">Source and results</a>${app.measured ? ` · ${esc(app.measured)}` : ""}</p>
        <p class="caption">Seed: ${esc(app.seed)}</p>
      </div>
      <div class="app-body" data-app="${esc(app.id)}">${renderApp(app)}</div>
    </section>`).join("");
}

function rerender() {
  renderOverview();
  for (const app of DATA.apps) $(`.app-body[data-app="${app.id}"]`).innerHTML = renderApp(app);
}

function renderCart() {
  const data = DATA.cart_pricing;
  const lines = Number($("#cart-lines").value);
  const impls = Object.entries(data.implementations);
  const labels = {rust1: "Rust 1T", rust16: "Rust 16T", go: "Go 1T", javascript: "Node 1T", resident: "GPU resident", upload_each: "GPU upload"};
  const body = data.points.filter((p) => p.lines === lines).map((p) => {
    const bestCPU = Math.min(...["rust1", "rust16", "go", "javascript"].map((i) => p.ms[i]));
    const cells = impls.map(([id]) => {
      const range = p.range_ms[id];
      return `<td class="num" title="Repetition means: ${num(range[0], 6)}–${num(range[1], 6)} ms">${num(p.ms[id], 6)}</td>`;
    }).join("");
    return `<tr><th scope="row">${num(p.carts)}</th>${cells}<td class="num">${num(bestCPU / p.ms.resident, 2)}×</td></tr>`;
  }).join("");
  $("#cart-results").innerHTML = `<table class="perf-detail"><caption>${esc(data.measured)} · best CPU / resident uses the fastest measured CPU implementation for each row.</caption><thead><tr><th scope="col">Carts</th>${impls.map(([id, name]) => `<th scope="col" class="num" title="${esc(name)}">${esc(labels[id])} ms</th>`).join("")}<th scope="col" class="num" title="Fastest measured CPU / GPU resident">CPU/GPU</th></tr></thead><tbody>${body}</tbody></table>`;
}

function renderResident() {
  const data = DATA.cart_resident;
  const lines = Number($("#resident-lines").value);
  const queries = Number($("#resident-queries").value);
  const profile = $("#resident-updates").value;
  const point = data.points.find((p) => p.lines === lines && p.queries === queries && p.profile === profile);
  if (!point) throw new Error("Missing resident update measurement");
  const labels = {"cpu-scan-1": "CPU scan 1T", "cpu-scan-4": "CPU scan 4T", "cpu-delta": "CPU delta", "gpu-scan": "GPU scan", "gpu-delta": "GPU delta"};
  const timing = point.timings;
  const scanRatio = Math.min(timing["cpu-scan-1"].mean_us, timing["cpu-scan-4"].mean_us) / timing["gpu-scan"].mean_us;
  const bestRatio = Math.min(...data.implementations.filter((i) => i.startsWith("cpu")).map((i) => timing[i].mean_us)) / Math.min(...data.implementations.filter((i) => i.startsWith("gpu")).map((i) => timing[i].mean_us));
  const body = data.implementations.map((impl) => {
    const r = timing[impl];
    return `<tr><th scope="row">${esc(labels[impl])}</th><td class="num">${num(r.mean_us, 3)} ± ${num(r.stdev_us, 3)}</td><td class="num">${num(r.p50_us, 3)}</td><td class="num">${num(r.p99_us, 3)}</td><td class="num">${num(r.init_ms, 3)}</td></tr>`;
  }).join("");
  $("#resident-results").innerHTML = `<p class="caption">${num(lines)} lines/cart · ${num(queries)} queries · ${num(point.updates)} replacements/batch. Full-rescan CPU/GPU: <strong>${num(scanRatio, 2)}×</strong>. Best CPU/GPU including incremental totals on both: <strong>${num(bestRatio, 2)}×</strong>. Above 1 favors GPU. ${num(data.checked_totals)} exact totals checked across the complete experiment.</p><div class="table-wrap"><table class="perf-detail"><thead><tr><th scope="col">Backend</th><th scope="col" class="num">µs/batch ± stdev</th><th scope="col" class="num">p50 µs</th><th scope="col" class="num">p99 µs</th><th scope="col" class="num">Initial placement ms</th></tr></thead><tbody>${body}</tbody></table></div>`;
}

function renderResidentScale() {
  const data = DATA.cart_resident_scale;
  const maximum = data.points.reduce((a, b) => a.ratio > b.ratio ? a : b);
  $("#scale-summary").innerHTML = `Maximum best-CPU/GPU ratio across all ${num(data.points.length)} shapes: <strong>${num(maximum.ratio, 2)}×</strong> (${num(maximum.carts)} carts, ${num(maximum.lines)} lines/cart, ${num(maximum.factor)} replacements/cart).`;
  const lines = Number($("#scale-lines").value);
  const carts = Number($("#scale-carts").value);
  const factor = Number($("#scale-factor").value);
  const point = data.points.find((p) => p.lines === lines && p.carts === carts && p.factor === factor);
  if (!point) throw new Error("Missing resident scale measurement");
  const labels = {"cpu-scan-1": "CPU scan 1T", "cpu-scan-4": "CPU scan 4T", "cpu-delta": "CPU delta, event order", "cpu-delta-grouped": "CPU delta, grouped 1T", "cpu-delta-4": "CPU delta, grouped 4T", "gpu-scan": "GPU scan", "gpu-delta": "GPU delta"};
  const body = data.implementations.map((impl) => {
    const t = point.timings[impl];
    return `<tr><th scope="row">${esc(labels[impl])}</th><td class="num">${num(t.mean_us, 3)} ± ${num(t.stdev_us, 3)}</td><td class="num">${num(t.p50_us, 3)}</td><td class="num">${num(t.p99_us, 3)}</td><td class="num">${num(t.init_ms, 3)}</td></tr>`;
  }).join("");
  $("#scale-results").innerHTML = `<p class="caption">${num(carts)} queried carts × ${num(lines)} lines · ${num(point.updates)} replacements/batch. Best CPU/GPU: <strong>${num(point.ratio, 2)}×</strong> (${esc(labels[point.best_cpu])} / ${esc(labels[point.best_gpu])}). ${num(data.checked_totals)} exact totals checked across this sweep.</p><div class="table-wrap"><table class="perf-detail"><thead><tr><th scope="col">Backend</th><th scope="col" class="num">µs/batch ± stdev</th><th scope="col" class="num">p50 µs</th><th scope="col" class="num">p99 µs</th><th scope="col" class="num">Initial placement ms</th></tr></thead><tbody>${body}</tbody></table></div>`;
}

function renderUpdatePhases() {
  const data = DATA.cart_update_phases;
  const p = data.points[Number($("#phase-shape").value)];
  const get = (v, mode) => p.modes.find((m) => m.variant === v && m.mode === mode).timings;
  const cpu = get("cpu-delta-4", "plain").total_us.mean;
  const variants = ["gpu-scan", "gpu-delta"];
  const hostKeys = ["total_us", "upload_us", "enqueue_us", "sync_us", "alloc_us", "download_us", "validate_us"];
  const rows = variants.map((v) => {
    const plain = get(v, "plain"), host = get(v, "host");
    return `<tr><th scope="row">${v === "gpu-scan" ? "GPU scan" : "GPU delta"}</th><td class="num">${num(plain.total_us.mean, 3)} ± ${num(plain.total_us.stdev, 3)}</td>${hostKeys.map((k) => `<td class="num">${num(host[k].mean, 3)}${k === "total_us" ? ` ± ${num(host[k].stdev, 3)}` : ""}</td>`).join("")}</tr>`;
  }).join("");
  const events = variants.map((v) => {
    const t = get(v, "events"), host = get(v, "host");
    return `<tr><th scope="row">${v === "gpu-scan" ? "GPU scan" : "GPU delta"}</th><td class="num">${num(t.device_update_or_fused_us.mean, 3)}</td><td class="num">${v === "gpu-delta" ? "fused" : num(t.device_scan_us.mean, 3)}</td><td class="num">${num(t.total_us.mean, 3)} ± ${num(t.total_us.stdev, 3)}</td><td class="num">${num((t.total_us.mean / host.total_us.mean - 1) * 100, 1)}%</td><td class="num">${num(t.timer_tail_us.mean, 3)}</td></tr>`;
  }).join("");
  const best = Math.min(...variants.map((v) => get(v, "plain").total_us.mean));
  $("#phase-results").innerHTML = `<p class="caption">Separate diagnostic run: CPU grouped delta 4T <strong>${num(cpu, 3)} µs</strong>; best GPU plain <strong>${num(best, 3)} µs</strong>, CPU/GPU <strong>${num(cpu / best, 2)}×</strong>. Commands ${num(p.command_bytes)} bytes; results ${num(p.result_bytes)} bytes. ${num(data.checked_totals)} exact totals checked across ${num(data.rounds)} rounds.</p><div class="table-wrap"><table class="perf-detail"><thead><tr><th scope="col">Backend</th><th scope="col">Plain total ± SD</th><th scope="col">Host total ± SD</th><th scope="col">Upload</th><th scope="col">Enqueue</th><th scope="col">Sync</th><th scope="col">Allocate</th><th scope="col">Download</th><th scope="col">Validate</th></tr></thead><tbody>${rows}</tbody></table></div><p class="caption">All times µs/batch. CUDA event replay below is a separate diagnostic; changes versus host mode include instrumentation and run-to-run variation.</p><div class="table-wrap"><table class="perf-detail"><thead><tr><th scope="col">Backend</th><th scope="col">Device update / fused</th><th scope="col">Device scan</th><th scope="col">Event replay total ± SD</th><th scope="col">Change vs host</th><th scope="col">Event readout / timer tail</th></tr></thead><tbody>${events}</tbody></table></div>`;
}

function renderUpdateTransport() {
  const data = DATA.cart_update_transport;
  const p = data.points[Number($("#transport-shape").value)];
  const cpu = p.modes.find((m) => m.variant === "cpu-delta-4" && m.mode === "plain").timings.total_us.mean;
  const label = (v) => v === "cpu-delta-4" ? "CPU delta grouped 4T" : v.replace("-encode4", " (encode 4T)").replace("gpu-", "GPU ").replaceAll("-", " ");
  const rows = p.modes.filter((m) => m.mode === "plain").map((m) => {
    const t = m.timings;
    return `<tr><th scope="row">${esc(label(m.variant))}</th><td class="num">${num(t.total_us.mean, 3)} ± ${num(t.total_us.stdev, 3)}</td><td class="num">${m.variant.startsWith("cpu") ? "—" : `${num(cpu / t.total_us.mean, 2)}×`}</td><td class="num">${num(t.encoding_us.mean, 3)}</td><td class="num">${num(m.command_bytes)}</td><td class="num">${num(m.init_ms, 3)}</td></tr>`;
  }).join("");
  const eventRows = p.modes.filter((m) => m.mode === "events").map((m) => {
    const t = m.timings;
    return `<tr><th scope="row">${esc(label(m.variant))}</th>${["encoding_us", "event_upload_us", "event_kernels_us"].map((k) => `<td class="num">${num(t[k].mean, 3)}</td>`).join("")}<td class="num">${m.variant.includes("pinned") ? num(t.event_download_us.mean, 3) : "not instrumented"}</td><td class="num">${num(t.total_us.mean, 3)} ± ${num(t.total_us.stdev, 3)}</td></tr>`;
  }).join("");
  $("#transport-results").innerHTML = `<p class="caption">CPU4 / fastest GPU: <strong>${num(p.ratio, 2)}×</strong> (${esc(label(p.best_gpu))}). Speedup over fastest legacy GPU (controls included): <strong>${num(p.speedup_vs_legacy, 2)}×</strong>. Ratios above 1 indicate a speedup. Source commands ${num(p.source_bytes)} bytes, complete results ${num(p.result_bytes)} bytes. ${num(data.checked_totals)} exact totals checked across ${num(data.rounds)} rounds.</p><div class="table-wrap"><table class="perf-detail"><thead><tr><th scope="col">Backend / transport</th><th scope="col">Plain µs/batch ± SD</th><th scope="col">CPU4 / GPU</th><th scope="col">Encode/stage µs</th><th scope="col">Uploaded bytes</th><th scope="col">Initial placement ms</th></tr></thead><tbody>${rows}</tbody></table></div><p class="caption">Separate event replays below, all times µs/batch. Device intervals are diagnostics and must not be added to the plain total.</p><div class="table-wrap"><table class="perf-detail"><thead><tr><th scope="col">Backend / transport</th><th scope="col">Encode/stage</th><th scope="col">Upload interval</th><th scope="col">Kernels</th><th scope="col">Download</th><th scope="col">Event total ± SD</th></tr></thead><tbody>${eventRows}</tbody></table></div>`;
}

function renderResidentLanguages() {
  const data = DATA.cart_resident_languages;
  const p = data.points[Number($("#language-shape").value)];
  const labels = {"rust-1": "Rust · 1 worker", "rust-4": "Rust · 4 workers", "go-1": "Go · 1 worker", "go-4": "Go · 4 workers", "javascript-1": "JavaScript · 1 worker", "javascript-4": "JavaScript · 4 workers", "python-1": "CPython · 1 process", "python-4": "CPython · 4 processes", "python-numpy": "Python / NumPy · native vectorized", "gpu-scan-pageable": "GPU scan · legacy pageable", "gpu-delta-pageable": "GPU delta · legacy pageable", "gpu-scan-compact-pinned-encode4": "GPU scan · compact pinned / encode 4T", "gpu-delta-compact-pinned-encode4": "GPU delta · compact pinned / encode 4T"};
  const gpu = p.timings.find((t) => t.variant === p.best_gpu).mean_us;
  const rows = p.timings.map((t) => `<tr><th scope="row">${esc(labels[t.variant] + (t.historical ? " · prior run" : ""))}</th><td class="num">${num(t.mean_us, 3)} ± ${num(t.stdev_us, 3)}</td><td class="num">${t.variant.startsWith("gpu") ? "—" : `${num(t.mean_us / gpu, 2)}×`}</td></tr>`).join("");
  const reference = data.historical_gpu;
  const note = reference ? `CPU measurements are new; GPU values are prior-run references (${esc(data.gpu_reference_utc)}). External vLLM jobs occupied all GPUs; a new contended GPU rerun is reported separately below. These ratios are references, not contemporary measured speedups. ` : "";
  $("#language-results").innerHTML = `<p class="caption">${note}Fastest measured CPU: <strong>${esc(labels[p.best_cpu])}</strong>. ${reference ? "Prior" : "Fastest"} GPU: <strong>${esc(labels[p.best_gpu])}</strong>. ${reference ? "Reference CPU / prior GPU" : "Fastest CPU / GPU"}: <strong>${num(p.ratio, 2)}×</strong>. Ratios above 1 favor GPU. ${num(data.checked_totals)} exact totals checked across ${num(data.rounds)} new ${reference ? "CPU " : ""}changing rounds, plus 808 upstream cases per implementation.</p><div class="table-wrap"><table class="perf-detail"><thead><tr><th scope="col">Implementation</th><th scope="col">Total µs/batch ± SD</th><th scope="col">CPU / ${reference ? "prior GPU (reference)" : "fastest GPU"}</th></tr></thead><tbody>${rows}</tbody></table></div>`;
  const current = DATA.cart_resident_languages_contended.points.find((t) => t.carts === p.carts && t.lines === p.lines && t.factor === p.factor);
  $("#language-contended").innerHTML = `<p class="caption"><strong>New GPU measurement under external contention:</strong> ${esc(labels[current.variant])}: <strong>${num(current.mean_us, 3)} ± ${num(current.stdev_us, 3)} µs/batch</strong>, ${num(current.slowdown_vs_prior, 2)}× the prior GPU time. GPU 0 was shared with external vLLM processing. Three repetitions, identical input and complete results; this is a contended diagnostic, not an isolated CPU/GPU speedup. <a href="https://github.com/h5i-dev/h5i-app-bench/blob/main/performance/django-cart/resident/languages/results/2026-10-20-contended/summary.md">Rerun details and evidence</a>.</p>`;

}

async function main() {
  setTheme(currentTheme());
  for (const b of document.querySelectorAll("[data-theme-set]")) b.addEventListener("click", () => setTheme(b.dataset.themeSet));

  DATA = await fetch("./data.json").then((r) => r.json());
  $("#language-shape").innerHTML = DATA.cart_resident_languages.points.map((p, i) => `<option value="${i}">${num(p.carts)} × ${num(p.lines)} · ${num(p.factor)} replacements/cart</option>`).join("");
  $("#language-shape").addEventListener("change", renderResidentLanguages);
  renderResidentLanguages();
  $("#phase-shape").innerHTML = DATA.cart_update_phases.points.map((p, i) => `<option value="${i}">${num(p.carts)} × ${num(p.lines)} · ${num(p.factor)} replacements/cart</option>`).join("");
  $("#phase-shape").addEventListener("change", renderUpdatePhases);
  renderUpdatePhases();
  $("#transport-shape").innerHTML = DATA.cart_update_transport.points.map((p, i) => `<option value="${i}">${num(p.carts)} × ${num(p.lines)} · ${num(p.factor)} replacements/cart</option>`).join("");
  $("#transport-shape").addEventListener("change", renderUpdateTransport);
  renderUpdateTransport();
  const concs = [...new Set(DATA.apps.flatMap((a) => a.concurrency))].sort((a, b) => a - b);
  if (!concs.includes(CONC)) CONC = concs[concs.length - 1];
  $("#f-conc").innerHTML = concs.map((c) => `<option value="${c}"${c === CONC ? " selected" : ""}>${c} clients</option>`).join("");
  $("#f-conc").addEventListener("input", (e) => { CONC = Number(e.target.value); rerender(); });

  for (const app of DATA.apps) pick[app.id] = app.scenarios.some((s) => s.id === "mixed") ? "mixed" : app.scenarios[0].id;
  const nav = $("#app-nav");
  nav.querySelector('a[href="#method"]').insertAdjacentHTML("beforebegin",
    DATA.apps.map((a) => `<a href="#${esc(a.id)}">${esc(a.nav_title || a.title.split(" ")[0])}</a>`).join(""));

  renderOverview();
  renderApps();
  renderCart();
  $("#cart-lines").addEventListener("input", renderCart);
  renderResident();
  for (const id of ["#resident-lines", "#resident-queries", "#resident-updates"]) $(id).addEventListener("input", renderResident);
  renderResidentScale();
  for (const id of ["#scale-lines", "#scale-carts", "#scale-factor"]) $(id).addEventListener("input", renderResidentScale);

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
