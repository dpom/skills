# emacs skills

Agent skills for working with a running Emacs via `emacsclient`. Requires an Emacs server running on the host.

## Skills

### buffer

Read the contents of a named Emacs buffer (e.g. `*Messages*`, `*scratch*`, a compilation buffer) through `emacsclient`, with optional line-range and regexp narrowing. Use whenever an agent references a buffer and wants its contents — "explain the error from the `*Messages*` buffer lines 23-25".

```bash
npx skills add dpom/skills --skill buffer
```

### ent

Run an `ent` (https://github.com/dpom/ent) build task in the agent's current project directory through `emacsclient`, wait for it to finish, and bring the `*ent-log*` buffer contents back for further processing. Also lists available tasks and reads an existing ent log. Use whenever an agent needs to run or inspect an ent task — "run the ent test task", "did the ent task pass", "read the ent log".

```bash
npx skills add dpom/skills --skill ent
```

[![skills.sh](https://skills.sh/b/dpom/skills)](https://skills.sh/dpom/skills)

## License

GPL-3.0. See [LICENSE](LICENSE).
