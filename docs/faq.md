# FAQ

Why things are the way they are.

## Why a plain bash installer instead of GNU Stow / chezmoi / a bare git repo?

Three reasons:

1. **No dependencies.** Bash is on every Unix box. Stow isn't on macOS by default; chezmoi requires a Go binary; bare git repos have surprising failure modes.
2. **One file to read.** Everything `install.sh` does is in plain bash with logs. Anyone can audit it in five minutes.
3. **Explicit mappings.** Each `link_file` line is a deliberate decision: "this file goes there." Stow infers the mapping from directory structure, which is fast but can surprise you when it picks up files you didn't mean to share.

Trade-off: every new file needs one line in `install.sh`. For a personal dotfiles repo this is fine.

## Why is the prefix remapped to `C-a` instead of `C-b`?

`C-b` is the GNU readline binding for "move backward one character" — having it eaten by tmux makes editing commands in zsh annoying. `C-a` ("go to start of line" in readline) is *also* useful, but most people who use tmux heavily decide they want it for tmux. Either is fine; this repo defaults to `C-a` because that's what the original tmux config used.

## Why is zsh-syntax-highlighting loaded LAST?

The plugin overrides `zle_keymap_select` and `zle_line_init` to add highlighting. If anything else (autosuggestions, fzf-tab, custom widgets) rebinds those widgets after syntax-highlighting loads, highlighting silently breaks. Sourcing it last guarantees its widgets win.

This is documented in the [official plugin README](https://github.com/zsh-users/zsh-syntax-highlighting#why-must-zsh-syntax-highlightingzsh-be-sourced-at-the-end-of-the-zshrc-file).

## Why is `escape-time` set to 0 in tmux?

By default tmux waits 500ms after `Esc` to disambiguate from escape sequences. That's the entire latency of leaving insert mode in vim/nvim. Setting it to 0 makes Neovim feel native. (Modern terminals send proper escape sequences fast enough that this is safe — circa-2010 advice to leave a non-zero delay is obsolete.)

## Why does the Brewfile not include Ghostty / Alacritty / a Nerd Font?

Those are personal preferences and break CI installs. They're listed as commented-out lines so you can opt in.

If you want a Nerd Font:

```bash
brew install --cask font-jetbrains-mono-nerd-font
```

Then set it as your terminal's font.

## Why is Neovim installed via AppImage on Debian instead of from a PPA?

PPAs come and go. The official `unstable` PPA was abandoned for months in 2024. The AppImage is the maintainers' supported, version-locked, "just works" channel.

If your kernel/distro doesn't support AppImages, edit `install_neovim_debian` in `install.sh` to clone and build from source instead.

## Why does the installer back up to `~/.dotfiles-backup/` instead of overwriting?

Mistakes happen. Replacing `~/.zshrc` with a symlink to a different file is destructive; making a copy first costs nothing and has saved many a config from oblivion. The directory is timestamped so multiple installs don't clobber each other.

## Why no `.zshenv`?

It would be sourced for **every** invocation of zsh — including non-interactive scripts and remote `ssh user@host command` runs. That's the wrong place for almost everything. The exception is `XDG_CONFIG_HOME` and similar low-level env vars; this repo doesn't need to set any, so `.zshenv` is omitted. Add one if you do.

## Why a `.gitconfig.local` include at the end of `gitconfig`?

Per-machine settings (work email, signing key, work directory `includeIf`, …) should not be in source control. The `[include]` block at the end of `gitconfig` pulls them in unconditionally — and `git config` quietly ignores missing files, so this works even on a fresh machine before you've created the local file.

## Why isn't `oh-my-zsh` used?

It's heavy. It loads dozens of files at startup and adds 200–400ms to zsh startup time. The features people actually use (autosuggestions, syntax-highlighting, fzf integration, useful aliases, a nice prompt) are all available as standalone components that load faster and that you can wire together exactly how you want — which is what this repo does.

## Can I use this on Arch / Fedora / NixOS?

The configs themselves work fine. The installer doesn't know about pacman/dnf/nix yet; either add a branch in `install.sh` (the `OS_FAMILY` detection and `install_packages_<os>` function pattern is easy to extend) or run with `--no-packages` and install the packages yourself.
