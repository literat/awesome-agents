# Conventional Comments Reference

Single source of truth for label definitions, decorations, and scoring rules used by the code review skill.

## Format

```
<label> (<decorations>): <subject>

<discussion>
```

- **label** — classifies the comment's intent (see table below)
- **decorations** — required modifiers in parentheses, comma-separated. Default to `(non-blocking)` when no other decoration applies
- **subject** — short description of the finding
- **discussion** — structured body with `File:` (local path) or `File:` (GitHub permalink), then `Fix:`, `Why:` fields (see output templates for exact format)

## Labels

| Label | Meaning | When to Use | Expected Developer Action | Blocking by Default |
|-------|---------|-------------|--------------------------|---------------------|
| **issue** | A problem that must or should be addressed | Bugs, security vulnerabilities, data loss risks, logic errors | Fix before merge (if blocking) or before next release | No (use `(blocking)` decoration explicitly) |
| **suggestion** | A proposed improvement | Better approaches, cleaner patterns, performance gains | Consider and apply or discuss | No |
| **todo** | A required follow-up task | Missing tests, incomplete error handling, unfinished migration | Complete before merge or create tracked issue | No |
| **question** | Seeking clarification | Unclear intent, ambiguous logic, missing context | Respond with explanation or add code comment | No |
| **thought** | An observation for consideration | Architectural observations, potential future concerns | No action required — informational | No |
| **note** | Highlighting information | Context for reviewers, non-obvious behavior, design rationale | No action required — informational | No |
| **chore** | Maintenance or cleanup task | Rename, restructure, update dependency, remove dead code | Apply when convenient | No |
| **praise** | Positive feedback | Well-written code, good patterns, clever solutions | None — recognition | No |

## Decorations

| Decoration | Definition | When to Apply |
|------------|------------|---------------|
| **(blocking)** | Merge must not proceed until resolved | Security vulnerabilities, data loss, critical bugs |
| **(non-blocking)** | Default decoration — finding does not block merge | Always applied unless a more specific decoration overrides it |
| **(if-minor)** | Resolution is only needed if the change is small | Minor suggestions where the fix effort should be proportional |
| **(security)** | Flags a security-related concern | Any finding with security implications, regardless of label |

## Internal Confidence Thresholds

Confidence scores are used internally to decide whether to report a finding. They are **never shown in output**.

| Labels | Minimum Confidence |
|--------|--------------------|
| issue, suggestion, todo, chore | 80+ |
| question, thought, note | Below 80 allowed |
| nitpick | **Never use** — linter-catchable items should not be reported |

## Scoring Factors

When assigning internal confidence:

- **Evidence strength** — Can you point to the exact line and explain the concrete failure mode?
- **Impact severity** — What breaks if this ships? Data loss > UX bug > style issue.
- **Certainty** — Are you sure this is wrong, or could it be intentional?

## Label Ordering (Output)

Findings are listed flat (no dimension headers), ordered by severity:

1. `issue (blocking)`
2. `issue`
3. `todo`
4. `suggestion`
5. `question`
6. `thought`
7. `note`
8. `chore`

Praise is reported as a single block after all findings, before the summary table. See `review-output-templates.md` for the summary table format and verdict templates.

## Finding Examples

### issue (blocking)
```
issue (blocking, security): SQL injection via string concatenation

File: src/db/users.ts:42

Fix: Use parameterized query: `db.query('SELECT * FROM users WHERE id = $1', [userId])`

Why: User-controlled `userId` is interpolated directly into the query string.
```

### issue (non-blocking)
```
issue (non-blocking): Race condition in counter increment

File: src/services/counter.ts:15

Fix: Use atomic increment: `db.query('UPDATE counters SET value = value + 1 WHERE id = $1', [id])`

Why: Read-modify-write without a transaction allows concurrent requests to lose increments.
```

### suggestion (non-blocking)
```
suggestion (non-blocking): Extract repeated validation into shared helper

File: src/api/orders.ts:18

Fix: Move the email/phone validation to `src/utils/validate.ts` and import it.

Why: The same 15-line validation block appears in 3 route handlers.
```

### todo (non-blocking)
```
todo (non-blocking): Add unit tests for the new discount calculation

File: src/services/pricing.ts:45

Fix: Add test cases for: zero quantity, negative price, boundary discount tiers.

Why: The discount logic has multiple branches with no test coverage.
```

## Verdict Mapping

| Verdict | Condition |
|---------|-----------|
| **REQUEST CHANGES** | Any `(blocking)` finding present |
| **COMMENT** | Has `issue` or `todo` findings but none are `(blocking)` |
| **APPROVE** | No `issue` or `todo` findings |
