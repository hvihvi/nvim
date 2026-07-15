-- Native LSP setup (Neovim 0.11+) — no nvim-lspconfig framework.
--   Server configs live in `lsp/<name>.lua` (auto-discovered on 'runtimepath').
--   Here we enable the servers and wire up buffer-local behavior on attach.
--   See `:help lsp-config`, `:help lsp-attach`, `:help lsp-defaults`.

-- Enable language servers (config comes from the matching lsp/<name>.lua).
vim.lsp.enable 'lua_ls'
-- gdscript connects to a running Godot editor (no-op outside Godot projects /
-- when Godot isn't running, so it's safe to always enable).
vim.lsp.enable 'gdscript'
vim.lsp.enable 'roslyn_ls'

-- Diagnostics (global, not LSP-specific).
--   <leader>éé shows the full message for the diagnostic under the cursor
--   (same as the built-in <C-w>d). See also <leader>fé (diagnostics picker).
vim.keymap.set('n', '<leader>éé', vim.diagnostic.open_float, { desc = '[É]rror: show message (float)' })

-- Goto definition, unless the cursor is already on the definition — then show
-- usages instead (same as <leader>fu). The `on_list` hook only collects the
-- locations (no jump), so we can inspect them: cursor inside one of the
-- returned ranges means we're already at the definition -> references picker;
-- otherwise re-run the plain goto-definition to keep the default jump
-- behavior (tagstack, multiple-results list, ...).
local function definition_or_usages()
  local fname = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
  local row, col = unpack(vim.api.nvim_win_get_cursor(0)) -- row 1-based, col 0-based

  -- Cursor inside this loclist item's range? (lnum/col 1-based; end_* may be
  -- 0/absent for servers that return bare positions -> fall back to the line.)
  local function cursor_inside(item)
    if vim.fs.normalize(item.filename) ~= fname then
      return false
    end
    local end_lnum = (item.end_lnum and item.end_lnum > 0) and item.end_lnum or item.lnum
    if row < item.lnum or row > end_lnum then
      return false
    end
    if row == item.lnum and col + 1 < item.col then
      return false
    end
    if row == end_lnum and item.end_col and item.end_col > 0 and col + 1 > item.end_col then
      return false
    end
    return true
  end

  vim.lsp.buf.definition {
    on_list = function(t)
      for _, item in ipairs(t.items or {}) do
        if cursor_inside(item) then
          require('mini.extra').pickers.lsp { scope = 'references' }
          return
        end
      end
      vim.lsp.buf.definition()
    end,
  }
end

-- Buffer-local setup when any language server attaches.
--   Note: Nvim already provides default LSP keymaps when a server attaches:
--   K (hover), grn (rename), gra (code action), grr (references),
--   gri (implementation), grt (type definition), gO (document symbols),
--   [d / ]d (prev/next diagnostic). We only add what's missing.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('my-lsp-attach', { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local bufnr = args.buf

    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = bufnr, desc = 'LSP: [G]oto [D]eclaration' })
    -- gd / <leader>fd / <C-f>: goto definition; when the cursor is already on
    -- the definition, show usages instead (same as <leader>fu).
    for _, lhs in ipairs { 'gd', '<leader>fd', '<C-f>' } do
      vim.keymap.set('n', lhs, definition_or_usages, { buffer = bufnr, desc = 'LSP: goto definition (usages if already there)' })
    end
    -- <leader>rn: rename symbol (same as the built-in grn).
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { buffer = bufnr, desc = 'LSP: [R]e[n]ame symbol (like grn)' })
    -- <leader>fu: find usages (all references) as a filterable picker.
    vim.keymap.set('n', '<leader>fu', function()
      require('mini.extra').pickers.lsp { scope = 'references' }
    end, { buffer = bufnr, desc = 'LSP: find usages (references)' })

    -- Native LSP completion (Neovim 0.11+). No autotrigger: the menu only
    -- appears on demand. Trigger it with <C-Space> in insert mode.
    if client and client:supports_method 'textDocument/completion' then
      vim.lsp.completion.enable(true, client.id, bufnr)
      vim.keymap.set('i', '<C-Space>', vim.lsp.completion.get, { buffer = bufnr, desc = 'LSP: trigger completion' })
    end

    -- Inlay hints, when the server provides them.
    if client and client:supports_method 'textDocument/inlayHint' then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end
  end,
})
