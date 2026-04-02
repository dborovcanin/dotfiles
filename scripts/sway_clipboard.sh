#!/bin/bash

rofi_cmd=(rofi -dmenu -matching fuzzy -i \
    -font 'JetBrainsMono Nerd Font 14' \
    -theme-str 'window {width: 30%;} listview {lines: 20;}' \
    -p clipboard \
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
