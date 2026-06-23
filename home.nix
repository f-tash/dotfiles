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
  ];

  # Link the nvim init.lua only — lazy.nvim writes lazy-lock.json etc.
  # into the same dir, so leave the rest of ~/.config/nvim writable.
  xdg.configFile."nvim/init.lua".source = ./nvim/init.lua;

  # home.file.".gitconfig".source = ./gitconfig;
  # home.file.".zshrc".source = ./zshrc;
}
