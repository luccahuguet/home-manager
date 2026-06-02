{ inputs, pkgs, ... }:
  let
    system = pkgs.stdenv.hostPlatform.system;
    aiPkgs = inputs.llm-agents.packages.${system};

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
      flyctl
    ];
}
