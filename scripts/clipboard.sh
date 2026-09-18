#!/bin/bash

# Clipboard history from cliphist, drawn by config/rofi/menu.rasi.
#
# Return copies the entry back, Alt+p previews an image entry in feh.

here=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

# theme:begin clipboard
key_color="#e5e9f0"
# theme:end

# nf-md-clipboard_text, spelled as a code point like the icons in power.sh.
icon=$'\U000F014D'

# cliphist lists "id<tab>entry"; the entry is shown with a row number in front,
# but rofi still prints the whole line, and the id is what cliphist decode needs
# - decode only reads the id, so the number riding along in column 2 is fine.
entries() {
    cliphist list | awk -F'\t' '{
        entry = substr($0, index($0, "\t") + 1)
        printf "%s\t%2d  %s\n", $1, NR, entry
    }'
}

rofi_cmd=(rofi -dmenu -matching fuzzy -i \
    -p "$icon" \
    -display-columns 2 -display-column-separator '\t' \
    -mesg "<span foreground=\"$key_color\">Return</span> copy  ·  <span foreground=\"$key_color\">Alt+p</span> preview" \
    -theme "$here/../config/rofi/menu.rasi" \
    -theme-str 'window {width: 56em; padding: 18px;}
                mainbox {spacing: 10px;}
                listview {lines: 14; spacing: 2px;}
                element {padding: 3px 12px;}' \
    -kb-custom-1 'Alt+p')

selected_row=0
while true; do
    selection=$(entries | "${rofi_cmd[@]}" -selected-row "$selected_row")
    exit_code=$?

    # 0 = selected, 10 = custom-1 (Alt+p preview)
    if [ $exit_code -eq 10 ]; then
        selected_row=$(printf '%s' "$selection" | cut -f2- | awk '{print $1 + 0}')
        selected_row=$((selected_row - 1))
        tmp=/tmp/cliphist-preview.png
        echo "$selection" | cliphist decode > "$tmp" 2>/dev/null
        if [ -s "$tmp" ] && file -b --mime-type "$tmp" | grep -q '^image/'; then
            feh --auto-zoom --scale-down "$tmp"
        fi
        continue
    elif [ $exit_code -eq 0 ]; then
        echo "$selection" | cliphist decode | wl-copy
    fi
    break
done
