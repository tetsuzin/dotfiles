{ config, lib, user, pkgs, lazyvimStarter, isWsl, ... }:

let
  wslHostDir = "/mnt/c/Users/${user}";
  mkLink = config.lib.file.mkOutOfStoreSymlink;
in {
  imports = [
    ../../common/nix/home-manager
    ./packages.nix
  ];

  home.username = user;
  home.homeDirectory = "/home/${user}";

  # WSL では Windows ホスト側のファイルにパスを貼る
  home.file = lib.optionalAttrs isWsl {
    ".aws/credentials".source = mkLink "${wslHostDir}/.aws/credentials";
    ".kube/config".source = mkLink "${wslHostDir}/.kube/config";
  };

  xdg.configFile = {
    "nvim/".source = "${lazyvimStarter}/";
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    initExtra = builtins.readFile ../dotfiles/bashrc_base + ''

      # mise を有効化
      eval "$(${pkgs.mise}/bin/mise activate bash)"

      # ユーザのカスタム設定を読み込む
      source ~/.bashrc_custom
    '';

    profileExtra = ''
      # ユーザのカスタム設定を読み込む
      source ~/.bash_profile_custom
    '';
  };
}
