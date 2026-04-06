{
  description = "Klee DevOps NixOS";

  inputs = {
    # 使用清华大学提供的 Nixpkgs Git 镜像
    nixpkgs.url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim DevOps 配置
    nvim-config = {
      url = "github:Kleesuran/my-nvim-devops-config";
      flake = false;
    };

    # ilyamiro's rice - 引用作为主题源
    ilyamiro-config = {
      url = "github:ilyamiro/nixos-configuration";
      flake = false;
    };

    # Rime 词库 - 雾凇拼音
    rime-ice = {
      url = "github:iDvel/rime-ice";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, nvim-config, ilyamiro-config, rime-ice, ... }:
  let
    system = "x86_64-linux";
  in {
    nixosConfigurations.klee = nixpkgs.lib.nixosSystem {
      inherit system;

      modules = [
        ./hosts/klee.nix

        home-manager.nixosModules.home-manager

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit nvim-config ilyamiro-config rime-ice; };
          home-manager.users.klee = import ./home/klee.nix;
        }
      ];
    };
  };
}
