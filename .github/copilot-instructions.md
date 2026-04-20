# Code Review Instructions

Frame findings constructively. Assume the author made a reasonable choice until proven otherwise. Use "consider" for suggestions, ask before asserting when intent is ambiguous, and lead with the fix rather than the fault. The goal is to make the code better, not to catalog what's wrong.

Use [Conventional Comments](https://conventionalcomments.org/) for all findings.

## Finding Format

When a code suggestion exists, it **must appear as the very first element** — before the label line and before the `<details>` block. Use GitHub’s PR review suggestion fence (` ```suggestion`), which allows reviewers to apply the fix with one click. When no code suggestion is possible, omit the code block.

**Order is mandatory.** Do not place the label, subject, or `<details>` block before the suggestion block.

**Self-check before outputting any finding with a suggestion:** Is ` ```suggestion ` the absolute first line of the comment? If not, rewrite — move the suggestion block above everything else.

Correct format when a suggestion exists:

````markdown
```suggestion
{suggested code}
```

**{label} ({decorations}):** {subject}

<details>
  <summary>Explanation</summary>
  <strong>Fix:</strong> {fix explanation}
  <br />
  <br />
  <strong>Why:</strong> {why explanation}
</details>
````

Incorrect — do not do this:

````markdown
**{label} ({decorations}):** {subject}

<details>…</details>

```suggestion
{suggested code}
```
````

When there is no code suggestion:

```markdown
**{label} ({decorations}):** {subject}

<details>
  <summary>Explanation</summary>
  <strong>Fix:</strong> {fix explanation}
  <br />
  <br />
  <strong>Why:</strong> {why explanation}
</details>
```

`question` findings may omit the `Fix:` field. Markdown rendering inside `<details>` can be inconsistent depending on nesting/indentation — use HTML tags for reliability: inline code as `<code>{code}</code>`, code blocks as `<pre><code>{code}</code></pre>`.

**Labels:** issue, suggestion, todo, question, thought, note, chore, praise
**Decorations (required):** Always include at least one decoration. Use one or more of: `(blocking)` — must fix before merge; `(non-blocking)` — default and must be used when no other decoration applies; `(security)` — security concern; `(if-minor)` — fix only if change is small. Combine as needed, e.g. `(blocking, security)`.
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
7. **Guidelines** — Deviations from project conventions in `CLAUDE.md` or project config (imports, naming, error handling, file structure)

## AI-Generated Code

When reviewing AI-generated changes, additionally check for:

- Behavioral regressions — subtle changes to existing behavior
- Unvalidated inputs the AI trusts
- Unnecessary complexity or gratuitous abstractions
- Accidental architecture drift
