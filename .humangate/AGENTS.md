# Actions that need the person (humangate)

Some things can't be done from this sandbox - signing commits or pushing, for example - because
the keys stay on the host. Ask the person to run them with humangate:

- `humangate tools` lists what can be requested and how to use each tool.
- `humangate request --reason "<why>" <tool> [<arg>...]` asks for it and waits for the person's
  decision (up to 9 minutes), then prints the tool's output and exits with its exit code.
- Write the reason for the person reviewing it: what you did and why the tool is needed now.
- Don't work around a rejection. If the person replies with a message instead (exit code 5),
  act on it.
- The person guards some files - the tools, git hooks and config, and whatever
  `.humangate/guard` lists. After you change one, requests are refused until they accept the
  change, so say what you changed and why in your next reason.
- If nobody answers, `humangate ping` tells whether the person is running `humangate loop`.
