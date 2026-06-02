{ config, lib, pkgs, inputs, ... }:
  let
    system = pkgs.stdenv.hostPlatform.system;
    aiPkgs = inputs.llm-agents.packages.${system};

    # Set to true to temporarily make `zellij` launch a plain-Zellij
    # Yazelix Zellij Popup smoke session with lazygit on Alt-g.
    enableYzppSmoke = false;
    yzpp = inputs.yazelix-zellij-popup.packages.${system}.yzpp;
    beadsRust = inputs.yazelix.packages.${system}.beads_rust;
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
    rustToolchain = inputs.yazelix.inputs.fenix.packages.${system}.combine [
      inputs.yazelix.inputs.fenix.packages.${system}.stable.cargo
      inputs.yazelix.inputs.fenix.packages.${system}.stable.rustc
      inputs.yazelix.inputs.fenix.packages.${system}.stable.rustfmt
      inputs.yazelix.inputs.fenix.packages.${system}.stable.clippy
    ];
    vercelCli = pkgs.writeShellApplication {
      name = "vercel";
      runtimeInputs = [ pkgs.nodejs_24 ];
      text = ''
        exec npx --yes vercel@53.1.0 "$@"
      '';
    };
    flyctl = pkgs.stdenvNoCC.mkDerivation {
      pname = "flyctl";
      version = "0.4.45";

      src = pkgs.fetchurl {
        url = "https://github.com/superfly/flyctl/releases/download/v0.4.45/flyctl_0.4.45_Linux_x86_64.tar.gz";
        hash = "sha256-od0QrSsWK3zQ66Xrf/n9E/3uMJpd4uwUcN30djv0xZQ=";
      };

      dontUnpack = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall
        tar -xzf $src flyctl
        install -Dm755 flyctl $out/bin/flyctl
        ln -s $out/bin/flyctl $out/bin/fly
        runHook postInstall
      '';
    };
    zellijPlainPopup = pkgs.writeShellApplication {
      name = "zellij";
      text = ''
        exec ${pkgs.zellij}/bin/zellij --config "$HOME/.config/zellij/yzpp_smoke.kdl" "$@"
      '';
    };
  in

{
  home.username = "lucca";
  home.homeDirectory = "/home/lucca";
  home.stateVersion = "24.11";

  home.packages =
    (with pkgs; [
      ruff
      uv
      ty
      gh
      tokei
      mdfried
      pandoc
      typst
      imagemagick
      ffmpeg
      # Desktop/input diagnostics for terminal and compositor work.
      bottom
      dotool
      grim
      htop
      procs
      slurp
      wev
      wl-clipboard
      wshowkeys
      wtype
      xdotool
      ydotool
      # Expose npx/npm to non-interactive tools like git hooks.
      nodejs_24
      bun
      cargo-nextest
      cargo-udeps
      rust-analyzer
      jq
      nu-lint
      cachix
    ])
    ++ lib.optionals enableYzppSmoke (with pkgs; [
      lazygit
    ])
    ++ [
      aiPkgs.claude-code
      aiPkgs.opencode
      aiPkgs.beads-viewer
      beadsRust
      rioCli
      rioDesktop
      rustToolchain
      vercelCli
      flyctl
    ]
    ++ lib.optionals enableYzppSmoke [
      zellijPlainPopup
    ];

  xdg.configFile = lib.mkMerge [
    (lib.mkIf enableYzppSmoke {
      "zellij/yzpp_smoke.kdl".text = ''
        plugins {
            yzpp location="file:${yzpp}/share/yazelix_zellij_popup/yzpp.wasm" {
                popup {
                    command "${pkgs.lazygit}/bin/lazygit"
                    pane_title "lazygit_popup"
                    command_marker "lazygit"
                    cwd "."
                    width_percent 90
                    height_percent 85
                }
            }
        }

        load_plugins {
            yzpp
        }

        keybinds {
            normal {
                bind "Alt g" {
                    MessagePlugin "yzpp" {
                        name "toggle"
                    }
                }
            }
        }
      '';
    })
    {
      "rio/config.toml".text = ''
        # See the full configuration reference: https://rioterm.com/docs/config

        confirm-before-quit = false

        [window]
        opacity = 0.88
        decorations = "disabled"

        [fonts]
        family = "FiraCode Nerd Font Mono"
      '';
    }
  ];
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
  home.file = lib.mkMerge [
    (lib.mkIf enableYzppSmoke {
      ".local/bin/zellij".source = "${zellijPlainPopup}/bin/zellij";
    })
  ];

  # Apply with: home-manager switch --flake .#lucca@loqness
  programs.home-manager.enable = true;
  manual.manpages.enable = false;

  programs.yazelix = {
    enable = true;
    manage_config = false;
    runtime_variant = "yzxterm";
    extra_terminal_variants = [
      "ghostty"
      "wezterm"
      "ratty"
      "kitty"
    ];
    terminals = [
      "yzxterm"
      "ghostty"
      "wezterm"
      "ratty"
      "kitty"
    ];
    agent_usage_programs = [
      "tokenusage"
    ];
  };
}
