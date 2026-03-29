# TESTING_NOTES.md — Admin Portal Testing Notes

**Location:** `apps/admin/docs/TESTING_NOTES.md`

This file captures testing gotchas, workarounds, and setup patterns
discovered during development. It is not the testing strategy (see
`apps/admin/docs/testing-strategy.md`) — it is the practical knowledge
that accumulates alongside it.

Before writing any test, check this file for existing workarounds
relevant to what you are testing.

## Index

*Populated as notes are added. Each entry links to the section below.*

## Notes

### Template — copy for each new note

```text
## NOTE-[000] — [Short title]
**Applies to:** [Component / hook / pattern this note is about]
**Context:** [When does this situation arise?]
**Problem:** [What goes wrong without this workaround]
**Solution / Workaround:** [Exact approach — include code snippet if helpful]
**Date:** [YYYY-MM-DD]
```

### Supabase Client Mocking in Vitest

*To be filled in when the first Supabase-dependent test is written.*

### next-intl Provider Setup in Tests

*To be filled in when the first component using useTranslations is tested.*

### Playwright Test Data Seeding

*To be filled in when the first E2E test requiring specific DB state is written.*

---

*No notes logged yet. First entry goes here.*