{
  description = "macOS dependencies";

  inputs = {
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = _: {};
}
