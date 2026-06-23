-- snacks.nvim picker: modern, pure-Lua fuzzy picker (folke).
--   Keymaps intentionally mirror the mini.pick setup (commit 5166d7c) so the
--   two can be compared apples-to-apples under the same <leader>f bindings.
--   See `:help snacks-picker`.
return {
  'folke/snacks.nvim',
  priority = 1000,
  event = 'VeryLazy',
  opts = {
    picker = { enabled = true },
  },
  config = function(_, opts)
    local snacks = require 'snacks'
    snacks.setup(opts)

    local picker = snacks.picker

    -- Route `vim.ui.select` (LSP code actions, etc.) through snacks
    vim.ui.select = picker.select

    local map = function(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { desc = desc })
    end

    -- Core pickers
    map('<leader>ff', picker.files, '[F]ind [F]iles')
    map('<leader>fg', picker.grep, '[F]ind by [G]rep (live)')
    map('<leader>fb', picker.buffers, '[F]ind [B]uffers')
    map('<leader>fh', picker.help, '[F]ind [H]elp')
    map('<leader>fr', picker.resume, '[F]ind [R]esume last picker')

    -- Extra pickers
    map('<leader>fd', picker.diagnostics, '[F]ind [D]iagnostics')
    map('<leader>fo', picker.recent, '[F]ind [O]ld files')
    map('<leader>fk', picker.keymaps, '[F]ind [K]eymaps')
    map('<leader>fw', picker.grep_word, '[F]ind current [W]ord')
    map('<leader>f/', picker.lines, '[F]ind in current buffer (/)')
  end,
}
