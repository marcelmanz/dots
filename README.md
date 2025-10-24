```
          ▗▄▄▄       ▗▄▄▄▄    ▄▄▄▖             marcel@nixos
          ▜███▙       ▜███▙  ▟███▛             ------------
           ▜███▙       ▜███▙▟███▛              OS: NixOS 25.11 (Xantusia) x86_64
            ▜███▙       ▜██████▛               Host: 21A0CTO1WW (ThinkPad P14s Gen 2a)
     ▟█████████████████▙ ▜████▛     ▟▙         Kernel: Linux 6.12.53
    ▟███████████████████▙ ▜███▙    ▟██▙        Uptime: 17 hours, 59 mins
           ▄▄▄▄▖           ▜███▙  ▟███▛        Packages: 2185 (nix-system), 1492 (nix-user), 9 (flatpak)
          ▟███▛             ▜██▛ ▟███▛         Shell: bash 5.3.3
         ▟███▛               ▜▛ ▟███▛          Display (DELL S2721QS): 1920x1080 in 27", 60 Hz [External]
▟███████████▛                  ▟██████████▙    Display (BOE0982): 1920x1200 @ 1.25x in 14", 60 Hz [Built-in]
▜██████████▛                  ▟███████████▛    WM: Hyprland 0.51.1 (Wayland)
      ▟███▛ ▟▙               ▟███▛             Icons: breeze-dark [GTK2/3/4]
     ▟███▛ ▟██▙             ▟███▛              Font: Noto Sans (10pt) [GTK2/3/4]
    ▟███▛  ▜███▙           ▝▀▀▀▀               Cursor: retrosmart-xcursor-white (24px)
    ▜██▛    ▜███▙ ▜██████████████████▛         Terminal: alacritty 0.15.1
     ▜▛     ▟████▙ ▜████████████████▛          Terminal Font: BlexMono Nerd Font (10.0pt)
           ▟██████▙       ▜███▙                CPU: AMD Ryzen 7 PRO 5850U (16) @ 4.51 GHz
          ▟███▛▜███▙       ▜███▙               GPU: AMD Radeon Vega Series / Radeon Vega Mobile Series [Integrated]
         ▟███▛  ▜███▙       ▜███▙              Memory: 7.79 GiB / 42.93 GiB (18%)
         ▝▀▀▀    ▀▀▀▀▘       ▀▀▀▘              Disk (/): 184.06 GiB / 937.32 GiB (20%) - ext4
                                               Battery (5B10W51826)
                                               Locale: en_US.UTF-8
```

## Useful commands

Update arch mirror list to use the fastest matches using `rate-mirrors`:
```bash
# needs to be installed from the AUR with:
# `paru rate-mirrors-bin`
rate-mirrors --allow-root --protocol --entry-country=ES https arch | grep -v '^#' | sudo tee /etc/pacman.d/mirrorlist
# for endeavouros
rate-mirrors --disable-comments-in-file --entry-country=CA --protocol=https endeavouros  | sudo tee /etc/pacman.d/endeavouros-mirrorlist
```

Reset locale:
```
sudo localedef -i en_US -f UTF-8 en_US.UTF-8
```
