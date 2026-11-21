#!/usr/bin/env zsh
# Shows a checklist of modules, then runs the ticked ones. Takes no arguments.
# The tens digit of a module number is its phase: phases run in order, modules in one phase run in parallel.
set -euo pipefail
export DOTFILES_ROOT="${0:A:h}"
source "$DOTFILES_ROOT/lib/common.sh"
(( $# == 0 )) || die "no arguments, the checklist asks for everything"
[[ -t 0 ]] || die "needs a terminal"

typeset -A phase_title=(
  1 "Package manager"  2 "Terminal"      3 "Computer"
  4 "Hotkeys"          5 "Sign-in apps"  6 "SSH"
  7 "Agent harness"    8 "Media folders" 9 "More apps"
)

# Module name is the folder without its number, description is line 2 of its setup.sh.
names=(${DOTFILES_ROOT}/modules/*/setup.sh(N:h:t))
descs=(); checked=(); phases=(); namew=0
for n in $names; do
  descs+=("$(sed -n '2s/^# *//p' "$DOTFILES_ROOT/modules/$n/setup.sh")")
  checked+=(1); phases+=(${n[1]})
  (( ${#n} - 3 > namew )) && namew=$(( ${#n} - 3 ))
done

# Rows are phase headers and modules. row_mod[r] is the module index, 0 for a header.
rows=(); row_mod=(); prev=""
for i in {1..${#names}}; do
  if [[ "${phases[i]}" != "$prev" ]]; then
    rows+=("${phases[i]}"); row_mod+=(0); prev="${phases[i]}"
  fi
  rows+=("$i"); row_mod+=($i)
done

dim=$'\e[2m'; bold=$'\e[1m'; green=$'\e[32m'; cyan=$'\e[36m'; off=$'\e[0m'
cur=1; top=1
cols=${COLUMNS:-$(tput cols)}
lines=${LINES:-$(tput lines)}
height=$(( ${#rows} < lines - 4 ? ${#rows} : lines - 4 ))
(( height > 0 )) || height=${#rows}

# Count of ticked modules in a phase, to say whether it runs in parallel.
ticked_in() { local i c=0; for i in {1..${#names}}; do [[ "${phases[i]}" == "$1" ]] && (( checked[i] )) && c=$(( c + 1 )); done; print $c; }

draw() {
  local r i n desc sp line mark label pad nsel=0 descw
  for i in {1..${#names}}; do (( checked[i] )) && nsel=$(( nsel + 1 )); done
  # Keep the cursor row inside the window.
  for r in {1..${#rows}}; do (( row_mod[r] == cur )) && break; done
  (( r < top )) && top=$r
  (( r >= top + height )) && top=$(( r - height + 1 ))
  descw=$(( cols - namew - 7 ))
  for (( r = top; r < top + height; r++ )); do
    i=${row_mod[r]}
    if (( i == 0 )); then
      label="${rows[r]}  ${phase_title[${rows[r]}]}"
      n=$(ticked_in ${rows[r]})
      (( n > 1 )) && label+="  ${dim}run together${off}${bold}"
      line="${bold}Phase ${label}${off}"
    else
      if (( checked[i] )); then mark="${green}●${off}"; else mark="${dim}○${off}"; fi
      desc="${descs[i]}"
      (( ${#desc} > descw )) && desc="${desc[1,descw-1]}…"
      pad=$(( namew - ${#names[i]} + 6 ))
      printf -v sp '%*s' $pad ''
      if (( i == cur )); then
        line="${cyan}▸${off} ${mark} ${bold}${names[i]#*-}${off}${sp}${dim}${desc}${off}"
      elif (( checked[i] )); then
        line="  ${mark} ${names[i]#*-}${sp}${dim}${desc}${off}"
      else
        line="  ${mark} ${dim}${names[i]#*-}${sp}${desc}${off}"
      fi
    fi
    print -r -- $'\e[2K\r'"$line"
  done
  print -r -- $'\e[2K'
  print -r -- $'\e[2K\r'"${dim}↑↓ move   space tick   a all   n none   enter install   q quit${off}   ${nsel} of ${#names} ticked"
}

restore() { print -n $'\e[?25h'; }
trap restore EXIT
print -n $'\e[?25l'
draw
while true; do
  read -rsk1 key
  case $key in
    $'\e') read -rsk2 seq
           case $seq in '[A') (( cur > 1 )) && (( cur-- ));; '[B') (( cur < ${#names} )) && (( cur++ ));; esac;;
    k) (( cur > 1 )) && (( cur-- ));;
    j) (( cur < ${#names} )) && (( cur++ ));;
    ' ') checked[cur]=$(( 1 - checked[cur] ));;
    a) for i in {1..${#names}}; do checked[i]=1; done;;
    n) for i in {1..${#names}}; do checked[i]=0; done;;
    q) exit 0;;
    $'\n') break;;
  esac
  print -n $'\e['$(( height + 2 ))'A'
  draw
done
restore
print

logdir="$(mktemp -d)"
rmdir "${TMPDIR:-/tmp}/dotfiles-brew.lock" 2>/dev/null || true   # left behind by an interrupted run
failed=0
for ph in ${(u)phases}; do
  todo=()
  for i in {1..${#names}}; do
    [[ "${phases[i]}" == "$ph" ]] && (( checked[i] )) && todo+=(${names[i]})
  done
  (( ${#todo} )) || continue

  if (( ${#todo} == 1 )); then
    log "${phase_title[$ph]}: ${todo[1]}"
    zsh "$DOTFILES_ROOT/modules/${todo[1]}/setup.sh" || { warn "${todo[1]} failed"; failed=1; break; }
    continue
  fi

  short=(${todo#*-})
  log "${phase_title[$ph]}: ${(j:, :)short} in parallel"
  export HOMEBREW_NO_AUTO_UPDATE=1
  typeset -A pids=() rc=() finished=()
  for n in $todo; do
    zsh "$DOTFILES_ROOT/modules/$n/setup.sh" >"$logdir/$n.log" 2>&1 &
    lastpid=$!
    pids[$n]=$lastpid
  done

  # One live line per module: spinner, name, last line of its log. Redrawn until every module has ended.
  spin=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏); frame=0; first=1
  print -n $'\e[?25l'
  while true; do
    alive=0
    for n in $todo; do
      [[ -n "${finished[$n]:-}" ]] && continue
      if kill -0 ${pids[$n]} 2>/dev/null; then alive=1; else
        rc[$n]=0; wait ${pids[$n]} || rc[$n]=$?; finished[$n]=1
      fi
    done
    (( first )) || print -n $'\e['${#todo}'A'
    first=0
    for n in $todo; do
      if [[ -z "${finished[$n]:-}" ]]; then mark="${cyan}${spin[frame % 10 + 1]}${off}"
      elif (( rc[$n] == 0 )); then mark="${green}✓${off}"
      else mark=$'\e[31m✗'"${off}"; fi
      last="$(tr '\r' '\n' <"$logdir/$n.log" | sed $'s/\e\\[[0-9;?]*[A-Za-z]//g' | grep -v '^[[:space:]]*$' | tail -n1)"
      pad=$(( namew - ${#n} + 6 ))
      printf -v sp '%*s' $pad ''
      last="${last[1,cols-namew-9]}"
      print -r -- $'\e[2K\r'"  ${mark} ${n#*-}${sp}${dim}${last}${off}"
    done
    (( alive )) || break
    frame=$(( frame + 1 )); sleep 0.15
  done
  print -n $'\e[?25h'
  bad=0
  for n in $todo; do
    if (( rc[$n] != 0 )); then
      print -P "  %F{red}failed%f ${n#*-}, log $logdir/$n.log"
      tail -5 "$logdir/$n.log" | sed 's/^/        /'
      bad=1
    fi
  done
  unset HOMEBREW_NO_AUTO_UPDATE
  (( bad )) && { failed=1; break; }
done

(( failed )) && exit 1
log "done"
