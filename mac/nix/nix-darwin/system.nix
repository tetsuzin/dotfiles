{ pkgs, user, ... }:
{
  nix = {
    optimise.automatic = true;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };

  users.users.${user} = {
    home = "/Users/${user}";
  };

  # sudo で TouchID を使う
  security.pam.services.sudo_local.touchIdAuth = true;

  programs.zsh.enable = true;

  system = {
    stateVersion = 6;
    primaryUser = user;

    defaults = {
      dock = {
        autohide = false;
        show-recents = false;
        orientation = "left";
      };

      finder = {
        AppleShowAllFiles = true;
        AppleShowAllExtensions = true;
      };
    };
  };

  # フォントの設定
  fonts.packages = with pkgs; [
    moralerspace
  ];
}
