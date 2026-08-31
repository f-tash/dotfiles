{
  description = "f-tash personal dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, herdr, ... }:
    let
      system = "aarch64-darwin";
      # Evaluated here (not legacyPackages) so the herdr overlay can add pkgs.herdr.
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ herdr.overlays.default ];
        # Named rather than allowUnfree, so an unfree package can never slip in
        # unnoticed: anything not on this list still refuses to evaluate.
        config.allowUnfreePredicate = pkg:
          builtins.elem (nixpkgs.lib.getName pkg) [
            "cursor-cli"
            "orbstack"
          ];
      };
      # Machine-local config (gitignored). Keeps the username out of this repo.
      localConfig =
        if builtins.pathExists ./local.nix
        then import ./local.nix
        else { username = "user"; };
      username = localConfig.username;
      # Include ./private.nix if it exists; otherwise the public modules run on their own.
      privateModules =
        if builtins.pathExists ./private.nix
        then [ ./private.nix ]
        else [ ];
    in {
      homeConfigurations.default = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit username; };
        modules = [ ./home.nix ] ++ privateModules;
      };
    };
}
