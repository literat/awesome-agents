---
name: git-guardrails-claude-code
description: Set up Claude Code hooks to block dangerous git commands (push, reset --hard, clean, branch -D, etc.) before they execute. Use when user wants to prevent destructive git operations, add git safety hooks, or block git push/reset in Claude Code.
---

# Setup Git Guardrails

Sets up a PreToolUse hook that intercepts and blocks dangerous git commands before Claude executes them.

## What Gets Blocked

- `git reset --hard`
- `git clean -f` / `git clean -fd`
- `git branch -D`
- `git checkout .` / `git restore .`

When blocked, Claude sees a message telling it that it does not have authority to access these commands.

## Smart Push Workflow

`git push` is never silently executed. Instead, the hook intercepts every push and requires explicit user confirmation:

1. **Ask the user**: "Should I push these changes?" — **do NOT proceed without an explicit answer**
2. After the user confirms, run the push with a confirmation marker:
   ```bash
   GIT_PUSH_CONFIRMED=1 git push [original push arguments]
   ```

The hook recognises the `GIT_PUSH_CONFIRMED=1` prefix and allows the push through.

## Smart Commit Workflow

The hook also intercepts `git commit` commands to ensure meaningful commit messages. Instead of allowing Claude to commit directly with `-m`, it enforces one of two workflows:

### Allowed commit variants (pass through)

- `git commit --fixup=HEAD` — fixup/amend workflow
- `git commit -F <file>` / `git commit --file=<file>` — commit from a user-edited message file

### Blocked (everything else)

All other `git commit` invocations are blocked. When blocked, Claude **MUST ask the user first** and wait for their choice before running any commit command:

1. **Ask the user**: "Would you like a fixup commit or a new commit?" — **do NOT proceed without an explicit answer**
2. **Fixup** → run `git commit --fixup=HEAD`
3. **New commit** →
   - Create a unique temp file via `mktemp` and write the proposed message to it
   - Tell the user to edit it in their editor
   - Wait for user confirmation
   - Run `git commit -F <tempfile>`

## Steps

### 1. Ask scope

Ask the user: install for **this project only** (`.claude/settings.json`) or **all projects** (`~/.claude/settings.json`)?

### 2. Prerequisites

The hook script requires `jq` for JSON parsing. If `jq` is not installed, the hook will fail closed (blocking all commands) to prevent bypassing guardrails.

### 3. Copy the hook script

The bundled script is at: [scripts/block-dangerous-git.sh](scripts/block-dangerous-git.sh)

Copy it to the target location based on scope:

- **Project**: `.claude/hooks/block-dangerous-git.sh`
- **Global**: `~/.claude/hooks/block-dangerous-git.sh`

Make it executable with `chmod +x`.

### 4. Add hook to settings

Add to the appropriate settings file:

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

If the settings file already exists, merge the hook into existing `hooks.PreToolUse` array — don't overwrite other settings.

### 5. Ask about customization

Ask if user wants to add or remove any patterns from the blocked list. Edit the copied script accordingly.

### 6. Verify

Run quick tests:

```bash
# Should exit 2 and print a BLOCKED/confirmation message
echo '{"tool_input":{"command":"git push origin main"}}' | <path-to-script>

# Should exit 0 (user confirmed)
echo '{"tool_input":{"command":"GIT_PUSH_CONFIRMED=1 git push origin main"}}' | <path-to-script>

# Dangerous commands should still exit 2
echo '{"tool_input":{"command":"git reset --hard HEAD~1"}}' | <path-to-script>
```
