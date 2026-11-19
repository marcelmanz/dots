---
name: package-fallback
description: What to do when a command, package or tool is not installed. The user runs Nix, so run it ad hoc with nix run or nix shell instead of installing it or giving up. Use when a command is not found, an import or module is missing, a tool such as ruff or jq is unavailable, or before suggesting apt, brew, pip install -g or npm install -g.
---

# Package fallback

A missing command usually means the user runs Nix, not that the tool is
unavailable. Do not install it system-wide and do not skip the check. Run it
ad hoc.

## Order

1. Try the project's own runner first, such as `uv run <tool>`,
   `npx <tool>` or `make <target>`. Project-pinned versions win.
2. Run a single command from nixpkgs:

   ```
   nix run nixpkgs#ruff -- check src
   ```

   Arguments for the tool go after `--`.
3. Need several tools, or the same tool more than once, in a temporary shell:

   ```
   nix shell nixpkgs#jq nixpkgs#ripgrep -c jq . data.json
   ```

4. Not in nixpkgs, run it straight from its repository:

   ```
   nix run github:owner/repo -- args
   nix run github:owner/repo/<tag-or-branch> -- args
   ```

5. Only a one-off script with many dependencies, use a shell with a package set:

   ```
   nix shell nixpkgs#python3 nixpkgs#python3Packages.httpx -c python script.py
   ```

## Finding the package

- Package names often differ from command names. Look them up first:

  ```
  nix search nixpkgs <name>
  ```

- To find which package provides a command, use `nix-locate` if it is
  installed, or `nix search`.
- A flake repo exposes its default app. Add `#<name>` to pick another output.

## Rules

- Never use `sudo`, `apt`, `brew`, `pip install --user` or `npm install -g` to
  fill the gap. Those either fail on this system or drift from the Nix setup.
- Do not edit the project's dependencies to get a dev tool. Use `nix run`.
- Do not edit the home-manager or dots config to add a tool for one command.
  Suggest it in the reply if the tool will be needed again.
- Pass tool arguments after `--`, or nix will try to parse them itself.
- If a flake command is refused for experimental features, add
  `--extra-experimental-features "nix-command flakes"` and mention it.
- If the package truly does not exist anywhere, say so and stop. Do not
  invent a package name.

## Reply

Say which tool was missing and the exact `nix run` or `nix shell` line that
worked. If it will be needed repeatedly, suggest adding it to the user's Nix
config instead of doing it.
