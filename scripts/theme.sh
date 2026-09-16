#!/usr/bin/env bash
set -euo pipefail

# Writes a colour theme into every config and script of these dotfiles.
#
# Usage: theme.sh apply <name|path>   rewrite every theme block with that theme
#        theme.sh list                the themes in config/themes
#        theme.sh current             the theme applied last
#        theme.sh check               every theme block, and whether it can be drawn
#
# A theme is a file of THEME_* colours in config/themes (see gruvbox.sh). A
# themed file carries one or more blocks between two marker comments:
#
#     # theme:begin <block>
#     ...whatever render_<block> below prints...
#     # theme:end
#
# Everything between the markers is replaced on every apply and nothing outside
# them is touched, so edit a block's template here rather than in the file. The
# comment characters can be whatever the file's format needs. Nothing is reloaded
# or installed: copy the configs into place and reload what is running.

usage() {
    sed -n '4,21s/^# \{0,1\}//p' "$0"
}

root=$(realpath "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/..")
themes=$root/config/themes
self=$(realpath "${BASH_SOURCE[0]}")

# ---------------------------------------------------------------------------
# Blocks. Each prints the lines that go between its markers.
# ---------------------------------------------------------------------------

# The i3 and sway configs name their colours once and use the names everywhere.
render_wm() {
    cat <<EOF
set \$background $THEME_BG
set \$background_alt $THEME_BG_ALT
set \$foreground $THEME_FG
set \$primary $THEME_BORDER
set \$secondary $THEME_CYAN
set \$alert ${THEME_ANSI[1]}
set \$disabled $THEME_DIM
EOF
}

render_niri_background() {
    printf '    background-color "%s"\n' "$THEME_BG"
}

render_niri_border() {
    cat <<EOF
        active-color "$THEME_BORDER"
        inactive-color "$THEME_BG_ALT"
        urgent-color "${THEME_ANSI[1]}"
EOF
}

render_niri_tabs() {
    cat <<EOF
        active-color "$THEME_BORDER"
        inactive-color "$THEME_DIM"
        urgent-color "${THEME_ANSI[1]}"
EOF
}

# foot and the Xresources terminals want the sixteen colours; foot without '#'.
render_foot() {
    local i
    printf 'foreground=%s\nbackground=%s\n\n' "${THEME_FG#\#}" "${THEME_BG#\#}"
    for i in {0..7}; do printf 'regular%d=%s\n' "$i" "${THEME_ANSI[i]#\#}"; done
    echo
    for i in {0..7}; do printf 'bright%d=%s\n' "$i" "${THEME_ANSI[i + 8]#\#}"; done
    printf '\nselection-foreground=%s\nselection-background=%s\n\n' \
        "${THEME_FG#\#}" "${THEME_BG_ALT#\#}"
    printf 'urls=%s\n' "${THEME_BLUE#\#}"
}

render_alacritty() {
    local names=(black red green yellow blue magenta cyan white) i
    printf '[colors.primary]\nbackground = '\''%s'\''\nforeground = '\''%s'\''\n' "$THEME_BG" "$THEME_FG"
    printf '\n[colors.normal]\n'
    for i in {0..7}; do printf "%-7s = '%s'\n" "${names[i]}" "${THEME_ANSI[i]}"; done
    printf '\n[colors.bright]\n'
    for i in {0..7}; do printf "%-7s = '%s'\n" "${names[i]}" "${THEME_ANSI[i + 8]}"; done
}

# The [90] in front of the background is the terminal's transparency.
render_urxvt() {
    local i
    printf 'URxvt*background:                     [90]%s\n' "$THEME_BG"
    printf 'URxvt*foreground:                     %s\n' "$THEME_FG"
    printf 'URxvt*cursorColor:                    %s\n' "$THEME_ACCENT"
    printf 'URxvt*scrollColor:                    %s\n' "$THEME_FG"
    printf 'URxvt*highlightColor:                 %s\n' "$THEME_BG_ALT"
    printf 'URxvt*highlightTextColor:             %s\n\n' "$THEME_FG"
    for i in {0..15}; do
        printf 'URxvt*color%-27s%s\n' "$i:" "${THEME_ANSI[i]}"
    done
}

render_xmenus() {
    cat <<EOF
rofi.color-enabled: true
rofi.color-window: $THEME_BG, $THEME_BORDER, $THEME_BG
rofi.color-normal: $THEME_BG, $THEME_FG, $THEME_BG, $THEME_BG_ALT, $THEME_ACCENT
rofi.color-active: $THEME_BG, $THEME_BLUE, $THEME_BG, $THEME_BG_ALT, $THEME_BLUE
rofi.color-urgent: $THEME_BG, $THEME_RED, $THEME_BG, $THEME_BG_ALT, $THEME_RED
rofi.modi: run,drun,window

dmenu.selforeground:	    $THEME_BG
dmenu.background:	        $THEME_BG
dmenu.selbackground:	    $THEME_ACCENT
dmenu.foreground:	        $THEME_FG
EOF
}

render_polybar() {
    cat <<EOF
background = $THEME_BG
background-alt = $THEME_BG_ALT
foreground = $THEME_FG
primary = $THEME_ACCENT
secondary = $THEME_CYAN
alert = ${THEME_ANSI[1]}
disabled = $THEME_DIM
EOF
}

render_dbar() {
    cat <<EOF
background = "$THEME_BG"
surface = "$THEME_BG_ALT"
raised = "$THEME_BG_RAISED"
text = "$THEME_FG_ALT"
subtext = "$THEME_SUBTLE"
accent = "$THEME_BLUE"
warning = "$THEME_YELLOW"
critical = "$THEME_RED"
EOF
}

# i3status-rust ships no theme for most palettes, so every state is overridden.
render_i3status() {
    cat <<EOF
separator_fg = "$THEME_FG"
idle_bg = "$THEME_BG"
idle_fg = "$THEME_FG"
info_bg = "${THEME_ANSI[4]}"
info_fg = "$THEME_ON_COLOR"
good_bg = "${THEME_ANSI[2]}"
good_fg = "$THEME_ON_COLOR"
warning_bg = "${THEME_ANSI[3]}"
warning_fg = "$THEME_ON_COLOR"
critical_bg = "${THEME_ANSI[1]}"
critical_fg = "$THEME_ON_COLOR"
EOF
}

render_dunst_global() {
    cat <<EOF
    frame_color = "$THEME_BORDER"
    separator_color = "$THEME_BG_RAISED"
EOF
}

render_dunst_urgency() {
    cat <<EOF
[urgency_low]
    background = "$THEME_BG"
    foreground = "$THEME_SUBTLE"
    timeout = 20

[urgency_normal]
    background = "$THEME_BG"
    foreground = "$THEME_FG"
    timeout = 20

[urgency_critical]
    background = "$THEME_BG"
    foreground = "$THEME_FG"
    frame_color = "$THEME_RED"
    timeout = 0
EOF
}

render_tmux() {
    printf 'set -g status-bg "%s"\nset -g status-fg "%s"\n' "$THEME_BG_ALT" "$THEME_FG"
}

render_helix() {
    printf 'theme = "%s"\n' "$THEME_HELIX"
}

render_rofi() {
    cat <<EOF
    bg: $THEME_BG;
    bg-alt: $THEME_BG_ALT;
    fg: $THEME_FG;
    fg-alt: $THEME_FG_ALT;
    dim: $THEME_DIM;
    frame: $THEME_BORDER;
    accent: $THEME_ACCENT;
    urgent: $THEME_RED;
EOF
}

render_power() {
    cat <<EOF
BG=\${POWER_BG:-"$THEME_BG"}           # window
BG_ALPHA=\${POWER_BG_ALPHA:-ff}      # opaque; the last byte of the window colour
FG=\${POWER_FG:-"$THEME_FG"}           # tile labels
BORDER=\${POWER_BORDER:-"$THEME_BORDER"}   # the frame around the window
TILE=\${POWER_TILE:-"$THEME_BG_ALT"}       # behind the tile under the cursor
ACCENT=\${POWER_ACCENT:-"$THEME_ACCENT"}   # the frame of the tile under the cursor, the title
DIM=\${POWER_DIM:-"$THEME_DIM"}         # keys and uptime
DANGER=\${POWER_DANGER:-"$THEME_RED"}   # the frame of the tile in a confirmation

# One colour per action, so the tile you want is found by colour before its
# label is read.
C_LOCK=\${POWER_LOCK_COLOR:-"$THEME_BLUE"}
C_TRAVEL=\${POWER_TRAVEL_COLOR:-"$THEME_GREEN"}
C_LOGOUT=\${POWER_LOGOUT_COLOR:-"$THEME_MAGENTA"}
C_SUSPEND=\${POWER_SUSPEND_COLOR:-"$THEME_YELLOW"}
C_HIBERNATE=\${POWER_HIBERNATE_COLOR:-"$THEME_CYAN"}
C_REBOOT=\${POWER_REBOOT_COLOR:-"$THEME_ORANGE"}
C_SHUTDOWN=\${POWER_SHUTDOWN_COLOR:-"$THEME_RED"}
EOF
}

render_calendar() {
    cat <<EOF
BG=\${CAL_BG:-"$THEME_BG"}             # window, and the text on the selected day
BG_ALPHA=\${CAL_BG_ALPHA:-ff}        # opaque; the last byte of the window colour
FG=\${CAL_FG:-"$THEME_FG"}             # the days themselves
BORDER=\${CAL_BORDER:-"$THEME_BORDER"}     # the frame around the window
ACCENT=\${CAL_ACCENT:-"$THEME_ACCENT"}     # the date line at the top
SELECTED=\${CAL_SELECTED:-"$THEME_BORDER"} # behind the day under the cursor
TODAY=\${CAL_TODAY:-"$THEME_CYAN"}       # today, when it is not the day under the cursor
WEEKEND=\${CAL_WEEKEND:-"$THEME_RED"}   # Sunday
HEADING=\${CAL_HEADING:-"$THEME_SUBTLE"}   # the names of the weekdays
RULE=\${CAL_RULE:-"$THEME_BG_RAISED"}         # the lines between the parts
KEY=\${CAL_KEY:-"$THEME_FG_ALT"}           # the keys in the hint line
DIM=\${CAL_DIM:-"$THEME_DIM"}           # what the keys do
EOF
}

render_clipboard() {
    printf 'key_color="%s"\n' "$THEME_FG_ALT"
}

# ---------------------------------------------------------------------------
# Hooks that run after a file's blocks are written, for colours a format will
# not let a block hold.
# ---------------------------------------------------------------------------

# polybar cannot reference its [colors] inside %{F...} tags, so the tags are
# repainted by matching the colours the block held before it was rewritten.
# Every old colour becomes a placeholder first, so a new colour that equals
# some other old one is not repainted twice.
declare -A polybar_before=()
before_polybar() {
    local key value
    polybar_before=()
    while IFS=' =' read -r key value; do
        polybar_before[$key]=$value
    done < <(sed -n '/theme:begin polybar/,/theme:end/{/=/p}' "$1")
}

after_polybar() {
    local key new script=
    for key in "${!polybar_before[@]}"; do
        script+="s/%{F${polybar_before[$key]}}/%{F@$key@}/Ig;"
    done
    while IFS=' =' read -r key new; do
        script+="s/%{F@$key@}/%{F$new}/g;"
    done < <(render_polybar)
    sed -i "$script" "$1"
}

# ---------------------------------------------------------------------------

marked_files() {
    grep -rlI --exclude-dir=.git -E 'theme:begin [a-z]' "$root" | grep -vxF "$self" | sort
}

blocks_in() {
    grep -oE 'theme:begin [a-z0-9-]+' "$1" | cut -d' ' -f2
}

load_theme() {
    local theme=$1 file
    if [[ $theme == */* ]]; then file=$theme; else file=$themes/$theme.sh; fi
    [[ -r $file ]] || { echo "theme.sh: no theme at $file" >&2; exit 1; }
    # shellcheck source=../config/themes/gruvbox.sh
    source "$themes/gruvbox.sh"
    # shellcheck disable=SC1090
    source "$file"
}

apply() {
    local theme=${1:?apply needs a theme name or path}
    load_theme "$theme"

    local file block fn rel status=0
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT

    # Everything is drawn before anything is written, so an unknown block or a
    # broken theme leaves every file as it was.
    while read -r file; do
        for block in $(blocks_in "$file"); do
            fn=render_${block//-/_}
            if ! declare -F "$fn" >/dev/null; then
                echo "theme.sh: ${file#"$root"/}: no render_${block//-/_} for block '$block'" >&2
                status=1
                continue
            fi
            "$fn" >"$tmp/$block"
        done
    done < <(marked_files)
    ((status == 0)) || exit "$status"

    while read -r file; do
        rel=${file#"$root"/}
        for block in $(blocks_in "$file"); do
            declare -F "before_${block//-/_}" >/dev/null && "before_${block//-/_}" "$file"
        done
        awk -v dir="$tmp" -v name="$rel" '
            match($0, /theme:begin [a-z0-9-]+/) {
                print
                block = dir "/" substr($0, RSTART + 12, RLENGTH - 12)
                while ((getline line < block) > 0) print line
                close(block)
                inside = 1
                next
            }
            /theme:end/ { inside = 0 }
            !inside { print }
            END {
                if (inside) {
                    print "theme.sh: " name ": theme:begin without theme:end" > "/dev/stderr"
                    exit 1
                }
            }
        ' "$file" >"$tmp/out"
        # Written over rather than moved, so the file keeps its mode and links.
        cat "$tmp/out" >"$file"
        for block in $(blocks_in "$file"); do
            declare -F "after_${block//-/_}" >/dev/null && "after_${block//-/_}" "$file"
        done
        echo "  $rel"
    done < <(marked_files)

    if [[ $theme == */* ]]; then realpath "$theme"; else echo "$theme"; fi >"$themes/current"
    echo "Applied $theme. Copy the configs into place and reload sway, niri, dunst and tmux."
}

case ${1:-} in
    apply) apply "${2:-}" ;;
    list) for f in "$themes"/*.sh; do basename "$f" .sh; done ;;
    current) cat "$themes/current" 2>/dev/null || echo "none applied yet" ;;
    check)
        while read -r file; do
            for block in $(blocks_in "$file"); do
                if declare -F "render_${block//-/_}" >/dev/null; then mark=ok; else mark=MISSING; fi
                printf '%-8s %-40s %s\n' "$mark" "${file#"$root"/}" "$block"
            done
        done < <(marked_files)
        ;;
    -h | --help | help) usage ;;
    *) usage >&2; exit 2 ;;
esac
