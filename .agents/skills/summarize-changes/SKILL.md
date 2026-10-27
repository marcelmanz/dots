---
name: summarize-changes
description: Turn a set of code changes (usually a UI/style/design-token pass) into a CHANGES.md table of Change / Where in the UI / Before / After, with diffs for anything more than a simple value swap, so the user can visually follow each change in the running app. Use when the user asks to "summarize the changes", "create a changes table", "table of before/after", or wants a visual-review reference after implementing a ticket.
---

# Summarize Changes

Produce a `CHANGES.md` that lets someone click through the running app and
verify each change against a simple table, without re-reading every diff
hunk. This is a wrap-up artifact for work already implemented — not a plan,
not a todo list. If `PLAN.md`/`TODO.md` exist for the same work, use them for
context on intent, but the diff is the source of truth for what actually
changed.

## Process

1. **Get the diff.** Default to the uncommitted working-tree diff:
   `git diff --no-ext-diff` (add specific paths if the user scoped the work
   to certain files, or `git diff --no-ext-diff <base>...HEAD` if the change
   is already committed on a branch). Read the whole diff before writing
   anything.

2. **Group hunks into logical changes, not literal file edits.** The same
   conceptual change (e.g. a font-weight tweak) often lands in more than one
   file (a base component and a wrapper, or two sibling components with
   duplicated markup) — that is one row, not two. Conversely, one file can
   contain several unrelated changes — split those into separate rows.

3. **For each change, determine "Where in the UI" from the code, not the
   file path.** Read enough of the surrounding component/page to describe
   the on-screen location a non-engineer would recognize: "left sidebar
   navigation item text", "hovering a row in any data table", "the disabled
   state of any button" — not "SidebarMenuButton/index.tsx". If it's
   genuinely unclear where a token is consumed, say so rather than guessing
   confidently (e.g. "wherever the warning token is consumed — no UI surface
   currently uses it").

4. **Classify each change as simple or complex:**
   - **Simple** — a single value swapped (a color, a size, a font-weight
     keyword, an opacity, an alignment). Show it directly in the Before/After
     columns as short code-ticked values. No diff needed.
   - **Complex** — anything spanning multiple lines, restructuring markup,
     touching more than one class on the same element, or otherwise not
     reducible to "X became Y" in a few words. Put a short descriptive phrase
     in the Before/After columns (e.g. "Dark gray background, dark gray
     border/arrow" → "White background, bordered, shadowed, white arrow")
     and add a fenced ` ```diff ` block for it in a section below the table.

5. **Write `CHANGES.md`** (ask if a different filename/location fits better,
   otherwise default to the repo root) with this shape:

   ```
   # Changes: <short description of the overall work>

   | Change | Where in the UI | Before | After |
   | ------ | ---------------- | ------ | ----- |
   | ... one row per logical change, simple changes fully summarized here ... |

   ---

   ## Diffs for changes that are more than a single value swap

   ### <Change name> (`path/to/file.ext`)

   ```diff
   - old lines
   + new lines
   ```
   ```

   - Table rows stay terse — even complex changes get a short plain-language
     Before/After in the table; the diff section is the detail, not a
     duplicate of the table.
   - When a complex change spans multiple files (e.g. the same class edit
     duplicated in a base component and a wrapper), note the duplication in
     prose after the first diff rather than pasting the identical diff twice.
   - Order the table to roughly match how someone would encounter the
     changes navigating the app (top-level tokens/colors first, then
     component-level structural changes, then layout), not file order.

## What NOT to include

- Don't include unrelated formatting/lint-only diffs that aren't part of the
  requested change — if the diff contains noise, filter it out and mention
  you did so.
- Don't speculate about visual impact you haven't traced through the code
  (e.g. don't claim "this will look like CMT's tooltip" unless you actually
  compared against a spec/reference the user gave you) — describe what
  changed, not a subjective quality judgment.
- Don't re-explain the ticket or restate the plan — this file is about the
  diff, not the motivation.
