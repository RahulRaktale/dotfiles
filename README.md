# dotfiles

Personal configuration for **zsh**, **tmux**, **Neovim** (via [LazyVim]), **Starship**, and **git**, plus a one-shot installer that bootstraps a fresh machine on macOS or Debian/Ubuntu.

[LazyVim]: https://www.lazyvim.org/

```
~/.dotfiles
├── install.sh         # main installer (idempotent, dry-run, --only support)
├── uninstall.sh       # remove symlinks, optionally restore backups
├── update.sh          # git pull + refresh packages + plugins
├── lib/common.sh      # shared bash helpers (logging, link_file, OS detect, ...)
├── packages/
│   ├── Brewfile       # macOS package manifest
│   └── apt.txt        # Debian/Ubuntu package list
├── zsh/               # zshrc, zprofile
├── tmux/              # tmux.conf, tmux-keybindings.conf
├── nvim/              # LazyVim configuration (-> ~/.config/nvim)
├── starship/          # starship.toml (-> ~/.config/starship.toml)
├── git/               # gitconfig, gitignore_global
└── docs/              # detailed docs (installation, structure, etc.)
```

## Quick start

```bash
git clone https://github.com/rahulraktale/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

The installer is **idempotent** — safe to re-run. It will:

1. Detect macOS or Debian/Ubuntu and abort on anything else.
2. Install **Homebrew** (macOS) or run **apt-get** (Debian) and pull in every package listed in `packages/`.
3. Install everything that isn't in the standard repos (Starship, eza, zoxide, fzf-tab, a current Neovim AppImage on Debian).
4. **Back up** anything already living at the target paths into `~/.dotfiles-backup/<timestamp>/`.
5. **Symlink** each module's files into your home directory.
6. Bootstrap **TPM** and install your tmux plugins.
7. Bootstrap **LazyVim** by running `nvim --headless +Lazy! sync +qa`.
8. Offer to `chsh -s $(which zsh)` if zsh isn't already your default shell.

### See what it would do (no changes)

```bash
./install.sh --dry-run
```

### Skip the package step (you already have everything)

```bash
./install.sh --no-packages
```

### Only install one or two modules

```bash
./install.sh --only=zsh,tmux
# valid modules: zsh, tmux, nvim, git, starship
```

### Update everything later

```bash
~/.dotfiles/update.sh
```

### Tear it down

```bash
~/.dotfiles/uninstall.sh
```

`uninstall.sh` removes only the symlinks that point inside the dotfiles repo, then offers to restore the most recent backup from `~/.dotfiles-backup/`.

## What you get

| Module     | What it sets up                                                                                                                         |
| ---------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| `zsh`      | `~/.zshrc`, `~/.zprofile` with: history config, fzf + fzf-tab, **zsh-autosuggestions**, **zsh-syntax-highlighting**, aliases, widgets   |
| `tmux`     | `~/.tmux.conf` + `~/.tmux/tmux-keybindings.conf`, TPM auto-bootstrap, prefix remapped to `C-a`, vim-like copy-mode, mouse, 50k history  |
| `nvim`     | `~/.config/nvim` symlinked to a **LazyVim** install with sensible options, custom keymaps and autocmds, tokyonight colorscheme          |
| `starship` | `~/.config/starship.toml` — two-line prompt with git status, language indicators, nerd-font glyphs                                      |
| `git`      | `~/.gitconfig` + `~/.gitignore_global` — sane defaults, useful aliases, `.gitconfig.local` for machine-specific overrides               |

## Documentation

For deeper detail, see the [`docs/`](docs/) folder:

- [Installation guide](docs/installation.md) — step-by-step walkthrough, OS-specific notes, troubleshooting the installer itself.
- [Project structure](docs/structure.md) — what each folder is for and why.
- [Customization](docs/customization.md) — how to add a new module, override a value, keep machine-specific config out of the repo.
- [Troubleshooting](docs/troubleshooting.md) — common problems and fixes (missing fzf-tab, slow nvim startup, tmux plugins not loading, …).
- [FAQ](docs/faq.md) — design decisions explained.

## Supported platforms

- macOS 12+ (Apple Silicon or Intel) — primary target.
- Debian 11+ / Ubuntu 22.04+ — fully supported by the installer.

The configs themselves are written to be portable (Homebrew paths and Linuxbrew paths are both probed, OS-specific aliases switch on `$(uname -s)`), so the runtime configs work fine on Arch/Fedora/NixOS too — you'll just need to install packages yourself.

## License

[MIT](LICENSE) — see the file for details.
