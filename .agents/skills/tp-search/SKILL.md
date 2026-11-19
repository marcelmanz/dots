---
name: tp-search
description: Search TargetProcess tickets by text to see how a feature is progressing across teams and branches. Use when the user asks to investigate ticket status, check whether work on a topic already exists or is in progress, or says "tp-search", "target process", "search tickets", before planning a feature.
---

# TargetProcess ticket search

Run `~/scripts/work/tp-search.sh` to list tickets whose name or description
mention a term. Use it before planning so the plan reflects work already in
flight.

## Usage

```
~/scripts/work/tp-search.sh [-t team]... [-o] term [term...]
```

- `-t team` limits to a team name (repeatable).
- `-o` hides tickets in a final state.
- Terms are OR-ed and matched against name and description.

Output is TSV: id, type, state, team, owner, name.

## Process

1. Pick several related terms (for example `timezone`, `time zone`, `tz`,
   `ntp`) and run one search with all of them, first with `-o`, then without
   to see what is already done.
2. Group results by team (frontend, backend, network manager) and state.
3. For each relevant ticket, look for a matching branch in the related repos
   under `~/clones/work` (`git branch -a | grep -i <term>`, `git log --all
   --grep`) to see how far it has progressed.
4. Summarise: ticket, state, owner, branch, and what it implies for the plan.

## Notes

- The token comes from `rbw get target-process/token`. If it fails, tell the
  user to unlock rbw.
- Read-only; never modify tickets.
