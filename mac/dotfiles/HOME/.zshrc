# 対話シェル。mise の activate とカスタム設定を読み込む。
autoload -Uz compinit && compinit

# 履歴。zsh は HISTFILE を指定しないと保存しない。
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_FCNTL_LOCK

export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate zsh)"
source ~/.zshrc_custom
