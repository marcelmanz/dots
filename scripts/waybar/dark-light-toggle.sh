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
else
    icon="󰖨"
    color_scheme="prefer-light"
    gtk_theme="Adwaita"
fi

gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"

echo "{\"text\": \"$icon\", \"tooltip\": \"Theme: $current\", \"class\": \"$current\"}"
