# Installed software inventory

Snapshot of everything on the box as of 2026-08-09. The machine-readable ground
truth is [`packages-explicit.txt`](packages-explicit.txt) (`pacman -Qqe`); this
file is the curated map of what matters and where it came from.

## Desktop stack

| component | package | role |
|---|---|---|
| Hyprland | `hyprland` | Wayland compositor (multi-GPU fix in `hypr/hyprland.conf`) |
| Ambxst | `quickshell` + axctl | bar, dock, notch, control center, lockscreen |
| nwg-displays | `nwg-displays` | drag-arrange monitor GUI; owns `hypr/monitors.conf` + `workspaces.conf` |
| Fuzzel | `fuzzel` | launcher |
| hyprshell | (local, `~/.local/bin/hyprshell`) | window switcher |
| SDDM/Plasma bits | `plasma-*` | login manager + KDE apps (Dolphin, Kate, Okular, Gwenview, Spectacle) |

## Terminals and shell

- `kitty` (primary, JetBrainsMono Nerd Font, blur), `ghostty`, `alacritty`
- `fish` via `cachyos-fish-config`; custom `config.fish` adds the `opencode`
  model/effort wrapper function and gh-token export
- `tmux`, `btop`, `cava`, `peaclock`, `fastfetch`, `micro`, `neovim`

## Browsers and daily apps

- Firefox (`firefox`), Chromium (`chromium`)
- Obsidian (`obsidian`), LibreOffice (`libreoffice-fresh`)
- Discord (`discord`), Spotify (`spotify`), Bitwarden (`bitwarden`)
- Steam (`steam`) + Heroic (`heroic-games-launcher-bin`) + MangoHud
- Haruna (video), EasyEffects, Solaar (MX Master daemon, autostart)
- Proton VPN (`proton-vpn-gtk-app`), Tailscale, KDE Connect

## AI / agent tooling

- **Claude Desktop** (`claude-desktop-bin`) and **Claude.AppImage** (`~/Applications`)
- **Claude Code** CLI (npm global)
- **OpenCode** (`opencode` pacman + `~/.local/bin/opencode`)
- **Ollama** (`ollama-cuda`)
- **Handy** speech-to-text (`~/Applications/Handy.AppImage`, autostart) — see [voice.md](voice.md)
- **handy-voice-activation** wake-word daemon — see [voice.md](voice.md)
- **agentdash** usage indicator — see [usage-indicator.md](usage-indicator.md)
- axi toolchain in `~/.local/bin` (local npm installs, symlinked):
  `gh-axi`, `sqlite-axi`, `npm-axi`, `chrome-devtools-axi`, `lavish-axi`,
  `codex-axi`, plus `herdr`, `worker-health`, `seer`, `hermes`

## AppImages (`~/Applications`)

- `Claude.AppImage` — Claude desktop client
- `Handy.AppImage` — push-to-talk / toggle speech-to-text
- `Paper.AppImage`

## Dev toolchain

- `git` + `github-cli` + `lazygit`, `docker` + `docker-compose`
- `nodejs`/`npm`, `python` + `uv` + `pipx`, JDK 21/25, `cmake`/`ninja`, `lldb`/`valgrind`
- HDL: `iverilog`, `yosys`, `gtkwave`
- `visual-studio-code-bin`, `ripgrep`, `meld`, `tectonic` (LaTeX), `tesseract` (OCR)

## Hardware / ASUS specifics

- NVIDIA 580xx open-dkms + `nvidia-prime`, AMD `vulkan-radeon` + `xf86-video-amdgpu`
- `asusctl`, `rog-control-center`, `supergfxctl`, `switcheroo-control`
- `power-profiles-daemon`, `brightnessctl`, `solaar`

## User services (`~/.config/systemd/user`)

| unit | what |
|---|---|
| `agentdash.service` | usage-indicator poller daemon |
| `hva.service` | wake-word voice activation daemon |
| `worker-health.service` + `.timer` | agent-worker liveness checks every 5 min |
| `hermes-gateway.service` | personal agent stack |

## Companion repos

- [tool-ring](https://github.com/nethum529/tool-ring) — radial launcher (Super+G)
- [handy-voice-activation](https://github.com/nethum529/handy-voice-activation) — wake word
- `tools/agentdash` — vendored in this repo (no upstream)
