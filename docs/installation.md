# Installation guide

Step-by-step walkthrough of `install.sh` and how to recover when something goes wrong.

## Prerequisites

The installer assumes a working internet connection and the following:

| Platform | Required up-front | Installer will install for you |
| --- | --- | --- |
| **macOS** | macOS 12+, Xcode Command Line Tools (`xcode-select --install`) | Homebrew, all packages, fzf-tab, zsh-autosuggestions, zsh-syntax-highlighting, etc. |
| **Debian / Ubuntu** | A sudo-enabled user, `curl`, `git` | apt packages, current Neovim AppImage, Starship, eza, zoxide, fzf-tab |

If you don't have `git` or `curl` yet on Debian:

```bash
sudo apt-get update && sudo apt-get install -y git curl
```

## The standard install

```bash
git clone https://github.com/rahulraktale/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

The script walks five phases. Each prints its own `==>` banner so you can see where you are.

### Phase 1 — OS detection

The installer reads `uname` and `/etc/os-release`, then either picks `macos` or `debian` (which also covers Ubuntu, Mint, Pop!_OS, Raspbian, Zorin, and any distro whose `ID_LIKE` includes `debian`/`ubuntu`).

If your OS is unsupported, the installer aborts before touching anything.

### Phase 2 — Package install

- **macOS:** if `brew` isn't on the PATH, the installer offers to download and run the official Homebrew installer. Once Homebrew is present it runs `brew bundle --file=packages/Brewfile`, which is idempotent — already-installed formulae are skipped.
- **Debian/Ubuntu:** `apt-get update`, then one `apt-get install -y` per line of `packages/apt.txt`. Each call goes through `apt_install_if_missing`, which checks `dpkg -s` first, so re-runs are fast.

After the package manager phase, the installer fills in tools that aren't in standard repos:

- A current Neovim AppImage (the apt version is too old for LazyVim, which needs Neovim ≥ 0.10).
- **Starship** (official install script).
- **eza** (official apt repo, signed with the maintainer's GPG key).
- **zoxide** (official install script).
- **fzf-tab** (cloned to `~/.zsh/plugins/fzf-tab`; the zshrc picks it up there).
- `~/.local/bin/bat → batcat` and `~/.local/bin/fd → fdfind` symlinks, since Debian renames those binaries.

To skip this phase entirely:

```bash
./install.sh --no-packages
```

### Phase 3 — Symlinks

For every file in the repo, the installer:

1. Computes the target path in `$HOME` (e.g. `zsh/zshrc → ~/.zshrc`, `nvim → ~/.config/nvim`).
2. If the target is already a symlink to the right place, it skips.
3. If something else is there, it moves it to `~/.dotfiles-backup/<timestamp>/` first.
4. Then creates the symlink.

This is the safest possible flow: nothing is ever deleted. If you have a five-year-old `~/.zshrc` you've forgotten about, it'll be sitting in `~/.dotfiles-backup/` after the install.

### Phase 4 — Plugin bootstrap

- **TPM:** if `~/.tmux/plugins/tpm/` doesn't exist, the installer clones it and runs `~/.tmux/plugins/tpm/bin/install_plugins` once. After that, the `tmux.conf` itself has an `if-shell` block that re-bootstraps TPM if it ever goes missing.
- **LazyVim:** the installer runs `nvim --headless "+Lazy! sync" +qa`, which:
  1. Clones `folke/lazy.nvim` (which `lua/config/lazy.lua` bootstraps if missing).
  2. Pulls every plugin LazyVim depends on.
  3. Quits.

  First run takes ~30–60 seconds. After that, plugins are cached and nvim starts in <100ms.

### Phase 5 — Default shell

If your `$SHELL` isn't zsh, the installer offers to `chsh` to the installed zsh. It also makes sure that zsh path is listed in `/etc/shells` first.

## Flags

| Flag | Effect |
| --- | --- |
| `-y`, `--yes` | Skip all confirmation prompts (CI-friendly). |
| `--dry-run` | Print every action with a `[dry]` prefix; don't touch anything. |
| `--no-packages` | Symlinks + plugin bootstrap only. |
| `--only=zsh,tmux` | Subset of modules. Valid: `zsh`, `tmux`, `nvim`, `git`, `starship`. |
| `-h`, `--help` | Usage. |

## What if something fails?

The installer uses `set -euo pipefail`, so any uncaught error stops the run. Re-running picks up where it left off — symlinks that succeeded are no-ops the second time.

If a package fails to install, fix that one thing manually and re-run:

```bash
./install.sh --yes
```

If you need to start over completely:

```bash
./uninstall.sh                    # remove symlinks
mv ~/.dotfiles-backup/<ts>/* ~/   # restore old configs
```

See [troubleshooting.md](troubleshooting.md) for specific failure modes.
