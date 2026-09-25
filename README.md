# dotfiles

Config for my Linux desktop: window managers (niri, sway, Hyprland, i3), terminals,
shells, editors and the scripts that hold them together. Every colour in the repo
comes from one theme file, and the fonts, borders, corners, gaps and transparency
from one style file, so a single command restyles the whole desktop.

## Layout

| Path                    | What                                                                                                                                                |
| ----------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `config/`               | per-program configs (niri, sway, hypr, i3, foot, alacritty, kitty, ghostty, fish, helix, nvim, rofi, dunst, polybar, dbar, btop, gtk, qt, starship) |
| `scripts/`              | launcher, screenshot, clipboard, power, brightness, background, theme, startup                                                                      |
| `themes/`               | colour themes (`nord.sh`, `gruvbox-dark.sh`, …), `style.sh` for fonts and geometry, and the wallpaper                                               |
| `tools/`                | Go and Rust helpers, built into `bin/`                                                                                                              |
| `zsh/`, `tmux/`, `etc/` | shell, tmux and system files                                                                                                                        |

## Requirements

- Core: `bash`, `git`, `fish` or `zsh`, `tmux`
- Desktop: one of `niri` / `sway` / `hyprland` / `i3`, plus `rofi`, `dunst`,
  a bar (`dbar`, `polybar` or i3status) and a terminal (`foot`, `alacritty`,
  `kitty`, `ghostty`)
- Scripts: `fzf`, `jq`, `fd`, `magick` (ImageMagick), `wl-clipboard` or `xclip`,
  `swaybg`/`feh`, `gsettings`, `xrdb` (X11)
- Tools: Go 1.26+ and Rust (cargo) to build `tools/`

Everything is probed at runtime; missing programs are skipped, not fatal.

## Install

```sh
git clone https://github.com/dborovcanin/dotfiles ~/dotfiles
cd ~/dotfiles
./scripts/install.sh --dry-run   # see what would be replaced
./scripts/install.sh
```

`install.sh` copies the configs that programs insist on reading from their own
paths, backs up what it replaces under `~/.config/dotfiles-backup-<timestamp>`,
and reloads whatever is running. Flags: `--dry-run`, `--no-backup`, `--no-reload`.

The clone must live at `~/dotfiles`: the window manager configs run `scripts/`,
`bin/` and the bar, notification and launcher configs straight out of it, so
those are deliberately not copied.

`etc/tlp.conf` needs root: `sudo cp etc/tlp.conf /etc/tlp.conf`.

## Setup

Build the tools (`bin/search`, used by the launcher, and `bin/niri-autofill`,
which niri starts):

```sh
make -C tools install       # builds bin/, installs into ~/.local/bin
```

Pick a theme, then install so the copies land in `~`:

```sh
./scripts/theme.sh list
./scripts/theme.sh apply nord
./scripts/install.sh
```

`theme.sh` rewrites every block marked `theme:begin` / `theme:end` in the repo;
`theme.sh current` shows the theme in use, `theme.sh check` verifies the blocks.

What is not a colour lives in `themes/style.sh`: the font roles (menus, prompt
icons, terminals, the bar, GTK and Qt applications), the border width, the radii,
the gaps and the transparency. It is read before the theme, so it holds for all
of them, and a theme that wants its own sets the same variable again. Change a
value there and run `theme.sh apply` and `install.sh` as above.

Pick a wallpaper (renders sharp and blurred copies for the lock screen):

```sh
./scripts/background.sh
```

Note: Make backups of your config files if you want to make sure nothing is lost.