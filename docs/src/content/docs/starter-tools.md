---
title: Starter tools
description: The ready-made tools humangate init adds - git-sign, git-push, git-push-with-force and gh-pr-create.
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

## gh-pr-create

```
gh-pr-create [--base <branch>] <branch> <title> [<body>]
```

Opens a GitHub pull request from `<branch>` with the [gh CLI](https://cli.github.com/), which
must be installed and signed in on the host. It goes into the base branch - `main`, or
`$HUMANGATE_BASE_BRANCH` in the loop's environment - or into `--base` for a branch stacked on
another. The title must be a single line; the body is optional.

It refuses unless `<branch>` is already pushed to `origin` exactly as it is locally, so the pull
request holds the commits it lists before creating it - the ones you can see in the project.
