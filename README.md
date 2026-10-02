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

On Arch, `install.sh` installs these for the window manager it is given with
`--wm` (`sway`, the default and installed as `swayfx`, `niri`, `hyprland`, `i3`,
a comma-separated list, or `all`): the shared programs plus that compositor's
bar, locker, idler, wallpaper, portal backend and clipboard and screenshot
tools. Repo packages go through `sudo pacman`; `swayfx`, `dbar`, `kbdd-git`,
`breezex-cursor-theme`, `zsh-theme-powerlevel10k`, `brave-bin` and
`vscodium-bin` come from the AUR through `paru` or `yay` (install one first).
Only what is missing is asked for. Elsewhere, install them by hand.

Everything is probed at runtime; missing programs are skipped, not fatal.

## Install

```sh
git clone https://github.com/dborovcanin/dotfiles ~/dotfiles
cd ~/dotfiles
./scripts/install.sh --dry-run   # see what would be installed and replaced
./scripts/install.sh             # sway; or --wm niri, --wm hyprland,i3, --wm all
```

`install.sh` installs the missing packages, copies the configs that programs
insist on reading from their own paths, backs up what it replaces under
`~/.config/dotfiles-backup-<timestamp>`, and reloads whatever is running. Flags:
`--wm`, `--dry-run`, `--no-backup`, `--no-reload`, `--no-packages`.

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
