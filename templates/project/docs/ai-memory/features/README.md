# Feature Notes

Create one file per accepted feature or durable implementation area using a kebab-case slug.

## When to create a feature note

- The feature changed durable project behavior.
- Future work will benefit from remembering touched files, constraints, or fixes.

## Lifecycle

- Treat each feature note as a durable memory supplement for the current implementation state of that feature, not as the source of truth for active planning or delivery status.
- Rewrite the note in place when behavior changes.
- Trim sections that became stale while keeping the useful parts.
- Delete the file when the feature is removed, absorbed, or no longer carries durable value.
- Do not archive obsolete feature notes under `docs/ai-memory/`; rely on Git history instead.
- Deletions require a brief review before removal.

## Recommended structure

- `# <Feature Title>`
- `## Summary`
- `## Files`
- `## Durable constraints`
- `## Errors and fixes`

Record durable knowledge only. Avoid raw diff summaries, transient chat context, active task lists, acceptance criteria, rollout plans, and status tracking already covered by specs.
