# shellcheck shell=bash
# scripts/switch.sh (共通ドライバ) から source される
# OS 固有フック。単体では実行しない。

os_shell="zsh"

function check_nix() {
  local nix_version

  command -v nix &>/dev/null ||
    fail "Nix が見つかりません。先に ./setup.sh prepare を実行してください"

  nix_version="$(nix --version | head -n 1)"
  log_debug "NIX: ${nix_version}"
}

function resolve_flake_attr() {
  host="$(scutil --get LocalHostName)"
  log_debug "HOST: ${host}"

  flake_attr="${NIX_DIR}#darwinConfigurations.${host}.system"
}

function run_activation() {
  local system_path
  system_path="$(
    nix build \
      --no-update-lock-file \
      --no-link \
      --print-out-paths \
      "${flake_attr}"
  )"
  # nix-darwin 25.05 以降 darwin-rebuild switch は root 権限が必要
  sudo "${system_path}/sw/bin/darwin-rebuild" switch --flake "${NIX_DIR}#${host}"
}

# home-manager (useUserPackages) によってインストールされたパッケージをパスに反映する
function post_activation_env() {
  export PATH="/etc/profiles/per-user/$(id -un)/bin:${PATH}"
}
