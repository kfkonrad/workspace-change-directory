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

TEST_CASES = [
    ("wcd project1", "/workspace/project1", 0),
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
        docker_cmd = [
            "docker", "exec", container_name,
            "fish", "-c", f"{source_commands} && {command} && pwd"
        ]
    elif shell == "nu":
        docker_cmd = [
            "docker", "exec", container_name,
            "nu", "-c", f"source {cli_files}; {command}; pwd"
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

    if exit_code != expected_code or expected_output not in stdout:
        print(f"\n--- Debug Info for {shell} ---")
        print(f"Command: {command}")
        print(f"Expected exit code: {expected_code}, got: {exit_code}")
        print(f"Expected output: '{expected_output}'")
        print(f"Stdout: {repr(stdout)}")
        print(f"Stderr: {repr(stderr)}")
        print("--- End Debug ---")

    # Assertions
    assert exit_code == expected_code, f"Expected exit code {expected_code}, got {exit_code}"
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
