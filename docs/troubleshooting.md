# Troubleshooting

Most common failure modes and how to recover from them.

## "Homebrew is not installed" loop on macOS

The installer tries to add brew to your PATH inside the script, but a fresh Homebrew install sometimes needs a new shell session. Easy fix:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"   # Apple Silicon
# or
eval "$(/usr/local/bin/brew shellenv)"      # Intel
./install.sh
```

## `nvim` is too old / LazyVim refuses to start

LazyVim requires Neovim 0.10 or newer. On Debian/Ubuntu, the `apt` version is usually 0.7–0.9. The installer detects this and installs the latest AppImage to `~/.local/bin/nvim`. Make sure `~/.local/bin` is on your PATH:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc.local
exec zsh
nvim --version
```

If it still picks the old one, check `which -a nvim` and reorder PATH.

## zsh autosuggestions / syntax-highlighting not visible

The `zshrc` probes a handful of paths for each plugin. If you installed via a non-standard method (e.g. directly cloning to `~/.zsh/plugins/`), make sure the plugin file ends up at one of:

- `/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh` (Homebrew, Apple Silicon)
- `/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh` (Homebrew, Intel)
- `/home/linuxbrew/.linuxbrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh` (Linuxbrew)
- `/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh` (apt)
- `~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh` (manual clone)

Same applies to `zsh-syntax-highlighting` and `fzf-tab`. Easiest fix if you're on Debian and the apt package doesn't exist:

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/plugins/zsh-syntax-highlighting
git clone https://github.com/Aloxaf/fzf-tab ~/.zsh/plugins/fzf-tab
```

## fzf-tab not triggering on Tab

Three things have to be in the right order in `zshrc`:

1. `compinit` — runs before anything else.
2. `eval "$(fzf --zsh)"` — fzf's shell integration.
3. `source .../fzf-tab.plugin.zsh` — fzf-tab itself.

If you've added zsh plugins of your own, make sure none of them bind `^I` (Tab) before fzf-tab does. The shipped `zshrc` sources autosuggestions and syntax-highlighting **after** fzf-tab on purpose.

## tmux plugins don't load

Symptoms: `prefix + I` does nothing, or plugins show as "not installed".

1. Is TPM cloned? `ls ~/.tmux/plugins/tpm`. If not, run `~/.dotfiles/install.sh --only=tmux` to bootstrap.
2. Is the `run '~/.tmux/plugins/tpm/tpm'` line the **last** line of `tmux.conf`? If you edited it, make sure it stayed at the bottom.
3. Reload: kill tmux entirely (`tmux kill-server`) and start a fresh session.

## Backup didn't restore via `uninstall.sh`

`uninstall.sh` looks for the most recent timestamped backup at `~/.dotfiles-backup/<YYYYMMDD-HHMMSS>/`. If you have multiple backups and want an older one:

```bash
ls -1dt ~/.dotfiles-backup/*/
mv ~/.dotfiles-backup/20260318-201500/.zshrc ~/.zshrc
```

## `chsh` says "non-standard shell"

You need to whitelist zsh in `/etc/shells` first:

```bash
command -v zsh | sudo tee -a /etc/shells
chsh -s "$(command -v zsh)"
```

The installer does this automatically, but if you skipped the prompt, run it manually.

## "Permission denied" on `install.sh`

```bash
chmod +x install.sh uninstall.sh update.sh
```

## Symlinks point to the wrong place after moving the repo

Symlinks store absolute paths. If you move `~/.dotfiles` to `~/code/dotfiles`, every symlink is now broken. Either:

```bash
./uninstall.sh && ./install.sh         # rebuild
```

or fix them in-place:

```bash
find ~ -maxdepth 3 -lname '*/old-dotfiles-path/*' -print
```

## Nothing works after install on macOS — terminal says "command not found"

Homebrew on Apple Silicon installs to `/opt/homebrew`, not `/usr/local`. The shipped `zprofile` handles both. If you've sourced `.zshrc` from `.zprofile` in some custom way and broken the chain, just:

```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
exec zsh -l
```

## Need to start completely over

```bash
./uninstall.sh --yes
rm -rf ~/.config/nvim ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
rm -rf ~/.tmux/plugins
./install.sh --yes
```

This wipes LazyVim's local plugin cache and TPM's plugins, then reinstalls everything. Your dotfiles repo and `~/.dotfiles-backup/` are untouched.
