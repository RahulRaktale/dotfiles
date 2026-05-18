# Customization

How to make this repo yours without diverging from upstream.

## Machine-specific overrides

You almost never want to edit `zshrc` or `gitconfig` for one-off things like a work email or a path that only exists on one laptop. Use the override files instead.

### `~/.zshrc.local`

Sourced near the bottom of `zsh/zshrc` if it exists:

```zsh
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
```

Use it for:

- Work-only API tokens and `export FOO=bar` lines
- A different `JAVA_HOME` on this specific machine
- Project-specific aliases you don't want on your personal laptop

### `~/.gitconfig.local`

The shipped `gitconfig` ends with:

```ini
[include]
	path = ~/.gitconfig.local
```

Anything in `~/.gitconfig.local` overrides anything in `~/.gitconfig`. Typical contents:

```ini
[user]
	email = me@work-employer.com
[commit]
	gpgsign = true
[user]
	signingkey = ABCD1234EFGH5678
```

## Adding a new module

Say you want to add an Alacritty config. The install/update/uninstall scripts pick up any module you wire in correctly.

1. **Create the folder and file** in the repo:

   ```bash
   mkdir -p alacritty
   $EDITOR alacritty/alacritty.toml
   ```

2. **Add a `link_file` call** to `install.sh` in the "Linking dotfiles" section:

   ```bash
   if is_enabled alacritty; then
     run mkdir -p "$HOME/.config/alacritty"
     link_file "$DOTFILES_DIR/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
   fi
   ```

3. **Register the module** in the `ENABLED` map at the top of `install.sh`:

   ```bash
   declare -A ENABLED=( [zsh]=1 [tmux]=1 [nvim]=1 [git]=1 [starship]=1 [alacritty]=1 )
   ```

4. **Add to `uninstall.sh`** so `./uninstall.sh` knows about it:

   ```bash
   TARGETS=(
     # ...
     "$HOME/.config/alacritty/alacritty.toml"
   )
   ```

That's it. Re-run `./install.sh` and your alacritty.toml is symlinked.

## Customizing LazyVim

LazyVim is normal Neovim Lua config — change anything you like in `nvim/`:

- **Add a plugin:** create a new file in `nvim/lua/plugins/` that returns a plugin spec table.
- **Override a LazyVim plugin's options:** see the examples in `nvim/lua/plugins/example.lua`.
- **Enable an extra language pack:** uncomment the relevant `import = "lazyvim.plugins.extras.lang.X"` line in `lua/config/lazy.lua`, then run `:Lazy sync` inside nvim.
- **Disable a default LazyVim plugin:** `{ "akinsho/bufferline.nvim", enabled = false }` in any file under `lua/plugins/`.

After any change, run `:Lazy sync` once. The lockfile (`nvim/lazy-lock.json`) commits to git so other machines pull the same versions.

## Changing the prompt

Edit `starship/starship.toml`. See https://starship.rs/config for every option. Reload your shell to see changes (`exec zsh`).

## Changing tmux keybindings

All keybindings live in `tmux/tmux-keybindings.conf`. After editing, either:

- Inside tmux: press `prefix + r` (the shipped tmux.conf binds `r` to reload), or
- From outside: `tmux source ~/.tmux.conf`

## Adding aliases

For permanent aliases that should be on every machine, edit `zsh/zshrc`. For machine-specific ones, drop them in `~/.zshrc.local`.

## Excluding a module from a particular install

```bash
./install.sh --only=zsh,git    # only zsh and git on this machine
```
