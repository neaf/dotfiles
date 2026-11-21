# Destructive: drops all tracked changes and untracked files, back to HEAD. Asks first.
function greset
    command git rev-parse --is-inside-work-tree >/dev/null 2>&1; or begin
        echo "not a git repository"; return 1
    end
    set -l changes (command git status --short)
    if test -z "$changes"
        echo "already clean"; return 0
    end
    set_color red; echo "Will discard:"; set_color normal
    printf '  %s\n' $changes
    read -l -P "Reset to HEAD and delete untracked files? [y/N] " answer
    if test "$answer" = y -o "$answer" = Y
        command git reset --hard HEAD; and command git clean -fd
    else
        echo "aborted"
    end
end
