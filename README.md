# tailscaled for MIPS little-endian routers (TOTOLINK T6 V3)

Unofficial, size-reduced build of [Tailscale](https://github.com/tailscale/tailscale)
1.104.1 for small `mipsle` softfloat routers, built for a TOTOLINK T6 V3
(Realtek RTL8197F, Linux 3.10, ~109 MB RAM, 8 MB flash, no TUN driver).

The release asset `tailscaled-mipsle` is a **single binary** that works as both
the daemon and the CLI: run it as `tailscaled`, or call it through a symlink
named `tailscale`.

| | |
|---|---|
| Size | 18.5 MB (official `tailscaled` + `tailscale` for mipsle: ~76 MB) |
| Source | Tailscale `v1.104.1`, unmodified |
| Toolchain | Go 1.27.2, `GOOS=linux GOARCH=mipsle GOMIPS=softfloat CGO_ENABLED=0` |
| Flags | `-trimpath -ldflags "-s -w"`, tags in [`build-tags.txt`](build-tags.txt) + `ts_include_cli` |
| Features kept | netstack (userspace networking), subnet routes, NAT traversal, port mapping, embedded CA roots, health, ipnbus |

Rebuild it with [`build-tailscale.sh`](build-tailscale.sh) (downloads Go and the
Tailscale source into `~/.cache`).

## Verify

```sh
sha256sum -c SHA256SUMS
```

`MD5SUMS` is included for devices whose busybox has only `md5sum`.

## Running on the T6

```sh
TS_FORCE_NOISE_443=true GOGC=50 GOMEMLIMIT=35MiB ./tailscaled \
  --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state \
  --socket=/var/run/tailscale/tailscaled.sock --port=41641 &
ln -sf tailscaled tailscale
./tailscale --socket=/var/run/tailscale/tailscaled.sock up --advertise-routes=192.168.1.0/24
```

- `--tun=userspace-networking`: the kernel has no TUN driver.
- `TS_FORCE_NOISE_443=true`: on some networks port 80 to the control plane is
  intercepted and the login hangs at `creating new noise client`.
- The clock must be correct before `up` (TLS); these routers boot in 2021.

## License

Tailscale is distributed under the BSD 3-Clause License, see [`LICENSE`](LICENSE).
This build is not affiliated with or endorsed by Tailscale Inc.
