{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fastfetch.minimal
    bitwarden-cli
  ];
}
