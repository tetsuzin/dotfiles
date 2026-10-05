# shellcheck shell=bash
# scripts/switch.sh (共通ドライバ) から source される
# OS 固有フック。単体では実行しない。

os_shell="bash"

function check_nix() {
  local nix_version_output nix_version

  command -v nix &>/dev/null ||
    fail "Lix が見つかりません。先に ./setup.sh prepare を実行してください"

  nix_version_output="$(nix --version)"
  nix_version="${nix_version_output%%$'\n'*}"
  [[ "${nix_version_output}" == *Lix* ]] ||
    fail "Lix 以外の Nix が使用されています: ${nix_version}"
  log_debug "LIX: ${nix_version}"
}

function resolve_flake_attr() {
  local user flake_name
  user="$(id -un)"

  # WSL では専用の home-manager 構成を使用する
  if grep -qi microsoft /proc/version 2>/dev/null; then
    flake_name="${user}-wsl"
  else
    flake_name="${user}"
  fi
  log_debug "FLAKE_NAME: ${flake_name}"

  flake_attr="${NIX_DIR}#homeConfigurations.${flake_name}.activationPackage"
}

function run_activation() {
  local activation_package
  activation_package="$(
    nix build \
      --no-update-lock-file \
      --no-link \
      --print-out-paths \
      "${flake_attr}"
  )"
  HOME_MANAGER_BACKUP_EXT=backup "${activation_package}/activate"
}

# home-manager によってインストールされたパッケージをパスに反映する
function post_activation_env() {
  if [[ -e "${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh" ]]; then
    # shellcheck disable=SC1091
    source "${HOME}/.nix-profile/etc/profile.d/hm-session-vars.sh"
  fi
}
