# Code Review Instructions

Frame findings constructively. Assume the author made a reasonable choice until proven otherwise. Use "consider" for suggestions, ask before asserting when intent is ambiguous, and lead with the fix rather than the fault. The goal is to make the code better, not to catalog what's wrong.

Use [Conventional Comments](https://conventionalcomments.org/) for all findings.

## Finding Format

```
<label> (<decorations>): <subject>

  File: https://github.com/{owner}/{repo}/blob/{sha}/{file}#L{line}

  Fix: Concrete fix with code example.

  Why: What is wrong and why it matters.
```

Use the PR head commit SHA for permalinks. For line ranges use `#L{start}-L{end}`.

`question` findings may omit the `Fix:` field because they seek clarification rather than prescribe a change. In PR review mode, Tier 2 already-reported findings may also omit `Fix:`/`Why:` when the disposition is `already covered` (see `skills/code-review/references/review-output-templates.md`). All other labels require `Fix:`.

**Labels:** issue, suggestion, todo, question, thought, note, chore, praise
**Decorations (required):** `(blocking)` — must fix before merge; `(non-blocking)` — default; `(security)` — security concern; `(if-minor)` — fix only if change is small. Combine as needed: `(blocking, security)`.
**Confidence rule:** Only report actionable labels (issue, suggestion, todo, chore) when highly confident. Use softer labels (question, thought, note) when uncertain. Prefer `question` over `issue` when you aren't sure whether code is intentional — ask for the rationale rather than flagging it as a defect. Never use `nitpick`.

## What NOT to Report

- Pre-existing issues in unchanged code (unless critical security)
- Linter-catchable items: formatting, import order, unused variables
- Style preferences not codified in project conventions
- Code outside the diff scope
- Intentional lint suppressions with explanatory comments
- Patterns consistent with the rest of the codebase
- Hypothetical issues without evidence ("could be a problem if...")
- Ambiguous intent flagged as defects — when unsure whether code is intentional, use `question` to ask for clarification rather than reporting it as an `issue`

## Review Dimensions

Analyze all changed code across these areas:

1. **Security** — Hardcoded credentials, SQL injection, XSS, path traversal, CSRF, auth bypasses, secrets in logs, insecure dependencies
2. **Bugs** — Logic errors, null/undefined gaps, race conditions, resource leaks, off-by-one, boundary errors, stale closures
3. **Silent Failures** — Empty catch blocks, swallowed errors, broad `catch(e: any)`, missing error logging, unhandled promise rejections, default fallbacks hiding bugs
4. **Tests** — Missing coverage for critical paths, edge cases, error branches; high regression risk without tests
5. **Types** — `any` abuse, stringly-typed APIs, exposed mutable internals, god objects (10+ fields), types that allow invalid states
6. **Simplification** — Deep nesting (>3 levels), duplicate logic, poor naming, unnecessary abstractions, over-engineering
7. **Guidelines** — Deviations from project conventions in CLAUDE.md or project config (imports, naming, error handling, file structure)

## Consolidated Findings

When the same issue appears in multiple files:

```
<label> (<decorations>): <subject> — N occurrences

  Files:
  - https://github.com/{owner}/{repo}/blob/{sha}/{file_a}#L10
  - https://github.com/{owner}/{repo}/blob/{sha}/{file_b}#L25

  Fix: Common fix approach.

  Why: Common description.
```

## Verdict

| Verdict | Condition |
|---------|-----------|
| **REQUEST CHANGES** | Any `(blocking)` finding |
| **COMMENT** | Has `issue` or `todo` findings, none blocking |
| **APPROVE** | No `issue` or `todo` findings |

Never approve code with security vulnerabilities or critical bugs.

## Output Structure

1. Start with `Code Review: <branch-name>` header, then `Scope: N commits, N files (+N / -N)`, then a numbered overview of what the branch does
2. Group findings by file — numbered sections: `1. path/to/file.ts — Short context`
3. Order findings by severity: `issue (blocking)` → `issue` → `todo` → `suggestion` → `question` → `thought` → `note` → `chore`
4. End with a single `praise:` block summarizing what was done well
5. For the review summary section (headings, summary table, verdict, and when to omit zero-count rows), follow the canonical templates in `skills/code-review/references/review-output-templates.md`.

## AI-Generated Code

When reviewing AI-generated changes, additionally check for:
- Behavioral regressions — subtle changes to existing behavior
- Unvalidated inputs the AI trusts
- Unnecessary complexity or gratuitous abstractions
- Accidental architecture drift
