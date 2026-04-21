#!/usr/bin/env bash
# demo/reset.sh — wipe sandbox so the demo can be rerun from scratch.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
rm -rf "$HERE/sandbox"
printf 'sandbox wiped: %s/sandbox\n' "$HERE"
