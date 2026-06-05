---
name: changelog-enrich
description: >
  Enrich CHANGELOG.md entries with concise context derived from git commits.
  Surgically adds essential missing info to vague bullets without rewriting base text.
  Use when user says "enrich changelog", "add context to changelog", "fill in changelog
  details from commits", or invokes /changelog-enrich. Optionally scoped to a specific
  version section (e.g. "enrich 0.31.0").
---

# changelog-enrich

Enrich `CHANGELOG.md` entries with context from git commits. Goal: make vague bullets understandable without bloating the changelog or rewriting curated wording.

## Core rules

- **Do not rewrite base text.** Keep existing wording intact. Append a short inline clarification only when the original is unclear standalone.
- **Only edit entries that lack context.** If a bullet already conveys what changed, leave it alone.
- **Inline additions, not sub-bullets.** Append a short parenthetical or a few words after the existing text. No new lines, no nested lists, no extra sections.
- **Source of truth = commits.** Pull context from commit subjects, bodies, and (when needed) diffs/stats. Never invent rationale.
- **No category changes.** Keep entries under their existing `Added`/`Changed`/`Fixed`/`Removed` headings. Do not reorder.
- **No emojis.** Match the project's existing changelog style.
- **Minimal diff.** Final patch should touch only the lines that needed enrichment.

## Workflow

1. **Locate target section.** Read `CHANGELOG.md`. If user named a version, jump to that section header. Otherwise default to the topmost version section.
2. **Resolve commit range.** Find the previous version tag/section and use `git log --no-ext-diff <prev>..HEAD` (or `<prev>..<target-tag>` if the target is already released). If no tag exists, ask the user for the range.
3. **List commits with bodies.**
   ```
   git log --no-ext-diff --format='%h%n%s%n%b%n---' <range>
   ```
4. **Triage entries.** For each bullet in the target section, decide:
   - Clear standalone → skip.
   - Vague / single-word / acronym-only / missing the "what" → mark for enrichment.
5. **Gather context for vague entries only.** Match bullet text to commit(s) by keyword. If subject + body is still unclear, run `git show --no-ext-diff --stat <sha>` and, when needed, `git show --no-ext-diff <sha>` (limit output).
6. **Draft inline additions.** Each addition: ≤ ~15 words, factual, references the concrete mechanism (function name, mode, status code, hook name) when that is what made the original vague.
7. **Apply edits via `Edit` tool** — one targeted `old_string`/`new_string` per bullet. Never use `Write` to overwrite the whole file.
8. **Report.** List which bullets were enriched. No summary of unchanged ones.

## Heuristics for "needs enrichment"

- One- or two-word bullets (e.g. `WifiNetworksList`, `Improve handlers`).
- Bare HTTP codes / error names without context (`422 and 429 ApiError`).
- "Improve X" / "Update Y" without saying how.
- References to renamed/new hooks or schemas the reader can't locate from the bullet alone.

## Heuristics for "leave alone"

- Already names the file/function/mode and the action.
- Bug fix where the title is the bug (e.g. `Toggle inverted logic`, `Empty password clearing credentials`).
- One-line entries that match a single self-explanatory commit subject.

## Style for additions

- Prefer concrete identifiers: function names, hook names, status codes, modes, file paths.
- No restating the verb already in the bullet. Add the missing object/mechanism.
- Parenthetical or trailing clause, lowercase unless proper noun. No trailing period unless the original had one.

### Examples

Original: `- 422 and 429 ApiError`
Enriched: `- 422 (UnprocessableContent) and 429 (TooManyRequests) ApiError subclasses`

Original: `- WifiNetworksList`
Enriched: `- WifiNetworksList row click handler extracted to memoized callback, disabled guard moved to prop`

Original: `- Http throws in multiple api calls`
Enriched: `- Http throws \`ApiError.fromResponse\` in multiple api calls (connect, delete, scan, status) instead of generic Error`

Original: `- Toggle inverted logic` → leave alone (clear).

## Boundaries

- Never reorder, regroup, or split bullets.
- Never add bullets that aren't already there (missing items belong in a separate "write changelog" task).
- Never touch sections outside the target version.
- If a bullet's commit cannot be found, leave the bullet unchanged and note it in the report.
