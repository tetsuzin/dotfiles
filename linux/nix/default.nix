# linux / wsl (home-manager 単体) の構成
{ nixpkgs, home-manager, ezaThemes, lazyvimStarter, user, ... }:

let
  mkHome =
    isWsl:
    home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [ ./home-manager.nix ];
      extraSpecialArgs = {
        inherit user ezaThemes lazyvimStarter isWsl;
      };
    };
in
{
  homeConfigurations.${user} = mkHome false;
  homeConfigurations."${user}-wsl" = mkHome true;
}
