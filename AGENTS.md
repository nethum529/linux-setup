# AGENTS.md — bringing this setup up on a machine

Target: CachyOS (or Arch with CachyOS repos) → power-on to a working
Hyprland + Ambxst desktop. Anything broken: [docs/debugging.md](docs/debugging.md).

## Happy path

```sh
git clone https://github.com/nethum529/linux-setup ~/linux-setup
cd ~/linux-setup
./install.sh          # needs sudo; idempotent; --no-pkgs skips pacman
```

The script handles: packages (`packages.txt`), stow of all dotfiles, GPU
detection (`tools/gen-gpu-conf.sh` → `gpu.conf` + udev rule), login-manager
enable (only when none is active), the Tailscale/resolved DNS fix, agentdash
deploy + service, tool-ring and handy-voice-activation clone + install, and
the **parity layer** (`parity/install-parity.sh`): the Ambxst shell itself
with the custom bar widgets, hyprexpo (Super+Tab), wallpapers, prebuilt tools
(herdr/herdmates/teammux/hyprshell), and the axi toolchain. Without the parity
layer the desktop comes up barebones — almost no keybinds, no workspace
switching, empty bar. `parity/README.md` maps each symptom to its cause.

## What you must do around it

1. If stow reports conflicts: back up and remove the listed real files, re-run
   with `--no-pkgs`. Details in debugging.md.
2. Interactive auth no script can do:
   - `sudo tailscale up` → open the printed link.
   - `npm install -g @anthropic-ai/claude-code`, then log in once (agentdash
     reads the credentials it writes).
   - Handy is fully automated (parity layer downloads the AppImage, registers
     app-search/autostart entries, seeds keybinds + vocabulary). Only launch it
     once so it fetches its speech model (~600 MB, needs network).
3. Reboot (or relog) once so GPU env, udev symlinks, and the DM take effect.
4. Run `nwg-displays`, arrange the monitors, Apply.
5. Different username than `nethum`? Fix the hard-coded paths first —
   debugging.md § "Wrong-username breakage".

## Verify (all should pass before calling it done)

```sh
hyprctl configerrors                        # empty
ls -l /dev/dri/ | grep -E "igpu-card|nv-card"   # hybrid boxes only
systemctl --user --failed                   # empty
tailscale status                            # nodes listed, no health warnings
usage                                       # prints rate-limit windows
systemctl --user status hva agentdash       # both active (hva needs Handy installed)
pgrep -af 'qs -p'                           # Ambxst shell (process is 'qs', not 'quickshell')
hyprpm list | grep -A2 hyprexpo             # enabled: true  (Super+Tab)
hyprctl binds | grep -c workspace           # dozens, not a handful
herdr --help >/dev/null && echo herdr-ok
```

Keybind ground truth: `~/.config/ambxst/binds.json` (applied by Ambxst) plus
the hyprexpo submap in `hyprland.conf`. If binds are missing, Ambxst isn't
running — that's a parity-layer problem, not a binds.json problem.

## Repo map

- `home/` — stow package mirroring `$HOME`; `tools/` — gen-gpu-conf.sh + vendored agentdash
- `docs/hardware.md` — GPU matrix + per-machine assumptions (read before GPU debugging)
- `docs/apps.md` — what the finished machine should contain
- `docs/tailscale.md`, `docs/voice.md`, `docs/usage-indicator.md` — per-component docs

## Rules

- Never hand-edit generated files (`gpu.conf`, the udev rule, `monitors.conf`);
  re-run their generators.
- pacman only, no AUR helpers — the `-bin` packages come from CachyOS repos.
- `install.sh` and the generators are idempotent; prefer re-running them to
  patching their output.
