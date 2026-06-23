-- mini.pick: minimal, fast fuzzy picker (files, grep, buffers, ...)
-- mini.extra: additional pickers built on mini.pick (diagnostics, lsp, git, ...)
--   See `:help mini.pick` and `:help mini.extra`
return {
  'echasnovski/mini.pick',
  version = false, -- track the main branch (latest)
  dependencies = {
    'echasnovski/mini.extra',
  },
  event = 'VeryLazy',
  config = function()
    local pick = require 'mini.pick'
    local extra = require 'mini.extra'

    pick.setup()
    extra.setup()

    -- Route `vim.ui.select` (LSP code actions, etc.) through mini.pick
    vim.ui.select = pick.ui_select

    local map = function(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { desc = desc })
    end

    -- Core pickers (mini.pick)
    map('<leader>ff', pick.builtin.files, '[F]ind [F]iles')
    map('<leader>fg', pick.builtin.grep_live, '[F]ind by [G]rep (live)')
    map('<leader>fb', pick.builtin.buffers, '[F]ind [B]uffers')
    map('<leader>fh', pick.builtin.help, '[F]ind [H]elp')
    map('<leader>fr', pick.builtin.resume, '[F]ind [R]esume last picker')

    -- Extra pickers (mini.extra)
    map('<leader>fd', extra.pickers.diagnostic, '[F]ind [D]iagnostics')
    map('<leader>fo', extra.pickers.oldfiles, '[F]ind [O]ld files')
    map('<leader>fk', extra.pickers.keymaps, '[F]ind [K]eymaps')
    map('<leader>fw', function()
      extra.pickers.grep { pattern = vim.fn.expand '<cword>' }
    end, '[F]ind current [W]ord')
    map('<leader>f/', function()
      extra.pickers.buf_lines { scope = 'current' }
    end, '[F]ind in current buffer (/)')
  end,
}
