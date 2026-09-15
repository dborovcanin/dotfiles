#!/usr/bin/env bash
set -euo pipefail

# A calendar you glance at and dismiss.
#
# Bind it to a key or hang it off the bar clock; it draws itself and needs no
# wrapper. The window lasts only as long as you are looking at it: the arrows
# walk a day at a time, up and down a week, ctrl with left and right walks whole
# months, t comes back to today, and Escape, q, space or Return close it.
#
# Run with no arguments it starts rofi and hands it this same file as a script
# mode, so everything below happens twice over: once to open the window, and
# then again, in a fresh shell, for every key you press. Anything exported into
# the first run reaches every later one, which is what makes the CAL_* overrides
# below stick for the whole life of the window.

# Same family as config/sway/foot.ini, one size up, because this is read at a
# glance from across the desk. The hint line is not read so much as remembered,
# so it gets out of the way at a size of its own.
FONT=${CAL_FONT:-"JetBrainsMonoNL NF 18"}
HINT_SIZE=${CAL_HINT_SIZE:-11pt}

# The gruvbox dark that config/sway/foot.ini paints the terminal with, so the
# calendar belongs to the rest of the desktop rather than to rofi's own theme.
# Every colour can be swapped from the environment without touching the file.
BG=${CAL_BG:-"#282828"}             # window, and the text on the selected day
BG_ALPHA=${CAL_BG_ALPHA:-e6}        # foot's alpha=.9, as the last byte of the window
FG=${CAL_FG:-"#ebdbb2"}             # the days themselves
BORDER=${CAL_BORDER:-"#d79921"}     # the frame around the window
ACCENT=${CAL_ACCENT:-"#fabd2f"}     # the date line at the top
SELECTED=${CAL_SELECTED:-"#d79921"} # behind the day under the cursor
TODAY=${CAL_TODAY:-"#8ec07c"}       # today, when it is not the day under the cursor
WEEKEND=${CAL_WEEKEND:-"#fb4934"}   # Sunday
HEADING=${CAL_HEADING:-"#a89984"}   # the names of the weekdays
RULE=${CAL_RULE:-"#504945"}         # the lines between the parts
KEY=${CAL_KEY:-"#d5c4a1"}           # the keys in the hint line
DIM=${CAL_DIM:-"#928374"}           # what the keys do

# The longest date line there can be is "Wednesday, 30 September 2026" behind
# an icon and a space: thirty columns. The grid is only twenty, and the hint at
# its smaller size fits comfortably inside the same thirty.
WIDTH=30
BORDER_WIDTH=2
PADDING=18

# The bar clock that opens this sits at the top middle, so the window belongs up
# near it rather than in the middle of the screen.
#
# The width is the text plus everything rofi takes out of it before the text
# gets a say. Sized in columns alone, the padding and the border ate into the
# columns and the longest dates came out cut short with an ellipsis.
#
# The calendar arrives as rows because a script mode talks to rofi one line at a
# time and a message could not hold the newlines. Eleven rows are the whole
# calendar - the date, a rule, the weekdays, six weeks, a rule and the hint - so
# the list never scrolls and the window never changes size. Rows come with a
# cursor of rofi's own, which would sit on a line of the grid and mean nothing,
# so the selected row is painted like every other one. Every row is centred by
# rofi, which keeps the date line in the middle whatever its length and saves
# building left margins out of spaces rofi would eat.
THEME="
window {
    location: north;
    anchor: north;
    y-offset: 137px;
    width: calc( ${WIDTH}ch + $((2 * (PADDING + BORDER_WIDTH)))px );
    background-color: $BG$BG_ALPHA;
    border: ${BORDER_WIDTH}px solid;
    border-color: $BORDER;
    border-radius: 12px;
    padding: ${PADDING}px;
}
* { font: \"$FONT\"; text-color: $FG; background-color: transparent; }
mainbox { children: [ listview ]; padding: 0; spacing: 0; border: 0; }
listview {
    lines: 11; columns: 1; spacing: 0; padding: 0;
    scrollbar: false; border: 0; fixed-height: true;
}
element { padding: 0; spacing: 0; border: 0; }
element normal.normal, element alternate.normal, element selected.normal,
element normal.active, element alternate.active, element selected.active,
element normal.urgent, element alternate.urgent, element selected.urgent {
    background-color: transparent;
    text-color: $FG;
}
element-text {
    background-color: transparent;
    text-color: inherit;
    horizontal-align: 0.5;
    vertical-align: 0.5;
}
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

# A rule as wide as the text, drawn in box characters so it meets the edges of
# the widest line exactly instead of stopping short of them.
rule() {
  local line
  printf -v line '%*s' "$WIDTH" ''
  printf '<span foreground="%s">%s</span>\n' "$RULE" "${line// /─}"
}

hint() {
  printf '<span foreground="%s">%s</span>\302\240<span foreground="%s">%s</span>' \
    "$KEY" "$1" "$DIM" "$2"
}

render() {
  local year=$((10#${1:0:4})) month=$((10#${1:5:2})) day=$((10#${1:8:2}))
  # cal only marks today when it is the month on screen, so tell awk which day
  # to mark and let it mark nothing while you are browsing another month.
  local today=0
  if [[ ${1:0:7} == "$(date +%Y-%m)" ]]; then
    today=$((10#$(date +%d)))
  fi

  # The date line already names the month, so cal's own title would only say
  # it a second time and is left out of the grid below.
  printf '<span foreground="%s"><b>󰃭 %s</b></span>\n' \
    "$ACCENT" "$(date -d "$1" '+%A, %-d %B %Y')"
  rule
  # -m starts the week on Monday, which is what the calendar on the wall does
  # here; the locale is en_US and would otherwise start it on Sunday. That
  # also puts Sunday in the last of the seven fixed three-column slots, which
  # is what makes painting it a matter of counting columns.
  cal -m "$month" "$year" | awk -v today="$today" -v day="$day" \
    -v bg="$BG" -v selected="$SELECTED" -v today_fg="$TODAY" \
    -v weekend="$WEEKEND" -v heading="$HEADING" '
        BEGIN {
            # Pango has no reverse video, so the day under the cursor sets both
            # colours by hand. Nested spans let the inner one win, which is what
            # keeps a marked Sunday readable instead of red on a highlight.
            mark = "<span background=\"" selected "\" foreground=\"" bg "\"><b>"
            unmark = "</b></span>"
            now = "<span foreground=\"" today_fg "\" underline=\"single\"><b>"
            paint = "<span foreground=\"" weekend "\">"
            head = "<span foreground=\"" heading "\">"
            off = "</span>"
        }
        NR == 1 { next }
        # cal pads lines out to a width of its own; only the twenty columns of
        # the seven slots are the grid, and a row any wider or narrower would
        # sit off to one side once rofi centres it.
        { $0 = sprintf("%-20s", substr($0, 1, 20)) }
        {
            line = ""
            for (i = 1; i <= 7; i++) {
                day_in = substr($0, (i - 1) * 3 + 1, 2)
                # A week that starts mid-week is padded with spaces rofi would
                # eat as readily as a margin, so those go non-breaking too.
                # It has to happen before the markup goes on, or the spaces
                # between a span attributes become non-breaking with them.
                cell = day_in
                gsub(/ /, "\302\240", cell)
                if (NR > 2 && day_in ~ /[0-9]/) {
                    # The day you are on is the one under the cursor; today is
                    # only ever the second mark, and only in its own month.
                    if (day_in + 0 == day) cell = mark cell unmark
                    else if (day_in + 0 == today) cell = now cell unmark
                }
                if (i == 7 && day_in ~ /[[:alnum:]]/) cell = paint cell off
                line = line (i > 1 ? "\302\240" : "") cell
            }
            print (NR == 2 ? head line off : line)
        }
        # A short month prints five week rows, a long one six. Pad to the six the
        # window is sized for, so it does not change height as you walk through
        # the year. An empty row is one rofi drops on the floor, so the padding
        # is a row holding a space it cannot see through and nothing else.
        END { while (NR++ < 8) print "\302\240" }'
  rule
  printf '<span size="%s">%s  %s  %s  %s  %s</span>\n' "$HINT_SIZE" \
    "$(hint '←→' day)" "$(hint '↑↓' week)" "$(hint '^←→' month)" \
    "$(hint t today)" "$(hint q quit)"
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
