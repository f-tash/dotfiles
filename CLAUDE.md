# CLAUDE.md

Personal dotfiles managed with Nix home-manager (standalone, flakes-based).

## Layout

```
flake.nix              Flake inputs (nixpkgs, home-manager, herdr) and outputs.
flake.lock             Locked input versions. Committed.
home.nix               Home-manager config: packages + dotfile links.
nvim/init.lua          Neovim config (kickstart.nvim base + customizations).
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

After editing `home.nix`, `nvim/init.lua`, or anything else linked from home.nix
(`shell/*`, `herdr/config.toml`, `karabiner.json`):

```sh
./apply.sh   # = nix run home-manager/master -- switch --flake .#default --impure
```

**New files must be `git add`-ed before applying.** Nix's git filter hides untracked
files from the flake evaluator, so an unstaged new file fails the build with a
missing-path error. (`apply.sh` already stages `local.nix` and `private.nix` for you,
and restores git state on exit.)

This rebuilds the home-manager generation and refreshes symlinks under `~/`.
`nvim/init.lua` is linked to `~/.config/nvim/init.lua`; everything else in `~/.config/nvim/` (e.g. `lazy-lock.json`, plugin state) stays writable.

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

Base is upstream `nvim-lua/kickstart.nvim` (single-file `init.lua`). It uses Neovim 0.12's built-in `vim.pack` package manager — no lazy.nvim. Plugins are declared inline with `vim.pack.add { gh '<repo>' }`.

Customizations added on top of kickstart:
- **`snacks.nvim`** (folke/snacks.nvim) is the **only fuzzy finder** — Telescope was removed and SECTION 5 is now just a pointer comment. SECTION 11 carries the explorer (`<leader>e`), lazygit (`<leader>gg`), the kickstart-compatible `<leader>s*` pickers, the LazyVim-style `<leader>f*` pickers, and the LSP `grr`/`gri`/`grd`/`grt`/`gO`/`gW` pickers (set globally, not on `LspAttach`).
- **Test files are hidden from pickers** by default; `T` (or `<a-t>` while typing) toggles them. files/grep/explorer use snacks' native `exclude` globs; other sources are filtered per item with `transform`; `git_diff` is left alone so diff hunks survive. Note the globs are `*test*`/`*Test*`, so a name like `latest.lua` is also hidden.
- **`lualine.nvim`** replaces `mini.statusline` (`globalstatus = true`, tokyonight theme with `lualine_bold`).
- **`diffview.nvim`** (+ `nvim-lua/plenary.nvim`, which used to arrive with Telescope) for `:DiffviewOpen` / `:DiffviewFileHistory`.
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

Caps Lock is mapped to Control+Option in `karabiner.json`, and `Ctrl+Option+hjkl`
is identity-mapped **before** the `Ctrl+hjkl -> arrows` rule so pane navigation
reaches Herdr instead of turning into arrow keys.

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
