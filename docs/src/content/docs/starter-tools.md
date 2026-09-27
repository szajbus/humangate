---
title: Starter tools
description: The ready-made tools humangate init adds - git-sign, git-push and git-push-with-force.
---

`humangate init` adds these to a project's `.humangate/tools/`, picked from a checklist or named
as arguments; `humangate init --global` adds them to `~/.humangate/tools/` on the host, for every
project. It never overwrites a tool you've changed, unless you pass `--force`.

They're ordinary [tools](/tools/): small bash scripts you can read, change or use as a
starting point for your own.

## git-sign

```
git-sign <branch>
```

Re-signs every commit `<branch>` has on top of the base branch, in place - for when a rebase in
the sandbox dropped the signatures. The base branch is `main`, or `$HUMANGATE_BASE_BRANCH` in the
loop's environment. Stacked branches pointing into the re-signed range move along with it.

On the base branch itself, it re-signs only the commits not on `origin` yet (all of them in a new
repository), never published history.

It refuses to run unless:

- `<branch>` is the branch checked out in the project directory;
- there are no uncommitted changes;
- the branch has commits on top of the base, with no merge commits among them;
- on the base branch, it hasn't diverged from `origin`.

## git-push

```
git-push <branch> [<branch>...]
```

Pushes existing local branches to `origin`, without force - git itself refuses anything but a
fast-forward or a new branch.

## git-push-with-force

```
git-push-with-force <branch> [<branch>...]
```

Force-pushes existing local branches to `origin`, replacing their history there - for a branch
rewritten by a rebase. It uses `--force-with-lease`, so it refuses if `origin` moved since your
last fetch, and it never force-pushes `main` or `master`.

Both push tools accept only names of existing local branches, so the command you approve says
exactly which branches go where.
