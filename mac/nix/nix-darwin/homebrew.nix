{ nix-homebrew, user, ... }: {

  nix-homebrew = {
    enable = true;
    user = user;
    enableRosetta = false;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;
    user = user;

    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };

    # brew install (CLIツール)
    brews = [
      # バージョン管理
      "git"
      "gh"
      "ghq"
      "wget"
      "curl"

      # 開発ツール
      "mise"
      "container"
    ];

    # brew install --cask (GUIアプリ)
    casks = [
      # ブラウザ
      "google-chrome"

      # ターミナル
      "ghostty"
      "warp"

      # エディタ
      "visual-studio-code"

      # ネットワークツール
      "tailscale-app"
      "wifiman"

      # ユーティリティ
      "raycast"
      "keyboardcleantool"
      "battery"

      # チャット
      "discord"
      "slack"

      # エンターテインメント
      "spotify"
    ];
  };
}
