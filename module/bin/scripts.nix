{
  pkgs,
  amdController,
  awakeMode,
  ...
}: {
  awake = pkgs.writeShellScriptBin "awake" ''
    ${amdController}/bin/amd-controller set --${awakeMode}
    echo "$(date) - ${awakeMode} profile ($1)" >> /var/log/power.log
  '';
}
