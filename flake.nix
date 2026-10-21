{
  description = "Klee 的 NixOS 配置（Legion T5 / Ryzen 3700X / RTX 2070）";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";

      mkHost =
        hostname:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/${hostname}
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                # 家目录与 Arch 共用，覆盖前先改名留底
                backupFileExtension = "hm-bak";
                extraSpecialArgs = { inherit inputs; };
                users.klee = import ./home/klee;
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        legion-t5 = mkHost "legion-t5";
      };
    };
}
