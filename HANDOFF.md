# HANDOFF

## Goal

hyprd3mon: one Bash script that turns an Arch install into a
lightweight Hyprland desktop in the d3mon theme (frosted glass, dark
or light), with Kitty, Hyprpaper, Hyprlock, Hyprshot, Waybar, Rofi,
Mako, Nautilus, Firefox, OBS and Steam. See AGENTS.md for rules.
GitHub: https://github.com/uhd3mon/hyprd3mon (public, re-created
2026-10-18 at Kevin's request; remote `origin`, only `main` pushed).
Local folder: /home/kevin/Workspace/hyprd3mon.

## Resumed (2026-10-18)

- 2026-10-17 the project briefly became d3mon-kde (KDE theme). On
  2026-10-18 Kevin moved back to hyprd3mon. History restored from
  `~/.local/share/hyprd3mon-archive/hyprd3mon.bundle` (kept).
- Branches: `main` = hyprd3mon; `wip-vpn` = the cancelled VPN
  work (a stash commit; apply with `git stash apply wip-vpn`);
  `d3mon-kde` = the KDE project, remote `d3mon-kde`
  (github.com/uhd3mon/d3mon-kde, still public). Never push
  `wip-vpn` or `d3mon-kde` to `origin`.
- History rewritten without AI co-author lines (Kevin's rule);
  commits carry only his name and no attribution trailers. The
  bundle has the originals.

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
- `configs/hypr/hyprland.lua` (Hyprland 0.56 Lua API): focused
  window solid (1.0), unfocused windows frosted (0.55 + blur size
  5, noise 0.04), blur on waybar/rofi/notifications layers, Steam
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
  power. Module toggles + 12/24h clock from settings. Background =
  palette `bar_glass` (45% alpha; falls back to `glass`), thinner
  than menus so the blur shows.
- Commands in `bin/`: launcher, network (rofi Wi-Fi/VPN menu),
  power (lock/logout/restart/shutdown), shot (window/region/monitor/all; always saved to
  ~/Pictures/Screenshots and copied as image/png), help (keybind
  list), settings (theme, accent, keybinds, bar, monitors),
  apply-settings, monitors.
- Wallpapers: Codec grid, `grid-dark.png` (#070707, white 3.5/6.5%)
  and `grid-light.png` (#f2f3ef, black 4/7%), 48/240 px grid at 2x,
  no centre axes (Kevin asked to drop them).
- Mocks in docs/preview/ are HTML renders, not real screenshots
  (re-rendered with the real wallpapers and keybind TSV).

## Next steps

0. When Kevin says it's ready: `gh repo create uhd3mon/hyprd3mon`
   and push `main` (his OK first). Decide on `wip-vpn` (VPN
   section beside the network module, request #6).
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

- Frosted glass (Kevin, 2026-10-18: "bar blurred, unfocused
  windows frosted"): focused window opaque, every unfocused window
  0.55 + light blur (size 5). Kevin picked this stronger frost
  from a browser mock on 2026-10-18 (0.78 + size 10 hid everything
  behind the window). Kitty no longer has its own background_opacity or
  an opacity override; it follows the same rule (unfocused text
  fades with the window). To make focused windows glassy too, set
  `active_opacity` below 1.0.

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

- Blur was already on (layer rules + decoration), but over the
  near-black grid wallpaper a 78%-opaque bar and 92%/85% windows
  showed almost nothing. Frost needs lower alpha and blur grain
  (noise); a busier wallpaper would show it more.

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
- Network: no nm-applet. Kevin found nmtui (terminal) "horrible",
  so the bar's network icon now opens `hyprd3mon-network`, a rofi
  menu in the same glass style (Wi-Fi on/off, networks with
  signal/lock/connected marks, password prompt, disconnect/forget,
  hidden network, VPN/WireGuard on/off, Advanced settings).
  Right-click still opens nm-connection-editor; 802.1X networks are
  sent there too.
- Keybind lists (help + Settings -> Keybinds) were cut off on the
  laptop ("SUPER …"): rows were padded to 64 chars for a 640px
  window, which overflowed. Now keys come first, padded to the
  longest combo, then the label; window 760px. If rofi still cuts a
  row, it cuts the label, not the keys.
- `IFS=$'\t' read` merges empty fields: Settings -> Keybinds showed
  an unbound key's default as its label and listed the TSV header as
  a bind. It now splits on \x1f like the help menu.
- The new network menu passes a new Wi-Fi password to
  `nmcli dev wifi connect ... password X`, so it is briefly visible
  in /proc/*/cmdline (same as most rofi Wi-Fi menus). Accepted for
  a single-user desktop; `nmcli --ask` via stdin or `passwd-file`
  would hide it but couldn't be tested without joining a network.

## Verification observed (2026-10-18, stronger frost)

- inactive_opacity 0.78 -> 0.55, blur size 10 -> 5 (matches the
  mock Kevin chose). `luac -p configs/hypr/*.lua`,
  `bash -n install.sh bin/*` OK; dry run exit 0. Not seen in real
  Hyprland.

## Verification observed (2026-10-18, frosted glass)

- `bash -n install.sh bin/*`, `luac -p configs/hypr/*.lua`: OK;
  dry run exit 0. Fake HOME `--apply --skip-packages`: exit 0;
  theme.css has `bar_glass rgba(22,22,25,0.45)` (dark) and
  `rgba(250,250,247,0.45)` (light); with bar_glass deleted from the
  installed palettes it falls back to glass (0.72). kitty.conf
  `background_opacity 1.0`. GTK3 CssProvider parses the installed
  waybar style.css with no errors. hyprland.lua under a Lua stub:
  active 1.0, inactive 0.78, noise 0.04, no kitty-glass rule,
  3 blur layer rules. Not seen in real Hyprland.

## Verification observed (2026-10-17)

- Network menu + keybind lists (stubbed rofi/nmcli, nothing changed
  on the real network): real `nmcli` read-only parse on this PC
  (Dungeon5G WPA2, 2 VPNs, "Wired: Wired connection 1"); stubs:
  new secured network -> password -> `dev wifi connect`, failed
  connect deletes the half-made profile, saved `Caf:e` reconnects via
  `con up`, wrong saved password re-asks + `con modify`, OWE and
  open networks skip the password, hidden network adds `hidden yes`
  (empty password = open), Forget deletes every profile for the SSID,
  802.1X opens the editor, VPN up, Wi-Fi off, cancel exits 0.
  Help + Settings -> Keybinds rows now "keys   label"; unbound shows
  "unbound"; setting a key from that page wrote keybinds.conf.
  Fake HOME install placed ~/.local/bin/hyprd3mon-network; dry run
  exit 0. Nova reviewed the network menu; all findings fixed except
  the password-in-argv one (see Lessons). Not seen on real
  Hyprland/rofi yet.

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
- hyprd3mon 2026-10-17 (commit 8c6daf1, pushed): bar network click = bin/hyprd3mon-network (rofi Wi-Fi/VPN menu; Kevin rejected nmtui as "horrible"); right-click = nm-connection-editor. Keybind help/settings lists are keys-first at 760px (were cut off). Kevin runs it live on 1920px screens now. uploads/ (chat screenshots) is gitignored. (Sora, 2026-10-17)
- d3mon-kde theme assets (Strata, 2026-10-17): theme/icons/d3mon (places/scalable 64 folders 32-512 px + places/symbolic 16-31 px line icons using ColorScheme-Text, aliases = symlinks, inherits breeze-dark), theme/aurorae/d3mon + d3mon-light (Aurorae v2 needs metadata.desktop or the theme is skipped; rc = <theme>rc; padding 14 holds the SVG shadow), theme/wallpapers/d3mon-grid (images/ light, images_dark/ dark, 5 sizes). Generated by scripts in /tmp/strata-gen (icons.py, aurorae.py, wall.sh, preview-*.sh) — not yet in the repo; suggest tools/. assets/wallpapers removed. Not yet seen in a real Plasma session. (Strata, 2026-10-17)
- d3mon-kde (2026-10-17, Atlas): install.sh rewritten for KDE: flags --apply --theme dark|light --layout --skip-theme/-packages/-steam/-aur --remove-hyprd3mon; packages in packages/{pacman,aur}.txt. Live plasma-apply-lookandfeel only when HOME == passwd home + plasmashell running + D3MON_NO_LIVE!=1; otherwise kwriteconfig6 into $HOME/.config (safe for fake-HOME tests). Theme files: color-schemes, konsole (2 schemes + d3mon.profile/d3mon-light.profile), look-and-feel org.d3mon.dark/light (+layout JS), configs/kitty (auto light/dark files), configs/mpv. Tested only in fake HOMEs; real apply not run. (Atlas, 2026-10-17)
- d3mon-kde icons (Strata, 2026-10-17): theme generators now live in tools/gen/ (icons.py writes both theme/icons/d3mon + d3mon-light by default; aurorae.py ROOT, tasks.py > widgets/tasks.svg, wall.sh, preview-*.sh). d3mon-light has its own places/scalable (body #cfd2ca, back/tab #a9ada4, glyph #3a3d37, strip #4f8f00); places/symbolic is a symlink to d3mon's. Dark icons regenerate byte-identical. Verified in nested light/dark screenshots. (Strata, 2026-10-17)
- d3mon-kde colours (Atlas, 2026-10-17): dark window/header #141416, view #0f0f11, button #1c1c1f (wallpaper #070707). Selection: ChangeSelectionColor=false + explicit [Colors:Selection][Inactive] (dark #2c3322, light #dfeccf); light active selection #c8e2a0 with dark ink. KDE otherwise tints unfocused selection 40% toward accent (olive/lime). Breeze focus/checkbox = DecorationFocus; QPalette::Accent (progress bars) = Selection bg. tools/screenshot.sh pre-writes user-places.xbel (owner http://www.kde.org, GroupState-Devices/RemovableDevices-IsHidden=true, one Home bookmark so KIO keeps the flags). Aurorae bg in tools/gen/aurorae.py still #0d0d0e, should become #141416. (Atlas, 2026-10-17)
- 2026-10-17: project pivoted from Hyprland to d3mon-kde (KDE Plasma 6 app restore + d3mon theme). New public repo https://github.com/uhd3mon/d3mon-kde (fresh history, commit c5008c6, release v0.1.0 with Install-from-File packages from tools/package.sh). Old hyprd3mon history saved at ~/.local/share/hyprd3mon-archive/hyprd3mon.bundle; old GitHub repo uhd3mon/hyprd3mon NOT yet deleted (gh token lacks delete_repo; Kevin must run gh auth refresh -h github.com -s delete_repo, then gh repo delete). Notes above about hyprd3mon/Hyprland are history. Visual testing: tools/screenshot.sh (nested KWin, fake HOME) — safe, real Plasma screenshots. (Sora, 2026-10-17)
- d3mon-kde window buttons (Strata, 2026-10-17): Kevin dropped the mac-style round dots. tools/gen/aurorae.py now draws flat 32x24 cells with line glyphs (1.4 px strokes on .5 px coordinates, title text colour, inactive = dim text, deactivated 35%), a rounded hover fill (dark #26272b, light #dcddd8), a stronger pressed fill and a red close hover (#e5534b dark / #e0483f light) with a white X. rc: TitleEdgeTop/Bottom 3, TitleHeight 24, ButtonSpacing 0, TitleEdgeLeft/Right 6. aurorae.py now also writes metadata.json. tools/gen/preview-deco.sh reads the layout from the rc and renders strips at 1x, 1.25x and 1.5x (run it with bash; it isn't executable). Seen in nested Plasma dark + light. (Strata, 2026-10-17)
- d3mon-kde 2026-10-17 (commit 788366e, pushed): install.sh split into apps.sh (packages, sudo) + theme.sh (all theme files + kitty/mpv configs, per user) + lib/common.sh; install.sh only chains them. Hyprland removal (--remove-hyprland/--remove-hyprd3mon) deleted. Aurorae v2.0 = flat line min/max/close buttons, red close hover (no round dots). History rewritten without Claude co-author lines; release v0.1.0 deleted, v0.2.0 published. Older notes about --remove-hyprland, round buttons and v0.1.0 are stale. (Sora, 2026-10-17)
- d3mon-kde 2026-10-17 (commit 8540aba, pushed): layout JS (--layout) is now ONE top bar: kickoff, icontasks with pinned apps (fill=false), spacer, centred clock, spacer, systray. Dock and app menu (File/Edit global menu) removed at Kevin's request. Older notes about "top bar + dock" are stale. (Sora, 2026-10-17)
- 2026-10-18: back to hyprd3mon. Folder renamed to /home/kevin/Workspace/hyprd3mon, Workspace project renamed hyprd3mon. GitHub uhd3mon/hyprd3mon was deleted by Kevin; re-create + push only when he says it's ready. Local git: main = hyprd3mon (restored from ~/.local/share/hyprd3mon-archive/hyprd3mon.bundle, history rewritten without Claude co-author lines, head 7e19f2e), wip-vpn = cancelled VPN stash commit, d3mon-kde = the KDE project branch (remote named d3mon-kde, no origin). Notes about d3mon-kde being this folder's project are stale. (Sora, 2026-10-18)
- hyprd3mon 2026-10-18 (commit 332c4ce, local, no remote): frosted glass = focused window opaque 1.0, unfocused 0.78 + blur (size 10, noise 0.04, brightness 0.9); waybar bg = new palette key bar_glass (45% alpha, apply-settings falls back to glass); kitty background_opacity 1.0 and kitty-glass override rule removed. Not yet seen in real Hyprland. (Sora, 2026-10-18)
- hyprd3mon 2026-10-18 (commit a8632f1, local): Kevin chose the stronger frost from the mock: unfocused windows inactive_opacity 0.55, blur size 5 (noise 0.04, brightness 0.9 unchanged). Older note saying 0.78 / size 10 is stale. Not yet seen in real Hyprland. (Sora, 2026-10-18)
- hyprd3mon re-published 2026-10-18: PUBLIC https://github.com/uhd3mon/hyprd3mon, remote origin, only main pushed (head 79d2dc5, 12 commits, all KevinEightSeven, no Claude trailers; contributors = uhd3mon). Never push wip-vpn or d3mon-kde branches to origin. Older notes saying "no remote / repo deleted" are stale. (Sora, 2026-10-18)
<!-- workspace:memory:end -->
