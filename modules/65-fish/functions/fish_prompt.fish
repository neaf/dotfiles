# Prompt in the robbyrussell layout: arrow, path, git branch and dirty marker.
function fish_prompt
    set -l last_status $status
    set -g fish_prompt_pwd_dir_length 0  # full path, only ~ is contracted

    set -l arrow_color green
    test $last_status -ne 0; and set arrow_color red
    set_color --bold $arrow_color; echo -n '➜ '
    set_color cyan; echo -n (prompt_pwd)

    set -l branch (command git --no-optional-locks symbolic-ref --short HEAD 2>/dev/null; or command git --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    if test -n "$branch"
        set_color --bold blue; echo -n ' git:('
        set_color red; echo -n $branch
        if test -n "$(command git --no-optional-locks status --porcelain 2>/dev/null)"
            set_color yellow; echo -n ' ✗'
        end
        set_color blue; echo -n ')'
    end
    set_color normal; echo -n ' '
end
