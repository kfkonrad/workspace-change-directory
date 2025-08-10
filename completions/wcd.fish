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
        if test -d "$current_dir/.git"
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
