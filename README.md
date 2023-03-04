<p align="center">
    <img src="./logo.png" alt="amd-controller" height="96">
  <h2 align="center">amd-controller</h2>
  <p align="center">NixOS module for optimizing the AMD Ryzen processors performance</p>
</p>


Important note: This module allows you to modify certain parameters of your machine's CPU, so if you do not know what you are doing, you may end up causing irreversible damage to your computer. Please use it with caution and responsibility.


## Why this project

This project arose from the need to have some tool to manage and optimize both the batteries and processors of Slimbook machines equipped with AMD Ryzen on NixOS.

Initially, I analyzed the feasibility of porting Slimbook's own AMD Controler project, but as it is strongly linked to their Linux distribution, I decided to investigate how it is built and port a simpler and more versatile solution to NixOS.

The module simply enables a system-level package called amd-controller that allows you to manage processor performance.

## How to use it

This module is implemented through Nix Flakes. To use it, you must define it as an input in your system's configuration flake and subsequently configure the module in your configuration.nix file.

The module has the following configuration options:

- `amd-controler.enable`, enables the module in the system.
- `runAsAdmin.enable`, allows you to use the package without having to use sudo for a defined user.
- `runAsAdmin.user`, name of the user to whom privileges are granted.
- `powerManagement.enable`, enables the service of the same name and allows for automatic performance management using amd-controller. By default, this option will detect when the system has changed the processor operating configuration and will automatically revert it to the slow mode.
- `udev.enable`, enables certain UDEV rules to detect changes, for example when an AC adapter is connected to a laptop and resets the processor configuration back to slow mode.
 
```nix
amd-controller = {
  enable = true;
  processor = "4800H";
  
  # optionals
  runAsAdmin = {
    enable = true;
    user = "<user_name>";
  };
  powerManagement = {
    enable = true;
  };
  udev = {
    enable = true;
  };
};
```
## Technical information

This module has RyzenAdj as its main dependency:

- [FlyGoat/RyzenAdj: Adjust power management settings for Ryzen APUs](https://github.com/FlyGoat/RyzenAdj)


## Tested computers
- [Slimbook PRO X : PRO X 14 AMD](https://slimbook.es/en/store/slimbook-pro-x/prox-amd5-comprar) con procesadores AMD 4800H
- [Slimbook ONE EN - SLIMBOOK Ultrabook, laptops, computers](https://slimbook.es/en/one-en) con procesadores AMD 5900HX

## Contributors
- [@juboba (Julio Borja Barra)](https://github.com/juboba)
- [@ajmasia (Antonio José Masiá)](https://github.com/ajmasia)



