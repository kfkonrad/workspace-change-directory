import subprocess
import pytest

SHELLS = [
    "bash",
    "zsh",
    "fish",
    "nu"
]

CLI_FILES = {
    "bash": "/wcd-repo/bash/wcd.sh",
    "zsh": "/wcd-repo/zsh/wcd.sh",
    "fish": ["/wcd-repo/functions/wcd.fish", "/wcd-repo/completions/wcd.fish"],
    "nu": "/wcd-repo/nushell/wcd.nu"
}

LIST_OF_ALL_REPOS = {
    "bar",
    "baz",
    "corge",
    "foo",
    "foobar",
    "grault",
    "quux",
    "qux",
    "thud",
}

# The container's working directory; every command starts here
START_DIR = "/workspace"

# Separates wcd's own output from the trailing `pwd` in run_in_shell
PWD_SENTINEL = "__WCD_TEST_PWD__"

# Each case is (command, expected_output, expected_cwd, expected_code):
# - expected_output: what wcd itself prints. A list means the output must consist of exactly these lines
#   (in order), a set means each element must appear somewhere in the output (order, duplicates and shell-specific
#   formatting are not checked), a string means it must be contained in the output, "" means wcd must print nothing.
# - expected_cwd: the working directory after the command, i.e. where wcd cd'd to. START_DIR means it did not cd.
TEST_CASES = [
    # basic navigation to existing repos
    ("wcd foo", "", "/workspace/foo", 0),
    ("wcd bar", "", "/workspace/bar", 0),
    # repo names may not be duplicate but the directory name may appear in different paths
    ("wcd quux", "", "/workspace/foobar/quux", 0),
    ("wcd foobar", "", "/workspace/company/foobar", 0),
    # navigation to repos in secondary BASE_DIR
    ("wcd corge", "", "/other-workspace/corge", 0),
    ("wcd grault", "", "/other-workspace/my-project/grault", 0),

    # test non-existent repository
    ("wcd nonexistent", "Repository not found", START_DIR, 1),
    # wcd should act case sensitive
    ("wcd FOO", "Repository not found", START_DIR, 1),
    # fuzzy finding is not supported
    ("wcd grau", "Repository not found", START_DIR, 1),
    # repos should be ignored if they have a .wcdignore
    ("wcd xyzzy", "Repository not found", START_DIR, 1),
    # repos should be ignored if there is a .wcdignore in any of their parent directories
    ("wcd waldo", "Repository not found", START_DIR, 1),
    ("wcd plugh", "Repository not found", START_DIR, 1),

    # test empty argument
    ("wcd", "Please provide a repository name", START_DIR, 1),

    # test multiple repos found case within one BASE_DIR
    ("wcd baz", "Multiple repositories found. Please select one:", START_DIR, 1),
    # test multiple repos found case across BASE_DIRs
    ("wcd qux", "Multiple repositories found. Please select one:", START_DIR, 1),

    # test whether completion lists all repos
    ("__wcd_find_any_repos", LIST_OF_ALL_REPOS, START_DIR, 0),

    ("wcd thud", "", "/workspace/thud", 0),

    # test --no-ignore flag functionality
    ("wcd --no-ignore xyzzy", "", "/other-workspace/xyzzy", 0),
    ("wcd --no-ignore waldo", "", "/other-workspace/garply/waldo", 0),
    ("wcd --no-ignore plugh", "", "/other-workspace/garply/fred/plugh", 0),

    # test -u flag functionality (short form)
    ("wcd -u xyzzy", "", "/other-workspace/xyzzy", 0),
    ("wcd -u waldo", "", "/other-workspace/garply/waldo", 0),
    ("wcd -u plugh", "", "/other-workspace/garply/fred/plugh", 0),

    # test flag with non-existent repo still fails
    ("wcd --no-ignore nonexistent", "Repository not found", START_DIR, 1),
    ("wcd -u nonexistent", "Repository not found", START_DIR, 1),

    # test tilde expansion with default ~/workspace
    ("wcd alpha", "", "/fake-home/workspace/alpha", 0),
    ("wcd beta", "", "/fake-home/workspace/beta", 0),

    # test tilde expansion with custom override ~/projects
    ("wcd gamma", "", "/fake-home/projects/gamma", 0),
    ("wcd delta", "", "/fake-home/projects/delta", 0),

    # test --list/-l flag prints absolute paths and does not cd
    ("wcd --list foo", ["/workspace/foo"], START_DIR, 0),
    ("wcd -l corge", ["/other-workspace/corge"], START_DIR, 0),
    ("wcd -l grault", ["/other-workspace/my-project/grault"], START_DIR, 0),
    # flag may come after the repo name
    ("wcd corge --list", ["/other-workspace/corge"], START_DIR, 0),
    ("wcd corge -l", ["/other-workspace/corge"], START_DIR, 0),
    # multiple matches are listed instead of prompting
    ("wcd -l baz", ["/workspace/baz", "/workspace/company/baz"], START_DIR, 0),
    ("wcd --list qux", ["/other-workspace/qux", "/workspace/company/qux"], START_DIR, 0),
    # --list respects .wcdignore unless combined with --no-ignore/-u
    ("wcd -l xyzzy", "Repository not found", START_DIR, 1),
    ("wcd -l -u xyzzy", ["/other-workspace/xyzzy"], START_DIR, 0),
    ("wcd -u -l waldo", ["/other-workspace/garply/waldo"], START_DIR, 0),
    ("wcd --list --no-ignore plugh", ["/other-workspace/garply/fred/plugh"], START_DIR, 0),
    ("wcd --no-ignore --list nonexistent", "Repository not found", START_DIR, 1),
    # --list still requires a repo name
    ("wcd -l", "Please provide a repository name", START_DIR, 1),
]

def run_in_shell(shell, command):
    """Execute command in specific shell container.

    Returns (exit_code, output, cwd, stderr) where output is what the command itself printed and cwd is the
    working directory after the command ran. The exit code is the command's own, `pwd` always runs.
    """
    container_name = f"wcd-{shell}"
    cli_files = CLI_FILES[shell]

    if shell in ["bash", "zsh"]:
        docker_cmd = [
            "docker", "exec", container_name,
            shell, "-c", f"source {cli_files}; {command}; rc=$?; echo {PWD_SENTINEL}; pwd; exit $rc"
        ]
    elif shell == "fish":
        source_commands = "; ".join([f"source {cli_file}" for cli_file in cli_files])
        docker_cmd = [
            "docker", "exec", container_name,
            "fish", "-c", f"{source_commands}; {command}; set rc $status; echo {PWD_SENTINEL}; pwd; exit $rc"
        ]
    elif shell == "nu":
        docker_cmd = [
            "docker", "exec", container_name,
            "nu", "-c", f"source {cli_files}; print ({command}); print {PWD_SENTINEL}; pwd"
        ]
    else:
        raise ValueError(f"Unknown shell: {shell}")

    try:
        result = subprocess.run(docker_cmd, capture_output=True, text=True, timeout=30)
    except subprocess.TimeoutExpired:
        return -1, "", "", "Command timed out"

    if PWD_SENTINEL not in result.stdout:
        return result.returncode, result.stdout, "", result.stderr

    output, cwd = result.stdout.split(PWD_SENTINEL + "\n", 1)
    return result.returncode, output, cwd.strip(), result.stderr

@pytest.mark.parametrize("shell", SHELLS)
@pytest.mark.parametrize("command,expected_output,expected_cwd,expected_code", TEST_CASES)
def test_wcd(shell, command, expected_output, expected_cwd, expected_code):
    """Test CLI command compatibility across different shells"""

    exit_code, output, cwd, stderr = run_in_shell(shell, command)

    debug = (f"\n--- Debug Info for {shell} ---\n"
             f"Command: {command}\n"
             f"Expected exit code: {expected_code}, got: {exit_code}\n"
             f"Expected output: {expected_output!r}\n"
             f"Expected cwd: {expected_cwd!r}, got: {cwd!r}\n"
             f"Output: {output!r}\n"
             f"Stderr: {stderr!r}\n"
             "--- End Debug ---")

    # Nu does not use exit codes for functions, only for external commands.
    # This means we need to skip this assertion for Nu
    if shell != "nu":
        assert exit_code == expected_code, f"Expected exit code {expected_code}, got {exit_code}{debug}"

    # Nu fails at parse time with a built-in error message on a missing parameter, so neither the output nor the
    # cwd can be checked for those test cases
    if shell == "nu" and command in ("wcd", "wcd -l"):
        return

    # where wcd cd'd to (or that it did not cd at all) is checked independently of what it printed
    assert cwd == expected_cwd, f"Expected cwd {expected_cwd!r}, got {cwd!r}{debug}"

    if type(expected_output) == list:
        assert output.strip().splitlines() == expected_output, f"Expected lines {expected_output}{debug}"
    elif type(expected_output) == set:
        for elem in expected_output:
            assert elem in output, f"Expected {elem!r} in output{debug}"
    else:
        assert expected_output in output, f"Expected {expected_output!r} in output{debug}"
        if expected_output == "":
            assert output.strip() == "", f"Expected no output{debug}"

def test_container_connectivity():
    """Verify all shell containers are accessible"""
    for shell in SHELLS:
        container = f"wcd-{shell}"
        result = subprocess.run(
            ["docker", "exec", container, "echo", "test"],
            capture_output=True, text=True
        )
        assert result.returncode == 0, f"Container {container} not accessible"
        assert "test" in result.stdout
