{ inputs, lib, pkgs, ... }:
  let
    system = pkgs.stdenv.hostPlatform.system;
    aiPkgs = inputs.llm-agents.packages.${system};

    beadsRust = inputs.yazelix.packages.${system}.beads_rust;
    homeManager = inputs.home-manager.packages.${system}.home-manager;
    cargoCrap = pkgs.rustPlatform.buildRustPackage rec {
      pname = "cargo-crap";
      version = "0.2.2";

      src = pkgs.fetchCrate {
        inherit pname version;
        hash = "sha256-cZ30mdHHLXzpvMhkC6XoPMgfqAdsmdqhEfHq8T15Fmw=";
      };

      cargoHash = "sha256-vzkGNzQrVOtfpGLniGTdPRQfwA9jn5elXhudrFC7w9g=";

      # The crates.io archive omits tests/fixtures/sample_workspace, which these
      # workspace tests require. Keep the rest of the upstream test suite enabled.
      checkFlags = [
        "--skip=workspace_human_output_includes_per_crate_summary"
        "--skip=workspace_json_includes_crate_field"
        "--skip=workspace_summary_flag_shows_only_crate_table"
      ];

      meta = {
        description = "Change Risk Anti-Patterns metric for Rust projects";
        homepage = "https://github.com/minikin/cargo-crap";
        license = pkgs.lib.licenses.mit;
        mainProgram = "cargo-crap";
      };
    };
    termshot = pkgs.buildGoModule rec {
      pname = "termshot";
      version = "0.6.1";

      src = pkgs.fetchFromGitHub {
        owner = "homeport";
        repo = "termshot";
        rev = "v${version}";
        hash = "sha256-YYN5ccfWkzthnwLjZAGgH8nm98Oci+KNYij8MS0/XY0=";
      };

      vendorHash = "sha256-fLbRo8f2tNN1vZGsriZ8cL4gU+wa/SfCUBrDLGXd70M=";
      subPackages = [ "cmd/termshot" ];

      meta = {
        description = "Create screenshots based on terminal command output";
        homepage = "https://github.com/homeport/termshot";
        license = pkgs.lib.licenses.mit;
        mainProgram = "termshot";
      };
    };
    betamax = pkgs.stdenvNoCC.mkDerivation rec {
      pname = "betamax";
      version = "unstable-2026-06-21";

      src = pkgs.fetchFromGitHub {
        owner = "marcus";
        repo = "betamax";
        rev = "36760ae903c8874f1edacd9d04c17df5b41d5a52";
        hash = "sha256-yKmz2Cf7Xp2WhKJzDG8ZdC9/1IRKzDh/FZPPG0dYDoE=";
      };

      nativeBuildInputs = [ pkgs.makeWrapper ];

      runtimeInputs = [
        pkgs.aha
        pkgs.bash
        pkgs.bc
        pkgs.coreutils
        pkgs.ffmpeg
        pkgs.findutils
        pkgs.gawk
        pkgs.gnugrep
        pkgs.gnused
        (pkgs.python3.withPackages (pythonPackages: [
          pythonPackages.pillow
        ]))
        pkgs.tmux
        termshot
      ];

      dontBuild = true;

      postPatch = ''
        substituteInPlace lib/validate.sh \
          --replace-fail '((line_num++))' '((++line_num))' \
          --replace-fail '((errors++))' '((++errors))'
        substituteInPlace lib/keys.sh \
          --replace-fail '((SOURCE_DEPTH++))' '((++SOURCE_DEPTH))'
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p "$out/share/betamax" "$out/bin"
        cp -R . "$out/share/betamax"
        chmod +x "$out/share/betamax/betamax" "$out/share/betamax/bin/betamax-record" "$out/share/betamax/bin/betamax-capture"
        patchShebangs "$out/share/betamax"

        makeWrapper "$out/share/betamax/betamax" "$out/bin/betamax" \
          --prefix PATH : "${lib.makeBinPath runtimeInputs}"

        runHook postInstall
      '';

      meta = {
        description = "Terminal session recorder and screenshot tool for TUI apps";
        homepage = "https://github.com/marcus/betamax";
        license = pkgs.lib.licenses.mit;
        mainProgram = "betamax";
      };
    };
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
  home.activation.installRustupStableToolchain = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! ${pkgs.rustup}/bin/rustup toolchain list | ${pkgs.gnugrep}/bin/grep -q '^stable'; then
      run ${pkgs.rustup}/bin/rustup toolchain install stable --profile minimal --component rustfmt --component clippy --component rust-analyzer --target wasm32-wasip1
    else
      run ${pkgs.rustup}/bin/rustup component add --toolchain stable rustfmt clippy rust-analyzer
      run ${pkgs.rustup}/bin/rustup target add --toolchain stable wasm32-wasip1
    fi
    run ${pkgs.rustup}/bin/rustup default stable
  '';

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
      sysstat
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
      cargo-llvm-cov
      cargo-mutants
      cargo-udeps
      rustup
      jq
      nu-lint
      cachix
      actionlint
    ])
    ++ lib.optionals pkgs.stdenv.isLinux [
      pkgs.perf
    ]
    ++ [
      aiPkgs.claude-code
      aiPkgs.opencode
      aiPkgs.beads-viewer
      beadsRust
      cargoCrap
      termshot
      betamax
      vercelCli
      hmSwitchCool
      hms
      hmu
      flyctl
    ];
}
