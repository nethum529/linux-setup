# parity/ — everything the stowed dotfiles alone can't give you

`install.sh` gets a machine to a working desktop; this layer makes it
**1:1 with the source laptop**. Run it after `install.sh`:

```sh
./parity/install-parity.sh
```

## Why the ported setup felt barebones

| symptom | actual cause |
|---|---|
| No Super+number, workspaces dead, most binds missing | Binds live in Ambxst (`binds.json` → generated `~/.local/share/ambxst/hyprland.conf`, sourced by hyprland.conf). Without Ambxst installed, that file doesn't exist and Hyprland has almost no binds. |
| Super+Tab does nothing | It's the **hyprexpo** plugin (sandwichfarm fork) installed through hyprpm, not a plain bind. |
| Bar/dock missing AirPods quick-connect, usage dropdown, wifi/bt/audio/hva indicators | Those are local, uncommitted modifications to the Ambxst clone — 7 patched files + 9 custom QML widgets. They existed only on the laptop until this folder. |
| No wallpapers | They live in `~/Pictures/Wallpapers`, picked via Ambxst (Super+Comma). Never part of the dotfiles. |
| `herdr` etc. missing | Prebuilt local binaries plus an npm-prefix axi toolchain, not pacman packages. |

## Contents

```
ambxst/UPSTREAM_COMMIT        # pinned Axenide/Ambxst commit + URL
ambxst/local-changes.patch    # tracked-file modifications
ambxst/overlay/               # custom widgets + lucide icons (untracked files)
ambxst/seed/                  # generated runtime config for first-launch parity
ambxst/axctl                  # the axctl binary (no public source)
bin/                          # herdr, herdmates, teammux, hyprshell
wallpapers/                   # ~/Pictures/Wallpapers content
install-parity.sh             # applies all of the above; idempotent
```

## What it does

1. Clones `Axenide/Ambxst` at the pinned commit into `~/.local/src/ambxst`,
   applies `local-changes.patch`, copies the widget overlay, rewrites the one
   hard-coded home path.
2. Installs `axctl` and a generated `ambxst` launcher into `/usr/local/bin`.
3. Seeds `~/.local/share/ambxst` (binds + look) so the very first Hyprland
   launch matches the laptop; Ambxst regenerates these afterward.
4. Installs + enables hyprexpo via hyprpm (or prints the command if no
   Hyprland session is up).
5. Copies wallpapers (no clobber), prebuilt tools, and installs the axi npm
   toolchain + `codex-axi` via pipx.

## Updating this folder from the laptop

After changing Ambxst locally: re-run the capture —

```sh
cd ~/.local/src/ambxst
git diff > ~/Projects/linux-setup/parity/ambxst/local-changes.patch
git status --short | grep '^??' | awk '{print $2}' | \
  xargs -I{} cp --parents -r {} ~/Projects/linux-setup/parity/ambxst/overlay/
```

Same idea for new wallpapers (`cp` into `parity/wallpapers/`) and rebuilt
binaries (`cp` into `parity/bin/`).

## Deliberately not ported

- **hermes gateway** — private venv under `~/.hermes`; recreate by hand or
  disable `hermes-gateway.service` on other machines.
- **Claude Code, Handy, Tailscale auth** — interactive; see AGENTS.md.
