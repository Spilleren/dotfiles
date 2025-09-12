export DOTFILES="$HOME/.dotfiles"
export SOURCE="$HOME/source"
export LARSSCRIPTS="$HOME/source/Development/Scripts"

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$XDG_CONFIG_HOME/local/share"
export XDG_CACHE_HOME="$XDG_CONFIG_HOME/cache"

# editor
export EDITOR="nvim"
export VISUAL="nvim"
export VIMCONFIG="$XDG_CONFIG_HOME/nvim"

# zsh
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export HISTFILE="$ZDOTDIR/.zhistory"    # History filepath
export HISTSIZE=10000                   # Maximum events for internal history
export SAVEHIST=10000                   # Maximum events in history file

# Go
export GOPROXY="https://artifactory.danskenet.net/artifactory/api/go/joined-golang,direct"
export GONOPROXY="none"
export GOPRIVATE="*"
export GOBIN="/c/Users/bg5470/.config/go.1.24.2.windows-amd64/go/bin"

# fzf
export FZF_DEFAULT_COMMAND='rg --files --no-ignore-vcs --hidden --glob "!.git"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

FZF_COLORS="bg+:-1,\
fg:gray,\
fg+:white,\
border:black,\
spinner:0,\
hl:yellow,\
header:blue,\
info:green,\
pointer:red,\
marker:blue,\
prompt:gray,\
hl+:red"

export FZF_DEFAULT_OPTS="--height 60% \
--border sharp \
--layout reverse \
--color '$FZF_COLORS' \
--prompt $(printf '\u2237') \
--pointer $(printf '\u25B6') \
--marker $(printf '\u21D2')"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -n 10'"
export FZF_COMPLETION_DIR_COMMANDS="cd pushd rmdir tree ls"
