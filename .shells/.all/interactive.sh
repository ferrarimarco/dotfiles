#!/usr/bin/env sh

# We don't have the source_file_if_available function yet
# shellcheck source=/dev/null
FILE="${HOME}"/.shells/.all/functions.sh && test -f "$FILE" && . "$FILE"

# Initialize rbenv if available
command -v rbenv >/dev/null 2>&1 && eval "$(rbenv init -)"

###############################################################################
# MOTD                                                                        #
###############################################################################
if command -v sw_vers >/dev/null 2>&1; then
  sw_vers
fi

if command -v uname >/dev/null 2>&1; then
  uname -snrvm
fi

###############################################################################
# Aliases                                                                     #
###############################################################################

# Check for various OS openers. Quit as soon as we find one that works.
for opener in browser-exec xdg-open cmd.exe cygstart "start" open; do
  if command -v $opener >/dev/null 2>&1; then
    if [ "$opener" = "cmd.exe" ]; then
      # shellcheck disable=SC2139
      alias open="$opener /c start"
    else
      # shellcheck disable=SC2139
      alias open="$opener"
    fi
    break
  fi
done

# Linux specific aliases
if ! command -v pbcopy >/dev/null 2>&1; then
  alias pbcopy='xclip -selection clipboard'
fi
if ! command -v pbpaste >/dev/null 2>&1; then
  alias pbpaste='xclip -selection clipboard -o'
fi

# copy working directory
alias cwd="pwd | tr -d '\n' | tr -d '\r' | pbcopy"

# Easier navigation: .., ..., ...., ....., ~ and -
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~='cd $HOME' # `cd` is probably faster to type though
alias -- -="cd -"

# Shortcuts
alias dl='cd $HOME/Downloads'
alias g="git"
alias h="history"
alias gc="git commit -v "

# Get the list of the most frequently typed commands in the history
alias frequentcommands="history | cut -c 8- | grep git | sort | uniq -c  | sort -n -r | head -n 10"

# Detect which `ls` flavor is in use
if ls --color >/dev/null 2>&1; then # GNU `ls`
  colorflag="--color"
else # OS X `ls`
  colorflag="-G"
fi

# List all files colorized in long format
# shellcheck disable=SC2139
alias l="ls -lhF ${colorflag}"

# List all files colorized in long format, including dot files
# shellcheck disable=SC2139
alias la="ls -lahF ${colorflag}"

# List only directories
# shellcheck disable=SC2139
alias lsd="ls -lF ${colorflag} | grep --color=never '^d'"

# Always use color output for `ls`
# shellcheck disable=SC2139
alias ls="command ls ${colorflag}"

# colors for GNU ls and ZSH
export LS_COLORS='no=00:fi=00:di=01;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:'

# colors for BSD ls
export LSCOLORS='ExGxFxDxCxFxedabagacad'

# Always enable colored `grep` output
alias grep='grep --color=auto '

# Enable aliases to be sudo’ed
alias sudo='sudo '

# Get data about the TLS certificate that a server presents, and exit
alias openssl_get_server_tls_cert='echo "Q" | openssl s_client -prexit -connect'

# IP addresses
alias pubip="dig +short myip.opendns.com @resolver1.opendns.com"

# OS X has no `md5sum`, so use `md5` as a fallback
command -v md5sum >/dev/null || alias md5sum="md5"

# OS X has no `sha1sum`, so use `shasum` as a fallback
command -v sha1sum >/dev/null || alias sha1sum="shasum"

# URL-encode strings
alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'

# One of @janmoesen’s ProTip™s
for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
  # shellcheck disable=SC2139,SC2140
  alias "$method"="lwp-request -m \"$method\""
done

# vhosts
alias hosts='sudo nano /etc/hosts'

# untar
alias untar='tar xvf'

# enable color support of ls and also add handy aliases
if command -v dircolors >/dev/null 2>&1; then
  # shellcheck disable=SC2015
  test -r "$HOME"/.dircolors && eval "$(dircolors -b "$HOME"/.dircolors)" || eval "$(dircolors -b)"
  command -v ls >/dev/null 2>&1 && alias ls='ls --color=auto'
  command -v dir >/dev/null 2>&1 && alias dir='dir --color=auto'
  command -v vdir >/dev/null && alias vdir='vdir --color=auto'

  command -v grep >/dev/null 2>&1 && alias grep='grep --color=auto'
  command -v fgrep >/dev/null 2>&1 && alias fgrep='fgrep --color=auto'
  command -v sha1sum >/dev/null 2>&1 && alias egrep='egrep --color=auto'
fi

# make less more friendly for non-text input files, see lesspipe(1)
command -v lesspipe >/dev/null 2>&1 && export LESSOPEN="|lesspipe %s"

###############################################################################
# Prompt                                                                      #
###############################################################################

if case "${COLORTERM:-""}" in "gnome-"*) true ;; *) false ;; esac && [ "$TERM" = "xterm" ] && infocmp gnome-256color >/dev/null 2>&1; then
  export TERM='gnome-256color'
elif infocmp xterm-256color >/dev/null 2>&1; then
  export TERM='xterm-256color'
fi

###############################################################################
# Git                                                                         #
###############################################################################

if command -v git >/dev/null 2>&1; then
  [ -z "${GIT_AUTHOR_NAME:-}" ] && GIT_AUTHOR_NAME="Marco Ferrari"
  [ "$(git config --global user.name)" != "$GIT_AUTHOR_NAME" ] && git config --global user.name "$GIT_AUTHOR_NAME"
  [ -z "${GIT_AUTHOR_EMAIL:-}" ] && GIT_AUTHOR_EMAIL="ferrari.marco@gmail.com"
  [ "$(git config --global user.email)" != "$GIT_AUTHOR_EMAIL" ] && git config --global user.email "$GIT_AUTHOR_EMAIL"
  [ -z "${GH_USER:-}" ] && GH_USER="ferrarimarco"
  [ "$(git config --global github.user)" != "$GH_USER" ] && git config --global github.user "$GH_USER"
  [ -z "${GIT_COMMIT_SIGN:-}" ] && GIT_COMMIT_SIGN=false
  [ "$(git config --global commit.gpgsign)" != "$GIT_COMMIT_SIGN" ] && git config --global commit.gpgsign "$GIT_COMMIT_SIGN"
fi

###############################################################################
# Completion                                                                  #
###############################################################################

###############################################################################
# Debian                                                                      #
###############################################################################

if is_debian; then
  # Get the list of the avaliable verions of a package to install
  alias apt-get-available-package-versions="apt-cache madison"
fi
