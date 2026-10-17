-- hyprd3mon monitor layout. This file is yours: install.sh only copies
-- it when it's missing. Set it with `hyprd3mon-monitors` (lists screens,
-- writes the two names below) or edit by hand, then save: Hyprland
-- reloads on its own.
--
-- main  = the screen in front of you (bar, first workspaces)
-- above = a second screen stacked directly above it
-- Leave both nil on a laptop or single screen.

local main  = nil   -- e.g. "DP-1"
local above = nil   -- e.g. "DP-2"

if main and above then
    hl.monitor({ output = main,  mode = "preferred", position = "0x0",            scale = "auto" })
    hl.monitor({ output = above, mode = "preferred", position = "auto-center-up", scale = "auto" })

    -- Workspaces 1-5 open on the main screen, 6-10 on the one above.
    for i = 1, 10 do
        hl.workspace_rule({ workspace = tostring(i), monitor = i <= 5 and main or above, default = i == 1 or i == 6 })
    end
end

-- Any other screen (a laptop panel, a TV) is placed automatically.
hl.monitor({ output = "", mode = "preferred", position = "auto-center-up", scale = "auto" })
