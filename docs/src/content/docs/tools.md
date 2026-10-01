---
title: Tools
description: What a humangate tool is and how to write one.
---

A tool is a capability you grant the agent. You're not asked "is this shell command safe?" but
"do I let the agent do this, with these arguments?" - a question you can answer at a glance.

It's any executable in one of these, looked up in this order - the first with a tool of that
name wins. `humangate tools` and the loop label each tool with where it comes from:

- **project** - the project's `.humangate/tools/`;
- **user** - `~/.humangate/user-tools/` on the host: your own, available in every project;
- **built-in** - `~/.humangate/built-in-tools/` on the host: the
  [built-in tools](/built-in-tools/), which the installer keeps current.

So you override a built-in tool with a copy of your own in either of the first two, and
the label says so: `git-push (user, overrides built-in)`. A tool runs
in the project root on the host with the agent's arguments as-is.

The agent discovers tools with `humangate tools`. It sees the ones on the host only while the
loop is running: they live in your home on the host, which the sandbox can't see, so the loop
lists them for it.

- Start it with a comment header after the shebang: a `Usage:` line and a short description.
  That's what `humangate tools` shows the agent - read from the file, never by running the tool.
- Print the same header on `--help`, as the built-in tools do.
- Optionally offer the person "just look" actions with header lines like
  `# Action: diff - the commits it would push, with their changes`. The loop adds each to the
  request menu and runs `<tool> --action <name> <arg>...` on the host when they pick it; the
  output shows in the loop only, the agent never sees it. Those lines don't appear in
  `humangate tools`. The built-in tools all offer `diff`.
- Validate every argument - they come from the agent. Refuse anything unexpected with a
  non-zero exit and a message on stderr.
- Keep it small and specific, so the command you're asked to approve says exactly what will
  happen. `git-push <branch>` is a capability you can decide on; `git <anything>` isn't.
- Run as little of the project's code as you can. The agent could have written any of it, so
  a tool that runs it can be made to do more than its name says. Git's own hooks and config
  are [guarded](/guarding-files/); for anything more, see below.

## Tools that run project code

Some tools can't avoid it - a deploy script, a release task. Don't let them run the working
tree the agent edits; have them check out code that's been reviewed, like `origin/main`, into
a fresh directory and run it from there. That only works if the agent can't change that code
through your tools alone - say, `main` accepts only reviewed pull requests.
