# Shared Bats setup helpers for chezmoi dotfiles tests.
# Load this in each test file:
#   load 'helpers/setup'

# Absolute path to the repo root (two levels up from this file).
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# The chezmoi source directory used by all tests.
CHEZMOI_SOURCE="${REPO_ROOT}/home"

# ---------------------------------------------------------------------------
# setup — called automatically by Bats before each test.
# Creates a per-test temp directory and exports TEST_DIR.
# ---------------------------------------------------------------------------
setup() {
    # Require chezmoi; skip the whole test if it is not installed.
    if ! command -v chezmoi &>/dev/null; then
        skip "chezmoi is not installed"
    fi

    # Create an isolated temp directory for this test.
    TEST_DIR="$(mktemp -d)"
    export TEST_DIR
    export CHEZMOI_SOURCE
}

# ---------------------------------------------------------------------------
# teardown — called automatically by Bats after each test.
# Removes the temp directory created in setup.
# ---------------------------------------------------------------------------
teardown() {
    if [[ -n "${TEST_DIR:-}" && -d "${TEST_DIR}" ]]; then
        rm -rf "${TEST_DIR}"
    fi
}
