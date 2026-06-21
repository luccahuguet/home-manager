{ inputs, lib, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  marsPackage = inputs.mars.packages.${system}.mars;
  mesaVulkanIcdDir = "${pkgs.mesa}/share/vulkan/icd.d";
  mesaVulkanIcdFiles = lib.concatStringsSep ":" (map
    (name: "${mesaVulkanIcdDir}/${name}")
    [
      "asahi_icd.x86_64.json"
      "broadcom_icd.x86_64.json"
      "dzn_icd.x86_64.json"
      "freedreno_icd.x86_64.json"
      "gfxstream_vk_icd.x86_64.json"
      "intel_hasvk_icd.x86_64.json"
      "intel_icd.x86_64.json"
      "lvp_icd.x86_64.json"
      "nouveau_icd.x86_64.json"
      "panfrost_icd.x86_64.json"
      "powervr_mesa_icd.x86_64.json"
      "radeon_icd.x86_64.json"
      "virtio_icd.x86_64.json"
    ]);
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
    export VK_ICD_FILENAMES="''${VK_ICD_FILENAMES:-${mesaVulkanIcdFiles}}"
    export VK_LAYER_PATH="''${VK_LAYER_PATH:-${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d}"
    export DRI_PRIME="''${DRI_PRIME:-pci-0000_00_02_0}"
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
      {
        printf '%s\n' "--- $(date --iso-8601=seconds) ---"
        printf 'PATH=%s\n' "''${PATH:-}"
        printf 'SHELL=%s\n' "''${SHELL:-}"
        printf 'LANG=%s\n' "''${LANG:-}"
        printf 'XDG_RUNTIME_DIR=%s\n' "''${XDG_RUNTIME_DIR:-}"
        printf 'WAYLAND_DISPLAY=%s\n' "''${WAYLAND_DISPLAY:-}"
        printf 'DISPLAY=%s\n' "''${DISPLAY:-}"
        printf 'XDG_CURRENT_DESKTOP=%s\n' "''${XDG_CURRENT_DESKTOP:-}"
        printf 'VK_ICD_FILENAMES(before)=%s\n' "''${VK_ICD_FILENAMES:-}"
        printf 'VK_LAYER_PATH(before)=%s\n' "''${VK_LAYER_PATH:-}"
        printf 'DRI_PRIME(before)=%s\n' "''${DRI_PRIME:-}"
      } >> "$log_dir/mars-desktop-launch.log" 2>&1

      ${marsLaunchEnv}
      ${marsPackage}/bin/mars "$@" >> "$log_dir/mars-desktop-launch.log" 2>&1
      status=$?
      printf 'mars exit status=%s\n' "$status" >> "$log_dir/mars-desktop-launch.log"
      exit "$status"
    '';
  };
  marsYazelix = pkgs.writeShellApplication {
    name = "mars-yazelix";
    text = ''
      if [ "$#" -gt 0 ]; then
        exec ${marsDesktop}/bin/mars-desktop "$@"
      fi

      export MARS_CONFIG_HOME="''${MARS_YAZELIX_CONFIG_HOME:-$HOME/.config/mars-yazelix}"
      exec ${marsDesktop}/bin/mars-desktop -e yzx enter
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
    family = "FiraCode Nerd Font"
    size = 18.0
    additional-dirs = [ "${pkgs.noto-fonts-monochrome-emoji}/share/fonts/noto" ]
    symbol-map = [
      { start = "2600", end = "27C0", font-family = "Noto Emoji" },
      { start = "1F000", end = "1FB00", font-family = "Noto Emoji" },
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
