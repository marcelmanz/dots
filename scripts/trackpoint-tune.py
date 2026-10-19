#!/usr/bin/env python3
"""Endless click-target game that blindly cycles trackpoint curves in Hyprland and keeps the one you score best on.

Run it, play in the browser tab, Ctrl-C to quit (applies the best curve). Results persist across runs.
"""
import json
import math
import random
import subprocess
import sys
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

DEVICE = "tpps/2-elan-trackpoint"
STATE_FILE = Path.home() / ".local/state/trackpoint-tune.json"
PORT = 8765
FACTORS = [1.6, 1.9, 2.2, 2.5, 2.8]
RAMPS = [0.0, 0.2, 0.4]
EXPLORATION = 0.5


def curve(factor, ramp):
    points = [v * factor * (1 + ramp * v / 5) for v in range(6)]
    return "custom 1 " + " ".join(f"{p:.2f}" for p in points)


CANDIDATES = {f"x{f} ramp{r}": curve(f, r) for f in FACTORS for r in RAMPS}


def mean(scores):
    return sum(scores) / len(scores)


def pick_next(state, rng=random):
    untested = [k for k in CANDIDATES if not state.get(k)]
    if untested:
        return rng.choice(untested)
    total = sum(len(state[k]) for k in CANDIDATES)
    return max(CANDIDATES, key=lambda k: mean(state[k]) + EXPLORATION * math.sqrt(math.log(total) / len(state[k])))


def best(state):
    tested = [k for k in CANDIDATES if state.get(k)]
    return max(tested, key=lambda k: mean(state[k])) if tested else None


def table(state):
    rows = [{"key": k, "runs": len(state.get(k, [])), "score": round(mean(state[k]), 2) if state.get(k) else None}
            for k in CANDIDATES]
    return sorted(rows, key=lambda r: -(r["score"] or 0))


def apply(key):
    lua = f'hl.device({{ name = "{DEVICE}", accel_profile = "{CANDIDATES[key]}", sensitivity = 0 }})'
    result = subprocess.run(["hyprctl", "eval", lua], check=False, capture_output=True, text=True)
    return result.returncode == 0 and result.stdout.strip() == "ok"


def load_state():
    try:
        return json.loads(STATE_FILE.read_text())
    except (OSError, ValueError):
        return {}


def save_state(state):
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, indent=1))


state = load_state()
current = None


def next_round():
    global current
    current = pick_next(state)
    return {"table": table(state), "applied": apply(current)}


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def send(self, body, content_type="application/json"):
        data = body.encode() if isinstance(body, str) else json.dumps(body).encode()
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/next":
            self.send(next_round())
        else:
            self.send(PAGE, "text/html; charset=utf-8")

    def do_POST(self):
        body = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or b"{}")
        if self.path == "/result":
            score = float(body["score"])
            if current and math.isfinite(score):
                state.setdefault(current, []).append(score)
                save_state(state)
            self.send(next_round())
        elif self.path == "/apply-best":
            key = best(state)
            if key:
                apply(key)
            self.send({"key": key, "curve": CANDIDATES.get(key)})


PAGE = """<!doctype html>
<title>Trackpoint Tune</title>
<style>
:root { --bg: #f3f4f1; --fg: #1d2420; --muted: #67706a; --target: #c2410c; --panel: #ffffffd9; }
@media (prefers-color-scheme: dark) { :root { --bg: #151917; --fg: #e4e8e5; --muted: #8b958f; --target: #fb923c; --panel: #1f2522d9; color-scheme: dark; } }
html, body { margin: 0; height: 100%; overflow: hidden; background: var(--bg); color: var(--fg); font: 14px system-ui, sans-serif; }
canvas { display: block; width: 100vw; height: 100vh; cursor: crosshair; }
#hud { position: fixed; top: 12px; left: 16px; color: var(--muted); font-variant-numeric: tabular-nums; pointer-events: none; }
#panel { position: fixed; bottom: 12px; right: 16px; background: var(--panel); padding: 10px 14px; border-radius: 6px; font-variant-numeric: tabular-nums; }
table { border-collapse: collapse; } td, th { padding: 1px 8px; text-align: right; } th { color: var(--muted); font-weight: 500; }
td:first-child, th:first-child { text-align: left; }
button { margin-top: 8px; font: inherit; }
#best { margin-top: 6px; font-family: monospace; user-select: all; }
#toast { position: fixed; top: 12px; left: 50%; transform: translateX(-50%); background: var(--panel); padding: 8px 14px; border-radius: 6px; pointer-events: none; transition: opacity .3s; }
#toast.error { color: var(--target); }
</style>
<canvas id="c"></canvas>
<div id="hud"></div>
<div id="toast" hidden></div>
<div id="panel">
  <table><thead><tr><th>curve</th><th>runs</th><th>bits/s</th></tr></thead><tbody id="rows"></tbody></table>
  <button id="apply">Apply best and stop testing</button>
  <div id="best"></div>
</div>
<script>
const WARMUP = 2, TRIALS = 12, RADII = [8, 14, 24], MIN_DIST = 120;
const canvas = document.getElementById("c"), ctx = canvas.getContext("2d");
let target = null, prevHit = null, trial = 0, bits = 0, seconds = 0, misses = 0, round = 0, lastScore = null, stopped = false;

function resize() {
  const dpr = devicePixelRatio || 1;
  canvas.width = innerWidth * dpr; canvas.height = innerHeight * dpr;
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0); draw();
}
function place() {
  const r = RADII[Math.floor(Math.random() * RADII.length)];
  let x, y;
  do {
    x = r + 20 + Math.random() * (innerWidth - 2 * r - 40);
    y = r + 50 + Math.random() * (innerHeight - 2 * r - 70);
  } while ((prevHit && Math.hypot(x - prevHit.x, y - prevHit.y) < MIN_DIST) || overlapsPanel(x, y, r));
  target = { x, y, r };
}
function overlapsPanel(x, y, r) {
  const box = document.getElementById("panel").getBoundingClientRect(), margin = r + 12;
  return x > box.left - margin && x < box.right + margin && y > box.top - margin && y < box.bottom + margin;
}
let toastTimer;
function toast(text, isError) {
  const el = document.getElementById("toast");
  el.textContent = text; el.classList.toggle("error", !!isError); el.hidden = false;
  clearTimeout(toastTimer); toastTimer = setTimeout(() => { el.hidden = true; }, isError ? 6000 : 2500);
}
function announce(data) {
  if (data.applied) toast(`Settings changed for round ${round}`);
  else toast("Could not apply settings: hyprctl eval failed. Is the script running inside your Hyprland session?", true);
}
function draw() {
  ctx.clearRect(0, 0, innerWidth, innerHeight);
  if (target && !stopped) {
    ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue("--target");
    ctx.beginPath(); ctx.arc(target.x, target.y, target.r, 0, 2 * Math.PI); ctx.fill();
  }
  const phase = trial < WARMUP ? "warm-up" : `${trial - WARMUP}/${TRIALS}`;
  document.getElementById("hud").textContent = stopped ? "Best curve applied. Press Continue testing to resume."
    : `round ${round} · ${phase}` + (lastScore ? ` · last round ${lastScore.toFixed(2)} bits/s` : "");
}
function showTable(rows) {
  document.getElementById("rows").innerHTML = rows.map(r =>
    `<tr><td>${r.key}</td><td>${r.runs}</td><td>${r.score ?? "-"}</td></tr>`).join("");
}
async function call(path, body) {
  const res = await fetch(path, body ? { method: "POST", body: JSON.stringify(body) } : {});
  return res.json();
}
async function finishRound() {
  lastScore = bits / seconds / (1 + misses / TRIALS);
  const data = await call("/result", { score: lastScore });
  showTable(data.table);
  trial = 0; bits = 0; seconds = 0; misses = 0; round++;
  announce(data);
}
canvas.addEventListener("mousedown", async e => {
  if (!target || stopped) return;
  const hit = Math.hypot(e.clientX - target.x, e.clientY - target.y) <= target.r;
  if (!hit) { if (trial >= WARMUP) misses++; return; }
  const now = performance.now();
  if (prevHit && trial >= WARMUP) {
    const distance = Math.hypot(target.x - prevHit.x, target.y - prevHit.y);
    bits += Math.log2(distance / (2 * target.r) + 1);
    seconds += (now - prevHit.t) / 1000;
  }
  prevHit = { x: e.clientX, y: e.clientY, t: now };
  trial++;
  if (trial >= WARMUP + TRIALS) await finishRound();
  place(); draw();
});
document.getElementById("apply").addEventListener("click", async e => {
  const button = e.currentTarget;
  if (stopped) {
    const data = await call("/next");
    showTable(data.table);
    stopped = false; prevHit = null; trial = 0; bits = 0; seconds = 0; misses = 0;
    button.textContent = "Apply best and stop testing";
    document.getElementById("best").textContent = "";
    announce(data); place(); draw();
    return;
  }
  const data = await call("/apply-best", {});
  stopped = true;
  button.textContent = "Continue testing";
  document.getElementById("best").textContent = data.curve ? `${data.key}: accel_profile = "${data.curve}"` : "No results yet.";
  draw();
});
addEventListener("resize", resize);
call("/next").then(data => { showTable(data.table); round = 1; announce(data); place(); resize(); });
</script>
"""


def self_check():
    for c in CANDIDATES.values():
        points = [float(p) for p in c.split()[2:]]
        assert points == sorted(points) and points[0] == 0
    rng = random.Random(0)
    partial = {k: [1.0] for k in list(CANDIDATES)[:-1]}
    assert pick_next(partial, rng) == list(CANDIDATES)[-1]
    full = {k: [1.0] * 20 for k in CANDIDATES}
    full["x2.2 ramp0.2"] = [5.0] * 20
    assert pick_next(full, rng) == "x2.2 ramp0.2" == best(full)
    print("ok")


if __name__ == "__main__":
    if "--test" in sys.argv:
        self_check()
        sys.exit()
    server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
    print(f"http://127.0.0.1:{PORT}  (Ctrl-C applies the best curve and quits)")
    webbrowser.open(f"http://127.0.0.1:{PORT}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        key = best(state)
        if key:
            apply(key)
            print(f"\napplied {key}: accel_profile = \"{CANDIDATES[key]}\"")
