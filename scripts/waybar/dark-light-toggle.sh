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
    gtk_theme="Adwaita-dark"
    cursor_theme="retrosmart-xcursor-white"
    wallpaper="$HOME/img/dark-grey.png"
    hypr_active_border="rgba(33ccffee)"
    hypr_inactive_border="rgba(595959aa)"
    hypr_locked_border="rgba(d8da9dff)"
else
    icon="󰖨"
    color_scheme="prefer-light"
    gtk_theme="Adwaita"
    cursor_theme="retrosmart-xcursor-black-shadow"
    wallpaper="$HOME/img/light-spring.png"
    hypr_active_border="rgba(007f86ee)"
    hypr_inactive_border="rgba(64666c55)"
    hypr_locked_border="rgba(ff79c6ff)"
fi

gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme"
hyprctl setcursor "$cursor_theme" 24 >/dev/null 2>&1
hyprctl keyword general:col.active_border "$hypr_active_border" >/dev/null 2>&1
hyprctl keyword general:col.inactive_border "$hypr_inactive_border" >/dev/null 2>&1
hyprctl keyword windowrule "border_color $hypr_locked_border, match:tag locked" >/dev/null 2>&1

sed -i "s/^initial-color-theme=.*/initial-color-theme=${current}/" "$HOME/.config/foot/foot.ini"
if [[ "$current" == "dark" ]]; then
    pkill -SIGUSR1 foot 2>/dev/null
else
    pkill -SIGUSR2 foot 2>/dev/null
fi

ln -sf "style-colors-${current}.css" "$HOME/.config/waybar/style-colors.css"
ln -sf "style-${current}.css" "$HOME/.config/swaync/style.css"
ln -sf "$HOME/.config/eza/theme-${current}.yml" "$HOME/.config/eza/theme.yml"

if [[ "$1" == "toggle" ]]; then
    pkill -SIGUSR2 waybar 2>/dev/null
    pkill -RTMIN+12 waybar 2>/dev/null
    swaync-client --reload-css 2>/dev/null

    for sock in /run/user/$(id -u)/nvim.*.0 ; do
        [ -S "$sock" ] && nvim --server "$sock" --remote-send "<Cmd>set background=${current}<CR>" 2>/dev/null &
    done
fi

pkill swaybg 2>/dev/null
sleep 0.2
setsid swaybg --image "$wallpaper" --mode fill >/dev/null 2>&1 & disown

echo "{\"text\": \"$icon\", \"tooltip\": \"Theme: $current\", \"class\": \"$current\"}"
