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
- `configs/<app>/` — configs to install into `~/.config/<app>/`
- `patches/<app>/` — patches/overrides for upstream apps
- `README.md` — user-facing overview
- `HANDOFF.md` — current status and history
- `CLAUDE.md` — points here

## Checks (verified 2026-10-17)

```sh
bash -n install.sh        # syntax check
./install.sh --dry-run    # prints plan, changes nothing
```

`shellcheck` is not installed on this machine yet; run
`shellcheck install.sh` once it is. Hyprland itself is not
installed here, so runtime testing needs a VM or Kevin's OK.
