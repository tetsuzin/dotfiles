{
  description = "Nix configuration of tetsuzin (linux / wsl / mac)";

  inputs = {
    common.url = "path:./common/nix/inputs";
    linux.url = "path:./linux/nix/inputs";
    mac = {
      url = "path:./mac/nix/inputs";
      inputs.nix-darwin.inputs.nixpkgs.follows = "common/nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      commonArgs = inputs.common.inputs // {
        user = "tetsuzin";
      };
    in
    import ./linux/nix (commonArgs // inputs.linux.inputs)
    // import ./mac/nix (commonArgs // inputs.mac.inputs);
}
