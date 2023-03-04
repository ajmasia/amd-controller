{ pkgs, amdController, ... }:

{
  awake = pkgs.writeShellScriptBin "awake" ''

    ${amdController}/bin/amd-controller set -s
    echo "$(date) - slow profile (power management service)" >> /var/log/power.log
  '';
}
