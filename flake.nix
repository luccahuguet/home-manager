{
  description = "Lucca's Home Manager Flake for loqness (Nix Unstable)";

  inputs = {
    # Nixpkgs from the unstable branch
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Home Manager from its master branch (tracks nixpkgs-unstable)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Fenix for Rust toolchains
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, fenix, ... }@inputs:
    let
      system = "x86_64-linux";
      username = "lucca";
      hostname = "loqness";

      # Apply fenix overlay to nixpkgs
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ fenix.overlays.default ];
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
          modules = [ ./home.nix ];
        };
    };
}
