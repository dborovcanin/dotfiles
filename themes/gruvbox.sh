# Gruvbox dark.
#
# A theme is sourced by scripts/theme.sh, which writes these colours into every
# config and script that carries a theme block. gruvbox is always read first,
# so another theme only has to set what it changes.

# dark or light. Everything that has to know which way round the palette runs
# reads this: the GTK 2 base theme, GTK 3's prefer-dark, and the reminder about
# the desktop colour scheme that apply prints at the end.
THEME_SCHEME="dark"

THEME_BG="#282828"        # bg0: windows, terminal background
THEME_BG_ALT="#3c3836"    # bg1: search boxes, the row under the cursor, selection
THEME_BG_RAISED="#504945" # bg2: rules and separators
THEME_FG="#ebdbb2"        # fg1: text
THEME_FG_ALT="#d5c4a1"    # fg2: text that should not shout
THEME_SUBTLE="#a89984"    # fg4: headings
THEME_DIM="#928374"       # grey: hints, keys, placeholders, inactive things
THEME_BORDER="#d79921"    # the frame around focused windows and every popup
THEME_ACCENT="#fabd2f"    # titles, prompts, the frame of the row under the cursor
THEME_ON_COLOR="#ebdbb2"  # text laid on one of the ANSI colours below

# The bright half of the terminal palette, used wherever a hue means something.
THEME_RED="#fb4934"
THEME_GREEN="#b8bb26"
THEME_YELLOW="#fabd2f"
THEME_BLUE="#83a598"
THEME_MAGENTA="#d3869b"
THEME_CYAN="#8ec07c"
THEME_ORANGE="#fe8019"

# The sixteen terminal colours: black red green yellow blue magenta cyan white,
# then the same eight bright.
THEME_ANSI=(
    "#282828" "#cc241d" "#98971a" "#d79921" "#458588" "#b16286" "#689d6a" "#a89984"
    "#928374" "#fb4934" "#b8bb26" "#fabd2f" "#83a598" "#d3869b" "#8ec07c" "#ebdbb2"
)

# Names of the matching built-in themes of apps that ship their own.
THEME_HELIX="gruvbox"
