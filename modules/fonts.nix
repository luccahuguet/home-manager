{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.symbols-only
    noto-fonts-monochrome-emoji
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts.emoji = [ "Noto Emoji" ];
  };
}
