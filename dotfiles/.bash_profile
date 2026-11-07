# ログインシェルでは非対話実行にも mise の shims を提供する。
export PATH="$HOME/.local/bin:${XDG_DATA_HOME:-$HOME/.local/share}/mise/shims:$PATH"
if [[ $- == *i* ]]; then
  source ~/.bashrc
else
  source ~/.bash_profile_custom
fi
