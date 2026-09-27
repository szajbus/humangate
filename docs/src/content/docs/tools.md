---
title: Tools
description: What a humangate tool is and how to write one.
---

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
