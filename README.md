# humangate

Coding agents are safest in a sandbox without your keys - but then they can't sign a commit,
push a branch or do anything else that needs them. humangate lets the agent ask you to run such
a command on the host: you see why it's needed and exactly what will run, and nothing happens
until you say yes.

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

What can be requested is up to you: every executable in a project's `.humangate/tools/`, or in
`~/.humangate/tools/` on the host for all projects, is one tool. humangate only carries requests
and answers, and runs a tool once you approve it.

## Install

On the host, and inside the sandbox the agent runs in:

```bash
curl -fsSL https://raw.githubusercontent.com/szajbus/humangate/main/install.sh | sh
```

It installs a single Python script to `~/.local/bin/humangate` (`HUMANGATE_BIN_DIR` to
change). It needs Python 3.8+ to install, and git to run; running the same command again
updates it.

The project directory has to be shared between the sandbox and the host, writable from both -
requests travel through `.humangate/queue/` in it. Most VM and container sandboxes mount the
project that way already.

Why files: that shared directory is the one channel every sandbox already has. So there's no
port to open or token to hand out, each project gets its own queue for free, and a request
survives either side restarting. The price is polling - an answer takes up to a second.

## Use

1. Give the project some tools: executables in `.humangate/tools/`. `humangate init` adds
   ready-made ones - `git-sign`, `git-push` and `git-push-with-force` - picked from a checklist; `humangate init --global`
   adds them to `~/.humangate/tools/` on the host instead, for every project. Write your own for
   anything else (see [Tools](#tools)).
2. On the host, in the project directory, start the loop and keep it open:
   ```bash
   humangate loop
   ```
3. Tell the agent about it. `humangate init` offers to (or `--instructions`, without the
   checklist): it writes the instructions to `.humangate/AGENTS.md` and adds a one-line
   reference to it to the project's `AGENTS.md` - a sentence any agent follows, whose
   `@.humangate/AGENTS.md` also makes Claude Code import the file.

Every project directory - every git worktree, too - has its own queue, so run one loop per
agent session.

### Commands

| Command                                                            | Who   | Does                                                          |
| ------------------------------------------------------------------ | ----- | ------------------------------------------------------------- |
| `humangate loop`                                                   | you   | shows requests as they come and runs the approved ones        |
| `humangate init [--global] [--force] [--instructions] [<tool>...]` | you   | adds starter tools and agent instructions                     |
| `humangate request --reason <why> <tool> ...`                      | agent | asks for a tool to be run and waits for the outcome           |
| `humangate tools [<tool>]`                                         | agent | lists the tools and their usage                               |
| `humangate ping`                                                   | agent | checks the loop is running - answered at once, without asking |
| `humangate wait <request-id>`                                      | agent | keeps waiting for a request after `request` timed out         |

`request` waits 9 minutes by default - just under the 10-minute limit some agents put on a shell
command (`--timeout <seconds>` to change) - then prints the tool's
output and exits with its exit code. `humangate --help` lists the exit codes for the other
outcomes.

### Answering

- **n** rejects it. It's preselected, so a stray Enter never runs anything.
- **y** runs the tool in your environment - your keys, SSH agent, credentials - shows the
  output and sends it back to the agent.
- **a** does the same, and runs this exact command (same tool, same arguments) again without
  asking for as long as the loop keeps running.
- **r** asks for a reply that goes back to the agent without running anything - to ask for more
  context, or for a different request.

Ctrl-C while a request is up cancels just that request, or interrupts its tool if it's running;
while the loop is idle it stops it. Decisions are logged on the host,
one file per project directory, in `~/.humangate/logs/` - not in the project, where the agent
could edit them.

## Tools

A tool is any executable in a project's `.humangate/tools/` or in `~/.humangate/tools/` on the
host (global tools, available in every project), named after what it does. A project tool
overrides a global one with the same name; the command you're asked to approve shows which one
runs. Either way it runs in the project root on the host and gets the agent's arguments as-is.

The sandbox can't see the host's home, so `humangate tools` asks the loop for the list - it
answers at once, like `ping`. Without a running loop it lists only the project's tools.

- Start it with a comment header after the shebang: a `Usage:` line, an empty comment line and
  a short description. `humangate tools` shows this header to the agent, reading it from the
  file - discovery never runs a tool.
- Print the same header on `--help`; the starter tools from `humangate init` show a one-line
  way to do it.
- Validate every argument - they come from the agent. Refuse anything unexpected with a
  non-zero exit and a message on stderr.
- Keep it small and specific, so the command you're asked to approve says exactly what will
  happen. A `git-push <branch>` tool is easy to review; a `git <anything>` tool isn't.

## Security

humangate assumes the agent may try to trick you, and relies on you to read what you approve.

- A request is only a tool name, arguments and a reason. The command shown to you is exactly
  the one that runs - a tool from `.humangate/tools/` or `~/.humangate/tools/` with those
  arguments, no shell involved.
  Control characters are stripped from the reason so it can't rewrite your terminal.
- The agent can write to the project directory - including the tools, and the git config and
  hooks a tool's git commands would run (a `pre-push` hook or `core.sshCommand` can run
  anything). The loop fingerprints all of those - and the global tools, in case the sandbox
  can reach your home after all - when it starts, and refuses every request once
  any of them changed; review the change, then restart the loop to accept it. Changes to
  `branch.*` config are allowed - git writes those itself and they can't run programs.
- Tools run with your full environment, so a tool's argument checks are what keeps it from
  doing more than its name says.
- The loop refuses to start inside a workmux sandbox (`WM_SANDBOX_GUEST` set).
- Any process that can write to the project directory can queue a request - including other
  agents sharing the same sandbox. The request still needs your approval.
