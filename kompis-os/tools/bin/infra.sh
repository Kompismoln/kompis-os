#!/usr/bin/env bash
# infra.sh

set -uo pipefail

declare -x session class entity action key

km_root="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
# shellcheck source=../libexec/run-with.bash
. "$km_root/libexec/run-with.bash"

for-all-identities() {
    if [[ $1 == "updatekeys" ]]; then
        org-toml.sh "sops-yaml" "*" >.sops.yaml
        sops updatekeys -y enc/*
        return
    fi
    org-toml.sh "ops" "[\"$1\"]" | while IFS=" " read -r id op; do
        [[ "$id" != "root-"* ]] || continue
        IFS=':' read -r prefix key <<<"$op"
        "$km_root/bin/id-entities.sh" "$id" "$prefix" "$key"
    done
}

for-all-identities "$@"
