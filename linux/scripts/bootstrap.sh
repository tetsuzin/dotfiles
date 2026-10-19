#!/usr/bin/env bash
set -euo pipefail

for plugin in krew explore fuzzy iexec images lineage ktop neat rolesum; do
  if ! krew list 2>/dev/null | grep -qx "${plugin}"; then
    krew install "${plugin}"
  fi
done

# ホスト側に存在する認証情報だけを共有する。既存の独立した設定は上書きしない。
if grep -qi microsoft /proc/version; then
  windows_home="${DOTFILES_WINDOWS_HOME:-/mnt/c/Users/$(id -un)}"
  for relative in .aws/credentials .kube/config; do
    source_path="${windows_home}/${relative}"
    target_path="${HOME}/${relative}"
    [[ -e "${source_path}" ]] || continue
    if [[ -L "${target_path}" && "$(readlink -f "${target_path}")" == "$(readlink -f "${source_path}")" ]]; then
      # Home Manager の store 経由のリンクも直接リンクへ移す。
      ln -sfn "${source_path}" "${target_path}"
      continue
    fi
    if [[ -e "${target_path}" || -L "${target_path}" ]]; then
      echo "既存の設定を確認してから移動してください: ${target_path}" >&2
      exit 1
    fi
    mkdir -p "$(dirname "${target_path}")"
    ln -s "${source_path}" "${target_path}"
  done
fi
