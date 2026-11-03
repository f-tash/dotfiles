# AGENTS.md

Personal dotfiles managed with Nix home-manager (standalone, flakes-based).

## Layout

```
flake.nix              Flake inputs (nixpkgs, home-manager, herdr) and outputs.
flake.lock             Locked input versions. Committed.
home.nix               Home-manager config: packages + dotfile links.
codex/config.toml      Managed ChatGPT/Codex app settings, merged on activation.
scripts/merge-toml.nix Nix-based TOML merge, applied to a writable config file.
nvim/init.lua          Neovim core config and feature wiring (kickstart.nvim base).
nvim/lua/config/       Shared plugin setup (currently Snacks).
nvim/lua/features/search/ Search keymaps and feature-local Snacks adapter.
nvim/lua/features/git/ Git feature: plugins, keymaps, actions, logic, and adapters.
shell/                 zsh startup files, linked to ~/.zprofile, ~/.zshrc
                       and ~/.config/shell/.
herdr/config.toml      Herdr keybindings, linked to ~/.config/herdr/.
karabiner.json         Karabiner-Elements config.
private.nix.example    Template for the optional private slot. Committed.
private.nix            Optional private overlay. **gitignored**, never commit.
commit.sh / push.sh    Tiny git helpers — `git add -A && git commit -m update`, `git push`.
.gitignore             Excludes private.nix.
```

## Applying changes

After editing `home.nix`, `nvim/`, or anything else linked from home.nix
(`shell/*`, `herdr/config.toml`, `karabiner.json`):

```sh
./apply.sh   # = nix run home-manager/master -- switch --flake .#default --impure
```

**New files must be `git add`-ed before applying.** Nix's git filter hides untracked
files from the flake evaluator, so an unstaged new file fails the build with a
missing-path error. (`apply.sh` already stages `local.nix` and `private.nix` for you,
and restores git state on exit.)

This rebuilds the home-manager generation and refreshes symlinks under `~/`.
`nvim/init.lua`, `nvim/lua/config/`, and `nvim/lua/features/` are linked into `~/.config/nvim/`.
Only these sources are managed; `nvim-pack-lock.json`, plugin state, and other Lua modules stay writable.

## ChatGPT / Codex app

`codex/config.toml` contains the keys managed in `~/.codex/config.toml`.
Home-manager activation (including `./apply.sh`) merges these keys into the
existing file, or creates it if missing. The destination stays a regular writable
file, not a Nix store symlink. Unmanaged keys are preserved. When values change,
the TOML is regenerated, so comments and original formatting are not preserved.
Removing a key from the repo stops managing it; it does not delete the live key.

The managed settings currently include the dark appearance and its full theme,
with `UDEVGothic35NF-Bold` for code and `UDEVGothic35-Bold` for the UI. The NF
variant includes Nerd Fonts glyphs for Neovim file icons in the terminal.
Complete theme fields are needed for the app to accept a newly created theme.
`pkgs.udev-gothic` and `pkgs.udev-gothic-nf` in `home.packages` install both fonts.
Keep credentials and machine-specific settings out of this file.

The merge uses `builtins.fromTOML` and `lib.recursiveUpdate` at activation time.
Nix emits JSON, and nixpkgs' `remarshal` converts it back to TOML. Live settings
are kept out of the Nix store. Invalid TOML or a symlink destination fails without
overwriting it. A semantically unchanged config is not rewritten, and
home-manager dry runs skip the merge.

## Private overlay

`flake.nix` conditionally includes `./private.nix` if the file exists:

```nix
privateModules =
  if builtins.pathExists ./private.nix
  then [ ./private.nix ]
  else [ ];
```

Without `private.nix`, the public modules apply on their own — no error, no degradation. To enable private settings on a machine, copy `private.nix.example` to `private.nix` and fill in the source.

**Hard rule:** the private repository URL must never appear in any file committed to this repo. The example uses an obviously-fake `git.example.com/...` placeholder. Do not replace it with a plausible-looking URL even in comments; use `example.com` / `.example` TLDs only.

## Neovim

Base is upstream `nvim-lua/kickstart.nvim`. Core options and remaining plugin setup stay in `init.lua`; shared Snacks setup lives in `lua/config/plugins/snacks.lua`. Search and Git behavior live in their own `lua/features/` directories, with adapters kept inside each feature. It uses Neovim 0.12's built-in `vim.pack` package manager — no lazy.nvim. Plugins are declared with `vim.pack.add` in their setup modules; Git-only dependencies live in `features/git/plugins.lua`.

Customizations added on top of kickstart:
- `vim.g.have_nerd_font = true` enables Nerd Fonts icons, including `mini.icons`.
- **`snacks.nvim`** (folke/snacks.nvim) is the **only fuzzy finder** — Telescope was removed. `lua/config/plugins/snacks.lua` installs Snacks and configures its picker, explorer, scrolling, indent guides, and `vim.ui.select`. The explorer uses the centered floating `vertical` layout with preview hidden; it closes after opening a file or leaving the picker. SECTION 11 loads this shared setup before the search and Git features.
- **Search feature** lives in `lua/features/search/`: `keymaps.lua` assigns keys, `adapters/snacks.lua` calls the plugin, and `init.lua` connects them. Each action opens one picker, so it needs no separate workflow layer. It includes the explorer (`<leader>e`), kickstart-compatible `<leader>s*` pickers, LazyVim-style `<leader>f*` aliases, and LSP `grr`/`gri`/`grd`/`grt`/`gO`/`gW` pickers (set globally, not on `LspAttach`).
- **Test files are hidden from pickers** by default; `T` (or `<a-t>` while typing) toggles them. This filter and its picker-internal keys live in the shared Snacks setup, so they apply to both search and Git. files/grep/explorer use Snacks' native `exclude` globs; other sources are filtered per item with `transform`; `git_diff` is left alone so diff hunks survive. Note the globs are `*test*`/`*Test*`, so a name like `latest.lua` is also hidden.
- **`lualine.nvim`** replaces `mini.statusline` (`globalstatus = true`, tokyonight theme with `lualine_bold`).
- **`diffview.nvim`** (+ `nvim-lua/plenary.nvim`, which used to arrive with Telescope) for `:DiffviewOpen` / `:DiffviewFileHistory`.
- **Git feature** is loaded with `require('features.git').setup()` after shared Snacks setup. Everything Git-specific is under `lua/features/git/`: `plugins.lua` installs/configures Gitsigns and Diffview; `keymaps.lua` binds keys to actions; `actions.lua` owns workflow and session state; `logic.lua` handles branch ordering, diff parsing, and file tree construction without Neovim APIs; `adapters/repository.lua` runs Git; `adapters/view.lua` handles Snacks, Gitsigns, Diffview, and editor UI. `init.lua` injects adapters into the actions and keeps one instance per session. Actions depend only on the pure logic and supplied operations; they never import adapters or plugin APIs. Keys: `<leader>gB` selects the base, `gb` lists branch changes, `gt` shows them as a floating tree, `gv` opens Diffview, `gq` closes it, `gs` lists uncommitted changes, `gl` shows read-only line history, `tb` toggles the gutter's diff base, and `gg` opens Lazygit. All use the space leader.
- **Git branch tree** (`<leader>gt`) uses the same merge-base diff source as `gb`, including committed and uncommitted tracked changes. It is a directory-first tree of changed paths, not a filesystem explorer; deleted files remain visible and untracked files are not included. Enter toggles directories or opens the selected file's hunks; Esc from hunks returns to the tree. Searching preserves matching files' parent directories. The tree has no stage/restore bindings.
- **`noice.nvim`** (folke/noice.nvim, dep `MunifTanjim/nui.nvim`) renders the `:` command-line as a centered floating popup. Only cmdline/popupmenu are enabled; messages stay in the default area.
- **`pkgs.tree-sitter`** in `home.packages` — required by nvim-treesitter `main` branch to build parsers.
- **`pkgs.lazygit`** in `home.packages` — invoked via `Snacks.lazygit()`.

## Shell

`shell/` is linked out by `home.nix`:

| Repo file | Linked to | Role |
|---|---|---|
| `shell/zprofile` | `~/.zprofile` | brew, `env.sh`, python@3.13 (if present), OrbStack. |
| `shell/zshrc` | `~/.zshrc` | compinit, sheldon, mise, uv, fzf, zoxide, direnv, starship, aliases. |
| `shell/aliases.zsh` | `~/.config/shell/aliases.zsh` | `cl`/`cr`/`n`/`h`/`md` and the `y` yazi wrapper. |
| `shell/herdr.zsh` | `~/.config/shell/herdr.zsh` | `h13` / `h23` pane layouts. |

Not managed here: `~/.config/shell/env.sh` (predates this repo) and `~/.zshrc.local`
(machine-specific, untracked). There is no `~/.zshenv`.

## Herdr

`herdr/config.toml` only overrides `[keys]` (all `ctrl+option+*`) and
`[experimental] pane_history = false`; everything else stays at herdr's defaults.
`herdr config check` validates the file and reports unknown sections.

Caps Lock is mapped to Control+Option in `karabiner.json`. Karabiner leaves
`Ctrl+hjkl` and `Ctrl+Option+hjkl` unchanged, so Neovim split navigation and
Herdr pane navigation receive their respective bindings.

There is currently no plugin lockfile in this repo (`lazy-lock.json` is not used because `vim.pack` manages versions internally; pin via `version = '...'` in the `vim.pack.add` call if reproducibility matters).


## Conventions

- **Code comments are in English** (this file and conversation may be in Japanese, but anything inside `.nix`, `.lua`, `.sh`, etc. is English).
- **Commit messages**: trivial `update` (or `init` for the root commit). Use `commit.sh`. This is a personal repo — no need for descriptive messages.
- **Placeholder URLs**: only `example.com` / `.example` TLDs. Never `OWNER/REPO`, `your-user/your-repo`, or any string that could be a real path.
- **Don't auto-run git**: leave `git init` / `commit` / `push` / `gh repo create` to the human, unless they explicitly ask in the current turn. The helper scripts (`commit.sh`, `push.sh`) exist so the human can run them from the shell.

## Useful one-liners

```sh
# Apply current config
./apply.sh   # = nix run home-manager/master -- switch --flake .#default

# Update flake inputs (nixpkgs, home-manager)
nix flake update

# See current home-manager generation state
ls -la ~/.local/state/nix/profiles/

# Check vim.pack-installed nvim plugins
nvim --headless -c 'lua vim.print(vim.pack.get())' -c 'qa'
```
