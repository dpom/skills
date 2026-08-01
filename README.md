# emacs skills

Agent skills for working with a running Emacs via `emacsclient`. Requires an Emacs server running on the host.

## Skills

### buffer

Read the contents of a named Emacs buffer (e.g. `*Messages*`, `*scratch*`, a compilation buffer) through `emacsclient`, with optional line-range and regexp narrowing. Use whenever an agent references a buffer and wants its contents — "explain the error from the `*Messages*` buffer lines 23-25".

```bash
npx skills add dpom/skills --skill buffer
```

[![skills.sh](https://skills.sh/b/dpom/skills)](https://skills.sh/dpom/skills)

## License

GPL-3.0. See [LICENSE](LICENSE).
