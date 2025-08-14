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

def --env wcd [repo_name: string@repositories] {
    let repos = __wcd_find_repos $repo_name | split row --regex '\s+' | where $it != ""

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

def __wcd_find_any_repos [] {
  let base_dir = $env.WCD_BASE_DIR? | default $"($nu.home-path)/workspace"

  mut queue = $base_dir | split row ':'
  mut repos = []

  # Breadth first search, skipping subdirectories of git repos
  while ($queue | length) > 0 {
      let current_dir = $queue.0
      $queue = ($queue | skip 1) # Dequeue

      if ($current_dir | path join ".git" | path exists) {
          $repos = ($repos | append ($current_dir | path split | last))
          continue # Skip adding subdirectories if a repo is found
      }

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

def __wcd_find_repos [repo_name: string] {
    let base_dir = $env.WCD_BASE_DIR? | default $"($nu.home-path)/workspace"

    mut queue = $base_dir | split row ':'
    mut repos = []

    # Breadth first search, skipping subdirectories of git repos
    while ($queue | length) > 0 {
        let current_dir = $queue.0
        $queue = ($queue | skip 1) # Dequeue

        if ($current_dir | path join ".git" | path exists) {
            continue # Skip adding subdirectories if a repo is found
        }

        if (($current_dir | path join ".wcdignore" | path exists) or
            ($current_dir | path join $repo_name | path join ".wcdignore" | path exists)) {
            continue # Skip adding subdirectories if an ignore-file is found
        }

        # Check if the current directory contains the target repo
        if ($current_dir | path join $repo_name | path join ".git" | path exists) {
            $repos = ($repos | append ($current_dir | path join $repo_name))
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
