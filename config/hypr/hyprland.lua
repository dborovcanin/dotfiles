-- Hyprland config, ported from config/sway/config.
-- https://wiki.hypr.land/Configuring/
--
-- Hyprland tiles the way sway does, so this is a closer port than the niri one:
-- binding modes become submaps, sticky becomes pin, the scratchpad becomes a
-- special workspace and urgent focus is a dispatcher. What has no equivalent is
-- noted inline - focus parent, per-window split direction, and gaps changed by a
-- step rather than to a preset.
--
-- Colours are written by scripts/theme.sh between the theme markers.
--
-- Since 0.56 the config is Lua; hyprland.conf is the legacy format Hyprland
-- still reads only when this file is missing.

local mod = "SUPER"
local dotfiles = os.getenv("HOME") .. "/dotfiles"

-- The wallpaper and the lock screen are each configured in their own file beside
-- this one - hyprpaper.conf and hyprlock.conf - and both name the pictures
-- scripts/background.sh renders.

-- --- Environment -----------------------------------------------------------

hl.env("GTK2_RC_FILES", os.getenv("HOME") .. "/.gtkrc-2.0")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("XCURSOR_THEME", "BreezeX-Light")
hl.env("XCURSOR_SIZE", "28")

-- --- Monitors --------------------------------------------------------------
--
-- Hyprland has no per-output background; hyprpaper draws it, started from the
-- startup section below with its own file in the clone.

-- disabled = false is spelled out because a monitor rule is merged into the one
-- before it: without it, turning a display back on keeps the disabled flag the
-- $mod+shift+p keys set.
local laptop = { output = "eDP-1", mode = "1920x1200", position = "0x0", scale = 1, disabled = false }
local external = { output = "DP-1", mode = "preferred", position = "1920x0", scale = 1, transform = 0, disabled = false }

hl.monitor(laptop)
hl.monitor(external)
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "1920x0", scale = 1 })

-- --- Input -----------------------------------------------------------------

hl.config({
    input = {
        kb_layout = "us,rs,rs",
        kb_variant = ",latin,",
        kb_options = "grp:alt_shift_toggle",

        follow_mouse = 1,

        touchpad = {
            tap_to_click = true,
            tap_and_drag = true,
            tap_button_map = "lrm",
            disable_while_typing = true,
            drag_lock = false,
            middle_button_emulation = true,
        },
    },
})

-- --- Look ------------------------------------------------------------------

hl.config({
    general = {
        -- theme:begin hypr-geometry
        gaps_in = 5,
        gaps_out = 10,
        border_size = 4,
        -- theme:end
        layout = "dwindle",
        col = {
            -- theme:begin hypr-border
            active_border = "rgb(88c0d0)",
            inactive_border = "rgb(3b4252)",
            -- theme:end
        },
    },

    decoration = {
        -- theme:begin hypr-rounding
        rounding = 5,
        -- theme:end

        blur = {
            enabled = true,
            size = 8,
            passes = 1,
            noise = 0.02,
        },
    },

    -- Tabbed containers. $mod+w groups the window with its neighbours and the
    -- groupbar is the row of tabs sway drew in its title bars.
    group = {
        col = {
            -- theme:begin hypr-group
            border_active = "rgb(88c0d0)",
            border_inactive = "rgb(3b4252)",
            -- theme:end
        },

        groupbar = {
            -- theme:begin hypr-groupbar-font
            font_family = "JetBrainsMonoNL NF",
            font_size = 14,
            -- theme:end
            col = {
                -- theme:begin hypr-groupbar
                active = "rgb(88c0d0)",
                inactive = "rgb(7b88a1)",
                -- theme:end
            },
        },
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        -- theme:begin hypr-background
        background_color = "rgb(2e3440)",
        -- theme:end
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },
})

hl.animation({ leaf = "windows", enabled = true, speed = 1.5, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 1.5, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 1.5, bezier = "default" })
-- Workspace switches are instant, as they are under niri.
hl.animation({ leaf = "workspaces", enabled = false })

-- --- Window and workspace rules --------------------------------------------
--
-- class matches the Wayland app-id and the X11 class alike, so the two lists the
-- sway config keeps apart are one list here.

-- sway's smart_gaps and smart_borders: a workspace holding one tiled window gets
-- no gaps, no border and no rounding.
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })

hl.window_rule({ match = { class = "(?i)^slack$" }, workspace = "1" })
hl.window_rule({ match = { class = "(?i)^(code|code-oss|codium|vscodium)$" }, workspace = "2" })
hl.window_rule({ match = { class = "^brave-browser$" }, workspace = "3" })
hl.window_rule({ match = { class = "^Postman$" }, workspace = "4" })
hl.window_rule({ match = { class = "^zoom$" }, workspace = "6" })

hl.window_rule({ match = { class = "^(float_term|sticky_term)$" }, float = true, size = { 1400, 1000 }, center = true })
hl.window_rule({ match = { class = "^sticky_term$" }, pin = true })
hl.window_rule({ match = { class = "^(content-search|file-search)$" }, float = true, size = { 1500, 950 }, center = true })
hl.window_rule({ match = { class = "^slight$" }, float = true, size = { 1400, 950 }, center = true, pin = true })
hl.window_rule({ match = { class = "^system-monitor$" }, float = true, size = { 1800, 900 }, center = true })
hl.window_rule({ match = { class = "^(satty|feh|fzf-menu)$" }, float = true })

-- Meetings keep the screen awake and follow you between workspaces.
hl.window_rule({ match = { title = "(?i).*meet.*" }, idle_inhibit = "focus", pin = true })

-- --- Startup ---------------------------------------------------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper -c " .. dotfiles .. "/config/hypr/hyprpaper.conf")
    -- dbar speaks to niri and sway only; under Hyprland it exits at once and the
    -- bar stays empty until dbar grows a Hyprland backend. The line is here so
    -- that the day it does, nothing else has to change.
    hl.exec_cmd("dbar -c " .. dotfiles .. "/config/dbar/config.toml")
    hl.exec_cmd("xrdb -merge ~/.Xresources")
    hl.exec_cmd("dunst -config " .. dotfiles .. "/config/dunst/dunstrc > /dev/null")
    hl.exec_cmd(dotfiles .. "/scripts/startup.sh > /dev/null")
    hl.exec_cmd("foot --server")
    hl.exec_cmd("kdeconnectd > /dev/null")
    hl.exec_cmd("wl-paste --watch cliphist -max-items 5000 store")
    hl.exec_cmd("hypridle -c " .. dotfiles .. "/config/hypr/hypridle.conf")
end)

-- --- Bindings --------------------------------------------------------------

local function key(mods, k)
    if mods == "" then
        return k
    end
    return mods .. " + " .. k
end

local function exec(cmd)
    return hl.dsp.exec_cmd(cmd)
end

-- Terminals
hl.bind(key(mod, "Return"), exec("footclient -T term"))
hl.bind(key(mod .. " + SHIFT", "Return"), exec("footclient -T term --app-id float_term"))
hl.bind(key(mod .. " + CTRL + SHIFT", "Return"), exec("footclient --app-id sticky_term"))

-- Displays. sway drove these through wlr-randr; a Hyprland monitor is put back
-- by the next config reload, so it is moved through Hyprland itself instead.
hl.bind(key(mod, "p"), function() hl.monitor(laptop) end)
hl.bind(key(mod .. " + CTRL", "p"), function() hl.monitor(external) end)
hl.bind(key(mod .. " + SHIFT", "p"), function() hl.monitor({ output = "eDP-1", disabled = true }) end)
hl.bind(key(mod .. " + CTRL + SHIFT", "p"), function() hl.monitor({ output = "DP-1", disabled = true }) end)

hl.bind(key(mod .. " + SHIFT", "q"), hl.dsp.window.close())

-- Launcher
hl.bind(key(mod, "d"), exec(dotfiles .. "/scripts/launcher.sh"))

-- Focus
hl.bind(key(mod, "j"), hl.dsp.focus({ direction = "left" }))
hl.bind(key(mod, "k"), hl.dsp.focus({ direction = "right" }))
hl.bind(key(mod, "Left"), hl.dsp.focus({ direction = "left" }))
hl.bind(key(mod, "Down"), hl.dsp.focus({ direction = "down" }))
hl.bind(key(mod, "Up"), hl.dsp.focus({ direction = "up" }))
hl.bind(key(mod, "Right"), hl.dsp.focus({ direction = "right" }))

-- Move
hl.bind(key(mod .. " + SHIFT", "j"), hl.dsp.window.move({ direction = "left" }))
hl.bind(key(mod .. " + SHIFT", "k"), hl.dsp.window.move({ direction = "down" }))
hl.bind(key(mod .. " + SHIFT", "l"), hl.dsp.window.move({ direction = "up" }))
hl.bind(key(mod .. " + SHIFT", "semicolon"), hl.dsp.window.move({ direction = "right" }))
hl.bind(key(mod .. " + SHIFT", "Left"), hl.dsp.window.move({ direction = "left" }))
hl.bind(key(mod .. " + SHIFT", "Down"), hl.dsp.window.move({ direction = "down" }))
hl.bind(key(mod .. " + SHIFT", "Up"), hl.dsp.window.move({ direction = "up" }))
hl.bind(key(mod .. " + SHIFT", "Right"), hl.dsp.window.move({ direction = "right" }))

-- dwindle picks the split direction from the shape of the window, and only
-- offers to flip it afterwards - there is no "the next window goes to the
-- right" the way sway's split h and split v have. Both keys flip the active
-- window's split, so either one still does what it did.
hl.bind(key(mod, "h"), hl.dsp.layout("togglesplit"))
hl.bind(key(mod, "v"), hl.dsp.layout("togglesplit"))

hl.bind(key(mod, "f"), hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(key(mod .. " + ALT", "f"), hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(key(mod, "s"), hl.dsp.layout("togglesplit"))

-- Tabs. sway's tabbed layout is a group here, so there is also a key to take a
-- window back out of one.
hl.bind(key(mod, "w"), hl.dsp.group.toggle())
hl.bind(key(mod .. " + SHIFT", "w"), hl.dsp.window.move({ out_of_group = true }))
hl.bind(key(mod, "Tab"), hl.dsp.group.next())

hl.bind(key(mod, "t"), hl.dsp.window.float({ action = "toggle" }))
-- Hyprland has no single float/tile focus toggle: one key walks the floating
-- windows and the other walks the tiled ones.
hl.bind(key(mod, "space"), hl.dsp.window.cycle_next({ floating = true }))
hl.bind(key(mod .. " + SHIFT", "space"), hl.dsp.window.cycle_next({ tiled = true }))

-- No equivalent of sway's $mod+a: dwindle exposes no parent container to focus.

-- Resize. The Lua resize dispatcher takes pixels only, so the tenth of the
-- screen the legacy config asked for as 10% is worked out from the monitor.
local function resize_by(fx, fy)
    return function()
        local m = hl.get_active_monitor()
        if m == nil then
            return
        end
        hl.dispatch(hl.dsp.window.resize({
            x = math.floor(m.width / m.scale * fx),
            y = math.floor(m.height / m.scale * fy),
            relative = true,
        }))
    end
end

hl.bind(key(mod, "r"), hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("j", resize_by(-0.1, 0))
    hl.bind("k", resize_by(0, 0.1))
    hl.bind("l", resize_by(0, -0.1))
    hl.bind("semicolon", resize_by(0.1, 0))
    hl.bind("Left", resize_by(0.1, 0))
    hl.bind("Right", resize_by(-0.1, 0))
    hl.bind("Up", resize_by(0, 0.1))
    hl.bind("Down", resize_by(0, -0.1))
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
    hl.bind(key(mod, "r"), hl.dsp.submap("reset"))
end)

-- Gaps. Hyprland changes gaps only by being told a number, never by a step, so
-- these are presets where sway had plus and minus.
local function gaps(inner, outer)
    return function()
        hl.config({ general = { gaps_in = inner, gaps_out = outer } })
    end
end

hl.bind(key(mod .. " + SHIFT", "g"), hl.dsp.submap("gaps"))
hl.define_submap("gaps", function()
    hl.bind("0", gaps(0, 0))
    hl.bind("1", gaps(5, 10))
    hl.bind("2", gaps(10, 20))
    hl.bind("3", gaps(20, 40))
    hl.bind("Return", hl.dsp.submap("reset"))
    hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- Workspaces
for i = 1, 10 do
    local k = tostring(i % 10)
    hl.bind(key(mod, k), hl.dsp.focus({ workspace = i }))
    hl.bind(key(mod .. " + SHIFT", k), hl.dsp.window.move({ workspace = i }))
end

-- Move the workspace to another output
hl.bind(key(mod, "o"), hl.dsp.submap("move_workspace"))
hl.define_submap("move_workspace", function()
    hl.bind("Left", hl.dsp.workspace.move({ monitor = "l" }))
    hl.bind("Right", hl.dsp.workspace.move({ monitor = "r" }))
    hl.bind("Up", hl.dsp.workspace.move({ monitor = "u" }))
    hl.bind("Down", hl.dsp.workspace.move({ monitor = "d" }))
    hl.bind("Escape", hl.dsp.submap("reset"))
end)

-- Reload
hl.bind(key(mod .. " + SHIFT", "r"), exec("hyprctl reload"))

-- Exit. sway asked through swaynag and niri draws its own dialog; Hyprland asks
-- nothing and quits at once. The power menu on $mod+Escape has a logout tile
-- that goes through the same dispatcher with a menu in front of it.
hl.bind(key(mod .. " + SHIFT", "e"), hl.dsp.exit())

-- Power menu (shared with sway, niri and i3)
hl.bind(key(mod, "Escape"), exec(dotfiles .. "/scripts/power.sh"))

-- Scratchpad
hl.bind(key(mod .. " + SHIFT", "m"), hl.dsp.window.move({ workspace = "special:scratch", follow = false }))
hl.bind(key(mod, "m"), hl.dsp.workspace.toggle_special("scratch"))

-- Focus urgent window
hl.bind(key(mod, "x"), hl.dsp.focus({ urgent_or_last = true }))

-- Brightness and audio. locked keeps them working over the lock screen.
local locked = { locked = true }
hl.bind("XF86MonBrightnessUp", exec(dotfiles .. "/scripts/brightness.sh up"), locked)
hl.bind("XF86MonBrightnessDown", exec(dotfiles .. "/scripts/brightness.sh down"), locked)
hl.bind("SHIFT + XF86MonBrightnessUp", exec("ddcutil setvcp 10 + 5"), locked)
hl.bind("SHIFT + XF86MonBrightnessDown", exec("ddcutil setvcp 10 - 5"), locked)
hl.bind("XF86AudioRaiseVolume", exec("pactl set-sink-volume @DEFAULT_SINK@ +5%"), locked)
hl.bind("XF86AudioLowerVolume", exec("pactl set-sink-volume @DEFAULT_SINK@ -5%"), locked)
hl.bind("XF86AudioMute", exec("pactl set-sink-mute @DEFAULT_SINK@ toggle"), locked)

-- Tools
hl.bind(key(mod, "e"), exec(dotfiles .. "/scripts/emoji.sh"))
hl.bind(key(mod .. " + SHIFT", "f"), exec("footclient --app-id content-search sh -c \"" .. dotfiles .. "/scripts/content_search.sh\""))
hl.bind(key(mod .. " + CTRL", "f"), exec("footclient --app-id file-search sh -c \"" .. dotfiles .. "/bin/search\""))
hl.bind(key(mod, "n"), exec("footclient -w 1400x950 --app-id slight ~/.local/bin/slight"))
hl.bind(key(mod, "b"), exec("footclient --app-id system-monitor btop"))
hl.bind(key(mod .. " + SHIFT", "c"), exec("codium " .. dotfiles))
hl.bind(key(mod, "c"), exec(dotfiles .. "/scripts/clipboard.sh"))
hl.bind(key(mod, "g"), exec("brave > /dev/null"))
hl.bind(key(mod .. " + SHIFT", "s"), exec(dotfiles .. "/scripts/screenshot.sh"))

-- Notifications
hl.bind("CTRL + space", exec("dunstctl close"))
hl.bind("CTRL + SHIFT + space", exec("dunstctl close-all"))
hl.bind("ALT + grave", exec("dunstctl history-pop"))
hl.bind("CTRL + SHIFT + period", exec("dunstctl context"))

-- Mouse
hl.bind(key(mod, "mouse:272"), hl.dsp.window.drag(), { mouse = true })
hl.bind(key(mod, "mouse:273"), hl.dsp.window.resize(), { mouse = true })
