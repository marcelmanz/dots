# Hyprland keys

Mod+Shift+? shows this page. Super+Shift+? lists every active bind from
`hyprctl binds`. Quit either with q.

Mod is Alt. Super is the second modifier.

## Prefix

Ctrl+B still reaches the focused app, so tmux keeps working.

| Keys     | Action                                       |
| -------- | -------------------------------------------- |
| Ctrl+B y | Alacritty vi mode, or tmux copy mode in tmux |

## Apps

| Keys        | Action                    |
| ----------- | ------------------------- |
| Mod+Return  | Terminal                  |
| Mod+D       | App launcher              |
| Mod+Q       | Browser                   |
| Mod+W / O   | Browser, Work / Personal  |
| Mod+Shift+O | ai.marcel.cool            |
| Mod+Shift+G | Gemini (Work)             |
| Mod+C       | Clipboard history         |
| Mod+Shift+C | Script selector           |
| Mod+Shift+P | Passwords (rbw)           |
| Mod+Shift+E | Emoji picker              |
| Mod+Shift+D | Drag files with `ripdrag` |
| Mod+B       | Bluetooth                 |
| Mod+P       | Power menu                |

## Scratchpads

| Keys        | Action                                 |
| ----------- | -------------------------------------- |
| Mod+S       | Terminal                               |
| Mod+N       | Notes (SilverBullet)                   |
| Mod+M       | Cinny                                  |
| Mod+Shift+V | Volume mixer (pulsemixer)              |
| Mod+Shift+M | Music (ostui), enters the music submap |
| Mod+Shift+N | nixbuild panel (home-manager switch)   |

## Music submap

Esc or Mod+Shift+M hides ostui and leaves the submap.

| Keys         | Action        |
| ------------ | ------------- |
| Space        | Play / pause  |
| Left / Right | Seek 5s       |
| Up / Down    | Player volume |

## Windows

| Keys              | Action                                                |
| ----------------- | ----------------------------------------------------- |
| Mod+H/J/K/L       | Focus, J/K cycle in monocle, fullscreen and scrolling |
| Mod+J/K           | Also cycle in deck, and between floating and tiled    |
| Mod+Shift+H/J/K/L | Move window; floating: 5% steps, hold to repeat       |
| Mod+Shift+Return  | Make the focused window the main                      |
| Super+H/J/K/L     | Resize; floating: 5% steps, stays on screen           |
| Mod+R             | Resize submap with h/j/k/l, Esc leaves                |
| Mod+V             | Toggle float and center                               |
| Mod+F             | Toggle monocle, then back to the previous layout      |
| Mod+A             | Pick a layout for this workspace, kept across reloads |
| Super+H/L         | In Mod+A layouts, shrink / grow the main              |
| Mod+Shift+F       | Fullscreen                                            |
| Mod+Tab           | Lock / unlock window                                  |
| Mod+Shift+Q       | Close, refused while locked                           |
| Mod+Shift+X       | Click a window to kill it                             |
| Mod+Shift+I       | Shift workspaces to the next monitor                  |
| Mod+Z             | Zoom in                                               |
| Mod+Shift+Z       | Reset zoom and reload Hyprland                        |
| Mod+drag L / R    | Move / resize with the mouse                          |

## Workspaces

| Keys           | Action                   |
| -------------- | ------------------------ |
| Mod+1..0       | Go to workspace 1-10     |
| Mod+Shift+1..0 | Send window to workspace |
| Mod+scroll     | Next / previous          |

## System

| Keys              | Action                           |
| ----------------- | -------------------------------- |
| Mod+E             | Toggle bar                       |
| Mod+T             | Toggle dark / light theme        |
| Mod+Shift+W       | Toggle projectw                  |
| Super+Space       | Next keyboard layout (us / es)   |
| Mod+middle click  | Toggle touchpad                  |
| Mod+Shift+R       | Reload Hyprland, pypr and swaync |
| Volume, mute keys | Volume with OSD                  |
| Brightness keys   | Brightness with OSD              |
| Lid switch        | Lock screen                      |

## Screenshots

| Keys        | Action                                |
| ----------- | ------------------------------------- |
| Mod+Print   | Region screenshot, edit in swappy     |
| Mod+Shift+S | Read QR code from region to clipboard |
| Mod+Shift+T | OCR region to clipboard               |
