-- mini.clue: shows available keybindings in a popup after a "trigger" key
--   (which-key style). It automatically uses the `desc` of existing keymaps,
--   so every mapping we set with a description shows up here.
--   See `:help mini.clue`.
vim.pack.add({
  { src = 'https://github.com/echasnovski/mini.clue' },
}, { confirm = false })

local clue = require 'mini.clue'

clue.setup {
  -- Prefix keys after which the clue window should appear.
  triggers = {
    -- Leader (normal + visual)
    { mode = 'n', keys = '<Leader>' },
    { mode = 'x', keys = '<Leader>' },

    -- `g` and `z` prefixes
    { mode = 'n', keys = 'g' },
    { mode = 'x', keys = 'g' },
    { mode = 'n', keys = 'z' },
    { mode = 'x', keys = 'z' },

    -- Marks
    { mode = 'n', keys = "'" },
    { mode = 'n', keys = '`' },
    { mode = 'x', keys = "'" },
    { mode = 'x', keys = '`' },

    -- Registers
    { mode = 'n', keys = '"' },
    { mode = 'x', keys = '"' },
    { mode = 'i', keys = '<C-r>' },
    { mode = 'c', keys = '<C-r>' },

    -- Window commands
    { mode = 'n', keys = '<C-w>' },

    -- Built-in completion submodes
    { mode = 'i', keys = '<C-x>' },

    -- Bracket motions (e.g. [d / ]d diagnostics)
    { mode = 'n', keys = '[' },
    { mode = 'n', keys = ']' },
  },

  -- Descriptions for built-in key groups.
  clues = {
    clue.gen_clues.builtin_completion(),
    clue.gen_clues.g(),
    clue.gen_clues.marks(),
    clue.gen_clues.registers(),
    clue.gen_clues.windows(),
    clue.gen_clues.z(),
  },

  -- Show the window fairly quickly (matches the small timeoutlen).
  window = { delay = 200 },
}
