# Tailscale

Mesh VPN between this laptop and the personal agent nodes. Installed from the
official repos (`tailscale`), daemon enabled at boot.

## Current shape

- Nodes: this laptop (`nethum-cachyos`) and `hermes-container` (runs the
  hermes gateway; see apps.md services).
- MagicDNS on (`tailscale dns status`), so nodes resolve by name:
  `hermes-container` or `hermes-container.<tailnet>.ts.net`.
- Plain node config everywhere else: no exit node, no subnet routes,
  no Tailscale SSH, shields down.

## The CachyOS DNS trap (the part worth documenting)

Symptom: `tailscale status` health-checks with *"systemd-resolved and
NetworkManager are wired together incorrectly; MagicDNS will probably not
work"*, and `.ts.net` names do not resolve.

Cause: NetworkManager writes `/etc/resolv.conf` as a **plain file** pointing at
the resolved stub (`127.0.0.53`). systemd-resolved then reports
`resolv.conf mode: foreign`, and tailscaled cannot program split DNS for
`ts.net`.

Fix (same nameserver either way, so nothing else changes):

```sh
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
sudo systemctl restart tailscaled
resolvectl status | grep 'resolv.conf mode'   # must say: stub
```

`install.sh` applies this automatically when resolved is active and
resolv.conf is not the stub symlink. Verified 2026-08-09: FQDN and short-name
lookups both answer over `tailscale0` in ~1 ms.

## Fresh-machine setup

```sh
sudo pacman -S tailscale          # in packages.txt
sudo systemctl enable --now tailscaled
sudo tailscale up                 # prints the browser auth link
```

## Everyday commands

```sh
tailscale status                  # nodes + health
tailscale ping hermes-container   # path check (direct vs DERP relay)
tailscale dns status              # MagicDNS state
sudo tailscale set --accept-dns=false   # opt out of tailnet DNS
```
