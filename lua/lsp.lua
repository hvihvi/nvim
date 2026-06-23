-- Native LSP setup (Neovim 0.11+) — no nvim-lspconfig framework.
--   Server configs live in `lsp/<name>.lua` (auto-discovered on 'runtimepath').
--   Here we enable the servers and wire up buffer-local behavior on attach.
--   See `:help lsp-config`, `:help lsp-attach`, `:help lsp-defaults`.

-- Enable language servers (config comes from the matching lsp/<name>.lua).
vim.lsp.enable 'lua_ls'

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

    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr, desc = 'LSP: [G]oto [D]efinition' })
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { buffer = bufnr, desc = 'LSP: [G]oto [D]eclaration' })

    -- Native LSP autocompletion (Neovim 0.11+), triggered as you type.
    if client and client:supports_method 'textDocument/completion' then
      vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
    end

    -- Inlay hints, when the server provides them.
    if client and client:supports_method 'textDocument/inlayHint' then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
    end
  end,
})
