{ pkgs, lib, ... }:
let
  sweepDays = 30;
  sweepRoots = [ "/home/lucca/pjs" ];

  cargoSweepAll = pkgs.writeShellApplication {
    name = "cargo-sweep-all";
    runtimeInputs = [ pkgs.cargo-sweep pkgs.findutils pkgs.coreutils ];
    text = ''
      set -euo pipefail

      roots=(
        ${lib.concatStringsSep "\n        " (map (path: lib.escapeShellArg path) sweepRoots)}
      )

      for root in "''${roots[@]}"; do
        [ -d "$root" ] || continue

        while IFS= read -r -d $'\0' cargoToml; do
          dir="$(dirname "$cargoToml")"
          echo "cargo-sweep: $dir" >&2
          (
            cd "$dir"
            cargo sweep -t ${toString sweepDays}
          ) || echo "cargo-sweep: failed in $dir" >&2
        done < <(
          find "$root" -path '*/target/*' -prune -o -name Cargo.toml -type f -print0
        )
      done
    '';
  };
in
{
  home.packages = [ cargoSweepAll ];

  systemd.user.services.cargo-sweep = {
    Unit = {
      Description = "Prune stale Rust target/ artifacts with cargo-sweep";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${cargoSweepAll}/bin/cargo-sweep-all";
    };
  };

  systemd.user.timers.cargo-sweep = {
    Unit = {
      Description = "Weekly cargo-sweep cleanup";
    };
    Timer = {
      OnCalendar = "Sun 03:00";
      Persistent = true;
      RandomizedDelaySec = "30min";
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}