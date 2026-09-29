---
title: Getting started
description: Install humangate on the host and in the sandbox, and set up a project.
---

## Install

On the host, and inside the sandbox the agent runs in:

```bash
curl -fsSL https://raw.githubusercontent.com/szajbus/humangate/main/install.sh | sh
```

It installs a single Python script to `~/.local/bin/humangate` (`HUMANGATE_BIN_DIR` to
change), and the [built-in tools](/built-in-tools/) to `~/.humangate/built-in-tools/`,
available in every
project. It needs Python 3.8+ and git. Run it again to update both.

The project directory has to be shared between the sandbox and the host, writable from both -
requests travel through `.humangate/queue/` in it. Most VM and container sandboxes mount the
project that way already. It's the one channel every sandbox has, so there's no port to open
or token to hand out; the price is polling - an answer takes up to a second.


## Set up a project

1. Give the project the tools it needs. The [built-in tools](/built-in-tools/) -
   `git-sign`, `git-push`, `git-push-with-force`, `gh-issue-create` and `gh-pr-create` - are there already; write
   your own for anything else, as executables in `.humangate/tools/` (see [Tools](/tools/)).
2. On the host, in the project directory, start the loop and keep it open:
   ```bash
   humangate loop
   ```
3. Tell the agent about it. `humangate init` offers to: it writes the instructions to
   `.humangate/AGENTS.md` and adds a reference to it to the project's `AGENTS.md`.
4. Optionally, list the files your tools run or read in `.humangate/guard`, so the loop tells
   you when the agent changes them (see [Guarding files](/guarding-files/)). `humangate init`
   offers a first list based on what it finds in the project.

Every project directory - every git worktree, too - has its own queue, so run one loop per
agent session. A second loop in the same directory refuses to start, naming the process that
has it: two would race for requests. The lock is kept on the host, in `~/.humangate/locks/`,
out of the agent's reach, and it goes away with the process, however it ends.
