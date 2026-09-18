# Everything about the look that is not a colour: the fonts, the width of a
# border, how round a corner is, how far apart windows sit, how much of what is
# behind a window shows through it.
#
# scripts/theme.sh sources this before the theme itself, so these apply to
# every theme. A theme that wants its own - a light one that reads badly
# through a transparent terminal, say - sets the same variable again in
# themes/<name>.sh and wins.
#
# Sizes are points where the program takes points and pixels where it takes
# pixels; each variable says which, because no two of these configs agree.

# ---------------------------------------------------------------------------
# Fonts. Four roles, because these are four different jobs: the menus are read
# in a hurry, a terminal is read for hours, the bar is read across the room,
# and the desktop is whatever GTK and Qt applications draw their own text with.
# ---------------------------------------------------------------------------

# Menus, notifications, window titles, and the rofi scripts: rofi, dunst, the
# sway and i3 title bars, hyprland's group tabs, hyprlock.
THEME_FONT="JetBrainsMonoNL NF"
THEME_FONT_SIZE=14

# The window title bars alone: a sway or i3 tab is as tall as this font plus
# the padding below it, and a tab is glanced at rather than read, so it is set
# smaller than the menu font rather than sharing it.
THEME_FONT_TITLE_SIZE=12

# Around the text in a sway title bar: horizontal first, then vertical, in
# pixels. i3 has no setting of its own for this, so its bars are as tall as the
# font alone makes them.
THEME_TITLEBAR_PADDING="6 1"

# The icon in a menu's prompt, and the emoji grid. The proportional cut of the
# same patched font: the monospaced one squeezes an icon into one cell and rofi
# clips what does not fit.
THEME_FONT_ICON="JetBrainsMonoNL NFP"
THEME_FONT_ICON_SIZE=18

# The terminals: foot, alacritty, kitty, urxvt. A patched font, because the prompt
# and the TUIs draw glyphs that a plain one has no room for.
THEME_FONT_TERM="JetBrainsMonoNL NF"
THEME_FONT_TERM_SIZE=14

# The bar: dbar. Proportional on purpose - the bar is text, not a table, and a
# proportional face fits more of a window title into the same strip.
THEME_FONT_BAR="Adwaita Sans"
THEME_FONT_BAR_SIZE=18

# GTK and Qt applications, which is most of what has a window rather than a
# terminal. This is the font a desktop calls its own.
THEME_FONT_DESKTOP="Adwaita Sans"
THEME_FONT_DESKTOP_SIZE=11

# ---------------------------------------------------------------------------
# Geometry, in pixels.
# ---------------------------------------------------------------------------

# The frame around a focused window, and around every menu the scripts draw.
THEME_BORDER_WIDTH=4

# Corners. Four of them, because a window and a notification are not asking for
# the same shape: a window is a working surface and stays nearly square, while
# the things that appear over it for a moment are rounder, so that they read as
# temporary.
THEME_RADIUS=5       # tiled and floating windows, hyprlock's input field
THEME_RADIUS_POPUP=10 # notifications
THEME_RADIUS_MENU=16  # the frame around a rofi menu
THEME_RADIUS_ITEM=12  # a row or a tile inside one

# Between windows, and between a window and the edge of the screen. hyprland
# counts the inner gap per window rather than per pair, so it is given half.
# Only hyprland is given an outer gap: sway, i3 and niri run without one today,
# and setting one there would move every window away from the screen edge.
THEME_GAPS_IN=10
THEME_GAPS_OUT=10

# ---------------------------------------------------------------------------
# Transparency, as a fraction: 1 is opaque, 0 is invisible.
# ---------------------------------------------------------------------------

# Terminals. The compositors blur what is behind a transparent window, which is
# what keeps text on top of it readable.
THEME_ALPHA=0.98

# Menus and notifications. Opaque by default: these are read in a glance and
# sit over whatever was already on the screen.
THEME_ALPHA_MENU=1.0
