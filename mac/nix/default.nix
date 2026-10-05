# mac (nix-darwin) の構成
{ nix-darwin, home-manager, nix-homebrew, ezaThemes, user, ... }:

{
  darwinConfigurations."shion" = nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [
      ./nix-darwin
      nix-homebrew.darwinModules.nix-homebrew
      home-manager.darwinModules.home-manager
    ];
    specialArgs = { inherit user ezaThemes; };
  };
}
