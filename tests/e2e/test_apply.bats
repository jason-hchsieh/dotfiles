#!/usr/bin/env bats
# End-to-end tests for chezmoi apply.
# Applies dotfiles to an isolated temp directory (TEST_HOME) and verifies the
# resulting state.  Safe to run locally because --destination is used — the
# real home directory is never touched.
#
# Run:
#   bats tests/e2e/test_apply.bats
#
# Requirements:
#   - chezmoi installed and on PATH
#   - bats-core installed
#
# NOTE: These tests also run in CI (Docker for Linux, native for macOS).

load '../helpers/setup'
load '../helpers/mock_data'

# ---------------------------------------------------------------------------
# Detect the current OS and return a chezmoi osid string.
# ---------------------------------------------------------------------------
_detect_osid() {
    case "$(uname -s)" in
        Darwin) echo "darwin" ;;
        Linux)
            if [[ -f /etc/os-release ]]; then
                # shellcheck source=/dev/null
                source /etc/os-release
                case "${ID:-}" in
                    ubuntu|debian) echo "linux-ubuntu" ;;
                    arch)          echo "linux-arch"   ;;
                    *)             echo "linux-ubuntu" ;;  # safe fallback
                esac
            else
                echo "linux-ubuntu"
            fi
            ;;
        *) echo "linux-ubuntu" ;;
    esac
}

# ---------------------------------------------------------------------------
# setup_file — runs once before all tests in this file.
# Applies chezmoi to an isolated TEST_HOME directory.
# ---------------------------------------------------------------------------
setup_file() {
    # Require chezmoi; skip all tests if not installed.
    if ! command -v chezmoi &>/dev/null; then
        skip "chezmoi is not installed"
    fi

    # Create isolated directories for this test run.
    E2E_DIR="$(mktemp -d)"
    export E2E_DIR

    TEST_HOME="${E2E_DIR}/home"
    mkdir -p "${TEST_HOME}"
    export TEST_HOME

    CONFIG_DIR="${E2E_DIR}/config"
    mkdir -p "${CONFIG_DIR}"
    CONFIG_FILE="${CONFIG_DIR}/chezmoi.toml"
    export CONFIG_FILE

    # Detect the current OS and generate a config.
    local osid
    osid="$(_detect_osid)"
    generate_chezmoi_config false "${osid}" false "${CONFIG_FILE}"

    # Append destination so chezmoi knows where to apply files.
    cat >> "${CONFIG_FILE}" <<EOF

[chezmoi]
  destDir = "${TEST_HOME}"
EOF

    # Run chezmoi init with the source directory.
    INIT_EXIT=0
    chezmoi init \
        --config "${CONFIG_FILE}" \
        --source "${CHEZMOI_SOURCE}" \
        2>"${E2E_DIR}/init.stderr" || INIT_EXIT=$?
    export INIT_EXIT

    # Apply to the isolated TEST_HOME; skip scripts to avoid side effects.
    APPLY_EXIT=0
    chezmoi apply \
        --config "${CONFIG_FILE}" \
        --source "${CHEZMOI_SOURCE}" \
        --destination "${TEST_HOME}" \
        --exclude=scripts \
        2>"${E2E_DIR}/apply.stderr" || APPLY_EXIT=$?
    export APPLY_EXIT
}

# ---------------------------------------------------------------------------
# teardown_file — runs once after all tests in this file.
# Removes the isolated directory created in setup_file.
# ---------------------------------------------------------------------------
teardown_file() {
    if [[ -n "${E2E_DIR:-}" && -d "${E2E_DIR}" ]]; then
        rm -rf "${E2E_DIR}"
    fi
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

@test "chezmoi apply exits cleanly" {
    if [[ -n "${APPLY_EXIT+set}" ]]; then
        if [[ "${APPLY_EXIT}" -ne 0 ]]; then
            cat "${E2E_DIR}/apply.stderr" >&2 || true
        fi
        [ "${APPLY_EXIT}" -eq 0 ]
    else
        skip "APPLY_EXIT not set — setup_file may have been skipped"
    fi
}

@test "expected files exist" {
    [ -f "${TEST_HOME}/.zshrc" ]
    # .zprofile is only generated on macOS (requires Homebrew)
    if [[ "$(uname -s)" == "Darwin" ]]; then
        [ -f "${TEST_HOME}/.zprofile" ]
    fi
    [ -f "${TEST_HOME}/.config/git/config" ]
    [ -f "${TEST_HOME}/.claude/CLAUDE.md" ]
    [ -f "${TEST_HOME}/.p10k.zsh" ]
}

@test "CLAUDE.md is always present" {
    [ -f "${TEST_HOME}/.claude/CLAUDE.md" ]
}

@test "symlinks resolve when targets exist" {
    # ~/.codex/AGENTS.md should be a symlink pointing to ~/.claude/CLAUDE.md
    if [[ -d "${TEST_HOME}/.codex" ]]; then
        [ -L "${TEST_HOME}/.codex/AGENTS.md" ]
        local target
        target="$(readlink "${TEST_HOME}/.codex/AGENTS.md")"
        [ "${target}" = "${TEST_HOME}/.claude/CLAUDE.md" ]
    else
        skip "~/.codex directory was not created (may be gated by template condition)"
    fi

    # ~/.gemini/GEMINI.md should be a symlink pointing to ~/.claude/CLAUDE.md
    if [[ -d "${TEST_HOME}/.gemini" ]]; then
        [ -L "${TEST_HOME}/.gemini/GEMINI.md" ]
        local gemini_target
        gemini_target="$(readlink "${TEST_HOME}/.gemini/GEMINI.md")"
        [ "${gemini_target}" = "${TEST_HOME}/.claude/CLAUDE.md" ]
    fi
}

@test "chezmoi verify passes" {
    run chezmoi verify \
        --config "${CONFIG_FILE}" \
        --source "${CHEZMOI_SOURCE}" \
        --destination "${TEST_HOME}" \
        --exclude=scripts
    [ "$status" -eq 0 ]
}

@test "chezmoi doctor has no critical issues" {
    run chezmoi doctor \
        --config "${CONFIG_FILE}"
    # chezmoi doctor may exit non-zero when optional tools are absent;
    # filter out known-optional tool warnings (age, gpg, secret, etc.)
    # and only fail on unexpected error lines.
    local errors
    # In CI, chezmoi doctor reports errors for source-dir and working-tree
    # because ~/.local/share/chezmoi doesn't exist (we use --source flag).
    # Filter these along with optional tool warnings.
    errors="$(echo "${output}" | grep -i "^error" | grep -iv -e "source-dir" -e "working-tree" -e "age" -e "gpg" -e "secret" -e "1password" -e "bitwarden" -e "dashlane" -e "gopass" -e "keepass" -e "lastpass" -e "pass " -e "vault" -e "vimdiff" -e "pinentry" || true)"
    [ -z "${errors}" ]
}
