{ config, lib, pkgs, inputs, ... }:
  let
    system = pkgs.stdenv.hostPlatform.system;
    aiPkgs = inputs.llm-agents.packages.${system};

    codex-latest = pkgs.stdenv.mkDerivation rec {
      pname = "codex";
      version = "0.125.0";

      src = pkgs.fetchurl {
        url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-x86_64-unknown-linux-musl.tar.gz";
        hash = "sha256-SiClOUOn5qDF+kRj1OR8WN2OVT7OveRVpBB+mQa/sAE=";
      };

      nativeBuildInputs = [ pkgs.gnutar pkgs.gzip ];

      unpackPhase = ''
        tar xzf $src
      '';

      installPhase = ''
        mkdir -p $out/bin
        cp codex-x86_64-unknown-linux-musl $out/bin/codex
        chmod +x $out/bin/codex
      '';

      meta = {
        description = "OpenAI Codex CLI - lightweight coding agent";
        homepage = "https://github.com/openai/codex";
        license = lib.licenses.asl20;
      };
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
    ])
    ++ [
      aiPkgs.claude-code
      codex-latest
      aiPkgs.opencode
    ];

  # Apply with: home-manager switch --flake .#lucca@loqness
  programs.home-manager.enable = true;

  programs.yazelix = {
    enable = true;
  };
}
