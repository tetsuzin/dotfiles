{ pkgs, lib, isWsl, ... }:

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
  ] ++ lib.optionals stdenv.isLinux [
    neovim
    fastfetch-unwrapped
    yazi
    herdr
  ] ++ lib.optionals stdenv.isDarwin [
    fastfetch.minimal
    bitwarden-cli
  ] ++ lib.optionals isWsl [
    wsl2-ssh-agent
  ];

  # WSL では Windows 側の SSH エージェント連携用のシンボリックリンクを貼っておく
  home.file = lib.optionalAttrs isWsl {
    ".ssh/wsl2-ssh-agent".source = "${pkgs.wsl2-ssh-agent}/bin/wsl2-ssh-agent";
  };
}
