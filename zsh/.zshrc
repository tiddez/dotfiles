
. "$HOME/.local/share/../bin/env"

export ATUIN_NOBIND=true
eval "$(atuin init zsh)"
bindkey "^R" atuin-search

# incremental history search with arrow keys
bindkey "^[[A" history-beginning-search-backward
bindkey "^[[B" history-beginning-search-forward]]
