{
  description = "Nix configuration of tetsuzin (linux / wsl / mac)";

  inputs = {
    # 共通
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ezaThemes = {
      url = "github:eza-community/eza-themes";
      flake = false;
    };

    # linux (home-manager 単体)
    lazyvimStarter = {
      url = "github:LazyVim/starter";
      flake = false;
    };

    # mac (nix-darwin)
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs =
    inputs:
    let
      args = inputs // {
        user = "tetsuzin";
      };
    in
    import ./linux/nix args // import ./mac/nix args;
}
