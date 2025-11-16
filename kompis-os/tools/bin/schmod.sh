#!/usr/bin/env bash
path=${1:-"."}
mode=${2:-"640"}
dirmode=${3:-$(case $mode in
    644) echo 755 ;;
    640) echo 750 ;;
    600) echo 700 ;;
    *) exit 1 ;;
    esac)}
find "$path" -type f -exec chmod "$mode" {} + && find "$path" -type d -exec chmod "$dirmode" {} +
