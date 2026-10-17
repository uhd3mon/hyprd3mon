#!/usr/bin/env bash
# hyprd3mon installer: Hyprland + companion apps with the d3mon theme.
# Safe by default: prints the plan (--dry-run) unless --apply is given.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=1
SKIP_STEAM=0
SKIP_PACKAGES=0
SKIP_AUR=0

PACKAGES=(
	hyprland hyprlock hyprpaper hyprshot hyprshutdown hyprpolkitagent
	xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
	kitty waybar rofi mako
	grim slurp wl-clipboard jq libnotify
	ttf-jetbrains-mono-nerd fontconfig
	brightnessctl playerctl pavucontrol network-manager-applet
	nautilus gvfs xdg-utils xdg-user-dirs papirus-icon-theme pciutils
	networkmanager wireplumber hyprpicker
	firefox obs-studio obs-studio-plugin-browser
)

# AUR packages (yay). lib32-obs-vkcapture is added when multilib is on.
AUR_PACKAGES=(obs-vkcapture)

# Files installed only when absent (user-owned after the first install).
KEEP_IF_PRESENT=(
	configs/hypr/monitors.lua
	configs/hyprd3mon/settings.conf
	configs/hyprd3mon/keybinds.conf
)

CONFIG_DIR="$HOME/.config"
BIN_DIR="$HOME/.local/bin"
SHARE_DIR="$HOME/.local/share/hyprd3mon"
FONT_DIR="$HOME/.local/share/fonts/hyprd3mon"
BACKUP_DIR="$HOME/.local/state/hyprd3mon/backup/$(date +%Y%m%d-%H%M%S)"

# Counters and notes for the summary.
N_NEW=0 N_UPDATED=0 N_SAME=0 N_KEPT=0 N_BACKUP=0
FONTS_CHANGED=0
PKG_STATUS="not run"
STEAM_STATUS="not run"
AUR_STATUS="not run"
NOTES=()

usage() {
	cat <<EOF
Usage: $(basename "$0") [--dry-run | --apply] [options]

Installs hyprd3mon (Hyprland, Kitty, Hyprpaper, Hyprlock, Hyprshot,
Waybar, Rofi, Mako, Steam) on Arch Linux.

  --dry-run        Print every action, change nothing (default)
  --apply          Really install packages and files
  --skip-steam     Do not install Steam
  --skip-aur       Do not install AUR packages (obs-vkcapture)
  --skip-packages  Configs only: no pacman or yay at all
                   (implies --skip-steam and --skip-aur)
  -h, --help       Show this help

Files go to ~/.config, ~/.local/bin and ~/.local/share. Changed files
are backed up to ~/.local/state/hyprd3mon/backup/<timestamp>/ first.
EOF
}

say() { printf '%s\n' "$*"; }
step() { printf '\n==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

# Run a command, or only print it in dry-run mode.
run() {
	if ((DRY_RUN)); then
		say "[dry-run] $*"
	else
		say "+ $*"
		"$@"
	fi
}

# ---------------------------------------------------------------- packages

# Prints the lib32 Vulkan driver(s) matching the GPUs found by lspci.
# Matches only GPU lines, case-sensitively for AMD ("ati" alone would
# match "Corporation").
lib32_vulkan_drivers() {
	local gpus
	gpus="$(lspci 2>/dev/null | grep -iE 'vga|3d controller|display controller' || true)"
	if grep -qE '\[AMD/ATI\]|Radeon|AMD' <<<"$gpus"; then
		echo lib32-vulkan-radeon
	fi
	if grep -qi 'intel' <<<"$gpus"; then
		echo lib32-vulkan-intel
	fi
	if grep -qi 'nvidia' <<<"$gpus"; then
		if pacman -Qq nvidia-utils >/dev/null 2>&1; then
			echo lib32-nvidia-utils
		else
			warn "NVIDIA GPU found but nvidia-utils is not installed;" \
				"not adding lib32-nvidia-utils."
		fi
	fi
}

multilib_enabled() {
	grep -qE '^[[:space:]]*\[multilib\]' /etc/pacman.conf
}

# Prints Steam and its lib32 Vulkan driver(s), one per line.
steam_packages() {
	local drivers=()
	if command -v lspci >/dev/null; then
		mapfile -t drivers < <(lib32_vulkan_drivers)
	else
		warn "lspci not found (package pciutils); cannot detect the GPU."
	fi
	if ((${#drivers[@]})); then
		say "GPU Vulkan driver(s): ${drivers[*]}" >&2
	else
		warn "No lib32 Vulkan driver picked; pacman may ask for a provider."
	fi
	printf '%s\n' "${drivers[@]}" steam
}

# One full upgrade + install (no partial upgrades); Steam joins it.
install_packages() {
	step "Packages (official repos, full upgrade)"
	local pkgs=("${PACKAGES[@]}") extra=()
	if ((SKIP_STEAM)); then
		STEAM_STATUS="skipped (--skip-steam)"
	elif multilib_enabled; then
		mapfile -t extra < <(steam_packages)
		pkgs+=("${extra[@]}")
		if ((DRY_RUN)); then STEAM_STATUS="planned"; else STEAM_STATUS="installed"; fi
	else
		say "[multilib] is not enabled in /etc/pacman.conf; skipping Steam."
		say "To enable it, uncomment these two lines in /etc/pacman.conf:"
		say "  [multilib]"
		say "  Include = /etc/pacman.d/mirrorlist"
		say "then re-run this script."
		STEAM_STATUS="skipped (multilib disabled)"
	fi
	run sudo pacman -Syu --needed "${pkgs[@]}"
	if ((DRY_RUN)); then PKG_STATUS="planned"; else PKG_STATUS="installed"; fi
}

# AUR packages via yay (never as root; yay calls sudo itself).
install_aur() {
	step "AUR packages (yay)"
	local pkgs=("${AUR_PACKAGES[@]}")
	multilib_enabled && pkgs+=(lib32-obs-vkcapture)
	if ! command -v yay >/dev/null; then
		say "yay not found; skipping: ${pkgs[*]}"
		say "To get yay:"
		say "  sudo pacman -S --needed git base-devel"
		say "  git clone https://aur.archlinux.org/yay-bin.git"
		say "  cd yay-bin && makepkg -si"
		say "then re-run this script."
		AUR_STATUS="skipped (yay not installed)"
		return 0
	fi
	run yay -S --needed "${pkgs[@]}"
	if ((DRY_RUN)); then AUR_STATUS="planned"; else AUR_STATUS="installed"; fi
}

# ------------------------------------------------------------------- files

is_keep_if_present() {
	local rel="$1" k
	for k in "${KEEP_IF_PRESENT[@]}"; do
		[[ "$rel" == "$k" ]] && return 0
	done
	return 1
}

# Path of a target relative to $HOME, for display and backups.
home_rel() { printf '%s' "${1#"$HOME"/}"; }

# install_file SRC DEST MODE REPO_REL
# Identical -> skip. Different -> back up, then replace. Absent -> copy.
install_file() {
	local src="$1" dest="$2" mode="$3" rel="$4" shown
	shown="~/$(home_rel "$dest")"

	if [[ -e "$dest" || -L "$dest" ]]; then
		if is_keep_if_present "$rel"; then
			say "keep     $shown (user-owned, already present)"
			N_KEPT=$((N_KEPT + 1))
			return 0
		fi
		if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
			say "same     $shown"
			N_SAME=$((N_SAME + 1))
			return 0
		fi
		local backup
		backup="$BACKUP_DIR/$(home_rel "$dest")"
		say "update   $shown (backup -> ~/$(home_rel "$backup"))"
		if ((!DRY_RUN)); then
			mkdir -p "$(dirname "$backup")"
			cp -a -- "$dest" "$backup"
			rm -f -- "$dest"
		fi
		N_BACKUP=$((N_BACKUP + 1))
		N_UPDATED=$((N_UPDATED + 1))
	else
		say "new      $shown"
		N_NEW=$((N_NEW + 1))
	fi
	if ((!DRY_RUN)); then
		install -D -m "$mode" -- "$src" "$dest"
	fi
	return 0
}

# install_tree SRC_DIR DEST_DIR [MODE]
# Walks SRC_DIR file by file. MODE forces a mode; otherwise 755 for
# executable sources and 644 for the rest. Returns 0 if SRC_DIR is absent.
install_tree() {
	local src_dir="$1" dest_dir="$2" force_mode="${3:-}" src rel mode
	[[ -d "$src_dir" ]] || return 0
	while IFS= read -r -d '' src; do
		rel="${src#"$src_dir"/}"
		[[ "$(basename "$rel")" == .gitkeep ]] && continue
		if [[ -n "$force_mode" ]]; then
			mode="$force_mode"
		elif [[ -x "$src" ]]; then
			mode=755
		else
			mode=644
		fi
		install_file "$src" "$dest_dir/$rel" "$mode" \
			"${src#"$SCRIPT_DIR"/}"
	done < <(find "$src_dir" -type f -print0 | sort -z)
}

install_files() {
	step "Configs -> ~/.config"
	install_tree "$SCRIPT_DIR/configs" "$CONFIG_DIR"

	step "Commands -> ~/.local/bin"
	install_tree "$SCRIPT_DIR/bin" "$BIN_DIR" 755

	step "Wallpapers, themes and avatar -> ~/.local/share/hyprd3mon"
	install_tree "$SCRIPT_DIR/assets/wallpapers" "$SHARE_DIR/wallpapers" 644
	install_tree "$SCRIPT_DIR/assets/themes" "$SHARE_DIR/themes" 644
	if [[ -f "$SCRIPT_DIR/assets/avatar.png" ]]; then
		install_file "$SCRIPT_DIR/assets/avatar.png" "$SHARE_DIR/avatar.png" \
			644 assets/avatar.png
	fi

	step "Fonts -> ~/.local/share/fonts/hyprd3mon"
	local before=$((N_NEW + N_UPDATED))
	install_tree "$SCRIPT_DIR/assets/fonts" "$FONT_DIR" 644
	if ((N_NEW + N_UPDATED > before)); then FONTS_CHANGED=1; fi
	if ((FONTS_CHANGED)); then
		if ((DRY_RUN)) || command -v fc-cache >/dev/null; then
			run fc-cache -f "$FONT_DIR"
		else
			warn "fc-cache not found (package fontconfig); font cache not refreshed."
		fi
	else
		say "fonts unchanged; fc-cache not needed"
	fi

	if [[ -f "$CONFIG_DIR/hypr/hyprland.conf" ]]; then
		NOTES+=("~/.config/hypr/hyprland.conf (older setup) is left in place; Hyprland 0.56 loads hyprland.lua, so it is ignored.")
	fi
	if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
		NOTES+=("~/.local/bin is not in PATH; the configs call the commands by full path, so this only matters in your own shell.")
	fi
	if [[ -f "$CONFIG_DIR/waybar/config" ]]; then
		warn "~/.config/waybar/config exists; hyprd3mon starts waybar with -c config.jsonc, so it is ignored."
		NOTES+=("~/.config/waybar/config (older setup) is ignored; waybar is started with -c ~/.config/waybar/config.jsonc.")
	fi

	# Also links wallpapers/current.png and sets the GTK colour scheme,
	# theme and icons (gsettings) from the theme in settings.conf.
	step "Generated settings -> ~/.config/hyprd3mon/generated"
	if ! run "$BIN_DIR/hyprd3mon-apply-settings" --no-reload; then
		warn "hyprd3mon-apply-settings failed; run it again after fixing the error above."
		NOTES+=("Generated settings were not written (hyprd3mon-apply-settings failed).")
	fi
}

# ----------------------------------------------------------- desktop prefs

desktop_settings() {
	step "Desktop settings"
	if ((DRY_RUN)) || command -v xdg-mime >/dev/null; then
		# xdg-mime merges into ~/.config/mimeapps.list; never write it directly.
		run xdg-mime default org.gnome.Nautilus.desktop inode/directory
	else
		warn "xdg-mime not found (package xdg-utils); file manager default not set."
	fi
	# GTK colour scheme, theme and icons follow the theme palette; they are
	# set by hyprd3mon-apply-settings (step above), not here.
}

# ----------------------------------------------------------------- summary

summary() {
	local mode=applied
	((DRY_RUN)) && mode="dry run (nothing changed)"
	step "Summary: $mode"
	say "Packages: $PKG_STATUS"
	say "Steam:    $STEAM_STATUS"
	say "AUR:      $AUR_STATUS"
	say "Files:    $N_NEW new, $N_UPDATED updated, $N_SAME unchanged," \
		"$N_KEPT kept (user-owned)"
	if ((N_BACKUP)); then
		say "Backups:  $N_BACKUP file(s) in ~/$(home_rel "$BACKUP_DIR")"
	else
		say "Backups:  none needed"
	fi
	local note
	for note in "${NOTES[@]}"; do say "Note:     $note"; done
	if ((DRY_RUN)); then
		say ""
		say "Re-run with --apply to install."
	else
		say ""
		say "Done. Log out and pick Hyprland in the login screen."
	fi
}

main() {
	while (($#)); do
		case "$1" in
		--dry-run) DRY_RUN=1 ;;
		--apply) DRY_RUN=0 ;;
		--skip-steam) SKIP_STEAM=1 ;;
		--skip-aur) SKIP_AUR=1 ;;
		--skip-packages) SKIP_PACKAGES=1 ;;
		-h | --help) usage; return 0 ;;
		*) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; return 2 ;;
		esac
		shift
	done

	((EUID != 0)) || die "do not run as root; run as your user (sudo is used for pacman)."
	command -v pacman >/dev/null || die "pacman not found; this installer is for Arch Linux."
	[[ -n "${HOME:-}" && -d "$HOME" ]] || die "HOME is not set to a directory."

	say "hyprd3mon installer"
	say "Repo: $SCRIPT_DIR"
	((DRY_RUN)) && say "Mode: dry run (use --apply to make changes)"

	if ((SKIP_PACKAGES)); then
		PKG_STATUS="skipped (--skip-packages)"
		STEAM_STATUS="skipped (--skip-packages)"
		AUR_STATUS="skipped (--skip-packages)"
	else
		install_packages
		if ((SKIP_AUR)); then
			AUR_STATUS="skipped (--skip-aur)"
		else
			install_aur
		fi
	fi

	install_files
	desktop_settings
	summary
}

main "$@"
