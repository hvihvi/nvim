-- Git integration, installed via the built-in `vim.pack` manager.
--   mini.diff: +/~/- signs in the signcolumn, hunk navigation and staging.
--   mini.git:  :Git command (commit, push, ...) and "show at cursor" (blame).
--   Git pickers (hunks, commits, branches) live in plugins/mini-pick.lua,
--   provided by mini.extra.
--   See `:help mini.diff`, `:help mini.git`.
vim.pack.add({
  { src = 'https://github.com/echasnovski/mini.diff' },
  -- Repo is named mini-git (module is still `mini.git`).
  { src = 'https://github.com/echasnovski/mini-git' },
}, { confirm = false })

local diff = require 'mini.diff'

diff.setup {
  -- Force classic +/~/- signs; the default would highlight line numbers
  -- instead because 'number' is set.
  view = {
    style = 'sign',
    signs = { add = '+', change = '~', delete = '-' },
  },
  -- Default mappings (listed here as a reminder):
  --   gh  apply (= STAGE) hunk / visual selection
  --   gH  reset hunk / visual selection
  --   gh  hunk textobject (e.g. `dgh` deletes a hunk)
  --   ]h / [h / ]H / [H  jump to next/prev/last/first hunk
}

require('mini.git').setup()

-- Next/prev hunk (in addition to the default ]h / [h)
vim.keymap.set('n', '<leader>gn', function()
  diff.goto_hunk 'next'
end, { desc = '[G]it [N]ext hunk' })
vim.keymap.set('n', '<leader>gN', function()
  diff.goto_hunk 'prev'
end, { desc = '[G]it previous hunk' })

-- Toggle inline diff overlay (word-level diff of the whole buffer)
vim.keymap.set('n', '<leader>go', function()
  diff.toggle_overlay(0)
end, { desc = '[G]it toggle diff [O]verlay' })

-- Show git info (blame, diff) for the line/range under the cursor
vim.keymap.set({ 'n', 'x' }, '<leader>ga', '<Cmd>lua MiniGit.show_at_cursor()<CR>', { desc = '[G]it show [A]t cursor' })
