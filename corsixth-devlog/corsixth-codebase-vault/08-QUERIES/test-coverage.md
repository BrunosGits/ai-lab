```dataview
TABLE area, file.name as test, status
FROM "01-CODEBASE"
WHERE contains(file.name, "spec") OR contains(file.path, "test")
SORT area ASC
```


## Related Pages

- [[BUG_PATTERN_CATALOG]]
- [[code-refs]]
- [[coverage-dashboard]]
- [[open-issues]]
- [[pr-status]]
- [[regression-index]]
