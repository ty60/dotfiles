# Minimal prompt for bash and zsh (replaces starship).
#
#   ty at host in ~/path on branch   (SSH)
#   ty in ~/path on branch           (local)
#   $
#
# Colors mirror the old starship config:
#   - username / hostname / directory: bold gold      (256-color 222)
#   - git branch:                      bold dark-gold  (256-color 94)
# Hostname is shown only inside an SSH session.

# Current branch (or short SHA on detached HEAD); empty outside a work tree.
__prompt_branch() {
  git symbolic-ref --short HEAD 2>/dev/null ||
    git rev-parse --short HEAD 2>/dev/null
}

if [ -n "${ZSH_VERSION:-}" ]; then
  # ---- zsh ----
  autoload -Uz add-zsh-hook
  __prompt_precmd() {
    local branch loc git
    branch=$(__prompt_branch)
    branch=${branch//\%/%%}            # escape % so it isn't read as a prompt code
    if [ -n "$branch" ]; then
      git=" on %B%F{94}${branch}%f%b"
    else
      git=""
    fi
    # "at host in " over SSH, just "in " locally; "in" always precedes the dir.
    if [ -n "${SSH_CONNECTION}${SSH_CLIENT}${SSH_TTY}" ]; then
      loc=" at %B%F{222}%m%f%b in "
    else
      loc=" in "
    fi
    PROMPT="%B%F{222}%n%f%b${loc}%B%F{222}%~%f%b${git}"$'\n''$ '
  }
  add-zsh-hook precmd __prompt_precmd
else
  # ---- bash ----
  # Connector between username and directory:
  #   "at host in " over SSH, just "in " locally. "in" always precedes the dir.
  __prompt_loc() {
    if [ -n "${SSH_CONNECTION:-}${SSH_CLIENT:-}${SSH_TTY:-}" ]; then
      printf ' at \001\033[1;38;5;222m\002%s\001\033[0m\002 in ' "${HOSTNAME%%.*}"
    else
      printf ' in '
    fi
  }
  # Show "on branch" (branch in bold dark-gold) when inside a git work tree.
  __prompt_git() {
    local branch
    branch=$(__prompt_branch) || return
    [ -n "$branch" ] || return
    printf 'on \001\033[1;38;5;94m\002%s\001\033[0m\002' "$branch"
  }
  PS1='\[\033[1;38;5;222m\]\u\[\033[0m\]$(__prompt_loc)\[\033[1;38;5;222m\]\w\[\033[0m\] $(__prompt_git)\n\$ '
fi
