---
name: dive-in
description: Generate a DIVE_IN.md that explains how a subsystem actually works end to end — the protocol, the pipeline, and any unfamiliar technique it relies on — so the reader can understand it without re-reading every file. Use when the user says "dive in", "explain how X works", "I want to understand X properly", "walk me through X", or asks for a deep explanation document rather than a plan.
---

# Dive in

Produce `DIVE_IN.md`: a teaching document about one subsystem or flow. Not a plan, not
API reference, not a summary of a diff. The test it must pass: someone who has never
opened this code can read it once and then follow the real files without getting lost.

Write it only after reading the actual code on both sides of the boundary. Every claim
must be traceable to a file, and line references must be real.

## Scope

Take one flow end to end — a request from where it enters to where it produces its effect,
crossing every process, protocol and language boundary on the way. Do not document a
single file. Do not document "the module"; document what happens.

If the flow spans repos, cover all of them. Name the languages explicitly, and correct the
user if the premise is wrong (e.g. "the C++ service" that is actually Python) — quietly
inheriting a wrong mental model is the thing this document exists to prevent.

## Structure

1. `# Dive in: <what the flow does>` and one paragraph stating what is covered and what
   knowledge is assumed.
2. **The cast** — a table of the processes involved: name, language, where it runs, role.
3. **Primer** — a short section for each technology the reader may not know (D-Bus, SSE,
   SWUpdate, A/B partitions, async generators). Explain the concept from scratch, in the
   terms this codebase uses, and then *why this design chose it*. Skip nothing as obvious;
   include nothing the flow does not actually use.
4. **The producing side** — walk the pipeline in order. Use tables for enums, codes and
   step sequences. Quote short real excerpts, not invented ones.
5. **The consuming side** — same treatment. Explain any technique the reader must
   understand to modify it safely (queue bridges, generators, threadpool offloading,
   cleanup in `finally`).
6. **Timeline** — one ASCII sequence diagram of the whole flow, columns per process.
7. **Known breakage** — anything currently wrong, with the symptom first, then the cause.
   Point at the plan or ticket that fixes it. Omit the section if there is nothing.
8. **Seeing it for yourself** — the exact commands to observe the thing live: bus monitors,
   `curl -N`, mock mode, tests. Include the flags whose absence makes it look broken.
9. **Files worth reading, in order** — a table of path and why, ordered as a reading path.

Separate major sections with `---`.

## Style

- Explain *why*, not just *what*. A design decision without its reason is not understood.
- Call out the traps: the asymmetric contract, the thing that must happen before the other
  thing, the flag whose absence silently breaks it. These are the sentences that earn the
  document.
- Tables for anything enumerable. Prose for anything causal.
- Real code excerpts, kept short. Never paste a whole function when five lines carry it.
- Backticks and code blocks are fine — this is a design doc.
- No emojis.
- Second person, present tense, direct. No filler and no "in conclusion".

## Process

1. Read both sides of the boundary before writing a line. Note file and line spans as you
   go — the reading-path table and every reference come from these.
2. Trace one successful run and one failing run. The failure path is usually where the
   real contract lives.
3. Identify what the reader would have to already know, and write the primer for exactly
   that.
4. Write `DIVE_IN.md` at the repo root unless the user names another location.
5. If a `SOURCES.md` already exists for the same work, do not duplicate it — `DIVE_IN.md`
   explains, `SOURCES.md` indexes.
