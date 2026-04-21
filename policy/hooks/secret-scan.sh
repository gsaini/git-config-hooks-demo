#!/usr/bin/env bash
# policy/hooks/secret-scan.sh
# Fires on: pre-commit (against staged content) and pre-push (against full files).
# Blocks if any tracked file contains a known-dangerous credential pattern.

set -u

BOLD=$'\e[1m'; DIM=$'\e[2m'; RED=$'\e[31m'; YEL=$'\e[33m'; CYAN=$'\e[36m'; RST=$'\e[0m'
if [ "${FORCE_COLOR:-0}" != "1" ] && [ ! -t 2 ]; then BOLD= DIM= RED= YEL= CYAN= RST=; fi

PATTERNS=(
  'AKIA[0-9A-Z]{16}'
  '-----BEGIN (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY-----'
  'ghp_[A-Za-z0-9]{36,}'
  'xox[baprs]-[A-Za-z0-9-]{10,}'
  '"type"[[:space:]]*:[[:space:]]*"service_account"'
  'sk-[A-Za-z0-9]{32,}'
)
LABELS=(
  'AWS access key ID (AKIA…)'
  'PEM-encoded private key'
  'GitHub personal access token'
  'Slack API token'
  'Google service-account credentials'
  'OpenAI-style secret key (sk-…)'
)

# Collect files to scan. Pre-commit: staged files. Pre-push: all tracked files.
files=()
if git rev-parse --verify HEAD >/dev/null 2>&1 && [ -n "${GIT_INDEX_FILE:-}" ] || git diff --cached --name-only >/dev/null 2>&1; then
    while IFS= read -r f; do
        [ -f "$f" ] && files+=("$f")
    done < <(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)
fi
if [ ${#files[@]} -eq 0 ]; then
    while IFS= read -r f; do
        [ -f "$f" ] && files+=("$f")
    done < <(git ls-files 2>/dev/null)
fi
[ ${#files[@]} -eq 0 ] && exit 0

hits=0
for f in "${files[@]}"; do
    for i in "${!PATTERNS[@]}"; do
        while IFS=: read -r lineno line; do
            [ -z "$lineno" ] && continue
            if [ $hits -eq 0 ]; then
                printf '\n%b%s%b %bsecret-scan%b %s\n\n' \
                    "$RED$BOLD" "✗" "$RST" "$BOLD" "$RST" \
                    "— credentials detected in staged content"
            fi
            hits=$((hits + 1))
            printf '  %b%s:%s%b\n' "$BOLD" "$f" "$lineno" "$RST"
            printf '    %b%s%b\n' "$DIM" "$line" "$RST"
            printf '    %b↳ %s%b\n\n' "$YEL" "${LABELS[$i]}" "$RST"
        done < <(grep -nE -- "${PATTERNS[$i]}" "$f" 2>/dev/null)
    done
done

if [ $hits -gt 0 ]; then
    printf '  %b%d finding(s). Credentials must never enter history.%b\n' "$RED$BOLD" "$hits" "$RST"
    printf '  %b• Remove the secret, rotate it, then %bgit add%b%b and retry.%b\n' "$DIM" "$CYAN" "$RST$DIM" "$DIM" "$RST"
    printf '  %b• Emergency bypass: %bgit config set hook.secret-scan.enabled false%b %b(not recommended)%b\n\n' "$DIM" "$CYAN" "$RST$DIM" "$DIM" "$RST"
    exit 1
fi
exit 0
