#!/usr/bin/env bash
# policy/hooks/conventional-commit.sh
# Fires on: commit-msg. Enforces Conventional Commits 1.0 subject-line format.

set -u

BOLD=$'\e[1m'; DIM=$'\e[2m'; RED=$'\e[31m'; GREEN=$'\e[32m'; CYAN=$'\e[36m'; RST=$'\e[0m'
if [ "${FORCE_COLOR:-0}" != "1" ] && [ ! -t 2 ]; then BOLD= DIM= RED= GREEN= CYAN= RST=; fi

MSG_FILE="$1"
# First non-comment, non-empty line is the subject
subject="$(grep -v -E '^[[:space:]]*#' "$MSG_FILE" | awk 'NF' | head -n1)"

TYPES='feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert'
REGEX="^(${TYPES})(\\([^)]+\\))?!?: .{1,72}$"

if [[ "$subject" =~ $REGEX ]]; then
    exit 0
fi

printf '\n%b✗%b %bconventional-commit%b — subject does not match Conventional Commits\n\n' \
    "$RED$BOLD" "$RST" "$BOLD" "$RST"
printf '  %bGot:%b      %b%s%b\n' "$DIM" "$RST" "$RED" "${subject:-<empty>}" "$RST"
printf '  %bExpected:%b %b<type>(<optional-scope>)!?: <subject ≤72 chars>%b\n\n' "$DIM" "$RST" "$BOLD" "$RST"
printf '  %bAllowed types:%b %s\n\n' "$DIM" "$RST" "$(printf '%s' "$TYPES" | tr '|' ' ')"
printf '  %bExamples:%b\n' "$DIM" "$RST"
printf '    %bfeat(payments): add Stripe webhook receiver%b\n' "$GREEN" "$RST"
printf '    %bfix(api): handle null response from /users%b\n' "$GREEN" "$RST"
printf '    %bdocs: clarify retry behavior%b\n' "$GREEN" "$RST"
printf '    %brefactor(auth)!: rename Session → AuthSession (BREAKING)%b\n\n' "$GREEN" "$RST"
printf '  %bAmend and retry:%b %bgit commit --amend%b\n\n' "$DIM" "$RST" "$CYAN" "$RST"
exit 1
