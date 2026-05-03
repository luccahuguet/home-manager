{ config, pkgs, inputs, ... }:
  let
    system = pkgs.stdenv.hostPlatform.system;
    aiPkgs = inputs.llm-agents.packages.${system};
    beadsRust = pkgs.stdenvNoCC.mkDerivation {
      pname = "beads-rust";
      version = "0.2.3";

      src = pkgs.fetchurl {
        url = "https://github.com/Dicklesworthstone/beads_rust/releases/download/v0.2.3/br-v0.2.3-linux_musl_amd64.tar.gz";
        sha256 = "0pmrwxagcyfcm5g4i10xhxw6l67fr06nsy23jks2jvjazcsqln15";
      };

      dontUnpack = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall
        tar -xzf $src br
        install -Dm755 br $out/bin/br
        runHook postInstall
      '';
    };
    vercelCli = pkgs.writeShellApplication {
      name = "vercel";
      runtimeInputs = [ pkgs.nodejs_24 ];
      text = ''
        exec npx --yes vercel@53.1.0 "$@"
      '';
    };
    flyctl = pkgs.stdenvNoCC.mkDerivation {
      pname = "flyctl";
      version = "0.4.45";

      src = pkgs.fetchurl {
        url = "https://github.com/superfly/flyctl/releases/download/v0.4.45/flyctl_0.4.45_Linux_x86_64.tar.gz";
        hash = "sha256-od0QrSsWK3zQ66Xrf/n9E/3uMJpd4uwUcN30djv0xZQ=";
      };

      dontUnpack = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall
        tar -xzf $src flyctl
        install -Dm755 flyctl $out/bin/flyctl
        ln -s $out/bin/flyctl $out/bin/fly
        runHook postInstall
      '';
    };
  in

{
  home.username = "lucca";
  home.homeDirectory = "/home/lucca";
  home.stateVersion = "24.11";

  nix = {
    package = pkgs.nix;
    settings = {
      extra-substituters = [
        "https://yazelix.cachix.org"
      ];
      extra-trusted-public-keys = [
        "yazelix.cachix.org-1:ZgxIjQvaP0VTWL8Racx27mpUNzDJ97xC2y7QWYjmGNM="
      ];
    };
  };

  home.packages =
    (with pkgs; [
      ruff
      uv
      ty
      gh
      tokei
      mdfried
      imagemagick
      ffmpeg
      bun
      cargo
      rustc
      rustfmt
      clippy
      rust-analyzer
      cachix
    ])
    ++ [
      aiPkgs.claude-code
      aiPkgs.codex
      aiPkgs.opencode
      beadsRust
      vercelCli
      flyctl
    ];

  # Apply with: home-manager switch --flake .#lucca@loqness
  programs.home-manager.enable = true;
  manual.manpages.enable = false;

  programs.yazelix = {
    enable = true;
    manage_config = false;
    agent_usage_programs = [
      "tokenusage"
    ];
  };
}
