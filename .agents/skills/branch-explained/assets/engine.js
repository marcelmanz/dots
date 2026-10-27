/* Generic engine for the branch explainer page.
   Needs window.COMMITS / window.FILES (data.js, from gen_data.py) and window.PAGE (content.js):
   PAGE = {
     lang: "cpp" | "c" | "ts" | "js" | "python" | "go" | "rust" | "java" | "kotlin" | "csharp" | "shell" | "nix",
     phases: { 1: { name, desc }, ... },                       // colours assigned in order
     notes: { "<short hash>": { p, what, why, watch? } },      // HTML strings, one per commit
     codeNotes: { "<repo path>": [{ from, to, c, t }] },        // line ranges in the final file
     scenarios: { key: { title, init, threads: [{ name, code: [] }], steps: [{ t, l, s?, say, bad?, good? }] } },
   }
   Everything is optional except the data; widgets init only when their elements exist. */

const PAGE = window.PAGE || {};
const COMMITS = window.COMMITS || [];
const FILES = window.FILES || {};
const PHASE_COLORS = ["var(--p1)", "var(--p2)", "var(--p3)", "var(--p4)", "var(--p5)", "var(--p6)", "var(--p7)", "var(--p8)"];
const PHASES = {};
Object.entries(PAGE.phases || { 1: { name: "Commits", desc: "" } }).forEach(([k, v], i) => PHASES[k] = Object.assign({ color: PHASE_COLORS[i % PHASE_COLORS.length] }, v));
const firstPhase = Object.keys(PHASES)[0];

const commitByHash = {};
COMMITS.forEach((c, i) => {
  c.idx = i;
  c.note = (PAGE.notes || {})[c.hash] || { p: firstPhase, what: "", why: "" };
  if (!PHASES[c.note.p]) c.note.p = firstPhase;
  commitByHash[c.hash] = c;
});

function esc(s) { return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;"); }
function phaseColor(hash) { const c = commitByHash[hash]; return c ? PHASES[c.note.p].color : "var(--line)"; }

/* nav: built from the sections' first heading */
(function () {
  const nav = document.getElementById("navLinks");
  if (!nav) return;
  const sections = [...document.querySelectorAll("main > section[id]")];
  nav.innerHTML = sections.map(s => {
    const h = s.querySelector("h1, h2");
    const label = s.dataset.nav || (h ? h.textContent.trim() : s.id);
    return `<a href="#${s.id}">${esc(label)}</a>`;
  }).join("");
  const links = [...nav.querySelectorAll("a")];
  const obs = new IntersectionObserver(entries => entries.forEach(en => {
    if (en.isIntersecting) links.forEach(a => a.classList.toggle("active", a.getAttribute("href") === "#" + en.target.id));
  }), { rootMargin: "-20% 0px -70% 0px" });
  sections.forEach(s => obs.observe(s));
})();

/* commit links: any element with class chash and data-c="<hash>" */
function openCommit(hash) {
  if (activePhase && commitByHash[hash] && String(commitByHash[hash].note.p) !== String(activePhase)) {
    activePhase = 0;
    document.querySelectorAll("#phaseFilter button").forEach(x => x.classList.toggle("on", x.dataset.p === "0"));
    renderCommits();
  }
  const el = document.getElementById("c-" + hash);
  if (!el) return;
  el.classList.add("open", "flash");
  el.scrollIntoView({ behavior: "smooth", block: "start" });
  setTimeout(() => el.classList.remove("flash"), 1600);
}
function bindHashes(root) {
  root.querySelectorAll(".chash").forEach(h => {
    const c = commitByHash[h.dataset.c];
    if (c) h.title = c.subject;
    h.onclick = () => openCommit(h.dataset.c);
  });
}

/* syntax highlighting: single pass, so inserted spans are never re-matched */
const LANGS = {
  cpp: { kw: "if|else|while|for|do|switch|case|default|return|break|continue|const|constexpr|auto|void|struct|class|public|private|protected|namespace|static|this|true|false|using|override|new|delete|typename|template|virtual|noexcept|nullptr|try|catch|throw|enum|inline|mutable|explicit|operator", ty: "std::[A-Za-z_:]+|u?int(?:8|16|32|64)_t|size_t|double|float|bool|int|unsigned|long|char|short", line: "//" },
  c: { kw: "if|else|while|for|do|switch|case|default|return|break|continue|const|void|struct|static|enum|union|typedef|sizeof|extern|inline|goto|NULL", ty: "u?int(?:8|16|32|64)_t|size_t|double|float|bool|int|unsigned|long|char|short", line: "//" },
  ts: { kw: "if|else|while|for|do|switch|case|default|return|break|continue|const|let|var|function|class|extends|implements|interface|type|enum|import|export|from|as|new|this|true|false|null|undefined|async|await|try|catch|finally|throw|typeof|instanceof|in|of|readonly|public|private|protected|static|yield", ty: "string|number|boolean|void|unknown|any|never|Promise|Array|Record|Map|Set|Partial|Readonly", line: "//" },
  python: { kw: "if|elif|else|while|for|in|return|break|continue|def|class|import|from|as|with|try|except|finally|raise|lambda|yield|async|await|not|and|or|is|None|True|False|pass|global|nonlocal|self", ty: "int|float|str|bool|list|dict|tuple|set|bytes|Optional|Any|Callable", line: "#" },
  go: { kw: "if|else|for|range|switch|case|default|return|break|continue|func|go|defer|select|chan|var|const|type|struct|interface|package|import|map|nil|true|false", ty: "string|int|int64|int32|uint|uint64|uint32|float64|bool|byte|rune|error|any", line: "//" },
  rust: { kw: "if|else|while|for|loop|in|match|return|break|continue|fn|let|mut|const|static|struct|enum|trait|impl|pub|use|mod|crate|self|Self|super|as|ref|move|async|await|unsafe|where|dyn|true|false", ty: "u8|u16|u32|u64|usize|i8|i16|i32|i64|isize|f32|f64|bool|char|str|String|Vec|Option|Result|Box|Rc|Arc|Mutex", line: "//" },
  java: { kw: "if|else|while|for|do|switch|case|default|return|break|continue|class|interface|enum|extends|implements|new|this|super|public|private|protected|static|final|abstract|synchronized|volatile|try|catch|finally|throw|throws|import|package|true|false|null|var|record", ty: "int|long|double|float|boolean|char|byte|short|void|String|List|Map|Set|Optional", line: "//" },
  shell: { kw: "if|then|else|elif|fi|for|while|do|done|case|esac|in|function|return|local|export|readonly|set|unset", ty: "", line: "#" },
  nix: { kw: "let|in|with|rec|inherit|if|then|else|import|true|false|null|assert", ty: "", line: "#" },
};
LANGS.js = LANGS.ts; LANGS.kotlin = LANGS.java; LANGS.csharp = LANGS.java; LANGS.h = LANGS.cpp;
const LANG = LANGS[PAGE.lang] || LANGS.cpp;
const TOKENS = new RegExp(`\\b(${LANG.kw})\\b` + (LANG.ty ? `|\\b(${LANG.ty})\\b` : "|(?!x)x()") + `|\\b(\\d+(?:\\.\\d+)?)\\b`, "g");
function hl(line) {
  const t = line.trim();
  if (t.startsWith(LANG.line) || t.startsWith("/*") || t.startsWith("*") || t.startsWith('"""')) return `<span class="cm">${esc(line)}</span>`;
  let rest = line, comment = "";
  const ci = rest.indexOf(" " + LANG.line);
  if (ci >= 0 && (rest.slice(0, ci).split('"').length % 2 === 1)) { comment = rest.slice(ci); rest = rest.slice(0, ci); }
  const parts = rest.split(/("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|`[^`]*`)/);
  const out = parts.map((p, i) => i % 2 ? `<span class="st">${esc(p)}</span>` :
    esc(p).replace(TOKENS, (m, kw, ty, nu) => kw ? `<span class="kw">${kw}</span>` : ty ? `<span class="ty">${ty}</span>` : nu ? `<span class="nu">${nu}</span>` : m)).join("");
  return out + (comment ? `<span class="cm">${esc(comment)}</span>` : "");
}

/* code explorer with click tooltip */
let currentFile = Object.keys(FILES)[0];
function noteFor(file, n) {
  const notes = ((PAGE.codeNotes || {})[file] || []).filter(x => n >= x.from && n <= x.to);
  notes.sort((a, b) => (a.to - a.from) - (b.to - b.from));
  return notes[0];
}
function hideTip() {
  const tip = document.getElementById("codeTip");
  if (tip) tip.hidden = true;
  document.querySelectorAll("#codeView .ln.hl").forEach(x => x.classList.remove("hl"));
}
function showTip(lineEl, html, clickX) {
  const tip = document.getElementById("codeTip");
  tip.innerHTML = `<button class="close" title="Close">&times;</button>` + html;
  tip.querySelector(".close").onclick = hideTip;
  bindHashes(tip);
  tip.hidden = false;
  const r = lineEl.getBoundingClientRect(), w = tip.offsetWidth, h = tip.offsetHeight;
  const left = Math.min(Math.max(16, clickX - 40), document.documentElement.clientWidth - w - 16);
  const below = r.bottom + 10 + h < window.innerHeight || r.top - 10 - h < 0;
  tip.classList.toggle("above", !below);
  tip.style.left = (left + window.scrollX) + "px";
  tip.style.top = ((below ? r.bottom + 10 : r.top - 10 - h) + window.scrollY) + "px";
  tip.style.setProperty("--arrow-left", Math.min(Math.max(12, clickX - left - 6), w - 24) + "px");
}
function renderFile(file) {
  currentFile = file;
  document.querySelectorAll("#fileTabs button").forEach(b => b.classList.toggle("on", b.dataset.f === file));
  const f = FILES[file];
  document.getElementById("codeView").innerHTML = '<div class="code-inner">' + f.lines.map((l, i) => {
    const n = i + 1, h = f.blame[i] || "";
    return `<div class="ln${noteFor(file, n) ? " ann" : ""}" data-n="${n}"><span style="background:${phaseColor(h)}"></span><span class="no">${n}</span><span class="bl">${h}</span><span>${hl(l) || " "}</span></div>`;
  }).join("") + "</div>";
  hideTip();
}
(function () {
  const view = document.getElementById("codeView"), tabs = document.getElementById("fileTabs");
  if (!view || !tabs || !currentFile) return;
  tabs.innerHTML = Object.keys(FILES).map(f => `<button data-f="${f}">${f}</button>`).join("");
  tabs.querySelectorAll("button").forEach(b => b.addEventListener("click", () => renderFile(b.dataset.f)));
  view.addEventListener("click", e => {
    const ln = e.target.closest(".ln"); if (!ln) return;
    const n = Number(ln.dataset.n), h = FILES[currentFile].blame[n - 1], note = noteFor(currentFile, n);
    view.querySelectorAll(".ln").forEach(x => {
      const m = Number(x.dataset.n);
      x.classList.toggle("hl", note ? (m >= note.from && m <= note.to) : m === n);
    });
    const c = commitByHash[h];
    let html = `<div class="muted mono">${currentFile}:${note ? note.from + "-" + note.to : n}</div>`;
    html += note ? `<p>${note.t}</p><p class="muted">Shaped by <span class="chash" data-c="${note.c}">${note.c}</span> ${esc(commitByHash[note.c]?.subject || "")}</p>` : `<p class="muted">No specific note for this line.</p>`;
    html += `<hr style="border:0;border-top:1px solid var(--line)"><div class="muted">This exact line was last changed in</div>`;
    html += c ? `<p><span class="chash" data-c="${h}">${h}</span> <b>${esc(c.subject)}</b> <span class="pill">${esc(PHASES[c.note.p].name)}</span></p><p>${c.note.why || ""}</p>` : `<p class="mono">${h} (before this branch)</p>`;
    showTip(ln, html, e.clientX);
  });
  view.addEventListener("scroll", hideTip);
  document.addEventListener("keydown", e => { if (e.key === "Escape") hideTip(); });
  document.addEventListener("click", e => { if (!e.target.closest("#codeTip") && !e.target.closest("#codeView .ln")) hideTip(); });
  renderFile(currentFile);
})();

/* commit story */
let activePhase = 0;
function renderDiff(diff) {
  return diff.split("\n").map(l => {
    if (l.startsWith("diff --git")) return `<div class="f">${esc(l.replace(/^diff --git a\/(\S+) b\/.*/, "$1"))}</div>`;
    if (/^(index |--- |\+\+\+ |new file|deleted file|similarity|rename )/.test(l)) return "";
    const c = l.startsWith("@@") ? "h" : l.startsWith("+") ? "a" : l.startsWith("-") ? "d" : "";
    return `<div class="${c}">${esc(l) || " "}</div>`;
  }).join("");
}
function renderCommits() {
  const list = document.getElementById("commitList");
  if (!list) return;
  let lastPhase = null, html = "";
  COMMITS.forEach(c => {
    if (activePhase && String(c.note.p) !== String(activePhase)) return;
    if (c.note.p !== lastPhase) {
      lastPhase = c.note.p;
      const ph = PHASES[lastPhase];
      html += `<h3 style="display:flex;align-items:center;gap:8px"><span class="dot" style="background:${ph.color}"></span>Phase ${lastPhase}: ${esc(ph.name)} <span class="muted" style="font-weight:400;font-size:14px">${ph.desc || ""}</span></h3>`;
    }
    const files = c.stat.split("\n").slice(0, -1).map(s => s.split("|")[0].trim()).join(", ");
    html += `<div class="commit" id="c-${c.hash}">
      <div class="commit-head"><span class="dot" style="background:${PHASES[c.note.p].color}"></span><span class="mono" style="color:var(--accent)">${c.hash}</span><span class="date muted">${c.date}</span><span>${esc(c.subject)}</span><span class="pill">#${c.idx + 1}</span></div>
      <div class="commit-body">
        <p class="muted mono" style="font-size:12px">${esc(files)}</p>
        ${c.note.what ? `<p><b>What:</b> ${c.note.what}</p>` : ""}
        ${c.note.why ? `<div class="why"><b>Why:</b> ${c.note.why}</div>` : ""}
        ${c.note.watch ? `<div class="watch"><b>Watch:</b> ${c.note.watch}</div>` : ""}
        <details><summary style="cursor:pointer;margin:8px 0">Diff</summary><div class="diff">${renderDiff(c.diff)}</div></details>
      </div></div>`;
  });
  list.innerHTML = html;
  list.querySelectorAll(".commit-head").forEach(h => h.addEventListener("click", () => h.parentElement.classList.toggle("open")));
  bindHashes(list);
}
(function () {
  const filter = document.getElementById("phaseFilter"), bar = document.getElementById("phaseBar");
  if (filter) {
    filter.innerHTML = `<button data-p="0" class="on">All</button>` + Object.entries(PHASES).map(([k, v]) => `<button data-p="${k}"><span class="dot" style="display:inline-block;width:9px;height:9px;background:${v.color};margin-right:6px"></span>${esc(v.name)}</button>`).join("");
    filter.querySelectorAll("button").forEach(b => b.addEventListener("click", () => {
      activePhase = b.dataset.p === "0" ? 0 : b.dataset.p;
      filter.querySelectorAll("button").forEach(x => x.classList.toggle("on", x === b));
      renderCommits();
    }));
  }
  if (bar) {
    bar.innerHTML = COMMITS.map(c => `<div title="${c.hash} ${esc(c.subject)}" style="flex:1;background:${PHASES[c.note.p].color};cursor:pointer" data-c="${c.hash}"></div>`).join("");
    bar.querySelectorAll("div").forEach(d => d.addEventListener("click", () => openCommit(d.dataset.c)));
  }
  renderCommits();
})();

/* step-through players: <div class="player" data-scenarios="key1,key2"></div> */
function initPlayer(el) {
  const SCEN = PAGE.scenarios || {};
  const keys = el.dataset.scenarios.split(",").filter(k => SCEN[k]);
  if (!keys.length) return;
  let key = keys[0], idx = 0;
  el.innerHTML = `${keys.length > 1 ? `<div class="tabs pl-tabs">${keys.map(k => `<button data-k="${k}">${esc(SCEN[k].title)}</button>`).join("")}</div>` : `<div class="pl-title">${esc(SCEN[key].title)}</div>`}
    <div class="pl-cols"></div>
    <div class="pl-bottom"><div class="pl-state"></div><div class="pl-say"></div></div>
    <div class="pl-ctrl"><button class="pl-prev">&larr; Prev</button><button class="pl-next primary">Next &rarr;</button><button class="pl-reset">Reset</button><span class="muted pl-count"></span></div>`;
  function render() {
    const sc = SCEN[key], state = Object.assign({}, sc.init || {}), cur = sc.threads.map(() => -1);
    el.querySelectorAll(".pl-tabs button").forEach(b => b.classList.toggle("on", b.dataset.k === key));
    for (let i = 0; i < idx; i++) { const st = sc.steps[i]; Object.assign(state, st.s || {}); cur[st.t] = st.l; }
    const last = sc.steps[idx - 1];
    const cols = el.querySelector(".pl-cols");
    cols.style.gridTemplateColumns = `repeat(${sc.threads.length}, 1fr)`;
    cols.innerHTML = sc.threads.map((th, ti) => `<div class="pl-col ${last && last.t === ti ? "active" : ""}"><div class="pl-name t${(ti % 2) + 1}c">${esc(th.name)}</div>${th.code.map((c, li) => `<div class="pl-line ${cur[ti] === li ? (last && last.t === ti ? "now" : "was") : ""}">${esc(c)}</div>`).join("")}</div>`).join("");
    el.querySelector(".pl-state").innerHTML = `<div class="muted" style="font-size:12px;margin-bottom:4px">state</div>` + Object.entries(state).map(([k, v]) => `<div class="pl-kv ${last && last.s && k in last.s ? "chg" : ""}"><span>${esc(k)}</span><b>${esc(v)}</b></div>`).join("");
    const say = el.querySelector(".pl-say");
    say.innerHTML = last ? last.say : "Press <b>Next</b> to run the first step.";
    say.className = "pl-say" + (last && last.bad ? " bad-box" : "") + (last && last.good ? " good-box" : "");
    el.querySelector(".pl-count").textContent = `step ${idx} / ${sc.steps.length}`;
    el.querySelector(".pl-prev").disabled = idx === 0;
    el.querySelector(".pl-next").disabled = idx === sc.steps.length;
    bindHashes(el);
  }
  el.querySelector(".pl-next").onclick = () => { idx++; render(); };
  el.querySelector(".pl-prev").onclick = () => { idx--; render(); };
  el.querySelector(".pl-reset").onclick = () => { idx = 0; render(); };
  el.querySelectorAll(".pl-tabs button").forEach(b => b.onclick = () => { key = b.dataset.k; idx = 0; render(); });
  render();
}
document.querySelectorAll(".player[data-scenarios]").forEach(initPlayer);

/* clickable diagrams: <svg class="arch" data-info="infoElId"> with <g class="box" data-k> and PAGE.arch[k] html */
document.querySelectorAll("svg.arch[data-info]").forEach(svg => {
  const info = document.getElementById(svg.dataset.info);
  svg.querySelectorAll(".box").forEach(b => b.addEventListener("click", () => {
    svg.querySelectorAll(".box").forEach(x => x.classList.remove("sel"));
    b.classList.add("sel");
    info.innerHTML = ((PAGE.arch || {})[b.dataset.k]) || "";
    bindHashes(info);
  }));
});

/* checklists remembered per browser: <ul class="check"><li><label><input type="checkbox" data-k="id"> ... */
document.querySelectorAll(".check input[data-k]").forEach(i => {
  const k = location.pathname + ":check:" + i.dataset.k;
  try { i.checked = localStorage.getItem(k) === "1"; } catch (e) {}
  i.addEventListener("change", () => { try { localStorage.setItem(k, i.checked ? "1" : "0"); } catch (e) {} });
});

bindHashes(document);
