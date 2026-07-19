#!/usr/bin/env bash
p() {
    local pid=$1 args mem mem_mb etime
    args=$(ps -p "$pid" -o args= | tr -d '\n')
    mem=$(ps -p "$pid" -o rss= | tr -d ' ')
    mem_mb=$(echo "scale=1; $mem/1024" | bc)
    etime=$(ps -p "$pid" -o etime= | tr -d ' ')

    echo "cmd: $args"
    echo "mem: ${mem_mb}MB"
    echo "uptime: $etime"
}

p "$1"
