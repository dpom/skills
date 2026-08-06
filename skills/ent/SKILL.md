---
name: ent
description: 'Use this skill whenever the user wants to run an ent build task in the agent''s current project directory, or wants to read or inspect the ent log buffer. Ent (https://github.com/dpom/ent) is an Emacs Lisp build tool: projects define tasks in a `.ent.el` file and ent runs them, reporting output in the `*ent-log*` buffer. Covers requests like "/ent test", "run the ent lint task", "run the build with ent", "run ent task X", "did the ent task pass", "read the ent log". Make sure to use this skill proactively whenever YOU (the agent) need to run a project build, test, lint, compile, or cleanup step during a coding task and the project uses ent (has a `.ent.el` file in it or above the current directory) — check for it before falling back to shell commands, even if the user never said "ent". The skill runs the task through the running Emacs server via emacsclient, waits for it to finish, and brings the `*ent-log*` buffer contents into the conversation for further processing.'
tools: Bash
---

# Run an ent task and read its log

`ent` is an Emacs Lisp build tool. A project defines tasks in a `.ent.el` file at its root (each task's `:action` is a shell command or an elisp function, with optional `:deps`), and running a task executes it — plus all its dependencies — reporting output to the `*ent-log*` buffer. This skill runs a task for the agent's current project directory in the running Emacs server (via `emacsclient`), waits for it to complete, and returns the log so you can process it (e.g. diagnose a failed step).

This skill is not just for explicit user requests. Use it proactively during coding tasks whenever the project uses ent and you need to run or verify a build step. Before running a build, test, lint, or cleanup command yourself, check whether the current directory or its parents contain a `.ent.el` project file (e.g. via `ls` or the existence of the file). If it does, the ent tasks are the project's canonical way to run those steps — use this skill instead of ad-hoc shell commands, and report the results back from the log.

First, locate `agent-skill-ent.el`, which lives alongside this skill file at `skills/ent/agent-skill-ent.el` in the emacs-skills plugin directory.

## Run a task

`agent-skill-ent-run` takes the task name and the project directory. Use the agent's current working directory as `:dir` unless the user says otherwise (get it with `pwd` if unsure).

```sh
emacsclient --eval '
(progn
  (load "/path/to/skills/ent/agent-skill-ent.el" nil t)
  (agent-skill-ent-run
    :task "test"
    :dir "/home/user/project"))'
```

The command blocks until the task finishes (default timeout 600s) and returns a plist:

```elisp
(:task "test" :success t :timed-out nil :error nil
 :lines 42 :chars 1234 :text "...")
```

- `:text` — full contents of the `*ent-log*` buffer. Work with it directly; don't summarize unless asked.
- `:success` — non-nil only if every shell command exited with status 0 and no task errored.
- `:error` — the error message when something went wrong (missing `.ent.el`, unknown task, task timeout, a lisp action that signaled).
- `:timed-out` — non-nil if the run exceeded `:timeout` seconds.

Because the eval blocks for the whole run, give the Bash tool call a timeout comfortably larger than the task's expected runtime, e.g. `:timeout 120` in the elisp and a 180000ms Bash timeout.

## If the task name isn't given

Ask which task, or if the user refers to a task loosely ("run the build"), discover the available tasks first:

```sh
emacsclient --eval '
(progn
  (load "/path/to/skills/ent/agent-skill-ent.el" nil t)
  (agent-skill-ent-tasks
    :dir "/home/user/project"))'
```

This returns `(:project-dir P :tasks (("help" . "doc") ("test" . "doc") ...))` and does not touch the log buffer. Pick the task that matches the user's intent.

## Read an existing log

When a task was already run (by the user with `M-x ent-run`, or by you earlier) and the user just wants the log, read it without running anything:

```sh
emacsclient --eval '
(progn
  (load "/path/to/skills/ent/agent-skill-ent.el" nil t)
  (agent-skill-ent-log))'
```

Returns `(:exists BOOL :lines N :chars N :text TEXT)`.

## Rules

- Run the `emacsclient --eval` commands via the Bash tool; always use `emacsclient`, never `emacs` or `emacs --batch`.
- Use absolute paths for `:dir` and the helper file.
- `:dir` is the directory ent searches for `.ent.el` (it searches upward from it too), so the project root is the natural choice.
- A run always starts a fresh `*ent-log*` buffer, so a log you already read is invalidated after the next run.
- Present `:text` to the user verbatim, and use `:success`/`:error` to tell them whether the task actually passed.
