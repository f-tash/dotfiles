# CLAUDE.md

Personal dotfiles managed with Nix home-manager (standalone, flakes-based).

## Layout

```
flake.nix              Flake inputs (nixpkgs, home-manager) and outputs.
flake.lock             Locked input versions. Committed.
home.nix               Home-manager config: packages + dotfile links.
nvim/init.lua          Neovim config (kickstart.nvim base + customizations).
private.nix.example    Template for the optional private slot. Committed.
private.nix            Optional private overlay. **gitignored**, never commit.
commit.sh / push.sh    Tiny git helpers — `git add -A && git commit -m update`, `git push`.
.gitignore             Excludes private.nix.
```

## Applying changes

After editing `home.nix` or `nvim/init.lua` (or anything else linked from home.nix):

```sh
./apply.sh   # = nix run home-manager/master -- switch --flake .#default
```

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
- **`snacks.nvim`** (folke/snacks.nvim) for file explorer, picker, and lazygit integration. Keymaps under `<leader>e`, `<leader>ff`/`fg`/`fr`/`fb`, `<leader>gg`. See SECTION 11.
- **`noice.nvim`** (folke/noice.nvim, dep `MunifTanjim/nui.nvim`) renders the `:` command-line as a centered floating popup. Only cmdline/popupmenu are enabled; messages stay in the default area.
- **`pkgs.tree-sitter`** in `home.packages` — required by nvim-treesitter `main` branch to build parsers.
- **`pkgs.lazygit`** in `home.packages` — invoked via `Snacks.lazygit()`.

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
