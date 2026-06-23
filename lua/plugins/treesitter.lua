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

-- [[ Incremental selection ]]
--   Recreated natively (removed from nvim-treesitter `main`):
--     <leader>z  start selection at the node under the cursor (normal mode)
--     k          expand selection to the parent node (visual mode)
--     j          shrink selection back to the previous node (visual mode)
--   j/k are remapped in visual mode; use <C-n>/<C-p> (or arrows) for plain
--   vertical movement while in visual mode.
do
  local stacks = {} -- bufnr -> list of {srow, scol, erow, ecol} (0-indexed, inclusive)

  local function cur_buf()
    return vim.api.nvim_get_current_buf()
  end

  -- Current charwise visual selection as a normalized inclusive 0-indexed range.
  local function visual_range()
    local s, e = vim.fn.getpos 'v', vim.fn.getpos '.'
    local sr, sc, er, ec = s[2] - 1, s[3] - 1, e[2] - 1, e[3] - 1
    if sr > er or (sr == er and sc > ec) then
      sr, sc, er, ec = er, ec, sr, sc
    end
    return { sr, sc, er, ec }
  end

  -- Clamp a 0-indexed column to a valid cursor position on the given row.
  local function clamp_col(row, col)
    local line = vim.api.nvim_buf_get_lines(0, row, row + 1, true)[1] or ''
    return math.max(0, math.min(col, math.max(#line - 1, 0)))
  end

  -- Reselect a charwise range (0-indexed, inclusive end).
  local function set_selection(r)
    -- Leave any current visual mode so `v` sets a fresh anchor.
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'nx', false)
    vim.api.nvim_win_set_cursor(0, { r[1] + 1, clamp_col(r[1], r[2]) })
    vim.cmd 'normal! v'
    vim.api.nvim_win_set_cursor(0, { r[3] + 1, clamp_col(r[3], r[4]) })
  end

  local function same(a, b)
    return a and b and a[1] == b[1] and a[2] == b[2] and a[3] == b[3] and a[4] == b[4]
  end

  -- Inclusive 0-indexed range of a node.
  local function node_range(node)
    local sr, sc, er, ec = node:range()
    -- Treesitter reports an end of (row, 0) one line past multiline content;
    -- pull it back to the end of the previous line.
    if ec == 0 and er > sr then
      er = er - 1
      ec = #(vim.api.nvim_buf_get_lines(0, er, er + 1, true)[1] or '')
    end
    return { sr, sc, er, ec > 0 and ec - 1 or 0 }
  end

  -- Smallest named node strictly larger than the given inclusive range.
  local function expand_node(range)
    local ok, parser = pcall(vim.treesitter.get_parser)
    if not ok or not parser then
      return nil
    end
    local tree = parser:parse()[1]
    if not tree then
      return nil
    end
    local node = tree:root():named_descendant_for_range(range[1], range[2], range[3], range[4])
    while node and same(node_range(node), range) do
      node = node:parent()
    end
    return node
  end

  local function init_selection()
    local node = vim.treesitter.get_node()
    if not node then
      return
    end
    local r = node_range(node)
    stacks[cur_buf()] = { r }
    set_selection(r)
  end

  local function node_incremental()
    local cur = visual_range()
    local st = stacks[cur_buf()]
    -- Fresh session if the stack is stale (selection moved since last time).
    if not st or not same(st[#st], cur) then
      st = { cur }
      stacks[cur_buf()] = st
    end
    local node = expand_node(cur)
    if not node then
      return
    end
    local r = node_range(node)
    table.insert(st, r)
    set_selection(r)
  end

  local function node_decremental()
    local st = stacks[cur_buf()]
    if not st or #st <= 1 then
      return
    end
    if not same(st[#st], visual_range()) then
      return
    end
    table.remove(st)
    set_selection(st[#st])
  end

  vim.keymap.set('n', '<leader>z', init_selection, { desc = 'Treesitter: start incremental selection' })
  vim.keymap.set('x', 'k', node_incremental, { desc = 'Treesitter: expand selection to parent node' })
  vim.keymap.set('x', 'j', node_decremental, { desc = 'Treesitter: shrink selection to child node' })
  -- Keep plain vertical movement in visual mode (since j/k are taken).
  vim.keymap.set('x', '<C-n>', 'j', { desc = 'Visual: move down' })
  vim.keymap.set('x', '<C-p>', 'k', { desc = 'Visual: move up' })
end
