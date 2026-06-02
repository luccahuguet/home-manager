{ inputs, lib, pkgs, ... }:
  let
    system = pkgs.stdenv.hostPlatform.system;
    rioUpstream = inputs.rio.packages.${system}.rio;

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
    # See the full configuration reference: https://rioterm.com/docs/config

    confirm-before-quit = false

    [window]
    opacity = 0.88
    decorations = "disabled"

    [fonts]
    family = "FiraCode Nerd Font Mono"
    size = 18.0
    additional-dirs = [ "${pkgs.noto-fonts-monochrome-emoji}/share/fonts/noto" ]
    symbol-map = [
      { start = "2600", end = "27C0", font-family = "Noto Emoji" },
      { start = "1F000", end = "1FB00", font-family = "Noto Emoji" },
    ]
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
