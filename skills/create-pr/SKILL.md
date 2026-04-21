---
name: create-pr
description: Create or update a GitHub PR for the current branch. Checks gh CLI, discovers the repo's PR template, drafts a short why-first description from branch changes and conversation context, asks for any missing info, then creates or updates the PR via gh CLI.
---

# Create PR

Create or update a GitHub pull request for the current branch. Check prerequisites, discover the PR template, gather context, draft a reviewer-focused description interactively, then apply via `gh` CLI.

## Principles

- **Lead with why, not what.** The reviewer can read the diff. Explain the problem or context that drove the change.
- **Be short and sharp.** The description should let a reviewer orient themselves in under 30 seconds.
- **Help reviewers, not bots.** Add links, edge-case notes, and anything that speeds up review — not summaries of what the code does.
- **Follow the repo's template.** Discover and use the project's PR template as the structural skeleton.
- **No AI attribution.** Do not add "Generated with Claude Code" or similar.

---

## Workflow

### Step 0: Check Prerequisites

Run both checks before proceeding:

```bash
# Verify gh CLI is installed before checking authentication
if command -v gh >/dev/null 2>&1; then
  gh auth status 2>&1
else
  echo "GH_NOT_FOUND"
  exit 1
fi
```

- If `gh` is not installed: tell the user to install it from https://cli.github.com and stop.
- If not authenticated: tell the user to run `gh auth login` and stop.

### Step 1: Gather Context

Run these in parallel:

```bash
# Determine default branch (origin/main, origin/master, or whatever the remote uses)
git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null

# Commits ahead of default branch
git log $(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)..HEAD --oneline

# Diff against default branch (exclude lock files)
git diff $(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)..HEAD -- . ':(exclude)*.lock' ':(exclude)package-lock.json' ':(exclude)yarn.lock' ':(exclude)pnpm-lock.yaml'

# Existing PR for this branch
gh pr view --json number,title,body,url,state 2>/dev/null || echo "NO_PR"
```

Also note from the current conversation: what problem did the user describe? What was decided and why? Any issue IDs, links, or constraints mentioned?

Extract any linked issue from:
1. Branch name (e.g. `feat/123-...`, `fix/GH-456-...`, `DS-789-...`)
2. Commit messages (`#123`, `closes #456`, `fixes PROJ-789`)
3. Conversation context

### Step 2: Discover PR Template

Check for a PR template in this order:

```bash
# Single-template locations (check in order, use the first match)
for path in \
  ".github/PULL_REQUEST_TEMPLATE.md" \
  ".github/pull_request_template.md" \
  "docs/pull_request_template.md" \
  "PULL_REQUEST_TEMPLATE.md"; do
  [ -f "$path" ] && cat "$path" && break
done

# Multi-template directory (list available templates)
ls .github/PULL_REQUEST_TEMPLATE/ 2>/dev/null
```

**If a template is found:** use it as the structural skeleton for the description. Preserve all section headings and placeholder comments.

**If no template is found:** use this fallback:

```markdown
## Description

{why the change was needed; what was changed and why that approach}

### Additional context

{links, edge cases, demo URLs, deferred follow-ups — omit section if nothing to add}

### Related issues

{link to related issues, tickets, or discussions — omit if none}
```

**If multiple templates exist** (`.github/PULL_REQUEST_TEMPLATE/` directory): use `AskUserQuestion` to let the user pick which template applies to this PR.

### Step 3: Check PR State

**If a PR exists:**

- Read its current `body`.
- Identify what is missing or stale:
  - Is the Description section empty or just a what-summary?
  - Is the Additional context section missing something reviewers need?
  - Is the issue reference a placeholder or missing?
- Note the gaps — you will fill them in the draft.

**If no PR exists:**

- You will create one. Derive the PR title from the branch name or top commit:
  - Format: `type(scope): description` (all lowercase, max 100 chars, imperative mood)
  - Example: `feat(auth): add oauth2 pkce flow`

### Step 4: Ask for Missing Issue Reference

If no issue was found (branch, commits, and conversation all lack one), use `AskUserQuestion` to ask:

> "What is the issue URL or number for this PR? (e.g. https://github.com/org/repo/issues/123) — or type 'none' to skip."

Do not proceed to drafting until you have the answer.

### Step 5: Draft the Description

Fill the discovered template sections:

**Description** (required, 2–5 sentences max):

- First sentence: the _problem or gap_ that made this change necessary.
- Second sentence: what was changed and why that specific approach was chosen over alternatives.
- Optional third sentence: a non-obvious trade-off, constraint, or follow-up that is out of scope.

**Additional context** (optional):

- Include only if there is something specific reviewers should scrutinize: a tricky edge case, a deliberate deviation from convention, a dependency on another PR, a demo URL, or a follow-up intentionally deferred.
- Omit the section entirely if there is nothing worth flagging.

**Issue reference / Related issues:**

- Full URL to the issue or ticket (GitHub, Linear, Jira, etc.)
- If none, leave the placeholder comment as-is.

### Step 6: Present for Review

Use `AskUserQuestion` with a single-select. Set the full draft as the `preview` of the first option so it renders side-by-side with the choices:

- **Apply it** (preview: full draft text) — create or update the PR with this description
- **Edit first** — user will provide changes, then re-apply
- **Discard** — do not touch the PR

The preview field renders markdown — format the draft exactly as it will appear in the PR body.

### Step 7: Create or Update the PR

**If PR already exists**, update its body (and title if it was auto-generated and looks like a branch name):

```bash
gh pr edit <number> --body "$(cat <<'EOF'
<approved description>
EOF
)"
```

**If no PR exists**, create it:

```bash
gh pr create \
  --title "<derived title>" \
  --body "$(cat <<'EOF'
<approved description>
EOF
)" \
  --base <default-branch>
```

Add `--draft` only if the user explicitly asked for a draft PR.

After the command succeeds, print the PR URL.

---

## Good vs Bad Examples

|                     | Description                                                                                                                                                                                        |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ❌ **What-focused** | "Adds an explicit ordering rule and a counter-example to the finding format section."                                                                                                              |
| ✅ **Why-focused**  | "The linter was placing suggestion blocks after the explanation despite the instructions saying to put them first — the rule was buried in a dependent clause with no negative example to anchor it." |
| ❌ **What-focused** | "Moves auth logic from middleware to a service class."                                                                                                                                             |
| ✅ **Why-focused**  | "Auth logic scattered across three middlewares made it impossible to unit test in isolation — extracting it into a service gave us a single seam to mock and cut test setup from 80 lines to 12." |

Keep the description to the point. If you find yourself listing more than three bullet points, focus on top-level intent instead.
