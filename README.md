# workspace-change-directory

[![standard-readme compliant](https://img.shields.io/badge/standard--readme-OK-green.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)

Change the directory to a given repo in your workspace in Fish, Bash and ZSH

The `wcd` command searches for a git repo within a configured folder (default: `~/workspace`) and `cd`s into
that repo if it is found. If multiple repos are found, the user is asked to pick one interactively.

## Table of Contents

- [Install](#install)
- [Usage](#usage)
- [Maintainers](#maintainers)
- [Contributing](#contributing)
- [License](#license)

## Install

There are three implementations of `wcd` with an identical feature set for Fish, Bash and ZSH. All implementations come
_with_ completions.

### Fish

This repo is an oh my fish and fisher compatible plugin repo.

To install `wcd` with oh my fish run:

```sh
omf install https://github.com/kfkonrad/workspace-change-directory.git
```

To install `wcd` with fisher run:

```sh
fisher install kfkonrad/workspace-change-directory
```

### Bash

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

### ZSH

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

## Usage

You can set the base directory for the search by setting `WCD_BASE_DIR`. If unset it defaults to `~/workspace`.

```sh
wcd <repo-name>
```

`wcd` only finds repos if the name fully matches `wcd`'s argument, i.e. passing partial names will not find a match.

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

## Maintainers

[@kfkonrad](https://github.com/kfkonrad)

## Contributing

PRs accepted.

Small note: If editing the README, please conform to the
[standard-readme](https://github.com/RichardLitt/standard-readme) specification.

## License

MIT © 2024 Kevin F. Konrad
