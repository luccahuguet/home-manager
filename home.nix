{ config, lib, pkgs, inputs, ... }:
  let
    aiPkgs = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
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
      aiPkgs.codex
      aiPkgs.opencode
    ];

  # Apply with: home-manager switch --flake .#lucca@loqness
  programs.home-manager.enable = true;

  programs.yazelix = {
    # enable = true;
    enable = false;
  };
}
