#!/usr/bin/env bash
# demo/run.sh — Git 2.54 config-based hooks, eight-scene narrated demo.
#
# Knobs:
#   PAUSE=1   pause for Enter between scenes (otherwise auto-pace)
#   SPEED=N   seconds between beats/scenes when auto-pacing (default 0.6)
#
# Sandboxing:
#   Rewrites GIT_CONFIG_GLOBAL and GIT_CONFIG_SYSTEM at process scope, so
#   your real ~/.gitconfig and /etc/gitconfig are NEVER touched.

set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY="$HERE/policy"
SANDBOX="$HERE/sandbox"
FAKE_HOME="$SANDBOX/fake-home"
PAY="$SANDBOX/payments-service"
ANA="$SANDBOX/analytics-api"

# shellcheck source=./lib.sh
source "$HERE/lib.sh"

# ---- environment isolation --------------------------------------------------
export GIT_CONFIG_GLOBAL="$FAKE_HOME/.gitconfig"
export GIT_CONFIG_SYSTEM=/dev/null
export FORCE_COLOR=1
unset GIT_DIR GIT_WORK_TREE

# ============================================================================
# SCENE 1 — Meet the Policy Bundle
# ============================================================================
s1_meet_the_bundle() {
    scene 1 "Meet the Policy Bundle"
    narrate "Four hook scripts and one config fragment. That is the whole product."
    narrate "Ship this to every dev machine — every repo inherits the policy."
    beat

    run "ls -1 $POLICY/hooks/"
    beat
    run "cat $POLICY/policy.gitconfig.tmpl"
    beat

    info "The '__POLICY_ROOT__' placeholder gets rendered to an absolute path at install time."
    info "In real life the bundle lives in a shared repo like org-policy.git."
    pause
}

# ============================================================================
# SCENE 2 — Install the bundle into a sandboxed global config
# ============================================================================
s2_install_bundle() {
    scene 2 "Install the bundle (sandboxed \$GIT_CONFIG_GLOBAL)"
    narrate "We render policy.gitconfig with real paths, and include it from a fake \$HOME/.gitconfig."
    narrate "Exactly how you'd roll it out org-wide — but scoped to this demo only."
    beat

    mkdir -p "$FAKE_HOME"
    sed "s|__POLICY_ROOT__|$POLICY|g" "$POLICY/policy.gitconfig.tmpl" > "$FAKE_HOME/policy.gitconfig"

    cat > "$FAKE_HOME/.gitconfig" <<EOF
[user]
	name  = Demo User
	email = demo@example.com
[init]
	defaultBranch = main
[include]
	path = $FAKE_HOME/policy.gitconfig
EOF

    run "cat $FAKE_HOME/.gitconfig"
    beat
    info "That '[include] path = …' is the only line that needs to land in a real ~/.gitconfig."
    pause
}

# ============================================================================
# SCENE 3 — Spin up two fresh repos; zero per-repo setup
# ============================================================================
s3_two_repos() {
    scene 3 "Two fresh repos — zero per-repo hook setup"
    narrate "Neither repo has a .git/hooks/ directory of its own."
    narrate "Yet the full policy is active the moment they're initialized."
    beat

    rm -rf "$PAY" "$ANA"
    run_ok "git init -q '$PAY' && git init -q '$ANA'"
    beat

    run "ls -la '$PAY/.git/hooks' | head -5"
    info "That's the default stock hooks dir — all our hooks live in config, not on disk."
    beat

    run "cd '$PAY' && git hook list --show-scope pre-commit"
    run "cd '$PAY' && git hook list --show-scope commit-msg"
    run "cd '$PAY' && git hook list --show-scope pre-push"
    beat
    ok "Every hook shown as scope=global — inherited from the bundle, no local config."
    pause
}

# ============================================================================
# SCENE 4 — Secret scanner blocks a leaked AWS key
# ============================================================================
s4_secret_caught() {
    scene 4 "Catch a leaked credential (and everything else at once)"
    narrate "An engineer commits a config file containing an AWS key AND an RSA private key."
    narrate "Two pre-commit hooks will fire — secret-scan AND no-direct-main — and git runs"
    narrate "them BOTH so you see every policy violation, not one-at-a-time."
    beat

    cat > "$PAY/config.env" <<'EOF'
# payments-service — production config
DATABASE_URL=postgres://payments:hunter2@db.internal:5432/pay
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAwY…[truncated for demo]…
-----END RSA PRIVATE KEY-----"
EOF

    run "cd '$PAY' && git add config.env"
    run_fail "cd '$PAY' && git commit -m 'feat(payments): wire up prod AWS creds'"
    beat
    ok "Credentials never entered git history. Log is still empty:"
    run "cd '$PAY' && git log --oneline 2>&1 || true"
    pause
}

# ============================================================================
# SCENE 5 — Fix the leak, see the branch guard in isolation
# ============================================================================
s5_fix_leak_and_branch_guard() {
    scene 5 "Fix the leak — branch guard in isolation"
    narrate "Scrub the secret. Retry. Now only the branch guard speaks up — no false noise."
    beat

    cat > "$PAY/config.env" <<'EOF'
# payments-service — production config (env-driven, no secrets in repo)
DATABASE_URL=postgres://payments:${DB_PASSWORD}@db.internal:5432/pay
AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
EOF
    run_ok "cd '$PAY' && git add config.env"
    run_fail "cd '$PAY' && git commit -m 'feat(payments): add prod config skeleton'"
    ok "secret-scan stayed quiet — no findings. no-direct-main did its job."
    pause
}

# ============================================================================
# SCENE 6 — Topic branch; message guard in isolation; then success
# ============================================================================
s6_msg_guard_and_success() {
    scene 6 "Topic branch — message guard in isolation, then clean commit"
    narrate "Switch to a feature branch. The branch guard stops objecting."
    narrate "A sloppy commit message is now the ONLY thing left to catch."
    beat

    run_ok "cd '$PAY' && git switch -c feat/prod-config"
    beat
    run_fail "cd '$PAY' && git commit -m 'wip: stuff'"
    ok "conventional-commit caught the bad subject. Try again with a proper one:"
    beat
    run_ok "cd '$PAY' && git commit -m 'feat(payments): add prod config skeleton'"
    beat
    run "cd '$PAY' && git log --oneline --decorate"
    ok "All three pre-commit hooks + commit-msg ran silently on the successful commit."
    pause
}

# ============================================================================
# SCENE 7 — Per-repo opt-out with hook.<name>.enabled = false
# ============================================================================
s7_opt_out() {
    scene 7 "Per-repo opt-out (one line)"
    narrate "analytics-api legitimately commits on main (it's a docs/data repo)."
    narrate "We opt it out of ONE hook — no fork, no wrapper script, no core.hooksPath rewrite."
    beat

    run "cd '$ANA' && git hook list --show-scope pre-commit"
    beat
    run_ok "cd '$ANA' && git config set hook.no-direct-main.enabled false"
    beat
    run "cd '$ANA' && git hook list --show-scope pre-commit"
    info "Notice the 'disabled' badge — config is preserved, the hook just skips."
    beat

    echo "# analytics-api" > "$ANA/README.md"
    run_ok "cd '$ANA' && git add README.md"
    run_ok "cd '$ANA' && git commit -m 'docs: initial README'"
    ok "Commit on main succeeded here; payments-service is still fully protected."
    pause
}

# ============================================================================
# SCENE 8 — Scope composition + multi-event
# ============================================================================
s8_multiscope() {
    scene 8 "Scopes compose. Events compose."
    narrate "Global policy + repo-local extras, layered. And one command can fire on many events."
    beat

    info "A) Layer a LOCAL hook on top of the global bundle (payments-specific PCI check):"
    cat > "$PAY/.pci-check.sh" <<'PCI'
#!/usr/bin/env bash
# Pretend this scans for PAN/CVV patterns. For the demo it just prints a line.
printf '\e[1;36m  ℹ pci-check\e[0m — (payments-local) no cardholder data in staged diff.\n'
exit 0
PCI
    chmod +x "$PAY/.pci-check.sh"
    run_ok "cd '$PAY' && git config set hook.pci-check.command '$PAY/.pci-check.sh'"
    run_ok "cd '$PAY' && git config set --append hook.pci-check.event pre-commit"
    run "cd '$PAY' && git hook list --show-scope pre-commit"
    info "Four hooks firing now: three from the global bundle + one local. Impossible with core.hooksPath."
    beat

    info "B) ONE hook, MULTIPLE events — secret-scan is already wired to pre-commit AND pre-push:"
    run "cd '$PAY' && git config get --all hook.secret-scan.event"
    beat
    info "Trigger the pre-push chain manually (no remote required):"
    run "cd '$PAY' && git hook run pre-push -- origin /dev/null"
    ok "tests-reminder nudged us, and secret-scan would have re-scanned for leaks before hitting the network."
    pause
}

# ============================================================================
# SCENE 9 — Policy coverage report
# ============================================================================
s9_report() {
    scene 9 "Policy Bundle — active coverage"
    narrate "The final tally across both sandboxed repos."
    beat

    printf '\n  %b%s%b\n' "$C_BOLD$C_CYN" "payments-service" "$C_RESET"
    for ev in pre-commit commit-msg pre-push; do
        printf '    %b%s%b\n' "$C_DIM" "$ev" "$C_RESET"
        ( cd "$PAY" && git hook list --show-scope "$ev" 2>/dev/null || true ) | sed 's/^/      /'
    done
    printf '\n  %b%s%b\n' "$C_BOLD$C_CYN" "analytics-api" "$C_RESET"
    for ev in pre-commit commit-msg pre-push; do
        printf '    %b%s%b\n' "$C_DIM" "$ev" "$C_RESET"
        ( cd "$ANA" && git hook list --show-scope "$ev" 2>/dev/null || true ) | sed 's/^/      /'
    done

    printf '\n%b%s%b\n' "$C_MAG" "$BAR" "$C_RESET"
    printf '  %bRoll this out for real:%b\n' "$C_BOLD" "$C_RESET"
    printf '    %b1.%b Put policy/ in a shared repo (e.g. %borg-policy.git%b).\n' "$C_CYN$C_BOLD" "$C_RESET" "$C_BOLD" "$C_RESET"
    printf '    %b2.%b Clone it to a known path on every dev machine (dotfiles / Ansible / Jamf).\n' "$C_CYN$C_BOLD" "$C_RESET"
    printf '    %b3.%b Add one line to %b/etc/gitconfig%b or %b~/.gitconfig%b:\n' "$C_CYN$C_BOLD" "$C_RESET" "$C_BOLD" "$C_RESET" "$C_BOLD" "$C_RESET"
    printf '         %b[include]%b\n' "$C_GRN" "$C_RESET"
    printf '         %b    path = /opt/org-policy/policy.gitconfig%b\n' "$C_GRN" "$C_RESET"
    printf '    %b4.%b Update the shared repo; every machine picks it up on next git invocation.\n\n' "$C_CYN$C_BOLD" "$C_RESET"
    printf '%b%s%b\n\n' "$C_MAG" "$BAR" "$C_RESET"
}

# ---- main -------------------------------------------------------------------
main() {
    banner
    pause
    s1_meet_the_bundle
    s2_install_bundle
    s3_two_repos
    s4_secret_caught
    s5_fix_leak_and_branch_guard
    s6_msg_guard_and_success
    s7_opt_out
    s8_multiscope
    s9_report
}

main "$@"
