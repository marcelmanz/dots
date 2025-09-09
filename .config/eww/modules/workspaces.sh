#!/bin/bash

workspaces() {
    unset -v o1 o2 o3 o4 o5 o6 o7 o8 o9 f1 f2 f3 f4 f5 f6 f7 f8 f9

    # Get occupied workspaces
    ows="$(hyprctl workspaces -j | jq '.[] | select(.id > 0 and .id <= 9) | .id')"
    
    for num in $ows; do
        export o"$num"="occupied"
    done

    # Get focused workspace
    num="$(hyprctl activeworkspace -j | jq '.id')"
    if [ "$num" -ge 1 ] && [ "$num" -le 9 ]; then
        export f"$num"="focused"
    fi

    echo "(eventbox :onscroll \"echo {} | sed -e 's/up/-1/g' -e 's/down/+1/g' | xargs hyprctl dispatch workspace\" \
          (box :class \"workspaces\" :orientation \"h\" :space-evenly false \
              (button :onclick \"hyprctl dispatch workspace 1\" :class \"${o1}${f1}\" \"1\") \
              (button :onclick \"hyprctl dispatch workspace 2\" :class \"${o2}${f2}\" \"2\") \
              (button :onclick \"hyprctl dispatch workspace 3\" :class \"${o3}${f3}\" \"3\") \
              (button :onclick \"hyprctl dispatch workspace 4\" :class \"${o4}${f4}\" \"4\") \
              (button :onclick \"hyprctl dispatch workspace 5\" :class \"${o5}${f5}\" \"5\") \
              (button :onclick \"hyprctl dispatch workspace 6\" :class \"${o6}${f6}\" \"6\") \
              (button :onclick \"hyprctl dispatch workspace 7\" :class \"${o7}${f7}\" \"7\") \
              (button :onclick \"hyprctl dispatch workspace 8\" :class \"${o8}${f8}\" \"8\") \
              (button :onclick \"hyprctl dispatch workspace 9\" :class \"${o9}${f9}\" \"9\") \
          ) \
        )"
}

workspaces
socat -u UNIX-CONNECT:/tmp/hypr/"$HYPRLAND_INSTANCE_SIGNATURE"/.socket2.sock - | while read -r; do 
    workspaces
done