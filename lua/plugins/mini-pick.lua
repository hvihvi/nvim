-- mini.pick + mini.extra, installed via the built-in `vim.pack` manager.
--   mini.pick: minimal, fast fuzzy picker (files, grep, buffers, ...)
--   mini.extra: extra pickers built on mini.pick (diagnostics, oldfiles, ...)
--   mini.icons: file/folder icons used by mini.pick (needs a Nerd Font).
--   See `:help mini.pick`, `:help mini.extra`, `:help mini.icons`.

-- Install (blobless clone on first run) and add to runtimepath.
-- `confirm = false` installs without the interactive confirmation prompt.
vim.pack.add({
  { src = 'https://github.com/echasnovski/mini.pick' },
  { src = 'https://github.com/echasnovski/mini.extra' },
  { src = 'https://github.com/echasnovski/mini.icons' },
}, { confirm = false })

-- Icons must be set up before the picker shows items so it can pick them up.
require('mini.icons').setup()

local pick = require 'mini.pick'
local extra = require 'mini.extra'

-- Center the picker window (golden-ratio sized) with a rounded border, rather
-- than the small default in the top-left corner.
local function win_config()
  local height = math.floor(0.618 * vim.o.lines)
  local width = math.floor(0.618 * vim.o.columns)
  return {
    anchor = 'NW',
    height = height,
    width = width,
    row = math.floor(0.5 * (vim.o.lines - height)),
    col = math.floor(0.5 * (vim.o.columns - width)),
  }
end

pick.setup {
  window = { config = win_config },
}
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

-- Convenience aliases outside the <leader>f group
map('<leader>e', extra.pickers.oldfiles, 'Recent files (oldfiles)')
map('<leader>sa', pick.builtin.grep_live, '[S]earch [A]ll files (live grep)')

-- Extra pickers (mini.extra)
map('<leader>fé', extra.pickers.diagnostic, 'Find diagnostics')
map('<leader>fo', extra.pickers.oldfiles, '[F]ind [O]ld files')
map('<leader>fk', extra.pickers.keymaps, '[F]ind [K]eymaps')
map('<leader>fw', function()
  extra.pickers.grep { pattern = vim.fn.expand '<cword>' }
end, '[F]ind current [W]ord')
map('<leader>f/', function()
  extra.pickers.buf_lines { scope = 'current' }
end, '[F]ind in current buffer (/)')
