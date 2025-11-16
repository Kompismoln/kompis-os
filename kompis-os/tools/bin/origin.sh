#!/usr/bin/env bash

origin() {
    local cmd="$1"
    local checked_aliases=()

    if [[ -z "$cmd" ]]; then
        echo "Usage: origin <command>" >&2
        return 1
    fi

    # Track the command through aliases and functions
    while true; do
        # Check if it's an alias
        local alias_def=$(alias "$cmd" 2>/dev/null | sed "s/^alias $cmd=//;s/^'//;s/'$//")

        if [[ -n "$alias_def" ]]; then
            echo "'$cmd' is an alias for '${alias_def%% *}' in shell '$BASH': '$alias_def'"

            # Prevent infinite loops
            if [[ " ${checked_aliases[@]} " =~ " ${cmd} " ]]; then
                echo "Circular alias detected, stopping."
                return 0
            fi
            checked_aliases+=("$cmd")

            # Extract the next command to check
            cmd="${alias_def%% *}"
            continue
        fi

        # Check if it's a function
        if declare -f "$cmd" &>/dev/null; then
            echo "'$cmd' is a function in shell '$BASH'"
            return 0
        fi

        # Check if it's a builtin
        if type -t "$cmd" 2>/dev/null | grep -q "builtin"; then
            echo "'$cmd' is a shell builtin"
            return 0
        fi

        break
    done

    # Find in PATH
    local cmd_path=$(command -v "$cmd" 2>/dev/null)

    if [[ -z "$cmd_path" ]]; then
        echo "'$cmd' not found" >&2
        return 1
    fi

    echo "'$cmd' found in PATH as '$cmd_path'"

    # Follow symlink chain
    while [[ -L "$cmd_path" ]]; do
        local target=$(readlink "$cmd_path")

        # Handle relative symlinks
        if [[ "$target" != /* ]]; then
            target="$(dirname "$cmd_path")/$target"
        fi

        echo "'$cmd_path' is a symlink to '$target'"
        cmd_path="$target"
    done

    # Final file type
    if [[ -f "$cmd_path" ]]; then
        if [[ -x "$cmd_path" ]]; then
            echo "'$cmd_path' is an executable"
        else
            echo "'$cmd_path' is a file"
        fi
    elif [[ -d "$cmd_path" ]]; then
        echo "'$cmd_path' is a directory"
    else
        echo "'$cmd_path' exists but type unknown"
    fi
}

# Run if executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    origin "$@"
fi
