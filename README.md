# git-config-hooks-demo

![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Git](https://img.shields.io/badge/Git%202.54+-F05032?style=for-the-badge&logo=git&logoColor=white)
![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

A **narrated, sandboxed, 60-second walkthrough** of Git 2.54's new config-based
hooks. Run one command, watch a color-coded story play out across two fake
repos, understand the feature end-to-end.

> Production-ready counterpart: **[git-config-hooks-policy](https://github.com/gsaini/git-config-hooks-policy)**
> — the hook bundle this demo exercises, packaged for real-world rollout.

---

## What you'll see

Nine scenes, ~45 seconds at default pacing:

1. **Meet the Policy Bundle** — four hook scripts, one config fragment. Nothing else.
2. **Install** — `[include]` the bundle from a sandboxed `$GIT_CONFIG_GLOBAL`.
3. **Two fresh repos — zero per-repo hook setup.** Both inherit everything.
4. **Catch a leaked credential** — AWS key + RSA key in a config file. Two hooks reject in parallel; you get every finding at once, not one-at-a-time.
5. **Fix the leak; see the branch guard in isolation** — now only `no-direct-main` speaks up. Clean signal.
6. **Topic branch; message guard in isolation; clean commit lands.** All three pre-commit hooks + commit-msg run silently on success.
7. **Per-repo opt-out** — `hook.no-direct-main.enabled = false` in the other repo. Config preserved, hook skipped. `--show-scope` prints a `disabled` badge.
8. **Scopes compose. Events compose.** A local-scope hook layered on top of global. One hook wired to two events (`pre-commit` + `pre-push`).
9. **Policy coverage report** — active hooks across both repos, plus the four-step org rollout recipe.

Every red `✗` you see is a hook correctly blocking a bad action. Every green
`✓` is a hook passing — silently, the way they should in a healthy repo.

---

## Visual overview

### 1. How the Policy Bundle plugs in

One `include.path` line pulls the bundle into the user's (or system's) git
config. Each `[hook "..."]` stanza registers one hook against one-or-more
events. No repo-local setup, no `core.hooksPath`.

```text
  ~/.gitconfig  ──include.path──▶  policy.gitconfig
                                          │
                ┌─────────────────┬───────┴─────────┬────────────────────┐
                ▼                 ▼                 ▼                    ▼
         hook.secret-scan  hook.no-direct-main  hook.conv-commit  hook.tests-reminder
                │                 │                 │                    │
         ┌──────┴──────┐          │                 │                    │
         ▼             ▼          ▼                 ▼                    ▼
    [pre-commit]  [pre-push]  [pre-commit]    [commit-msg]          [pre-push]
         │             │          │                 │                    │
         └─────────────┴──────────┴─────────────────┴────────────────────┘
                                  │
                                  ▼
                     every repo on the machine
```

### 2. What fires on `git commit`

Git parses config in **system → global → local** order, builds a per-event
chain, and runs each entry in discovery order. Traditional
`.git/hooks/<event>` scripts still run, last.

```text
  git commit -m "feat(x): ..."
            │
            ▼
  ┌───────────────────────────────┐
  │  parse config                 │
  │  system → global → local      │
  └───────────────┬───────────────┘
                  │
                  ▼
  ┌───────────────────────────────┐
  │  pre-commit chain             │
  │    1. secret-scan.sh          │
  │    2. no-direct-main.sh       │
  │    3. .git/hooks/pre-commit   │  ◀── hookdir runs last
  └───────────────┬───────────────┘
                  │
         any exits non-zero? ──── yes ──▶  ✗ commit blocked
                  │
                  no
                  ▼
  ┌───────────────────────────────┐
  │  commit-msg chain             │
  │    1. conventional-commit.sh  │
  └───────────────┬───────────────┘
                  │
         subject valid? ──── no ──▶  ✗ commit blocked
                  │
                  yes
                  ▼
           ✓ commit created
```

### 3. The nine-scene demo journey

```text
  ┌───────────────────────────────────────────────────────────────────────┐
  │  1 · Meet the Policy Bundle                 4 hooks, 1 fragment       │
  └────────────────────────────────┬──────────────────────────────────────┘
                                   ▼
  ┌───────────────────────────────────────────────────────────────────────┐
  │  2 · Install                                 [include] the bundle     │
  └────────────────────────────────┬──────────────────────────────────────┘
                                   ▼
  ┌───────────────────────────────────────────────────────────────────────┐
  │  3 · Two fresh repos                         zero per-repo setup      │
  └────────────────────────────────┬──────────────────────────────────────┘
                                   ▼
  ┌───────────────────────────────────────────────────────────────────────┐
  │  4 · Leaked credential      ✗ secret-scan + no-direct-main (parallel) │
  └────────────────────────────────┬──────────────────────────────────────┘
                                   ▼
  ┌───────────────────────────────────────────────────────────────────────┐
  │  5 · Fix leak                                ✗ no-direct-main alone   │
  └────────────────────────────────┬──────────────────────────────────────┘
                                   ▼
  ┌───────────────────────────────────────────────────────────────────────┐
  │  6 · Topic branch                            ✓ clean commit lands     │
  └────────────────────────────────┬──────────────────────────────────────┘
                                   ▼
  ┌───────────────────────────────────────────────────────────────────────┐
  │  7 · Per-repo opt-out              hook.<name>.enabled = false        │
  └────────────────────────────────┬──────────────────────────────────────┘
                                   ▼
  ┌───────────────────────────────────────────────────────────────────────┐
  │  8 · Scopes + events compose       local on top of global             │
  └────────────────────────────────┬──────────────────────────────────────┘
                                   ▼
  ┌───────────────────────────────────────────────────────────────────────┐
  │  9 · Coverage report                 + org rollout recipe             │
  └───────────────────────────────────────────────────────────────────────┘
```

---

## Requirements

- **Git 2.54 or later.** `git --version` must report `2.54.0+`. Lower versions
  don't recognize `[hook "..."]` configs or the `git hook` subcommand.
- **Bash 3.2+, POSIX `grep`, `sed`.** Standard on macOS and every Linux distro.
- **A terminal with ANSI color support** is recommended but not required.

---

## Run it

```bash
git clone https://github.com/gsaini/git-config-hooks-demo.git
cd git-config-hooks-demo
./run.sh
```

That's the whole thing.

### Controls

| Variable | Effect | Default |
| --- | --- | --- |
| `PAUSE=1` | Wait for Enter between scenes. Best for live presentations. | off |
| `SPEED=N` | Seconds between beats when auto-pacing (`0` = instant). | `0.6` |

```bash
PAUSE=1 ./run.sh        # live demo, audience-paced
SPEED=0 ./run.sh        # fast-forward through everything (good for CI smoke test)
SPEED=2 ./run.sh        # slow cinema mode
```

### Reset

The demo writes only into `./sandbox/`. To re-run from scratch:

```bash
./reset.sh              # wipes ./sandbox/
./run.sh
```

---

## Your real git config is safe

Before any git command runs, the driver sets:

```bash
export GIT_CONFIG_GLOBAL=./sandbox/fake-home/.gitconfig
export GIT_CONFIG_SYSTEM=/dev/null
```

Every repo-scoped `git config` call reads and writes inside `./sandbox/` only.
Your real `~/.gitconfig` and `/etc/gitconfig` are **never read, never mutated.**
Nuking `./sandbox/` is the total undo.

---

## The Policy Bundle (embedded in `policy/`)

The demo ships a vendored copy of the bundle, pinned to a known-good version
so the narration stays accurate. In production you'd point git at the
canonical repo instead — see
[git-config-hooks-policy](https://github.com/gsaini/git-config-hooks-policy)
for deployment docs.

Four hooks, one config fragment:

| Hook | Event(s) | Action |
| --- | --- | --- |
| `secret-scan` | `pre-commit`, `pre-push` | Block AWS keys, PEM keys, GitHub/Slack/OpenAI tokens, GCP service-account JSON. |
| `no-direct-main` | `pre-commit` | Refuse commits on `main`/`master`/`trunk`/`production`/`release`. |
| `conventional-commit` | `commit-msg` | Enforce `type(scope)!?: subject` with 72-char subject cap. |
| `tests-reminder` | `pre-push` | Non-blocking nudge: tests? docs? PR description? |

The config fragment is ~25 lines of ini:

```ini
[hook "secret-scan"]
    command = __POLICY_ROOT__/hooks/secret-scan.sh
    event = pre-commit
    event = pre-push

[hook "no-direct-main"]
    command = __POLICY_ROOT__/hooks/no-direct-main.sh
    event = pre-commit

[hook "conventional-commit"]
    command = __POLICY_ROOT__/hooks/conventional-commit.sh
    event = commit-msg

[hook "tests-reminder"]
    command = __POLICY_ROOT__/hooks/tests-reminder.sh
    event = pre-push
```

`__POLICY_ROOT__` is substituted with an absolute path at setup time.

---

## Feature primer — what's new in Git 2.54

Before 2.54 you had **one** per-event file in `.git/hooks/`, shareable only via
`core.hooksPath` (all-or-nothing) or third-party tools like husky/pre-commit.
Composing multiple org-wide checks required a wrapper script you maintained
yourself.

Git 2.54 adds a config-file-native model:

```ini
[hook "<name>"]
    command = <path or shell oneliner>  # what to execute
    event   = <hook-event>              # multi-valued — same hook, many events
    enabled = true|false                # opt out without deleting config
```

Plus two subcommands:

- `git hook list --show-scope <event>` — inventory of configured hooks, with
  the scope (system / global / local) each came from, and a `disabled` badge
  when turned off.
- `git hook run <event> [-- <args>]` — invoke the hook chain manually
  (useful for testing and for wrapper tools; see the
  [`man git-hook`](https://git-scm.com/docs/git-hook) "Wrappers" section).

Execution order: hooks fire in the order git encounters their config during
parse (system → global → local, and within each file top-to-bottom).
Traditional `.git/hooks/<event>` scripts still work and run **last** — they
show up in `git hook list --show-scope` as `hook from hookdir`.

> **No trust model.** Config-based hooks execute with the current user's
> privileges, just like `.git/hooks/`. Don't source policy bundles from places
> an attacker can mutate. System-scope installation from a root-owned path is
> the defensible rollout pattern.

---

## Directory layout

```text
git-config-hooks-demo/
├── run.sh                       # the 9-scene narrated driver
├── lib.sh                       # ANSI colors + scene/run/pause helpers
├── reset.sh                     # wipes ./sandbox/
├── policy/                      # vendored Policy Bundle
│   ├── hooks/
│   │   ├── secret-scan.sh
│   │   ├── no-direct-main.sh
│   │   ├── conventional-commit.sh
│   │   └── tests-reminder.sh
│   └── policy.gitconfig.tmpl    # [hook "..."] fragment with placeholder
├── README.md                    # (this file)
├── LICENSE
└── .gitignore                   # ignores ./sandbox/ at the repo root
#
# created at runtime by run.sh, gitignored:
#   sandbox/fake-home/.gitconfig
#   sandbox/fake-home/policy.gitconfig
#   sandbox/payments-service/       (a demo repo)
#   sandbox/analytics-api/          (another demo repo)
```

---

## Use this as a learning jumping-off point

After the demo runs, poke at the sandbox directly:

```bash
# The config the demo installed:
cat sandbox/fake-home/.gitconfig
cat sandbox/fake-home/policy.gitconfig

# Everything git sees from inside a demo repo:
cd sandbox/payments-service
GIT_CONFIG_GLOBAL=../fake-home/.gitconfig GIT_CONFIG_SYSTEM=/dev/null \
    git config --list --show-origin --show-scope

# Run a hook chain by hand:
GIT_CONFIG_GLOBAL=../fake-home/.gitconfig GIT_CONFIG_SYSTEM=/dev/null FORCE_COLOR=1 \
    git hook run pre-commit

# Try writing your own hook, register it at local scope:
GIT_CONFIG_GLOBAL=../fake-home/.gitconfig GIT_CONFIG_SYSTEM=/dev/null \
    git config set hook.my-thing.command /path/to/my-script.sh
GIT_CONFIG_GLOBAL=../fake-home/.gitconfig GIT_CONFIG_SYSTEM=/dev/null \
    git config set --append hook.my-thing.event pre-commit
```

---

## Related

- **[git-config-hooks-policy](https://github.com/gsaini/git-config-hooks-policy)** — the bundle, packaged for production.
- [Git 2.54 highlights (GitHub blog)](https://github.blog/open-source/git/highlights-from-git-2-54/)
- [`man git-hook`](https://git-scm.com/docs/git-hook) — authoritative reference for the `hook.*` config schema and subcommands.
- [`man githooks`](https://git-scm.com/docs/githooks) — complete list of hook events.

---

## License

MIT — see [LICENSE](./LICENSE).
