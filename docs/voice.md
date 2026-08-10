# Voice activation stack

Three pieces, all installed automatically:

1. **Handy** — offline speech-to-text (AppImage). `handy/install-handy.sh`
   (run by the parity layer) downloads the latest release, registers it in app
   search + autostart, and seeds the laptop's settings.
2. **handy-voice-activation (hva)** — always-on wake-word daemon; installed by
   `install.sh` from <https://github.com/nethum529/handy-voice-activation>
   (venv, `~/.local/bin/hva`, `hva.service`).
3. **Listening indicator** — the `HvaIndicator` Ambxst bar widget (parity
   overlay). hva publishes its FSM state atomically to
   `$XDG_STATE_HOME/handy-voice/indicator.json` (`{listening, state, ts}`,
   heartbeat, stale after 4 s) and the widget shows while listening; Handy's
   own overlay is set to "none" on purpose, so the bar widget is the only
   indicator. `install-handy.sh` seeds an IDLE copy so the widget parses
   cleanly before the service's first start.

## The controls

| trigger | what | where it's defined |
|---|---|---|
| say **"mars"** | toggles Handy recording hands-free (SIGUSR2) | `~/.config/handy-voice/config.toml` (stowed) |
| hold **Left-Shift+Z** | Handy transcribe push-to-talk | Handy's own global shortcut, seeded in `handy/settings_store.json` — NOT a Hyprland bind |
| **Ctrl+Shift+Space** | transcribe with AI post-processing | same |
| **Escape** | cancel recording | same |

Custom vocabulary (correction threshold 0.18) is seeded too:
lavish, axi, claude, code, codex, director, nethum, opencode, graph, diff, PR, git.

## First run on a new machine

- Launch Handy once (app search "Handy"; autostarts from then on). The first
  transcription downloads the parakeet model (~600 MB) into
  `~/.cache/huggingface` — needs network.
- Device selections (mic / output / GPU) are deliberately NOT seeded; Handy
  uses the machine's defaults. Wrong default source is the #1 "it's not
  listening" cause: `pactl list sources short`.
- Wake word needs the daemon: `systemctl --user status hva`.

## Operate / debug

```sh
systemctl --user status hva                  # daemon state
pgrep -f Handy                               # app running?
hva serve --config ~/.config/handy-voice     # foreground run, watch it hear you
ls "$XDG_STATE_HOME"/hva/ 2>/dev/null || ls ~/.local/state/hva/   # indicator state file
```

Full failure ladder: [debugging.md](debugging.md) § "Voice activation dead".
