# AGENTS.md

Read this file, README.md and HANDOFF.md before any work.
After lasting changes, update HANDOFF.md (state, next steps,
decisions, lessons, checks you actually observed).

## Goal

One script that sets up Hyprland on Arch Linux with a few
companion apps (Hyprshot, Hyprlock, more to come), each with
this project's modifications applied.

## Constraints

- Target: Arch Linux (pacman; AUR via yay). Bash only.
- Safe by default: `install.sh` must not change the system
  without an explicit flag; `--dry-run` is the default.
- Idempotent: re-running must not duplicate or clobber work.
- Back up any existing file in `~/.config` before replacing it.
- Never run the real install, `sudo`, or package installs on
  Kevin's machine without his OK.
- Keep modifications as files in `configs/` or `patches/`,
  not inline edits buried in the script.
- No credentials, tokens or personal notes in the repo.

## Layout

- `install.sh` — entry point (options, plan, steps)
- `configs/<app>/` — installed into `~/.config/<app>/`
  (hypr, kitty, waybar, rofi, mako, xdg-desktop-portal)
- `configs/hypr/monitors.lua`, `configs/hyprd3mon/settings.conf`,
  `configs/hyprd3mon/keybinds.conf` — user-owned: installed only
  if absent
- `bin/` — `hyprd3mon-*` commands -> `~/.local/bin/`
  (`hyprd3mon-apply-settings` turns settings + `assets/themes/`
  palettes into `~/.config/hyprd3mon/generated/*`, which waybar,
  rofi, kitty, mako and hyprlock include)
- `assets/wallpapers/`, `assets/themes/`, `assets/avatar.png`
  -> `~/.local/share/hyprd3mon/`
- `assets/fonts/` -> `~/.local/share/fonts/hyprd3mon/`
- `patches/<app>/` — patches for upstream apps (none needed yet;
  Hyprshot is wrapped by `bin/hyprd3mon-shot` instead)
- `docs/preview/` — design mocks
- `README.md` — user-facing overview
- `HANDOFF.md` — current status and history
- `CLAUDE.md` — points here

Hyprland is 0.56: its config is Lua (`hyprland.lua`, `hl.*` API).
Hyprlock and hyprpaper still use hyprlang `.conf` files.

## Checks (verified 2026-10-17)

```sh
bash -n install.sh bin/*                 # syntax check
luac -p configs/hypr/*.lua               # Lua syntax
./install.sh --dry-run                   # prints plan, changes nothing
# real file install into a throwaway HOME:
GSETTINGS_BACKEND=memory HOME=$(mktemp -d) ./install.sh --apply --skip-packages
```

Use `GSETTINGS_BACKEND=memory` with a fake HOME, or gsettings
changes the real user's settings.

`shellcheck` is not installed on this machine yet; run
`shellcheck install.sh` once it is. Hyprland itself is not
installed here, so runtime testing needs a VM or Kevin's OK.
