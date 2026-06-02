{ inputs, lib, pkgs, ... }:
  let
    system = pkgs.stdenv.hostPlatform.system;

    # Set to true to temporarily make `zellij` launch a plain-Zellij
    # Yazelix Zellij Popup smoke session with lazygit on Alt-g.
    enableYzppSmoke = false;
    yzpp = inputs.yazelix-zellij-popup.packages.${system}.yzpp;
    zellijPlainPopup = pkgs.writeShellApplication {
      name = "zellij";
      text = ''
        exec ${pkgs.zellij}/bin/zellij --config "$HOME/.config/zellij/yzpp_smoke.kdl" "$@"
      '';
    };
  in

{
  home.packages =
    lib.optionals enableYzppSmoke (with pkgs; [
      lazygit
    ])
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

  home.file = lib.mkIf enableYzppSmoke {
    ".local/bin/zellij".source = "${zellijPlainPopup}/bin/zellij";
  };
}
