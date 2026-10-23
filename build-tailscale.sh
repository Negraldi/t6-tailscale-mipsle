#!/usr/bin/env bash
# Rebuild the minimal combined tailscaled+CLI binary for the T6 (mipsle softfloat).
# Downloads Go and the Tailscale source into a work dir; installs nothing system-wide.
#
# Usage: ./build-tailscale.sh [tailscale_version] [go_version]
set -euo pipefail

TS_VERSION="${1:-1.104.1}"
GO_VERSION="${2:-1.27.2}"
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="${WORK:-$HOME/.cache/totolink-t6-build}"

mkdir -p "$WORK" "$HERE/bin"
cd "$WORK"

if [ ! -x "go/bin/go" ]; then
	curl -sSfL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" | tar -xz
fi
if [ ! -d "tailscale-${TS_VERSION}" ]; then
	curl -sSfL "https://github.com/tailscale/tailscale/archive/refs/tags/v${TS_VERSION}.tar.gz" | tar -xz
fi

export PATH="$WORK/go/bin:$PATH" GOPATH="$WORK/gopath" GOCACHE="$WORK/gocache" GOTOOLCHAIN=local
cd "tailscale-${TS_VERSION}"

# Keep only what a userspace subnet router needs. ipnbus is required for
# `tailscale up` to print the login URL.
TAGS="$(go run ./cmd/featuretags --min \
	--add=netstack,advertiseroutes,nattraversal,bakedroots,portmapper,udptransport,health,ipnbus | tail -1)"
echo "$TAGS" > "$HERE/build-tags.txt"

GOOS=linux GOARCH=mipsle GOMIPS=softfloat CGO_ENABLED=0 \
	go build -o "$HERE/bin/tailscaled-mipsle" -tags "$TAGS,ts_include_cli" \
	-trimpath -ldflags "-s -w" ./cmd/tailscaled

cd "$HERE/bin" && sha256sum tailscaled-mipsle > SHA256SUMS
ls -la "$HERE/bin"
