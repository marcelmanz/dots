```
                     ./o.                                                       marcel@p14s
                   ./sssso-                 -----------
                 `:osssssss+-               OS: EndeavourOS x86_64
               `:+sssssssssso/.             Host: 21A0CTO1WW (ThinkPad P14s Gen 2a)
             `-/ossssssssssssso/.           Kernel: Linux 6.12.1-arch1-1
           `-/+sssssssssssssssso+:`         Uptime: 13 mins
         `-:/+sssssssssssssssssso+/.        Packages: 2147 (pacman), 6 (flatpak)
       `.://osssssssssssssssssssso++-       Shell: bash 5.2.37
      .://+ssssssssssssssssssssssso++:      Display (LG HDR 4K): 3840x2160 @ 60 Hz (as 2048x1152) in 27" [External]
    .:///ossssssssssssssssssssssssso++:     Display (DELL S2721QS): 3840x2160 @ 60 Hz (as 2048x1152) in 27" [External]
  `:////ssssssssssssssssssssssssssso+++.    WM: Hyprland (Wayland)
`-////+ssssssssssssssssssssssssssso++++-    Theme: Adwaita-Dark [Qt], Arc-Dark [GTK2/3]
 `..-+oosssssssssssssssssssssssso+++++/`    Icons: breeze-dark [GTK2/3/4]
   ./++++++++++++++++++++++++++++++/:.      Font: DejaVu LGC Sans (12pt) [Qt], Noto Sans (10pt) [GTK2/3/4]
  `:::::::::::::::::::::::::------``        Cursor: breeze (24px)
                                            Terminal: foot 1.19.0
                                            Terminal Font: BlexMono Nerd Font (9pt)
                                            CPU: AMD Ryzen 7 PRO 5850U (16) @ 4.51 GHz
                                            GPU: AMD Radeon Vega Series / Radeon Vega Mobile Series [Integrated]
                                            Memory: 5.30 GiB / 42.93 GiB (12%)
                                            Disk (/): 258.94 GiB / 936.83 GiB (28%) - ext4
                                            Locale: en_US.UTF-8
```

## Useful commands

Update arch mirror list to use the fastest matches using `rate-mirrors`:
```bash
# needs to be installed from the AUR with:
# `paru rate-mirrors-bin`
rate-mirrors --allow-root --protocol https arch | grep -v '^#' | sudo tee /etc/pacman.d/mirrorlist
```
