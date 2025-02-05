{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = {
    self,
    nixpkgs,
    hardware,
    ...
  }@inputs:
  {
    nixosConfigurations = {
      cflow = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/x1
          hardware.nixosModules.lenovo-thinkpad-x1-7th-gen
        ];
      };
      xps = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/xps
          hardware.nixosModules.dell-xps-15-9500
        ];
      };
    };
  };
}
