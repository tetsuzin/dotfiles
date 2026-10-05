{
  description = "Dependencies shared by Linux and macOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ezaThemes = {
      url = "github:eza-community/eza-themes";
      flake = false;
    };
  };

  outputs = _: {};
}
