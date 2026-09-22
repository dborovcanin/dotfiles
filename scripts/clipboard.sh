#!/bin/bash

# Clipboard history from cliphist, drawn by config/rofi/menu.rasi.
#
# Return copies the entry back, Alt+p previews an image entry in feh,
# Ctrl+Backspace drops the entry from history.
#
# Run without arguments this opens the menu; rofi then calls the same file back
# as a script mode (rofi-script(5)) for every key, so deleting an entry redraws
# the list inside the running menu instead of tearing the window down and
# building a new one, which is what made a delete flicker.

here=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
self=$(realpath "${BASH_SOURCE[0]}")

# --preview <file> <row> runs detached, after the menu has closed. rofi draws
# itself on the layer-shell overlay and holds an exclusive keyboard grab, so a
# viewer started while the menu is up lands under it and never sees a key. The
# preview therefore waits for rofi to go away, shows the image in the
# foreground, and reopens the menu on the row it came from once feh exits.
if [ "$1" = "--preview" ]; then
    for _ in {1..60}; do
        pgrep -x rofi > /dev/null || break
        sleep 0.05
    done
    feh --auto-zoom --scale-down "$2" > /dev/null 2>&1
    exec env -u ROFI_RETV -u ROFI_INFO -u ROFI_DATA "$self" --row "$3"
fi

# --row <n> reopens the menu with the cursor already on row n.
start_row=0
if [ "$1" = "--row" ]; then
    start_row=$2
fi

# theme:begin clipboard
key_color="#e5e9f0"
# theme:end

# nf-md-clipboard_text, spelled as a code point like the icons in power.sh.
icon=$'\U000F014D'

mesg="<span foreground=\"$key_color\">Return</span> copy  ·  \
<span foreground=\"$key_color\">Alt+p</span> preview  ·  \
<span foreground=\"$key_color\">Ctrl+Backspace</span> delete"

# The menu itself. Ctrl+Backspace is rofi's default remove-word-back, so that
# binding is left with its other default key alone.
if [ -z "$ROFI_RETV" ]; then
    exec rofi -show clipboard -modes "clipboard:$self" \
        -matching fuzzy -i \
        -theme "$here/../config/rofi/menu.rasi" \
        -theme-str 'window {width: 56em; padding: 18px;}
                    mainbox {spacing: 10px;}
                    listview {lines: 14; spacing: 2px;}
                    element {padding: 3px 12px;}' \
        -selected-row "$start_row" \
        -kb-remove-word-back 'Control+Alt+h' \
        -kb-custom-1 'Alt+p' \
        -kb-custom-2 'Control+BackSpace'
fi

# Below here rofi is the caller. Rows carry the cliphist id as their info, so
# the id comes back in ROFI_INFO and the text of the row is free to be prettied
# up with a number and used for filtering. Printing no rows closes the menu.

# cliphist list gives "id<tab>entry", newest first, one line per entry.
rows() {
    local n=0 id entry
    while IFS=$'\t' read -r id entry; do
        n=$((n + 1))
        printf '%s\0display\x1f%2d  %s\x1finfo\x1f%s\n' "$entry" "$n" "$entry" "$id"
    done < <(cliphist list)
}

# $1, when given, is the row to land on, so a delete leaves the cursor on the
# entry that took the deleted one's place.
menu() {
    printf '\0use-hot-keys\x1ftrue\n'
    printf '\0prompt\x1f%s\n' "$icon"
    printf '\0message\x1f%s\n' "$mesg"
    printf '\0no-custom\x1ftrue\n'
    if [ -n "$1" ]; then
        printf '\0keep-selection\x1ftrue\n'
        printf '\0new-selection\x1f%s\n' "$1"
    fi
    rows
}

# Where the entry with this id sits in the list, counted from 0.
row_of() {
    cliphist list | awk -F'\t' -v id="$1" '$1 == id {print NR - 1; exit}'
}

id=$ROFI_INFO

case "$ROFI_RETV" in
    # Opening the menu.
    0)
        menu
        ;;
    # An entry was picked: copy it, print no rows, and the menu closes.
    1)
        printf '%s' "$id" | cliphist decode | wl-copy
        ;;
    # Alt+p: hand the image to a detached copy of this script and print no rows,
    # which closes the menu and lets the viewer take the focus. Nothing is
    # detached for a non-image entry, so the menu just redraws where it was.
    10)
        tmp=/tmp/cliphist-preview.png
        printf '%s' "$id" | cliphist decode > "$tmp" 2>/dev/null
        if [ -s "$tmp" ] && file -b --mime-type "$tmp" | grep -q '^image/'; then
            setsid "$self" --preview "$tmp" "$(row_of "$id")" > /dev/null 2>&1 &
        else
            menu "$(row_of "$id")"
        fi
        ;;
    # Ctrl+Backspace.
    11)
        row=$(row_of "$id")
        printf '%s' "$id" | cliphist delete
        menu "$row"
        ;;
esac
