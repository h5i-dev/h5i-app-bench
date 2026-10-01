"use strict";

const DATA = "./data";
const $ = (sel, root = document) => root.querySelector(sel);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
// Grader verdicts in plain words.
function reasonText(r) {
  if (!r) return "";
  if (r.startsWith("axioms") && r.includes("sorryAx")) return "the proof still uses sorry";
  if (r.startsWith("axioms")) return `uses a non-standard axiom: ${r.slice(7)}`;
  if (r === "MISSING") return "the theorem is missing from Solution.lean";
  if (r === "STATEMENT_MISMATCH") return "the theorem's statement was changed";
  if (r === "NOT_A_THEOREM") return "the declaration is not a theorem";
  if (r === "build failed") return "the proof does not build";
  if (r.startsWith("forbidden")) return `rejected: ${r.slice(11)}`;
  return r;
}
const fmtCost = (c) => (c == null ? "–" : c < 1 ? `$${c.toFixed(2)}` : `$${c.toFixed(1)}`);

let INDEX = null;
let COLUMNS = [];
const cache = new Map();

// ---- Syntax highlighting -------------------------------------------------

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

// ---- Overview ------------------------------------------------------------

function columnLabel(key) {
  const c = INDEX.columns[key];
  return { model: c.model, agent: c.agent === "claude" ? "Claude Code" : c.agent === "gemini" ? "gemini-cli" : "Codex" };
}

const kLines = (n) => (n >= 1000 ? `${(n / 1000).toFixed(1)}k` : String(n));
const pct = (a, b) => (b ? Math.round((a / b) * 100) : 0);
const bar = (a, b) => `<div class="bar-track" aria-hidden="true"><div class="bar-fill" style="width:${b ? ((a / b) * 100).toFixed(1) : 0}%"></div></div>`;

function renderTiles() {
  const s = INDEX.stats;
  const tiles = [
    [s.repos, "repositories", "open-source Rust web applications"],
    [kLines(s.ported_loc), "lines of upstream Rust", "ported to i5h"],
    [s.properties, "properties", "one theorem each"],
    [s.proved, "properties proved", `by at least one model · ${pct(s.proved, s.properties)}%`, [s.proved, s.properties]],
  ];
  $("#tiles").innerHTML = tiles.map(([v, l, sub, frac]) =>
    `<div class="tile"><span class="v">${v}</span><span class="l">${l}</span>${frac ? bar(...frac) : ""}<span class="s">${sub}</span></div>`).join("");
  const runs = Object.values(INDEX.columns).reduce((n, c) => n + c.runs, 0);
  $("#status-note").textContent = `Results as of ${INDEX.generated}: ${runs} graded runs of ${COLUMNS.length} model and agent pairs. Runs are still being added.`;
}

function renderApps() {
  $("#apps-table tbody").innerHTML = Object.entries(INDEX.apps).map(([app, a]) => {
    const ts = INDEX.tasks.filter((t) => t.app === app);
    const proved = ts.filter((t) => Object.values(t.results).some((r) => r.p)).length;
    return `<tr><td>${esc(app)}</td>
      <td class="repo"><a href="https://github.com/${esc(a.repo)}/tree/${esc(a.commit)}" target="_blank" rel="noreferrer">${esc(a.repo)} @ ${esc(a.commit)}</a></td>
      <td class="num">${(a.ported_loc ?? 0).toLocaleString("en")}</td><td class="num">${ts.length}</td>
      <td><div class="bar-row">${bar(proved, ts.length)}<span class="bar-label"><span class="pct">${pct(proved, ts.length)}%</span> <span class="of">${proved} of ${ts.length}</span></span></div></td></tr>`;
  }).join("");
}

function renderModels() {
  $("#models-table tbody").innerHTML = COLUMNS.map((key) => {
    const c = INDEX.columns[key];
    const { model, agent } = columnLabel(key);
    const rate = c.runs ? c.solved / c.runs : 0;
    return `<tr>
      <td>${esc(model)}</td><td class="agent">${esc(agent)}</td>
      <td><div class="bar-row"><div class="bar-track" aria-hidden="true"><div class="bar-fill" style="width:${(rate * 100).toFixed(1)}%"></div></div>
        <span class="bar-label"><span class="pct">${Math.round(rate * 100)}%</span> <span class="of">${c.solved} of ${c.runs}</span></span></div></td>
      <td class="num">${c.solved_minutes ?? "–"}</td><td class="num">${c.solved_loc ? `$${(c.solved_cost / c.solved_loc).toPrecision(2)}` : `<span class="of">no proof yet</span>`}</td></tr>`;
  }).join("");
}

function renderMatrixHead() {
  $("#matrix thead").innerHTML = `<tr><th scope="col">Task</th><th scope="col">Property</th><th scope="col" class="num">Upstream lines</th>${COLUMNS.map((key) => {
    const { model, agent } = columnLabel(key);
    return `<th scope="col" class="col">${esc(model)}<span class="agent">${esc(agent)}</span></th>`;
  }).join("")}</tr>`;
}

function cellHtml(task, key) {
  const r = task.results[key];
  if (!r) return `<td class="cell" data-col="${esc(key)}"><span class="cell-icon none" aria-label="not run">·</span></td>`;
  return `<td class="cell" data-col="${esc(key)}"><span class="cell-icon ${r.p ? "good" : "bad"}" aria-label="${r.p ? "solved" : "not solved"}">${r.p ? "✓" : "✗"}</span></td>`;
}

function filteredTasks() {
  const app = $("#f-app").value;
  const scope = $("#f-scope").value;
  const q = $("#f-q").value.trim().toLowerCase();
  return INDEX.tasks.filter((t) => {
    if (app && t.app !== app) return false;
    const rs = Object.values(t.results);
    if (scope === "all-models" && COLUMNS.some((k) => !t.results[k])) return false;
    if (scope === "solved" && !rs.some((r) => r.p)) return false;
    if (scope === "unsolved" && (rs.some((r) => r.p) || !rs.length)) return false;
    if (q && !`${t.id} ${t.property} ${t.theorem}`.toLowerCase().includes(q)) return false;
    return true;
  });
}

function renderMatrix() {
  const tasks = filteredTasks();
  let html = "";
  let app = null;
  for (const t of tasks) {
    if (t.app !== app) {
      app = t.app;
      const a = INDEX.apps[app];
      html += `<tr class="group"><td colspan="${COLUMNS.length + 3}">${esc(app)} · ${esc(a.repo)}</td></tr>`;
    }
    html += `<tr class="task" tabindex="0" data-id="${esc(t.id)}"><td class="t-name">${esc(t.id)}</td><td class="t-prop">${esc(t.property)}</td><td class="num">${t.loc ? t.loc.toLocaleString("en") : "–"}</td>${COLUMNS.map((k) => cellHtml(t, k)).join("")}</tr>`;
  }
  if (!tasks.length) html = `<tr><td class="count" colspan="${COLUMNS.length + 3}">No task matches the filters.</td></tr>`;
  $("#matrix tbody").innerHTML = html;
}

// ---- Tooltip -------------------------------------------------------------

function showTip(cell, ev) {
  const tr = cell.closest("tr.task");
  const task = INDEX.tasks.find((t) => t.id === tr.dataset.id);
  const key = cell.dataset.col;
  const { model, agent } = columnLabel(key);
  const r = task.results[key];
  const body = r
    ? `${r.p ? "Solved" : "Not solved"} · ${r.m} min · ${fmtCost(r.c)}`
    : "Not run yet";
  const tip = $("#tooltip");
  tip.innerHTML = `<b>${esc(model)} <span class="r">· ${esc(agent)}</span></b>${esc(task.id)}<br><span class="r">${esc(body)}</span>`;
  tip.hidden = false;
  const x = Math.min(ev.clientX + 14, window.innerWidth - tip.offsetWidth - 8);
  const y = ev.clientY + 16 + tip.offsetHeight > window.innerHeight ? ev.clientY - tip.offsetHeight - 12 : ev.clientY + 16;
  tip.style.left = `${x}px`;
  tip.style.top = `${y}px`;
}

// ---- Task drawer ---------------------------------------------------------

const TABS = [
  ["statement", "Statement"],
  ["rust", "Rust"],
  ["equivalence", "Equivalence"],
  ["lean", "Lean"],
  ["results", "Results"],
];

async function loadTask(id) {
  if (!cache.has(id)) cache.set(id, fetch(`${DATA}/tasks/${encodeURIComponent(id)}.json`).then((r) => r.json()));
  return cache.get(id);
}

function tabStatement(d) {
  let h = `<h3>Theorem</h3><p class="note">The agent replaces <code>sorry</code> with a proof. The statement must stay exactly as written.</p>`;
  h += codeBlock({ title: d.theorem.split(".").pop(), sub: "Solution.lean", code: d.statement, lang: "lean" });
  h += d.target.loc
    ? `<p class="note">The property is about ${d.target.loc.toLocaleString("en")} lines of upstream Rust: ${d.target.fns.map((f) => `<code>${esc(f)}</code>`).join(", ")} and what they call.</p>`
    : `<p class="note">The property is about code that exists only in the port, so no upstream lines are counted.</p>`;
  h += `<h3>Spec definitions it uses</h3>`;
  h += d.spec.length
    ? `<p class="note">From the port's <code>Spec.lean</code>, which the agent is given.</p>` + d.spec.map((s) => codeBlock({ title: s.name, code: s.code, lang: "lean" })).join("")
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
    h += codeBlock({ title: "i5h port", sub: `${k.file}:${k.line}`, url: k.url, code: k.code, lang: "rust" });
    h += `</div>`;
  }
  return h;
}

function tabEquivalence(d) {
  const app = INDEX.apps[d.app];
  let h = `<p class="note">The differential test runs upstream and the i5h port on the same generated inputs and compares results; a mutated port must fail it. These are the tests that call the functions above.</p>`;
  h += d.difftest.length
    ? d.difftest.map((t) => codeBlock({ title: t.fn, sub: `${t.file}:${t.line}`, url: t.url, code: t.code, lang: "rust" })).join("")
    : `<p class="empty">No test names these functions directly; they are covered through their callers.</p>`;
  h += `<h3>Deviations from upstream</h3><p class="note">Upstream: <a href="https://github.com/${esc(app.repo)}/tree/${esc(app.commit)}" target="_blank" rel="noreferrer">${esc(app.repo)} @ ${esc(app.commit)}</a> · <a href="${esc(app.port)}" target="_blank" rel="noreferrer">port</a></p>`;
  h += `<details class="dev"><summary>Show the port's deviations file</summary><div class="dev-body">${app.deviations}</div></details>`;
  return h;
}

function tabLean(d) {
  if (!d.lean.length) return `<p class="empty">No generated definition is referenced by this statement.</p>`;
  return `<p class="note">Extracted from the i5h port by Aeneas. The bracket in each comment names the Rust item it came from.</p>` +
    d.lean.map((l) => codeBlock({ title: l.name, sub: l.rust, code: l.code, lang: "lean" })).join("");
}

function tabResults(d) {
  if (!d.runs.length) return `<p class="empty">No model has been run on this task yet.</p>`;
  const rows = [...d.runs].sort((a, b) => b.passed - a.passed || a.minutes - b.minutes).map((r) => {
    const agent = r.agent === "claude" ? "Claude Code" : r.agent === "gemini" ? "gemini-cli" : "Codex";
    const res = r.passed
      ? `<span class="result good"><span class="cell-icon good" aria-hidden="true">✓</span>Solved</span>`
      : `<span class="result bad"><span class="cell-icon bad" aria-hidden="true">✗</span>Not solved</span>`;
    return `<tr><td><strong>${esc(r.model)}</strong><br><span class="reason">${esc(agent)}</span></td><td>${res}${r.reason ? `<br><span class="reason">${esc(reasonText(r.reason))}</span>` : ""}</td>
      <td class="num">${r.minutes}</td><td class="num">${fmtCost(r.cost)}</td><td class="num">${r.builds ?? "–"} / ${r.failed_builds ?? "–"}</td><td class="num">${r.passed && r.proof_loc != null ? r.proof_loc : "–"}</td></tr>`;
  }).join("");
  let h = `<div class="table-wrap"><table class="runs"><thead><tr><th>Model</th><th>Result</th><th class="num">Minutes</th><th class="num">Cost</th><th class="num">Builds / failed</th><th class="num">Proof lines</th></tr></thead><tbody>${rows}</tbody></table></div>`;
  if (!INDEX.proofs) return h + `<p class="note">Proofs are not published.</p>`;
  for (const p of d.proofs) {
    const { model, agent } = columnLabel(p.column);
    h += `<details class="proof"><summary>${esc(model)} · ${esc(agent)} — ${p.loc ?? "?"} lines, ${p.minutes} min</summary>${codeBlock({ title: "Solution.lean", code: p.code, lang: "lean" })}</details>`;
  }
  return h;
}

const RENDER = { statement: tabStatement, rust: tabRust, equivalence: tabEquivalence, lean: tabLean, results: tabResults };
let current = null;
let lastFocus = null;

function selectTab(name) {
  for (const b of $("#d-tabs").children) b.setAttribute("aria-selected", String(b.dataset.tab === name));
  $("#d-body").innerHTML = RENDER[name](current);
  $("#d-body").scrollTop = 0;
}

async function openTask(id, tab = "statement") {
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
  $("#d-tabs").innerHTML = TABS.map(([k, label]) => {
    const n = k === "results" ? ` (${current.runs.filter((r) => r.passed).length}/${current.runs.length})` : "";
    return `<button role="tab" type="button" data-tab="${k}">${label}${n}</button>`;
  }).join("");
  selectTab(tab);
  $(".close", drawer).focus();
  if (location.hash.slice(1) !== id) history.replaceState(null, "", `#${id}`);
}

function closeTask() {
  $("#drawer").hidden = true;
  document.body.style.overflow = "";
  history.replaceState(null, "", location.pathname + location.search);
  if (lastFocus) lastFocus.focus();
}

// ---- Wiring --------------------------------------------------------------

async function main() {
  INDEX = await fetch(`${DATA}/index.json`).then((r) => r.json());
  COLUMNS = Object.keys(INDEX.columns).sort((a, b) => {
    const x = INDEX.columns[a], y = INDEX.columns[b];
    return y.solved / y.runs - x.solved / x.runs || y.runs - x.runs;
  });
  renderTiles();
  renderApps();
  renderModels();
  const sel = $("#f-app");
  for (const app of Object.keys(INDEX.apps)) sel.insertAdjacentHTML("beforeend", `<option value="${esc(app)}">${esc(app)}</option>`);
  renderMatrixHead();
  renderMatrix();

  for (const id of ["#f-app", "#f-scope", "#f-q"]) $(id).addEventListener("input", renderMatrix);
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
  tbody.addEventListener("mousemove", (e) => {
    const cell = e.target.closest("td.cell");
    if (cell) showTip(cell, e);
    else $("#tooltip").hidden = true;
  });
  tbody.addEventListener("mouseleave", () => ($("#tooltip").hidden = true));

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
