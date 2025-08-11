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
FAKE_WORKSPACE_DIR2=""

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

    if [[ -n "$FAKE_WORKSPACE_DIR2" && -d "$FAKE_WORKSPACE_DIR2" ]]; then
        rm -rf "$FAKE_WORKSPACE_DIR2"
        echo "Removed fake workspace: $FAKE_WORKSPACE_DIR2"
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
FAKE_WORKSPACE_DIR2=$(mktemp -d -t wcd-test-workspace-XXXXXX)

# Create some fake repositories with just .git folders
mkdir -p "$FAKE_WORKSPACE_DIR"/{foo,bar,baz,company/baz,company/qux,company/foobar,foobar/quux}/.git
mkdir -p "$FAKE_WORKSPACE_DIR"/thud/custom
mkdir -p "$FAKE_WORKSPACE_DIR2"/{qux,corge,my-project/grault,garply/waldo,garply/fred/plugh,xyzzy}/.git
touch "$FAKE_WORKSPACE_DIR2"/{garply,xyzzy}/.wcdignore

echo "Created fake workspace at: $FAKE_WORKSPACE_DIR"
echo "Fake repositories: foo, bar, baz, company/baz, company/qux, company/foobar, foobar/quux, thud"
echo "Created fake secondary workspace at: $FAKE_WORKSPACE_DIR2"
echo "Fake repositories: quux, corge, my-project/grault, garply/waldo, garply/fred/plugh, xyzzy"

# Bash Container
docker run -d --name "wcd-bash" \
  -v "$(pwd)/..:/wcd-repo" \
  -v "$FAKE_WORKSPACE_DIR:/workspace" \
  -v "$FAKE_WORKSPACE_DIR2:/other-workspace" \
  -e WCD_BASE_DIR=/workspace:/other-workspace \
  -e WCD_REPO_MARKERS=custom:.git \
  -w /workspace \
  ${DOCKER_USER_ARGS:-} \
  "bash:${BASH_VERSION}" sleep infinity

# ZSH Container
docker run -d --name "wcd-zsh" \
  -v "$(pwd)/..:/wcd-repo" \
  -v "$FAKE_WORKSPACE_DIR:/workspace" \
  -v "$FAKE_WORKSPACE_DIR2:/other-workspace" \
  -e WCD_BASE_DIR=/workspace:/other-workspace \
  -e WCD_REPO_MARKERS=custom:.git \
  -w /workspace \
  ${DOCKER_USER_ARGS:-} \
  "zshusers/zsh:${ZSH_VERSION}" sleep infinity

# Fish Container
docker run -d --name "wcd-fish" \
  -v "$(pwd)/..:/wcd-repo" \
  -v "$FAKE_WORKSPACE_DIR:/workspace" \
  -v "$FAKE_WORKSPACE_DIR2:/other-workspace" \
  -e WCD_BASE_DIR=/workspace:/other-workspace \
  -e WCD_REPO_MARKERS=custom:.git \
  -w /workspace \
  ${DOCKER_USER_ARGS:-} \
  "ohmyfish/fish:${FISH_VERSION}" sleep infinity

# Nushell Container
docker run -d --name "wcd-nu" \
  -v "$(pwd)/..:/wcd-repo" \
  -v "$FAKE_WORKSPACE_DIR:/workspace" \
  -v "$FAKE_WORKSPACE_DIR2:/other-workspace" \
  -e WCD_BASE_DIR=/workspace:/other-workspace \
  -e WCD_REPO_MARKERS=custom:.git \
  -w /workspace \
  --entrypoint /bin/sh \
  ${DOCKER_USER_ARGS:-} \
  "hustcer/nushell:${NU_VERSION}" -c 'sleep infinity'


echo "Installing pytest and running tests..."
pip install pytest
python -m pytest test_wcd.py -v
