{
  pkgs,
  amdController,
  awakeMode,
  ...
}: {
  awake = pkgs.writeShellScriptBin "awake" ''
    ${amdController}/bin/amd-controller set --${awakeMode}
    ${amdController}/bin/amd-controller set --power-saving
    echo "$(date) - ${awakeMode} profile woth power-saving ($1)" >> /var/log/power.log
  '';
}
