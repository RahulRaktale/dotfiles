#!/usr/bin/env bash
# update.sh - pull the dotfiles repo and refresh everything plugin-y
#
# - git pull --rebase the dotfiles repo
# - brew update + brew bundle  (macOS)  /  apt-get update + upgrade  (Debian)
# - tmux: update TPM plugins
# - nvim: :Lazy sync
#
# Usage:
#   ./update.sh
#   ./update.sh --dry-run

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"

# shellcheck source=lib/common.sh
source "$DOTFILES_DIR/lib/common.sh"

DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) echo "Usage: ./update.sh [--dry-run]"; exit 0 ;;
    *)         die "unknown argument: $1" ;;
  esac
done
export DRY_RUN

detect_os

log_section "Pulling dotfiles repo"
( cd "$DOTFILES_DIR" && run git pull --rebase --autostash )

log_section "Updating packages"
case "$OS_FAMILY" in
  macos)
    run brew update
    run brew upgrade
    run brew bundle --file="$DOTFILES_DIR/packages/Brewfile"
    ;;
  debian)
    sudo="$(sudo_cmd)"
    run $sudo apt-get update
    run $sudo apt-get upgrade -y
    ;;
  *)
    log_warn "unknown OS, skipping package update"
    ;;
esac

log_section "Updating tmux plugins (TPM)"
if [[ -x "$HOME/.tmux/plugins/tpm/bin/update_plugins" ]]; then
  run "$HOME/.tmux/plugins/tpm/bin/update_plugins" all || true
else
  log_skip "TPM not installed"
fi

log_section "Updating Neovim plugins"
if command -v nvim >/dev/null 2>&1; then
  run nvim --headless "+Lazy! sync" +qa || log_warn "Lazy sync exited non-zero"
else
  log_skip "nvim not on PATH"
fi

log_section "Done"
