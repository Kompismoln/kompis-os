#!/usr/bin/env bash
ip -6 -j addr show scope global | jq -r '
  .[].addr_info[]
  | select(
      .local != null
      and (.local | test("^fd") | not)
      and (.flags // [] | index("temporary") | not)
      and .prefixlen == 64
    )
  | .local
'
