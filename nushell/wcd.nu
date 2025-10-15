def repositories [] {
  {
    options: {
        case_sensitive: false,
        completion_algorithm: prefix,
        positional: true,
        sort: true,
    },
    completions: (__wcd_find_any_repos)
  }
}

def --env wcd [
    repo_name: string@repositories
    --no-ignore(-u) # Ignore .wcdignore files
] {
    let repos = __wcd_find_repos $repo_name $no_ignore | split row --regex '\s+' | where $it != ""

    if ($repos | length) > 0 {
        if ($repos | length) > 1 {
            try { __wcd_select_and_cd_repo $repos }
        } else {
            cd $repos.0
        }
    } else {
        "Repository not found."
    }
}

def __wcd_is_repo [dir: string] {
    let markers = $env.WCD_REPO_MARKERS? | default ".git"
    let marker_list = $markers | split row ':'

    $marker_list | any { |marker|
        $dir | path join $marker | path exists
    }
}

def __wcd_find_any_repos [] {
  let base_dir = $env.WCD_BASE_DIR? | default $"($nu.home-path)/workspace"

  # Split base directories and expand tildes
  mut queue = ($base_dir | split row ':' | each {|dir| $dir | str replace --regex '^~' $nu.home-path })
  mut repos = []

  # Breadth first search, skipping subdirectories of git repos
  while ($queue | length) > 0 {
      let current_dir = $queue.0
      $queue = ($queue | skip 1) # Dequeue

      if (__wcd_is_repo $current_dir) {
          $repos = ($repos | append ($current_dir | path split | last))
          continue # Skip adding subdirectories if a repo is found
      }

      # Note: We can't easily check for --no-ignore flag in completion context,
      # so we'll always check for .wcdignore in completions for consistency
      if ($current_dir | path join ".wcdignore" | path exists) {
          continue # Skip adding subdirectories if an ignore-file is found
      }

      # Enqueue all immediate subdirectories
      let subdirs = (ls -l $current_dir | where type == dir | get name)
      $queue = ($queue | append $subdirs)
  }

  # Output all found repos
  $repos | uniq
}

def __wcd_find_repos [repo_name: string, ignore_flag: bool = false] {
    let base_dir = $env.WCD_BASE_DIR? | default $"($nu.home-path)/workspace"

    # Split base directories and expand tildes
    mut queue = ($base_dir | split row ':' | each {|dir| $dir | str replace --regex '^~' $nu.home-path })
    mut repos = []

    if ($env.WCD_DEBUG? | default "" | is-not-empty) {
        print -e $"[DEBUG] Starting search for '($repo_name)' in: ($base_dir)"
    }

    # Breadth first search, skipping subdirectories of git repos
    while ($queue | length) > 0 {
        let current_dir = $queue.0
        $queue = ($queue | skip 1) # Dequeue

        if ($env.WCD_DEBUG? | default "" | is-not-empty) {
            print -e $"[DEBUG] Visiting:          ($current_dir)"
        }

        if (__wcd_is_repo $current_dir) {
            if ($env.WCD_DEBUG? | default "" | is-not-empty) {
                print -e $"[DEBUG] Skipped \(is repo\): ($current_dir)"
            }
            continue # Skip adding subdirectories if a repo is found
        }

        if (not $ignore_flag) and (($current_dir | path join ".wcdignore" | path exists) or
            ($current_dir | path join $repo_name | path join ".wcdignore" | path exists)) {
            if ($env.WCD_DEBUG? | default "" | is-not-empty) {
                print -e $"[DEBUG] Skipped \(ignored\): ($current_dir)"
            }
            continue # Skip adding subdirectories if an ignore-file is found
        }

        # Check if the current directory contains the target repo (case sensitive)
        let subdirs = (ls -l $current_dir | where type == dir | get name)
        for sub_dir in $subdirs {
            if ($sub_dir | path split | last) == $repo_name and (__wcd_is_repo $sub_dir) {
                if ($env.WCD_DEBUG? | default "" | is-not-empty) {
                    print -e $"[DEBUG] Found repo:        ($sub_dir)"
                }
                $repos = ($repos | append $sub_dir)
            }
        }

        # Enqueue all immediate subdirectories
        let subdirs = (ls -l $current_dir | where type == dir | get name)
        $queue = ($queue | append $subdirs)
    }

    # Output all found repos
    $repos | str join "\n"
}

def --env __wcd_select_and_cd_repo [repos: list] {
    print "Multiple repositories found. Please select one:"

    $repos | enumerate | each { |repo|
        print $"($repo.index + 1): ($repo.item)"
    }

    mut selection = ""
    while true {
        if $selection != "" {
            print $"Please enter a number smaller than (($repos | length) + 1)."
        }

        $selection = (input "Enter your choice: ")

        if (try {$selection | into int}) == null {
            print "Please enter a valid number."
            $selection = ""
            continue
        }

        let selection_int = ($selection | into int)
        if $selection_int > 0 and $selection_int <= ($repos | length) {
            cd ($repos | get ($selection_int - 1))
            break
        } else {
          print $"Please enter a number between 1 and ($repos | length)"
        }

        $selection = ""
    }
}
