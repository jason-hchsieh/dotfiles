#!/usr/bin/env bats
# Template rendering tests.
# Validates that each .tmpl file renders without error across all 12 data combos.
#
# Run:
#   bats tests/templates/test_templates.bats

load '../helpers/setup'
load '../helpers/mock_data'

# ---------------------------------------------------------------------------
# Helper: render a single template with a given config and assert exit 0.
# Usage: render_template <config_file> <template_file>
# ---------------------------------------------------------------------------
render_template() {
    local config_file="$1"
    local template_file="$2"
    run chezmoi execute-template \
        --config "${config_file}" \
        --source "${CHEZMOI_SOURCE}" \
        < "${template_file}"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Helper: render a template and additionally validate output as JSON.
# Empty output is allowed (templates gated by lookPath may emit nothing).
# Usage: render_template_json <config_file> <template_file>
# ---------------------------------------------------------------------------
render_template_json() {
    local config_file="$1"
    local template_file="$2"
    run chezmoi execute-template \
        --config "${config_file}" \
        --source "${CHEZMOI_SOURCE}" \
        < "${template_file}"
    [ "$status" -eq 0 ]
    # Only validate JSON when the output is non-empty (lookPath may gate it).
    if [[ -n "${output// /}" ]]; then
        echo "${output}" | jq . > /dev/null
    fi
}

# ---------------------------------------------------------------------------
# Callback wrappers — one per template.
# Each accepts (work, osid, sudoer) and runs the appropriate render helper.
# ---------------------------------------------------------------------------

_render_chezmoiignore() {
    local config="${TEST_DIR}/chezmoi.toml"
    generate_chezmoi_config "$1" "$2" "$3" "${config}"
    render_template "${config}" "${CHEZMOI_SOURCE}/.chezmoiignore.tmpl"
}

_render_zshrc() {
    local config="${TEST_DIR}/chezmoi.toml"
    generate_chezmoi_config "$1" "$2" "$3" "${config}"
    render_template "${config}" "${CHEZMOI_SOURCE}/dot_zshrc.tmpl"
}

_render_zprofile() {
    local config="${TEST_DIR}/chezmoi.toml"
    generate_chezmoi_config "$1" "$2" "$3" "${config}"
    render_template "${config}" "${CHEZMOI_SOURCE}/dot_zprofile.tmpl"
}

_render_git_config() {
    local config="${TEST_DIR}/chezmoi.toml"
    generate_chezmoi_config "$1" "$2" "$3" "${config}"
    render_template "${config}" "${CHEZMOI_SOURCE}/dot_config/git/config.tmpl"
}

_render_ssh_config() {
    local config="${TEST_DIR}/chezmoi.toml"
    generate_chezmoi_config "$1" "$2" "$3" "${config}"
    render_template "${config}" "${CHEZMOI_SOURCE}/private_dot_ssh/config.tmpl"
}

_render_claude_settings() {
    local config="${TEST_DIR}/chezmoi.toml"
    generate_chezmoi_config "$1" "$2" "$3" "${config}"
    render_template_json "${config}" "${CHEZMOI_SOURCE}/dot_claude/settings.json.tmpl"
}

_render_codex_config() {
    local config="${TEST_DIR}/chezmoi.toml"
    generate_chezmoi_config "$1" "$2" "$3" "${config}"
    render_template "${config}" "${CHEZMOI_SOURCE}/dot_codex/config.toml.tmpl"
}

_render_gemini_settings() {
    local config="${TEST_DIR}/chezmoi.toml"
    generate_chezmoi_config "$1" "$2" "$3" "${config}"
    render_template_json "${config}" "${CHEZMOI_SOURCE}/dot_gemini/settings.json.tmpl"
}

_render_codex_agents_symlink() {
    local config="${TEST_DIR}/chezmoi.toml"
    generate_chezmoi_config "$1" "$2" "$3" "${config}"
    render_template "${config}" "${CHEZMOI_SOURCE}/dot_codex/symlink_AGENTS.md.tmpl"
}

_render_gemini_symlink() {
    local config="${TEST_DIR}/chezmoi.toml"
    generate_chezmoi_config "$1" "$2" "$3" "${config}"
    render_template "${config}" "${CHEZMOI_SOURCE}/dot_gemini/symlink_GEMINI.md.tmpl"
}

# ---------------------------------------------------------------------------
# Tests — one @test block per template; each iterates all 12 combos.
# ---------------------------------------------------------------------------

@test ".chezmoiignore.tmpl renders without error across all combos" {
    all_combos _render_chezmoiignore
}

@test "dot_zshrc.tmpl renders without error across all combos" {
    all_combos _render_zshrc
}

@test "dot_zprofile.tmpl renders without error across all combos" {
    all_combos _render_zprofile
}

@test "dot_config/git/config.tmpl renders without error across all combos" {
    all_combos _render_git_config
}

@test "private_dot_ssh/config.tmpl renders without error across all combos" {
    all_combos _render_ssh_config
}

@test "dot_claude/settings.json.tmpl renders without error and produces valid JSON across all combos" {
    all_combos _render_claude_settings
}

@test "dot_codex/config.toml.tmpl renders without error across all combos" {
    all_combos _render_codex_config
}

@test "dot_gemini/settings.json.tmpl renders without error and produces valid JSON across all combos" {
    all_combos _render_gemini_settings
}

@test "dot_codex/symlink_AGENTS.md.tmpl renders without error across all combos" {
    all_combos _render_codex_agents_symlink
}

@test "dot_gemini/symlink_GEMINI.md.tmpl renders without error across all combos" {
    all_combos _render_gemini_symlink
}
