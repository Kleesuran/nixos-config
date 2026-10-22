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

      overlays.default = final: prev: {
        zedg = final.callPackage ./pkgs/zedg { };
        grok-build = final.callPackage ./pkgs/grok-build { };
        openlogi = final.callPackage ./pkgs/openlogi { };
        rea-agents = final.callPackage ./pkgs/rea-agents { };
        qoder-cn = final.callPackage ./pkgs/qoder-cn { };
        workbuddy = final.callPackage ./pkgs/workbuddy { };

        # nixpkgs 自带 1.4.1，但上游下载站不可达；本地 AUR 缓存里有 1.4.2。
        antigravity-cli = prev.antigravity-cli.overrideAttrs (old: {
          version = "1.4.2";
          src = final.fetchurl {
            url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.2-4835981233356800/linux-x64/cli_linux_x64.tar.gz";
            hash = "sha256-Y5WDesDhk90/5Q8SKOHErqNFypljbVRASrfnQ5fUCRw=";
          };
          passthru = old.passthru // {
            wholeVersion = "1.4.2-4835981233356800";
          };
        });
      };

      mkHost =
        hostname:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/${hostname}
            { nixpkgs.overlays = [ overlays.default ]; }
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
      inherit overlays;

      nixosConfigurations = {
        legion-t5 = mkHost "legion-t5";
      };
    };
}
