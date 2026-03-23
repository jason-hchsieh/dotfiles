# Chezmoi Dotfiles Testing Design

## Goal

Add two-tier automated testing for chezmoi dotfiles: fast template validation and full end-to-end apply tests. Tests run locally via Bats and in CI via GitHub Actions across macOS, Ubuntu, and Arch Linux.

## File Structure

```
tests/
  helpers/
    setup.bash              # Shared Bats setup (install chezmoi, create temp dirs)
    mock_data.bash          # Functions to generate chezmoi config combos
  templates/
    test_templates.bats     # Fast tier: template rendering tests
  e2e/
    test_apply.bats         # Full tier: end-to-end chezmoi apply
  docker/
    Dockerfile.ubuntu       # Ubuntu test image
    Dockerfile.arch         # Arch Linux test image
  run.sh                    # Local runner script
.github/
  workflows/
    test.yml                # GitHub Actions workflow
```

## Tier 1: Template Validation (Fast)

Runs `chezmoi execute-template` on every `.tmpl` file with different data combos to catch rendering errors.

### Data Combos

All mock configs include baseline required values:
- `.username` = `"testuser"`
- `.email` = `"test@example.com"`
- `.ephemeral` = `true`
- `.zshPlugins` = `["vi-mode", "zsh-syntax-highlighting"]`

The combo matrix varies these:

| Variable | Values |
|----------|--------|
| `.work` / `.personal` | `true`/`false`, `false`/`true` |
| `.osid` | `darwin`, `linux-ubuntu`, `linux-arch` |
| `.sudoer` | `true`, `false` |

12 combinations total (2 x 3 x 2).

### What Gets Validated

1. **Template renders without error** — catches syntax errors, missing variables
2. **Output is valid format** — JSON templates parsed with `jq`, TOML templates checked for basic syntax
3. **Conditional gating works** — templates gated on `lookPath` render empty when the tool binary is absent

### How Mock Data Works

Each combo generates a temporary chezmoi config file with the appropriate data values. The config is passed to `chezmoi execute-template` via the `--config` flag.

The `lookPath` checks depend on actual binaries on PATH and cannot be easily mocked at the template level. These guards are implicitly tested in the e2e tier (where the tools are absent, so `.chezmoiignore` excludes the files).

### Templates Covered

Templates are discovered dynamically via glob (`home/**/*.tmpl`), with the following exclusions:

**Excluded from fast tier** (tested only in e2e):
- `home/.chezmoi.toml.tmpl` — uses `promptBool`/`promptString` which require interactive input
- `home/.chezmoiexternal.toml.tmpl` — uses `gitHubLatestRelease` which makes live GitHub API calls
- Any template using the `completion` function (e.g., completions templates) — not available in `execute-template`

**Included in fast tier:**
- `home/.chezmoiignore.tmpl`
- `home/dot_zshrc.tmpl`
- `home/dot_zprofile.tmpl`
- `home/dot_config/git/config.tmpl`
- `home/private_dot_ssh/config.tmpl`
- `home/dot_claude/settings.json.tmpl`
- `home/dot_codex/config.toml.tmpl`
- `home/dot_gemini/settings.json.tmpl`
- `home/dot_codex/symlink_AGENTS.md.tmpl`
- `home/dot_gemini/symlink_GEMINI.md.tmpl`
- Any new `.tmpl` files added in the future (auto-discovered unless excluded)

## Tier 2: End-to-End Apply (Full)

Runs `chezmoi init` + `chezmoi apply` on a clean environment and verifies the result.

### What Gets Verified

1. `chezmoi apply` exits cleanly (no errors)
2. Expected files exist at target paths (`~/.zshrc`, `~/.claude/CLAUDE.md`, `~/.config/git/config`, etc.)
3. Symlinks resolve correctly (`~/.codex/AGENTS.md` -> `~/.claude/CLAUDE.md`, same for Gemini)
4. `chezmoi verify` passes (target state matches source)
5. `chezmoi doctor` reports no critical issues

### Platform Strategy

| Platform | Environment | Runner |
|----------|-------------|--------|
| macOS | Native GitHub Actions runner | `macos-latest` |
| Ubuntu | Docker container (`Dockerfile.ubuntu`) | `ubuntu-latest` |
| Arch | Docker container (`Dockerfile.arch`) | `ubuntu-latest` |

### Config Data

Each e2e run uses a non-interactive chezmoi init with a pre-built config file (no prompts). Tests use `personal` + `ephemeral` defaults as the safest option for CI (no work-specific or sudo-dependent steps).

### Limitations

- E2e tests do not install `claude`, `codex`, or `gemini` binaries in CI. AI agent configs are correctly ignored by `.chezmoiignore`. Template rendering correctness for these is covered by the fast tier.
- Install scripts (`run_once_change-shell-to-zsh.sh`) are not tested — they have side effects that are risky in CI. Can be added later with more isolation.

## Docker Images

### Dockerfile.ubuntu

Minimal Ubuntu image with:
- `chezmoi` installed
- `git`, `zsh`, `curl` for basic functionality
- Non-root test user

### Dockerfile.arch

Minimal Arch image with:
- `chezmoi` installed via pacman or binary
- `git`, `zsh`, `curl`
- Non-root test user

Docker images are built in CI and cached via GitHub Actions cache to speed up subsequent runs.

## GitHub Actions Workflow

### Triggers

```yaml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 9 * * 5'  # Weekly Friday run
  workflow_dispatch:        # Manual trigger
```

### Jobs

| Job | Runner | What it does |
|-----|--------|-------------|
| `template-validation` | `ubuntu-latest` | Install Bats + chezmoi, run fast tier across all 12 data combos |
| `e2e-macos` | `macos-latest` | Native chezmoi init + apply + verify |
| `e2e-ubuntu` | `ubuntu-latest` | Build Docker image, run chezmoi init + apply + verify inside container |
| `e2e-arch` | `ubuntu-latest` | Build Docker image (Arch), same e2e flow |

- Template validation runs on every push/PR (~1 min)
- E2e jobs run on every push/PR (Docker builds cached)
- Weekly scheduled run catches upstream breakage (chezmoi updates, oh-my-zsh changes)

## Local Runner

`./tests/run.sh` — a simple script that:
1. Checks Bats is installed (prompts to install via brew if missing)
2. Runs `bats tests/templates/` for the fast tier
3. Optionally runs e2e with `--e2e` flag (requires Docker for Linux tests)

Developers run this before pushing.

## Out of Scope

- Testing install scripts (`run_once_*`) — side effects make CI testing risky
- Code coverage measurement — can be added later
- Shell startup time benchmarking — nice to have, not essential
- Testing with actual AI agent binaries installed
