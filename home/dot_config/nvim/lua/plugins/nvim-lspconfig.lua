return {
  "neovim/nvim-lspconfig",
  config = function()
    -- neovim 0.11+ uses vim.lsp.config instead of require("lspconfig")
    vim.lsp.config("lua_ls", {})
    vim.lsp.enable("lua_ls")
  end,
}
