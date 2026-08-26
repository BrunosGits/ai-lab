# Grep Patterns

Useful grep commands for exploring the espanso codebase.

## Engine

```bash
# All middleware implementations
grep -rn "impl Middleware for" espanso-engine/src/

# All executor implementations
grep -rn "impl Executor for" espanso-engine/src/

# All EventType matches
grep -rn "EventType::" espanso-engine/src/

# All middleware names
grep -rn "fn name(&self)" espanso-engine/src/

# All trait definitions
grep -rn "pub trait" espanso-engine/src/

# All factory functions
grep -rn "pub fn default" espanso-engine/src/

# Crossbeam usage
grep -rn "crossbeam" espanso-engine/src/
```

## Config

```bash
# YAML parsing
grep -rn "yaml" espanso-config/src/

# Config file paths
grep -rn "config_dir" espanso-config/src/

# Match groups
grep -rn "MatchGroup" espanso-config/src/
```

## Detect

```bash
# Platform-specific detection
grep -rn "target_os" espanso-detect/src/

# CGEvent (macOS)
grep -rn "CGEvent" espanso-detect/src/

# Win32 hooks
grep -rn "SetWindowsHookEx" espanso-detect/src/

# X11 XRecord
grep -rn "XRecord" espanso-detect/src/

# evdev
grep -rn "evdev" espanso-detect/src/
```

## Inject

```bash
# Platform-specific injection
grep -rn "target_os" espanso-inject/src/

# CGEvent post (macOS)
grep -rn "CGEventPost" espanso-inject/src/

# SendInput (Windows)
grep -rn "SendInput" espanso-inject/src/

# xdotool (Linux)
grep -rn "xdotool" espanso-inject/src/

# uinput (Linux)
grep -rn "uinput" espanso-inject/src/
```

## Match

```bash
# Rolling matcher
grep -rn "RollingMatcher" espanso-match/src/

# Regex matcher
grep -rn "RegexMatcher" espanso-match/src/
```

## Render

```bash
# Extensions
grep -rn "Extension" espanso-render/src/

# Script extension
grep -rn "script" espanso-render/src/

# Shell extension
grep -rn "shell" espanso-render/src/

# Date extension
grep -rn "date" espanso-render/src/
```

## General

```bash
# All unwrap()s (potential panics)
grep -rn "\.unwrap()" espanso-*/src/

# All TODO/FIXME
grep -rn "TODO\|FIXME" espanso-*/src/

# All unsafe code
grep -rn "unsafe" espanso-*/src/

# All #[cfg(target_os)] conditionals
grep -rn "target_os" espanso-*/src/
```

## For Learning

```bash
# Find all event types
grep -rn "pub enum EventType" espanso-engine/src/

# Find all struct definitions
grep -rn "pub struct" espanso-*/src/

# Find all function definitions
grep -rn "pub fn" espanso-*/src/

# Find all test functions
grep -rn "#\[test\]" espanso-*/src/
```
