{ config, lib, pkgs, ... }:

let cfg = config.amd-controller;
    awake = pkgs.writeShellScriptBin "awake" ''
    if [ ! -f "/sys/class/power_supply/AC0/online" ]; then
      exit 1
    fi

    AC_STATUS=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/AC0/online)
    sleep 10 # needed for override the BIOS default setup

    if [[ $AC_STATUS == "1" ]]; then
      ${pkgs.ryzenadj}/bin/ryzenadj --tctl-temp=95 --slow-limit=15000 --stapm-limit=15000 --fast-limit=25000 --power-saving &>/dev/null
    else
      ${pkgs.ryzenadj}/bin/ryzenadj --tctl-temp=95 --slow-limit=10000 --stapm-limit=10000 --fast-limit=10000 --power-saving &>/dev/null
    fi
  '';

    awake-udev = pkgs.writeShellScriptBin "awake-udev" ''
    if [ ! -f "/sys/class/power_supply/AC0/online" ]; then
      exit 1
    fi

    AC_STATUS=$(${pkgs.coreutils}/bin/cat /sys/class/power_supply/AC0/online)
    sleep 1m # needed for override the BIOS default setup

    if [[ $AC_STATUS == "1" ]]; then
      ${pkgs.ryzenadj}/bin/ryzenadj --tctl-temp=95 --slow-limit=15000 --stapm-limit=15000 --fast-limit=25000 --power-saving &>/dev/null
    else
      ${pkgs.ryzenadj}/bin/ryzenadj --tctl-temp=95 --slow-limit=10000 --stapm-limit=10000 --fast-limit=10000 --power-saving &>/dev/null
    fi
  '';


  processors = {
    "4800H" = import ./processors/4800H.nix;
  };

in {
  options.amd-controller = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = mDoc ''
        Enable AMD Controller thingy
      '';
    };

    udev.enable = mkOption {
      type = types.bool;
      default = false;
      description = mDoc ''
        Enable management of udev rules for waking from suspension...
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [ pkgs.callPackage ./default.nix {} ];

      etc."amd-controller/config.json".source = with builtins; toFile "config" (toJSON processors."4800H");
    };

    powerManagement = {
      enable = true;

      cpuFreqGovernor = "ondemand";
      powerUpCommands = "${awake}/bin/awake";
      resumeCommands = "${awake}/bin/awake";

      powertop.enable = true;
    };

    services.udev.extraRules = lib.mkIf cfg.udev.enable ''
      # This config is needed to work with Bazecor
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="1209", ATTRS{idProduct}=="2201", GROUP="users", MODE="0666"

      # This config optimize the battery power
      SUBSYSTEM=="power_supply", KERNEL=="AC0", DRIVER=="", ATTR{online}=="1", RUN+="${awake-udev}/bin/awake-udev"
      SUBSYSTEM=="power_supply", KERNEL=="AC0", DRIVER=="", ATTR{online}=="0", RUN+="${awake-udev}/bin/awake-udev"
    '';
  };
}
