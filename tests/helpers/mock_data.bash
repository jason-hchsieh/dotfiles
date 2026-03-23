# Helper functions to generate chezmoi config files for template rendering tests.
# Load this in each test file:
#   load 'helpers/mock_data'

# Baseline values present in every generated config.
readonly MOCK_USERNAME="testuser"
readonly MOCK_EMAIL="test@example.com"
readonly MOCK_EPHEMERAL="true"
readonly MOCK_ZSH_PLUGINS='["vi-mode", "zsh-syntax-highlighting"]'

# ---------------------------------------------------------------------------
# generate_chezmoi_config <work> <osid> <sudoer> <output_path>
#
# Writes a valid chezmoi TOML config to <output_path>.
#
# Arguments:
#   work        - "true" or "false"
#   osid        - e.g. "darwin", "linux-ubuntu", "linux-arch"
#   sudoer      - "true" or "false"
#   output_path - destination file (directory must already exist)
#
# Example:
#   generate_chezmoi_config false darwin true "${TEST_DIR}/chezmoi.toml"
# ---------------------------------------------------------------------------
generate_chezmoi_config() {
    local work="${1:?work argument is required}"
    local osid="${2:?osid argument is required}"
    local sudoer="${3:?sudoer argument is required}"
    local output_path="${4:?output_path argument is required}"

    # Derive personal as the logical inverse of work.
    local personal
    if [[ "${work}" == "true" ]]; then
        personal="false"
    else
        personal="true"
    fi

    cat > "${output_path}" <<EOF
[data]
  username = "${MOCK_USERNAME}"
  email = "${MOCK_EMAIL}"
  work = ${work}
  ephemeral = ${MOCK_EPHEMERAL}
  personal = ${personal}
  osid = "${osid}"
  sudoer = ${sudoer}
  zshPlugins = [
      "vi-mode",
      "zsh-syntax-highlighting",
  ]

[github]
    refreshPeriod = "12h"
EOF
}

# ---------------------------------------------------------------------------
# all_combos <callback>
#
# Iterates all 12 combinations of (.work, .osid, .sudoer) and calls
# <callback> once per combo with the arguments: <work> <osid> <sudoer>
#
# Combo matrix:
#   work: true, false                           (2 values)
#   osid: darwin, linux-ubuntu, linux-arch      (3 values)
#   sudoer: true, false                         (2 values)
#   Total: 2 × 3 × 2 = 12 combos
#
# Example:
#   run_combo() { echo "work=$1 osid=$2 sudoer=$3"; }
#   all_combos run_combo
# ---------------------------------------------------------------------------
all_combos() {
    local callback="${1:?callback argument is required}"

    local work osid sudoer
    for work in true false; do
        for osid in darwin linux-ubuntu linux-arch; do
            for sudoer in true false; do
                "${callback}" "${work}" "${osid}" "${sudoer}"
            done
        done
    done
}
