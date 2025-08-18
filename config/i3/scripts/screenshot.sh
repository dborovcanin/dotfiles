#!/bin/bash

# Save currently focused window ID
focused_win=$(xdotool getwindowfocus)

# Launch Flameshot GUI
flameshot gui -r | xclip -selection clipboard -t image/png

# Wait for Flameshot to exit, then refocus previous window
xdotool windowactivate "$focused_win"
