#!/bin/bash
# dunstctl close-all && notify-send -a "cal" "📅 Calendar" "$(echo "<span font='22px'><b>$(cal -m | sed -E "s/(^| )($(date +%-d))([ $])/\1<span foreground='red'><b>\2<\/b><\/span>\3/")</b></span>")"

rofi --no-focus -theme-str 'window { location: northeast; width: 22ch; height:25ch;  x-offset: -30; y-offset: 30; border: 3px solid; } * { font: "monospace 18"; }' -markup -e \
"📅 Calendar
⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻⎻
$(cal -m | sed -E "s/\b($(date +%-d))\b/<span foreground='red'><b>\1<\/b><\/span>/")"
