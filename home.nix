{ pkgs, username, ... }:
{
  home.username = username;
  home.homeDirectory = "/Users/${username}";
  # 25.11 flips the darwin app default from linkApps (symlinks, invisible to
  # Spotlight) to copyApps. Do not raise past 25.11: 26.05 drops man-db on
  # darwin, and the system man does not see ~/.nix-profile/share/man here.
  home.stateVersion = "25.11";

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
    # Terminal emulator. Use ghostty-bin (prebuilt macOS app); pkgs.ghostty is Linux-only.
    pkgs.ghostty-bin
    # Terminal multiplexer for AI coding agents. https://herdr.dev
    # Comes from the herdr flake overlay applied in flake.nix, not nixpkgs.
    pkgs.herdr
    # Image conversion, used by terminal image renderers.
    pkgs.imagemagick
    # Per-directory environments, hooked into zsh in shell/zshrc.
    pkgs.direnv
    # File manager, wrapped by the `y` function in shell/aliases.zsh.
    pkgs.yazi
    # Cursor CLI. Ships the binary as cursor-agent; `cr` aliases it.
    pkgs.cursor-cli
    # Container/VM runtime. shell/zprofile sources its init.zsh when present.
    pkgs.orbstack
  ];

  # Link the nvim init.lua only — lazy.nvim writes lazy-lock.json etc.
  # into the same dir, so leave the rest of ~/.config/nvim writable.
  xdg.configFile."nvim/init.lua".source = ./nvim/init.lua;

  # Herdr keybindings. The rest of ~/.config/herdr (sockets, logs, session
  # state) is written by herdr itself, so link only config.toml.
  xdg.configFile."herdr/config.toml".source = ./herdr/config.toml;

  # zsh. env.sh stays hand-managed (it predates this repo); everything the
  # rc files source from ~/.config/shell comes from here.
  xdg.configFile."shell/aliases.zsh".source = ./shell/aliases.zsh;
  xdg.configFile."shell/herdr.zsh".source = ./shell/herdr.zsh;

  home.file.".zprofile".source = ./shell/zprofile;
  home.file.".zshrc".source = ./shell/zshrc;

  # Karabiner-Elements config. Note: editing rules via the GUI rewrites
  # this file, replacing the symlink — re-run apply.sh after GUI edits, or
  # just edit karabiner.json in this repo directly.
  xdg.configFile."karabiner/karabiner.json".source = ./karabiner.json;

  # home.file.".gitconfig".source = ./gitconfig;
}
