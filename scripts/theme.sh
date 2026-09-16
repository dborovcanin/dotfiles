#!/usr/bin/env bash
set -euo pipefail

# Writes a colour theme into every config and script of these dotfiles.
#
# Usage: theme.sh apply <name|path>   rewrite every theme block with that theme
#        theme.sh list                the themes in themes/
#        theme.sh current             the theme applied last
#        theme.sh check               every theme block, and whether it can be drawn
#
# A theme is a file of THEME_* colours in themes/ (see gruvbox-dark.sh). A
# themed file carries one or more blocks between two marker comments:
#
#     # theme:begin <block>
#     ...whatever render_<block> below prints...
#     # theme:end
#
# Everything between the markers is replaced on every apply and nothing outside
# them is touched, so edit a block's template here rather than in the file. The
# comment characters can be whatever the file's format needs. Nothing is reloaded
# or installed: copy the configs into place and reload what is running.

usage() {
  sed -n '4,21s/^# \{0,1\}//p' "$0"
}

root=$(realpath "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/..")
themes=$root/themes
self=$(realpath "${BASH_SOURCE[0]}")

# ---------------------------------------------------------------------------
# Blocks. Each prints the lines that go between its markers.
# ---------------------------------------------------------------------------

# The i3 and sway configs name their colours once and use the names everywhere.
render_wm() {
  cat <<EOF
set \$background $THEME_BG
set \$background_alt $THEME_BG_ALT
set \$foreground $THEME_FG
set \$primary $THEME_BORDER
set \$secondary $THEME_CYAN
set \$alert ${THEME_ANSI[1]}
set \$disabled $THEME_DIM
EOF
}

render_niri_background() {
  printf '    background-color "%s"\n' "$THEME_BG"
}

render_niri_border() {
  cat <<EOF
        active-color "$THEME_BORDER"
        inactive-color "$THEME_BG_ALT"
        urgent-color "${THEME_ANSI[1]}"
EOF
}

render_niri_tabs() {
  cat <<EOF
        active-color "$THEME_BORDER"
        inactive-color "$THEME_DIM"
        urgent-color "${THEME_ANSI[1]}"
EOF
}

# foot wants the sixteen colours without '#'. Since foot 1.27 there is no plain
# [colors] section: there is [colors-dark] and [colors-light], and foot picks
# between them by what the desktop asks for. Both get the same colours, so the
# terminal shows the theme that was applied even when the desktop's preference
# says otherwise. alpha stays outside the markers, in the file, because it is a
# preference rather than a colour.
foot_colors() {
  local i
  printf 'foreground=%s\nbackground=%s\n\n' "${THEME_FG#\#}" "${THEME_BG#\#}"
  for i in {0..7}; do printf 'regular%d=%s\n' "$i" "${THEME_ANSI[i]#\#}"; done
  echo
  for i in {0..7}; do printf 'bright%d=%s\n' "$i" "${THEME_ANSI[i + 8]#\#}"; done
  printf '\nselection-foreground=%s\nselection-background=%s\n\n' \
    "${THEME_FG#\#}" "${THEME_BG_ALT#\#}"
  printf 'urls=%s\n' "${THEME_BLUE#\#}"
}

render_foot_dark() { foot_colors; }
render_foot_light() { foot_colors; }

render_alacritty() {
  local names=(black red green yellow blue magenta cyan white) i
  printf '[colors.primary]\nbackground = '\''%s'\''\nforeground = '\''%s'\''\n' "$THEME_BG" "$THEME_FG"
  printf '\n[colors.normal]\n'
  for i in {0..7}; do printf "%-7s = '%s'\n" "${names[i]}" "${THEME_ANSI[i]}"; done
  printf '\n[colors.bright]\n'
  for i in {0..7}; do printf "%-7s = '%s'\n" "${names[i]}" "${THEME_ANSI[i + 8]}"; done
}

# The [90] in front of the background is the terminal's transparency.
render_urxvt() {
  local i
  printf 'URxvt*background:                     [90]%s\n' "$THEME_BG"
  printf 'URxvt*foreground:                     %s\n' "$THEME_FG"
  printf 'URxvt*cursorColor:                    %s\n' "$THEME_ACCENT"
  printf 'URxvt*scrollColor:                    %s\n' "$THEME_FG"
  printf 'URxvt*highlightColor:                 %s\n' "$THEME_BG_ALT"
  printf 'URxvt*highlightTextColor:             %s\n\n' "$THEME_FG"
  for i in {0..15}; do
    printf 'URxvt*color%-27s%s\n' "$i:" "${THEME_ANSI[i]}"
  done
}

render_xmenus() {
  cat <<EOF
rofi.color-enabled: true
rofi.color-window: $THEME_BG, $THEME_BORDER, $THEME_BG
rofi.color-normal: $THEME_BG, $THEME_FG, $THEME_BG, $THEME_BG_ALT, $THEME_ACCENT
rofi.color-active: $THEME_BG, $THEME_BLUE, $THEME_BG, $THEME_BG_ALT, $THEME_BLUE
rofi.color-urgent: $THEME_BG, $THEME_RED, $THEME_BG, $THEME_BG_ALT, $THEME_RED
rofi.modi: run,drun,window

dmenu.selforeground:	    $THEME_BG
dmenu.background:	        $THEME_BG
dmenu.selbackground:	    $THEME_ACCENT
dmenu.foreground:	        $THEME_FG
EOF
}

render_polybar() {
  cat <<EOF
background = $THEME_BG
background-alt = $THEME_BG_ALT
foreground = $THEME_FG
primary = $THEME_ACCENT
secondary = $THEME_CYAN
alert = ${THEME_ANSI[1]}
disabled = $THEME_DIM
EOF
}

render_dbar() {
  cat <<EOF
background = "$THEME_BG"
surface = "$THEME_BG_ALT"
raised = "$THEME_BG_RAISED"
text = "$THEME_FG_ALT"
subtext = "$THEME_SUBTLE"
accent = "$THEME_BLUE"
warning = "$THEME_YELLOW"
critical = "$THEME_RED"
EOF
}

# btop names every colour it draws, including the three-stop gradients under the
# cpu and temperature meters. The meters that measure quantity rather than trouble
# - memory and network - are given a start and nothing else, which btop reads as
# one flat colour.
render_btop() {
  cat <<EOF
theme[main_bg]="$THEME_BG"
theme[main_fg]="$THEME_FG"
theme[title]="$THEME_FG"
theme[hi_fg]="$THEME_BORDER"
theme[selected_bg]="$THEME_BG_RAISED"
theme[selected_fg]="$THEME_FG"
theme[inactive_fg]="$THEME_DIM"
theme[graph_text]="$THEME_SUBTLE"
theme[proc_misc]="$THEME_ACCENT"
theme[cpu_box]="$THEME_BG_RAISED"
theme[mem_box]="$THEME_BG_RAISED"
theme[net_box]="$THEME_BG_RAISED"
theme[proc_box]="$THEME_BG_RAISED"
theme[div_line]="$THEME_BG_RAISED"
theme[temp_start]="$THEME_CYAN"
theme[temp_mid]="$THEME_ORANGE"
theme[temp_end]="$THEME_RED"
theme[cpu_start]="$THEME_GREEN"
theme[cpu_mid]="$THEME_YELLOW"
theme[cpu_end]="$THEME_RED"
theme[free_start]="$THEME_GREEN"
theme[free_mid]=""
theme[free_end]=""
theme[cached_start]="$THEME_CYAN"
theme[cached_mid]=""
theme[cached_end]=""
theme[available_start]="$THEME_YELLOW"
theme[available_mid]=""
theme[available_end]=""
theme[used_start]="$THEME_RED"
theme[used_mid]=""
theme[used_end]=""
theme[download_start]="$THEME_BLUE"
theme[download_mid]=""
theme[download_end]=""
theme[upload_start]="$THEME_MAGENTA"
theme[upload_mid]=""
theme[upload_end]=""
EOF
}

# i3status-rust ships no theme for most palettes, so every state is overridden.
render_i3status() {
  cat <<EOF
separator_fg = "$THEME_FG"
idle_bg = "$THEME_BG"
idle_fg = "$THEME_FG"
info_bg = "${THEME_ANSI[4]}"
info_fg = "$THEME_ON_COLOR"
good_bg = "${THEME_ANSI[2]}"
good_fg = "$THEME_ON_COLOR"
warning_bg = "${THEME_ANSI[3]}"
warning_fg = "$THEME_ON_COLOR"
critical_bg = "${THEME_ANSI[1]}"
critical_fg = "$THEME_ON_COLOR"
EOF
}

render_dunst_global() {
  cat <<EOF
    frame_color = "$THEME_BORDER"
    separator_color = "$THEME_BG_RAISED"
EOF
}

render_dunst_urgency() {
  cat <<EOF
[urgency_low]
    background = "$THEME_BG"
    foreground = "$THEME_SUBTLE"
    timeout = 20

[urgency_normal]
    background = "$THEME_BG"
    foreground = "$THEME_FG"
    timeout = 20

[urgency_critical]
    background = "$THEME_BG"
    foreground = "$THEME_FG"
    frame_color = "$THEME_RED"
    timeout = 0
EOF
}

# fish takes colours without '#'. The __prompt_color_* ones are read by the
# prompt functions in config/fish/functions.
render_fish() {
  local bg=${THEME_BG#\#} bg_alt=${THEME_BG_ALT#\#} raised=${THEME_BG_RAISED#\#}
  local fg=${THEME_FG#\#} fg_alt=${THEME_FG_ALT#\#} dim=${THEME_DIM#\#}
  local accent=${THEME_ACCENT#\#} red=${THEME_RED#\#} green=${THEME_GREEN#\#}
  local yellow=${THEME_YELLOW#\#} blue=${THEME_BLUE#\#} magenta=${THEME_MAGENTA#\#}
  local cyan=${THEME_CYAN#\#} orange=${THEME_ORANGE#\#}
  cat <<EOF
set -g fish_color_normal $fg
set -g fish_color_command $green
set -g fish_color_keyword $red
set -g fish_color_quote $yellow
set -g fish_color_redirection $cyan
set -g fish_color_end $orange
set -g fish_color_error $red
set -g fish_color_param $fg_alt
set -g fish_color_option $fg_alt
set -g fish_color_comment $dim
set -g fish_color_operator $fg_alt
set -g fish_color_escape $magenta
set -g fish_color_autosuggestion $dim
set -g fish_color_valid_path --underline
set -g fish_color_cancel $red --reverse
set -g fish_color_selection --background=$bg_alt
set -g fish_color_search_match --background=$raised
set -g fish_color_history_current --bold
set -g fish_color_cwd $green
set -g fish_color_cwd_root $red
set -g fish_color_user $green
set -g fish_color_host $blue
set -g fish_color_host_remote $yellow
set -g fish_color_status $red
set -g fish_pager_color_prefix $accent --bold --underline
set -g fish_pager_color_completion $fg
set -g fish_pager_color_description $dim
set -g fish_pager_color_progress $bg --background=$accent
set -g fish_pager_color_selected_background --background=$bg_alt
set -g fish_pager_color_selected_completion $accent

set -g __prompt_color_parent ${THEME_ANSI[4]#\#}
set -g __prompt_color_dir ${THEME_ANSI[12]#\#}
set -g __prompt_color_ok $green
set -g __prompt_color_error $red
set -g __prompt_color_clean $green
set -g __prompt_color_modified $yellow
set -g __prompt_color_conflicted $red
set -g __prompt_color_meta $dim
set -g __prompt_color_duration ${THEME_ANSI[1]#\#}
set -g __prompt_color_jobs ${THEME_ANSI[2]#\#}
set -g __prompt_color_root $yellow
set -g __prompt_color_remote $orange
set -g __prompt_color_time ${THEME_ANSI[6]#\#}
EOF
}

render_tmux() {
  printf 'set -g status-bg "%s"\nset -g status-fg "%s"\n' "$THEME_BG_ALT" "$THEME_FG"
}

# KDE writes colours as "r,g,b" decimals rather than hex.
kde_rgb() {
  local h=${1#\#}
  printf '%d,%d,%d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}

# One [Colors:*] set. $1 is the background, $2 the colour of the banded row or
# the pressed state; every foreground is shared, since KDE expects the same
# semantic colours in each set.
kde_set() {
  local bg=$1 alt=$2 fg=$3
  cat <<EOF
BackgroundNormal=$(kde_rgb "$bg")
BackgroundAlternate=$(kde_rgb "$alt")
ForegroundNormal=$(kde_rgb "$fg")
ForegroundInactive=$(kde_rgb "$THEME_DIM")
ForegroundActive=$(kde_rgb "$THEME_ACCENT")
ForegroundLink=$(kde_rgb "$THEME_BLUE")
ForegroundVisited=$(kde_rgb "$THEME_MAGENTA")
ForegroundNegative=$(kde_rgb "$THEME_RED")
ForegroundNeutral=$(kde_rgb "$THEME_YELLOW")
ForegroundPositive=$(kde_rgb "$THEME_GREEN")
DecorationFocus=$(kde_rgb "$THEME_BORDER")
DecorationHover=$(kde_rgb "$THEME_BORDER")
EOF
}

# The KDE colour scheme. Breeze reads these instead of the Qt palette, so the
# same reading of the theme is spelled out again: window and view on the plain
# background, buttons and tooltips a shade above, selection on the border
# colour with dark text.
render_kde() {
  # The scheme is named for the dotfiles rather than the palette, so that
  # switching themes rewrites its colours instead of leaving a scheme called
  # "gruvbox" full of catppuccin.
  printf '[General]\nName=Dotfiles\nColorScheme=Dotfiles\nAccentColor=%s\n\n' \
    "$(kde_rgb "$THEME_BORDER")"
  printf '[Colors:Window]\n%s\n\n' "$(kde_set "$THEME_BG" "$THEME_BG_ALT" "$THEME_FG")"
  printf '[Colors:View]\n%s\n\n' "$(kde_set "$THEME_BG" "$THEME_BG_ALT" "$THEME_FG")"
  printf '[Colors:Button]\n%s\n\n' "$(kde_set "$THEME_BG_ALT" "$THEME_BG_RAISED" "$THEME_FG")"
  printf '[Colors:Tooltip]\n%s\n\n' "$(kde_set "$THEME_BG_ALT" "$THEME_BG_RAISED" "$THEME_FG")"
  printf '[Colors:Complementary]\n%s\n\n' "$(kde_set "$THEME_BG" "$THEME_BG_ALT" "$THEME_FG")"
  printf '[Colors:Header]\n%s\n\n' "$(kde_set "$THEME_BG_ALT" "$THEME_BG_RAISED" "$THEME_FG")"
  printf '[Colors:Selection]\n%s\n\n' "$(kde_set "$THEME_BORDER" "$THEME_BORDER" "$THEME_BG")"
  # The window frame that KWin draws, for the rare KDE app that is not tiled.
  printf '[WM]\nactiveBackground=%s\nactiveForeground=%s\ninactiveBackground=%s\ninactiveForeground=%s\n' \
    "$(kde_rgb "$THEME_BG_ALT")" "$(kde_rgb "$THEME_FG")" \
    "$(kde_rgb "$THEME_BG")" "$(kde_rgb "$THEME_DIM")"
}

# GTK 3 has no light/dark variant to name, it has a flag. GTK 4 and libadwaita
# ignore the flag and read the desktop colour scheme instead, which apply prints
# a reminder about rather than setting, since it is dconf and not a file here.
render_gtk_prefs() {
  local dark=0
  [[ $THEME_SCHEME == dark ]] && dark=1
  printf 'gtk-application-prefer-dark-theme=%d\n' "$dark"
}

# GTK 2 picks the variant by name. Breeze ships both and is already installed.
render_gtk2_theme() {
  if [[ $THEME_SCHEME == dark ]]; then
    printf 'gtk-theme-name = "Breeze-Dark"\n'
  else
    printf 'gtk-theme-name = "Breeze"\n'
  fi
}

render_helix() {
  printf 'theme = "%s"\n' "$THEME_HELIX"
}

# GTK. The three versions share one reading of the palette: the window is the
# background, anything that sits above it — titlebars, sidebars, menus, popovers
# — is the alt background, and the border colour is the selection. Dark text is
# laid on the accent and on yellow and green, which are too bright to carry the
# light foreground.
render_gtk2() {
  local scheme
  scheme+="fg_color:$THEME_FG\n"
  scheme+="bg_color:$THEME_BG\n"
  scheme+="base_color:$THEME_BG\n"
  scheme+="text_color:$THEME_FG\n"
  scheme+="selected_fg_color:$THEME_BG\n"
  scheme+="selected_bg_color:$THEME_BORDER\n"
  scheme+="tooltip_fg_color:$THEME_FG\n"
  scheme+="tooltip_bg_color:$THEME_BG_ALT"
  printf 'gtk_color_scheme = "%s"\n\n' "$scheme"
  cat <<EOF
style "gruvbox-default" {
    fg[NORMAL]        = "$THEME_FG"
    fg[PRELIGHT]      = "$THEME_FG"
    fg[SELECTED]      = "$THEME_BG"
    fg[ACTIVE]        = "$THEME_FG"
    fg[INSENSITIVE]   = "$THEME_DIM"
    bg[NORMAL]        = "$THEME_BG"
    bg[PRELIGHT]      = "$THEME_BG_ALT"
    bg[SELECTED]      = "$THEME_BORDER"
    bg[ACTIVE]        = "$THEME_BG_ALT"
    bg[INSENSITIVE]   = "$THEME_BG"
    base[NORMAL]      = "$THEME_BG"
    base[PRELIGHT]    = "$THEME_BG_ALT"
    base[SELECTED]    = "$THEME_BORDER"
    base[ACTIVE]      = "$THEME_BG_RAISED"
    base[INSENSITIVE] = "$THEME_BG"
    text[NORMAL]      = "$THEME_FG"
    text[PRELIGHT]    = "$THEME_FG"
    text[SELECTED]    = "$THEME_BG"
    text[ACTIVE]      = "$THEME_FG"
    text[INSENSITIVE] = "$THEME_DIM"
}

class "GtkWidget" style "gruvbox-default"
EOF
}

render_gtk3() {
  cat <<EOF
@define-color theme_bg_color $THEME_BG;
@define-color theme_fg_color $THEME_FG;
@define-color theme_base_color $THEME_BG;
@define-color theme_text_color $THEME_FG;
@define-color theme_selected_bg_color $THEME_BORDER;
@define-color theme_selected_fg_color $THEME_BG;

/* Anything a shade above the window: titlebars, menus, popovers, sidebars. */
@define-color raised_bg_color $THEME_BG_ALT;

@define-color insensitive_bg_color $THEME_BG;
@define-color insensitive_fg_color $THEME_DIM;
@define-color insensitive_base_color $THEME_BG;
@define-color unfocused_insensitive_color $THEME_DIM;

@define-color theme_unfocused_bg_color $THEME_BG;
@define-color theme_unfocused_fg_color $THEME_SUBTLE;
@define-color theme_unfocused_base_color $THEME_BG;
@define-color theme_unfocused_text_color $THEME_SUBTLE;
@define-color theme_unfocused_selected_bg_color $THEME_BG_RAISED;
@define-color theme_unfocused_selected_fg_color $THEME_FG;

@define-color borders $THEME_BG_RAISED;
@define-color unfocused_borders $THEME_BG_ALT;
@define-color content_view_bg $THEME_BG;
@define-color text_view_bg $THEME_BG;
@define-color placeholder_text_color $THEME_DIM;

@define-color accent_color $THEME_ACCENT;
@define-color warning_color $THEME_YELLOW;
@define-color error_color $THEME_RED;
@define-color success_color $THEME_GREEN;

/* The window manager colours, which GTK draws into client-side decorations. */
@define-color wm_bg_a $THEME_BG_ALT;
@define-color wm_bg_b $THEME_BG_ALT;
@define-color wm_border $THEME_BG_RAISED;
@define-color wm_borders_edge $THEME_BG_RAISED;
@define-color wm_highlight $THEME_BG_RAISED;
@define-color wm_shadow alpha(black, 0.35);
@define-color wm_title $THEME_FG;
@define-color wm_unfocused_title $THEME_SUBTLE;
@define-color wm_button_hover_color_a $THEME_BG_RAISED;
@define-color wm_button_hover_color_b $THEME_BG_RAISED;
@define-color wm_button_active_color_a $THEME_BORDER;
@define-color wm_button_active_color_b $THEME_BORDER;
@define-color wm_button_active_color_c $THEME_BORDER;
EOF
}

render_gtk4() {
  cat <<EOF
@define-color window_bg_color $THEME_BG;
@define-color window_fg_color $THEME_FG;
@define-color view_bg_color $THEME_BG;
@define-color view_fg_color $THEME_FG;

@define-color headerbar_bg_color $THEME_BG_ALT;
@define-color headerbar_fg_color $THEME_FG;
@define-color headerbar_border_color $THEME_BG_RAISED;
@define-color headerbar_backdrop_color $THEME_BG;
@define-color headerbar_shade_color alpha(black, 0.3);
@define-color headerbar_darker_shade_color alpha(black, 0.5);

@define-color sidebar_bg_color $THEME_BG_ALT;
@define-color sidebar_fg_color $THEME_FG;
@define-color sidebar_backdrop_color $THEME_BG;
@define-color sidebar_border_color $THEME_BG_RAISED;
@define-color sidebar_shade_color alpha(black, 0.25);
@define-color secondary_sidebar_bg_color $THEME_BG_ALT;
@define-color secondary_sidebar_fg_color $THEME_FG;
@define-color secondary_sidebar_backdrop_color $THEME_BG;
@define-color secondary_sidebar_border_color $THEME_BG_RAISED;
@define-color secondary_sidebar_shade_color alpha(black, 0.25);

@define-color card_bg_color $THEME_BG_ALT;
@define-color card_fg_color $THEME_FG;
@define-color card_shade_color alpha(black, 0.3);
@define-color dialog_bg_color $THEME_BG_ALT;
@define-color dialog_fg_color $THEME_FG;
@define-color popover_bg_color $THEME_BG_ALT;
@define-color popover_fg_color $THEME_FG;
@define-color popover_shade_color alpha(black, 0.25);
@define-color thumbnail_bg_color $THEME_BG_RAISED;
@define-color thumbnail_fg_color $THEME_FG;
@define-color overview_bg_color $THEME_BG_ALT;
@define-color overview_fg_color $THEME_FG;
@define-color shade_color alpha(black, 0.25);
@define-color scrollbar_outline_color $THEME_BG_RAISED;

/* Solid backgrounds carry dark text; the standalone ones are text on the
 * window, so they take the bright half of the palette. */
@define-color accent_bg_color $THEME_BORDER;
@define-color accent_fg_color $THEME_BG;
@define-color accent_color $THEME_ACCENT;
@define-color destructive_bg_color ${THEME_ANSI[1]};
@define-color destructive_fg_color $THEME_ON_COLOR;
@define-color destructive_color $THEME_RED;
@define-color error_bg_color ${THEME_ANSI[1]};
@define-color error_fg_color $THEME_ON_COLOR;
@define-color error_color $THEME_RED;
@define-color success_bg_color ${THEME_ANSI[2]};
@define-color success_fg_color $THEME_BG;
@define-color success_color $THEME_GREEN;
@define-color warning_bg_color ${THEME_ANSI[3]};
@define-color warning_fg_color $THEME_BG;
@define-color warning_color $THEME_YELLOW;

/* The GTK 3 names, for the GTK 4 apps that are not libadwaita apps. */
@define-color theme_bg_color $THEME_BG;
@define-color theme_fg_color $THEME_FG;
@define-color theme_base_color $THEME_BG;
@define-color theme_text_color $THEME_FG;
@define-color theme_selected_bg_color $THEME_BORDER;
@define-color theme_selected_fg_color $THEME_BG;
@define-color insensitive_bg_color $THEME_BG;
@define-color insensitive_fg_color $THEME_DIM;
@define-color insensitive_base_color $THEME_BG;
@define-color borders $THEME_BG_RAISED;
@define-color unfocused_borders $THEME_BG_ALT;
EOF
}

render_rofi() {
  cat <<EOF
    bg: $THEME_BG;
    bg-alt: $THEME_BG_ALT;
    fg: $THEME_FG;
    fg-alt: $THEME_FG_ALT;
    dim: $THEME_DIM;
    frame: $THEME_BORDER;
    accent: $THEME_ACCENT;
    urgent: $THEME_RED;
EOF
}

render_power() {
  cat <<EOF
BG=\${POWER_BG:-"$THEME_BG"}           # window
BG_ALPHA=\${POWER_BG_ALPHA:-ff}      # opaque; the last byte of the window colour
FG=\${POWER_FG:-"$THEME_FG"}           # tile labels
BORDER=\${POWER_BORDER:-"$THEME_BORDER"}   # the frame around the window
TILE=\${POWER_TILE:-"$THEME_BG_ALT"}       # behind the tile under the cursor
ACCENT=\${POWER_ACCENT:-"$THEME_ACCENT"}   # the frame of the tile under the cursor, the title
DIM=\${POWER_DIM:-"$THEME_DIM"}         # keys and uptime
DANGER=\${POWER_DANGER:-"$THEME_RED"}   # the frame of the tile in a confirmation

# One colour per action, so the tile you want is found by colour before its
# label is read.
C_LOCK=\${POWER_LOCK_COLOR:-"$THEME_BLUE"}
C_TRAVEL=\${POWER_TRAVEL_COLOR:-"$THEME_GREEN"}
C_LOGOUT=\${POWER_LOGOUT_COLOR:-"$THEME_MAGENTA"}
C_SUSPEND=\${POWER_SUSPEND_COLOR:-"$THEME_YELLOW"}
C_HIBERNATE=\${POWER_HIBERNATE_COLOR:-"$THEME_CYAN"}
C_REBOOT=\${POWER_REBOOT_COLOR:-"$THEME_ORANGE"}
C_SHUTDOWN=\${POWER_SHUTDOWN_COLOR:-"$THEME_RED"}
EOF
}

render_calendar() {
  cat <<EOF
BG=\${CAL_BG:-"$THEME_BG"}             # window, and the text on the selected day
BG_ALPHA=\${CAL_BG_ALPHA:-ff}        # opaque; the last byte of the window colour
FG=\${CAL_FG:-"$THEME_FG"}             # the days themselves
BORDER=\${CAL_BORDER:-"$THEME_BORDER"}     # the frame around the window
ACCENT=\${CAL_ACCENT:-"$THEME_ACCENT"}     # the date line at the top
SELECTED=\${CAL_SELECTED:-"$THEME_BORDER"} # behind the day under the cursor
TODAY=\${CAL_TODAY:-"$THEME_CYAN"}       # today, when it is not the day under the cursor
WEEKEND=\${CAL_WEEKEND:-"$THEME_RED"}   # Sunday
HEADING=\${CAL_HEADING:-"$THEME_SUBTLE"}   # the names of the weekdays
RULE=\${CAL_RULE:-"$THEME_BG_RAISED"}         # the lines between the parts
KEY=\${CAL_KEY:-"$THEME_FG_ALT"}           # the keys in the hint line
DIM=\${CAL_DIM:-"$THEME_DIM"}           # what the keys do
EOF
}

render_clipboard() {
  printf 'key_color="%s"\n' "$THEME_FG_ALT"
}

# ---------------------------------------------------------------------------
# Hooks that run after a file's blocks are written, for colours a format will
# not let a block hold.
# ---------------------------------------------------------------------------

# polybar cannot reference its [colors] inside %{F...} tags, so the tags are
# repainted by matching the colours the block held before it was rewritten.
# Every old colour becomes a placeholder first, so a new colour that equals
# some other old one is not repainted twice.
declare -A polybar_before=()
before_polybar() {
  local key value
  polybar_before=()
  while IFS=' =' read -r key value; do
    polybar_before[$key]=$value
  done < <(sed -n '/theme:begin polybar/,/theme:end/{/=/p}' "$1")
}

after_polybar() {
  local key new script=
  for key in "${!polybar_before[@]}"; do
    script+="s/%{F${polybar_before[$key]}}/%{F@$key@}/Ig;"
  done
  while IFS=' =' read -r key new; do
    script+="s/%{F@$key@}/%{F$new}/g;"
  done < <(render_polybar)
  sed -i "$script" "$1"
}

# ---------------------------------------------------------------------------

marked_files() {
  grep -rlI --exclude-dir=.git -E 'theme:begin [a-z]' "$root" | grep -vxF "$self" | sort
}

blocks_in() {
  grep -oE 'theme:begin [a-z0-9-]+' "$1" | cut -d' ' -f2
}

load_theme() {
  local theme=$1 file
  if [[ $theme == */* ]]; then file=$theme; else file=$themes/$theme.sh; fi
  [[ -r $file ]] || {
    echo "theme.sh: no theme at $file" >&2
    exit 1
  }
  # shellcheck source=../themes/gruvbox-dark.sh
  source "$themes/gruvbox-dark.sh"
  # shellcheck disable=SC1090
  source "$file"
}

apply() {
  local theme=${1:?apply needs a theme name or path}
  load_theme "$theme"

  local file block fn rel status=0
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT

  # Everything is drawn before anything is written, so an unknown block or a
  # broken theme leaves every file as it was.
  while read -r file; do
    for block in $(blocks_in "$file"); do
      fn=render_${block//-/_}
      if ! declare -F "$fn" >/dev/null; then
        echo "theme.sh: ${file#"$root"/}: no render_${block//-/_} for block '$block'" >&2
        status=1
        continue
      fi
      "$fn" >"$tmp/$block"
    done
  done < <(marked_files)
  ((status == 0)) || exit "$status"

  while read -r file; do
    rel=${file#"$root"/}
    for block in $(blocks_in "$file"); do
      declare -F "before_${block//-/_}" >/dev/null && "before_${block//-/_}" "$file"
    done
    awk -v dir="$tmp" -v name="$rel" '
            match($0, /theme:begin [a-z0-9-]+/) {
                print
                block = dir "/" substr($0, RSTART + 12, RLENGTH - 12)
                while ((getline line < block) > 0) print line
                close(block)
                inside = 1
                next
            }
            /theme:end/ { inside = 0 }
            !inside { print }
            END {
                if (inside) {
                    print "theme.sh: " name ": theme:begin without theme:end" > "/dev/stderr"
                    exit 1
                }
            }
        ' "$file" >"$tmp/out"
    # Written over rather than moved, so the file keeps its mode and links.
    cat "$tmp/out" >"$file"
    for block in $(blocks_in "$file"); do
      declare -F "after_${block//-/_}" >/dev/null && "after_${block//-/_}" "$file"
    done
    echo "  $rel"
  done < <(marked_files)

  if [[ $theme == */* ]]; then realpath "$theme"; else echo "$theme"; fi >"$themes/current"
  # install.sh copies this out and sets the desktop colour scheme from
  # THEME_SCHEME, which is what makes a light theme land on light widgets.
  echo "Applied $theme ($THEME_SCHEME). Run scripts/install.sh, then reload sway, niri, dunst and tmux."
}

case ${1:-} in
apply) apply "${2:-}" ;;
list) for f in "$themes"/*.sh; do basename "$f" .sh; done ;;
current) cat "$themes/current" 2>/dev/null || echo "none applied yet" ;;
check)
  while read -r file; do
    for block in $(blocks_in "$file"); do
      if declare -F "render_${block//-/_}" >/dev/null; then mark=ok; else mark=MISSING; fi
      printf '%-8s %-40s %s\n' "$mark" "${file#"$root"/}" "$block"
    done
  done < <(marked_files)
  ;;
-h | --help | help) usage ;;
*)
  usage >&2
  exit 2
  ;;
esac
