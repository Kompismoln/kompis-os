#!/usr/bin/env bash
# tools/bin/apply.sh

set -euo pipefail

km_root="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
# shellcheck source=../libexec/run-with.bash
. "$km_root/libexec/run-with.bash"

declare -x target=${1:?target required}
declare -x \
    TARGET_ADDRESS=${TARGET_ADDRESS:-$(find-route.sh "$target")} \
    BUILD_HOST_ADDRESS=${BUILD_HOST_ADDRESS:-$(find-route.sh "$BUILD_HOST" 5000)}

apply() {
    log info "use $BUILD_HOST to build $target (at $TARGET_ADDRESS)"

    if [[ -n $BUILD_WORKING_TREE ]]; then
        with source

        # export for build.sh
        export SOURCE=$source

        log important "export SOURCE=$source"
        if [[ $BUILD_HOST != localhost ]]; then
            "$km_root/bin/as.sh" nix-push nix copy --to "ssh://nix-push@$BUILD_HOST_ADDRESS" "$SOURCE"
        fi
    fi

    with build
    log important "build=$build"

    if [[ $BUILD_HOST == localhost && $TARGET_ADDRESS != localhost ]]; then
        "$km_root/bin/as.sh" nix-push nix copy --to "ssh://nix-push@$TARGET_ADDRESS" "$build"
    fi

    if [[ $BUILD_HOST != localhost && "$BUILD_HOST" != "$target" ]]; then
        "$km_root/bin/as.sh" nix-build ssh "nix-build@$TARGET_ADDRESS" \
            pull \
            "$build" \
            "http://$BUILD_HOST_ADDRESS:5000"
    fi

    log important "switching $target to $build"
    "$km_root/bin/as.sh" nix-switch ssh "nix-switch@$TARGET_ADDRESS" "$build"
}

declare -g build source
build() {
    "$km_root/bin/build.sh" "$target"
}

source() {
    nix eval --raw .#src
}
apply
