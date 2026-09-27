# AGENTS.md

humangate lets a sandboxed coding agent ask the person at the host to run one of a project's
tools, and runs it only after they approve. See `README.md` for what it does and how it's used.

## Layout

- `bin/humangate` - the whole program: one Python script, both the agent side (`request`,
  `tools`, `ping`, `wait`) and the person's side (`loop`).
- `install.sh` - the `curl | sh` installer; downloads `bin/humangate` from GitHub.
- Starter tools (`sign`, `push`) live inside `bin/humangate`, in `STARTER_TOOLS`, so the
  installed script is self-contained; `humangate init` writes them into a project, or with
  `--global` into `~/.humangate/tools/` on the host.
- `.humangate/tools/` - the tools this repository itself uses, installed from the starter tools
  (`bin/humangate init --force sign push` after changing them); development of humangate goes
  through humangate, so sign and push by requesting them (`humangate request ...`).

## Conventions

- `bin/humangate` stays a single file using only the Python standard library, compatible with
  Python 3.8 (the oldest the installer accepts) - no dependencies, nothing to install besides
  the script.
- Tools are portable to macOS: bash 3.2 and BSD `sed`/`awk`/`grep`, since the loop usually runs
  on a Mac.
- Anything that comes from the agent - request files, tool names, arguments, reasons - is
  untrusted. The loop builds what it runs itself and never passes agent input to a shell.
- Commit messages explain why, in English.

## Testing

There's no test suite yet. Exercise changes against a throwaway git repository:

- run the loop with `env -u WM_SANDBOX_GUEST humangate loop` (it refuses to start inside a
  workmux sandbox otherwise), feeding answers on stdin - piped input takes one-line answers
  (`y`, `a`, `n`, `r` then the reply, or reply text);
- for the interactive menu, run it under `script -qfc "humangate loop" <log>` and send key
  sequences (`\033[A`, `\r`, `\003`) with pauses between them;
- check exit codes and the output `request` prints, and the log in `~/.humangate/logs/` (point `HOME`
  at a temporary directory).

Some actions need the person at the host - signing commits, pushing and the like; see @.humangate/AGENTS.md for how to ask for them.
