{ pkgs, ... }:

{
  imports = [
    ./dotfiles-linker.nix
    ./k8s.nix
  ];

  home.packages = with pkgs; [
    git
    git-lfs
    gh
    curl
    wget
    nh
    eclint
    jq
    docker-client
    act
    starship
    eza
    zoxide
    shfmt
    lazygit
    fzf
    bat
    ghq
    btop

    # AWS
    awscli2
    aws-vault
  ];
}
