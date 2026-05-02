{ config, pkgs, inputs, ... }:
  let
    system = pkgs.stdenv.hostPlatform.system;
    aiPkgs = inputs.llm-agents.packages.${system};
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
