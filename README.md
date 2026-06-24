# linux-setup

My CachyOS (Arch-based) desktop setup — a Hyprland + Ambxst Wayland rice, shell,
terminals, and the small scripts that hold it together. Managed with
[GNU Stow](https://www.gnu.org/software/stow/): every file under `home/` mirrors
its real location under `$HOME` and gets symlinked there.

> Tuned for one machine: an ASUS laptop with a hybrid **AMD iGPU + NVIDIA RTX
> 4070**, multi-monitor, username `nethum`. The Hyprland and Ambxst configs hard-code
> hardware details — read before applying to different hardware.

## Screenshots

Hyprland tiling a Firefox window alongside a clock + `cmatrix` column:

![Hyprland window manager](images/hyprland.png)

The Ambxst bar and control center — quick toggles, media, calendar, notifications:

![Ambxst bar](images/ambxst-bar.png)

## Layout

```
home/                       # stow package → symlinked into ~
  .config/
    hypr/       hyprland.conf   # monitors + the multi-GPU fix (see below)
    ambxst/     binds.json + per-feature config (bar, dock, theme, …)
    fish/       config.fish + functions
    kitty/  ghostty/  alacritty/      # terminals
    btop/  cava/  hyprshell/        # TUIs / shell extras
    autostart/  solaar.desktop        # Logitech (MX Master) daemon
  .peaclock/    config
  .local/bin/   lidawake  keybinds  pomodoro
etc/
  udev/rules.d/99-hypr-gpu.rules      # stable DRM symlinks Hyprland needs
install.sh                            # stow + udev rule + reload
```

## Install

```sh
git clone https://github.com/<you>/linux-setup ~/linux-setup
cd ~/linux-setup
./install.sh
```

`install.sh` stows the dotfiles, installs the udev rule, and prints the remaining
manual steps (packages, Ambxst reload, tool-ring).

## The multi-GPU fix (the interesting part)

On a hybrid AMD+NVIDIA laptop, Hyprland's allocator must open the **AMD** card
first or it crashes on launch with *"no allocator available"*. The catch:
Aquamarine splits `AQ_DRM_DEVICES` on `:`, and PCI by-path names contain colons,
so they get shredded. The fix is colon-free, rename-stable DRM symlinks created
by `etc/udev/rules.d/99-hypr-gpu.rules`, then:

```
env = AQ_DRM_DEVICES,/dev/dri/amd-card:/dev/dri/nv-card
```

Full reasoning is commented inline in `home/.config/hypr/hyprland.conf`.

## Companion repos

- **[tool-ring](https://github.com/<you>/tool-ring)** — the radial launcher ring
  bound to `Super+G`.

## Scripts

| script     | what it does                                           |
|------------|--------------------------------------------------------|
| `lidawake` | toggle "close lid, stay awake" via a logind inhibitor  |
| `keybinds` | pretty-printed Hyprland keybind cheat sheet            |
| `pomodoro` | zero-dependency peaclock-style Pomodoro TUI            |
