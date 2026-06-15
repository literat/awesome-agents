---
name: atomic-commits
description: >-
  Create clean, atomic git commits using Conventional Commits. Splits a mixed working
  tree into one logical commit per change via git-surgeon hunk staging, then commits each
  through git hooks. Use whenever the user asks to commit, "commit my changes", "make a
  commit", "commit this", "commit my work", or to stage and commit changes.
---

# Atomic Commits

Turn a working tree into a clean series of **atomic commits** — each commit one logical,
self-contained change with a [Conventional Commits](https://www.conventionalcommits.org) message.
Use the `git-surgeon` CLI for hunk-level staging, then commit through the normal `git` path so
commit-msg hooks run.

> **Prerequisite:** `git-surgeon` is a separate CLI tool (not part of this repo). Install it first;
> if it isn't available, fall back to `git add -p` / `git add <path>` for staging.

## Principles

- **One commit = one logical change.** A reviewer should be able to understand and, if needed,
  revert a single commit in isolation.
- **Stage at hunk granularity.** Use `git-surgeon` to pick exactly the hunks (or line ranges) that
  belong together. Never `git add -A` blindly when the tree mixes unrelated changes.
- **Conventional Commits subject; body explains _why_.** The diff already shows _what_ changed.
- **Commit with `git`, not `git-surgeon commit`.** Stage hunks with `git-surgeon`, but create the
  commit through `git` so the repo's commit-msg / pre-commit hooks stay in the loop. Never bypass
  them with `--no-verify`.
- **Pass the message via `-F <tmpfile>`, not `-m`.** Hooks run either way, but `-F` cleanly
  supports the multi-line bullet body and avoids local tooling that blocks `-m`.
- **No AI attribution.** Do not add "Generated with Claude Code" or similar trailers.
- **Pushing is out of scope.** Stop after committing unless the user explicitly asked to push.

---

## Workflow

### Step 1: Survey the changes

```bash
git status
git-surgeon hunks    # lists every unstaged hunk with a stable ID, file, and +/- counts
```

If anything is already staged, check it too: `git-surgeon hunks --staged`.

### Step 2: Group hunks into atomic units

Cluster the hunks by logical change — e.g. the feature vs. its tests vs. docs vs. an unrelated
fix that happened to be in the tree. Inspect anything ambiguous:

```bash
git-surgeon show <id>    # full diff for one hunk, lines numbered for partial staging
```

A single file often spans multiple commits; a single commit often spans multiple files. Group by
intent, not by file.

### Step 3: Draft a message per group

Write one Conventional Commit message for each group, following the format below. Keep the subject
tight; add a body when the _why_ isn't obvious from the subject.

### Step 4: Confirm the plan

Use `AskUserQuestion` to present the proposed grouping and messages before committing. Put the full
plan (groups → hunk IDs → messages) in the `preview` of the first option:

- **Apply it** (preview: the full grouping + messages) — create the commits as proposed.
- **Edit first** — user adjusts grouping or wording, then re-confirm.
- **Discard** — make no commits.

### Step 5: Commit each group

Commit in dependency order (e.g. the change before the test that exercises it). For each group:

```bash
git-surgeon stage <id1> <id2> ...        # or <id>:5-30 to stage only part of a hunk
TMPFILE=$(mktemp /tmp/commit-msg.XXXXXX)
printf '%s\n' "<commit message>" > "$TMPFILE"
git commit -F "$TMPFILE"
rm -f "$TMPFILE"
```

> Stage with `git-surgeon`, commit with `git` — not `git-surgeon commit`. This keeps the user's
> commit-msg hooks in the loop and supports full multi-line bodies via the tempfile.

After all groups are committed, verify:

```bash
git log --oneline -n <count>
git status               # should be clean, or hold only intentionally-deferred hunks
```

---

## Conventional Commits format (subject)

```
type(scope): subject
```

- **type** (required) — one of:
  - `feat` — a new feature
  - `fix` — a bug fix
  - `docs` — documentation only
  - `style` — formatting, no code-behavior change
  - `refactor` — code change that neither fixes a bug nor adds a feature
  - `perf` — performance improvement
  - `test` — adding or correcting tests
  - `build` — build system or dependencies
  - `ci` — CI configuration
  - `chore` — maintenance, no src/test change
  - `revert` — reverts a previous commit
- **scope** (optional) — lowercase area affected: `auth`, `api`, `deps`.
- **subject** (required) — imperative mood, lowercase start, no trailing period, ≤ ~50 chars.
  - ✅ `feat(auth): add oauth2 pkce flow`
  - ❌ `Added OAuth2 PKCE flow.`

Append `!` after the type/scope for a breaking change: `feat(api)!: drop v1 endpoints`.

## Commit message body format

Separate the subject from the body with a **blank line**. The body is a bullet list — each line
starts with two spaces, an asterisk, and a space (`  * `), and the bullet text is all lowercase.
Include a body when the change isn't self-explanatory; omit it for trivial commits
(e.g. `chore: bump version to 1.2.0`).

```
type(scope): message

  * some body part
  * another body part
```

- **Bullets** — two-space indent, `*` marker, lowercase text: `  * `. Each bullet states one point
  about _why_ the change is needed or the approach taken — not a restatement of the diff. Wrap
  long bullets at ~72 characters.
- **Footer** (optional, after a blank line below the bullets):
  - `BREAKING CHANGE: <description>` for breaking changes.
  - Issue references: `Closes #123`, `Fixes #45`, `Refs PROJ-456`.

Full example:

```
fix(auth): drop the legacy session cookie

  * the old cookie wasn't marked secure, so it leaked over http
  * removing it lets us standardise on the signed jwt path

Closes #123
```

### Good vs. bad bullet

|                     | Bullet                                                                                                       |
| ------------------- | ------------------------------------------------------------------------------------------------------------ |
| ❌ **What-focused** | `  * moves auth logic from middleware to a service class and updates imports`                                |
| ✅ **Why-focused**  | `  * auth logic spread across three middlewares couldn't be unit-tested — a service gives one seam to mock`  |
