return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    -- neovim 0.10+ has built-in treesitter, highlighting enabled by default
    -- nvim-treesitter now only manages parser installation
    -- Use :TSInstall <lang> to install parsers
  end,
}
