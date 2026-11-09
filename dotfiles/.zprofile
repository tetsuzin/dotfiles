# shellcheck disable=SC2148
# ログインシェル。macOS のターミナルは常にログインシェルとして起動する。
# 非対話実行にも Homebrew と mise の shims を提供する。
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# dotnet tools でインストールしたツールにパスを通す
export PATH="$HOME/.dotnet/tools:$PATH"
