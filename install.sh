#!/usr/bin/env zsh
# Shows a checklist of modules, then runs the ticked ones in order. Takes no arguments.
set -euo pipefail
export DOTFILES_ROOT="${0:A:h}"
source "$DOTFILES_ROOT/lib/common.sh"
(( $# == 0 )) || die "no arguments, the checklist asks for everything"
[[ -t 0 ]] || die "needs a terminal"

# Module name is the folder, description is line 2 of its setup.sh.
names=(${DOTFILES_ROOT}/modules/*/setup.sh(N:h:t))
descs=()
for n in $names; do descs+=("$(sed -n '2s/^# *//p' "$DOTFILES_ROOT/modules/$n/setup.sh")"); done
checked=(); for n in $names; do checked+=(1); done

cur=1
draw() {
  local i mark
  for i in {1..${#names}}; do
    mark=" "; (( checked[i] )) && mark="x"
    (( i == cur )) && print -n $'\e[7m'
    print -r -- "[$mark] ${names[i]:s/#[0-9]##-/}  ${descs[i]}" | sed 's/^/  /'
    (( i == cur )) && print -n $'\e[0m'
  done
}

print "up/down move, space toggles, a all, n none, enter runs, q quits"
draw
while true; do
  read -rsk1 key
  case $key in
    $'\e') read -rsk2 seq
           case $seq in '[A') (( cur > 1 )) && (( cur-- ));; '[B') (( cur < ${#names} )) && (( cur++ ));; esac;;
    ' ') checked[cur]=$(( 1 - checked[cur] ));;
    a) for i in {1..${#names}}; do checked[i]=1; done;;
    n) for i in {1..${#names}}; do checked[i]=0; done;;
    q) exit 0;;
    $'\n') break;;
  esac
  print -n $'\e['${#names}'A'
  draw
done

for i in {1..${#names}}; do
  (( checked[i] )) || continue
  log "module: ${names[i]}"
  zsh "$DOTFILES_ROOT/modules/${names[i]}/setup.sh"
done
