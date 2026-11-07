# ログインシェル。macOS のターミナルは常にログインシェルとして起動する。
# 非対話実行にも Homebrew と mise の shims を提供する。
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims:$PATH"
source ~/.zprofile_custom
