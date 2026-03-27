# AI Agent Dotfiles Management Design

## Goal

Manage configuration files for AI coding agents (Claude Code, Codex CLI, Gemini CLI) via chezmoi, with work/personal separation and conditional installation based on tool availability.

## File Structure

```
home/
  dot_claude/
    CLAUDE.md                          # Always present, global AI instructions
    settings.json.tmpl                 # Excluded via .chezmoiignore when claude not installed
  dot_codex/
    config.toml.tmpl                   # Gated on lookPath "codex"
    symlink_AGENTS.md.tmpl             # Symlink -> ~/.claude/CLAUDE.md
  dot_gemini/
    settings.json.tmpl                 # Gated on lookPath "gemini"
    symlink_GEMINI.md.tmpl             # Symlink -> ~/.claude/CLAUDE.md
```

## Design Decisions

### Global Instructions via CLAUDE.md

`~/.claude/CLAUDE.md` is the single source of truth for global AI agent instructions. Codex and Gemini reference it via symlinks:

- `~/.codex/AGENTS.md` -> `~/.claude/CLAUDE.md`
- `~/.gemini/GEMINI.md` -> `~/.claude/CLAUDE.md`

`CLAUDE.md` is always installed regardless of whether `claude` is on the machine, since other agents depend on it.

### Conditional Installation

For Codex and Gemini, entire directories are excluded via `.chezmoiignore.tmpl` when the tool isn't present. For Claude, only `settings.json` is ignored (not the whole directory) so that `CLAUDE.md` is always present for other agents' symlinks.

`.chezmoiignore.tmpl` additions:

```gotemplate
{{ if not (lookPath "claude") }}
.claude/settings.json
{{ end }}
{{ if not (lookPath "codex") }}
.codex/**
{{ end }}
{{ if not (lookPath "gemini") }}
.gemini/**
{{ end }}
```

The `~/.claude/` directory is never fully ignored — `CLAUDE.md` is always installed.

### Work/Personal Split

Claude `settings.json.tmpl` uses `{{ if .work }}` blocks for work-specific overrides. Current settings serve as the shared baseline. Codex and Gemini start with minimal configs identical across work/personal.

### Scope

Only `settings.json` is managed for Claude Code (not `settings.local.json`). Plugin-installed files (hooks, plugin cache) are left to the plugin system.

## Config Details

### CLAUDE.md

- Plain markdown, no template — global AI instructions don't need work/personal variation
- Always installed to `~/.claude/CLAUDE.md`

### Claude Code settings.json.tmpl

- Excluded via `.chezmoiignore.tmpl` when `claude` is not installed (avoids creating an empty file that could conflict with Claude Code defaults)
- Contains: hooks config, enabled plugins, mode preferences
- Work/personal branching via `{{ if .work }}` for plugin and hook differences

### Codex config.toml.tmpl

- Gated on `lookPath "codex"`
- Minimal: model selection only (`o4-mini`)
- Grow as needed

### Gemini settings.json.tmpl

- Gated on `lookPath "gemini"`
- Minimal: model selection only (`gemini-2.5-pro`)
- Grow as needed

### Symlinks

`symlink_AGENTS.md.tmpl` and `symlink_GEMINI.md.tmpl` contain:

```
{{ .chezmoi.homeDir }}/.claude/CLAUDE.md
```

## What Is NOT Managed

For `~/.claude/`:
- `settings.local.json` (permissions)
- `plugins/` (auto-managed by plugin system)
- `hooks/` (plugin-installed)
- `history.jsonl`, `sessions/`, `projects/`, `plans/`, `todos/`
- `debug/`, `cache/`, `telemetry/`, `statsig/`
- `backups/`, `file-history/`, `shell-snapshots/`
- `paste-cache/`, `session-env/`, `tasks/`
- `stats-cache.json`
