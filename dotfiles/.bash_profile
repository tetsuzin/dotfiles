# shellcheck shell=bash
# ログインシェル。非対話実行にも mise の shims と環境変数を提供し、対話なら .bashrc を読む。
export PATH="$HOME/.local/bin:${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# dotnet tools でインストールしたツールにパスを通す
export PATH="$HOME/.dotnet/tools:$PATH"

# k8s用のスクリプトにパスを通す
export PATH="$HOME/common_scripts:$PATH"

# Windows 側の Docker に接続する
if grep -qi microsoft /proc/version; then
  export DOCKER_HOST="tcp://localhost:2375"
fi

if [[ $- == *i* ]]; then
  source ~/.bashrc
fi
