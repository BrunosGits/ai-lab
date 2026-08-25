```dataview
TABLE area, task, status
FROM "01-CODEBASE"
WHERE contains(file.content, "TODO") OR contains(file.content, "FIXME")
SORT area ASC
```
