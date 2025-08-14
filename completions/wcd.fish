function __wcd_is_repo
    set dir $argv[1]
    set markers (test -z "$WCD_REPO_MARKERS" && echo ".git" || echo $WCD_REPO_MARKERS)

    set marker_list (string split ':' "$markers")
    for marker in $marker_list
        if test -e "$dir/$marker"
            return 0
        end
    end
    return 1
end

function __wcd_find_any_repos
    set base_dir (test -z "$WCD_BASE_DIR" && echo ~/workspace || echo $WCD_BASE_DIR)

    set -l queue (string split ':' "$base_dir")
    set -l repos

    # Breadth first search, skipping subdirectories of git repos
    while set -q queue[1]
        set -l current_dir $queue[1]
        set queue $queue[2..-1] # Dequeue

        if test -f "$current_dir/.wcdignore"
            continue # Skip adding subdirectories if an ignore-file is found
        end

        # Check if the current directory contains the target repo
        if __wcd_is_repo "$current_dir"
            set repos $repos $current_dir
            continue # Skip adding subdirectories if a repo is found
        end

        # Enqueue all immediate subdirectories
        for sub_dir in $current_dir/*
            if test -d $sub_dir
                set queue $queue $sub_dir
            end
        end
    end

    # Output all found repos
    for repo in $repos
        set repo (echo $repo | string split '/')
        echo $repo[-1]
    end
end

complete -c wcd -f -a '(__wcd_find_any_repos)'
