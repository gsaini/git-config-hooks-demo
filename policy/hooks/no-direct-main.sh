#!/usr/bin/env bash
# policy/hooks/no-direct-main.sh
# Fires on: pre-commit. Blocks commits made directly on protected branches.

set -u

BOLD=$'\e[1m'; DIM=$'\e[2m'; RED=$'\e[31m'; CYAN=$'\e[36m'; RST=$'\e[0m'
if [ "${FORCE_COLOR:-0}" != "1" ] && [ ! -t 2 ]; then BOLD= DIM= RED= CYAN= RST=; fi

PROTECTED='^(main|master|trunk|production|release)$'

branch="$(git symbolic-ref --short -q HEAD || true)"
[ -z "$branch" ] && exit 0  # detached HEAD (e.g. rebase) — let it pass

if [[ "$branch" =~ $PROTECTED ]]; then
    printf '\n%b✗%b %bno-direct-main%b — refusing commit on protected branch %b%s%b\n\n' \
        "$RED$BOLD" "$RST" "$BOLD" "$RST" "$BOLD" "$branch" "$RST"
    printf '  %bWork on a topic branch and open a PR instead:%b\n' "$DIM" "$RST"
    printf '    %bgit switch -c feat/your-change%b\n' "$CYAN" "$RST"
    printf '    %bgit commit …%b\n\n' "$CYAN" "$RST"
    printf '  %bNeed an exception for this repo only?%b\n' "$DIM" "$RST"
    printf '    %bgit config set hook.no-direct-main.enabled false%b\n\n' "$CYAN" "$RST"
    exit 1
fi
exit 0
