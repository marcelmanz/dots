# Alacritty hints

Custom hints in `alacritty.toml`. A hint draws letter labels over every match
on screen. Type a label to run the action for that match.

## Bindings

Shift inserts the match at the prompt.
Ctrl+Alt copies it to the clipboard.

| Match | Insert       | Copy       |
| ----- | ------------ | ---------- |
| Path  | Ctrl+Shift+P | Ctrl+Alt+P |
| URL   | Ctrl+Shift+Y | Ctrl+Alt+Y |
| Hash  | Ctrl+Shift+H | Ctrl+Alt+H |

Other hints:

| Keys         | Action                                            |
| ------------ | ------------------------------------------------- |
| Ctrl+Shift+O | Open a URL with `xdg-open`                        |
| Ctrl+Shift+D | Run `~/scripts/foot-cwd ripdrag <path>` on a path |

## Matches

- Path: starts with `./`, `../`, `/` or `~/`.
- URL: `scheme://...`.
- Hash: 7 to 128 hex characters.

## Notes

- Setting `hints.enabled` replaces Alacritty's default URL hint, so the open
  hint is declared explicitly.
- Foot inserts when the last label key is uppercase. Alacritty has one action
  per hint, hence the two bindings.
- Plain Ctrl+P and Ctrl+Y are left to the shell (history and yank). Alt is
  Hyprland's `mainMod`, so Ctrl+Alt is used for copy.
- The match is appended as the last argument of `command`. There is no
  `${match}` templating.
