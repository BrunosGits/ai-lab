# Java Checkstyle Rules

## Key Rules Enforced

| Rule | Description |
|------|-------------|
| `NeedBraces` | All `if`, `else`, `for`, `while`, `do` statements must have braces |
| `JavadocMethod` | Public/protected methods must have Javadoc |
| `JavadocType` | Classes/interfaces must have Javadoc |
| `UnusedImports` | No unused imports allowed |
| `LineLength` | Max line length (typically 120 chars) |
| `WhitespaceAround` | Proper whitespace around operators |

## Common Violations from PR #11982

| Violation | Fix |
|-----------|-----|
| One-line `if` without braces | Always use braced blocks: `if (cond) { ... }` |
| String concatenation in logging | Use parameterized: `logger.debug("msg: {}", value)` |

## Run Checkstyle

```bash
./gradlew checkstyleMain checkstyleTest
```