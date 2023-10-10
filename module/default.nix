{ config, lib, pkgs, ... }:

let
  cfg = config.amd-controller;

  amdController = (pkgs.callPackage ../packages/amd-controller.nix { });

  awake = (import ./bin/scripts.nix {
    pkgs = pkgs;
    amdController = amdController;
    awakeMode = cfg.powerManagement.awakeMode;
  }).awake;

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

    powerManagement = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = mDoc ''
        Enable powerManagement to optimize the processor rules ...
      '';
      };

      awakeMode = mkOption {
        type = types.enum [ "slow" "medium" "high" ];
        default = "slow";
        description = mDoc ''
        Define procesor tune level for awake fucntion
      '';
      };

      powerUpCommandsDelay = mkOption {
        type = types.int;
        default = 30;
        description = mDoc ''
        Define the powerUpCommands delay in seconds
      '';
      };

      resumeCommandsDelay = mkOption {
        type = types.int;
        default = 10;
        description = mDoc ''
        Define the resumeCommands delay in seconds
      '';
      };

      cpuFreqGovernor = mkOption {
        type = types.enum [ "ondemand" "performance" "powersave" ];
        default = "ondemand";
        description = mDoc ''
        Configure the governor used to regulate the frequency of the available CPUs. By default, the kernel configures the performance governor,
        although this may be overwritten in your hardware-configuration.nix file.
      '';
      };

      powertop.enable = mkOption {
        type = types.bool;
        default = true;
        description = mDoc ''
        Enable powertop service
      '';
      };
    };

    thermald.enable = mkOption {
      type = types.bool;
      default = false;
      description = mDoc ''
        Whether to enable thermald, the temperature management daemon.
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
      systemPackages = [
        pkgs.ryzenadj
        amdController
      ];

      etc."amd-controller/config.json".source = with builtins; toFile "config" (toJSON processors."${config.amd-controller.processor}");
    };

    powerManagement = lib.mkIf cfg.powerManagement.enable {
      enable = true;

      cpuFreqGovernor = cfg.powerManagement.cpuFreqGovernor;
      powerUpCommands = "sleep ${toString cfg.powerManagement.powerUpCommandsDelay} && ${awake}/bin/awake &";
      resumeCommands = "sleep ${toString cfg.powerManagement.resumeCommandsDelay} && ${awake}/bin/awake";

      powertop.enable = cfg.powerManagement.powertop.enable;
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

    services = {
      thermald.enable = cfg.thermald.enable;

      udev.extraRules = lib.mkIf cfg.udev.enable ''
      # This config optimize the battery power
      SUBSYSTEM=="power_supply", KERNEL=="AC0", DRIVER=="", ATTR{online}=="1", RUN+="${awake}/bin/awake"
      SUBSYSTEM=="power_supply", KERNEL=="AC0", DRIVER=="", ATTR{online}=="0", RUN+="${awake}/bin/awake"
    '';
    };
  };
}
