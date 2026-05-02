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
  in

{
  home.username = "lucca";
  home.homeDirectory = "/home/lucca";
  home.stateVersion = "24.11";

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
    ])
    ++ [
      aiPkgs.claude-code
      aiPkgs.codex
      aiPkgs.opencode
      beadsRust
      vercelCli
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
