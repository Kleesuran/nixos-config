{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history.size = 10000;
    history.path = "$HOME/.zsh_history";
    history.ignoreAllDups = true;

    initContent = builtins.readFile ./zsh-init.sh;

    shellAliases = {
      edit = "sudo -E nvim -n";
      update = "sudo nixos-rebuild switch --flake .#klee";
      stop = "shutdown now";
      edconf = "sudo -E nvim flake.nix";
    };
    
    oh-my-zsh = {
        enable = true;
        plugins = [
          "git"                
        ];
        theme = "robbyrussell";
      };
    };

  home.sessionVariables = {
      hypr = "$HOME/.config/hypr/";  
      programs = "$HOME/.config/";
    };

}
