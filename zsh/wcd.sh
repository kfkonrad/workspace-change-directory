wcd() {
    local repo_name=$1

    if [[ -z "$repo_name" ]]; then
        echo "Please provide a repository name."
        return 1
    fi

    local repos
    repos=($(__wcd_find_repos "$repo_name"))

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

__wcd_find_repos() {
    local repo_name=$1
    local base_dir=$(test -z "$WCD_BASE_DIR" && echo ~/workspace || echo $WCD_BASE_DIR)

    # Initialize a queue with the base directory
    local -a queue=("$base_dir")
    local -a repos

    # Breadth-first search, skipping subdirectories of git repos
    while [[ -n "${queue[1]}" ]]; do
        local current_dir="${queue[1]}"
        queue=("${queue[@]:1}")

        if [[ -d "$current_dir/.git" ]]; then
            continue  # Skip adding subdirectories if a repo is found
        fi

        if [[ -f "$current_dir/.wcdignore" ]] || [[ -f "$current_dir/$repo_name/.wcdignore" ]]; then
            continue  # Skip adding subdirectories if an ignore-file is found
        fi

        # Check if the current directory contains the target repo
        if [[ -d "$current_dir/$repo_name/.git" ]]; then
            repos+=("$current_dir/$repo_name")
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
    local base_dir=$(test -z "$WCD_BASE_DIR" && echo ~/workspace || echo $WCD_BASE_DIR)
    local -a queue=("$base_dir")
    local -a repos

    # Breadth first search, skipping subdirectories of git repos
    while [[ -n "${queue[1]}" ]]; do
        local current_dir="${queue[1]}"
        queue=("${queue[@]:1}") # Dequeue

        if [[ -f "$current_dir/.wcdignore" ]]; then
            continue  # Skip adding subdirectories if an ignore-file is found
        fi

        # Check if the current directory contains the target repo
        if [[ -d "$current_dir/.git" ]]; then
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
        local repo_parts=(${(s:/:)repo})
        echo "${repo_parts[-1]}"
    done
}

compctl -K __wcd_completion wcd
__wcd_completion() {
    reply=($(__wcd_find_any_repos))
}
