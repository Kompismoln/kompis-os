#!/usr/bin/env bash
# kompis-os/tools/bin/build.sh

set -euo pipefail

km_root="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
# shellcheck source=../libexec/run-with.bash
. "$km_root/libexec/run-with.bash"

BUILD_HOST_ADDRESS=${BUILD_HOST_ADDRESS:-$(find-route.sh "$BUILD_HOST")}

build() {
    local target=$1
    if [[ $BUILD_HOST == localhost ]]; then
        "$km_root/remote/nixservice.sh" build "$target" "${SOURCE:-}"
    else
        # Build the package and store the result directly on the remote machine
        "$km_root/bin/as.sh" nix-build ssh -A "nix-build@$BUILD_HOST_ADDRESS" build "$target" "${SOURCE:-}"
    fi
}

build "$@"
