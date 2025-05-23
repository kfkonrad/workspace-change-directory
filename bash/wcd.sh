wcd() {
    local repo_name=$1

    if [[ -z "$repo_name" ]]; then
        echo "Please provide a repository name."
        return 1
    fi

    local repos
    IFS=' ' read -r -a repos <<< "$(__wcd_find_repos "$repo_name")"

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

__wcd_find_repos() {
    local repo_name=$1
    local base_dir=$(test -z "$WCD_BASE_DIR" && echo ~/workspace || echo $WCD_BASE_DIR)

    # Initialize a queue with the base directory
    local queue=("$base_dir")
    local repos=()

    # Breadth-first search, skipping subdirectories of git repos
    while [[ ${#queue[@]} -gt 0 ]]; do
        local current_dir=${queue[0]}
        queue=("${queue[@]:1}")  # Dequeue

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
    local base_dir=$(test -z "$WCD_BASE_DIR" && echo ~/workspace || echo $WCD_BASE_DIR)
    local queue=("$base_dir")
    local repos=()

    # Breadth first search, skipping subdirectories of git repos
    while [[ ${#queue[@]} -gt 0 ]]; do
        local current_dir=${queue[0]}
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
    any_repos=$(__wcd_find_any_repos | sort -u)
    COMPREPLY=($(echo $any_repos | tr " " "\n" | grep "^$cur"))
    if test -z "$COMPREPLY"; then
        COMPREPLY=($(echo $any_repos | tr " " "\n" | grep "$cur"))
    fi
}
complete -F _wcd_completion wcd
