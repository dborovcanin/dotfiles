# Everforest dark, medium contrast.
#
# A warm, low-contrast palette: the greys are green-tinted rather than neutral,
# and the accents are muted enough that none of them shouts. Green is what marks
# the focused thing, the way gruvbox uses yellow and nord the frost blues.

THEME_SCHEME="dark"

THEME_BG="#2d353b"        # bg0
THEME_BG_ALT="#343f44"    # bg1
THEME_BG_RAISED="#3d484d" # bg2
THEME_FG="#d3c6aa"        # fg
# Everforest has one foreground and three greys under it, so the quieter text
# takes the foreground itself and the ladder below it starts at grey2.
THEME_FG_ALT="#d3c6aa"    # fg
THEME_SUBTLE="#9da9a0"    # grey2
THEME_DIM="#859289"       # grey1
THEME_BORDER="#a7c080"    # green
THEME_ACCENT="#83c092"    # aqua
THEME_ON_COLOR="#2d353b"  # bg0: every accent here is light enough to want dark text

THEME_RED="#e67e80"
THEME_GREEN="#a7c080"
THEME_YELLOW="#dbbc7f"
THEME_BLUE="#7fbbb3"
THEME_MAGENTA="#d699b6"
THEME_CYAN="#83c092"
THEME_ORANGE="#e69875"

# Everforest has one set of accents rather than a normal and a bright half, so
# the two rows differ only in their monotones.
THEME_ANSI=(
    "#343f44" "#e67e80" "#a7c080" "#dbbc7f" "#7fbbb3" "#d699b6" "#83c092" "#9da9a0"
    "#859289" "#e67e80" "#a7c080" "#dbbc7f" "#7fbbb3" "#d699b6" "#83c092" "#d3c6aa"
)

THEME_HELIX="everforest_dark"
