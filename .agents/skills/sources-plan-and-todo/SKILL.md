---
name: plan-and-todo
description: Generate PLAN.md, TODO.md and SOURCES.md for a feature in the user's house style. Use when the user asks to plan a feature, write a plan/todo, or break down work into a checklist. Input is a feature description; output is one or more of these files.
---

# Plan, Todo and Sources generator

Turn a feature description into a `PLAN.md` (design), a `TODO.md` (checklist), and a `SOURCES.md` (reference index of the files/lines the plan was based on), all matching the user's established style. Produce all three unless the user asks for a subset.

## TODO.md style

- Top-level `# TODO` heading.
- Every item is a checkbox: `- [ ]` (unchecked) or `- [x]` (done).
- Each item starts with a plain-English action lead, then the technical detail in the same line.
- No backticks around names, symbols, enums, or paths. Write them as plain words.
- No arrows (no `->`, `→`, `=>`).
- Nest sub-steps under their parent item, indented two spaces, also as checkboxes.
- Group related sub-steps under one parent; blank line between top-level groups.

Example:

```
# TODO

- [ ] Create mobile schemas file with enums and request/response models
  - [ ] ApnMode enum with auto and static values
  - [ ] MobileConfigRequest model with enabled, apn, optional pin, ipType, roaming

- [ ] Register mobile router in main
```

## PLAN.md style

- Title line `# Plan: <Feature Name>`.
- `## Goal` — 2-4 sentences: what endpoints/behavior, what it talks to, which existing pattern it follows.
- Contract section(s) describing the external interface (D-Bus, REST, DB, etc.) using tables and fenced JSON examples where it clarifies.
- `## Files to create / modify` — numbered list. Each entry names the file path, tags it NEW or MODIFY, and lists what goes in it as a sub-bullet list. Code snippets allowed here for concrete signatures/constants.
- `## Order of work` — numbered build sequence, usually mirroring the files list bottom-up dependency order.
- `## Open questions / assumptions` — bullets for anything unconfirmed, mapping decisions, or things deferred. State assumptions explicitly.
- Separate major sections with `---`.

PLAN.md is allowed backticks and code blocks (it is design doc, not the checklist). TODO.md is not.

## SOURCES.md style

A flat reference index of the existing files (with line numbers) that were read to write the plan — the patterns being mirrored, the contracts being followed, the spec. Goal: a reader can jump straight to each reference without re-searching.

- Title line `# Sources: <Feature Name>`.
- One Markdown table with columns: `Source` (path, with `:line` or `:start-end` when a specific span matters), `What it gives us` (concise, one line).
- Group rows loosely top-to-bottom by kind: patterns to mirror first, then contracts/specs, then wiring/registration points.
- Keep descriptions concrete: name the function/class/pattern, not "see this file".
- Backticks allowed (it is a reference doc, like PLAN.md).
- Only list sources actually used in the plan. No speculative or unread files.

Example:

```
# Sources: Modem (Mobile) Backend

| Source | What it gives us |
| ------ | ---------------- |
| `src/fusion_backend/routers/ethernet.py:14-22` | `get_*_dbus_client()` mock/real selector pattern to copy |
| `src/fusion_backend/dbus/network.py:36-55` | `DBusClient` base + `EthernetDBusClient` shape for the new client |
| `thread-x4-internal-API-network-manager.md:120-140` | Mobile `Configure` signature and `Configuration` property contract |
| `src/fusion_backend/main.py:66-72` | where routers are registered under `api_v1_router` |
```

## Process

1. If the feature description is thin, ask 1-2 questions to pin down the endpoints/interface and which existing pattern it mirrors. Otherwise proceed.
2. As you read existing code/specs to design the plan, note each file and the relevant line span — these become SOURCES.md.
3. Write `PLAN.md` first (it drives the todo). Derive `TODO.md` from the plan's files list and order of work, one checkbox per concrete step.
4. Keep TODO items at the granularity of the plan's sub-bullets, not whole files.
5. Write `SOURCES.md` from the references gathered in step 2, one row per file/span actually used.
