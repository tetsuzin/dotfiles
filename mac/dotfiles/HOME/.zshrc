# 対話シェル。mise の activate とカスタム設定を読み込む。
autoload -Uz compinit && compinit

export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate zsh)"
source ~/.zshrc_custom
