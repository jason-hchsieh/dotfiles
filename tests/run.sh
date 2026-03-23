#!/bin/bash

set -euo pipefail

# Script directory and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Change to repo root
cd "${REPO_ROOT}"

# Parse arguments
mode="fast"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      cat <<EOF
Usage: tests/run.sh [OPTIONS]

Options:
  --help, -h     Show this help message
  --e2e          Run e2e tests only
  --all          Run all test tiers (fast + e2e)

By default, runs fast tier only: tests/templates/test_templates.bats
EOF
      exit 0
      ;;
    --e2e)
      mode="e2e"
      shift
      ;;
    --all)
      mode="all"
      shift
      ;;
    *)
      echo "Error: unknown option '$1'" >&2
      exit 1
      ;;
  esac
done

# Check for bats
if ! command -v bats &>/dev/null; then
  echo "Error: bats is not installed"
  echo "  Install with: brew install bats-core"
  exit 1
fi

# Check for chezmoi
if ! command -v chezmoi &>/dev/null; then
  echo "Error: chezmoi is not installed"
  exit 1
fi

# Run tests based on mode
case "$mode" in
  fast)
    bats tests/templates/test_templates.bats
    ;;
  e2e)
    bats tests/e2e/test_apply.bats
    ;;
  all)
    bats tests/templates/test_templates.bats tests/e2e/test_apply.bats
    ;;
esac
