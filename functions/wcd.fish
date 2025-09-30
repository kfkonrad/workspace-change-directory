function wcd
    set repo_name $argv[1]
    set -l ignore yes
    if test "$repo_name" = "--no-ignore" || test "$repo_name" = "-u"
      set repo_name $argv[2]
      set ignore no
    else if test "$argv[2]" = "--no-ignore" || test "$argv[2]" = "-u"
      set ignore no
    end

    if test -z "$repo_name"
        echo "Please provide a repository name."
        return 1
    end

    set repos (string split " " --no-empty -- (__wcd_find_repos $repo_name $ignore))

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

function __wcd_find_repos
    set repo_name $argv[1]
    set ignore $argv[2]
    set base_dir (test -z "$WCD_BASE_DIR" && echo ~/workspace || echo $WCD_BASE_DIR)


    set -l queue (string split ':' "$base_dir")
    set -l repos

    # Breadth first search, skipping subdirectories of git repos
    while set -q queue[1]
        set -l current_dir $queue[1]
        set queue $queue[2..-1] # Dequeue

        if __wcd_is_repo "$current_dir"
            continue # Skip adding subdirectories if a repo is found
        end

        if test -f "$current_dir/.wcdignore" -o -f "$current_dir/$repo_name/.wcdignore"
            if test $ignore = "yes"
                continue # Skip adding subdirectories if an ignore-file is found
            end
        end

        # Check if the current directory contains the target repo (case sensitive)
        for sub_dir in $current_dir/*
            if test -d $sub_dir
                set name (basename "$sub_dir")
                if test "$name" = "$repo_name"; and __wcd_is_repo "$sub_dir"
                    set repos $repos $sub_dir
                end
            end
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
