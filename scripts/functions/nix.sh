#!/usr/bin/env bash

function install_nix() {
  if command -v nix &>/dev/null; then
    log_info "Nix はインストール済みです: $(nix --version | head -n 1)"
    return
  fi

  log_step "Nix のインストール"
  curl --proto '=https' --tlsv1.2 -sSf -L https://nixos.org/nix/install |
    sh -s -- --daemon --yes --no-channel-add

  if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
    # shellcheck disable=SC1091
    source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi

  command -v nix &>/dev/null ||
    fail "Nix をインストールしましたが、PATH で見つかりません"
  log_info "Nix をインストールしました: $(nix --version | head -n 1)"
}
