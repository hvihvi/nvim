-- nvim-treesitter (the `main`-branch rewrite) via vim.pack.
--   `main` only provides parsers + queries: it does NOT auto-install parsers
--   or auto-enable features. We install parsers explicitly and enable
--   highlighting / folding / indentation ourselves with Neovim's core APIs.
--   Requires the tree-sitter CLI (>= 0.26.1) to compile parsers.
--   See `:help vim.treesitter` and the plugin README on the `main` branch.

-- Parsers to keep installed. Adding a new language = add its name here
-- (then `:TSUpdate`/reinstall, or it builds on next plugin update).
local parsers = {
  'lua',
  'luadoc',
  'vim',
  'vimdoc',
  'query',
  'markdown',
  'markdown_inline',
  'bash',
  'json',
  'yaml',
}

-- Build/update parsers whenever vim.pack installs or updates the plugin.
-- Registered BEFORE add() so it also fires on the very first install.
vim.api.nvim_create_autocmd('PackChanged', {
  group = vim.api.nvim_create_augroup('treesitter-build', { clear = true }),
  callback = function(ev)
    local d = ev.data
    if d.spec.name ~= 'nvim-treesitter' then
      return
    end
    if d.kind ~= 'install' and d.kind ~= 'update' then
      return
    end
    -- `install` fires before the plugin is loaded; make its Lua available.
    if not d.active then
      vim.cmd.packadd 'nvim-treesitter'
    end
    require('nvim-treesitter').install(parsers)
  end,
})

vim.pack.add({
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
}, { confirm = false })

-- Open files unfolded even though we use a treesitter foldexpr below.
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99

-- Enable treesitter features for any buffer whose parser is installed.
-- Generic over filetype, so installed languages "just work" with no per-
-- language config. Buffers without a parser are silently skipped.
vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('treesitter-enable', { clear = true }),
  callback = function(args)
    local buf = args.buf
    local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
    if not lang then
      return
    end
    -- Highlighting (errors if the parser isn't installed yet -> skip quietly).
    if not pcall(vim.treesitter.start, buf, lang) then
      return
    end
    -- Folding (window-local, current-buffer scope).
    vim.wo[0][0].foldmethod = 'expr'
    vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    -- Indentation (experimental on `main`).
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})
