return {
  "neovim/nvim-lspconfig",
  config = function()
    require("lspconfig").lua_ls.setup {}  -- or replace with your desired LSP
  end,
}
