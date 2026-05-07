# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# ZSH THEME
ZSH_THEME="flazz"

HISTFILE=/code/.zsh_container_history
SAVEHIST=50000
HISTSIZE=50000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS

# OMZSH PLUGINS
plugins=(git kube-ps1 kubectl terraform)

source $ZSH/oh-my-zsh.sh

# Exports
export EDITOR='vim'

# Aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
alias k='kubectl'
alias ktx='kubectx'
alias kns='kubens'

# FZF
source <(fzf --zsh)

# Custom functions
function aws-profile() {
    local AWS_PROFILES
    AWS_PROFILES=$(cat ~/.aws/credentials | sed -n -e 's/^\[\(.*\)\]/\1/p' | fzf)
    if [[ -n "$AWS_PROFILES" ]]; then
        export AWS_PROFILE=$AWS_PROFILES
        echo "Selected profile: $AWS_PROFILES"
    else
        echo "No profile selected"
    fi
}
