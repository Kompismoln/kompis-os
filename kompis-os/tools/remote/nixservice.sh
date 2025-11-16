#!/usr/bin/env bash
# tools/remote/nixservice.sh
set -euo pipefail

main() {
    case $1 in
    build)
        host=${2:?"host required"}
        refresh=${3:-}
        ;;
    pull)
        closure=${2:?"closure required"}
        build_host=${3:-$BUILD_HOST}
        ;;
    switch)
        generation=${2:-}
        ;;
    *) exit 1 ;;
    esac
    "$1" "$@"
}

build() {
    if [[ -n $refresh ]]; then
        rm -rf "$HOME/.cache/nix/"*
    fi
    nix build "$REPO#nixosConfigurations.$host.config.system.build.toplevel" \
        --print-out-paths --no-link
}

pull() {
    nix copy --from "$build_host" "$closure"
}

switch() {
    if [[ $generation =~ ^/nix/store/ ]]; then
        nix-env -p /nix/var/nix/profiles/system --set "$generation"
    elif [[ -n "$generation" ]]; then
        nix-env -p /nix/var/nix/profiles/system --switch-generation "$generation"
    fi

    nix-env -p /nix/var/nix/profiles/system --list-generations

    if [[ -n "$generation" ]]; then
        /nix/var/nix/profiles/system/bin/switch-to-configuration switch
    fi
}

main "$@"
