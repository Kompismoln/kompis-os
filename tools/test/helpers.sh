#!/usr/bin/env bash

set -euo pipefail

setup-testenv() {
    local here root
    export TESTROOT=$BATS_TEST_TMPDIR/testroot

    here="$(cd "$(dirname "$BATS_TEST_FILENAME")" && pwd)"
    root=$TESTROOT
    mkdir -p "$root"
    cp -a "$here/../." "$root"
    mv "$root/test/org.toml" "$root/org.toml"
    mkdir "$root/enc" "$root/keys" "$root/artifacts"

    tree "$root"

    cd "$root" || exit 1

    export PATH="$root/bin:$root/test/bin:$PATH"
}

declare -g output status
expect() {
    local lines
    lines="$(echo "$output" | wc -l)"
    local expected_lines=${3:-$lines}

    local lastline
    local expected_status=$1
    local expected_lastline=${2:-}

    lastline=$(echo "$output" | tail -n 1 | strip-color)

    [[ 
        "$lastline" == *"$expected_lastline"* &&
        "$status" == "$expected_status" &&
        "$lines" == "$expected_lines" ]] &&
        return 0

    cat >&2 <<EOF

=== '$BATS_TEST_NAME' ===
$output

in '$BATS_TEST_NAME'
run '$BATS_RUN_COMMAND' failed:
expected: $expected_lastline ($expected_status) (lines: $expected_lines)
got:      $lastline ($status) (lines: $lines)

EOF
    return 1
}

mock-host() {
    local hostroot=$BATS_TEST_TMPDIR/host-$1.local
    mkdir -p "$hostroot/keys"

    echo "$test_age_key_1" >"$hostroot/keys/host-testhost"
    echo "$test_ssh_key_1" >"$hostroot/keys/ssh-key"
    chmod 600 "$hostroot/keys/ssh-key"
    echo "$test_luks_key_1" >"$hostroot/keys/luks-key"
}

strip-color() {
    sed 's/\x1B\[[0-9;]*[JKmsu]//g'
}

test_age_key_1=AGE-SECRET-KEY-1L0EJY3FLSYHDE46Y80F0KLUKUWP6V3J340UR7G2GWNFGXJQ0P6ZQ6X37TN

test_ssh_key_1="-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACDEE3csx1IE4hhJQOzYQh7xZ8iZY6wj1C1xYp2DjxjmOAAAAKDYIpSm2CKU
pgAAAAtzc2gtZWQyNTUxOQAAACDEE3csx1IE4hhJQOzYQh7xZ8iZY6wj1C1xYp2DjxjmOA
AAAEA4YkpxaWCNi2sH27/j3HB+cMO81OHPrAzAeD15B1N9BcQTdyzHUgTiGElA7NhCHvFn
yJljrCPULXFinYOPGOY4AAAAF3Rlc3R1c2VyQHRlc3Rob3N0LmxvY2FsAQIDBAUG
-----END OPENSSH PRIVATE KEY-----"

test_luks_key_1="luks1-Atzc2gtZWQyNTUxO"
