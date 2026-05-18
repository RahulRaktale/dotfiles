#!/usr/bin/env bash
# uninstall.sh - reverse what install.sh did to $HOME
#
# Removes the symlinks this dotfiles repo created and, if a most-recent
# backup directory exists at ~/.dotfiles-backup/<timestamp>/, offers to
# restore the files it contains.
#
# This script does NOT uninstall any packages -- removing brew formulae or
# apt packages is out of scope and easy to do manually if you want.
#
# Usage:
#   ./uninstall.sh
#   ./uninstall.sh --yes
#   ./uninstall.sh --dry-run

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"

# shellcheck source=lib/common.sh
source "$DOTFILES_DIR/lib/common.sh"

ASSUME_YES=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes)    ASSUME_YES=1; shift ;;
    --dry-run)   DRY_RUN=1; shift ;;
    -h|--help)
      cat <<'EOF'
Usage: ./uninstall.sh [options]

Options:
  -y, --yes      Assume yes
      --dry-run  Show what would happen, change nothing
  -h, --help     This help
EOF
      exit 0
      ;;
    *) die "unknown argument: $1" ;;
  esac
done
export ASSUME_YES DRY_RUN

TARGETS=(
  "$HOME/.zshrc"
  "$HOME/.zprofile"
  "$HOME/.tmux.conf"
  "$HOME/.tmux/tmux-keybindings.conf"
  "$HOME/.config/nvim"
  "$HOME/.config/starship.toml"
  "$HOME/.gitconfig"
  "$HOME/.gitignore_global"
)

log_section "Removing dotfiles symlinks"
for t in "${TARGETS[@]}"; do
  if [[ -L "$t" ]]; then
    src="$(readlink "$t")"
    if [[ "$src" == "$DOTFILES_DIR"* ]]; then
      run rm "$t"
      log_ok "removed $t"
    else
      log_skip "$t is a symlink but not to this repo ($src)"
    fi
  elif [[ -e "$t" ]]; then
    log_skip "$t is not a symlink, leaving it alone"
  else
    log_skip "$t does not exist"
  fi
done

# Offer to restore the most recent backup
LATEST_BACKUP="$(ls -1dt "$HOME"/.dotfiles-backup/*/ 2>/dev/null | head -1 || true)"
if [[ -n "$LATEST_BACKUP" ]]; then
  log_section "Backup found"
  log_info "Most recent backup: $LATEST_BACKUP"
  if confirm "Restore files from this backup into \$HOME?"; then
    # shellcheck disable=SC2231
    for f in "$LATEST_BACKUP".*; do
      [[ -e "$f" ]] || continue
      run mv "$f" "$HOME/$(basename "$f")"
      log_ok "restored $(basename "$f")"
    done
  fi
fi

log_section "Done"
