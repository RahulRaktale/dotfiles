#!/usr/bin/env bash
# install.sh - bootstrap this machine from the dotfiles repo
#
# What it does (in order):
#   1. Detect the OS family (macOS / Debian-Ubuntu).
#   2. Install a package manager (Homebrew on both macOS and Debian, or apt).
#   3. Install all packages (zsh, tmux, neovim, starship, fzf, ripgrep, bat,
#      eza, zoxide, zsh-autosuggestions, zsh-syntax-highlighting, fzf-tab, ...).
#   4. Back up any conflicting files in $HOME to ~/.dotfiles-backup/<timestamp>/
#   5. Symlink the repo's configs into $HOME and $HOME/.config.
#   6. Bootstrap TPM (tmux plugin manager) and install its plugins.
#   7. Bootstrap LazyVim by running `nvim --headless` once.
#   8. Optionally chsh to zsh.
#
# Safe to re-run. Symlinks that already point to this repo are left alone.
#
# Usage:
#   ./install.sh                # interactive
#   ./install.sh --yes          # assume yes to every prompt
#   ./install.sh --dry-run      # print what would happen, change nothing
#   ./install.sh --no-packages  # only symlink dotfiles, skip package install
#   ./install.sh --only=zsh,tmux,nvim,git,starship   # subset of modules
#   ./install.sh --help

set -euo pipefail

# ---- locate the repo --------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"

# shellcheck source=lib/common.sh
source "$DOTFILES_DIR/lib/common.sh"

# ---- argv parsing -----------------------------------------------------------
ASSUME_YES=0
DRY_RUN=0
SKIP_PACKAGES=0
ONLY=""

print_help() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  -y, --yes              Assume "yes" for every interactive prompt
      --dry-run          Print every action; do not modify the filesystem
      --no-packages      Skip the package-install step
      --only=LIST        Only install/link these modules (comma-separated).
                         Valid: zsh, tmux, nvim, git, starship
  -h, --help             Show this help

Examples:
  ./install.sh
  ./install.sh --dry-run
  ./install.sh --yes --no-packages
  ./install.sh --only=zsh,tmux
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes)          ASSUME_YES=1; shift ;;
    --dry-run)         DRY_RUN=1; shift ;;
    --no-packages)     SKIP_PACKAGES=1; shift ;;
    --only=*)          ONLY="${1#*=}"; shift ;;
    --only)            ONLY="${2:-}"; shift 2 ;;
    -h|--help)         print_help; exit 0 ;;
    *)                 log_err "unknown argument: $1"; print_help; exit 2 ;;
  esac
done

export ASSUME_YES DRY_RUN

# ---- module enable flags ----------------------------------------------------
# bash 3.2 (macOS default) doesn't support `declare -A`, so we use a
# space-separated string sentinel pattern instead.
ALL_MODULES="zsh tmux nvim git starship"
ENABLED_MODULES="$ALL_MODULES"

if [[ -n "$ONLY" ]]; then
  ENABLED_MODULES=""
  # Split $ONLY on commas (portable across bash 3.x)
  IFS=',' read -r -a picked <<<"$ONLY"
  for m in "${picked[@]}"; do
    m="$(echo "$m" | tr '[:upper:]' '[:lower:]' | xargs)"
    case " $ALL_MODULES " in
      *" $m "*) ENABLED_MODULES="$ENABLED_MODULES $m" ;;
      *)        die "unknown module: $m (valid: $ALL_MODULES)" ;;
    esac
  done
fi

is_enabled() {
  case " $ENABLED_MODULES " in
    *" $1 "*) return 0 ;;
    *)        return 1 ;;
  esac
}

# ---- banner -----------------------------------------------------------------
log_section "Dotfiles install"
log_info "repo:     $DOTFILES_DIR"
log_info "dry-run:  $DRY_RUN"
log_info "modules: $ENABLED_MODULES"

# ---- detect OS --------------------------------------------------------------
detect_os
log_info "os:       $OS_FAMILY"
if [[ "$OS_FAMILY" == "unsupported" ]]; then
  die "Unsupported OS. This installer supports macOS and Debian/Ubuntu."
fi

# =============================================================================
# Step 1: package manager + packages
# =============================================================================
install_packages_macos() {
  log_section "Installing packages (macOS / Homebrew)"

  if ! command -v brew >/dev/null 2>&1; then
    if confirm "Homebrew is not installed. Install it now?" default-y; then
      log_info "Installing Homebrew..."
      run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      # shellenv for the rest of this script
      if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
    else
      die "Homebrew is required."
    fi
  fi

  log_info "Running brew bundle..."
  run brew update
  run brew bundle --file="$DOTFILES_DIR/packages/Brewfile"
}

install_packages_debian() {
  log_section "Installing packages (Debian/Ubuntu / apt)"
  local sudo
  sudo="$(sudo_cmd)"

  run $sudo apt-get update

  # Read packages from apt.txt (skip blank lines and comments)
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    apt_install_if_missing "$line"
  done < "$DOTFILES_DIR/packages/apt.txt"

  # Debian's `bat` and `fd` binaries are installed under different names.
  # Create user-local symlinks so scripts find them.
  if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    run mkdir -p "$HOME/.local/bin"
    run ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    log_ok "linked batcat -> ~/.local/bin/bat"
  fi
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    run mkdir -p "$HOME/.local/bin"
    run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    log_ok "linked fdfind -> ~/.local/bin/fd"
  fi

  # Neovim on apt is usually too old for LazyVim (needs >= 0.10).
  # Install via the official AppImage if missing or too old.
  install_neovim_debian
  # Starship, fzf-tab, eza, zoxide are not in standard apt repos; install them.
  install_starship_debian
  install_eza_debian
  install_zoxide_debian
  install_fzf_tab_debian
}

install_neovim_debian() {
  local need_install=1
  if command -v nvim >/dev/null 2>&1; then
    local v
    v="$(nvim --version | head -1 | sed 's/^NVIM v//')"
    # major.minor compare against 0.10
    if [[ "$v" =~ ^([0-9]+)\.([0-9]+) ]]; then
      local maj="${BASH_REMATCH[1]}" min="${BASH_REMATCH[2]}"
      if (( maj > 0 )) || (( maj == 0 && min >= 10 )); then
        need_install=0
      fi
    fi
  fi
  if (( need_install )); then
    log_info "Installing latest Neovim AppImage..."
    run mkdir -p "$HOME/.local/bin"
    run curl -L -o "$HOME/.local/bin/nvim" \
      "https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"
    run chmod +x "$HOME/.local/bin/nvim"
  else
    log_skip "nvim already >= 0.10"
  fi
}

install_starship_debian() {
  if command -v starship >/dev/null 2>&1; then
    log_skip "starship already installed"
  else
    log_info "Installing starship..."
    run sh -c "$(curl -fsSL https://starship.rs/install.sh)" -- --yes --bin-dir "$HOME/.local/bin"
  fi
}

install_eza_debian() {
  if command -v eza >/dev/null 2>&1; then
    log_skip "eza already installed"
    return
  fi
  log_info "Installing eza from the official apt repo..."
  local sudo
  sudo="$(sudo_cmd)"
  run $sudo mkdir -p /etc/apt/keyrings
  run sh -c 'curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor | '"$sudo"' tee /etc/apt/keyrings/gierens.gpg > /dev/null'
  run sh -c 'echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | '"$sudo"' tee /etc/apt/sources.list.d/gierens.list'
  run $sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  run $sudo apt-get update
  run $sudo apt-get install -y eza
}

install_zoxide_debian() {
  if command -v zoxide >/dev/null 2>&1; then
    log_skip "zoxide already installed"
    return
  fi
  log_info "Installing zoxide..."
  run sh -c "$(curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh)"
}

install_fzf_tab_debian() {
  local target="$HOME/.zsh/plugins/fzf-tab"
  if [[ -d "$target" ]]; then
    log_skip "fzf-tab already cloned at $target"
    return
  fi
  log_info "Cloning fzf-tab..."
  run git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$target"
}

if (( SKIP_PACKAGES == 0 )); then
  case "$OS_FAMILY" in
    macos)  install_packages_macos  ;;
    debian) install_packages_debian ;;
  esac
else
  log_skip "package install (--no-packages)"
fi

# =============================================================================
# Step 2: symlink dotfiles
# =============================================================================
log_section "Linking dotfiles"

# zsh
if is_enabled zsh; then
  link_file "$DOTFILES_DIR/zsh/zshrc"    "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/zsh/zprofile" "$HOME/.zprofile"
fi

# tmux
if is_enabled tmux; then
  link_file "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
  run mkdir -p "$HOME/.tmux"
  link_file "$DOTFILES_DIR/tmux/tmux-keybindings.conf" "$HOME/.tmux/tmux-keybindings.conf"
fi

# nvim (LazyVim lives at ~/.config/nvim)
if is_enabled nvim; then
  run mkdir -p "$HOME/.config"
  link_file "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
fi

# starship
if is_enabled starship; then
  run mkdir -p "$HOME/.config"
  link_file "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
fi

# git
if is_enabled git; then
  link_file "$DOTFILES_DIR/git/gitconfig"        "$HOME/.gitconfig"
  link_file "$DOTFILES_DIR/git/gitignore_global" "$HOME/.gitignore_global"
fi

# =============================================================================
# Step 3: bootstrap plugin managers
# =============================================================================
log_section "Bootstrapping plugin managers"

# TPM (tmux plugin manager)
if is_enabled tmux; then
  if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    log_skip "tpm already installed"
  else
    log_info "Cloning TPM..."
    run git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    log_info "Installing tmux plugins via TPM..."
    run "$HOME/.tmux/plugins/tpm/bin/install_plugins" || log_warn "tpm install returned non-zero; run it manually inside tmux with prefix + I."
  fi
fi

# LazyVim / lazy.nvim
if is_enabled nvim; then
  if command -v nvim >/dev/null 2>&1; then
    log_info "Bootstrapping LazyVim (this can take a minute on first run)..."
    # Headless install: lazy.nvim clones itself, then syncs all plugins, then quits.
    run nvim --headless "+Lazy! sync" +qa || log_warn "headless Lazy sync exited non-zero; open nvim and run :Lazy sync to finish."
  else
    log_warn "nvim not on PATH yet. Open a new shell and start nvim to finish LazyVim setup."
  fi
fi

# =============================================================================
# Step 4: optional shell change
# =============================================================================
if is_enabled zsh; then
  if [[ "${SHELL:-}" != *"zsh"* ]]; then
    if confirm "Set zsh as the default shell?" default-y; then
      ZSH_PATH="$(command -v zsh)"
      # Ensure zsh is in /etc/shells
      if ! grep -qx "$ZSH_PATH" /etc/shells 2>/dev/null; then
        local_sudo="$(sudo_cmd)"
        # shellcheck disable=SC2086
        run sh -c "echo \"$ZSH_PATH\" | $local_sudo tee -a /etc/shells >/dev/null"
      fi
      run chsh -s "$ZSH_PATH"
    fi
  else
    log_skip "default shell is already zsh"
  fi
fi

# =============================================================================
# done
# =============================================================================
log_section "All done"
log_ok "Backups (if any) are in: ${BACKUP_DIR:-<none created>}"
log_info "Open a new terminal (or run \`exec zsh -l\`) to load your new shell."
log_info "Inside tmux, plugins will auto-install on first launch."
log_info "Inside nvim, run :Lazy to see plugin status."
