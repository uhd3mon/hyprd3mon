#!/usr/bin/env bash
# Hyprland setup script. Safe by default: --dry-run unless --apply is given.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=1

PACMAN_PKGS=(hyprland hyprlock)
AUR_PKGS=(hyprshot)

usage() {
	cat <<EOF
Usage: $(basename "$0") [--dry-run | --apply] [--help]

  --dry-run  Print the plan without changing anything (default)
  --apply    Not implemented yet
  --help     Show this help
EOF
}

run() {
	if ((DRY_RUN)); then
		echo "[dry-run] $*"
	else
		"$@"
	fi
}

main() {
	while (($#)); do
		case "$1" in
		--dry-run) DRY_RUN=1 ;;
		--apply) DRY_RUN=0 ;;
		-h | --help) usage; return 0 ;;
		*) echo "Unknown option: $1" >&2; usage >&2; return 2 ;;
		esac
		shift
	done

	if ((!DRY_RUN)); then
		echo "--apply is not implemented yet." >&2
		return 1
	fi

	echo "Project: $SCRIPT_DIR"
	run sudo pacman -S --needed "${PACMAN_PKGS[@]}"
	run yay -S --needed "${AUR_PKGS[@]}"
	echo "TODO: install configs/ and apply patches/"
}

main "$@"
