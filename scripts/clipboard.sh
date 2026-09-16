#!/bin/bash

# Clipboard history from cliphist, drawn by config/rofi/menu.rasi.
#
# Return copies the entry back, Alt+p previews an image entry in feh.

here=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

# theme:begin clipboard
key_color="#d5c4a1"
# theme:end

# nf-md-clipboard_text, spelled as a code point like the icons in power.sh.
icon=$'\U000F014D'

# cliphist lists "id<tab>entry"; only the entry is shown, but rofi still prints
# the whole line, and the id is what cliphist decode needs.
rofi_cmd=(rofi -dmenu -matching fuzzy -i \
    -p "$icon" \
    -display-columns 2 -display-column-separator '\t' \
    -mesg "<span foreground=\"$key_color\">Return</span> copy  ·  <span foreground=\"$key_color\">Alt+p</span> preview" \
    -theme "$here/../config/rofi/menu.rasi" \
    -theme-str 'window {width: 56em;} listview {lines: 12;}' \
    -kb-custom-1 'Alt+p')

selected_row=0
while true; do
    selection=$(cliphist list | "${rofi_cmd[@]}" -selected-row "$selected_row")
    exit_code=$?

    # 0 = selected, 10 = custom-1 (Alt+p preview)
    if [ $exit_code -eq 10 ]; then
        selected_row=$(cliphist list | grep -nF "$selection" | head -1 | cut -d: -f1)
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
