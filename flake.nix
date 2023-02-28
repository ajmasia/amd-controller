{
  description = "AMD Controller flake";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.callPackage ./packages/amd-controller.nix {};
    module = import ./module;
  };
}
