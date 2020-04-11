#!/usr/bin/env zsh

# shellcheck source=/dev/null
. "$HOME"/.shells/.all/interactive.sh

###############################################################################
# Expansion and globbing                                                      #
###############################################################################

setopt EXTENDED_GLOB # Treat the ‘#’, ‘~’ and ‘^’ characters as part of patterns for filename generation

###############################################################################
# Changing directories                                                        #
###############################################################################

setopt AUTO_CD           # If a command is issued that can’t be executed as a normal command, and the command is the name of a directory, perform the cd command to that directory
setopt AUTO_PUSHD        # Make cd push the old directory onto the directory stack.
setopt CDABLE_VARS       # If the argument to a cd command (or an implied cd with the AUTO_CD option set) is not a directory, and does not begin with a slash, try to expand the expression as if it were preceded by a ‘~’
setopt PUSHD_IGNORE_DUPS # Don’t push multiple copies of the same directory onto the directory stack.
setopt PUSHD_MINUS       # Exchanges the meanings of ‘+’ and ‘-’ when used with a number to specify a directory in the stack.
setopt PUSHD_SILENT      # Do not print the directory stack after pushd or popd.
setopt PUSHD_TO_HOME     # Have pushd with no arguments act like ‘pushd $HOME’.

###############################################################################
# Input/Output                                                                #
###############################################################################

setopt CORRECT     # Try to correct the spelling of commands.
setopt CORRECT_ALL # Try to correct the spelling of all arguments in a line.

###############################################################################
# Completion                                                                  #
###############################################################################

setopt AUTO_MENU          # Automatically use menu completion after the second consecutive request for completion, for example by pressing the tab key repeatedly.
setopt ALWAYS_TO_END      # If a completion is performed with the cursor within a word, and a full completion is inserted, the cursor is moved to the end of the word.
setopt COMPLETE_IN_WORD   # If unset, the cursor is set to the end of the word if completion is started.
unsetopt COMPLETE_ALIASES # Complete aliases on the command line
unsetopt MENU_COMPLETE    # If MENU_COMPLETE is enabled, on an ambiguous completion, instead of listing possibilities or beeping, insert the first match immediately.

add_to_fpath() {
    PATH_TO_ADD="${1}"
    VARIABLE_NAME="${2}"
    typeset -U FPATH fpath
    if [ -d "$PATH_TO_ADD" ]; then
        fpath=("$PATH_TO_ADD" $fpath)
    else
        echo "WARNING: Cannot add $VARIABLE_NAME (set to: $PATH_TO_ADD) to fpath because it doesn't exist or it's empty."
    fi
}

add_to_fpath "$ZSH_SITE_FUNCTIONS_PATH" "ZSH_SITE_FUNCTIONS_PATH"
add_to_fpath "$ZSH_COMPLETIONS_PATH" "ZSH_COMPLETIONS_PATH"

# shellcheck source=/dev/null
command -v kubectl >/dev/null 2>&1 && . <(kubectl completion zsh)

zmodload -i zsh/complist

WORDCHARS=''

# case insensitive (all), partial-word and substring completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'

# Complete . and .. special directories
zstyle ':completion:*' special-dirs true

# If the zsh/complist module is loaded, this style can be used to set color specifications
zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"

# Complete kill and ps
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

# disable named-directories autocompletion
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# Use caching so that commands like apt and dpkg complete are useable
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path $ZSH_CACHE_DIR

# Don't complete uninteresting users
zstyle ':completion:*:*:*:users' ignored-patterns \
        adm amanda apache at avahi avahi-autoipd beaglidx bin cacti canna \
        clamav daemon dbus distcache dnsmasq dovecot fax ftp games gdm \
        gkrellmd gopher hacluster haldaemon halt hsqldb ident junkbust kdm \
        ldap lp mail mailman mailnull man messagebus  mldonkey mysql nagios \
        named netdump news nfsnobody nobody nscd ntp nut nx obsrun openvpn \
        operator pcap polkitd postfix postgres privoxy pulse pvm quagga radvd \
        rpc rpcuser rpm rtkit scard shutdown squid sshd statd svn sync tftp \
        usbmux uucp vcsa wwwrun xfs '_*'

# ... unless we really want to.
zstyle '*' single-ignored show

expand-or-complete-with-dots() {
    # toggle line-wrapping off and back on again
    [[ -n "$terminfo[rmam]" && -n "$terminfo[smam]" ]] && echoti rmam
    print -Pn "%{%F{red}......%f%}"
    [[ -n "$terminfo[rmam]" && -n "$terminfo[smam]" ]] && echoti smam

    zle expand-or-complete
    zle redisplay
  }
zle -N expand-or-complete-with-dots
bindkey "^I" expand-or-complete-with-dots

autoload -Uz compinit
compinit

###############################################################################
# Key bindings                                                                #
###############################################################################

# Make sure that the terminal is in application mode when zle is active, since
# only then values from $terminfo are valid
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
    function zle-line-init() {
    echoti smkx
    }
    function zle-line-finish() {
        echoti rmkx
    }
    zle -N zle-line-init
    zle -N zle-line-finish
fi

bindkey -e                                            # Use emacs key bindings

bindkey '\ew' kill-region                             # [Esc-w] - Kill from the cursor to the mark
bindkey '^r' history-incremental-search-backward      # [Ctrl-r] - Search backward incrementally for a specified string. The string may begin with ^ to anchor the search to the beginning of the line.
if [[ "${terminfo[kpp]}" != "" ]]; then
  bindkey "${terminfo[kpp]}" up-line-or-history       # [PageUp] - Up a line of history
fi
if [[ "${terminfo[knp]}" != "" ]]; then
  bindkey "${terminfo[knp]}" down-line-or-history     # [PageDown] - Down a line of history
fi

# start typing + [Up-Arrow] - fuzzy find history forward
if [[ "${terminfo[kcuu1]}" != "" ]]; then
  autoload -U up-line-or-beginning-search
  zle -N up-line-or-beginning-search
  bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
fi
# start typing + [Down-Arrow] - fuzzy find history backward
if [[ "${terminfo[kcud1]}" != "" ]]; then
  autoload -U down-line-or-beginning-search
  zle -N down-line-or-beginning-search
  bindkey "${terminfo[kcud1]}" down-line-or-beginning-search
fi

if [[ "${terminfo[khome]}" != "" ]]; then
  bindkey "${terminfo[khome]}" beginning-of-line      # [Home] - Go to beginning of line
fi
if [[ "${terminfo[kend]}" != "" ]]; then
  bindkey "${terminfo[kend]}"  end-of-line            # [End] - Go to end of line
fi

bindkey ' ' magic-space                               # [Space] - do history expansion

bindkey '^[[1;5C' forward-word                        # [Ctrl-RightArrow] - move forward one word
bindkey '^[[1;5D' backward-word                       # [Ctrl-LeftArrow] - move backward one word

if [[ "${terminfo[kcbt]}" != "" ]]; then
  bindkey "${terminfo[kcbt]}" reverse-menu-complete   # [Shift-Tab] - move through the completion menu backwards
fi

bindkey '^?' backward-delete-char                     # [Backspace] - delete backward
if [[ "${terminfo[kdch1]}" != "" ]]; then
  bindkey "${terminfo[kdch1]}" delete-char            # [Delete] - delete forward
else
  bindkey "^[[3~" delete-char
  bindkey "^[3;5~" delete-char
  bindkey "\e[3~" delete-char
fi

# Edit the current command line in $EDITOR
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line

# file rename magick
bindkey "^[m" copy-prev-shell-word

###############################################################################
# Prompt                                                                      #
###############################################################################

# Load the theme
source_file_if_available "$ZSH_THEME_PATH" "ZSH_THEME_PATH"

# Load the theme configuration
source_file_if_available "$ZSH_THEME_CONFIGURATION_PATH" "ZSH_THEME_CONFIGURATION_PATH"

# Load syntax highlighting
source_file_if_available "$ZSH_SYNTAX_HIGHLIGHTING_PATH" "ZSH_SYNTAX_HIGHLIGHTING_PATH"

# Load autosuggestion configuration
source_file_if_available "$ZSH_AUTOSUGGESTIONS_CONFIGURATION_PATH" "ZSH_AUTOSUGGESTIONS_CONFIGURATION_PATH"

# Show expensive prompt segments only when needed
typeset -g POWERLEVEL9K_GCLOUD_SHOW_ON_COMMAND='gcloud'
typeset -g POWERLEVEL9K_GOOGLE_APP_CRED_SHOW_ON_COMMAND='gcloud'
typeset -g POWERLEVEL9K_KUBECONTEXT_SHOW_ON_COMMAND='kubectl|helm|istioctl'
typeset -g POWERLEVEL9K_TERRAFORM_SHOW_ON_COMMAND='terraform'

###############################################################################
# Aliases                                                                     #
###############################################################################

# shows the whole history
alias history="history 0"
