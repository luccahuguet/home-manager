# This file is imported by flake.nix
{
  pkgs,
  inputs,
  config,
  lib,
  username,
  hostname,
  ...
}:

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
    XDG_DATA_DIRS = "${config.home.homeDirectory}/.nix-profile/share:/usr/share:/usr/local/share:${config.home.homeDirectory}/.local/share";

    # Ensure PATH includes essential system directories
    PATH = "/bin:/usr/bin:/usr/local/bin:$PATH";
  };

  home.packages = with pkgs; [
    fenix.stable.toolchain
    bottom
    nixgl.nixGLIntel
    maven
    nushell
    parallel
    # nixfmt-rfc-style
    (rustPlatform.buildRustPackage rec {
      pname = "rusty-rain";
      version = "0.2.0";
      src = fetchCrate {
        inherit pname version;
        sha256 = "sha256-WhxaVeyiM/76CUSi/LyefGHsGYW/CeAyRhVCIJtG3qk=";
      };
      cargoLock = {
        lockFile = "${src}/Cargo.lock";
      };
      meta = with lib; {
        description = "A Rust-based terminal rain animation";
        homepage = "https://github.com/cowboy8625/rusty-rain";
        license = licenses.mit;
      };
    })
    # nixGL wrappers for terminal emulators (GPU acceleration support)
    (writeShellScriptBin "ghostty-nixgl" ''
      exec ${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${pkgs.ghostty}/bin/ghostty "$@"
    '')
    (writeShellScriptBin "kitty-nixgl" ''
      exec ${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${pkgs.kitty}/bin/kitty "$@"
    '')
  ];

  # --- Dotfile Management ---
  # Helix configuration moved to ~/.config/helix/ for better integration with yazelix

  # --- Program Configuration ---
  # Terminal emulators use their default config locations
  # Kitty: ~/.config/kitty/kitty.conf  (use kitty-nixgl wrapper)
  # Ghostty: ~/.config/ghostty/config  (use ghostty-nixgl wrapper)
}
