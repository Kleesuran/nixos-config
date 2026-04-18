{
  description = "Klee DevOps NixOS";

  inputs = {
    # 使用清华大学提供的 Nixpkgs Git 镜像
    nixpkgs.url = "git+https://mirrors.tuna.tsinghua.edu.cn/git/nixpkgs.git?ref=nixos-unstable";
    daeuniverse.url = "github:daeuniverse/flake.nix";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim 配置
    nvim-config = {
      url = "github:Kleesuran/my-nvim-config";
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

  outputs = { self, nixpkgs, home-manager, nvim-config, ilyamiro-config, rime-ice, daeuniverse , ... } @inputs:
  {
    nixosConfigurations.klee = nixpkgs.lib.nixosSystem {
      # 使用 nixpkgs 内部推荐的参数传递方式，消除 evaluation warning
      specialArgs = { inherit inputs; };
      modules = [
        # 在 modules 中显式声明架构
        { nixpkgs.hostPlatform = "x86_64-linux"; }
        
        ./hosts/klee.nix
        daeuniverse.nixosModules.daed

        home-manager.nixosModules.home-manager

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs nvim-config ilyamiro-config rime-ice; };
          home-manager.users.klee = import ./home/klee.nix;
        }
      ];
    };
  };
}
