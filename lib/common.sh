#!/usr/bin/env bash
# lib/common.sh - shared helpers for install/uninstall/update scripts
#
# Sourced by: install.sh, uninstall.sh, update.sh
# Provides: logging, OS detection, symlink + backup helpers, dry-run gating.
#
# This file should never be executed directly.
#
# shellcheck shell=bash

# ---- strict mode is set by the calling script, not here -------------------
# We avoid `set -euo pipefail` in libraries because it would also affect the
# interactive shell of anyone who sources this for debugging.

# ---- colors (only when stdout is a TTY) -----------------------------------
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
  C_RESET="$(tput sgr0)"
  C_RED="$(tput setaf 1)"
  C_GREEN="$(tput setaf 2)"
  C_YELLOW="$(tput setaf 3)"
  C_BLUE="$(tput setaf 4)"
  C_BOLD="$(tput bold)"
else
  C_RESET=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_BOLD=""
fi

# ---- logging --------------------------------------------------------------
log_info()    { printf '%s[info]%s  %s\n' "${C_BLUE}"   "${C_RESET}" "$*"; }
log_ok()      { printf '%s[ ok ]%s  %s\n' "${C_GREEN}"  "${C_RESET}" "$*"; }
log_warn()    { printf '%s[warn]%s  %s\n' "${C_YELLOW}" "${C_RESET}" "$*" >&2; }
log_err()     { printf '%s[err ]%s  %s\n' "${C_RED}"    "${C_RESET}" "$*" >&2; }
log_section() { printf '\n%s==> %s%s\n' "${C_BOLD}" "$*" "${C_RESET}"; }
log_skip()    { printf '%s[skip]%s  %s\n' "${C_YELLOW}" "${C_RESET}" "$*"; }

die() { log_err "$*"; exit 1; }

# ---- dry-run gating -------------------------------------------------------
# Scripts set DRY_RUN=1 to preview without making changes.
DRY_RUN="${DRY_RUN:-0}"

# run <cmd...>: execute the command, or just print it in dry-run mode.
run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '%s[dry ]%s  %s\n' "${C_YELLOW}" "${C_RESET}" "$*"
  else
    "$@"
  fi
}

# ---- OS detection ---------------------------------------------------------
# Sets OS_FAMILY to one of: macos, debian, unsupported
detect_os() {
  local uname_s
  uname_s="$(uname -s)"

  case "$uname_s" in
    Darwin)
      OS_FAMILY="macos"
      ;;
    Linux)
      if [[ -r /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "${ID:-}" in
          debian|ubuntu|raspbian|pop|linuxmint|elementary|zorin)
            OS_FAMILY="debian"
            ;;
          *)
            # Some derivatives only set ID_LIKE
            case "${ID_LIKE:-}" in
              *debian*|*ubuntu*) OS_FAMILY="debian" ;;
              *)                 OS_FAMILY="unsupported" ;;
            esac
            ;;
        esac
      else
        OS_FAMILY="unsupported"
      fi
      ;;
    *)
      OS_FAMILY="unsupported"
      ;;
  esac
  export OS_FAMILY
}

# ---- privilege helper -----------------------------------------------------
# Echoes "sudo" when needed for apt; empty on macOS / root.
sudo_cmd() {
  if [[ "$(id -u)" -eq 0 ]]; then
    echo ""
  elif command -v sudo >/dev/null 2>&1; then
    echo "sudo"
  else
    echo ""
  fi
}

# ---- backup directory -----------------------------------------------------
# Timestamped backup dir, created lazily on first use.
init_backup_dir() {
  BACKUP_DIR="${BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"
  if [[ "$DRY_RUN" != "1" ]]; then
    mkdir -p "$BACKUP_DIR"
  fi
  export BACKUP_DIR
}

# ---- symlink helper -------------------------------------------------------
# link_file <source> <target>
#   - <source> must be an absolute path inside the dotfiles repo
#   - <target> is the destination path in $HOME (e.g., ~/.zshrc)
#
# Behavior:
#   - If target is already a symlink to source: skip (idempotent).
#   - If target exists (file/dir/wrong symlink): move it to BACKUP_DIR.
#   - Create parent directory if missing.
#   - Create symlink.
link_file() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" ]]; then
    log_warn "source missing, skipping: $src"
    return 0
  fi

  # Ensure parent dir of destination exists
  local parent
  parent="$(dirname "$dst")"
  if [[ ! -d "$parent" ]]; then
    run mkdir -p "$parent"
  fi

  # Already linked correctly?
  if [[ -L "$dst" ]]; then
    local current
    current="$(readlink "$dst")"
    if [[ "$current" == "$src" ]]; then
      log_skip "$dst -> $src (already linked)"
      return 0
    fi
  fi

  # Back up anything in the way
  if [[ -e "$dst" || -L "$dst" ]]; then
    init_backup_dir
    log_warn "backing up existing $dst -> $BACKUP_DIR/"
    run mv "$dst" "$BACKUP_DIR/"
  fi

  run ln -s "$src" "$dst"
  log_ok "linked $dst -> $src"
}

# ---- confirmation prompt --------------------------------------------------
# confirm "Question?" [default-y|default-n]
# Returns 0 (yes) or 1 (no). Respects ASSUME_YES=1.
confirm() {
  local prompt="$1"
  local default="${2:-default-n}"
  if [[ "${ASSUME_YES:-0}" == "1" ]]; then
    return 0
  fi
  local hint="[y/N]"
  [[ "$default" == "default-y" ]] && hint="[Y/n]"
  local reply
  read -r -p "$prompt $hint " reply
  if [[ -z "$reply" ]]; then
    [[ "$default" == "default-y" ]] && return 0 || return 1
  fi
  [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

# ---- package install wrappers --------------------------------------------
brew_install_if_missing() {
  local formula="$1"
  if brew list --formula "$formula" >/dev/null 2>&1; then
    log_skip "brew: $formula (already installed)"
  else
    run brew install "$formula"
  fi
}

brew_cask_install_if_missing() {
  local cask="$1"
  if brew list --cask "$cask" >/dev/null 2>&1; then
    log_skip "brew cask: $cask (already installed)"
  else
    run brew install --cask "$cask"
  fi
}

apt_install_if_missing() {
  local pkg="$1"
  local sudo
  sudo="$(sudo_cmd)"
  if dpkg -s "$pkg" >/dev/null 2>&1; then
    log_skip "apt: $pkg (already installed)"
  else
    run $sudo apt-get install -y "$pkg"
  fi
}
