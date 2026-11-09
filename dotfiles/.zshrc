# shellcheck disable=SC2148
# 対話シェル。環境変数はログインシェルの .zprofile が設定する。
autoload -Uz compinit && compinit

# 履歴。zsh は HISTFILE を指定しないと保存しない。
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_FCNTL_LOCK

export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate zsh)"

# dotnet コマンドの補完を有効化
if command -v dotnet &> /dev/null; then
  eval "$(dotnet completions script zsh)"
fi

# Starship の有効化
if command -v starship &> /dev/null; then
  eval "$(starship init zsh)"
fi

# zoxide の有効化
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init zsh)"
fi

# alias
alias ls='eza --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons'

alias k='kubectl'
alias kx='kubectx'
alias kn='kubens'

# 起動時に実行
if command -v fastfetch &> /dev/null; then
  fastfetch
fi
