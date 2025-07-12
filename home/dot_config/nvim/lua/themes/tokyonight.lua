return {
  "folke/tokyonight.nvim",
  priority = 1000, -- Ensure it's loaded before other UI plugins
  lazy = false,    -- Load immediately
  config = function()
    vim.cmd.colorscheme("tokyonight-storm") -- Options: night, storm, day, moon
  end,
}

