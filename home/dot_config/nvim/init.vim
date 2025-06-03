" Load packer.nvim
lua << EOF
require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'       -- packer manages itself

  use 'nvim-lua/plenary.nvim'
  use 'nvim-telescope/telescope.nvim'
  use 'nvim-treesitter/nvim-treesitter'
  use 'neovim/nvim-lspconfig'
  use 'hrsh7th/nvim-cmp'
  use 'tpope/vim-surround'
  use 'nvim-lualine/lualine.nvim'
end)
EOF

