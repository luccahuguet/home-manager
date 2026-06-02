{ inputs, pkgs, ... }:
  let
    system = pkgs.stdenv.hostPlatform.system;
    aiPkgs = inputs.llm-agents.packages.${system};

    beadsRust = inputs.yazelix.packages.${system}.beads_rust;
    homeManager = inputs.home-manager.packages.${system}.home-manager;
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
    hmSwitchCool = pkgs.writeShellApplication {
      name = "hm-switch-cool";
      runtimeInputs = [
        homeManager
        pkgs.coreutils
      ];
      text = ''
        percent="''${1:-80}"
        if [ -z "$percent" ]; then
          echo "usage: hm-switch-cool [1-100] [home-manager switch args...]" >&2
          exit 2
        fi
        case "$percent" in
          *[!0-9]*)
            echo "usage: hm-switch-cool [1-100] [home-manager switch args...]" >&2
            exit 2
            ;;
        esac
        if [ "$percent" -lt 1 ] || [ "$percent" -gt 100 ]; then
          echo "usage: hm-switch-cool [1-100] [home-manager switch args...]" >&2
          exit 2
        fi
        shift || true

        logical_cpus="$(nproc)"
        core_budget="$(( (logical_cpus * percent + 99) / 100 ))"
        nix_limits="$(printf 'max-jobs = 1\ncores = %s\neval-cores = %s' "$core_budget" "$core_budget")"
        if [ -n "''${NIX_CONFIG:-}" ]; then
          export NIX_CONFIG="''${NIX_CONFIG}
$nix_limits"
        else
          export NIX_CONFIG="$nix_limits"
        fi

        echo "home-manager switch using $percent% of logical CPUs: $core_budget/$logical_cpus cores" >&2
        exec home-manager switch --flake "$HOME/.config/home-manager#lucca@loqness" "$@"
      '';
    };
    hms = pkgs.writeShellApplication {
      name = "hms";
      runtimeInputs = [ hmSwitchCool ];
      text = ''
        percent="80"
        case "''${1:-}" in
          [0-9]*)
            percent="$1"
            shift
            ;;
        esac
        exec hm-switch-cool "$percent" "$@"
      '';
    };
    hmu = pkgs.writeShellApplication {
      name = "hmu";
      runtimeInputs = [ hmSwitchCool ];
      text = ''
        percent="80"
        case "''${1:-}" in
          [0-9]*)
            percent="$1"
            shift
            ;;
        esac
        flake="$HOME/.config/home-manager"
        echo "updating Yazelix input in $flake" >&2
        nix flake update yazelix --flake "$flake"
        exec hm-switch-cool "$percent" "$@"
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
  in

{
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
    ++ [
      aiPkgs.claude-code
      aiPkgs.opencode
      aiPkgs.beads-viewer
      beadsRust
      rustToolchain
      vercelCli
      hmSwitchCool
      hms
      hmu
      flyctl
    ];
}
