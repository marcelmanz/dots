# Hyprland .conf -> Lua migration report

Date: 2026-09-15
Hyprland installed: 0.56.2 (hyprlang .conf support is being removed in 0.57)

## Why

Hyprland is dropping hyprlang (`.conf`) support for the core compositor
config starting 0.57, in favor of Lua (`hyprland.lua`). Hyprland only
loads `hyprland.lua` if it exists; otherwise it falls back to
`hyprland.conf`. This migrates the core config ahead of that removal.

## Scope

Only the core Hyprland config chain was migrated:

- `hyprland.conf` -> `hyprland.lua`
- `keybinds.conf` -> `keybinds.lua` (`require("keybinds")`)
- `devices/nixos.conf` -> `devices/nixos.lua`
- `devices/WS0277.conf` -> `devices/WS0277.lua`
- `device.conf` (untracked, runtime symlink to `devices/$(hostname).conf`)
  is now created as `device.lua` -> `devices/$(hostname).lua` instead,
  via the `exec-once` in `hyprland.lua`.

**Not migrated, and don't need to be:**

- `hypridle.conf`, `hyprlock.conf` — separate daemons/binaries with their
  own hyprlang parsers. Per Hyprland's own announcement, the small
  Hypr\* ecosystem tools keep hyprlang indefinitely; they're not part of
  the core Hyprland config removal.
- `kanshi/config` — unrelated project (emersion/kanshi), never used
  hyprlang, not affected at all.
- `monitors.conf`, `workspaces.conf`, `hyprpaper.conf` — already dead/
  orphaned before this migration (not sourced by anything, confirmed via
  code search). Left alone, out of scope.

**Old `.conf` files for the migrated chain are left in place, untouched.**
They're inert once `hyprland.lua` exists (Hyprland prefers the Lua file),
so nothing breaks if the new files aren't linked yet (see To-do below).

## How it was done

1. Used the `hyprlang2lua` CLI (github.com/EIonTusk/hyprlang2lua — checked
   repo legitimacy first: real project, 92 stars, active commit history,
   not a fresh/suspicious repo) via `nix run github:EIonTusk/hyprlang2lua`,
   run against each `.conf` file individually.
2. Manually fixed everything the tool got wrong or couldn't know about
   (see below).
3. Verified the result against the **actual installed Hyprland binary**:
   `Hyprland --verify-config -c <file>` — this is the authoritative check,
   more reliable than trusting docs or the converter's own report.

## Bugs found and fixed (not caught by the converter's own report)

The converter reported `0 flagged / 100% coverage` on every file, but
`--verify-config` still caught real breakage. These needed manual fixes:

| Issue                                                                                                                                                                                              | File(s)                                   | Fix                                                                                                                                                  |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `hl.workspace_rule` has no `name` field                                                                                                                                                            | `hyprland.lua`                            | renamed to `default_name`                                                                                                                            |
| `hl.workspace_rule` has no `on-created-empty` field                                                                                                                                                | `keybinds.lua`                            | renamed to `on_created_empty` (underscored)                                                                                                          |
| `hl.device()` rejects hyphenated keys `tap-to-click` / `tap-and-drag`                                                                                                                              | `hyprland.lua`                            | renamed to `tap_to_click` / `tap_and_drag` (nested `hl.config` sections get auto-underscored by the converter; standalone `hl.device()` calls don't) |
| `device.conf` symlink target still had `.conf` extension                                                                                                                                           | `hyprland.lua`                            | `exec-once` now creates `device.lua` -> `devices/$(hostname).lua`, matching what `require("device")` looks for                                       |
| `$mainMod = Alt` — new key parser is case-sensitive, rejects `"Alt"`                                                                                                                               | `devices/nixos.lua`, `devices/WS0277.lua` | changed to `"ALT"` (matches `keybinds.lua`, which already had it right)                                                                              |
| Two `bind`s to the same key (`mainMod+V`: `togglefloating` then `centerwindow`) silently overwrite each other as two `hl.bind()` calls — Lua doesn't stack binds on the same key like hyprlang did | `keybinds.lua`                            | merged into one `hl.bind` with a function dispatching both actions                                                                                   |
| `devices/WS0277.conf` had a pre-existing typo, `windowrulev` (not a real directive, already broken before this migration)                                                                          | `devices/WS0277.lua`                      | converted to a working `hl.window_rule` for the fullscreen border-color rule it was clearly meant to express                                         |

## Verification performed

- `Hyprland --verify-config -c hyprland.lua` — **config ok**, from the real
  repo path, with `device.lua` symlinked to each of `devices/nixos.lua`
  and `devices/WS0277.lua` in turn (both host variants tested).
- Did not test live (didn't reload/restart the running compositor).

Side effect observed: `--verify-config` still executes `exec` /
`config.reloaded` hooks (it restarted waybar and re-ran the two
`gsettings` calls a few times during testing). Harmless — same idempotent
values — but worth knowing if you re-run verification yourself.

## To-do / open items

1. **Wire up the symlinks.** This repo only provides the files; something
   outside this repo (home-manager config, not present here) symlinks
   individual files from `.config/hypr/` into `~/.config/hypr/` (confirmed:
   `~/.config/hypr/hyprland.conf` resolves back to this repo). That
   symlink list needs the four new `.lua` files added the same way the
   `.conf` files are today:
   - `hyprland.lua`
   - `keybinds.lua`
   - `devices/nixos.lua`
   - `devices/WS0277.lua`
   - `.luarc.json` (LSP config, see below) if that's not auto-included
2. **Test live** after linking: `hyprctl reload` (or a fresh Hyprland
   session) and walk through keybinds, workspace names/scratchpad,
   window rules, per-host overrides on both machines.
3. **Once confirmed working on both hosts**, delete the old `.conf` files
   for the migrated chain (`hyprland.conf`, `keybinds.conf`,
   `devices/nixos.conf`, `devices/WS0277.conf`) and drop this report or
   fold the relevant notes into a CHANGELOG entry.
4. Not required, but worth a look sometime: `monitors.conf`,
   `workspaces.conf`, `hyprpaper.conf` are still dead weight in the repo,
   independent of this migration.

## LSP setup

Added `.luarc.json` in this directory pointing `workspace.library` at the
type stubs Hyprland itself ships for the `hl` global (`hl.meta.lua`).
Lists three candidate paths, since this repo has configs for more than
one host and they're not all NixOS (`devices/WS0277.conf`'s manual
`~/.nix-profile/bin` PATH prepend is a tell that it's Nix-on-non-NixOS,
not a NixOS install):

- `/run/current-system/sw/share/hypr/stubs` — NixOS system profile
- `/usr/share/hypr/stubs` — standard distro packaging (Arch/Debian/Fedora)
- `/usr/local/share/hypr/stubs` — manual/local installs

lua-language-server silently skips entries that don't exist, so listing
all three is free — no per-host detection needed. lua-language-server also
picks up the nearest `.luarc.json` walking up the tree, so this is scoped
to `.config/hypr/` only.

This clears `undefined global variable: hl`. It will **not** clear
`Cannot resolve module 'device'` — that's expected, since `device.lua` is
only ever a runtime-created symlink and is intentionally not committed.

## Reference

- [link0][0] — official announcement
- [link1][1] — Lua config docs entry point
- [link2][2] — bind syntax, flags, submaps
- [link3][3] — official example config
- [link4][4] — converter used
- `/nix/store/*/share/hypr/stubs/hl.meta.lua` — authoritative Lua API types, shipped with the installed Hyprland package

[0]: https://hypr.land/news/26_lua/
[1]: https://wiki.hypr.land/Configuring/Start/
[2]: https://wiki.hypr.land/Configuring/Basics/Binds/
[3]: https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua
[4]: https://github.com/EIonTusk/hyprlang2lua
