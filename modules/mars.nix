{ inputs, lib, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  marsPackage = inputs.mars.packages.${system}.mars;
  yzcPackage = inputs.localYazelixCursors.packages.${system}.yazelix_cursors;
  firaCodeNerdDir = "${pkgs.nerd-fonts.fira-code}/share/fonts/truetype/NerdFonts/FiraCode";
  symbolsNerdDir = "${pkgs.nerd-fonts.symbols-only}/share/fonts/truetype/NerdFonts/Symbols";
  notoSymbolsDir = "${pkgs.noto-fonts}/share/fonts/noto";
  notoEmojiDir = "${pkgs.noto-fonts-color-emoji}/share/fonts/noto";
  marsLaunchEnv = ''
    unset LD_LIBRARY_PATH
    for name in "''${!YAZELIX_@}"; do
      if [ -n "$name" ]; then
        unset "$name"
      fi
    done
    unset IN_YAZELIX_SHELL
    unset MARS
    unset ZELLIJ
    unset ZELLIJ_SESSION_NAME
    unset ZELLIJ_PANE_ID
    unset ZELLIJ_SOCKET_DIR
    unset ZELLIJ_DEFAULT_LAYOUT
    export MARS_CONFIG_HOME="''${MARS_CONFIG_HOME:-$HOME/.config/mars}"
  '';
  marsCli = pkgs.writeShellApplication {
    name = "mars";
    text = ''
      ${marsLaunchEnv}
      exec ${marsPackage}/bin/mars "$@"
    '';
  };
  marsDesktop = pkgs.writeShellApplication {
    name = "mars-desktop";
    text = ''
      log_dir="''${XDG_CACHE_HOME:-$HOME/.cache}"
      mkdir -p "$log_dir"
      ${marsLaunchEnv}
      exec ${marsPackage}/bin/mars-launch-trace \
        --log-file "$log_dir/mars-desktop-launch.log" \
        --label mars-desktop \
        -- ${marsPackage}/bin/mars "$@"
    '';
  };
  marsYazelix = pkgs.writeShellApplication {
    name = "mars-yazelix";
    text = ''
      if [ "$#" -gt 0 ]; then
        exec ${marsDesktop}/bin/mars-desktop "$@"
      fi

      base_mars_config_home="''${MARS_YAZELIX_CONFIG_HOME:-$HOME/.config/mars-yazelix}"
      cursor_config_home="$(${yzcPackage}/bin/yzc materialize rio-compatible-config \
        --source-config "$base_mars_config_home/config.toml")"
      export MARS_CONFIG_HOME="$cursor_config_home"
      exec ${marsDesktop}/bin/mars-desktop -e env MARS=mars YAZELIX_SESSION_TERMINAL=mars /home/lucca/.nix-profile/bin/yzx enter
    '';
  };
  marsIconSizes = [ 16 24 32 48 64 128 256 512 1024 ];
  marsIconForSize = size:
    pkgs.runCommand "mars-icon-${toString size}.png" {
      nativeBuildInputs = [ pkgs.imagemagick ];
    } ''
      magick ${marsPackage}/share/icons/hicolor/1024x1024/apps/mars.png \
        -resize ${toString size}x${toString size} "$out"
    '';
  marsConfigText = ''
    # Rio-compatible Yazelix dogfood config.

    confirm-before-quit = false
    scrollback-history-limit = 0
    force-theme = "dark"
    enable-scroll-bar = false

    [bell]
    audio = false
    visual = true

    [effects]
    trail-cursor = true

    [window]
    width = 960
    height = 620
    decorations = "Disabled"
    opacity = 0.78
    opacity-cells = true

    [panel]
    margin = [0.0]
    padding = [0.0]
    border-width = 0.0

    [fonts]
    family = "FiraCode Nerd Font Mono"
    size = 18.0
    additional-dirs = [
      "${firaCodeNerdDir}",
      "${symbolsNerdDir}",
      "${notoSymbolsDir}",
      "${notoEmojiDir}"
    ]
    symbol-map = [
      { start = "E000", end = "F900", font-family = "Symbols Nerd Font Mono" },
      { start = "F0000", end = "F3000", font-family = "Symbols Nerd Font Mono" },
      { start = "1F5B0", end = "1F5C0", font-family = "Noto Sans Symbols2" },
      { start = "2600", end = "276F", font-family = "Noto Color Emoji" },
      { start = "1F000", end = "1F5B0", font-family = "Noto Color Emoji" },
      { start = "1F5C0", end = "1FB00", font-family = "Noto Color Emoji" },
    ]

    [colors]
    background = "#111416"
    foreground = "#eeeeec"
    black = "#000000"
    red = "#cd0000"
    green = "#00cd00"
    yellow = "#cdcd00"
    blue = "#1093f5"
    magenta = "#cd00cd"
    cyan = "#00cdcd"
    white = "#faebd7"
    light-black = "#404040"
    light-red = "#ff0000"
    light-green = "#00ff00"
    light-yellow = "#ffff00"
    light-blue = "#11b5f6"
    light-magenta = "#ff00ff"
    light-cyan = "#00ffff"
    light-white = "#ffffff"

    [navigation]
    mode = "Plain"
  '';
in
{
  home.packages = [
    marsCli
    marsDesktop
    marsYazelix
  ];

  xdg.configFile."mars/config.toml".text = marsConfigText;
  xdg.configFile."mars-yazelix/config.toml".text = marsConfigText;

  xdg.dataFile =
    {
      "applications/mars-yazelix.desktop" = {
        executable = true;
        text = lib.concatStringsSep "\n" [
          "[Desktop Entry]"
          "Type=Application"
          "Name=Mars Yazelix"
          "GenericName=Terminal"
          "Comment=Private Mars dogfooding launcher for Yazelix"
          "TryExec=/home/lucca/.nix-profile/bin/mars-yazelix"
          "Exec=/home/lucca/.nix-profile/bin/mars-yazelix"
          "Icon=mars"
          "Terminal=false"
          "Categories=System;TerminalEmulator;"
          "StartupWMClass=mars"
          "Actions=New;"
          ""
          "[Desktop Action New]"
          "Name=New Yazelix Session"
          "Exec=/home/lucca/.nix-profile/bin/mars-yazelix"
          ""
        ];
      };
    }
    // lib.listToAttrs (map
      (size: {
        name = "icons/hicolor/${toString size}x${toString size}/apps/mars.png";
        value.source = marsIconForSize size;
      })
      marsIconSizes);
}
