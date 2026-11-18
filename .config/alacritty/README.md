# Alacritty keys

Press Ctrl+Shift+H to show this page in a floating window. Quit with q.

## Hints

A hint draws letter labels over every match on screen. Type a label to run the
action for that match.

Shift inserts the match at the prompt.
Ctrl+Alt copies it to the clipboard.

| Match | Insert       | Copy       |
| ----- | ------------ | ---------- |
| Path  | Ctrl+Shift+P | Ctrl+Alt+P |
| URL   | Ctrl+Shift+Y | Ctrl+Alt+Y |
| Hash  | Ctrl+Shift+G | Ctrl+Alt+G |

Other hints:

| Keys         | Action                                            |
| ------------ | ------------------------------------------------- |
| Ctrl+Shift+O | Open a URL with `xdg-open`                        |
| Ctrl+Shift+D | Run `~/scripts/foot-cwd ripdrag <path>` on a path |

## General

| Keys             | Action                             |
| ---------------- | ---------------------------------- |
| Ctrl+Shift+H     | This help                          |
| Ctrl+Shift+C / V | Copy / paste                       |
| Ctrl+Shift+Space | Vi mode (v select, y copy)         |
| Ctrl+Shift+F / B | Search forward / backward          |
| Ctrl+Shift+N     | New Alacritty window               |
| Ctrl+= / - / 0   | Font size bigger / smaller / reset |
| Middle click     | Paste selection                    |
| Ctrl+Shift+Up / Down | Opacity +5% / -5%              |
| Ctrl+Shift+T     | Toggle opacity (opaque / previous) |
| Ctrl+Alt+Up / Down / T | Same three, for all terminals |

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
- Opacity is changed at runtime by `~/scripts/alacritty-opacity`. Ctrl+Shift
  keys affect only the Alacritty process where the key is pressed, Ctrl+Alt
  keys affect all of them. Switching theme resets it to the theme's value.
- The help window is floated and centered by the `alacritty-help` window rule
  in `hyprland.lua`.
