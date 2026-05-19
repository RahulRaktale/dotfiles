# Catppuccin Macchiato

Color theme files used across the dotfiles. **Macchiato** is the second-darkest Catppuccin variant (after Mocha) — soft contrast, warm pastels, easy on the eyes for long sessions.

## What gets themed

| Tool         | Method                                                                                  |
| ------------ | --------------------------------------------------------------------------------------- |
| **iTerm2**   | `iterm2/Catppuccin-Macchiato.itermcolors` — installer imports it via `open` on macOS    |
| **Ghostty**  | `ghostty/macchiato` — or use Ghostty's built-in `theme = catppuccin-macchiato`          |
| **Alacritty**| `alacritty/macchiato.toml` — import from your alacritty.toml                            |
| **tmux**     | `catppuccin/tmux` plugin pinned in `tmux/tmux.conf` (auto-installed by TPM on first run)|
| **Starship** | Custom palette declared in `starship/starship.toml`                                     |
| **Neovim**   | `catppuccin/nvim` plugin in `nvim/lua/plugins/colorscheme.lua` (flavour = macchiato)    |
| **FZF**      | `FZF_DEFAULT_OPTS` colors in `zsh/zshrc`                                                |
| **bat**      | Optional: `BAT_THEME=Catppuccin-macchiato` if you install the theme bundle              |

## Macchiato palette (for reference)

```
rosewater #f4dbd6    flamingo  #f0c6c6    pink      #f5bde6
mauve     #c6a0f6    red       #ed8796    maroon    #ee99a0
peach     #f5a97f    yellow    #eed49f    green     #a6da95
teal      #8bd5ca    sky       #91d7e3    sapphire  #7dc4e4
blue      #8aadf4    lavender  #b7bdf8

text      #cad3f4    subtext1  #b8c0e0    subtext0  #a5adcb
overlay2  #939ab7    overlay1  #8087a2    overlay0  #6e738d
surface2  #5b6078    surface1  #494d64    surface0  #363a4f
base      #24273a    mantle    #1e2030    crust     #181926
```

## Manual install (per app)

### iTerm2

The dotfiles installer handles this on macOS automatically — but if you want to do it by hand:

```bash
open ~/.dotfiles/catppuccin/iterm2/Catppuccin-Macchiato.itermcolors
```

Then in iTerm2: **Preferences → Profiles → Colors → Color Presets… → Catppuccin Macchiato**.

### Ghostty

Either drop in a custom theme:

```bash
mkdir -p ~/.config/ghostty/themes
cp ~/.dotfiles/catppuccin/ghostty/macchiato ~/.config/ghostty/themes/
```

…and reference it from `~/.config/ghostty/config`:

```
theme = macchiato
```

…or just use Ghostty's built-in:

```
theme = catppuccin-macchiato
```

### Alacritty

In your `~/.config/alacritty/alacritty.toml`:

```toml
[general]
import = ["~/.dotfiles/catppuccin/alacritty/macchiato.toml"]
```

### Switching to a different flavour

To use Mocha (darker) or Frappé (warmer) instead, swap the plugin spec / palette / flavour value in each of: `tmux.conf`, `starship.toml`, `nvim/lua/plugins/colorscheme.lua`, FZF env var. The palette colors above also have official files in the upstream Catppuccin repos.

## Upstream

- https://github.com/catppuccin/iterm
- https://github.com/catppuccin/tmux
- https://github.com/catppuccin/nvim
- https://github.com/catppuccin/starship
- https://github.com/catppuccin/fzf
- https://github.com/catppuccin/alacritty
- https://github.com/catppuccin/ghostty
