# AGENTS.md

# General Instructions

When writing code:

- Don’t add comments unless I explicitly ask
- If you have already written a full example, don't rewrite it all again for a small change
- Don't change code names, variables, or functions unless explicitly requested
- If showing a small change, don’t rewrite the full file
- Keep formatting consistent with the existing codebase
- Only provide explanations if I ask for them separately
- Prefer descriptive variable names

## Code Style
- Follow project conventions for naming, formatting, and structure
- Keep code minimal and production-ready

## Testing
- Always explain how to run tests
- Prefer lightweight test examples unless asked otherwise

# Project Context

- Prefer minimal diffs and clean patches.
- Follow Unix-style conventions: small, focused changes that are easy to review.

If a repository includes a `flake.nix`, try to use `nix develop` to run commands.
If there is a `Makefile`, `Justfile`, or similar, check them first to see if common commands are already defined.
If both exist, prefer the project’s documented setup flow over inventing new commands.

## Reasoning
- Use concise explanations
- Show only the final answer unless step-by-step reasoning is requested
