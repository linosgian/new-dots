#TODO: convert those to zsh setOptions
setopt nonomatch nohup promptsubst autocd
autoload -U colors && colors
autoload -Uz compinit select-word-style
select-word-style bash
compinit

function username_color {
  if [[ $UID -eq 0 ]]; then
    echo "$fg[red]"
  else
    echo "$fg[cyan]"
  fi
}

bindkey -e
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

function prompt_symbol_color {
  if [[ -n $SSH_CLIENT || -n $SSH_TTY ]]; then
    echo "$fg[magenta]"  # Magenta for SSH sessions
  else
    echo "$fg[blue]"     # Blue for local
  fi
}

function git_prompt_info() {
  PREFIX=" %{$fg[white]%}on%{$reset_color%} %{$fg[cyan]%}"
  local ref
  ref=$(command git symbolic-ref --short HEAD 2> /dev/null) \
    || ref=$(command git rev-parse --short HEAD 2> /dev/null) \
    || return 0
  echo "${PREFIX}${ref}$(parse_git_dirty)%{$reset_color%}"
}

function parse_git_dirty() {
  STATUS=$(command git status --porcelain 2> /dev/null | tail -1)
  if [[ -n $STATUS ]]; then
    echo " %{$fg[red]%}⨯ "
  else
    echo " %{$fg[green]%}● "
  fi
}

function evinced() {
  evince "$@" &> /dev/null & disown
}

function dexec() {
  local container="$1"
  local shell="/bin/bash"

  # Check if the container has bash, otherwise use sh
  if ! docker exec -it "$container" sh -c 'command -v bash' &>/dev/null; then
    shell="/bin/sh"
  fi

  docker exec -it "$container" "$shell"
}

# Autocomplete function for dexec
_dexec() {
  local containers
  containers=($(docker ps --format '{{.Names}}'))  # Get running container names
  _arguments "1: :(${containers[*]})"  # Provide completion suggestions
}

# Register the completion function
compdef _dexec dexec

local current_dir='${PWD/#$HOME/~}'
local git_info='$(git_prompt_info)'

compdef evinced=evince
compdef _dexec dexec

export HIST_STAMPS="dd.mm.yyyy"
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/"'
export EDITOR="vim"
export VISUAL="vim"
export SSH_AUTH_SOCK=/run/user/1000/ssh-agent

alias l="ls -ahltr --color=always"
alias c="clear"
alias ssh-add='ssh-add -t 24h'
alias k="kubectl"
alias kon="kubeon"
alias koff="kubeoff"
alias nixd="nix develop -c zsh"
alias sudos="sudo -s"

PROMPT="%{$terminfo[bold]$(prompt_symbol_color)%}#%{$reset_color%} \
%{$(username_color)%}%n\
%{$fg[white]%}\
"@%{$fg[green]%}" $HOST\
%{$fg[white]%}[\
%{$terminfo[bold]$fg[yellow]%}${current_dir}%{$reset_color%}\
${git_info}]\
%{$fg[white]%} \
%{$terminfo[bold]$fg[red]%}→ %{$reset_color%}"

source kube_ps1.sh
PROMPT='$(kube_ps1)'$PROMPT
kubeoff
source ~/.zshrc_local

eval "$(fzf --zsh)"
eval "$(direnv hook zsh)"
eval "$(fzf --zsh)"
