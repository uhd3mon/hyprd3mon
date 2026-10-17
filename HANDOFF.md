# HANDOFF

## Goal

A Bash script that sets up Hyprland on Arch with companion
apps (Hyprshot, Hyprlock, more) carrying this project's
modifications. See AGENTS.md for rules.

## Current state (2026-10-17)

- Project scaffolded from an empty folder: README.md,
  AGENTS.md, CLAUDE.md, HANDOFF.md, .gitignore, install.sh,
  configs/ and patches/ (empty, with .gitkeep).
- install.sh is a skeleton: `--dry-run` (default) prints the
  package steps; `--apply` exits 1 "not implemented".
- Local git repo initialised; no remote.

## Next steps

1. Kevin to list the full app set and what each
   modification is (Hyprshot, Hyprlock, others).
2. Add configs per app under `configs/<app>/`.
3. Implement `--apply`: packages, backup + copy configs,
   apply patches; keep it idempotent.
4. Install shellcheck; test in a VM before a real run.

## Decisions

- Arch only (pacman + yay; both present on this machine).
- Dry-run is the default; real changes need `--apply`.
- Modifications live as files, not inline script edits.

## Lessons / observations

- Hyprland, hyprlock, hyprshot and shellcheck are not
  installed here, but `~/.config/hypr/` holds an older
  config (hyprland.conf, hyprpaper.conf, config/*.conf).
  Not imported; ask Kevin before using it as a base.

## Verification observed (2026-10-17)

- `bash -n install.sh`: OK.
- `./install.sh`: printed plan, exit 0.
- `./install.sh --apply`: exit 1 (not implemented).
- `./install.sh --bogus`: usage, exit 2.
