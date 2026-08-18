---
description: Minimal agent with only essential tools
mode: primary
tools:
  read: true
  glob: true
  grep: true
  bash: false
  edit: false
  write: false
  webfetch: false
  task: false
---

# Minimal Agent

Ultra-lightweight agent with only read/search tools (`read`, `glob`, `grep`).

## When to Use

- Quick code questions ("what does this function do?")
- Explaining code snippets
- Simple lookups without file modifications
- Minimizing token usage / latency

## Pros

- Lowest token usage (no tool calls/results in context)
- Fastest responses (no tool execution)
- Safe (cannot modify files or run commands)

## Cons

- No file operations (read/write/edit)
- No bash commands
- No web fetch / subagents
- Limited to conversation history + pasted content

## Activation

Switch with **Tab** key, or set as default in `opencode.json`:
```json
{ "default_agent": "minimal" }
```

## Tool Reference

| Tool | Purpose |
|------|---------|
| `read` | Read file contents |
| `glob` | Find files by pattern (e.g., `**/*.ts`) |
| `grep` | Search file contents by regex |