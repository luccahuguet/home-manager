{ config, lib, pkgs, inputs, ... }:
  let
    system = pkgs.stdenv.hostPlatform.system;
    aiPkgs = inputs.llm-agents.packages.${system};

    # Set to true to temporarily make `zellij` launch a plain-Zellij
    # Yazelix Zellij Popup smoke session with lazygit on Alt-g.
    enableYzppSmoke = false;
    yzpp = inputs.yazelix-zellij-popup.packages.${system}.yzpp;
    beadsRust = inputs.yazelix.packages.${system}.beads_rust;
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
      rustToolchain
      vercelCli
      flyctl
    ]
    ++ lib.optionals enableYzppSmoke [
      zellijPlainPopup
    ];

  xdg.configFile = lib.mkIf enableYzppSmoke {
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
