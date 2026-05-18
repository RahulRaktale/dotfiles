-- Colorscheme override
-- Tokyonight is LazyVim's default; this file is here so you have a single
-- place to swap it out (e.g., catppuccin, gruvbox, kanagawa, ...).

return {
  { "folke/tokyonight.nvim", opts = { style = "moon" } },

  -- Make LazyVim use tokyonight by default
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
