# Neovim config

A modern, minimal Neovim configuration built on **native Neovim features**:

- **Plugins** — managed by the built-in [`vim.pack`](https://neovim.io/doc/user/pack.html) (no external plugin manager).
- **LSP** — the native `vim.lsp` API (`vim.lsp.config` / `vim.lsp.enable`), no `nvim-lspconfig`.
- **Picker** — [`mini.pick`](https://github.com/echasnovski/mini.nvim) (+ `mini.extra`, `mini.icons`).
- **Treesitter** — [`nvim-treesitter`](https://github.com/nvim-treesitter/nvim-treesitter) `main`-branch rewrite, with highlighting/folding/indent and a native incremental-selection reimplementation.

## Requirements

- **Neovim ≥ 0.12** — `vim.pack` and the treesitter `main` branch both require it.
  ```sh
  nvim --version   # must report 0.12.0 or later
  ```

## Dependencies

Install these **before** the first launch (commands shown for macOS / Homebrew):

| Tool | Needed for | Install (macOS) |
|------|-----------|-----------------|
| `git` | `vim.pack` clones plugins | preinstalled / `brew install git` |
| `ripgrep` (`rg`) | mini.pick grep & file finding | `brew install ripgrep` |
| `lua-language-server` | Lua LSP | `brew install lua-language-server` |
| **tree-sitter CLI ≥ 0.26.1** | compiling treesitter parsers | `npm install -g tree-sitter-cli` |
| C compiler (`cc`/clang) | compiling treesitter parsers | Xcode Command Line Tools (`xcode-select --install`) |
| `node` | tree-sitter CLI / some grammars | `brew install node` |
| `fd` | *optional* — faster file finding | `brew install fd` |
| A **Nerd Font** (terminal) | file icons (mini.icons) | `brew install --cask font-jetbrains-mono-nerd-font` |

> **tree-sitter CLI note:** Homebrew's `tree-sitter` formula ships only the
> *library*, not the CLI. Install the CLI via `npm` (above) or
> `cargo install tree-sitter-cli`. The treesitter `main` branch needs it to
> build parsers.

> **Linux note:** install the equivalents with your package manager. The
> `clipboard = 'unnamedplus'` setting also needs a clipboard provider there
> (`xclip` or `wl-clipboard`); on macOS this works out of the box.

> **Nerd Font:** after installing, set it as your **terminal's** font — Neovim
> can't pick it on its own. Without it, icons render as boxes/`?`.

## Install

```sh
git clone <this-repo> ~/.config/nvim
nvim
```

That's it. On first launch:

1. **`vim.pack` auto-installs** all plugins (mini.pick/extra/icons,
   nvim-treesitter) — no prompt. Plugin revisions are pinned in
   `nvim-pack-lock.json`.
2. **Treesitter parsers compile** in the background (via the tree-sitter CLI).
   You'll see progress messages. If a file isn't highlighted on the very first
   open, reopen it once the build finishes.
3. **lua_ls** attaches automatically when you open a `.lua` file. It takes a few
   seconds to warm up (it preloads the runtime library) before completion works.

## Maintenance

- **Update plugins:** `:lua vim.pack.update()` → review the confirmation buffer,
  `:w` to apply or `:q` to cancel.
- **Update parsers:** `:lua require('nvim-treesitter').install(...)` or `:TSUpdate`.
- **Add a plugin:** create `lua/plugins/<name>.lua` that calls `vim.pack.add{...}`
  and configures it, then `require` it in `init.lua`.
- **Add a treesitter language:** add its name to the `parsers` list in
  `lua/plugins/treesitter.lua`, then `:lua require('nvim-treesitter').install({'<lang>'})`.
- **Add a language server:** install its binary, drop a `lsp/<name>.lua` config
  file, and add `vim.lsp.enable('<name>')` in `lua/lsp.lua`.

## Godot / GDScript

GDScript support is built in (LSP + treesitter + external-editor integration).
The LSP server is **hosted by the Godot editor**, so it only works while Godot
is open with your project.

**One-time Godot setup** (Editor → Editor Settings):

1. **Network → Language Server** — note the port (default `6005`) and enable
   **Use Thread** (prevents the LSP from dropping when opening files).
2. **Text Editor → External**:
   - *Use External Editor*: **on**
   - *Exec Path*: path to your `nvim` binary (e.g. `/opt/homebrew/bin/nvim`)
   - *Exec Flags*:
     ```
     --server {project}/server.pipe --remote-send "<C-\><C-N>:e {file}<CR>:call cursor({line}+1,{col})<CR>"
     ```

**Usage:** launch `nvim` from inside the project directory (it auto-listens on
`<project>/server.pipe`), keep the Godot editor open, and open `.gd` files.
Clicking a script in Godot opens it in that running Neovim at the right line.

> If completion/diagnostics don't appear: confirm Godot is running, the port
> matches (`GDScript_Port` env var overrides it), and you launched nvim from
> within the project (so `project.godot` is found and the LSP root resolves).

## Layout

```
init.lua                 options, keymaps, autocmds; requires the modules below
lua/lsp.lua              native LSP: enable servers + on-attach behavior
lua/plugins/             one file per plugin (each calls vim.pack.add)
  mini-pick.lua          fuzzy picker (+ extra pickers, icons)
  treesitter.lua         nvim-treesitter (main) + incremental selection
lsp/                     per-server LSP config files (auto-discovered)
  lua_ls.lua             lua-language-server config
nvim-pack-lock.json      vim.pack lockfile (pinned plugin revisions)
```

## Key bindings

Leader is `<Space>`.

| Key | Action |
|-----|--------|
| `<leader>ff` / `fg` / `fb` | find files / live grep / buffers |
| `<leader>fh` / `fr` | help / resume last picker |
| `<leader>e` / `<leader>sa` | recent files / live grep all files |
| `<leader>fé` / `fo` / `fk` | diagnostics / old files / keymaps |
| `<leader>fw` / `f/` | grep word under cursor / lines in buffer |
| `<leader>fd` / `<leader>fu` | goto definition (like `gd`) / find usages (references) |
| `<leader>z`, then `k` / `j` (visual) | incremental selection: start, expand, shrink |
| `<C-n>` / `<C-p>` (visual) | move down / up (since `j`/`k` are taken) |
| `gd` / `gD`, `K`, `grn`, `gra`, `grr` | LSP: definition / declaration, hover, rename, code action, references |
| `<C-Space>` (insert) | trigger LSP completion |

In a picker: `<Tab>` toggles a live preview, `<CR>` opens, `<C-v>`/`<C-s>`/`<C-t>` open in vsplit/split/tab.
