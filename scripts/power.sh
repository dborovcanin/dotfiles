#!/usr/bin/env bash
set -euo pipefail

# A power menu that works under whatever window manager is running.
#
# It is the system mode from config/sway/config drawn as a row of tiles: the
# same keys still do the same things the moment they are pressed (l lock,
# t travel lock, e logout, s suspend, h hibernate, r reboot, Shift+s shutdown),
# and the arrows with Return pick a tile for when the keys are forgotten.
# Logging out, rebooting and shutting down ask once more before they happen,
# because a stray Return here costs everything that was open.
#
# Usage: power.sh [--wm sway|niri|i3|hyprland|generic]
#
# Only locking, logging out and the travel lock depend on the window manager.
# Without --wm (or POWER_WM) it is worked out from the sockets each one leaves
# in the environment, and anything unknown falls back to loginctl.

usage() {
    sed -n '4,17s/^# \{0,1\}//p' "$0"
}

WM=${POWER_WM:-}
while (($#)); do
    case $1 in
        -w | --wm) WM=${2:?--wm needs a value}; shift 2 ;;
        --wm=*) WM=${1#--wm=}; shift ;;
        -h | --help) usage; exit 0 ;;
        *) echo "power.sh: unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ -z $WM ]]; then
    if [[ -n ${SWAYSOCK:-} ]]; then WM=sway
    elif [[ -n ${NIRI_SOCKET:-} ]]; then WM=niri
    elif [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then WM=hyprland
    elif [[ -n ${I3SOCK:-} ]] || i3-msg -t get_version >/dev/null 2>&1; then WM=i3
    else WM=generic
    fi
fi

# Same family as config/sway/foot.ini; the icons are what is read first, so
# they get a size of their own well above the labels.
FONT=${POWER_FONT:-"JetBrainsMonoNL NF 14"}
ICON_SIZE=${POWER_ICON_SIZE:-30pt}
KEY_SIZE=${POWER_KEY_SIZE:-10pt}

# The gruvbox dark of config/sway/foot.ini, the same one the calendar in
# scripts/dbar/sway_calendar.sh is painted with. Every colour can be swapped
# from the environment without touching the file.
BG=${POWER_BG:-"#282828"}           # window
BG_ALPHA=${POWER_BG_ALPHA:-ff}      # opaque; the last byte of the window colour
FG=${POWER_FG:-"#ebdbb2"}           # tile labels
BORDER=${POWER_BORDER:-"#d79921"}   # the frame around the window
TILE=${POWER_TILE:-"#3c3836"}       # behind the tile under the cursor
ACCENT=${POWER_ACCENT:-"#fabd2f"}   # the frame of the tile under the cursor, the title
DIM=${POWER_DIM:-"#928374"}         # keys and uptime
DANGER=${POWER_DANGER:-"#fb4934"}   # the frame of the tile in a confirmation

# One colour per action, so the tile you want is found by colour before its
# label is read.
C_LOCK=${POWER_LOCK_COLOR:-"#83a598"}
C_TRAVEL=${POWER_TRAVEL_COLOR:-"#b8bb26"}
C_LOGOUT=${POWER_LOGOUT_COLOR:-"#d3869b"}
C_SUSPEND=${POWER_SUSPEND_COLOR:-"#fabd2f"}
C_HIBERNATE=${POWER_HIBERNATE_COLOR:-"#8ec07c"}
C_REBOOT=${POWER_REBOOT_COLOR:-"#fe8019"}
C_SHUTDOWN=${POWER_SHUTDOWN_COLOR:-"#fb4934"}

LOCK_IMAGE=${POWER_LOCK_IMAGE:-"$HOME/Downloads/bg-blur.jpg"}
CONFIRM=${POWER_CONFIRM:-"logout reboot shutdown"}

# Nerd Font glyphs, spelled as code points so the file survives an editor that
# does not have the font.
I_POWER=$'\U000F0425'
I_LOCK=$'\U000F033E'
I_TRAVEL=$'\U000F001D'
I_LOGOUT=$'\U000F0343'
I_SUSPEND=$'\U000F04B2'
I_HIBERNATE=$'\U000F0717'
I_REBOOT=$'\U000F0709'
I_CANCEL=$'\U000F0156'

here=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

lock_cmd() {
    case $WM in
        sway | niri | hyprland)
            if [[ -f $LOCK_IMAGE ]]; then
                swaylock -f -i "$LOCK_IMAGE"
            else
                swaylock -f -c "${BG#\#}"
            fi
            ;;
        # i3lock reads only PNG, so the blurred JPEG sway locks with is no use to
        # it and it gets the plain background instead.
        i3) i3lock -c "${BG#\#}" ;;
        *) loginctl lock-session ;;
    esac
}

logout_cmd() {
    case $WM in
        sway) swaymsg exit ;;
        niri) niri msg action quit --skip-confirmation ;;
        hyprland) hyprctl dispatch exit ;;
        i3) i3-msg exit ;;
        *) loginctl terminate-session "${XDG_SESSION_ID:-}" ;;
    esac
}

# The travel lock blanks outputs with swaymsg and shoots them with grim, so it is
# offered only where it can work: under sway, or wherever POWER_TRAVEL_CMD
# names something that does the same job.
travel_cmd() {
    if [[ -n ${POWER_TRAVEL_CMD:-} ]]; then
        eval "$POWER_TRAVEL_CMD"
    else
        # It holds on until the screen is unlocked, and this menu should not.
        setsid -f "$here/sway/travel_lock.sh" >/dev/null 2>&1
    fi
}

can() {
    local answer
    answer=$(busctl call org.freedesktop.login1 /org/freedesktop/login1 \
        org.freedesktop.login1.Manager "Can$1" 2>/dev/null) || return 1
    [[ $answer == *'"yes"'* || $answer == *'"challenge"'* ]]
}

# Each action runs its POWER_<ID>_CMD when one is set, so any of them can be
# pointed somewhere else without editing the file.
run() {
    local id=$1 override="POWER_${1^^}_CMD"
    if [[ -n ${!override:-} ]]; then
        eval "${!override}"
        return
    fi
    case $id in
        lock) lock_cmd ;;
        travel) travel_cmd ;;
        logout) logout_cmd ;;
        suspend) systemctl suspend ;;
        hibernate) systemctl hibernate ;;
        reboot) systemctl reboot ;;
        shutdown) systemctl poweroff ;;
    esac
}

IDS=() ICONS=() COLORS=() LABELS=() KEYS=() KEY_NAMES=()
add() {
    IDS+=("$1") ICONS+=("$2") COLORS+=("$3") LABELS+=("$4")
    KEYS+=("$5") KEY_NAMES+=("$6")
}

add lock "$I_LOCK" "$C_LOCK" Lock l l
if [[ $WM == sway || -n ${POWER_TRAVEL_CMD:-} ]]; then
    add travel "$I_TRAVEL" "$C_TRAVEL" Travel t t
fi
add logout "$I_LOGOUT" "$C_LOGOUT" Logout e e
can Suspend && add suspend "$I_SUSPEND" "$C_SUSPEND" Suspend s s
can Hibernate && add hibernate "$I_HIBERNATE" "$C_HIBERNATE" Hibernate h h
add reboot "$I_REBOOT" "$C_REBOOT" Reboot r r
add shutdown "$I_POWER" "$C_SHUTDOWN" Shutdown Shift+s S

# A tile is three lines - icon, label, key - handed to rofi as one entry, which
# is why entries are split on | rather than on the newlines inside them.
tile() {
    printf '<span size="%s" foreground="%s">%s</span>\n%s\n<span size="%s" foreground="%s">%s</span>' \
        "$ICON_SIZE" "$2" "$1" "$3" "$KEY_SIZE" "$DIM" "$4"
}

# Every tile is as wide as the longest label, "Hibernate", with room either side,
# and the window is exactly as wide as the tiles it holds, so dropping one
# (hibernate without swap, travel off sway) shrinks the window rather than
# leaving a hole in it.
theme() {
    local count=$1 frame=$2
    local tile_ch=10 gap=12 pad=24 border=2
    cat <<EOF
window {
    location: center;
    anchor: center;
    width: calc( $((count * tile_ch))ch + $(((count - 1) * gap + 2 * (pad + border)))px );
    background-color: $BG$BG_ALPHA;
    border: ${border}px solid;
    border-color: $BORDER;
    border-radius: 16px;
    padding: ${pad}px;
}
* { font: "$FONT"; text-color: $FG; background-color: transparent; }
mainbox { children: [ message, listview ]; spacing: 20px; padding: 0; border: 0; }
message { padding: 0; border: 0; }
textbox { horizontal-align: 0.5; }
listview {
    columns: $count; lines: 1; fixed-columns: true; fixed-height: false;
    spacing: ${gap}px; padding: 0; border: 0; scrollbar: false;
    flow: horizontal;
}
element {
    padding: 14px 0;
    border: 2px solid;
    border-radius: 12px;
    orientation: vertical;
}
element normal.normal, element alternate.normal,
element normal.active, element alternate.active,
element normal.urgent, element alternate.urgent {
    background-color: transparent;
    border-color: transparent;
    text-color: $FG;
}
element selected.normal, element selected.active, element selected.urgent {
    background-color: $TILE;
    border-color: $frame;
    text-color: $FG;
}
element-icon { enabled: false; }
element-text {
    background-color: transparent;
    text-color: inherit;
    horizontal-align: 0.5;
    vertical-align: 0.5;
}
EOF
}

# rofi has no switch for filtering, so every tile carries the alphabet many
# times over in a second column that is matched but never shown, and fuzzy
# matching finds whatever was typed somewhere in all of them alike. rofi's own
# row metadata would read better, but dmenu never matches against it.
entries() {
    local keywords first=1
    printf -v keywords '%.0sabcdefghijklmnopqrstuvwxyz0123456789' {1..8}
    while (($#)); do
        ((first)) || printf '|'
        first=0
        tile "$1" "$2" "$3" "$4"
        printf '\t%s' "$keywords"
        shift 4
    done
}

# rofi with every key a tile answers to bound as a custom key, so pressing one
# ends rofi at once with an exit code naming the tile. Return ends it with 0 and
# the index of the tile under the cursor instead. Either way the index of the
# chosen tile is printed, and nothing is printed when it was dismissed.
#
# Letters that belong to no tile would otherwise filter the list behind an input
# bar nobody can see, and every tile would vanish.
pick() {
    local mesg=$1 frame=$2 selected=$3
    shift 3
    local -a binds=() tiles=()
    local i=0 status out
    while (($#)); do
        tiles+=("$1" "$2" "$3" "$4")
        binds+=(-kb-custom-$((i + 1)) "$5")
        shift 5
        i=$((i + 1))
    done

    set +e
    out=$(entries "${tiles[@]}" | rofi -dmenu -sep '|' -eh 4 -markup-rows \
        -matching fuzzy -display-columns 1 -display-column-separator '\t' \
        -format i -selected-row "$selected" -mesg "$mesg" -no-custom \
        -theme-str "$(theme "$i" "$frame")" \
        -kb-move-char-back "" -kb-move-char-forward "" \
        -kb-element-prev "Left,ISO_Left_Tab" -kb-element-next "Right,Tab" \
        -kb-custom-1 "" -kb-custom-2 "" -kb-custom-3 "" -kb-custom-4 "" \
        -kb-custom-5 "" -kb-custom-6 "" -kb-custom-7 "" \
        -kb-screenshot "" \
        -kb-cancel "Escape,q" \
        "${binds[@]}")
    status=$?
    set -e

    # Anything else - rofi dismissed, killed or failing - chooses nothing.
    if ((status == 0)) && [[ $out =~ ^[0-9]+$ ]] && ((out < i)); then
        printf '%s\n' "$out"
    elif ((status >= 10 && status < 10 + i)); then
        printf '%s\n' $((status - 10))
    fi
    return 0
}

title() {
    printf '<span foreground="%s"><b>%s  %s</b></span>' "$ACCENT" "$1" "$2"
    [[ -z ${3:-} ]] || printf '<span foreground="%s">  ·  %s</span>' "$DIM" "$3"
}

host=$(hostnamectl hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo localhost)
uptime=$(uptime -p 2>/dev/null | sed 's/^up //')

args=()
for i in "${!IDS[@]}"; do
    args+=("${ICONS[i]}" "${COLORS[i]}" "${LABELS[i]}" "${KEY_NAMES[i]}" "${KEYS[i]}")
done
choice=$(pick "$(title "$I_POWER" "$USER@$host" "up $uptime")" "$ACCENT" 0 "${args[@]}")
[[ -n $choice ]] || exit 0

id=${IDS[choice]}
if [[ " $CONFIRM " == *" $id "* ]]; then
    # Cancel sits under the cursor, so a second Return in a row changes nothing.
    # Two tiles leave no room for more of a title than the question itself.
    answer=$(pick "$(title "${ICONS[choice]}" "${LABELS[choice]} now?")" \
        "$DANGER" 1 \
        "${ICONS[choice]}" "${COLORS[choice]}" "${LABELS[choice]}" y y \
        "$I_CANCEL" "$DIM" Cancel n n)
    [[ $answer == 0 ]] || exit 0
fi

run "$id"
