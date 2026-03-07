#!/usr/bin/env bash

# Take screenshot, annotate, copy to clipboard
# Save to tmp - it's on RAM.
TMPFILE=$(mktemp /tmp/screenshot-XXXX.png)

# 1. Select area with slurp and take screenshot
grim -g "$(slurp)" "$TMPFILE" || exit 1

# 2. Annotate with swappy
satty --actions-on-escape=save-to-file,exit -f "$TMPFILE" -o "$TMPFILE" || exit 1

# 3. Copy final annotated image to clipboard
wl-copy < "$TMPFILE"

# 4. Optional: remove temp file
rm "$TMPFILE"
