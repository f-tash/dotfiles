{ pkgs, username, ... }:
{
  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  home.packages = [
    # Required by nvim-treesitter (main branch) to build parsers.
    pkgs.tree-sitter
    # Git TUI, opened from nvim via Snacks.lazygit().
    pkgs.lazygit
    # Toolchains Mason needs to install/run language servers:
    #   nodejs -> ts_ls (typescript-language-server, via npm)
    #   go     -> gopls (via `go install`)
    pkgs.nodejs
    pkgs.go
  ];

  # Link the nvim init.lua only — lazy.nvim writes lazy-lock.json etc.
  # into the same dir, so leave the rest of ~/.config/nvim writable.
  xdg.configFile."nvim/init.lua".source = ./nvim/init.lua;

  # Karabiner-Elements config. Note: editing rules via the GUI rewrites
  # this file, replacing the symlink — re-run apply.sh after GUI edits, or
  # just edit karabiner.json in this repo directly.
  xdg.configFile."karabiner/karabiner.json".source = ./karabiner.json;

  # home.file.".gitconfig".source = ./gitconfig;
  # home.file.".zshrc".source = ./zshrc;
}
