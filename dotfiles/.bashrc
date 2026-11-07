# mise の activate とカスタム設定は対話シェルでのみ読み込む。
case $- in
  *i*) ;;
  *) return ;;
esac

source ~/.config/dotfiles/bashrc_base
export PATH="$HOME/.local/bin:$PATH"
source ~/.bash_profile_custom
eval "$(mise activate bash)"
source ~/.bashrc_custom
