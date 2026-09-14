#!/usr/bin/env bash
# Travel lock: lock the session and blank the screens while keeping the machine
# awake, so long-running jobs keep going with the lid closed. Suspend, lid
# switch and idle handling stay inhibited until the session is unlocked.
#
# Usage: travel_lock.sh          start travel lock
#        travel_lock.sh --stop   drop the inhibitors (screen stays locked)
set -euo pipefail

INHIBIT_WHAT="handle-lid-switch:sleep:idle"
IDLE_TIMEOUT=5
RUNDIR="${XDG_RUNTIME_DIR:-/tmp}"
LOCKFILE="$RUNDIR/niri-travel-lock.lock"
PIDFILE="$RUNDIR/niri-travel-lock.pid"

if [ "${1:-}" = "--stop" ]; then
    if [ -s "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null; then
        echo "Travel lock stopped."
    else
        echo "Travel lock not running."
    fi
    exit 0
fi

# Phase 1: take the single-instance lock, then hand off to systemd-inhibit.
# The lock fd is inherited by systemd-inhibit and held for the whole session,
# so the re-exec'd phase 2 must not try to take it again.
if [ "${1:-}" != "--inhibited" ]; then
    exec 9>"$LOCKFILE"
    if ! flock -n 9; then
        notify-send -u low "Travel lock" "Already active" || true
        exit 0
    fi
    exec systemd-inhibit \
        --what="$INHIBIT_WHAT" \
        --who="niri travel lock" \
        --why="Keeping background tasks running while commuting" \
        --mode=block \
        "$0" --inhibited
fi

# Phase 2: runs under the inhibitor.
IMG="$(mktemp /tmp/travel-lock-XXXXXX.png)"
BLUR="$(mktemp /tmp/travel-lock-blur-XXXXXX.png)"
IDLE_PID=""

cleanup() {
    [ -n "$IDLE_PID" ] && kill "$IDLE_PID" 2>/dev/null || true
    niri msg action power-on-monitors >/dev/null 2>&1 || true
    rm -f "$IMG" "$BLUR" "$PIDFILE"
}
trap cleanup EXIT INT TERM

echo $$ >"$PIDFILE"

niri msg action power-on-monitors >/dev/null 2>&1 || true
sleep 0.2

LOCK_ARGS=(-f -c 000000)
if grim "$IMG" 2>/dev/null; then
    if magick "$IMG" -filter Gaussian -blur 0x6 "$BLUR" 2>/dev/null; then
        LOCK_ARGS=(-f -i "$BLUR")
    else
        LOCK_ARGS=(-f -i "$IMG")
    fi
fi

swaylock "${LOCK_ARGS[@]}"

# Let swayidle own the power state: blank after IDLE_TIMEOUT of inactivity,
# repeat for as long as the session stays locked. Niri wakes the monitors on
# any input by itself; the resume hook only makes that explicit.
swayidle -w \
    timeout "$IDLE_TIMEOUT" 'niri msg action power-off-monitors' \
    resume 'niri msg action power-on-monitors' >/dev/null 2>&1 &
IDLE_PID=$!

# Hold the inhibitor until the screen is unlocked.
while pgrep -x swaylock >/dev/null; do
    sleep 1
done
