# hyprland

A custom setup script for [Hyprland](https://hyprland.org) on Arch Linux.
It installs Hyprland plus a few companion apps (Hyprshot, Hyprlock and
more) and applies this project's modified configs/patches to them.

## Status

Early scaffold. `install.sh` is a skeleton: it parses options and prints
its plan, but installs nothing yet. See [HANDOFF.md](HANDOFF.md).

## Usage

```sh
./install.sh --dry-run   # show what would happen (default)
./install.sh --help
```

## Layout

- `install.sh` — entry point
- `configs/` — config files copied into `~/.config`, one folder per app
- `patches/` — modifications applied to upstream apps/scripts

Contributors and agents: read [AGENTS.md](AGENTS.md) first.
