{
  description = "Home Manager recovery";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    yazelix = {
      url = "git+file:///home/lucca/pjs/yazelix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    yazelix-terminal = {
      url = "git+https://github.com/luccahuguet/yazelix-terminal.git?ref=refs/heads/yazelix-terminal-experiment&rev=1e54b3f7f592944ee9aa18eef15eb81d804cfa21";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Disabled by default in home.nix. Kept locked for quick plain-Zellij
    # Yazelix Zellij Popup smoke tests.
    yazelix-zellij-popup = {
      url = "github:luccahuguet/yazelix-zellij-popup";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      username = "lucca";
      hostname = "loqness";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      homeConfigurations."${username}@${hostname}" =
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = {
            inherit inputs;
          };
          modules = [
            inputs.yazelix.homeManagerModules.default
            ./home.nix
          ];
        };
    };
}
