# Claude Instructions

When writing code:

- Don’t add comments unless I explicitly ask
- Don’t rename variables, functions, or identifiers unless I ask
- If showing a small change, don’t rewrite the full file
- Keep formatting consistent with the existing codebase
- Only provide explanations if I ask for them separately

# Project Context

This project prefers minimal diffs and clean patches.  
Follow Unix-style conventions: small, focused changes that are easy to review.
If the project has a flake.nix try to use nix develop to run commands.

