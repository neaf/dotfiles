# global {{{1
alias tmux="TERM=screen-256color-bce tmux"
# Show history
alias history='fc -l 1'
alias x=extract
# ls
alias ls="ls -h --color=tty"
alias ll='ls -lh --color=tty'
alias l="ls -h -1 --color=tty"
# tree
alias lta='tree -L 2'
alias lt='tree -L 2 -d'
#alias lt="ls -xCt" # show files in columnt sorted by modification
alias um="sudo umount"
alias po="ping onet.pl"
alias df="df -h"
alias '?=bc -l <<<'
alias serve="python2 -m SimpleHTTPServer 8000"
# always ask for confirmation for these while using ssh:
alias halt='rly sudo halt'
alias reboot='rly sudo reboot'
alias shutdown='rly sudo shutdown'
alias hist_off='HISTFILE='
alias hist_on='HISTFILE=$HOME/.zsh_history'
alias svim="vim -n -c 'set nobackup'"
alias dssh="dropship ssh"
alias vssh="cd /opt/starter-kit && vagrant ssh"
# disable globbing {{{1
# Disable globbing. stolen from prezto
alias find='noglob find'
alias history='noglob history'
alias locate='noglob locate'
alias rake='noglob rake'
alias rsync='noglob rsync'
alias scp='noglob scp'
alias sftp='noglob sftp'
alias nmap='noglob nmap'
# git {{{1
alias g='git'
alias gst='git status -sb'
GL_HASH="%C(yellow)%h%Creset"
GL_RELATIVE_TIME="%Cgreen(%ar)%Creset"
GL_AUTHOR="%C(bold blue)<%an>%Creset"
GL_REFS="%C(red)%d%Creset"
GL_SUBJECT="%s"
GL_FORMAT="$GL_HASH $GL_RELATIVE_TIME $GL_AUTHOR $GL_REFS $GL_SUBJECT"
alias gl="git log --abbrev-commit --pretty=oneline --no-merges --decorate --pretty='tformat:${GL_FORMAT}'"
alias gls="git log --abbrev-commit --pretty=oneline --stat --decorate --pretty='tformat:${GL_FORMAT}'"
alias gg="git log --abbrev-commit --pretty=oneline --graph --decorate --pretty='tformat:${GL_FORMAT}'"
alias glast="git --no-pager log --abbrev-commit --no-merges --pretty=oneline --stat --decorate --pretty='tformat:${GL_FORMAT}'"
alias glo="git --no-pager log --oneline --decorate --graph --abbrev-commit --date=relative --pretty='tformat:${GL_FORMAT}' -n 10"
alias gla="git log --all --oneline --decorate --graph --abbrev-commit --date=relative --pretty='tformat:${GL_FORMAT}' -n 10"
glastupstream(){
        glast ..origin/$(current_branch) $*
}
alias gp='git push'
alias gu='git pull --rebase'
alias gf='git fetch'
alias gd='git diff'
alias gdi='git diff --word-diff' # show changes in each word in each line
alias gsh='git stash'
alias gdc='git diff --cached'
alias gc='git commit -v'
alias gca='git commit -v -a'
alias gco='git checkout'
alias gb='git branch'
alias gba='git branch -a'
alias gcount='git shortlog -sn'
alias gcp='git cherry-pick'
alias gr='git for-each-ref --count=30 --sort=-committerdate refs/remotes/ --format="%(refname:short) (%(authordate))"'
# Git and svn mix
alias git-svn-dcommit-push='git svn dcommit && git push github master:svntrunk'
#
# Will return the current branch name
# Usage example: git pull origin $(current_branch)
#
function current_branch() {
  ref=$(git symbolic-ref HEAD 2> /dev/null) || return
  echo ${ref#refs/heads/}
}
# these aliases take advantage of the previous function
alias ggpull='git pull origin $(current_branch)'
alias ggpush='git push origin $(current_branch)'
alias ggpnp='git pull origin $(current_branch) && git push origin $(current_branch)'
# modeline {{{1
# vim: fdm=marker:fdl=0
