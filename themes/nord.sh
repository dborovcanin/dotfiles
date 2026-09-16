# Nord.
#
# Four greys (nord0-3), three off-whites (nord4-6), four frost blues (nord7-10)
# and five aurora accents (nord11-15). The frost blues do the work gruvbox gives
# to yellow: they are what marks the focused thing.

THEME_SCHEME="dark"

THEME_BG="#2e3440"        # nord0
THEME_BG_ALT="#3b4252"    # nord1
THEME_BG_RAISED="#434c5e" # nord2
THEME_FG="#eceff4"        # nord6
THEME_FG_ALT="#e5e9f0"    # nord5
THEME_SUBTLE="#d8dee9"    # nord4
# Nord has no grey between nord3 and nord4, and nord3 on nord0 is 1.7:1 - fine
# for code comments, which is what Nord means it for, but this drives menu key
# hints and placeholders too, so it is lifted to a readable 3.5:1.
THEME_DIM="#7b88a1"       # between nord3 and nord4
THEME_BORDER="#88c0d0"    # nord8
THEME_ACCENT="#8fbcbb"    # nord7
THEME_ON_COLOR="#2e3440"  # nord0: the frost and aurora colours want dark text

THEME_RED="#bf616a"
THEME_GREEN="#a3be8c"
THEME_YELLOW="#ebcb8b"
THEME_BLUE="#81a1c1"
THEME_MAGENTA="#b48ead"
THEME_CYAN="#88c0d0"
THEME_ORANGE="#d08770"

THEME_ANSI=(
    "#3b4252" "#bf616a" "#a3be8c" "#ebcb8b" "#81a1c1" "#b48ead" "#88c0d0" "#e5e9f0"
    "#4c566a" "#bf616a" "#a3be8c" "#ebcb8b" "#81a1c1" "#b48ead" "#8fbcbb" "#eceff4"
)

THEME_HELIX="nord"
