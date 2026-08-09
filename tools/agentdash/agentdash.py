#!/usr/bin/env python3
"""agentdash - track Claude Code and Codex rate-limit usage (5h + weekly).

Usage:
  agentdash.py            # fetch and print current usage
  agentdash.py daemon     # poll forever, writing state JSON for other consumers
"""
import argparse
import json
import sys
import time
import urllib.request
from datetime import datetime
from pathlib import Path

CLAUDE_CREDS = Path.home() / ".claude" / ".credentials.json"
CODEX_SESSIONS = Path.home() / ".codex" / "sessions"
STATE_FILE = Path.home() / ".local" / "state" / "agentdash" / "usage.json"
DEFAULT_INTERVAL = 300  # seconds
WEEKLY_WINDOW_MINUTES = 7 * 24 * 60


def iso_to_epoch(s):
    return datetime.fromisoformat(s).timestamp()


def get_claude():
    creds = json.loads(CLAUDE_CREDS.read_text())["claudeAiOauth"]
    if creds["expiresAt"] / 1000 < time.time():
        return {"error": "OAuth token expired (use Claude Code to refresh it)"}
    req = urllib.request.Request(
        "https://api.anthropic.com/api/oauth/usage",
        headers={
            "Authorization": f"Bearer {creds['accessToken']}",
            "anthropic-beta": "oauth-2025-04-20",
        },
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        data = json.load(resp)
    return {
        "plan": creds.get("subscriptionType", "?"),
        "session_pct": data["five_hour"]["utilization"],
        "session_resets": iso_to_epoch(data["five_hour"]["resets_at"]),
        "weekly_pct": data["seven_day"]["utilization"],
        "weekly_resets": iso_to_epoch(data["seven_day"]["resets_at"]),
    }


def get_codex():
    files = sorted(CODEX_SESSIONS.glob("*/*/*/*.jsonl"),
                   key=lambda p: p.stat().st_mtime, reverse=True)
    for f in files[:5]:
        rl = last_rate_limits(f)
        if rl:
            return {
                "plan": rl.get("plan_type") or "?",
                **rate_limit_windows(rl),
            }
    return {"error": "no rate_limits found in recent Codex sessions"}


def rate_limit_windows(rate_limits):
    windows = {}
    for name in ("primary", "secondary"):
        limit = rate_limits.get(name)
        if not limit:
            continue
        window_minutes = limit.get("window_minutes")
        window = "weekly" if window_minutes and window_minutes >= WEEKLY_WINDOW_MINUTES else "session"
        windows[f"{window}_pct"] = limit["used_percent"]
        windows[f"{window}_resets"] = limit["resets_at"]
    return windows


def last_rate_limits(path):
    """Last rate_limits payload in a session file, reading only the tail."""
    size = path.stat().st_size
    with open(path, "rb") as f:
        f.seek(max(0, size - 262144))
        lines = f.read().split(b"\n")
    for line in reversed(lines):
        if b'"rate_limits"' not in line:
            continue
        try:
            rl = json.loads(line)["payload"].get("rate_limits")  # token_count event
        except (json.JSONDecodeError, KeyError, TypeError):
            continue
        if rl and (rl.get("primary") or rl.get("secondary")):
            return rl
    return None


def collect(previous=None):
    state = {"fetched_at": time.time(), "providers": {}}
    previous_providers = (previous or {}).get("providers", {})
    for name, fn in (("claude", get_claude), ("codex", get_codex)):
        try:
            provider = fn()
        except Exception as e:
            provider = {"error": str(e)}
        if "error" in provider:
            previous_provider = previous_providers.get(name, {})
            if "error" not in previous_provider:
                provider = {**previous_provider, "last_error": provider["error"]}
        state["providers"][name] = provider
    return state


def read_state():
    try:
        return json.loads(STATE_FILE.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def write_state(state):
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    tmp = STATE_FILE.with_suffix(".tmp")
    tmp.write_text(json.dumps(state))
    tmp.rename(STATE_FILE)


def bar(pct, width=10):
    filled = round(min(pct, 100) / 100 * width)
    return "█" * filled + "░" * (width - filled)


def fmt_reset(epoch):
    dt = datetime.fromtimestamp(epoch)
    if dt.date() == datetime.now().date():
        return dt.strftime("%H:%M")
    return dt.strftime("%a %H:%M")


def fmt_window(provider, name):
    pct = provider.get(f"{name}_pct")
    resets = provider.get(f"{name}_resets")
    if pct is None or resets is None:
        return "-".ljust(26)
    return f"{pct:>3.0f}% {bar(pct)} ↺ {fmt_reset(resets):<9}"


def cmd_status():
    state = collect(read_state())
    write_state(state)
    print("agent   plan  5h window                   weekly")
    for name in ("claude", "codex"):
        p = state["providers"].get(name, {"error": "missing"})
        if "error" in p:
            print(f"{name:<7} -     {p['error']}")
            continue
        print(f"{name:<7} {p['plan']:<5} "
              f"{fmt_window(p, 'session')}  {fmt_window(p, 'weekly')}")


def cmd_daemon(interval):
    previous = read_state()
    while True:
        previous = collect(previous)
        write_state(previous)
        time.sleep(interval)


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("command", nargs="?", default="status", choices=["status", "daemon"])
    ap.add_argument("--interval", type=int, default=DEFAULT_INTERVAL,
                    help=f"daemon poll interval in seconds (default {DEFAULT_INTERVAL})")
    args = ap.parse_args()
    if args.command == "daemon":
        cmd_daemon(args.interval)
    else:
        cmd_status()


if __name__ == "__main__":
    main()
