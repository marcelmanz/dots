The coolest dotfiles, made to be shared across multiple hosts.

```bash
git clone --recurse-submodules git@github.com:marcelarie/dots ~/clones/own/dots
```

**Stack**

| What     | Where                                                    |
| -------- | -------------------------------------------------------- |
| WM       | Hyprland, `.config/hypr`                                 |
| Overlays | Quickshell, `.config/quickshell`                         |
| Bar      | ironbar, `.config/ironbar`                               |
| Terminal | Alacritty + tmux                                         |
| Shell    | bash + reedline-bash + atuin                             |
| Secrets  | sops in `secrets/`, passwords in `.password-store`       |
| Agents   | `.agents/skills`, `.claude`                              |
| Scripts  | `scripts/`, on `PATH`                                    |

Per-host Hyprland config: `.config/hypr/devices/<host>.lua`.

**Keys**

- Hyprland: Mod+Shift+?, see `.config/hypr/README.md`
- Alacritty: Ctrl+Shift+H, see `.config/alacritty/README.md`
