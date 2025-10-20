#!/usr/bin/env bash

set -euo pipefail

km_root="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"

switch() {
    target_address=$(find-route.sh "$1")
    "$km_root/bin/as.sh" "nix-switch" "ssh" "nix-switch@$target_address" "${2:-}"
}

switch "$@"
