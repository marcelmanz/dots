# AGENTS.md

# General Instructions

When writing code:

- Don’t add comments unless I explicitly ask, but mantain the comments that
  already existed on the code.
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

# Changelog Updates

When asked to write a new changelog entry:

* Automatically create a new version section at the top of `CHANGELOG.md`
* Follow [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
* Determine the next version based on the change type:
  * **Major**: Increment the first digit (e.g. `3.76.0` → `4.0.0`)
  * **Minor**: Increment the middle digit (e.g. `3.76.0` → `3.77.0`)
  * **Patch**: Increment the last digit (e.g. `3.76.0` → `3.76.1`)
* Use the **current date** in `YYYY-MM-DD` format
* Insert the new section **above all previous versions**
* Maintain this structure:
  ```
  ## <version> - <date>
  ### <Category>
  - <description>
  - <description-2-if-needed>
  ```

Categories include: `Added`, `Changed` or `Fixed`

Would you like me to make this more tailored to your CLI (e.g., referencing how the codex tool or its agent triggers the changelog generation)?


If a repository includes a `flake.nix`, try to use `nix develop` to run commands.
If there is a `Makefile`, `Justfile`, or similar, check them first to see if common commands are already defined.
If both exist, prefer the project’s documented setup flow over inventing new commands.
Never run `rm` commands unless the user explicitly requests.
Never these `git` dangerous commands unless the user explicitly requests it:
* `git reset --hard`
* `git clean -fd`
* `git clean -fdx`
* `git checkout -- <file>`
* `git restore --source=HEAD`
* `git reflog expire`
* `git gc`
* `git rebase`
* `git commit --amend`
* `git push --force`
* `git push -f`
* `git branch -D <branch>`
* `git tag -d <tag>`
* `git push origin :refs/tags/<tag>`
* `git revert --no-commit <range>`
* `git stash drop`
* `git stash clear`
Also always use `--no-ext-diff` for git diff commands


## Reasoning
- Use concise explanations
- Show only the final answer unless step-by-step reasoning is requested
