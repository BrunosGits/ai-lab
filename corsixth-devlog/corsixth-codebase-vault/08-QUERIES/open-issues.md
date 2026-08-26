```dataview
TABLE area, task, status
FROM "01-CODEBASE"
WHERE contains(file.content, "TODO") OR contains(file.content, "FIXME")
SORT area ASC
```


## Related Pages

- [[BUG_PATTERN_CATALOG]]
- [[code-refs]]
- [[coverage-dashboard]]
- [[pr-status]]
- [[regression-index]]
- [[test-coverage]]
