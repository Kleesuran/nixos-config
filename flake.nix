{
  description = "Klee 的 NixOS 配置（Legion T5 / Ryzen 3700X / RTX 2070）";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # end4-pC：quickshell 外壳（illogical-impulse 分支）
    end4-pC = {
      url = "github:pctrade/end4-pC/cacaf5049dec31e023f2d39b24e22ce908ee9c56";
      flake = false;
    };

    # end4-pC 依赖的底包配置（matugen / fuzzel / wlogout 等）
    dots-hyprland = {
      url = "github:end-4/dots-hyprland/2f2a376fdb2ad738bf55f693dd0b474b64bb0ab8";
      flake = false;
    };
  };

  outputs =
    { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";

      overlays.default = final: prev: {
        liblhdcv5 = final.callPackage ./pkgs/liblhdcv5 { };
        pipewire-lhdc = final.callPackage ./pkgs/pipewire-lhdc { };
        zedg = final.callPackage ./pkgs/zedg { };
        grok-build = final.callPackage ./pkgs/grok-build { };
        openlogi = final.callPackage ./pkgs/openlogi { };
        rea-agents = final.callPackage ./pkgs/rea-agents { };
        qoder-cn = final.callPackage ./pkgs/qoder-cn { };
        qoder-cli = final.callPackage ./pkgs/qoder-cli { };
        codebuddy = final.callPackage ./pkgs/codebuddy { };
        workbuddy = final.callPackage ./pkgs/workbuddy { };
        openuuyc = final.callPackage ./pkgs/openuuyc { };

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

      # 方便单独构建/迭代：nix build .#openuuyc
      packages.x86_64-linux.openuuyc =
        nixpkgs.legacyPackages.${system}.callPackage ./pkgs/openuuyc { };

      packages.x86_64-linux.codebuddy =
        nixpkgs.legacyPackages.${system}.callPackage ./pkgs/codebuddy { };

      packages.x86_64-linux.qoder-cli =
        nixpkgs.legacyPackages.${system}.callPackage ./pkgs/qoder-cli { };

      packages.x86_64-linux.liblhdcv5 =
        (nixpkgs.legacyPackages.${system}.extend overlays.default).liblhdcv5;

      packages.x86_64-linux.pipewire-lhdc =
        (nixpkgs.legacyPackages.${system}.extend overlays.default).pipewire-lhdc;

      nixosConfigurations = {
        legion-t5 = mkHost "legion-t5";
      };
    };
}
