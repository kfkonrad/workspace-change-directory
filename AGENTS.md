# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`workspace-change-directory` (`wcd`) is a shell plugin that enables quick navigation to git repositories within a workspace directory. It provides identical functionality across **four shell implementations**: Bash, ZSH, Fish, and Nushell.

## Core Architecture

### Multi-Shell Implementation

Each shell has its own implementation that must maintain feature parity:
- `bash/wcd.sh` - Bash implementation with bash completion
- `zsh/wcd.sh` - ZSH implementation with compctl completion
- `functions/wcd.fish` + `completions/wcd.fish` - Fish implementation split into function and completion files
- `nushell/wcd.nu` - Nushell implementation with custom completion

**Critical**: When modifying functionality, **ALL four implementations must be updated** to maintain feature parity. The test suite validates this across all shells.

### Core Algorithm

All implementations use the same breadth-first search algorithm with these key behaviors:

1. **Repository Detection**: Uses `__wcd_is_repo()` to check for marker files (default: `.git`, configurable via `WCD_REPO_MARKERS`)
2. **Search Strategy**: BFS that stops descending into directories once a repo is found
3. **Ignore System**: Respects `.wcdignore` files unless `--no-ignore`/`-u` flag is used
4. **Multiple Base Directories**: Supports colon-separated paths in `WCD_BASE_DIR`
5. **Interactive Selection**: When multiple repos match, prompts user with numbered list

### Environment Variables

- `WCD_BASE_DIR`: Colon-separated base directories to search (default: `~/workspace`)
- `WCD_REPO_MARKERS`: Colon-separated list of repo marker files/dirs (default: `.git`)

## Testing

### Running Tests

```sh
cd tests
./test.sh
```

### Test Architecture

- `tests/test.sh` - Sets up Docker containers for all four shells, creates test workspaces, runs pytest
- `tests/test_wcd.py` - pytest suite that runs identical tests across all shell implementations

**Test Requirements**:
- Docker (for shell containers)
- Python 3 (for pytest)
- Bash (to run test.sh)

The test suite:
1. Spins up Docker containers for bash, zsh, fish, and nushell
2. Creates temporary workspace directories with test repositories
3. Runs the same test cases across all shells using pytest parametrization
4. Validates exit codes, output, and directory navigation
5. Cleans up containers and temp directories on exit

### Test Data

Tests use two workspace directories with repos like `foo`, `bar`, `baz`, `company/baz`, etc. Some directories have `.wcdignore` files to test the ignore functionality.

## Development Guidelines

### When Adding Features

1. Implement in all four shells in this order: **Fish → Bash → ZSH → Nushell**
2. Add test cases to `tests/test_wcd.py` TEST_CASES array
3. Ensure syntax differences are handled (e.g., Bash arrays use `[@]`, Fish uses `$var`, Nu uses `|`)
4. Run full test suite to verify all implementations pass

### Shell-Specific Notes

- **Bash**: Uses `COMP_WORDS` for completion, space-separated string for multi-repo output
- **ZSH**: Uses 1-indexed arrays, `compctl`, and `${@[$selection]}` for array access
- **Fish**: Uses 1-indexed arrays, separate completion file, `set -q` for variable checks
- **Nushell**: Uses pipeline-based logic, custom completion records, different flag handling

### Common Patterns

- All shells implement: `wcd`, `__wcd_is_repo`, `__wcd_find_repos`, `__wcd_select_and_cd_repo`, `__wcd_find_any_repos`
- Flag handling: Both `--no-ignore` and `-u` must be supported
- Case sensitivity: Repo name matching is case-sensitive
- Interactive prompts: Must handle non-TTY gracefully (Bash only)
