---
title: Guarding files
description: How the loop watches the files the agent could use to subvert your approvals.
---

Your "yes" is only as good as what the approved command runs, and the agent can edit much of
that: the tools, git hooks and config (a `pre-push` hook or `core.sshCommand` can run
anything), and whatever else your tools reach into - `package.json` scripts, a `Makefile`, CI
workflows, an `.envrc`, etc. So the loop guards these files: it remembers their state when it
starts, and checks them every couple of seconds and before each request.

Always guarded: the project's tools, git hooks (including `core.hooksPath`), the repository's git config
except `branch.*` (git writes those itself), and `.humangate/guard` - the project's list of
more paths to guard. It takes one path or glob per line (`**` matches any depth), relative to
the project root. A directory covers everything in it; `#` starts a comment:

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
