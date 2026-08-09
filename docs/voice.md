# Voice activation stack

Two pieces: **Handy** does speech-to-text; **handy-voice-activation (hva)**
listens for the wake word and toggles Handy hands-free.

## Handy

- `~/Applications/Handy.AppImage`, autostarted via `~/.config/autostart/Handy.desktop`.
- Push-to-talk/toggle STT that types the transcript into the focused window.

## handy-voice-activation

- Repo: <https://github.com/nethum529/handy-voice-activation>, cloned at
  `~/handy-voice-activation`. Its own `install.sh` builds a `.venv`, installs the
  `~/.local/bin/hva` wrapper, and installs + enables the `hva.service` user unit.
- Always-on wake-word daemon: hearing the wake phrase toggles Handy recording
  via `SIGUSR2`; recording stops on silence timeout.

## Config (`~/.config/handy-voice/`, stowed from this repo)

- `config.toml` — wake phrase `"mars"`, 1 confirmation, 1.25 s silence timeout,
  120 s max recording, SIGUSR2 toggle method.
- `env` — Wayland/DBus session variables the daemon needs when started by systemd.

## Operate

```sh
systemctl --user status hva      # daemon state
hva serve --config ~/.config/handy-voice   # foreground debug run
```
