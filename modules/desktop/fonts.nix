# 字体：中文 + 等宽 + emoji
{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    wqy_zenhei
    dejavu_fonts
    liberation_ttf
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      sansSerif = [
        "Noto Sans CJK SC"
        "Noto Sans"
        "DejaVu Sans"
      ];
      serif = [
        "Noto Serif CJK SC"
        "Noto Serif"
        "DejaVu Serif"
      ];
      monospace = [
        "JetBrainsMono Nerd Font"
        "FiraCode Nerd Font"
        "DejaVu Sans Mono"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
