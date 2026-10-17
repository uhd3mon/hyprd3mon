# HANDOFF

## Goal

hyprd3mon: one Bash script that turns an Arch install into a
lightweight Hyprland desktop in the d3mon theme (frosted glass, dark
or light), with Kitty, Hyprpaper, Hyprlock, Hyprshot, Waybar, Rofi,
Mako, Nautilus, Firefox, OBS and Steam. See AGENTS.md for rules.
Public GitHub repo: https://github.com/uhd3mon/hyprd3mon (branch main).

## Current state (2026-10-17)

Built and tested off-line. Not yet run for real: Hyprland isn't
installed on this machine, and the first real `--apply` is Kevin's
call (his laptop: KDE Plasma + Plasma Login Manager, AMD GPUs).

- `install.sh`: dry-run by default; `--apply`, `--skip-steam`,
  `--skip-aur`, `--skip-packages`. One `sudo pacman -Syu --needed`
  (Steam + lib32 Vulkan driver by GPU when multilib is on), then
  `yay` for obs-vkcapture (+ lib32). It copies configs/bin/assets
  (cmp skip, timestamped backups in
  ~/.local/state/hyprd3mon/backup/), never overwrites
  monitors.lua/settings.conf/keybinds.conf, sets Nautilus as the
  folder handler via xdg-mime, then runs
  `hyprd3mon-apply-settings --no-reload`.
- `configs/hypr/hyprland.lua` (Hyprland 0.56 Lua API): glass
  decoration, blur on waybar/rofi/notifications layers, Steam
  windows float (games opaque), file dialogs float. Keybinds are a
  table: defaults + `~/.config/hyprd3mon/keybinds.conf` overrides
  (`none` unbinds), exported to `~/.cache/hyprd3mon/keybinds.tsv`
  for the help and settings menus. Accent + inactive border come
  from settings.conf + the theme palette.
- Monitors: `monitors.lua` (user-owned). Default stacks each extra
  screen above the last (`auto-center-up`); `hyprd3mon-monitors
  MAIN ABOVE` pins Kevin's two DisplayPort screens (1-5 on main,
  6-10 above). Laptop/single screen needs nothing. Scale is 1
  by default; `hyprd3mon-monitors scale N` or Settings -> Monitors
  -> Scale rewrites every `scale = "..."` in monitors.lua and runs
  `hyprctl reload`.
- Theme system: `assets/themes/{dark,light}.conf` palettes ->
  `hyprd3mon-apply-settings` -> `~/.config/hyprd3mon/generated/`
  (theme.css, theme.rasi, hyprlock-theme.conf, kitty-theme.conf,
  mako-theme, waybar-modules.jsonc) + wallpapers/current.png
  symlink + gsettings. Runs at every Hyprland login too.
- Bar (Waybar): full width, flush top. Username (opens launcher),
  taskbar | clock + date | network, sound, help, settings, tray,
  power. Module toggles + 12/24h clock from settings.
- Commands in `bin/`: launcher, power (lock/logout/restart/
  shutdown), shot (window/region/monitor/all; always saved to
  ~/Pictures/Screenshots and copied as image/png), help (keybind
  list), settings (theme, accent, keybinds, bar, monitors),
  apply-settings, monitors.
- Wallpapers: Codec grid, `grid-dark.png` (#070707, white 3.5/6.5%)
  and `grid-light.png` (#f2f3ef, black 4/7%), 48/240 px grid at 2x,
  no centre axes (Kevin asked to drop them).
- Mocks in docs/preview/ are HTML renders, not real screenshots
  (re-rendered with the real wallpapers and keybind TSV).

## Next steps

1. Kevin: `git clone` + `./install.sh` (dry run), then
   `./install.sh --apply` on the laptop; log in to Hyprland.
2. On first login check: hyprctl's config errors banner, blur on bar
   and launcher, hyprlock (SUPER+L), screenshots + paste, Nautilus
   "Save as" from Firefox, Steam floating, theme switch.
3. On the host PC run `hyprd3mon-monitors` then
   `hyprd3mon-monitors <main> <above>`.
4. Replace the mocks in README with real screenshots.
5. Install shellcheck and run it on install.sh and bin/*.

## Decisions

- Hyprland 0.56 config is Lua (`hyprland.lua` wins over the old
  `hyprland.conf`, which is left in place). Hyprlock/hyprpaper
  stay hyprlang.
- Everything from official repos except obs-vkcapture (AUR).
- Display manager untouched: Plasma Login Manager lists the
  Hyprland session; hyprlock is the lock screen.
- Rofi 2.0 (native Wayland) for launcher/menus; Papirus icons.
- Hyprshot has no all-monitors mode: `shot all` uses grim.
- The repo is public, at Kevin's explicit request (his first line
  said private, his last said "make sure the github is public").

## Lessons

- Hyprland `require()` resolves next to hyprland.lua; a missing
  module is catchable with pcall (no error banner).
- `#` comments: only at line start or after whitespace, or
  `accent=#91e611` gets eaten (found in testing).
- Empty XDG_CONFIG_HOME/XDG_CACHE_HOME must fall back to defaults.
- rofi 2.0 rejects a theme with alpha written `.72`; use `0.72`.
- GTK3 CSS `@import` and mako `include=` are not optional:
  apply-settings must run before waybar/mako (install does it).
- Test file installs with `GSETTINGS_BACKEND=memory HOME=$(mktemp -d)`.
- Waybar prefers `~/.config/waybar/config` over config.jsonc, so
  hyprland.lua starts it with `-c`.
- Strip trailing comments from the value, not the line, or
  `accent = #22d3ee` (spaces around =) is lost (Nova found it).
- Keybind overrides are bound inside pcall and fall back to the
  default, so a typo can't stop the rest of the config loading.
- The GitHub account is `uhd3mon`; the git author name
  `KevinEightSeven` is not a GitHub login.
- Kevin's first real login (laptop, 2026-10-17): everything was
  far too big. Cause: `scale = "auto"` on every monitor line;
  Hyprland's auto picks a large scale on laptop panels. Default is
  now "1". monitors.lua is user-owned, so existing installs keep
  "auto" until `hyprd3mon-monitors scale 1` is run.
- Network: no nm-applet; the bar's network icon opens nmtui in a
  floating kitty (class hyprd3mon-float), right-click opens
  nm-connection-editor.

## Verification observed (2026-10-17)

- Scale fix: `hyprd3mon-monitors scale 1.25` on the old (auto)
  monitors.lua changed all 3 lines; `1.3x` rejected (exit 2);
  stubbed-rofi Settings -> Monitors -> Scale -> 1.5 wrote 1.5 to
  all 3 lines; Single screen entry still works. Not yet seen on
  real Hyprland.

- `bash -n install.sh bin/*`, `luac -p configs/hypr/*.lua`: OK.
- `./install.sh` dry run: exit 0; plan lists `pacman -Syu` (with
  lib32-vulkan-radeon steam), yay obs-vkcapture, all files.
- Fake HOME `--apply --skip-packages`: 29 new; rerun 26 unchanged,
  3 kept, no backups; current.png -> grid-dark.png; 6 generated
  files.
- apply-settings with theme=light: current.png -> grid-light.png,
  gsettings prefer-light/Papirus-Light, hyprlock `$*_hex` vars.
- hyprland.lua run in Lua 5.4 with a stub `hl`: 60 binds; override
  `launcher = SUPER + D` applied, `help = none` unbound; TSV has
  id/keys/label/default/group; border accent dark rgba(91e611ee),
  light rgba(4f8f00ee).
- Teammates (reports): rofi 2.0 `-dump-theme` OK on all themes;
  GTK3 parses style.css; kitty 0.48 loads kitty.conf; hyprlang
  parses hyprlock colours; settings/help menus with stubbed rofi.
- Not run: real Hyprland session, real package install,
  multilib-off path, root refusal, shellcheck.

## Team memory

<!-- workspace:memory:start -->
- hyprland project layout (2026-10-17): /home/kevin/Workspace/hyprland, local git (fe1ed45, no remote). install.sh = Bash entry, dry-run default, --apply not implemented; configs/<app>/ -> ~/.config/<app>/; patches/<app>/ = mods to upstream apps (Hyprshot, Hyprlock...). Guides: README, AGENTS.md (rules+checks), CLAUDE.md=@AGENTS.md, HANDOFF.md. Checks: bash -n install.sh; ./install.sh --dry-run. Arch (pacman+yay). Hyprland/shellcheck not installed; old config in ~/.config/hypr not imported. (Sora, 2026-10-17)
- hyprd3mon published 2026-10-17: PUBLIC repo https://github.com/uhd3mon/hyprd3mon (branch main, commit a5a74f8; local folder /home/kevin/Workspace/hyprland). Kevin's GitHub login is uhd3mon (git author name KevinEightSeven is not a login). Full installer built (Hyprland 0.56 Lua config, waybar/rofi/mako/kitty/hyprlock, Hyprshot keys, settings + dark/light themes, Firefox/OBS/obs-vkcapture(AUR)/Steam). Tested only offline (fake HOME, Lua stub); first real --apply + Hyprland login still to do on Kevin's laptop. Older note saying "--apply not implemented, no remote" is stale. (Sora, 2026-10-17)
<!-- workspace:memory:end -->
