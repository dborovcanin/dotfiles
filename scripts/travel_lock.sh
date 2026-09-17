#!/usr/bin/env bash
# Travel lock: lock the session and blank the screens while keeping the machine
# awake, so long-running jobs keep going with the lid closed. Suspend, lid
# switch and idle handling stay inhibited until the session is unlocked.
#
# Works under sway, niri and hyprland; anything else gets the lock without the
# blanking.
#
# Under hyprland this is nearly all hyprlock's own work: `path = screenshot`
# shoots the screen and blurs it without grim or magick, and hypridle does the
# blanking that swayidle does elsewhere. Both are handed a config written beside
# the real one at run time, because neither takes any of this on a command line.
#
# Usage: travel_lock.sh          start travel lock
#        travel_lock.sh --stop   drop the inhibitors (screen stays locked)
set -euo pipefail

source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/lib/wm.sh"
MONITORS_ON=$(wm_monitors_cmd on)
MONITORS_OFF=$(wm_monitors_cmd off)
LOCKER=$(wm_locker)
HYPRLOCK_CONF=${HYPRLOCK_CONF:-"$HOME/dotfiles/config/hypr/hyprlock.conf"}

INHIBIT_WHAT="handle-lid-switch:sleep:idle"
IDLE_TIMEOUT=5
RUNDIR="${XDG_RUNTIME_DIR:-/tmp}"
LOCKFILE="$RUNDIR/travel-lock.lock"
PIDFILE="$RUNDIR/travel-lock.pid"

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
        --who="$WM travel lock" \
        --why="Keeping background tasks running while commuting" \
        --mode=block \
        "$0" --inhibited
fi

# Phase 2: runs under the inhibitor.
IMG="$(mktemp /tmp/travel-lock-XXXXXX.png)"
BLUR="$(mktemp /tmp/travel-lock-blur-XXXXXX.png)"
LOCK_CONF="$RUNDIR/travel-lock-hyprlock.conf"
IDLE_CONF="$RUNDIR/travel-lock-hypridle.conf"
IDLE_PID=""

cleanup() {
    [ -n "$IDLE_PID" ] && kill "$IDLE_PID" 2>/dev/null || true
    eval "$MONITORS_ON" >/dev/null 2>&1 || true
    rm -f "$IMG" "$BLUR" "$LOCK_CONF" "$IDLE_CONF" "$PIDFILE"
}
trap cleanup EXIT INT TERM

echo $$ >"$PIDFILE"

eval "$MONITORS_ON" >/dev/null 2>&1 || true
sleep 0.2

# Lock, showing the screen as it was rather than the wallpaper, so that what was
# on it is hidden rather than advertised.
#
# hyprlock does the shot and the blur itself from `path = screenshot`; the config
# it is given is the themed one with that one line swapped, so the box, the
# clock and the colours stay as they are everywhere else. swaylock takes a
# picture on the command line, so grim and magick make one for it.
lock_screen() {
    if [ "$WM" = hyprland ]; then
        sed -e 's|^\( *\)path = .*|\1path = screenshot|' \
            -e 's|^\( *\)blur_passes = .*|\1blur_passes = 3|' \
            "$HYPRLOCK_CONF" >"$LOCK_CONF"
        hyprlock -c "$LOCK_CONF" &
        # Wait for it to be up before the inhibitor starts watching for it to go.
        while ! pgrep -x hyprlock >/dev/null; do sleep 0.1; done
        return 0
    fi

    local args
    args="-f -c 000000"
    if grim "$IMG" 2>/dev/null; then
        if magick "$IMG" -filter Gaussian -blur 0x6 "$BLUR" 2>/dev/null; then
            args="-f -i $BLUR"
        else
            args="-f -i $IMG"
        fi
    fi
    # shellcheck disable=SC2086
    swaylock $args
}

# Let the idle daemon own the monitor power state: blank after IDLE_TIMEOUT of
# inactivity, wake on any input, repeat for as long as the session stays locked.
# Do not blank the screen by hand here -- both daemons only fire "resume" once
# their own "timeout" has fired, so a manual blank leaves the wake-up unarmed,
# and input aimed at waking the screen keeps resetting the idle counter that
# would have armed it.
#
# hypridle reads a file where swayidle reads a command line, so it is given one.
watch_idle() {
    if [ "$WM" = hyprland ]; then
        cat >"$IDLE_CONF" <<EOF
listener {
    timeout = $IDLE_TIMEOUT
    on-timeout = $MONITORS_OFF
    on-resume = $MONITORS_ON
}
EOF
        hypridle -c "$IDLE_CONF" >/dev/null 2>&1 &
    else
        swayidle -w \
            timeout "$IDLE_TIMEOUT" "$MONITORS_OFF" \
            resume "$MONITORS_ON" >/dev/null 2>&1 &
    fi
    IDLE_PID=$!
}

lock_screen
watch_idle

# Hold the inhibitor until the screen is unlocked.
while [ -n "$LOCKER" ] && pgrep -x "$LOCKER" >/dev/null; do
    sleep 1
done
