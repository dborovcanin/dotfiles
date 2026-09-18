# Kanagawa lotus.
#
# The light half of kanagawa: a warm paper background with ink-dark text. The
# accents are the muted "lotus" set, dark enough to read on cream, so the
# normal/bright split runs the other way up from wave.

THEME_SCHEME="light"

THEME_BG="#f2ecbc"        # lotusWhite3
THEME_BG_ALT="#e5ddb0"    # lotusWhite2
THEME_BG_RAISED="#d5cea3" # lotusWhite0
THEME_FG="#545464"        # lotusInk1
THEME_FG_ALT="#716e61"    # lotusGray2
THEME_SUBTLE="#766b90"    # lotusViolet2
THEME_DIM="#8a8980"       # lotusGray3, the comment colour
THEME_BORDER="#4d699b"    # lotusBlue4
THEME_ACCENT="#624c83"    # lotusViolet4
THEME_ON_COLOR="#f2ecbc"  # lotusWhite3: the colours below are dark enough for light text

THEME_RED="#c84053"       # lotusRed
THEME_GREEN="#6f894e"     # lotusGreen
THEME_YELLOW="#77713f"    # lotusYellow
THEME_BLUE="#4d699b"      # lotusBlue4
THEME_MAGENTA="#b35b79"   # lotusPink
THEME_CYAN="#597b75"      # lotusAqua
THEME_ORANGE="#cc6d00"    # lotusOrange

THEME_ANSI=(
    "#1f1f28" "#c84053" "#6f894e" "#77713f" "#4d699b" "#b35b79" "#597b75" "#545464"
    "#8a8980" "#d7474b" "#6e915f" "#836f4a" "#6693bf" "#624c83" "#5e857a" "#43436c"
)

# Helix ships no lotus theme, so borrow the terminal's own 16 colours: those are
# the lotus ones two lines up.
THEME_HELIX="term16_light"
