{
  description = "AMD Controller flake";

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.callPackage ./default.nix {};

    module = import ./amd-controller.nix;
  };
}
