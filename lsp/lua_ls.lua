-- Configuration for lua-language-server (LuaLS).
--   Neovim auto-discovers files in `lsp/` on the 'runtimepath' and merges
--   this table when `vim.lsp.enable('lua_ls')` runs (see lua/lsp.lua).
--   See `:help lsp-config` and `:help lsp-new-config`.
return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  -- Workspace root: a project marker, else the git root.
  root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
  settings = {
    Lua = {
      -- Neovim's Lua runtime is LuaJIT.
      runtime = { version = 'LuaJIT' },
      -- Recognize the `vim` global (silences "undefined global" warnings).
      diagnostics = { globals = { 'vim' } },
      -- Expose Neovim's runtime files so `vim.*` API completes and gotos work.
      workspace = {
        library = { vim.env.VIMRUNTIME },
        checkThirdParty = false,
      },
      telemetry = { enable = false },
    },
  },
}
