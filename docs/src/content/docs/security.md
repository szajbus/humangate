---
title: Security
description: What humangate protects against, and what it relies on.
---

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

The sandbox is untrusted: the agent and everything it writes - requests, arguments, reasons,
any file in the project. The host is trusted: the loop, your credentials and the tools, which
are the only way across. humangate assumes the agent may try to trick you, and relies on you
to read what you approve.

- It only gates what the sandbox can't already do. A write-enabled credential inside the
  sandbox bypasses it entirely - keep those on the host (see
  [Which credentials go where](/credentials/)).
- A request is only a tool name, arguments and a reason. The command shown to you is exactly
  the one that runs, with no shell involved. Control characters are stripped from what's shown,
  so it can't rewrite your terminal.
- The agent can edit what the tools run, and turn a tool into a confused deputy. The first
  defense is how the tool is written (see [Tools](/tools/)); the second is
  [guarding files](/guarding-files/).
- Tools run with your full environment, so a tool's argument checks are what keeps it from
  doing more than its name says.
- The loop refuses to start inside a workmux sandbox (`WM_SANDBOX_GUEST` set).
- Any process that can write to the project directory can queue a request - including other
  agents sharing the same sandbox. The request still needs your approval.
