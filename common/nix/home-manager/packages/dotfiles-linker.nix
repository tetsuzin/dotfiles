{ pkgs, ... }:

let
  platform = {
    x86_64-linux = {
      asset = "DotfilesLinker_linux_amd64.tar.gz";
      hash = "sha256-BixgridkElrOYb9gMbkFsoDcPa7v3zJH0qTX/A+1JFo=";
    };
    aarch64-darwin = {
      asset = "DotfilesLinker_darwin_arm64.tar.gz";
      hash = "sha256-Eo+AfhJyVKQ3GgfNMcQaMzKcYM63O4yyzLWa/EgfK74=";
    };
  }.${pkgs.stdenv.hostPlatform.system};

  dotfiles-linker = pkgs.stdenvNoCC.mkDerivation rec {
    name = "dotfiles-linker";
    version = "0.4.0";
    src = pkgs.fetchzip {
      url = "https://github.com/guitarrapc/DotfilesLinker/releases/download/${version}/${platform.asset}";
      hash = platform.hash;
    };
    installPhase = ''
      install -Dm755 DotfilesLinker $out/bin/DotfilesLinker
    '';
  };

in
{
  home.packages = [ dotfiles-linker ];
}
