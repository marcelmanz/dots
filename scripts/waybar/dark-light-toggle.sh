#!/usr/bin/env bash

MODE_FILE="$HOME/.cache/.theme_mode"

if [[ -f "$MODE_FILE" ]]; then
    current=$(cat "$MODE_FILE")
else
    current="dark"
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
    gtk_theme="Adwaita-dark"
    cursor_theme="retrosmart-xcursor-white"
else
    icon="󰖨"
    color_scheme="prefer-light"
    gtk_theme="Adwaita"
    cursor_theme="retrosmart-xcursor-black-shadow"
fi

gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme"
hyprctl setcursor "$cursor_theme" 24 >/dev/null 2>&1

sed -i "s/^initial-color-theme=.*/initial-color-theme=${current}/" "$HOME/.config/foot/foot.ini"
if [[ "$current" == "dark" ]]; then
    pkill -SIGUSR1 foot 2>/dev/null
else
    pkill -SIGUSR2 foot 2>/dev/null
fi

if [[ "$1" == "toggle" ]]; then
    ln -sf "style-colors-${current}.css" "$HOME/.config/waybar/style-colors.css"
    pkill -SIGUSR2 waybar 2>/dev/null
    pkill -RTMIN+12 waybar 2>/dev/null

    for sock in /run/user/$(id -u)/nvim.*.0 ; do
        [ -S "$sock" ] && nvim --server "$sock" --remote-send "<Cmd>set background=${current}<CR>" 2>/dev/null &
    done
fi

echo "{\"text\": \"$icon\", \"tooltip\": \"Theme: $current\", \"class\": \"$current\"}"
