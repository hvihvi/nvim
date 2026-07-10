-- Configuration for Roslyn LSP (Microsoft.CodeAnalysis.LanguageServer) —
-- the same server VS Code's C# extension / C# Dev Kit uses.
--
-- Install: `dotnet tool install -g roslyn-language-server --prerelease`
-- (needs `~/.dotnet/tools` on PATH). For a more frequently-updated build,
-- add `--source https://pkgs.dev.azure.com/azure-public/vside/_packaging/vs-impl/nuget/v3/index.json`.
--
-- Unlike most servers, this one doesn't just open whatever directory it's
-- pointed at: after `initialize` we must explicitly tell it which .sln or
-- .csproj to load via a `solution/open`/`project/open` notification. Without
-- that handshake the server starts but never indexes anything.
local fs = vim.fs

local function refresh_diagnostics(client)
  for buf in pairs(client.attached_buffers) do
    if vim.api.nvim_buf_is_loaded(buf) then
      client:request('textDocument/diagnostic', { textDocument = vim.lsp.util.make_text_document_params(buf) }, nil, buf)
    end
  end
end

return {
  cmd = {
    vim.fn.executable 'Microsoft.CodeAnalysis.LanguageServer' == 1 and 'Microsoft.CodeAnalysis.LanguageServer' or 'roslyn-language-server',
    '--stdio',
  },
  -- Works around a macOS pipe issue when TMPDIR is a symlink (/var -> /private/var).
  cmd_env = {
    TMPDIR = vim.env.TMPDIR and vim.env.TMPDIR ~= '' and vim.fn.resolve(vim.env.TMPDIR) or nil,
  },
  filetypes = { 'cs' },
  root_markers = { '*.sln', '*.slnx', '*.csproj', '.git' },
  -- Diagnostics require opting in to dynamic registration, otherwise they
  -- silently never show up.
  capabilities = { textDocument = { diagnostic = { dynamicRegistration = true } } },
  settings = {
    ['csharp|background_analysis'] = {
      dotnet_analyzer_diagnostics_scope = 'fullSolution',
      dotnet_compiler_diagnostics_scope = 'fullSolution',
    },
  },
  on_init = function(client)
    local root_dir = client.config.root_dir
    for entry, ftype in fs.dir(root_dir) do
      if ftype == 'file' and (vim.endswith(entry, '.sln') or vim.endswith(entry, '.slnx')) then
        client:notify('solution/open', { solution = vim.uri_from_fname(fs.joinpath(root_dir, entry)) })
        return
      end
    end
    local projects = {}
    for entry, ftype in fs.dir(root_dir) do
      if ftype == 'file' and vim.endswith(entry, '.csproj') then
        table.insert(projects, vim.uri_from_fname(fs.joinpath(root_dir, entry)))
      end
    end
    if #projects > 0 then
      client:notify('project/open', { projects = projects })
    end
  end,
  -- The server reports indexing progress separately from `initialize`;
  -- re-request diagnostics once it's actually done analyzing the solution.
  handlers = {
    ['workspace/projectInitializationComplete'] = function(_, _, ctx)
      refresh_diagnostics(assert(vim.lsp.get_client_by_id(ctx.client_id)))
      return vim.NIL
    end,
  },
  on_attach = function(client, bufnr)
    vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave' }, {
      buffer = bufnr,
      callback = function()
        refresh_diagnostics(client)
      end,
    })
  end,
}
