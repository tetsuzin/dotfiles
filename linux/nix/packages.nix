{ pkgs, lib, isWsl, ... }:

{
  home.packages = with pkgs; [
    neovim
    fastfetch-unwrapped
    yazi
    herdr
  ] ++ lib.optionals isWsl [
    wsl2-ssh-agent
  ];

  # WSL では Windows 側の SSH エージェント連携用のシンボリックリンクを貼っておく
  home.file = lib.optionalAttrs isWsl {
    ".ssh/wsl2-ssh-agent".source = "${pkgs.wsl2-ssh-agent}/bin/wsl2-ssh-agent";
  };
}
