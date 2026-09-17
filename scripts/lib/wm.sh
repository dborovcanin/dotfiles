# Sourced, not run: what the scripts need to know about the window manager.
#
# WM is sway, niri, hyprland, i3 or generic. It is taken from the environment when WM is
# already set, and otherwise worked out from the sockets each one leaves behind.

detect_wm() {
    if [[ -n ${SWAYSOCK:-} ]]; then echo sway
    elif [[ -n ${NIRI_SOCKET:-} ]]; then echo niri
    elif [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then echo hyprland
    elif [[ -n ${I3SOCK:-} ]] || i3-msg -t get_version >/dev/null 2>&1; then echo i3
    else echo generic
    fi
}

WM=${WM:-$(detect_wm)}

# Starts a shell command through the window manager, so it outlives the caller
# and lands on the workspace the window manager picks.
wm_exec() {
    case $WM in
        sway) swaymsg exec "$1" ;;
        niri) niri msg action spawn-sh -- "$1" ;;
        hyprland) hyprctl dispatch exec -- "$1" ;;
        i3) i3-msg -q exec "$1" ;;
        *) setsid -f sh -c "$1" ;;
    esac >/dev/null
}

# The program that locks the screen, by the name it carries once it is running,
# so that a script can wait for the lock to be lifted. Empty where there is none.
wm_locker() {
    case $WM in
        hyprland) echo hyprlock ;;
        sway | niri) echo swaylock ;;
        i3) echo i3lock ;;
        *) echo "" ;;
    esac
}

# The command that turns every monitor on or off, as a string for swayidle.
wm_monitors_cmd() {
    case $WM:$1 in
        sway:on) echo "swaymsg 'output * dpms on'" ;;
        sway:off) echo "swaymsg 'output * dpms off'" ;;
        niri:on) echo "niri msg action power-on-monitors" ;;
        niri:off) echo "niri msg action power-off-monitors" ;;
        hyprland:on) echo "hyprctl dispatch dpms on" ;;
        hyprland:off) echo "hyprctl dispatch dpms off" ;;
        *) echo true ;;
    esac
}
