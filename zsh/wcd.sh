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
    repos=($(__wcd_find_repos "$repo_name" "$ignore"))

    if [[ -n "${repos[1]}" ]]; then
        if [[ -n "${repos[2]}" ]]; then
            __wcd_select_and_cd_repo "${repos[@]}"
        else
            cd "${repos[1]}"
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

    local -a marker_list
    IFS=':' read -r -A marker_list <<< "$markers"
    for marker in "${marker_list[@]}"; do
        if [[ -e "$dir/$marker" ]]; then
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
    local -a queue
    local -a base_dirs
    IFS=':' read -r -A base_dirs <<< "$base_dir"
    for dir in "${base_dirs[@]}"; do
        queue+=("${dir/#\~/$HOME}")
    done
    local -a repos

    # Breadth-first search, skipping subdirectories of git repos
    while [[ -n "${queue[1]}" ]]; do
        local current_dir="${queue[1]}"
        queue=("${queue[@]:1}")

        if __wcd_is_repo "$current_dir"; then
            continue  # Skip adding subdirectories if a repo is found
        fi

        if [[ "$ignore" == "yes" ]] && ([[ -f "$current_dir/.wcdignore" ]] || [[ -f "$current_dir/$repo_name/.wcdignore" ]]); then
            continue  # Skip adding subdirectories if an ignore-file is found
        fi

        # Check if the current directory contains the target repo (case sensitive)
        for sub_dir in "$current_dir"/*(N); do
            if [[ -d "$sub_dir" ]]; then
                local dir_name="${sub_dir:t}"
                if [[ "$dir_name" == "$repo_name" ]] && __wcd_is_repo "$sub_dir"; then
                    repos+=("$sub_dir")
                fi
            fi
        done

        # Enqueue all immediate subdirectories
        # Use a nullglob *(N) to avoid errors when no matches are found
        for sub_dir in "$current_dir"/*(N); do
            if [[ -d "$sub_dir" ]]; then
                queue+=("$sub_dir")
            fi
        done
    done

    # Output all found repos
    for repo in "${repos[@]}"; do
        echo "$repo"
    done
}

__wcd_select_and_cd_repo() {
    echo "Multiple repositories found. Please select one:"
    local i=1
    for repo in "$@"; do
        echo "$i: $repo"
        ((i++))
    done

    local selection
    while :; do
        [[ -n "$selection" ]] && echo "Please enter a number smaller than $(( $# + 1 ))."
        read "selection?Enter your choice: " || return
        if ! [[ "$selection" =~ ^[0-9]+$ ]]; then
            echo "Please enter a valid number."
            continue
        fi
        if (( selection < 1 || selection > $# )); then
            continue
        fi
        break
    done
    cd "${@[$selection]}"
}

__wcd_find_any_repos() {
    local ignore="yes"
    # Check if --no-ignore or -u is in the command line
    for arg in "${words[@]}"; do
        if [[ "$arg" == "--no-ignore" ]] || [[ "$arg" == "-u" ]]; then
            ignore="no"
            break
        fi
    done

    local base_dir=$(test -z "$WCD_BASE_DIR" && echo ~/workspace || echo $WCD_BASE_DIR)
    # Initialize queue and expand tildes
    local -a queue
    local -a base_dirs
    IFS=':' read -r -A base_dirs <<< "$base_dir"
    for dir in "${base_dirs[@]}"; do
        queue+=("${dir/#\~/$HOME}")
    done
    local -a repos

    # Breadth first search, skipping subdirectories of git repos
    while [[ -n "${queue[1]}" ]]; do
        local current_dir="${queue[1]}"
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
        # Use a nullglob *(N) to avoid errors when no matches are found
        for sub_dir in "$current_dir"/*(N); do
            if [[ -d "$sub_dir" ]]; then
                queue+=("$sub_dir")
            fi
        done
    done

    # Output all found repos
    for repo in "${repos[@]}"; do
        echo "${repo:t}"
    done
}

compctl -K __wcd_completion wcd
__wcd_completion() {
    local current_word="${words[CURRENT]}"

    # Complete flags
    if [[ "$current_word" == -* ]]; then
        reply=("--no-ignore" "-u")
        return
    fi

    reply=($(__wcd_find_any_repos))
}
