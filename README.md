# workspace-change-directory

[![standard-readme compliant](https://img.shields.io/badge/standard--readme-OK-green.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)

Change the directory to a given repo in your workspace in Fish, Bash, ZSH and Nushell.

The `wcd` command searches for a git repo within a configured folder (default: `~/workspace`) and `cd`s into
that repo if it is found. If multiple repos are found, the user is asked to pick one interactively.

## Table of Contents

- [Install](#install)
- [Usage](#usage)
- [Testing](#testing)
- [Maintainers](#maintainers)
- [Contributing](#contributing)
- [License](#license)

## Install

There are four implementations of `wcd` with an identical feature set for Fish, Bash, ZSH and Nushell. All
implementations come _with_ completions.

<details>
  <summary>Install <code>wcd</code> in Fish</summary>
This repo is an oh my fish and fisher compatible plugin repo.

To install `wcd` with oh my fish run:

```sh
omf install https://github.com/kfkonrad/workspace-change-directory.git
```

To install `wcd` with fisher run:

```sh
fisher install kfkonrad/workspace-change-directory
```

</details>

<details>
  <summary>Install <code>wcd</code> in Bash</summary>
To install `wcd` you can download
[bash/wcd.sh](https://github.com/kfkonrad/workspace-change-directory/blob/main/bash/wcd.sh) and source it in your
`.bashrc`. Below are examples for installing the script using `curl` and `wget` for added convenience:

Install with `curl`:

```sh
mkdir -p ~/.config/
curl https://raw.githubusercontent.com/kfkonrad/workspace-change-directory/main/bash/wcd.sh -so ~/.config/wcd.sh
echo 'source ~/.config/wcd.sh' >> ~/.bashrc
```

Install with `wget`:

```sh
mkdir -p ~/.config/
wget https://raw.githubusercontent.com/kfkonrad/workspace-change-directory/main/bash/wcd.sh -qO ~/.config/wcd.sh
echo 'source ~/.config/wcd.sh' >> ~/.bashrc
```

</details>

<details>
  <summary>Install <code>wcd</code> in ZSH</summary>

To install `wcd` you can download
[zsh/wcd.sh](https://github.com/kfkonrad/workspace-change-directory/blob/main/zsh/wcd.sh) and source it in your
`.zshrc`. Below are examples for installing the script using `curl` and `wget` for added convenience:

Install with `curl`:

```sh
mkdir -p ~/.config/
curl https://raw.githubusercontent.com/kfkonrad/workspace-change-directory/main/zsh/wcd.sh -so ~/.config/wcd.sh
echo 'source ~/.config/wcd.sh' >> ~/.zshrc
```

Install with `wget`:

```sh
mkdir -p ~/.config/
wget https://raw.githubusercontent.com/kfkonrad/workspace-change-directory/main/zsh/wcd.sh -qO ~/.config/wcd.sh
echo 'source ~/.config/wcd.sh' >> ~/.zshrc
```

</details>

<details>
  <summary>Install <code>wcd</code> in Nushell</summary>

To install `wcd` you can download
[nushell/wcd.sh](https://github.com/kfkonrad/klone/blob/main/nushell/wcd.sh) and source it in your `config.nu`.
Below are examples for installing the script using `curl` and `wget` for added convenience:

Install with `curl`:

```sh
mkdir ~/.config/wcd
curl https://raw.githubusercontent.com/kfkonrad/workspace-change-directory/main/nushell/wcd.nu -so ~/.config/wcd/wcd.nu
"\nsource ~/.config/wcd/wcd.nu\n" o>> $nu.config-path
```

Install with `wget`:

```sh
mkdir ~/.config/wcd
wget https://raw.githubusercontent.com/kfkonrad/workspace-change-directory/main/nushell/wcd.nu -qO ~/.config/wcd/wcd.nu
"\nsource ~/.config/wcd/wcd.nu\n" o>> $nu.config-path
```

</details>

## Usage

You can configure `wcd` with the following environment variables:

- `WCD_BASE_DIR`: Base directories to search. If unset it defaults to `~/workspace`. Multiple base directories are
  supported via the `:` separator, e.g. `WCD_BASE_DIR='~/workspace:/mnt/projects'`
- `WCD_REPO_MARKERS`: Colon-separated list of files or directories that mark a repository. Defaults to `.git`. Examples:
  `.git:.hg:.svn` or `Cargo.toml:package.json:pom.xml`

```sh
wcd <repo-name>
```

`wcd` only finds repos if the name fully matches `wcd`'s argument, i.e. passing partial names will not find a match.

When `WCD_REPO_MARKERS` is set, a directory is considered a repository if it contains any of the listed marker
files/directories. This affects both navigation and completions in all supported shells.

`wcd` also supports ignoring directories. To do so create an empty file called `.wcdignore` in
the directory you wish to ignore. This directory and any subdirectories won't be listed in completions and can't be
`cd`d into with `wcd`.

### Examples

1. Assume the directory `~/workspace/foo/bar/baz` exists and is a git repo. Running `wcd baz` will `cd` into
   `~/workspace/foo/bar/baz`
1. Assume that `~/workspace/a/foo` and `~/workspace/b/foo` are both repos. Running `wcd foo` will ask the user to pick
   one of the repos like so:

   ```txt
   Multiple repositories found. Please select one:
    1: /home/kfkonrad/workspace/a/foo
    2: /home/kfkonrad/workspace/b/foo
    Enter your choice:
   ```

   By typing in the number of your desired repo and pressing enter `wcd` with `cd` there.
1. Assume that no repo called `foo` exists in `~/workspace` or you have `WCD_BASE_DIR` set to a non-existent directory
  or `~/workspace` doesn't exist. Running `wcd foo` will print the following error message:

   ```txt
   Repository not found.
   ```

1. Assume the directory `~/workspace/foo/bar/` exists and is a git repo. Assume further than either a file
   `~/workspace/.wcdignore` or `~/workspace/foo/.wcdignore` or `~/workspace/foo/bar/.wcdignore` (or any combination of
   them) exists. Running `wcd bar` will print the following error message:

   ```txt
   Repository not found.
   ```

## Testing

The test suite validates `wcd` functionality across all supported shells (Bash, ZSH, Fish, Nushell) using Docker
containers and pytest.

### Requirements

- Bash
- Docker
- Python 3

### Running Tests

```sh
cd tests
./test.sh
```

The test script automatically sets up Docker containers for each shell, creates test repositories, installs dependencies
in a venv, runs the full test suite and cleans up the containers, test repos and venv.

## Maintainers

[@kfkonrad](https://github.com/kfkonrad)

## Contributing

PRs accepted.

Small note: If editing the README, please conform to the
[standard-readme](https://github.com/RichardLitt/standard-readme) specification.

## License

MIT © 2025 Kevin F. Konrad
