#!/usr/bin/env bash
# demo/lib.sh — color palette + scene/run/pause helpers.

if [ -t 1 ]; then
    C_RESET=$'\e[0m'; C_BOLD=$'\e[1m'; C_DIM=$'\e[2m'; C_ITAL=$'\e[3m'
    C_RED=$'\e[31m'; C_GRN=$'\e[32m'; C_YEL=$'\e[33m'
    C_BLU=$'\e[34m'; C_MAG=$'\e[35m'; C_CYN=$'\e[36m'; C_GRY=$'\e[90m'
else
    C_RESET= C_BOLD= C_DIM= C_ITAL= C_RED= C_GRN= C_YEL= C_BLU= C_MAG= C_CYN= C_GRY=
fi

BAR='━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
DASH='────────────────────────────────────────────────────────────────'

banner() {
    clear 2>/dev/null || true
    printf '%b%s%b\n' "$C_MAG" "$BAR" "$C_RESET"
    printf '  %bGit 2.54%b  ·  %bConfig-Based Hooks%b  ·  %bPolicy-as-Config Demo%b\n' \
        "$C_BOLD$C_CYN" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_BOLD$C_MAG" "$C_RESET"
    printf '%b%s%b\n' "$C_MAG" "$BAR" "$C_RESET"
    printf '  %bShip one policy bundle. Enforce it across every repo on the machine.%b\n' "$C_DIM$C_ITAL" "$C_RESET"
    printf '  %bNo copy-paste. No core.hooksPath all-or-nothing. Per-repo opt-outs.%b\n' "$C_DIM$C_ITAL" "$C_RESET"
    printf '%b%s%b\n\n' "$C_MAG" "$BAR" "$C_RESET"
    printf '  %s\n' "$(git --version)"
    printf '  %bmode:%b %s   %bspeed:%b %ss/scene   %bpause:%b %s\n\n' \
        "$C_DIM" "$C_RESET" "GIT_CONFIG_GLOBAL sandboxed" \
        "$C_DIM" "$C_RESET" "${SPEED:-0.6}" \
        "$C_DIM" "$C_RESET" "$([ "${PAUSE:-0}" = 1 ] && echo on || echo off)"
}

scene() {
    local num="$1" title="$2"
    printf '\n%b%s%b\n' "$C_MAG" "$BAR" "$C_RESET"
    printf '%b SCENE %s%b  %b%s%b\n' "$C_BOLD$C_MAG" "$num" "$C_RESET" "$C_BOLD" "$title" "$C_RESET"
    printf '%b%s%b\n' "$C_MAG" "$BAR" "$C_RESET"
}

narrate() {
    printf '  %b▸ %s%b\n' "$C_CYN$C_ITAL" "$*" "$C_RESET"
}

beat()   { printf '\n'; sleep "${SPEED:-0.6}"; }

ok()     { printf '  %b✓%b %s\n' "$C_GRN$C_BOLD" "$C_RESET" "$*"; }
info()   { printf '  %bℹ%b %s\n' "$C_CYN$C_BOLD" "$C_RESET" "$*"; }
warn()   { printf '  %b!%b %s\n' "$C_YEL$C_BOLD" "$C_RESET" "$*"; }

hr()     { printf '  %b%s%b\n' "$C_GRY" "$DASH" "$C_RESET"; }

# Print a command in prompt-style, then execute it. Output is indented.
run() {
    printf '\n  %b$ %s%b\n' "$C_GRN$C_BOLD" "$*" "$C_RESET"
    local out rc
    out=$(eval "$@" 2>&1) ; rc=$?
    if [ -n "$out" ]; then
        printf '%s\n' "$out" | sed "s/^/    /"
    fi
    return $rc
}

# Expect-success: fail the demo loudly if this command does not exit 0.
run_ok() {
    run "$@"
    local rc=$?
    if [ $rc -ne 0 ]; then
        printf '\n  %bDEMO ABORTED:%b expected success, got exit %d\n' "$C_RED$C_BOLD" "$C_RESET" "$rc"
        exit 1
    fi
}

# Expect-failure: we intentionally want this command to fail (hook blocked it).
run_fail() {
    run "$@"
    local rc=$?
    if [ $rc -eq 0 ]; then
        printf '\n  %bDEMO ABORTED:%b expected failure, got exit 0\n' "$C_RED$C_BOLD" "$C_RESET"
        exit 1
    fi
    printf '  %b→ command exited %d — hook did its job.%b\n' "$C_GRN" "$rc" "$C_RESET"
}

pause() {
    if [ "${PAUSE:-0}" = "1" ]; then
        printf '\n  %b(press Enter to continue)%b ' "$C_DIM" "$C_RESET"
        read -r _ || true
    else
        sleep "${SPEED:-0.6}"
    fi
}
