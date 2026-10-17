-- hyprd3mon: Hyprland 0.56 config (Lua). d3mon theme, frosted glass.
-- Installed by hyprd3mon's install.sh; local edits are backed up and
-- replaced on the next install. Put your own monitor setup in
-- monitors.lua (never overwritten) and extra tweaks in local.lua.

local home   = os.getenv("HOME")
local bin    = home .. "/.local/bin/"
-- XDG dir from the environment, or the default when unset or empty.
local function xdg(var, fallback)
    local v = os.getenv(var)
    if v == nil or v == "" then return home .. fallback end
    return v
end
local cfg    = xdg("XDG_CONFIG_HOME", "/.config") .. "/hyprd3mon/"
local cache  = xdg("XDG_CACHE_HOME", "/.cache") .. "/hyprd3mon/"

local terminal    = "kitty"
local fileManager = "nautilus --new-window"
local launcher    = bin .. "hyprd3mon-launcher"
local power       = bin .. "hyprd3mon-power"
local shot        = bin .. "hyprd3mon-shot"
local help        = bin .. "hyprd3mon-help"
local settingsApp = bin .. "hyprd3mon-settings"

-- Reads `key = value` / `key=value` lines (# comments) into a table.
local function readConf(path)
    local t = {}
    local f = io.open(path, "r")
    if not f then return t end
    for raw in f:lines() do
        -- `#` starts a comment at line start, or after a space once the
        -- value has begun, so `accent = #91e611  # lime` keeps its value.
        local k, v = raw:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
        if k then v = v:gsub("%s+#.*$", "") end
        if k and v ~= "" then t[k] = v end
    end
    f:close()
    return t
end

-- settings.conf is written by the gear menu (hyprd3mon-settings).
local settings = readConf(cfg .. "settings.conf")

-- Theme palette (dark or light), installed by install.sh.
local theme   = settings.theme == "light" and "light" or "dark"
local palette = readConf(home .. "/.local/share/hyprd3mon/themes/" .. theme .. ".conf")
local function unquote(v) return v and (v:gsub('^"(.*)"$', "%1")) end

-- d3mon: one accent colour. "auto" = the theme's default.
local accentHex = (settings.accent or ""):match("^#(%x%x%x%x%x%x)$")
    or (unquote(palette.accent_default) or ""):match("^#(%x%x%x%x%x%x)$")
    or "91e611"
local accent = "rgba(" .. accentHex:lower() .. "ee)"
local line   = unquote(palette.hypr_inactive_border)
    or (theme == "light" and "rgba(0000002e)" or "rgba(ffffff1a)")

------------------
---- MONITORS ----
------------------

-- monitors.lua holds the layout (single screen or stacked pair).
-- Fallback if it's missing: every screen auto-placed above the last.
if not pcall(require, "monitors") then
    hl.monitor({ output = "", mode = "preferred", position = "auto-center-up", scale = "auto" })
end

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("waybar -c ~/.config/waybar/config.jsonc")
    hl.exec_cmd("mako")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    -- GTK/libadwaita apps (Nautilus, file pickers) follow the theme.
    -- Plasma may reset these when you go back to KDE, so re-apply the
    -- settings (and regenerate theme files) at every login.
    hl.exec_cmd(bin .. "hyprd3mon-apply-settings --no-reload")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
if not (":" .. path .. ":"):find(":" .. bin:sub(1, -2) .. ":", 1, true) then
    hl.env("PATH", bin:sub(1, -2) .. ":" .. path)
end
-- Native Wayland where apps support it (dark mode comes from gsettings).
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")

-----------------------
---- LOOK AND FEEL ----
-----------------------

hl.config({
    general = {
        gaps_in  = 6,
        gaps_out = 14,

        border_size = 2,

        col = {
            active_border   = accent,
            inactive_border = line,
        },

        resize_on_border = true,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 14,
        rounding_power = 2,

        -- Frosted glass: every window is slightly see-through and the
        -- blur behind it softens the wallpaper. Kitty brings its own
        -- background opacity (see the kitty rule below).
        active_opacity     = 0.92,
        inactive_opacity   = 0.85,
        fullscreen_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 24,
            render_power = 3,
            color        = 0x66000000,
        },

        blur = {
            enabled           = true,
            size              = 8,
            passes            = 3,
            noise             = 0.02,
            contrast          = 0.9,
            brightness        = 0.8,
            vibrancy          = 0.2,
            new_optimizations = true,
            popups            = true,
        },
    },

    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1},  {0.32, 1} } })
hl.curve("linear",       { type = "bezier", points = { {0, 0},     {1, 1}    } })
hl.curve("almostLinear", { type = "bezier", points = { {0.5, 0.5}, {0.75, 1} } })
hl.curve("quick",        { type = "bezier", points = { {0.15, 0},  {0.1, 1}  } })
hl.curve("easy",         { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

-- Short smooth slides and fades; nothing bouncy.
hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  spring = "easy",         style = "popin 90%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 90%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

hl.config({
    dwindle = {
        preserve_split = true,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = 0,   -- hyprpaper draws the grid
        disable_hyprland_logo   = true,
        focus_on_activate       = true,
    },
})

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout    = "us",
        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

---------------------
---- KEYBINDINGS ----
---------------------

-- One table drives everything: the binds below, the help (?) list and
-- the gear menu's keybind editor. Each row: id, group, label, keys,
-- action, options. Overrides from ~/.config/hyprd3mon/keybinds.conf
-- (`id = SUPER + D`, or `none` to unbind) replace the default keys.

local exec = hl.dsp.exec_cmd
local binds = {
    { "terminal",    "Apps", "Terminal (Kitty)",        "SUPER + Return", exec(terminal) },
    { "launcher",    "Apps", "App launcher",            "SUPER + Space",  exec(launcher) },
    { "launcher_2",  "Apps", "App launcher (alt)",      "SUPER + R",      exec(launcher) },
    { "files",       "Apps", "Files (Nautilus)",        "SUPER + E",      exec(fileManager) },
    { "browser",     "Apps", "Firefox",                 "SUPER + B",      exec("firefox") },
    { "help",        "Apps", "Keybind help",            "SUPER + F1",     exec(help) },
    { "settings",    "Apps", "Settings",                "SUPER + comma",  exec(settingsApp) },

    { "lock",        "Session", "Lock screen",          "SUPER + L",      exec("pidof hyprlock || hyprlock") },
    { "power",       "Session", "Power menu",           "SUPER + Escape", exec(power) },

    { "close",       "Windows", "Close window",         "SUPER + Q",      hl.dsp.window.close() },
    { "float",       "Windows", "Float / tile",         "SUPER + V",      hl.dsp.window.float({ action = "toggle" }) },
    { "fullscreen",  "Windows", "Fullscreen",           "SUPER + F",      hl.dsp.window.fullscreen({ action = "toggle" }) },
    { "pseudo",      "Windows", "Pseudotile",           "SUPER + P",      hl.dsp.window.pseudo() },
    { "split",       "Windows", "Toggle split",         "SUPER + J",      hl.dsp.layout("togglesplit") },
    { "focus_left",  "Windows", "Focus left",           "SUPER + left",   hl.dsp.focus({ direction = "left" }) },
    { "focus_right", "Windows", "Focus right",          "SUPER + right",  hl.dsp.focus({ direction = "right" }) },
    { "focus_up",    "Windows", "Focus up",             "SUPER + up",     hl.dsp.focus({ direction = "up" }) },
    { "focus_down",  "Windows", "Focus down",           "SUPER + down",   hl.dsp.focus({ direction = "down" }) },
    { "drag",        "Windows", "Move window (drag)",   "SUPER + mouse:272", hl.dsp.window.drag(),   { mouse = true } },
    { "resize",      "Windows", "Resize window (drag)", "SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true } },

    -- Every screenshot is saved to ~/Pictures/Screenshots AND copied
    -- to the clipboard, ready to paste into Discord or a website.
    { "shot_region",    "Screenshots", "Region",               "Print",             exec(shot .. " region") },
    { "shot_window",    "Screenshots", "Window",               "SUPER + Print",     exec(shot .. " window") },
    { "shot_monitor",   "Screenshots", "This monitor",         "SHIFT + Print",     exec(shot .. " monitor") },
    { "shot_all",       "Screenshots", "All monitors",         "CTRL + Print",      exec(shot .. " all") },
    { "shot_region_2",  "Screenshots", "Region (alt)",         "SUPER + SHIFT + S", exec(shot .. " region") },
    { "shot_window_2",  "Screenshots", "Window (alt)",         "SUPER + SHIFT + W", exec(shot .. " window") },
    { "shot_monitor_2", "Screenshots", "This monitor (alt)",   "SUPER + SHIFT + M", exec(shot .. " monitor") },
    { "shot_all_2",     "Screenshots", "All monitors (alt)",   "SUPER + SHIFT + A", exec(shot .. " all") },
}

for i = 1, 10 do
    local key = tostring(i % 10)
    binds[#binds + 1] = { "workspace_" .. i, "Workspaces", "Go to workspace " .. i,
        "SUPER + " .. key, hl.dsp.focus({ workspace = i }) }
end
for i = 1, 10 do
    local key = tostring(i % 10)
    binds[#binds + 1] = { "move_to_" .. i, "Workspaces", "Move window to workspace " .. i,
        "SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }) }
end
binds[#binds + 1] = { "workspace_next", "Workspaces", "Next workspace",     "SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }) }
binds[#binds + 1] = { "workspace_prev", "Workspaces", "Previous workspace", "SUPER + mouse_up",   hl.dsp.focus({ workspace = "e-1" }) }

local media = {
    { "volume_up",       "Volume up",       "XF86AudioRaiseVolume",  "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", true },
    { "volume_down",     "Volume down",     "XF86AudioLowerVolume",  "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-",      true },
    { "mute",            "Mute",            "XF86AudioMute",         "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",     false },
    { "mic_mute",        "Mute microphone", "XF86AudioMicMute",      "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle",   false },
    { "brightness_up",   "Brightness up",   "XF86MonBrightnessUp",   "brightnessctl -e4 -n2 set 5%+",                  true },
    { "brightness_down", "Brightness down", "XF86MonBrightnessDown", "brightnessctl -e4 -n2 set 5%-",                  true },
    { "media_next",      "Next track",      "XF86AudioNext",         "playerctl next",                                 false },
    { "media_play",      "Play / pause",    "XF86AudioPlay",         "playerctl play-pause",                           false },
    { "media_pause",     "Pause",           "XF86AudioPause",        "playerctl play-pause",                           false },
    { "media_prev",      "Previous track",  "XF86AudioPrev",         "playerctl previous",                             false },
}
for _, m in ipairs(media) do
    binds[#binds + 1] = { m[1], "Media", m[2], m[3], exec(m[4]), { locked = true, repeating = m[5] } }
end

local overrides = readConf(cfg .. "keybinds.conf")
local rows = {}
for _, b in ipairs(binds) do
    local id, group, label, default, action, opts = b[1], b[2], b[3], b[4], b[5], b[6]
    local keys = overrides[id] or default
    if keys:lower() == "none" then keys = "" end
    if keys ~= "" then
        -- A typo in keybinds.conf must not stop the rest of the config.
        local function bind(k)
            if opts then hl.bind(k, action, opts) else hl.bind(k, action) end
        end
        if not pcall(bind, keys) and keys ~= default then
            keys = default
            pcall(bind, keys)
        end
    end
    rows[#rows + 1] = table.concat({ id, keys, label, default, group }, "\t")
end

-- Export for hyprd3mon-help and hyprd3mon-settings.
os.execute("mkdir -p '" .. cache .. "'")
local tsv = io.open(cache .. "keybinds.tsv", "w")
if tsv then
    tsv:write(table.concat(rows, "\n"), "\n")
    tsv:close()
end

--------------------------------
---- WINDOWS AND LAYERS ----
--------------------------------

hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Kitty draws its own translucent background; keep its text crisp.
hl.window_rule({
    name    = "kitty-glass",
    match   = { class = "^(kitty)$" },
    opacity = "1.0 override 1.0 override",
})

-- Steam: the client and all its windows (friends, chat, settings...)
-- float. Games (steam_app_*) are left alone and kept fully opaque.
hl.window_rule({
    name  = "steam-float",
    match = { class = "^([Ss]team)$" },
    float = true,
})

hl.window_rule({
    name  = "steam-main-size",
    match = { class = "^([Ss]team)$", title = "^(Steam)$" },
    size   = { "monitor_w * 0.7", "monitor_h * 0.75" },
    center = true,
})

hl.window_rule({
    name  = "steam-friends-size",
    match = { class = "^([Ss]team)$", title = "^(Friends List)$" },
    size  = { "380", "monitor_h * 0.7" },
})

hl.window_rule({
    name    = "games-opaque",
    match   = { class = "^(steam_app_.*)$" },
    opacity = "1.0 override 1.0 override",
    no_blur = true,
})

-- Native games that tag themselves as games stay opaque too.
hl.window_rule({
    name    = "game-content-opaque",
    match   = { content = "game" },
    opacity = "1.0 override 1.0 override",
    no_blur = true,
})

-- Nautilus dialogs and file pickers (browser Save As / upload) float
-- centred instead of tiling.
hl.window_rule({
    name   = "file-dialogs",
    match  = { title = "^(Open File|Open Files|Save File|Save As|Select.*|Choose.*|All Files)(.*)$" },
    float  = true,
    center = true,
    size   = { "monitor_w * 0.55", "monitor_h * 0.6" },
})

hl.window_rule({
    name  = "portal-picker",
    match = { class = "^(xdg-desktop-portal-gtk)$" },
    float = true,
    center = true,
})

-- Pop-up tools opened from the bar (e.g. nmtui for Wi-Fi).
hl.window_rule({
    name   = "hyprd3mon-float",
    match  = { class = "^(hyprd3mon-float)$" },
    float  = true,
    center = true,
    size   = { "760", "520" },
})

hl.window_rule({
    name  = "small-tools",
    match = { class = "^(org.pulseaudio.pavucontrol|nm-connection-editor|hyprland-share-picker)$" },
    float = true,
    center = true,
})

-- Frosted bar, launcher and notifications. ignore_alpha keeps the blur
-- out of their transparent rounded corners.
hl.layer_rule({ name = "glass-waybar",  match = { namespace = "^(waybar)$" },        blur = true, ignore_alpha = 0.1 })
hl.layer_rule({ name = "glass-rofi",    match = { namespace = "^(rofi)$" },          blur = true, ignore_alpha = 0.1 })
hl.layer_rule({ name = "glass-notify",  match = { namespace = "^(notifications)$" }, blur = true, ignore_alpha = 0.1 })

-- Optional personal additions that survive reinstalls.
pcall(require, "local")
