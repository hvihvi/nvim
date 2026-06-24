-- Configuration for the GDScript language server.
--   Unlike most servers, this one is hosted by the *running Godot editor*: we
--   connect to it over TCP (default 127.0.0.1:6005) rather than spawning it.
--   => The Godot editor must be open with the project for LSP to work.
--   Port is configurable via the GDScript_Port env var or Godot's settings.
--   See `:help lsp-config`.
local port = os.getenv 'GDScript_Port' or '6005'
return {
  cmd = vim.lsp.rpc.connect('127.0.0.1', tonumber(port)),
  filetypes = { 'gdscript' },
  root_markers = { 'project.godot', '.git' },
}
