---
name: buffer
description: 'Use this skill whenever the user references an Emacs buffer — e.g. `*Messages*`, `*scratch*`, `*Compile-Log*`, `*Org Agenda*`, a compilation or error buffer, or any buffer name — and wants to read, inspect, search, or explain its contents, or invokes "/buffer". Read the buffer via emacsclient and bring its text into the conversation.'
tools: Bash
---

# Read an Emacs buffer

Read the contents of a named Emacs buffer (e.g. `*Messages*`, `*scratch*`, a compilation, `*Org Agenda*`, or ibuffer output) using `emacsclient --eval`, and bring the text back into the conversation. The user may invoke this directly with `/buffer`, but they are more likely to refer to a buffer mid-conversation — e.g. "Explain the error from `*Messages*` buffer lines 23-25". Treat any buffer-name reference in the prompt as a request to read it.

## How to read

First, locate `agent-skill-buffer.el` which lives alongside this skill file at `skills/buffer/agent-skill-buffer.el` in the emacs-skills plugin directory.

A plain read of the whole buffer:

```sh
emacsclient --eval '
(progn
  (load "/path/to/skills/buffer/agent-skill-buffer.el" nil t)
  (agent-skill-buffer
    :buffer "*scratch*"))'
```

The helper returns a plist with the buffer name, whether it exists, its total line count, the character count of the returned text, and the text itself:

```elisp
(:buffer "*Messages*" :exists t :lines 1203 :chars 8912
 :text "...")
```

When the buffer does not exist, it returns the list of live buffers instead — relay that list so the user can pick the right name.

## Mapping a request to arguments

Extract the arguments from how the user phrased the request:

- **Buffer name** — the quoted name as displayed (`*Messages*`), or the bare name of a file-backed buffer (`~/.emacs`).
- **Line range** — "lines 23-25" becomes `:start 23 :end 25`; a single "line 42" becomes `:start 42 :end 42`.
- **Topic/keyword** — "the error", "warnings", a symbol, etc. becomes `:regexp`, which keeps only the matching lines.

## Narrowing large buffers

Buffers like `*Messages*` can be huge, so narrow before reading. `:start` and `:end` give a 1-based inclusive line range, and `:regexp` keeps only the lines that match:

```sh
emacsclient --eval '
(progn
  (load "/path/to/skills/buffer/agent-skill-buffer.el" nil t)
  (agent-skill-buffer
    :buffer "*Messages*"
    :regexp "error"))'
```

The narrowing options are independent and combinable — use whichever fits the request. When the user asks about a specific topic, narrow with `:regexp` instead of dumping the whole buffer.

## Rules

- Use the exact buffer name as displayed in the buffer list.
- Locate `agent-skill-buffer.el` relative to this skill file's directory.
- Extract `:text` from the returned plist and work with it directly.
- Return the full text to the user; don't summarize it unless they ask.
- If the buffer doesn't exist, relay the returned list of live buffers so the user can pick the right name.
- Run the `emacsclient --eval` command via the Bash tool.
