# Git Guardrails for Claude Code

PreToolUse hook that intercepts and blocks dangerous git commands before Claude executes them.

## Directory Structure

```
skills/git-guardrails-claude-code/
├── SKILL.md                              # Setup guide and full documentation
├── README.md                             # This file
└── scripts/
    └── block-dangerous-git.sh            # Hook script (PreToolUse)
```

## What Gets Blocked

| Pattern | Example |
|---------|---------|
| `git push` | `git push origin main`, `git push --force` |
| `git reset --hard` | `git reset --hard HEAD~1` |
| `git clean -f` / `-fd` | `git clean -fd` |
| `git branch -D` | `git branch -D feature-branch` |
| `git checkout .` | `git checkout .` |
| `git restore .` | `git restore .` |

When a command is blocked, Claude sees: `BLOCKED: command matches dangerous pattern '...'. The user has prevented you from doing this.`

## Smart Commit Workflow

All `git commit` invocations are intercepted. Only two variants pass through:

| Variant | Command | Use Case |
|---------|---------|----------|
| **Fixup** | `git commit --fixup=HEAD` | Amend the last commit |
| **File** | `git commit -F <file>` | Commit with a user-edited message file |

Everything else (including `git commit -m "..."`) is blocked. When blocked, Claude **must ask the user first** and wait for their choice before running any commit command:

1. **Ask the user**: "Would you like a fixup commit or a new commit?" — do NOT proceed without an explicit answer
2. **Fixup** — run `git commit --fixup=HEAD`
3. **New commit** — create a temp file with the proposed message, ask the user to review/edit it, then run `git commit -F <tempfile>` after confirmation

## Prerequisites

- **`jq`** — required for JSON parsing. If missing, the hook fails closed (blocks all commands) to prevent bypassing guardrails.
  - macOS: `brew install jq`
  - Ubuntu: `apt-get install jq`
  - Alpine: `apk add jq`

## Quick Start

1. **Choose scope** — project-level (`.claude/settings.json`) or global (`~/.claude/settings.json`)
2. **Copy the script** to the target location:
   - Project: `.claude/hooks/block-dangerous-git.sh`
   - Global: `~/.claude/hooks/block-dangerous-git.sh`
3. **Make it executable**: `chmod +x <path-to-script>`
4. **Add the hook** to the appropriate settings file:

   **Project** (`.claude/settings.json`):

   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Bash",
           "hooks": [
             {
               "type": "command",
               "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/block-dangerous-git.sh"
             }
           ]
         }
       ]
     }
   }
   ```

   **Global** (`~/.claude/settings.json`):

   ```json
   {
     "hooks": {
       "PreToolUse": [
         {
           "matcher": "Bash",
           "hooks": [
             {
               "type": "command",
               "command": "~/.claude/hooks/block-dangerous-git.sh"
             }
           ]
         }
       ]
     }
   }
   ```

5. **Verify** — see [Verification](#verification) below

## Customization

Edit the `DANGEROUS_PATTERNS` array in the copied script to add or remove patterns:

```bash
DANGEROUS_PATTERNS=(
  "git push"
  "git reset --hard"
  "git clean -f"
  "git clean -fd"
  "git branch -D"
  '(^|[[:space:]])git[[:space:]]+checkout([[:space:]]+--)?[[:space:]]+\.([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+restore([[:space:]]+--)?[[:space:]]+\.([[:space:]]|$)'
)
```

Each entry is a regex matched against the full command string via `grep -qE`.

## Verification

Replace `<path-to-script>` with your install location (`.claude/hooks/block-dangerous-git.sh` or `~/.claude/hooks/block-dangerous-git.sh`).

Test that blocking works:

```bash
echo '{"tool_input":{"command":"git push origin main"}}' | <path-to-script>
# Expected: exit code 2, stderr: BLOCKED: command matches dangerous pattern 'git push'...
```

Test that safe commands pass through:

```bash
echo '{"tool_input":{"command":"git status"}}' | <path-to-script>
# Expected: exit code 0, no output
```

Test commit interception:

```bash
echo '{"tool_input":{"command":"git commit -m \"feat: something\""}}' | <path-to-script>
# Expected: exit code 2, stderr: BLOCKED: Direct git commit is not allowed...
```

```bash
echo '{"tool_input":{"command":"git commit --fixup=HEAD"}}' | <path-to-script>
# Expected: exit code 0, no output
```

## Full Reference

See [SKILL.md](./SKILL.md) for the full step-by-step setup guide including scope selection, settings file merging, and customization prompts.
