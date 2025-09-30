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

LIST_OF_ALL_REPOS = [
    "bar",
    "baz",
    "corge",
    "foo",
    "foobar",
    "grault",
    "quux",
    "qux",
    "thud",
]

TEST_CASES = [
    # basic navigation to existing repos
    ("wcd foo", "/workspace/foo", 0),
    ("wcd bar", "/workspace/bar", 0),
    # repo names may not be duplicate but the directory name may appear in different paths
    ("wcd quux", "/workspace/foobar/quux", 0),
    ("wcd foobar", "/workspace/company/foobar", 0),
    # navigation to repos in secondary BASE_DIR
    ("wcd corge", "/other-workspace/corge", 0),
    ("wcd grault", "/other-workspace/my-project/grault", 0),

    # test non-existent repository
    ("wcd nonexistent", "Repository not found", 1),
    # wcd should act case sensitive
    ("wcd FOO", "Repository not found", 1),
    # fuzzy finding is not supported
    ("wcd grau", "Repository not found", 1),
    # repos should be ignored if they have a .wcdignore
    ("wcd xyzzy", "Repository not found", 1),
    # repos should be ignored if there is a .wcdignore in any of their parent directories
    ("wcd waldo", "Repository not found", 1),
    ("wcd plugh", "Repository not found", 1),

    # test empty argument
    ("wcd", "Please provide a repository name", 1),

    # test multiple repos found case within one BASE_DIR
    ("wcd baz", "Multiple repositories found. Please select one:", 1),
    # test multiple repos found case across BASE_DIRs
    ("wcd qux", "Multiple repositories found. Please select one:", 1),

    # test whether completion lists all repos
    ("__wcd_find_any_repos", LIST_OF_ALL_REPOS, 0),

    ("wcd thud", "/workspace/thud", 0),

    # test --no-ignore flag functionality
    ("wcd --no-ignore xyzzy", "/other-workspace/xyzzy", 0),
    ("wcd --no-ignore waldo", "/other-workspace/garply/waldo", 0),
    ("wcd --no-ignore plugh", "/other-workspace/garply/fred/plugh", 0),

    # test -u flag functionality (short form)
    ("wcd -u xyzzy", "/other-workspace/xyzzy", 0),
    ("wcd -u waldo", "/other-workspace/garply/waldo", 0),
    ("wcd -u plugh", "/other-workspace/garply/fred/plugh", 0),

    # test flag with non-existent repo still fails
    ("wcd --no-ignore nonexistent", "Repository not found", 1),
    ("wcd -u nonexistent", "Repository not found", 1),
]

def run_in_shell(shell, command):
    """Execute command in specific shell container"""
    container_name = f"wcd-{shell}"
    cli_files = CLI_FILES[shell]

    if shell in ["bash", "zsh"]:
        docker_cmd = [
            "docker", "exec", container_name,
            shell, "-c", f"source {cli_files} && {command} && pwd"
        ]
    elif shell == "fish":
        source_commands = " && ".join([f"source {cli_file}" for cli_file in cli_files])
        print()
        docker_cmd = [
            "docker", "exec", container_name,
            "fish", "-c", f"{source_commands} && {command} && pwd"
        ]
    elif shell == "nu":
        docker_cmd = [
            "docker", "exec", container_name,
            "nu", "-c", f"source {cli_files}; print ({command}); pwd"
        ]
    else:
        raise ValueError(f"Unknown shell: {shell}")

    try:
        result = subprocess.run(docker_cmd, capture_output=True, text=True, timeout=30)
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "Command timed out"

@pytest.mark.parametrize("shell", SHELLS)
@pytest.mark.parametrize("command,expected_output,expected_code", TEST_CASES)
def test_wcd(shell, command, expected_output, expected_code):
    """Test CLI command compatibility across different shells"""

    exit_code, stdout, stderr = run_in_shell(shell, command)

    if exit_code != expected_code or (type(expected_output) == list and any(elem not in stdout for elem in expected_output)) or (type(expected_output) == str and expected_output not in stdout):
        print(f"\n--- Debug Info for {shell} ---")
        print(f"Command: {command}")
        print(f"Expected exit code: {expected_code}, got: {exit_code}")
        print(f"Expected output: '{expected_output}'")
        print(f"Stdout: {repr(stdout)}")
        print(f"Stderr: {repr(stderr)}")
        print("--- End Debug ---")

    # Assertions

    # Nu does not use exit codes for functions, only for external commands.
    # This means we need to skip this assertion for Nu
    if shell != "nu":
        assert exit_code == expected_code, f"Expected exit code {expected_code}, got {exit_code}"

    # Nu will ouput a built-in error message on a missing parameter, so we have to skip this assertion as well for that
    # test case
    if shell == "nu" and command == "wcd":
        return

    if type(expected_output) == list:
        for elem in expected_output:
            assert elem in stdout, f"Expected '{elem}' in stdout: {stdout}"
    else:
        assert expected_output in stdout, f"Expected '{expected_output}' in stdout: {stdout}"

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
