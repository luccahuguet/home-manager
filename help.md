# This file is imported by flake.nix
# It receives arguments like pkgs, inputs, config, lib, username, hostname
{ pkgs, inputs, config, lib, username, hostname, ... }:

{
  # !!!! DO NOT REMOVE THESE COMMENTS !!!!
  # These comments are critical for understanding and maintaining this configuration.
  # Removing them makes it harder to onboard new users or debug issues.

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
  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  home.sessionVariables = {
    # Ensure COSMIC's pop-launcher finds .desktop files in ~/.nix-profile/share
    # This makes Nix-installed GUI apps appear in the launcher
    XDG_DATA_DIRS =
      "${config.home.homeDirectory}/.nix-profile/share:/usr/share:/usr/local/share:${config.home.homeDirectory}/.local/share";
    # EDITOR = "nvim"; # Or "vim", "emacs", etc.
  };

  # --- Rustup Configuration ---
  # Manages Rust toolchains using rustup
  programs.rustup = {
    enable = true;
    # Specifies the toolchains to install.
    # You can add "beta", "nightly", or specific versions like "1.70.0"
    toolchains = [ "stable" ];
    # You can also specify targets and components if needed:
    # targets = [ "wasm32-unknown-unknown" ];
    # components = [ "rust-src", "clippy", "rustfmt" ];
    # Sets the default toolchain for your user
    # defaultToolchain = "stable"; # This is often the default anyway
  };

  # --- Other Packages ---
  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!" # config.home.username will use the value set above
    # '')

    # Language server for Rust, useful for IDEs/editors
    rust-analyzer
  ];

  # --- Dotfile Management ---
  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # # Make sure you have a 'dotfiles' directory in ~/.config/home-manager/
    # # or provide an absolute path.
    # ".screenrc".source = ./dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
    ".config/helix/config.toml".source = ./dotfiles/helix/config.toml;
  };
}
