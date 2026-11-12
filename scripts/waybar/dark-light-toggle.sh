#!/usr/bin/env bash

MODE_FILE="$HOME/.cache/.theme_mode"

if [[ -f "$MODE_FILE" ]]; then
    current=$(cat "$MODE_FILE")
else
    current="light"
fi

toggle() {
    if [[ "$current" == "dark" ]]; then
        current="light"
    else
        current="dark"
    fi
    echo "$current" > "$MODE_FILE"
}

if [[ "$1" == "toggle" ]]; then
    toggle
fi

if [[ "$current" == "dark" ]]; then
    icon="󰖙"
    color_scheme="prefer-dark"
    gtk_theme="Breeze-Dark"
    gtk_icon_theme="breeze-dark"
    cursor_theme="retrosmart-xcursor-white"
    hyprpaper_conf="$HOME/clones/own/dots/.config/hypr/hyprpaper-dark.conf"
    hypr_active_border="rgba(33ccffee)"
    hypr_inactive_border="rgba(595959aa)"
    hypr_locked_border="rgba(d8da9dff)"
    btop_theme="adwaita-dark"
    alacritty_theme="alabaster"
else
    icon="󰖨"
    color_scheme="prefer-light"
    gtk_theme="Breeze"
    gtk_icon_theme="breeze"
    cursor_theme="retrosmart-xcursor-black-shadow"
    hyprpaper_conf="$HOME/clones/own/dots/.config/hypr/hyprpaper.conf"
    hypr_active_border="rgba(007f86ee)"
    hypr_inactive_border="rgba(64666c55)"
    hypr_locked_border="rgba(ff79c6ff)"
    btop_theme="whiteout"
    alacritty_theme="modus-operandi"
fi

# Update GTK config files directly
cat > ~/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-application-prefer-dark-theme=$([[ "$current" == "dark" ]] && echo "true" || echo "false")
gtk-theme-name=$gtk_theme
gtk-icon-theme-name=$gtk_icon_theme
gtk-cursor-theme-name=$cursor_theme
gtk-cursor-theme-size=24
gtk-enable-animations=true
gtk-font-name=Noto Sans,  10
gtk-button-images=true
gtk-menu-images=true
gtk-decoration-layout=icon:minimize,maximize,close
gtk-primary-button-warps-slider=true
gtk-modules=colorreload-gtk-module
EOF

cat > ~/.config/gtk-4.0/settings.ini << EOF
[Settings]
gtk-application-prefer-dark-theme=$([[ "$current" == "dark" ]] && echo "true" || echo "false")
gtk-theme-name=$gtk_theme
gtk-icon-theme-name=$gtk_icon_theme
gtk-cursor-theme-name=$cursor_theme
gtk-cursor-theme-size=24
gtk-enable-animations=true
gtk-font-name=Noto Sans,  10
gtk-button-images=true
gtk-menu-images=true
gtk-decoration-layout=icon:minimize,maximize,close
gtk-primary-button-warps-slider=true
EOF

cat > ~/.gtkrc-2.0 << EOF
gtk-theme-name="$gtk_theme"
gtk-icon-theme-name="$gtk_icon_theme"
gtk-cursor-theme-name="$cursor_theme"
gtk-cursor-theme-size=24
gtk-enable-animations=1
gtk-toolbar-style=3
gtk-menu-images=1
gtk-button-images=1
gtk-primary-button-warps-slider=1
gtk-sound-theme-name=ocean
gtk-font-name="Noto Sans,  10"
EOF

# gsettings needs GNOME schemas that aren't installed here; dconf writes the
# same keys directly (xdg-desktop-portal reads org.gnome.desktop.interface from dconf).
dconf write /org/gnome/desktop/interface/color-scheme "'$color_scheme'"
dconf write /org/gnome/desktop/interface/gtk-theme "'$gtk_theme'"
dconf write /org/gnome/desktop/interface/cursor-theme "'$cursor_theme'"
hyprctl setcursor "$cursor_theme" 24 >/dev/null 2>&1
hyprctl keyword general:col.active_border "$hypr_active_border" >/dev/null 2>&1
hyprctl keyword general:col.inactive_border "$hypr_inactive_border" >/dev/null 2>&1
hyprctl keyword windowrule "border_color $hypr_locked_border, match:tag locked" >/dev/null 2>&1

printf 'initial-color-theme=%s\n' "$current" >"$HOME/.config/foot/theme-active.ini"
if [[ "$current" == "dark" ]]; then
    pkill -SIGUSR1 foot 2>/dev/null
else
    pkill -SIGUSR2 foot 2>/dev/null
fi

cp "$HOME/.config/alacritty/themes/${alacritty_theme}.toml" "$HOME/.cache/alacritty-theme.toml"

ln -sf "style-${current}.css" "$HOME/.config/swaync/style.css"
ln -sf "$HOME/clones/own/dots/.config/ironbar/style-${current}.css" "$HOME/.config/ironbar/style.css"
ln -sf "$HOME/.config/eza/theme-${current}.yml" "$HOME/.config/eza/theme.yml"
ln -sf "$(dirname "$(readlink -f "$(command -v btop)")")/../share/btop/themes/${btop_theme}.theme" "$HOME/.config/btop/themes/system.theme"

# (the Brave prefs hack that used to live here was dropped: Brave follows the
# freedesktop color-scheme portal live since hyprland-portals.conf routes Settings to gnome)

if [[ "$1" == "toggle" ]]; then
    tmux source-file "$HOME/.config/tmux/tmux.conf" 2>/dev/null
    tmux refresh-client -S 2>/dev/null
    printf '%s tmux reload exit=%s mode=%s\n' "$(date +%H:%M:%S)" "$?" "$current" >> "$HOME/.cache/tmux-theme-toggle.log"

    swaync-client --reload-css 2>/dev/null
    pkill ironbar 2>/dev/null
    setsid ironbar >/dev/null 2>&1 & disown

    pkill -USR2 btop 2>/dev/null

    for sock in /run/user/$(id -u)/nvim.*.0 ; do
        [ -S "$sock" ] && nvim --server "$sock" --remote-send "<Cmd>set background=${current}<CR>" 2>/dev/null &
    done
fi

if [[ "$1" == "toggle" ]] || ! pgrep -x hyprpaper >/dev/null; then
    pkill hyprpaper 2>/dev/null
    sleep 0.2
    setsid hyprpaper -c "$hyprpaper_conf" >/dev/null 2>&1 & disown
fi

if [[ "$1" == "toggle" ]] || ! pgrep -f projectw.py >/dev/null; then
    pkill -f projectw.py 2>/dev/null
    sleep 0.5
    setsid projectw >/dev/null 2>&1 & disown
fi

echo "{\"text\": \"$icon\", \"tooltip\": \"Theme: $current\", \"class\": \"$current\"}"
