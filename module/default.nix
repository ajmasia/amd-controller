{ config, lib, pkgs, ... }:

let
  cfg = config.amd-controller;

  amdController = (pkgs.callPackage ../packages/amd-controller.nix { });

  awake = (import ./bin/scripts.nix { pkgs = pkgs; }).awake;

  processors = {
    "4800H" = import ./processors/4800H.nix;
    "5900HX" = import ./processors/5900HX.nix;
  };

in
{
  options.amd-controller = with lib; {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = mDoc ''
        Enable AMD Controller thingy
      '';
    };

    processor = mkOption {
      type = types.enum [ "4800H" "5900HX" ];
      description = "Select processor to apply specific tune values";
    };

    runAsAdmin.enable = mkOption {
      type = types.bool;
      default = false;
      description = mDoc ''
        Run amd-controler with admin privileges
      '';
    };

    runAsAdmin.user = mkOption {
      type = types.str;
      default = "";
      description = "Define user for admin privileges";
    };

    udev.enable = mkOption {
      type = types.bool;
      default = false;
      description = mDoc ''
        Enable management of udev rules for waking from suspension...
      '';
    };

    powerManagement.enable = mkOption {
      type = types.bool;
      default = false;
      description = mDoc ''
        Enable powerManagement to optimize the processor rules ...
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = [
        pkgs.ryzenadj
        amdController
      ];

      etc."amd-controller/config.json".source = with builtins; toFile "config" (toJSON processors."${config.amd-controller.processor}");
    };

    powerManagement = lib.mkIf cfg.powerManagement.enable {
      enable = true;

      cpuFreqGovernor = "ondemand";
      powerUpCommands = "sleep 1m && ${awake}/bin/awake &";
      resumeCommands = "sleep 1m && ${awake}/bin/awake &";

      powertop.enable = true;
    };

    security.sudo = lib.mkIf cfg.runAsAdmin.enable {
      enable = true;

      extraRules = [
        {
          users = [ "${cfg.runAsAdmin.user}" ];
          commands = [
            {
              command = "${pkgs.ryzenadj}/bin/ryzenadj";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    };

    services.udev.extraRules = lib.mkIf cfg.udev.enable ''
      # This config optimize the battery power
      SUBSYSTEM=="power_supply", KERNEL=="AC0", DRIVER=="", ATTR{online}=="1", RUN+="${awake}/bin/awake-udev"
      SUBSYSTEM=="power_supply", KERNEL=="AC0", DRIVER=="", ATTR{online}=="0", RUN+="${awake}/bin/awake-udev"
    '';
  };
}
