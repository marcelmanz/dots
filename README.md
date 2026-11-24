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

**Tree**

<!-- tree -->
```text
./
├── .agents/
│   └── skills/
│       ├── antislop/
│       ├── bbpr-review/
│       ├── branch-explained/
│       ├── caveman/
│       ├── caveman-commit/
│       ├── caveman-compress/
│       ├── caveman-help/
│       ├── caveman-review/
│       ├── changelog-enrich/
│       ├── diagram/
│       ├── dive-in/
│       ├── evaluate-data-fetching/
│       ├── find-skills/
│       ├── migrate-oxlint/
│       ├── package-fallback/
│       ├── sources-plan-and-todo/
│       ├── summarize-changes/
│       ├── tp-search/
│       ├── vite-environment-transfers/
│       └── zod-to-valibot/
├── .cargo/
├── .claude/
├── .config/
│   ├── alacritty/
│   ├── atuin/
│   ├── bat/
│   ├── beets/
│   ├── blueman/
│   ├── bluetuith/
│   ├── btop/
│   ├── cbfmt/
│   ├── cheat/
│   ├── cliflux/
│   ├── clipse/
│   ├── direnv/
│   ├── erdtree/
│   ├── eww/
│   ├── eza/
│   ├── fish/
│   ├── foot/
│   ├── gh/
│   ├── ghostty/
│   ├── gnupg/
│   ├── gtk-4.0/
│   ├── helix/
│   ├── himalaya/
│   ├── htop/
│   ├── hypr/
│   ├── ironbar/
│   ├── kanshi/
│   ├── lf/
│   ├── mako/
│   ├── neofetch/
│   ├── nushell/
│   ├── opencode/
│   ├── ostui/
│   ├── paru/
│   ├── pgcli/
│   ├── pypr/
│   ├── quickshell/
│   ├── rbw/
│   ├── reedline-bash/
│   ├── rustfmt/
│   ├── swappy/
│   ├── tmux/
│   ├── tofi/
│   ├── tombi/
│   ├── tridactyl/
│   ├── vale/
│   ├── vifm/
│   ├── vimmatic/
│   ├── waybar/
│   ├── wezterm/
│   ├── wob/
│   ├── wofi/
│   ├── xdg-desktop-portal/
│   ├── xdg-desktop-portal-termfilechooser/
│   ├── zathura/
│   ├── zellij/
│   ├── zk/
│   ├── mimeapps.list
│   ├── shellcheckrc
│   ├── starship.toml
│   ├── topgrade.toml
│   └── user-dirs.dirs
├── .githooks/
├── .kube/
├── .local/
├── models/
├── .newsboat/
├── .pi/
├── .ropeproject/
├── scripts/
│   ├── arch/
│   ├── dev/
│   ├── develop/
│   ├── env-sed/
│   ├── git/
│   ├── hyprland/
│   ├── lua/
│   ├── nushell/
│   ├── open-ai/
│   ├── __pycache__/
│   ├── tasks-menu/
│   ├── tmux/
│   ├── tofi/
│   ├── waybar/
│   ├── work/
│   ├── yabai/
│   ├── add-dekstop-entry.sh
│   ├── add-desktop-entry.sh
│   ├── add-ssh.sh
│   ├── add-to-gitignore.sh
│   ├── alacritty-help
│   ├── alacritty-opacity
│   ├── alacritty-to-tmux
│   ├── alacritty-vi-or-tmux-copy
│   ├── battery-left-perc
│   ├── bitcoin-price
│   ├── bluetooth-selector.sh
│   ├── calc
│   ├── cargo-build-run.sh
│   ├── check-todos.sh
│   ├── chrome-sound-rn.sh
│   ├── claude-sessions
│   ├── clean-color-output
│   ├── clean-color-outuput
│   ├── client
│   ├── clipfile
│   ├── conf.sh
│   ├── convert-to-env-bash.sh
│   ├── copy-to-multi-dirs.sh
│   ├── cowfiles
│   ├── create-bootable.sh
│   ├── create-ssh-key
│   ├── curl-token-refresher.sh
│   ├── deploy-mlab.sh
│   ├── discogs-from-yt-music-csv.py
│   ├── dock-nowake.sh
│   ├── dot-files-syslinks
│   ├── do-to-mulitple-dirs.sh
│   ├── dots_sync.sh
│   ├── download-youtube-music.sh
│   ├── fennel-nvim.sh
│   ├── find-notes.sh
│   ├── find-todos.sh
│   ├── firefox-has-work-tab.sh
│   ├── firefox-work-container.sh
│   ├── fish-home
│   ├── fix-audio.sh
│   ├── fix-micro.sh
│   ├── flac-to-wav.sh
│   ├── fman
│   ├── fman.sh
│   ├── foot-cwd
│   ├── gdoc2pdf-open.sh
│   ├── gd-spread.sh
│   ├── get-my-repos.sh
│   ├── get-wayland-screen-size.sh
│   ├── gh-stars
│   ├── github-pr-name-generator
│   ├── .gitignore
│   ├── git-noti
│   ├── git-noti-awk
│   ├── gpg-pinetry-loopback.sh
│   ├── hello-pepe
│   ├── hf-pull.sh
│   ├── hf-search.py
│   ├── hint-path
│   ├── how-get-cache.sh
│   ├── how.sh
│   ├── http-codes.sh
│   ├── http-status-cache.csv
│   ├── install-cargofile.sh
│   ├── install-head-2-neovim
│   ├── install-last-neovim
│   ├── install-last-rust-analyzer
│   ├── install-last-zeta-note
│   ├── install-rtw89-wlan-drivers
│   ├── keyd-autoreload.sh
│   ├── key-lay
│   ├── kill-menu.sh
│   ├── kill-port.sh
│   ├── launch-waybar.sh
│   ├── makefile-runner.sh
│   ├── media
│   ├── mermaid-generator.sh
│   ├── move-all-files-to-root.sh
│   ├── mv-kebab
│   ├── my-nix-search
│   ├── my-repos
│   ├── neovide-hide.sh
│   ├── nice-color-nmtui.sh
│   ├── nixpack.sh
│   ├── nix-remote-init.sh
│   ├── nixs
│   ├── nix-templates.sh
│   ├── no-spaces
│   ├── note.sh
│   ├── NOTES.md
│   ├── notify_hello.lua
│   ├── nvim-bob-selector.sh
│   ├── o
│   ├── open-1:1-notes.sh
│   ├── open-dev-templates.sh
│   ├── open-notes
│   ├── open-repos-web.sh
│   ├── open-retro-notes.sh
│   ├── open-tmux-term.sh
│   ├── op-env-sync.sh
│   ├── open-wez-yabai
│   ├── open-work-repo-link.sh
│   ├── ostui-launch
│   ├── pass-backup.sh
│   ├── passff.sh
│   ├── pass-restore.sh
│   ├── pass-to-rbw.sh
│   ├── pdf-dec.sh
│   ├── pdf-selector.sh
│   ├── pinentry-rbw
│   ├── practice.sh
│   ├── preview
│   ├── pulseaudio-volume-limit.sh
│   ├── pw-volume-monitor.sh
│   ├── qbit-pass.sh
│   ├── rbwmenu
│   ├── rebuild_query_map.sh
│   ├── remaining-bat.sh
│   ├── remove-neovim-source
│   ├── repos
│   ├── restart-awesome
│   ├── restore-backup-files.sh
│   ├── review-notes.sh
│   ├── rofi-power-menu
│   ├── rofi-pulse-sink
│   ├── .ruby-version
│   ├── sadrep.sh
│   ├── sca
│   ├── script-selector.sh
│   ├── sensors-temp.sh
│   ├── show-key-layout
│   ├── show_webcam.sh
│   ├── simulate_fraud_like_graph.ts
│   ├── skhd-start
│   ├── ss-auto-deploy
│   ├── ssh-rbw-bk.sh
│   ├── stuart_jwt.rb
│   ├── suspend-time.sh
│   ├── swap-displays-menu
│   ├── text-replacer.sh
│   ├── themed-bemenu
│   ├── ThisIsAText.js
│   ├── tmux-pipe-paste.sh
│   ├── tmux-se.sh
│   ├── tmux-smart-copy.sh
│   ├── todos.sh
│   ├── to-kebab
│   ├── to-lower
│   ├── trackpoint-tune.py
│   ├── uninstall-last-neovim
│   ├── uping
│   ├── video-selector.sh
│   ├── vi-runtime
│   ├── vi.sh
│   ├── viz
│   ├── volume-change.sh
│   ├── volume-control.sh
│   ├── whatsapp-waydroid.sh
│   ├── will-rain.sh
│   ├── workspace.sh
│   ├── yt-find-notes
│   ├── yt-note
│   ├── yt-rss.sh
│   ├── zd
│   ├── zd-fish.fish
│   ├── zd-fish-zoxide.fish
│   ├── zk-file-extraction
│   └── zk-new
├── secrets/
├── .termux/
├── .tmux/
├── arch-packages
├── arch-packages-aur
├── .asoundrc
├── .bash_aliases
├── .bash-preexec.sh
├── .bashrc
├── Brewfile
├── Cargofile
├── .cargo-programs
├── clones-file-structure.md
├── .gitconfig
├── .gitignore
├── gitleaks-report.json
├── .gitmessage
├── .gitmodules
├── .inputrc
├── lunarperche.vim
├── .myclirc
├── .node-version
├── notes.md
├── old-school-dots-gitignore
├── .password-store
├── .profile
├── programs-file-structure.md
├── README.md
├── .rustfmt.toml
├── .sops.yaml
├── .taskrc
├── .tmux.conf
├── vimmatic-config.json
├── .vimrc
└── .zshrc
```
<!-- /tree -->
