#!/usr/bin/env bash
set -euo pipefail

# A calendar you glance at and dismiss.
#
# Bind it to a key or hang it off the bar clock; it draws itself and needs no
# wrapper. The window lasts only as long as you are looking at it: the arrows
# walk a day at a time, ctrl with them walks whole months, t comes back to
# today, and Escape, q, space or Return close it.
#
# Run with no arguments it starts rofi and hands it this same file as a script
# mode, so everything below happens twice over: once to open the window, and
# then again, in a fresh shell, for every key you press.

# Same family as config/sway/foot.ini, one size up, because this is read at a
# glance from across the desk.
FONT="JetBrainsMonoNL NF 18"

# The gruvbox that config/sway/foot.ini paints the terminal with, so the
# calendar belongs to the rest of the desktop rather than to rofi's own theme.
# The window carries foot's alpha=.9 as the last byte of its background.
FG="#ebdbb2"
BG="#282828e6"
RED="#cc241d"
DIM="#928374"

# rofi eats the spaces a row starts with, so every left margin is built out of
# a space it cannot see through.
NB=$'\xc2\xa0'

# The bar clock that opens this sits at the top middle, so the window belongs up
# near it rather than in the middle of the screen. A month is 20 columns; the
# long date line and the hint set the real width, and the twelve lines are the
# whole calendar, so the list never scrolls and the window never changes size.
#
# The calendar arrives as rows because a script mode talks to rofi one line at a
# time and a message could not hold the newlines. Rows come with a cursor of
# rofi's own, which would sit on a line of the grid and mean nothing, so the
# selected row is painted like every other one.
THEME="
window {
    location: north;
    anchor: north;
    y-offset: 137px;
    width: 32ch;
    background-color: $BG;
    border: 0;
    padding: 16px;
}
* { font: \"$FONT\"; text-color: $FG; background-color: transparent; }
mainbox { children: [ listview ]; padding: 0; spacing: 0; border: 0; }
listview {
    lines: 12; columns: 1; spacing: 0; padding: 0;
    scrollbar: false; border: 0; fixed-height: true;
}
element { padding: 0; spacing: 0; border: 0; }
element normal.normal, element alternate.normal, element selected.normal,
element normal.active, element alternate.active, element selected.active,
element normal.urgent, element alternate.urgent, element selected.urgent {
    background-color: transparent;
    text-color: $FG;
}
element-text { background-color: transparent; text-color: inherit; }
"

if [[ -z ${ROFI_RETV:-} ]]; then
    self=$(realpath "${BASH_SOURCE[0]}")
    # Every key we care about has to be taken off whatever already owns it, or
    # rofi refuses the binding. Return joins the ways out because a list you
    # cannot pick anything from has nothing to accept.
    exec rofi -modi "calendar:$self" -show calendar -theme-str "$THEME" \
        -kb-move-char-back "" -kb-move-char-forward "" \
        -kb-move-word-back "" -kb-move-word-forward "" \
        -kb-row-up "" -kb-row-down "" -kb-accept-entry "" \
        -kb-cancel "Escape,q,space,Return" \
        -kb-custom-1 "Left,h" -kb-custom-2 "Right,l" \
        -kb-custom-3 "Up,k" -kb-custom-4 "Down,j" \
        -kb-custom-5 "Control+Left,p" -kb-custom-6 "Control+Right,n" \
        -kb-custom-7 "t"
fi

# Walking a month at a time is not date arithmetic date(1) will do for us: it
# reads "1 month" from the 31st as "the 31st of a month that has 30 days" and
# lands in the one after. Count the months by hand and pull the day back to the
# last one the target month actually has.
shift_month() {
    local year=$((10#${1:0:4})) month=$((10#${1:5:2})) day=$((10#${1:8:2}))
    local total=$((year * 12 + month - 1 + $2))
    local to_year=$((total / 12)) to_month=$((total % 12 + 1)) last
    last=$(date -d "$to_year-$to_month-01 +1 month -1 day" +%-d)
    ((day <= last)) || day=$last
    printf '%04d-%02d-%02d\n' "$to_year" "$to_month" "$day"
}

render() {
    local year=$((10#${1:0:4})) month=$((10#${1:5:2})) day=$((10#${1:8:2}))
    # cal only marks today when it is the month on screen, so tell awk which day
    # to mark and let it mark nothing while you are browsing another month.
    local today=0
    if [[ ${1:0:7} == "$(date +%Y-%m)" ]]; then
        today=$((10#$(date +%d)))
    fi

    printf '%s%s\n%s\n' "$NB$NB" "$(date -d "$1" '+%A, %-d %B %Y')" "$NB"
    # -m starts the week on Monday, which is what the calendar on the wall does
    # here; the locale is en_US and would otherwise start it on Sunday. That
    # also puts Sunday in the last of the seven fixed three-column slots, which
    # is what makes painting it red a matter of counting columns.
    cal -m "$month" "$year" | awk -v today="$today" -v day="$day" \
        -v fg="$FG" -v bg="$BG" -v red="$RED" '
        BEGIN {
            # Pango has no reverse video, so the day under the cursor swaps the
            # two colours by hand. Nested spans let the inner one win, which is
            # what keeps a marked Sunday readable instead of red on red.
            mark = "<span background=\"" fg "\" foreground=\"" substr(bg, 1, 7) "\">"
            under = "<span underline=\"single\">"
            paint = "<span foreground=\"" red "\">"
            off = "</span>"
            # rofi eats the spaces a row starts with, so the left margin has to
            # be one it cannot see through: U+00A0, five times over.
            pad = "\302\240\302\240\302\240\302\240\302\240"
        }
        NR == 1 { gsub(/ /, "\302\240"); print pad $0; next }
        {
            line = ""
            for (i = 1; i <= 7; i++) {
                day_in = substr($0, (i - 1) * 3 + 1, 2)
                # A week that starts mid-week is padded with spaces rofi would
                # eat as readily as the margin, so those go non-breaking too.
                # It has to happen before the markup goes on, or the spaces
                # between a span attributes become non-breaking with them.
                cell = day_in
                gsub(/ /, "\302\240", cell)
                if (day_in ~ /[0-9]/) {
                    # The day you are on is the one under the cursor; today is
                    # only ever the second mark, and only in its own month.
                    if (day_in + 0 == day) cell = mark cell off
                    else if (day_in + 0 == today) cell = under cell off
                }
                if (i == 7 && day_in ~ /[[:alnum:]]/) cell = paint cell off
                line = line (i > 1 ? "\302\240" : "") cell
            }
            print pad line
        }
        # A short month prints five week rows, a long one six. Pad to the six the
        # window is sized for, so it does not change height as you walk through
        # the year. An empty row is one rofi drops on the floor, so the padding
        # is a row holding the margin and nothing else.
        END { while (NR++ < 8) print pad }'
    printf '%s\n<span foreground="%s">%s←→ day   ^←^→ month   t   q</span>\n' \
        "$NB" "$DIM" "$NB$NB"
}

sel=${ROFI_DATA:-$(date +%F)}

case $ROFI_RETV in
    10) sel=$(date -d "$sel -1 day" +%F) ;;
    11) sel=$(date -d "$sel +1 day" +%F) ;;
    12) sel=$(date -d "$sel -7 days" +%F) ;;
    13) sel=$(date -d "$sel +7 days" +%F) ;;
    14) sel=$(shift_month "$sel" -1) ;;
    15) sel=$(shift_month "$sel" 1) ;;
    16) sel=$(date +%F) ;;
esac

# The day on screen is the only state there is, and rofi hands it back to the
# next shell as ROFI_DATA.
printf '\0data\x1f%s\n' "$sel"
# Without use-hot-keys the custom bindings never reach a script mode at all.
printf '\0use-hot-keys\x1ftrue\n'
printf '\0markup-rows\x1ftrue\n'
printf '\0no-custom\x1ftrue\n'
printf '\0keep-selection\x1ftrue\n'
render "$sel"
