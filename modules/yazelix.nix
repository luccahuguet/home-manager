{ inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
in
{
  programs.yazelix = {
    enable = true;
    manage_config = false;
    terminal = "ratty";
    extra_terminal_launchers = [
      "ghostty"
      "rio"
      "foot"
      "wezterm"
    ];
    agent_usage_programs = [
      "tokenusage"
    ];
  };
}
