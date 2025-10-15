wcd() {
    local repo_name=$1
    local ignore="yes"

    if [[ "$repo_name" == "--no-ignore" ]] || [[ "$repo_name" == "-u" ]]; then
        repo_name=$2
        ignore="no"
    elif [[ "$2" == "--no-ignore" ]] || [[ "$2" == "-u" ]]; then
        ignore="no"
    fi

    if [[ -z "$repo_name" ]]; then
        echo "Please provide a repository name."
        return 1
    fi

    local repos
    IFS=' ' read -r -a repos <<< "$(__wcd_find_repos "$repo_name" "$ignore")"

    if [[ -n "${repos[0]}" ]]; then
        if [[ -n "${repos[1]}" ]]; then
            __wcd_select_and_cd_repo "${repos[@]}"
        else
            cd "${repos[0]}"
        fi
    else
        echo "Repository not found."
        return 1
    fi
}

__wcd_is_repo() {
    local dir=$1
    local markers
    markers=$(test -z "$WCD_REPO_MARKERS" && echo ".git" || echo "$WCD_REPO_MARKERS")

    local marker_list=()
    IFS=':' read -r -a marker_list <<< "$markers"
    for marker in "${marker_list[@]}"; do
        if [[ -f "$dir/$marker" ]] || [[ -d "$dir/$marker" ]]; then
            return 0
        fi
    done
    return 1
}

__wcd_find_repos() {
    local repo_name=$1
    local ignore=$2
    local base_dir=$(test -z "$WCD_BASE_DIR" && echo ~/workspace || echo $WCD_BASE_DIR)

    # Initialize a queue with the base directory and expand tildes
    local queue=()
    local base_dirs=()
    IFS=':' read -r -a base_dirs <<< "$base_dir"
    for dir in "${base_dirs[@]}"; do
        queue+=("${dir/#\~/$HOME}")
    done
    local repos=()

    [[ -n "$WCD_DEBUG" ]] && echo "[DEBUG] Starting search for '$repo_name' in: $base_dir" >&2

    # Breadth-first search, skipping subdirectories of git repos
    while [[ ${#queue[@]} -gt 0 ]]; do
        local current_dir=${queue[0]}
        queue=("${queue[@]:1}")  # Dequeue

        [[ -n "$WCD_DEBUG" ]] && echo "[DEBUG] Visiting:          $current_dir" >&2

        if __wcd_is_repo "$current_dir"; then
            [[ -n "$WCD_DEBUG" ]] && echo "[DEBUG] Skipped (is repo): $current_dir" >&2
            continue  # Skip adding subdirectories if a repo is found
        fi

        if [[ "$ignore" == "yes" ]] && ([[ -f "$current_dir/.wcdignore" ]] || [[ -f "$current_dir/$repo_name/.wcdignore" ]]); then
            [[ -n "$WCD_DEBUG" ]] && echo "[DEBUG] Skipped (ignored): $current_dir" >&2
            continue  # Skip adding subdirectories if an ignore-file is found
        fi

        # Check if the current directory contains the target repo (case sensitive)
        for sub_dir in "$current_dir"/*; do
            if [[ -d "$sub_dir" ]]; then
                local name=$(basename "$sub_dir")
                if [[ "$name" == "$repo_name" ]] && __wcd_is_repo "$sub_dir"; then
                    [[ -n "$WCD_DEBUG" ]] && echo "[DEBUG] Found repo:        $sub_dir" >&2
                    repos+=("$sub_dir")
                fi
            fi
        done

        # Enqueue all immediate subdirectories
        for sub_dir in "$current_dir"/*; do
            if [[ -d "$sub_dir" ]]; then
                queue+=("$sub_dir")
            fi
        done
    done

    # Output all found repos
    for repo in "${repos[@]}"; do
        echo -n "$repo "
    done
}

__wcd_select_and_cd_repo() {
    echo "Multiple repositories found. Please select one:"

    # Check if running in non-interactive mode (no TTY)
    if [[ ! -t 0 ]]; then
        return 1
    fi

    local i=1
    for repo in "$@"; do
        echo "$i: $repo"
        ((i++))
    done

    local selection
    while [[ -z "${!selection}" ]]; do
        [[ -n "$selection" ]] && echo "Please enter a number smaller than $i."
        read -p "Enter your choice: " selection
        if ! [[ $selection =~ ^[0-9]+$ ]]; then
            echo "Please enter a valid number."
            unset selection
        fi
    done
    cd "${!selection}"
}

__wcd_find_any_repos() {
    local ignore="yes"
    # Check if --no-ignore or -u is in the command line
    for arg in "${COMP_WORDS[@]}"; do
        if [[ "$arg" == "--no-ignore" ]] || [[ "$arg" == "-u" ]]; then
            ignore="no"
            break
        fi
    done

    local base_dir=$(test -z "$WCD_BASE_DIR" && echo ~/workspace || echo $WCD_BASE_DIR)
    # Initialize queue and expand tildes
    local queue=()
    local base_dirs=()
    IFS=':' read -r -a base_dirs <<< "$base_dir"
    for dir in "${base_dirs[@]}"; do
        queue+=("${dir/#\~/$HOME}")
    done
    local repos=()

    # Breadth first search, skipping subdirectories of git repos
    while [[ ${#queue[@]} -gt 0 ]]; do
        local current_dir=${queue[0]}
        queue=("${queue[@]:1}") # Dequeue

        if [[ "$ignore" == "yes" ]] && [[ -f "$current_dir/.wcdignore" ]]; then
            continue  # Skip adding subdirectories if an ignore-file is found
        fi

        # Check if the current directory contains the target repo
        if __wcd_is_repo "$current_dir"; then
            repos+=("$current_dir")
            continue # Skip adding subdirectories if a repo is found
        fi

        # Enqueue all immediate subdirectories
        for sub_dir in "$current_dir"/*; do
            if [[ -d $sub_dir ]]; then
                queue+=("$sub_dir")
            fi
        done
    done

    # Output all found repos
    for repo in "${repos[@]}"; do
        repo=$(basename "$repo")
        echo "$repo"
    done
}

_wcd_completion() {
    local cur=${COMP_WORDS[COMP_CWORD]}

    # Complete flags
    if [[ "$cur" == -* ]]; then
        COMPREPLY=($(compgen -W "--no-ignore -u" -- "$cur"))
        return
    fi

    any_repos=$(__wcd_find_any_repos | sort -u)
    COMPREPLY=($(echo $any_repos | tr " " "\n" | grep "^$cur"))
    if test -z "$COMPREPLY"; then
        COMPREPLY=($(echo $any_repos | tr " " "\n" | grep "$cur"))
    fi
}
complete -F _wcd_completion wcd
