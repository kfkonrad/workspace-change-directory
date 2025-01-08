function wcd
    set repo_name $argv[1]

    if test -z "$repo_name"
        echo "Please provide a repository name."
        return 1
    end

    set repos (string split " " --no-empty -- (__wcd_find_repos $repo_name))

    if set -q repos[1]
        if set -q repos[2]
            __wcd_select_and_cd_repo $repos
        else
            cd $repos[1]
        end
    else
        echo "Repository not found."
        return 1
    end
end

function __wcd_find_repos
    set repo_name $argv[1]
    set base_dir (test -z "$WCD_BASE_DIR" && echo ~/workspace || echo $WCD_BASE_DIR)


    set -l queue $base_dir
    set -l repos

    # Breadth first search, skipping subdirectories of git repos
    while set -q queue[1]
        set -l current_dir $queue[1]
        set queue $queue[2..-1] # Dequeue

        if test -d "$current_dir/.git"
            continue # Skip adding subdirectories if a repo is found
        end

        if test -f "$current_dir/.wcdignore"
            continue # Skip adding subdirectories if an ignore-file is found
        end

        # Check if the current directory contains the target repo
        if test -d "$current_dir/$repo_name/.git"
            set repos $repos $current_dir/$repo_name
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
        echo $repo
    end
end

function __wcd_select_and_cd_repo
  echo "Multiple repositories found. Please select one:"
  for i in (seq (count $argv))
              echo "$i: $argv[$i]"
  end

  set selection
  while not set -q argv[$selection]
              test "$selection" != "" && echo "Please enter a number smaller than "(math (count $argv) + 1)"."
              read -P "Enter your choice: " selection || return
              if not string match -qr '^\d+$' $selection
              echo "Please enter a valid number."
              set -e selection
              end
  end
  cd $argv[$selection]
end
