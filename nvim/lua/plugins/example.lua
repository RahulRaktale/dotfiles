-- Example: how to add / override / disable plugins in LazyVim.
-- Delete or edit this file as you customize your setup.
-- Docs: https://www.lazyvim.org/configuration/plugins

return {
  -- Example 1: add a new plugin
  -- {
  --   "echasnovski/mini.surround",
  --   keys = { "sa", "sd", "sr" },
  --   opts = {},
  -- },

  -- Example 2: override a LazyVim plugin's options
  -- {
  --   "nvim-telescope/telescope.nvim",
  --   keys = {
  --     { "<leader>fp", function() require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find config files" },
  --   },
  -- },

  -- Example 3: disable a LazyVim plugin
  -- { "akinsho/bufferline.nvim", enabled = false },
}
