# Usage indicator (agentdash)

Tracks Claude Code and Codex rate-limit usage (5-hour and weekly windows).
Vendored in this repo at `tools/agentdash/` (no upstream remote); deployed to
`~/Projects/agentdash` by `install.sh`.

## Pieces

- `tools/agentdash/agentdash.py` — single-file Python app.
  - `agentdash.py` prints current usage once.
  - `agentdash.py daemon` polls every 5 min and writes state JSON to
    `~/.local/state/agentdash/usage.json` for other consumers (bar widgets, TUIs).
- `home/.local/bin/usage` — CLI wrapper (`usage` in a terminal → current numbers).
- `home/.config/systemd/user/agentdash.service` — runs the daemon.

## Data sources

- Claude: OAuth token from `~/.claude/.credentials.json` (refreshed by Claude
  Code itself; the indicator only reads it).
- Codex: session files under `~/.codex/sessions`.

## Operate

```sh
usage                                  # one-shot reading
systemctl --user status agentdash      # daemon state
cat ~/.local/state/agentdash/usage.json
```
