{
  description = "f-tash personal dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
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
