{
  home.username = "lucca";
  home.homeDirectory = "/home/lucca";
  home.stateVersion = "24.11";

  # Apply with: home-manager switch --flake .#lucca@loqness
  programs.home-manager.enable = true;
  manual.manpages.enable = false;
}
