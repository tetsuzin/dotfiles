# shellcheck shell=bash
# 対話シェル。環境変数はログインシェルの .bash_profile が設定する。
case $- in
  *i*) ;;
  *) return ;;
esac

# 履歴。重複と先頭空白の行は残さず、追記で保存する。
HISTCONTROL=ignoreboth
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000

# コマンドごとにウィンドウサイズを確認して LINES と COLUMNS を更新する。
shopt -s checkwinsize

# less でテキスト以外のファイルも扱えるようにする。
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# grep の色付け
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# プログラム補完
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate bash)"

# WSL2 から Windows 側の SSH エージェントを利用するための設定
if grep -qi microsoft /proc/version && command -v wsl2-ssh-agent &>/dev/null; then
  eval "$(wsl2-ssh-agent)"
fi

# dotnet コマンドの補完を有効化
if command -v dotnet &>/dev/null; then
  eval "$(dotnet completions script bash)"
fi

# zoxide の有効化
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash)"
fi

# Starship の有効化
if command -v starship &>/dev/null; then
  export STARSHIP_KUBERNETES_ENABLED=1

  kubeon() {
    export STARSHIP_KUBERNETES_ENABLED=1
  }

  kubeoff() {
    unset STARSHIP_KUBERNETES_ENABLED
  }

  eval "$(starship init bash)"
fi

# alias
alias ls='eza --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons'

alias k='kubectl'
alias kx='kubectx'
alias kn='kubens'

# 起動時に実行
if command -v fastfetch &>/dev/null; then
  fastfetch
fi
