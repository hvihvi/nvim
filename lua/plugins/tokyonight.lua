-- tokyonight colorscheme — full treesitter capture support (the default
-- colorscheme is intentionally muted and leaves most captures uncolored).
vim.pack.add({
  { src = 'https://github.com/folke/tokyonight.nvim' },
}, { confirm = false })

vim.cmd.colorscheme 'tokyonight-night'
