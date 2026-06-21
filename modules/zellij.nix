{ pkgs, ... }:

{
  programs.zellij = {
    enable = true;
    package = pkgs.zellij;
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableZshIntegration = false;
  };
}
