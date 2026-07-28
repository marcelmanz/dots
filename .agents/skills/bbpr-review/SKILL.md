---
name: bbpr-review
description: Fetch a Bitbucket PR's title, description, and diff via bbdiff, then review or explain it. Use when the user pastes a Bitbucket PR URL (bitbucket.org/.../pull-requests/N), says "review pr", "explain pr", "what does pr N do", "bbpr", or gives a PR number and asks what it changes.
---

# Bitbucket PR review

Fetch the PR with `bbdiff` and analyse it. The function outputs the PR header
(title, description, branch) followed by the raw unified diff.

## Process

1. **Extract PR number and repo from the input.**
   - If the user pastes a Bitbucket URL like
     `https://bitbucket.org/WORKSPACE/REPO/pull-requests/123` or
     `https://bitbucket.org/WORKSPACE/REPO/pull-requests/123/...`,
     parse out `WORKSPACE/REPO` and `123` directly — no need to ask.
   - Otherwise accept a bare PR number; `workspace/repo` is optional (see below).

2. Run `bbdiff <pr_number> [workspace/repo]` via Bash. The function is defined
   in `~/.bashrc`, so source it first:
   ```
   bash -c 'source ~/.bashrc && bbdiff <pr_number> [workspace/repo]'
   ```
   If the user is inside a Bitbucket-backed git repo, `workspace/repo` can be
   omitted — `bbdiff` derives it from `git remote get-url origin`.

2. Parse the output:
   - Everything before the first `diff --git` line is the PR header.
   - The rest is the unified diff.

3. Answer the user's question:
   - **"what does this PR do / explain it"** — summarise purpose, changed
     files, and key logic changes in plain language. Lead with the why (from
     the description), then the what (from the diff).
   - **"review this PR"** — check for correctness bugs, missing edge cases,
     security issues, and obvious simplifications. One finding per line:
     `file:line — issue`. Skip style nits unless glaring.
   - **"understand / walk me through"** — explain file by file what changed
     and why each change matters.

## Notes

- `BITBUCKET_USER` and `BITBUCKET_TOKEN` must be set in the environment;
  if the curl fails with 401, tell the user to check those env vars.
- If `$2` (workspace/repo) is needed but missing, ask the user for it in the
  form `workspace/repo` (e.g. `worldsensing/network-manager`).
- Keep the response proportional to the diff size: small diff → short answer,
  large diff → section per file or concern.
