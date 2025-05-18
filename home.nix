# This file is imported by flake.nix
{ pkgs, inputs, config, lib, username, hostname, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage. These are now derived from the 'username' variable passed from flake.nix
  home.username = username;
  home.homeDirectory = "/home/${username}";

  # This value determines the Home Manager release that your configuration is
  # compatible with. We're targeting 25.05.
  home.stateVersion = "25.05";

  home.enableNixpkgsReleaseCheck = false;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # --- Environment Variables ---
  home.sessionVariables = {
    # Ensure COSMIC's pop-launcher finds .desktop files in ~/.nix-profile/share
    XDG_DATA_DIRS =
      "${config.home.homeDirectory}/.nix-profile/share:/usr/share:/usr/local/share:${config.home.homeDirectory}/.local/share";
  };

  # --- Rust Configuration ---
  home.packages = with pkgs; [
    # Rust toolchain from fenix (includes rustc, cargo, rustfmt, clippy, rust-analyzer)
    fenix.stable.toolchain
    bottom
  ];

  # --- Dotfile Management ---
  home.file = {
    ".config/helix/config.toml".source = ./dotfiles/helix/config.toml;
  };
}
