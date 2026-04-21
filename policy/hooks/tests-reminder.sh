#!/usr/bin/env bash
# policy/hooks/tests-reminder.sh
# Fires on: pre-push. Non-blocking nudge — prints a reminder, always exits 0.

set -u

BOLD=$'\e[1m'; DIM=$'\e[2m'; YEL=$'\e[33m'; CYAN=$'\e[36m'; RST=$'\e[0m'
if [ "${FORCE_COLOR:-0}" != "1" ] && [ ! -t 2 ]; then BOLD= DIM= YEL= CYAN= RST=; fi

printf '\n%b⚠%b %btests-reminder%b — about to push. A quick checklist:\n' \
    "$YEL$BOLD" "$RST" "$BOLD" "$RST"
printf '    %b• did you run the test suite?%b\n' "$DIM" "$RST"
printf '    %b• did you update docs/CHANGELOG?%b\n' "$DIM" "$RST"
printf '    %b• is the PR description ready?%b\n\n' "$DIM" "$RST"
printf '  %bThis hook is informational — push proceeds.%b\n\n' "$DIM" "$RST"
exit 0
