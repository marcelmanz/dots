#!/usr/bin/env bash

WAYBAR_SIGNAL=${WAYBAR_SIGNAL:-11}
VOLUME_STEP=${WAYBAR_VOLUME_STEP:-5}
VOLUME_LIMIT=${WAYBAR_VOLUME_LIMIT:-1.5}

DEFAULT_SINK_ID=""
DEFAULT_SINK_RAW_NAME=""
DEFAULT_SINK_DISPLAY_NAME=""
DEFAULT_SINK_VOLUME=0
DEFAULT_SINK_MUTED=0

json_escape() {
    local value=$1
    value=${value//\\/\\\\}
    value=${value//\"/\\\"}
    value=${value//$'\n'/\\n}
    value=${value//$'\r'/\\r}
    value=${value//$'\t'/\\t}
    printf '%s' "$value"
}

emit_error() {
    local message=$1
    local text
    local tooltip
    text=$(json_escape "audio")
    tooltip=$(json_escape "$message")
    printf '{"text":"%s","tooltip":"%s","class":"error","alt":"error"}\n' "$text" "$tooltip"
}

signal_waybar() {
    pkill -RTMIN+"$WAYBAR_SIGNAL" waybar 2>/dev/null || true
}

collect_sink_lines() {
    local status_output=$1
    mapfile -t sink_lines < <(
        printf '%s\n' "$status_output" |
            awk '
                /Sinks:/ {section=1; next}
                /Sink endpoints:/ {section=2; next}
                /Sources:/ {section=0}
                /Source endpoints:/ {section=0}
                section == 1 || section == 2 {
                    gsub(/[│├└┌┬─╰╯]/, "")
                    sub(/^[[:space:]]+/, "")
                    if ($0 ~ /^[*![:space:]]*[0-9]+\./) print
                }
            '
    )
}

extract_volume() {
    local meta=$1
    if [[ $meta =~ vol:[[:space:]]*([0-9.]+) ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
    else
        printf '0'
    fi
}

extract_muted() {
    local meta=$1
    if [[ $meta =~ mute:[[:space:]]*([0-9]+) ]]; then
        if (( ${BASH_REMATCH[1]} != 0 )); then
            printf '1'
            return
        fi
    fi
    if [[ $meta =~ mute:[[:space:]]*(yes|on|true) ]]; then
        printf '1'
        return
    fi
    printf '0'
}

parse_sink_line() {
    local line=$1
    local meta=""
    [[ -z $line ]] && return 1
    if [[ $line =~ ^([*![:space:]]*)([0-9]+)\.\ ([^[]+)(\ \[(.+)\])?$ ]]; then
        DEFAULT_SINK_ID=${BASH_REMATCH[2]}
        DEFAULT_SINK_RAW_NAME=${BASH_REMATCH[3]}
        meta=${BASH_REMATCH[5]:-}
        DEFAULT_SINK_RAW_NAME=$(printf '%s' "$DEFAULT_SINK_RAW_NAME" | sed 's/[[:space:]]*$//')
        DEFAULT_SINK_VOLUME=$(extract_volume "$meta")
        DEFAULT_SINK_MUTED=$(extract_muted "$meta")
        return 0
    fi
    return 1
}

resolve_sink_display_name() {
    local inspect_output description nickname fallback
    DEFAULT_SINK_DISPLAY_NAME="$DEFAULT_SINK_RAW_NAME"
    inspect_output=$(wpctl inspect "$DEFAULT_SINK_ID" 2>/dev/null) || return
    description=$(printf '%s\n' "$inspect_output" | awk -F'"' '/node.description/ {print $2; exit}')
    nickname=$(printf '%s\n' "$inspect_output" | awk -F'"' '/node.nick/ {print $2; exit}')
    fallback=$(printf '%s\n' "$inspect_output" | awk -F'"' '/device.description/ {print $2; exit}')
    if [[ -n $description ]]; then
        DEFAULT_SINK_DISPLAY_NAME=$description
    elif [[ -n $nickname ]]; then
        DEFAULT_SINK_DISPLAY_NAME=$nickname
    elif [[ -n $fallback ]]; then
        DEFAULT_SINK_DISPLAY_NAME=$fallback
    fi
    DEFAULT_SINK_DISPLAY_NAME=$(printf '%s' "$DEFAULT_SINK_DISPLAY_NAME" | sed 's/[[:space:]]\+/ /g' | sed 's/[[:space:]]*$//')

    local mute_state
    mute_state=$(printf '%s\n' "$inspect_output" | awk -F'= ' '/mute =/ {print $2; exit}')
    case "${mute_state,,}" in
        true|1|yes) DEFAULT_SINK_MUTED=1 ;;
        false|0|no) DEFAULT_SINK_MUTED=0 ;;
    esac

    local volume_state
    volume_state=$(printf '%s\n' "$inspect_output" | awk -F'= ' '/volume =/ {print $2; exit}')
    if [[ $volume_state =~ ([0-9]+\.[0-9]+) ]]; then
        DEFAULT_SINK_VOLUME=${BASH_REMATCH[1]}
    fi
}

load_default_sink() {
    local silent=${1:-0}
    local status_output
    local default_line=""
    local fallback_line=""

    status_output=$(wpctl status 2>&1)
    if [[ $? -ne 0 ]]; then
        [[ $silent -eq 0 ]] && emit_error "${status_output:-wpctl status failed}"
        return 1
    fi

    collect_sink_lines "$status_output"

    for line in "${sink_lines[@]}"; do
        [[ -z $line ]] && continue
        [[ -z $fallback_line ]] && fallback_line=$line
        if [[ $line == *"*"* ]]; then
            default_line=$line
            break
        fi
    done

    if [[ -z $default_line ]]; then
        default_line=$fallback_line
    fi

    if [[ -z $default_line ]]; then
        [[ $silent -eq 0 ]] && emit_error "no sinks detected"
        return 1
    fi

    if ! parse_sink_line "$default_line"; then
        [[ $silent -eq 0 ]] && emit_error "failed to parse sink info"
        return 1
    fi

    resolve_sink_display_name
    refresh_volume_state
    return 0
}

refresh_volume_state() {
    local volume_output
    volume_output=$(wpctl get-volume "$DEFAULT_SINK_ID" 2>/dev/null) || return
    if [[ $volume_output =~ Volume:[[:space:]]*([0-9.]+) ]]; then
        DEFAULT_SINK_VOLUME=${BASH_REMATCH[1]}
    fi
    if [[ $volume_output == *"[MUTED]"* ]]; then
        DEFAULT_SINK_MUTED=1
    elif [[ $volume_output == *"[UNMUTED]"* ]]; then
        DEFAULT_SINK_MUTED=0
    fi
}

clamp_percentage() {
    local value=$1
    local limit=$2
    if (( value < 0 )); then
        value=0
    elif (( value > limit )); then
        value=$limit
    fi
    printf '%d' "$value"
}

print_status() {
    local rounded
    local limit
    local percentage
    local text
    local tooltip
    local class
    local alt
    local state_field=""

    rounded=$(awk -v v="$DEFAULT_SINK_VOLUME" 'BEGIN { printf "%d", int(v * 100 + 0.5) }')
    limit=$(awk -v v="$VOLUME_LIMIT" 'BEGIN { printf "%d", int(v * 100 + 0.5) }')
    percentage=$(clamp_percentage "$rounded" "$limit")

    if [[ $DEFAULT_SINK_MUTED -eq 1 ]]; then
        text=$(json_escape "${DEFAULT_SINK_DISPLAY_NAME}")
        percentage=0
        state_field=',"state":"muted"'
    else
        text=$(json_escape "${DEFAULT_SINK_DISPLAY_NAME}")
    fi

    local tooltip_lines=()
    tooltip_lines+=("ID: ${DEFAULT_SINK_ID}")
    tooltip_lines+=("Gain: ${DEFAULT_SINK_VOLUME}")
    if [[ $DEFAULT_SINK_MUTED -eq 1 ]]; then
        tooltip_lines+=("Muted: yes")
    else
        tooltip_lines+=("Muted: no")
    fi
    tooltip=$(json_escape "$(IFS=$'\n'; echo "${tooltip_lines[*]}")")

    class="default-sink"
    [[ $DEFAULT_SINK_MUTED -eq 1 ]] && class+=" muted"
    class=$(json_escape "$class")

    alt=$(json_escape "$DEFAULT_SINK_DISPLAY_NAME")

    printf '{"text":"%s","tooltip":"%s","percentage":%s,"class":"%s","alt":"%s"%s}\n' \
        "$text" "$tooltip" "$percentage" "$class" "$alt" "$state_field"
}

adjust_volume() {
    local delta=$1
    if wpctl set-volume @DEFAULT_AUDIO_SINK@ "$delta" --limit "$VOLUME_LIMIT" >/dev/null 2>&1; then
        signal_waybar
    fi
}

toggle_mute() {
    if wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle >/dev/null 2>&1; then
        signal_waybar
    fi
}

cycle_default_sink() {
    if command -v pulse-next-output >/dev/null 2>&1; then
        if pulse-next-output >/dev/null 2>&1; then
            signal_waybar
        fi
        return
    fi
    fallback_cycle_default_sink
}

fallback_cycle_default_sink() {
    local status_output
    status_output=$(wpctl status 2>&1) || return
    collect_sink_lines "$status_output"
    local ids=()
    local default_index=-1
    local idx=0
    for line in "${sink_lines[@]}"; do
        [[ -z $line ]] && continue
        if [[ $line =~ ^([*![:space:]]*)([0-9]+)\. ]]; then
            local flags=${BASH_REMATCH[1]}
            local sink_id=${BASH_REMATCH[2]}
            ids+=("$sink_id")
            if [[ $flags == *"*"* ]]; then
                default_index=$idx
            fi
            ((idx++))
        fi
    done
    if [[ ${#ids[@]} -eq 0 ]]; then
        return
    fi
    if (( default_index == -1 )); then
        default_index=0
    fi
    local next_index=$(( (default_index + 1) % ${#ids[@]} ))
    if wpctl set-default "${ids[$next_index]}" >/dev/null 2>&1; then
        signal_waybar
    fi
}

ACTION=${1:-status}

case "$ACTION" in
    volume-up)
        adjust_volume "${VOLUME_STEP}%+"
        ;;
    volume-down)
        adjust_volume "${VOLUME_STEP}%-"
        ;;
    toggle-mute)
        toggle_mute
        ;;
    next-sink)
        cycle_default_sink
        ;;
    *)
        if load_default_sink 0; then
            print_status
        fi
        ;;
esac
