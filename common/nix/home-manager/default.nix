{ pkgs, ezaThemes, ... }:

{
  imports = [
    ./packages/packages.nix
  ];

  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  programs.mise = {
    enable = true;
    enableBashIntegration = false;
  };

  xdg.configFile = {
    "eza/theme.yaml".source = "${ezaThemes}/themes/tokyonight.yml";
  };
}
