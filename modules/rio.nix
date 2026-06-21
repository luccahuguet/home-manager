{ inputs, lib, pkgs, ... }:
  let
    system = pkgs.stdenv.hostPlatform.system;
    rioUpstream = inputs.rio.packages.${system}.rio;
    firaCodeNerdDir = "${pkgs.nerd-fonts.fira-code}/share/fonts/truetype/NerdFonts/FiraCode";
    symbolsNerdDir = "${pkgs.nerd-fonts.symbols-only}/share/fonts/truetype/NerdFonts/Symbols";
    notoSymbolsDir = "${pkgs.noto-fonts}/share/fonts/noto";
    notoEmojiDir = "${pkgs.noto-fonts-color-emoji}/share/fonts/noto";

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
    rioCli = pkgs.runCommand "rio-cli" { } ''
      mkdir -p $out/bin
      ln -s ${rioUpstream}/bin/rio $out/bin/rio
    '';
    rioDesktop = pkgs.writeShellApplication {
      name = "rio-desktop";
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
        } >> "$log_dir/rio-desktop-launch.log" 2>&1

        unset LD_LIBRARY_PATH
        export RIO_CONFIG_HOME="''${RIO_CONFIG_HOME:-$HOME/.config/rio}"
        export VK_ICD_FILENAMES="''${VK_ICD_FILENAMES:-${mesaVulkanIcdFiles}}"
        export VK_LAYER_PATH="''${VK_LAYER_PATH:-${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d}"
        export DRI_PRIME="''${DRI_PRIME:-pci-0000_00_02_0}"
        ${rioUpstream}/bin/rio --app-id rio "$@" >> "$log_dir/rio-desktop-launch.log" 2>&1
        status=$?
        printf 'rio exit status=%s\n' "$status" >> "$log_dir/rio-desktop-launch.log"
        exit "$status"
      '';
    };
  in

{
  home.packages = [
    rioCli
    rioDesktop
  ];

  xdg.configFile."rio/config.toml".text = ''
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

  xdg.dataFile = {
    "applications/rio.desktop" = {
      executable = true;
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Rio
        GenericName=Terminal
        Comment=A hardware-accelerated GPU terminal emulator powered by WebGPU
        TryExec=/home/lucca/.nix-profile/bin/rio-desktop
        Exec=/home/lucca/.nix-profile/bin/rio-desktop
        Icon=rio
        Terminal=false
        Categories=System;TerminalEmulator;
        StartupWMClass=Rio
        Actions=New;

        [Desktop Action New]
        Name=New Terminal
        Exec=/home/lucca/.nix-profile/bin/rio-desktop
      '';
    };
    "icons/hicolor/scalable/apps/rio.svg".source =
      "${rioUpstream}/share/icons/hicolor/scalable/apps/rio.svg";
  };
}
