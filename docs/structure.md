# Project structure

Every folder under the repo root is a **module** — a self-contained unit that maps one or more files into `$HOME`. The installer treats each module independently, so you can install just `zsh` and `git` without touching nvim, etc.

```
.
├── install.sh / uninstall.sh / update.sh
├── lib/
│   └── common.sh             # shared bash helpers
├── packages/
│   ├── Brewfile              # macOS package manifest
│   └── apt.txt               # Debian/Ubuntu package list
├── zsh/
│   ├── zshrc                 -> ~/.zshrc
│   └── zprofile              -> ~/.zprofile
├── tmux/
│   ├── tmux.conf             -> ~/.tmux.conf
│   └── tmux-keybindings.conf -> ~/.tmux/tmux-keybindings.conf
├── nvim/                     -> ~/.config/nvim     (whole directory symlink)
│   ├── init.lua
│   ├── lazyvim.json
│   ├── stylua.toml
│   └── lua/
│       ├── config/
│       │   ├── lazy.lua      # lazy.nvim bootstrap + LazyVim spec import
│       │   ├── options.lua
│       │   ├── keymaps.lua
│       │   └── autocmds.lua
│       └── plugins/
│           ├── colorscheme.lua
│           └── example.lua
├── starship/
│   └── starship.toml         -> ~/.config/starship.toml
├── git/
│   ├── gitconfig             -> ~/.gitconfig
│   └── gitignore_global      -> ~/.gitignore_global
└── docs/
```

## Why "no leading dot" in the repo?

Industry-standard convention. Storing `zshrc` instead of `.zshrc` means:

- `ls` in the repo shows everything without `-a`.
- The repo is grep-friendly and easy to skim on github.com.
- The install step is explicit: `link_file zsh/zshrc ~/.zshrc`. There's a deliberate map from source name → target name.

The downside is one extra line in `install.sh` per file. Worth it.

## Why nvim is a directory symlink and tmux isn't

`~/.config/nvim/` is a directory LazyVim writes into (lockfiles, lazy-lock.json, lazyvim.json). Symlinking the whole directory means those writes go back into the repo, which is what we want — they're meant to be checked in.

For tmux, only two specific files are relevant (`~/.tmux.conf` and `~/.tmux/tmux-keybindings.conf`). The rest of `~/.tmux/` is TPM's plugin install dir, which we don't want in git. So we symlink the two files directly, leaving TPM free to manage `~/.tmux/plugins/`.

## `lib/common.sh`

The shared library every script sources. Provides:

- **Logging** — `log_info`, `log_ok`, `log_warn`, `log_err`, `log_section`, `log_skip`, all color-aware (no ANSI codes if stdout isn't a TTY).
- **`run`** — wraps any command so it can be no-op'd by `DRY_RUN=1`.
- **`detect_os`** — sets `$OS_FAMILY` to `macos` / `debian` / `unsupported`.
- **`sudo_cmd`** — echoes `sudo` when needed.
- **`init_backup_dir`** — lazy-creates `~/.dotfiles-backup/<timestamp>/`.
- **`link_file`** — the workhorse: backup, parent-mkdir, symlink, idempotent.
- **`confirm`** — y/N prompt that respects `$ASSUME_YES`.
- **`brew_install_if_missing`**, **`apt_install_if_missing`** — package wrappers that short-circuit when the package is already installed.

If you want to add a new helper that more than one script needs, this is where it goes.

## Local-only overrides

Three escape hatches exist for machine-specific settings that should not be checked in:

| File | Purpose |
| --- | --- |
| `~/.zshrc.local`     | Extra zsh config. Sourced near the bottom of `zshrc` if it exists. |
| `~/.gitconfig.local` | Per-machine git config. `gitconfig` `[include]`s it unconditionally. |
| `~/.dotfiles-backup` | Where displaced files go during install. Add it to your machine-wide ignore list. |

See [customization.md](customization.md) for examples.
