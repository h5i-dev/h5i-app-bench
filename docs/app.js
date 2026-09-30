const examples = {
  isolation: {
    rust: [
      ['use i5h_pgsql::{compile, Statement};', ''],
      ['', ''],
      ['pub fn tenant_query(', ''],
      ['  schema: &Schema, tenant: Val,', ''],
      [') -> Result<Statement, Error> {', ''],
      ['  let select = Select {', ''],
      ['    table: Tables::Messages,', 'tenant'],
      ['    filters: vec![', 'tenant'],
      ['      (TENANT_ID, tenant.clone()),', 'tenant'],
      ['    ],', 'tenant'],
      ['  };', 'tenant'],
      ['  compile(schema, &select)', 'compile'],
      ['}', ''],
    ],
    brokenRust: [
      ['use i5h_pgsql::{compile, Statement};', ''],
      ['', ''],
      ['pub fn tenant_query(', ''],
      ['  schema: &Schema, _tenant: Val,', ''],
      [') -> Result<Statement, Error> {', ''],
      ['  let select = Select {', ''],
      ['    table: Tables::Messages,', 'tenant'],
      ['    filters: vec![], // tenant filter removed', 'broken'],
      ['  };', 'broken'],
      ['  compile(schema, &select)', 'compile'],
      ['}', ''],
    ],
    lean: [
      ['theorem compile_sound', ''],
      ['    (hvalid : valid schema)', ''],
      ['    (hcompile :', 'compile'],
      ['      compile schema tenant stmt = .ok sql)', 'compile'],
      ['    (hexec : exec sql db = .ok db\') :', ''],
      ['', ''],
      ['  tenantRows db\' tenant =', 'tenant'],
      ['    Sql.exec stmt (tenantRows db tenant) ∧', 'tenant'],
      ['', ''],
      ['  ∀ other, other ≠ tenant →', 'tenant'],
      ['    tenantRows db\' other =', 'tenant'],
      ['    tenantRows db other := by', 'tenant'],
      ['  exact Pg.compile_sound hvalid hcompile hexec', 'compile'],
    ],
    title: 'Every query stays inside its tenant.',
    copy: 'The compiled statement cannot read or change rows belonging to another tenant.',
    theorem: 'Pg.compile_sound',
    failedTitle: 'Tenant isolation is no longer established.',
    failedCopy: 'Without the tenant filter, the proof obligation has a counterexample: another tenant’s rows may be selected.',
  },
  authorization: {
    rust: [
      ['pub fn transition(', ''],
      ['  actor: &Principal, snap: &Snapshot,', ''],
      ['  cmd: &Command,', ''],
      [') -> Outcome {', ''],
      ['  match cmd {', ''],
      ['    Command::Delete { id } => {', 'delete'],
      ['      let doc = find(&snap.docs, *id)?;', 'find'],
      ['      if !can_delete(actor, doc) {', 'guard'],
      ['        return Err(Error::Forbidden);', 'guard'],
      ['      }', 'guard'],
      ['      Ok((del(doc.id), Reply::Deleted))', 'write'],
      ['    }', 'delete'],
      ['  }', ''],
      ['}', ''],
    ],
    brokenRust: [
      ['pub fn transition(', ''],
      ['  actor: &Principal, snap: &Snapshot,', ''],
      ['  cmd: &Command,', ''],
      [') -> Outcome {', ''],
      ['  match cmd {', ''],
      ['    Command::Delete { id } => {', 'delete'],
      ['      let doc = find(&snap.docs, *id)?;', 'find'],
      ['      // permission check removed', 'broken'],
      ['      Ok((del(doc.id), Reply::Deleted))', 'broken'],
      ['    }', 'delete'],
      ['  }', ''],
      ['}', ''],
    ],
    lean: [
      ['theorem writes_authorized', ''],
      ['    (h : transition actor snap cmd =', ''],
      ['      .ok (writes, reply)) :', ''],
      ['    ∀ write ∈ writes,', 'write'],
      ['      Allowed actor snap write := by', 'write'],
      ['  cases cmd with', ''],
      ['  | Delete id =>', 'delete'],
      ['    simp only [transition] at h', 'delete'],
      ['    split at h <;> simp_all', 'find'],
      ['    · exact delete_allowed_of_can_delete', 'guard'],
      ['    · contradiction', 'guard'],
    ],
    title: 'Every successful write is authorized.',
    copy: 'The theorem covers every actor, reachable state, command, and write the kernel can return.',
    theorem: 'writes_authorized',
    failedTitle: 'The delete policy has a counterexample.',
    failedCopy: 'A user without delete permission can now produce a successful delete write, so Lean rejects the theorem.',
  },
  invariant: {
    rust: [
      ['fn transfer(s: &Snapshot, amount: u64)', ''],
      ['  -> Outcome {', ''],
      ['  if amount > s.sender.balance {', 'guard'],
      ['    return Err(Error::Insufficient);', 'guard'],
      ['  }', 'guard'],
      ['  let sender = s.sender.balance - amount;', 'write'],
      ['  let recipient =', 'write'],
      ['    s.recipient.balance.checked_add(amount)', 'overflow'],
      ['      .ok_or(Error::Overflow)?;', 'overflow'],
      ['  Ok((update(sender, recipient), Reply::Ok))', 'write'],
      ['}', ''],
    ],
    brokenRust: [
      ['fn transfer(s: &Snapshot, amount: u64)', ''],
      ['  -> Outcome {', ''],
      ['  // balance guard removed', 'broken'],
      ['  let sender =', 'broken'],
      ['    s.sender.balance.wrapping_sub(amount);', 'broken'],
      ['  let recipient =', 'write'],
      ['    s.recipient.balance.checked_add(amount)', 'overflow'],
      ['      .ok_or(Error::Overflow)?;', 'overflow'],
      ['  Ok((update(sender, recipient), Reply::Ok))', 'write'],
      ['}', ''],
    ],
    lean: [
      ['theorem transfer_preserves_total', ''],
      ['    (hinv : TotalIs initialTotal s)', ''],
      ['    (ht : transfer s amount =', ''],
      ['      .ok (writes, .Ok))', 'write'],
      ['    (ha : apply s writes = .ok s\') :', 'write'],
      ['    TotalIs initialTotal s\' := by', ''],
      ['  have hle : amount ≤ s.sender.balance :=', 'guard'],
      ['    accepted_implies_sufficient ht', 'guard'],
      ['  have hsafe := no_overflow_of_success ht', 'overflow'],
      ['  omega', 'write'],
    ],
    title: 'The total balance is conserved.',
    copy: 'Every successful transfer preserves the sum while preventing underflow and overflow.',
    theorem: 'transfer_preserves_total',
    failedTitle: 'Conservation can no longer be proved.',
    failedCopy: 'Wrapping subtraction admits transfers larger than the sender’s balance, breaking the total-balance invariant.',
  },
};

const rustCode = document.querySelector('#rust-code');
const leanCode = document.querySelector('#lean-code');
const breakInput = document.querySelector('#break-code');
const result = document.querySelector('.proof-result');
const resultTitle = document.querySelector('#result-title');
const resultCopy = document.querySelector('#result-copy');
const resultTheorem = document.querySelector('#result-theorem');
let activeExample = 'isolation';

const escapeHtml = (text) => text
  .replaceAll('&', '&amp;')
  .replaceAll('<', '&lt;')
  .replaceAll('>', '&gt;');

function syntax(text) {
  let output = escapeHtml(text);
  const comments = [];
  output = output.replace(/(\/\/.*)$/g, (match) => {
    comments.push(match);
    return `__COMMENT_${comments.length - 1}__`;
  });
  output = output
    .replace(/\b(pub|fn|let|match|if|return|use|theorem|exact|by|cases|with|have|split|at|∀|in|where)\b/g, '<span class="syn-key">$1</span>')
    .replace(/\b(Result|Error|Outcome|Command|Principal|Snapshot|Statement|Schema|Select|Tables|Val|Allowed|TotalIs|Reply|Pg|Sql)\b/g, '<span class="syn-type">$1</span>')
    .replace(/\b(transition|compile|tenantRows|exec|find|can_delete|del|transfer|update|apply|omega)\b/g, '<span class="syn-fn">$1</span>')
    .replace(/\b(ok|true|false|none|some|u64|vec)\b/g, '<span class="syn-lit">$1</span>')
    .replace(/__COMMENT_(\d+)__/g, (_, index) => `<span class="syn-comment">${comments[Number(index)]}</span>`);
  return output || '&nbsp;';
}

function renderLines(element, lines) {
  element.innerHTML = lines.map(([text, link], index) =>
    `<span class="code-line" data-line="${String(index + 1).padStart(2, '0')}"${link ? ` data-link="${link}"` : ''}>${syntax(text)}</span>`
  ).join('');
}

function bindLineLinks() {
  document.querySelectorAll('.code-line[data-link]').forEach((line) => {
    line.addEventListener('mouseenter', () => setLinkActive(line.dataset.link, true));
    line.addEventListener('mouseleave', () => setLinkActive(line.dataset.link, false));
    line.addEventListener('focus', () => setLinkActive(line.dataset.link, true));
    line.addEventListener('blur', () => setLinkActive(line.dataset.link, false));
  });
}

function setLinkActive(link, isActive) {
  document.querySelectorAll(`.code-line[data-link="${link}"]`).forEach((line) => {
    line.classList.toggle('link-active', isActive);
  });
}

function renderExample() {
  const data = examples[activeExample];
  const isBroken = breakInput.checked;
  renderLines(rustCode, isBroken ? data.brokenRust : data.rust);
  renderLines(leanCode, data.lean);
  result.classList.toggle('failed', isBroken);
  resultTitle.textContent = isBroken ? data.failedTitle : data.title;
  resultCopy.textContent = isBroken ? data.failedCopy : data.copy;
  resultTheorem.textContent = isBroken ? 'counterexample found' : data.theorem;
  const icon = result.querySelector('.result-symbol svg');
  icon.innerHTML = isBroken ? '<path d="M7 7l10 10M17 7 7 17" />' : '<path d="m5 12 4.5 4.5L19 7" />';
  result.querySelector('.result-label').textContent = isBroken ? 'LEAN / REJECTED' : 'LEAN / CHECKED';
  bindLineLinks();
}

document.querySelectorAll('.example-tab').forEach((tab) => {
  tab.addEventListener('click', () => {
    activeExample = tab.dataset.example;
    document.querySelectorAll('.example-tab').forEach((item) => {
      const selected = item === tab;
      item.classList.toggle('active', selected);
      item.setAttribute('aria-selected', String(selected));
    });
    renderExample();
  });
});

breakInput.addEventListener('change', renderExample);
renderExample();

const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
if (!reducedMotion) {
  window.addEventListener('pointermove', (event) => {
    const x = (event.clientX / window.innerWidth - .5) * 10;
    const y = (event.clientY / window.innerHeight - .5) * 7;
    document.querySelector('.caustics').style.transform = `translate(${x}px, ${y}px)`;
  }, { passive: true });
}
