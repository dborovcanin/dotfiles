#!/bin/sh

start_once() {
    app="$1"
    shift

    command -v "$app" >/dev/null 2>&1 || return 0
    if command -v pgrep >/dev/null 2>&1; then
        pgrep -x "$app" >/dev/null 2>&1 || "$app" "$@" >/dev/null 2>&1 &
    else
        "$app" "$@" >/dev/null 2>&1 &
    fi
}

start_once codium
start_once brave

# Start Slack only on workdays (Mon=1 ... Sun=7).
weekday="$(date '+%u')"
if [ "$weekday" -lt 6 ]; then
    sleep 5
    start_once slack
fi
