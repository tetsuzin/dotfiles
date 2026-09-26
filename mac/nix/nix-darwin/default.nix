{ pkgs, user, ezaThemes, ... }:
{
  imports = [
    ./system.nix
    ./homebrew.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.${user} = import ../home-manager.nix;
    extraSpecialArgs = {
      inherit user ezaThemes;
      isWsl = false;
    };
  };
}
