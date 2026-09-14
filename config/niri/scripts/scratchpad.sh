#!/usr/bin/env bash
# Scratchpad for niri, which has none of its own.
#
# Hidden windows are floated and parked on the named workspace "scratch"
# (declared in config.kdl). Window ids sent there are remembered, so "show"
# on one of them hides it again, like sway's "scratchpad show".
#
# Usage: scratchpad.sh move   hide the focused window in the scratchpad
#        scratchpad.sh show   bring the latest scratchpad window to the current
#                             workspace, or hide the focused one if it is a
#                             scratchpad window
set -euo pipefail

WS="scratch"
STATE="${XDG_RUNTIME_DIR:-/tmp}/niri-scratchpad"
touch "$STATE"

hide() {
    local id="$1"
    niri msg action move-window-to-floating --id "$id"
    niri msg action move-window-to-workspace --window-id "$id" --focus false "$WS"
    grep -qx "$id" "$STATE" || echo "$id" >>"$STATE"
}

focused_id="$(niri msg --json focused-window | jq -r '.id // empty')"

case "${1:-}" in
    move)
        [ -n "$focused_id" ] && hide "$focused_id"
        ;;
    show)
        if [ -n "$focused_id" ] && grep -qx "$focused_id" "$STATE"; then
            hide "$focused_id"
            exit 0
        fi

        workspaces="$(niri msg --json workspaces)"
        scratch_ws="$(jq -r --arg ws "$WS" '.[] | select(.name == $ws) | .id' <<<"$workspaces")"
        # Index on the focused output, which is where an index reference lands.
        target_idx="$(jq -r '.[] | select(.is_focused) | .idx' <<<"$workspaces")"
        [ -n "$scratch_ws" ] && [ -n "$target_idx" ] || exit 0

        id="$(
            niri msg --json windows | jq -r --argjson ws "$scratch_ws" '
                [.[] | select(.workspace_id == $ws)]
                | sort_by(.focus_timestamp.secs // 0, .focus_timestamp.nanos // 0)
                | last
                | .id // empty'
        )"
        [ -n "$id" ] || exit 0

        niri msg action move-window-to-workspace --window-id "$id" --focus false "$target_idx"
        niri msg action focus-window --id "$id"
        ;;
    *)
        echo "Usage: $0 move|show" >&2
        exit 1
        ;;
esac
