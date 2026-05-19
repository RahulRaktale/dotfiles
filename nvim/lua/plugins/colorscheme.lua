-- Colorscheme: Catppuccin Macchiato
-- Swap `flavour` to mocha / frappe / latte to switch variants without
-- changing anything else. tokyonight is kept installed as a fallback.

return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    opts = {
      flavour = "macchiato", -- latte, frappe, macchiato, mocha
      background = {
        light = "latte",
        dark = "macchiato",
      },
      transparent_background = false,
      show_end_of_buffer = false,
      term_colors = true,
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = false,
        mini = {
          enabled = true,
          indentscope_color = "",
        },
        telescope = { enabled = true },
        which_key = true,
        mason = true,
        markdown = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        dap = { enabled = true, enable_ui = true },
      },
    },
  },

  -- Kept around as a fallback colorscheme; LazyVim's defaults expect it.
  { "folke/tokyonight.nvim", lazy = true, opts = { style = "moon" } },

  -- Tell LazyVim to use Catppuccin by default.
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-macchiato",
    },
  },
}
