# Hardware portability

The repo is tuned on an ASUS laptop (AMD iGPU `65:00.0` + NVIDIA RTX 4070
`01:00.0`, MUX in dGPU mode, three monitors). Everything machine-specific is
either generated per machine or listed here.

## Generated per machine (never edit by hand)

| file | generator | when |
|---|---|---|
| `~/.config/hypr/gpu.conf` | `tools/gen-gpu-conf.sh` | install, or after any GPU change |
| `/etc/udev/rules.d/99-hypr-gpu.rules` | same script (hybrid boxes only) | same |
| `~/.config/hypr/monitors.conf` + `workspaces.conf` | `nwg-displays` (drag-arrange GUI) | after monitor changes |

`hyprland.conf` sources both and carries nothing hardware-specific itself.
The repo ships this machine's monitors.conf as a starting point; on new
hardware the fallback `monitor = , preferred, auto, 1` line brings every
screen up, then run `nwg-displays` and hit Apply.

## GPU matrix (what gen-gpu-conf.sh decides)

| topology | AQ_DRM_DEVICES | udev rule | VAAPI (`LIBVA_DRIVER_NAME`) |
|---|---|---|---|
| iGPU + NVIDIA (this laptop) | `igpu-card:nv-card` — iGPU first, it must own the allocator | yes | `radeonsi` (AMD) / `iHD` (Intel) — apps render on the iGPU, so VAAPI must match it, not the dGPU |
| NVIDIA only (e.g. a 5070 Ti desktop) | unset — single card needs no ordering | no (removed if present) | `nvidia` |
| AMD/Intel only | unset | no | `radeonsi` / `iHD` |

Two hard-won rules encoded in the script:

- On hybrids, listing NVIDIA first (or letting Hyprland pick) crashes the
  allocator; the iGPU must be the primary renderer.
- VAAPI follows the primary **renderer**, not the discrete card. Forcing
  `nvidia` on this laptop silently disabled hardware video decode
  (verified 2026-08-01: 0% NVDEC, load average 11.8 during playback).

## NVIDIA driver generations

`packages.txt` and this box use the `nvidia-580xx-open-dkms` **open** kernel
modules. The 580 branch covers Turing through Blackwell, and RTX 50-series
cards (5070 Ti included) **require** the open flavor — the proprietary modules
do not support Blackwell at all. So a 5070 Ti box installs the exact same
packages; only `gpu.conf` output differs (NVIDIA-only row above).

## Other per-machine assumptions

- Username `nethum` is baked into systemd unit paths and a few scripts.
- `asusctl` / `rog-control-center` / `supergfxctl` only apply to ASUS laptops;
  they are absent from `packages.txt` on purpose.
- Cursor: `cursor:no_hardware_cursors = 0` (forced hardware) is a measured win
  on this box; if the cursor turns invisible on other hardware set it to `2`.
