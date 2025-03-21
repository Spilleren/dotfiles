# Setup fzf
# ---------
if [[ ! "$PATH" == */c/Users/Benjamin/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/c/Users/Benjamin/.fzf/bin"
fi

source <(fzf --zsh)
