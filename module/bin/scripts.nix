{ pkgs, amdController, awakeMode, ... }:

{
  awake = pkgs.writeShellScriptBin "awake" ''

    ${amdController}/bin/amd-controller set --${awakeMode}
    echo "$(date) - slow profile (power management service)" >> /var/log/power.log
  '';
}
