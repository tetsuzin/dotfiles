{ pkgs, ... }:

{
  imports = [
    ../../common/nix/home-manager
    ./packages.nix
  ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    initContent = ''
      # mise を有効化
      eval "$(${pkgs.mise}/bin/mise activate zsh)"

      # ユーザのカスタム設定を読み込む
      source ~/.zshrc_custom
    '';

    profileExtra = ''
      eval "$(/opt/homebrew/bin/brew shellenv)"

      # ユーザのカスタム設定を読み込む
      source ~/.zprofile_custom
    '';
  };
}
