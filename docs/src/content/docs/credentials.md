---
title: Which credentials go where
description: Read-only credentials in the sandbox, write-enabled ones on the host.
---

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
