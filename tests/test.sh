#!/usr/bin/env bash

set -e

BASH_VERSION="5.3.3"
ZSH_VERSION="5.9"
FISH_VERSION="4.0.2"
NU_VERSION="0.106.1"

CONTAINERS=("wcd-bash" "wcd-zsh" "wcd-fish" "wcd-nu")

# Global variables for cleanup
VENV_DIR=""
FAKE_WORKSPACE_DIR=""

cleanup() {
    echo "Cleaning up containers..."
    for container in "${CONTAINERS[@]}"; do
        docker rm -f "$container" 2>/dev/null || true
    done

    echo "Cleaning up virtual environment and fake workspace..."
    if [[ -n "$VENV_DIR" && -d "$VENV_DIR" ]]; then
        rm -rf "$VENV_DIR"
        echo "Removed venv: $VENV_DIR"
    fi
    if [[ -d "__pycache__" ]]; then
        rm -rf "__pycache__"
        echo "Removed pycache"
    fi

    if [[ -n "$FAKE_WORKSPACE_DIR" && -d "$FAKE_WORKSPACE_DIR" ]]; then
        rm -rf "$FAKE_WORKSPACE_DIR"
        echo "Removed fake workspace: $FAKE_WORKSPACE_DIR"
    fi
}

trap cleanup EXIT

# Create Python virtual environment
echo "Creating Python virtual environment..."
VENV_DIR=$(mktemp -d -t wcd-test-venv-XXXXXX)
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
echo "Created and activated venv: $VENV_DIR"

# Create fake workspace with multiple repositories for wcd testing
echo "Creating fake workspace structure..."
FAKE_WORKSPACE_DIR=$(mktemp -d -t wcd-test-workspace-XXXXXX)

# Create some fake repositories with just .git folders
mkdir -p "$FAKE_WORKSPACE_DIR"/{project1,project2,nested/project3,company/app1,company/app2}/.git

echo "Created fake workspace at: $FAKE_WORKSPACE_DIR"
echo "Fake repositories: project1, project2, nested/project3, company/app1, company/app2"

# Bash Container
docker run -d --name "wcd-bash" \
  -v "$(pwd)/..:/wcd-repo" \
  -v "$FAKE_WORKSPACE_DIR:/workspace" \
  -e WCD_BASE_DIR=/workspace \
  -w /workspace \
  "bash:${BASH_VERSION}" sleep infinity

# ZSH Container
docker run -d --name "wcd-zsh" \
  -v "$(pwd)/..:/wcd-repo" \
  -v "$FAKE_WORKSPACE_DIR:/workspace" \
  -e WCD_BASE_DIR=/workspace \
  -w /workspace \
  "zshusers/zsh:${ZSH_VERSION}" sleep infinity

# Fish Container
docker run -d --name "wcd-fish" \
  -v "$(pwd)/..:/wcd-repo" \
  -v "$FAKE_WORKSPACE_DIR:/workspace" \
  -e WCD_BASE_DIR=/workspace \
  -w /workspace \
  "ohmyfish/fish:${FISH_VERSION}" sleep infinity

# Nushell Container
docker run -d --name "wcd-nu" \
  -v "$(pwd)/..:/wcd-repo" \
  -v "$FAKE_WORKSPACE_DIR:/workspace" \
  -e WCD_BASE_DIR=/workspace \
  -w /workspace \
  --entrypoint /bin/sh \
  "hustcer/nushell:${NU_VERSION}" -c 'sleep infinity'


echo "Installing pytest and running tests..."
pip install pytest
python -m pytest test_wcd.py -v
