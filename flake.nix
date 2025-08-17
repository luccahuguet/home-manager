# flake.nix
{
  description = "Lucca's Home Manager Flake for loqness (Nix Unstable)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, fenix, nixgl, ... }@inputs:
    let
      system = "x86_64-linux";
      username = "lucca";
      hostname = "loqness";

      # Apply fenix and nixgl overlays and allow unfree packages
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ fenix.overlays.default nixgl.overlay ];
        config.allowUnfree = true; # Allow all unfree packages
        # Alternatively, use a predicate for specific packages:
        # config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "vscode" ];
      };
    in
    {
      homeConfigurations."${username}@${hostname}" =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs;
            inherit username;
            inherit hostname;
          };
          modules = [
            ./home.nix
          ];
        };
    };
}
