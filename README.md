# humangate

Coding agents should run in sandboxes, away from your keys and anything that can do damage.
humangate keeps it that way: the agent can only ask for one of the tools you've set up, and you
run it on your host. Your keys and credentials never enter the sandbox - the agent just gets the
output back.

When the agent asks, you decide:

```
$ humangate loop
humangate 0.2.0 loop watching /home/me/project/.humangate/queue (Ctrl-C to stop)
Tools: gh-issue-create (built-in), gh-pr-create (built-in), git-push (built-in), git-push-with-force (built-in), git-sign (built-in)
Guarding: git config, .humangate/tools, .humangate/guard, .git/hooks, package.json (18 files)
Log: /home/me/.humangate/logs/home-me-project.jsonl

[4f93b1686d8a3142] hey human, can you please run built-in:git-sign my-branch for me?

Rebased onto main; signatures were lost

Run it? (↑/↓ and Enter, or a shortcut letter)
    n  no
  ❯ y  yes
    e  edit (then run)
    r  reply
      ────────────────────────
    d  diff - the commits in that range, with their changes
```

The tool's output and exit code go back to the agent's `request`. If you edit the command first (in `$VISUAL`/`$EDITOR`), the agent is told what actually ran. A tool can offer actions (`d` above): they run on your host, show their output in the loop and tell the agent nothing - to look before you decide.

## Install

On the host and in the sandbox:

```bash
curl -fsSL https://raw.githubusercontent.com/szajbus/humangate/main/install.sh | sh
```

It installs a single Python script to `~/.local/bin/humangate` (`HUMANGATE_BIN_DIR` to
change), and needs Python 3.8+ and git. Run it again to update.

The project directory has to be shared between the sandbox and the host, writable from both -
requests travel through `.humangate/queue/` in it. Most VM and container sandboxes mount it
that way already, so there's no port to open or token to hand out.

## Which credentials go where

**The sandbox gets read-only credentials; the ones that can write stay on the host.**

| In the sandbox (read-only)                         | On the host only (write-enabled)           |
| -------------------------------------------------- | ------------------------------------------ |
| a read-only deploy key or token to fetch and clone | your commit signing key, and push access   |
| a GitHub token that can read issues and PRs        | a token that can comment, merge or release |
| read-only API keys, a viewer role in the cloud     | deploy, publish and admin credentials      |
| a read replica or read-only database user          | a database user that can write             |

Give each write action a tool - `git-push`, `deploy-staging`, `npm-publish` - that runs on the
host once you approve it. Credentials the agent never gets can't leak.

## Use

1. Run `humangate init` in the project. It offers to tell the agent about humangate in
   `AGENTS.md` and to suggest files to guard. Tools need no setting up: humangate comes
   with `git-sign`, `git-push`, `git-push-with-force`, `gh-issue-create` and `gh-pr-create` built in, for every
   project; add your own to the project's `.humangate/tools/`.
2. On the host, in the project directory, run `humangate loop` and keep it open. Every project
   directory - every git worktree, too - has its own queue, so run one loop per agent session;
   a second loop in the same directory refuses to start.

## Tools

A tool is a capability you grant the agent. You're not asked "is this shell command safe?" but
"do I let the agent do this, with these arguments?"

It's any executable in one of these - the first with a tool of that name wins, and each tool
is labelled with where it comes from:

- **project** - `.humangate/tools/` in the project;
- **user** - `~/.humangate/user-tools/` on the host, yours for every project;
- **built-in** - `~/.humangate/built-in-tools/` on the host, replaced whenever the
  installer runs; override one with your own copy in either of the others.

It runs in the project root with the agent's arguments as-is. The agent lists tools with
`humangate tools` (those on the host only while the loop runs).

- Put a `Usage:` line and a short description in a comment after the shebang - that's what the
  agent sees - and print it on `--help`.
- Validate every argument; refuse anything unexpected with a non-zero exit.
- Keep it small and specific: `git-push <branch>` is a capability you can decide on;
  `git <anything>` isn't.
- Run as little of the project's code as you can - the agent could have written it. If a tool
  must, like a deploy, have it run reviewed code - a fresh checkout of an `origin/main` that
  only accepts reviewed pull requests - rather than the working tree.

## Guarding files

Your "yes" is only as good as what the approved command runs, and the agent can edit much of
that: the tools, git hooks and config (`core.sshCommand` can run anything), `package.json`
scripts, a `Makefile`. A tool that runs them becomes a *confused deputy*, acting on the agent's
code with your credentials. So the loop guards these files, checking them every couple of
seconds and before each request.

Always guarded: the tools, git hooks, git config (except `branch.*` and `workmux.worktree.*`)
and `.humangate/guard`, which lists more paths or globs, one per line, relative to the project
root:

```
package.json
Makefile
.github/workflows/
```

A change shows up as a diff. Accept it and it becomes the approved state; refuse it and no
request runs until it's reverted.

- It detects, it doesn't prevent. And it doesn't follow code: guarding `package.json` doesn't
  cover the script it runs, so guard the entry points and keep tools off unreviewed code.
- Expect to review tracked files after switching branches or rebasing.
- Files are re-read on every check - fine for tens of files, slow for `node_modules/`.

## Security

```
   sandbox - untrusted                     host - trusted
 ┌─────────────────────────┐            ┌─────────────────────────┐
 │ agent                   │  request   │ humangate loop - you    │
 │ read-only credentials   │ ─────────► │ approve or refuse       │
 │                         │ ◄───────── │ tools                   │
 │ no write credentials    │   result   │ write credentials       │
 └────────────┬────────────┘            └────────────┬────────────┘
              └───────── shared project directory ───┘
```

The sandbox is untrusted: the agent and everything it writes. The host is trusted: the loop,
your credentials and the tools, which are the only way across. humangate assumes the agent may
try to trick you, and relies on you to read what you approve.

- A write-enabled credential in the sandbox bypasses humangate entirely.
- A request is only a tool name, arguments and a reason. What you're shown is exactly what
  runs, with no shell involved; arguments with control or invisible characters, or too long to
  show whole, are refused.
- Tools run with your full environment; their argument checks keep them to what their name
  says.
- Any process that can write to the project directory can queue a request, other agents
  included. It still needs your approval.
- The loop refuses to start inside a workmux sandbox (`WM_SANDBOX_GUEST` set), and when
  another loop runs in the same project (the lock is kept on the host).
