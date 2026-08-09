# Agent Session Dashboard — Plan & Roadmap

**Goal:** Live dashboard of all Claude Code sessions → the subagents each invokes → the Codex sessions running under each.

**Architecture:** Two pieces with a JSON contract between them: a stdlib-only Python *collector* (poll loop, ~2s) that writes `~/.local/state/agentdash/sessions.json`, and a *renderer* (TUI first) that only reads that file. Mirrors the existing `agentdash.py` daemon pattern.

**Tech stack:** Python 3 stdlib only. No inotify/watchdog initially — polling `/proc` + file mtimes is cheap at this scale.

---

## Data sources (verified 2026-06-07)

| Source | Gives |
|---|---|
| `~/.claude/sessions/<pid>.json` | live registry: pid, sessionId, cwd, status, updatedAt |
| `/proc/<pid>` + stored `procStart` | liveness check, guards PID reuse |
| `~/.claude/projects/<slug>/<sessionId>/subagents/agent-*.jsonl` | subagents: agentId, prompt (line 1), activity (mtime) |
| `~/.claude/projects/<slug>/<sessionId>.jsonl` | `subagent_type` per Agent tool_use; codex `threadId` in MCP tool_results |
| process tree: `claude` → `codex mcp-server` | which codex belongs to which claude (live) |
| `/proc/<codex-pid>/fd` readlinks | exact open rollout files per mcp-server |
| `~/.codex/sessions/Y/M/D/rollout-*.jsonl` line 1 | codex session: id, cwd, git branch, source=mcp |

**Known traps (bake into collector):**
- Worktree split-brain: transcript lives under the *main repo* slug, `subagents/` under the *worktree* slug → always index by sessionId across **all** project dirs.
- Stale `sessions/<pid>.json` files → never trust without `/proc` + procStart check.
- Transcripts are large → tail with saved byte offsets, never re-read whole files.
- Subagent "running" state: mtime < ~30s OR no matching Agent tool_result in parent transcript yet.

---

## Roadmap

### Phase 1 — Collector: live Claude sessions
- New `collector.py`: read `~/.claude/sessions/*.json`, validate liveness, emit `sessions.json` with pid, sessionId, cwd, status, project slug.
- **Verify:** output matches `ps -C claude` reality; killed session disappears within one poll.

### Phase 2 — Subagents per session
- Resolve each sessionId to its dir(s) across all project slugs; enumerate `subagents/agent-*.jsonl`.
- Parse line 1 for agentId + prompt snippet; tail parent transcript (byte-offset) for `subagent_type` and completion tool_results.
- **Verify:** spawn a subagent in a test session → appears as running → flips to done.

### Phase 3 — Codex linkage
- Live: pgrep mcp-server → walk ppids to claude pid → `/proc/fd` → rollout files → parse `session_meta`.
- Historical/fallback: `threadId` from parent transcript tool_results; cwd+time-window as last resort.
- **Verify:** matches the actual process tree while a codex MCP call runs.

### Phase 4 — Renderer (TUI)
- ANSI-refresh tree view reading `sessions.json`: session → subagents → codex children; columns: status, cwd/branch, last activity. Sized for one Kitty pane.
- **Verify:** visual check against phases 1–3 ground truth.

### Phase 5 — Optional extras (only if wanted later)
- systemd user service (reuse `agentdash.service` pattern); merge rate-limit usage from existing `agentdash.py` into the same view; recent-history pane.

---

Each phase ships independently useful output. Detailed per-task implementation plans (TDD steps) to be written per phase at execution time.
