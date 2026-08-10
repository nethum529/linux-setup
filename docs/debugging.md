# Debugging

Symptom → cause → fix, ordered by how likely you are to hit them during
bring-up. Most entries are failure modes this setup has actually produced.

## First triage, any problem

```sh
hyprctl configerrors                  # hyprland config parse problems
systemctl --user --failed             # dead user services
systemctl --failed                    # dead system services
journalctl -b -p err --no-pager | tail -30
journalctl --user -u <unit> -e        # one service's log
```

## install.sh aborts at stow

Cause: real files already exist where symlinks go (fresh CachyOS ships a
default `~/.config/fish/config.fish`).

```sh
stow --target="$HOME" --no-folding -n -v home 2>&1 | grep -i conflict   # list them
mkdir -p ~/config-backup && mv <each-conflict> ~/config-backup/
./install.sh --no-pkgs
```

`--adopt` (then `git checkout .`) also works but silently overwrites repo
content with local files if you forget the checkout — prefer the backup path.

## Hyprland: black screen / SIGABRT / "no allocator available"

Cause: `AQ_DRM_DEVICES` points at DRM symlinks that do not exist on this
hardware, or a device order the allocator rejects.

```sh
ls -l /dev/dri/                       # igpu-card + nv-card present?
cat ~/.config/hypr/gpu.conf           # matches the hardware you see in lspci?
sudo ./tools/gen-gpu-conf.sh          # regenerate both, then relaunch Hyprland
```

Rules encoded in the generator, if you must hand-fix: iGPU first in
`AQ_DRM_DEVICES`; never use `/dev/dri/by-path/*` names (they contain colons,
Aquamarine splits on ":"); NVIDIA-only boxes need no `AQ_DRM_DEVICES` at all.
Hyprland's own log: `~/.local/share/hyprland/hyprlandCrashReport*.txt` and
`journalctl --user -u hyprland*` depending on launch path.

## Video playback melts the CPU (software decode)

Cause: `LIBVA_DRIVER_NAME` does not match the GPU apps actually render on.

```sh
vainfo                                # errors → wrong driver forced
# hybrid: radeonsi (AMD iGPU) or iHD (Intel); NVIDIA-only: nvidia
sudo ./tools/gen-gpu-conf.sh          # re-detect, then restart the session
```

Confirmed failure shape (2026-08-01): forcing `nvidia` on the hybrid laptop →
0% NVDEC use, load average 11+. Check who renders: `nvidia-smi` decoder %,
or per-process `/proc/<pid>/fdinfo/*` DRM clients.

## Ambxst bar/dock/binds missing or stale

```sh
pgrep -a quickshell                   # shell running at all?
axctl reload || pkill quickshell      # reload; autostart brings it back
# binds only: Super+Alt+B reloads ~/.config/ambxst/binds.json
journalctl --user -e | grep -i quickshell
```

JSON syntax errors in `~/.config/ambxst/config/*.json` fail silently —
validate with `python3 -m json.tool <file>` after edits.

## No audio

```sh
systemctl --user status pipewire wireplumber pipewire-pulse
systemctl --user restart pipewire wireplumber pipewire-pulse
pactl info                            # should name PipeWire as the server
```

## Tailscale: names in *.ts.net do not resolve

Cause: `/etc/resolv.conf` is a plain file → resolved in "foreign" mode →
tailscaled cannot program split DNS. Full writeup: [tailscale.md](tailscale.md).

```sh
tailscale status                      # shows the health warning when miswired
resolvectl status | grep mode         # must say: stub
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
sudo systemctl restart tailscaled
```

## Voice activation dead

Layered — test from the bottom up:

```sh
systemctl --user status hva           # 1. daemon alive?
pgrep -f Handy                        # 2. Handy app running? (autostart .desktop)
hva serve --config ~/.config/handy-voice   # 3. foreground run, watch it hear you
```

Common causes, in order:
- Handy never installed → `./handy/install-handy.sh` (parity layer runs it;
  also registers the app-search entry — if "Handy" doesn't appear in the
  launcher, this script didn't run).
- Speech model not downloaded yet: first transcription pulls ~600 MB into
  `~/.cache/huggingface`; launch Handy once with network.
- Mic muted or wrong default source (`pactl list sources short`). Device
  selections are deliberately not seeded; Handy uses the machine default.
- Keybind expectations: transcribe is **Left-Shift+Z** — Handy's own global
  shortcut from the seeded settings, invisible to `hyprctl binds`. The wake
  word "mars" only works while `hva.service` runs.
- Listening indicator missing from the bar → parity overlay not applied
  (HvaIndicator widget) or hva not publishing to `~/.local/state/hva/`.
- venv broken after a python upgrade → re-run `~/handy-voice-activation/install.sh`.

## usage / agentdash errors

- "OAuth token expired" → open Claude Code once; it refreshes
  `~/.claude/.credentials.json`. agentdash only reads that file.
- Empty Codex numbers → no sessions under `~/.codex/sessions` yet.
- Service log: `journalctl --user -u agentdash -e`.

## NVIDIA driver refuses to load (RTX 50 series)

Blackwell needs the **open** kernel modules — `nvidia-580xx-open-dkms`, never
the proprietary flavor. Check `dkms status` after kernel upgrades and
`journalctl -b | grep -i nvidia` for module taint. See
[hardware.md](hardware.md).

## Wrong-username breakage

Symptom: a unit or script fails with "No such file or directory" on a
`/home/nethum/...` path. Find every assumption:

```sh
git grep -l "/home/nethum" -- . && grep -rl "/home/nethum" ~/.config/systemd/user/
```

Rewrite the paths (or create the `nethum` user). Known carriers:
`agentdash.service`, the `hva`/`usage` wrappers, kbinds-adjacent scripts.

## Monitors wrong / a screen stays black

The shipped `monitors.conf` is the source laptop's layout; unknown outputs get
`monitor = , preferred, auto, 1`. Run `nwg-displays`, arrange, Apply — it owns
`monitors.conf` + `workspaces.conf` and hot-reloads them. Never hand-edit
monitor lines into `hyprland.conf`; nwg-displays' file silently wins.
