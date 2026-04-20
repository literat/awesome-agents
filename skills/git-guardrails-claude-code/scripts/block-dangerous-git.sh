#!/bin/bash

INPUT=$(cat)

# Ensure jq is available; if not, fail closed to avoid bypassing guardrails
if ! command -v jq >/dev/null 2>&1; then
  echo "BLOCKED: Required dependency 'jq' is not installed; cannot safely analyze git command." >&2
  exit 2
fi

# Extract the command from JSON; on parse failure, also fail closed
COMMAND=$(echo "$INPUT" | jq -er '.tool_input.command') || {
  echo "BLOCKED: Failed to parse git command from input JSON; refusing to run potentially dangerous operation." >&2
  exit 2
}

# --- Smart Commit Interception ---
# Intercept `git commit` to enforce fixup or user-edited message workflow.
# Allow: --fixup=, -F, --file= (user already chose a workflow)
# Block: everything else (especially `git commit -m "..."`)
if echo "$COMMAND" | grep -qE '(^|[[:space:]])git commit([[:space:]]|$)'; then
  if echo "$COMMAND" | grep -qE '(--fixup=|-F[[:space:]]|-F$|--file=)'; then
    exit 0
  fi
  cat >&2 <<'COMMIT_MSG'
BLOCKED: Direct git commit is not allowed.

IMPORTANT: You MUST ask the user which workflow they prefer BEFORE running any commit command. Do NOT commit without explicit user choice.

Available workflows:

1. **Fixup (amend) the last commit:**
   Run: git commit --fixup=HEAD

2. **New commit with a user-edited message:**
   a. Create a temp file with a unique name and write the proposed message:
      TMPFILE=$(mktemp /tmp/commit-msg.XXXXXX)
      echo "feat: your message here" > "$TMPFILE"
   b. Tell the user to edit it:
      "Please review and edit the commit message in $TMPFILE, then confirm when ready."
   c. After user confirms, run:
      git commit -F "$TMPFILE"

Ask the user: "Would you like a fixup commit or a new commit?" and WAIT for their response before proceeding.
COMMIT_MSG
  exit 2
fi

# --- Smart Push Interception ---
# Intercept `git push` to require explicit user confirmation before pushing.
# Allow: commands prefixed with GIT_PUSH_CONFIRMED=1 (signals user said yes)
# Block: everything else
if echo "$COMMAND" | grep -qE '(^|[[:space:]])git push([[:space:]]|$)'; then
  if echo "$COMMAND" | grep -q 'GIT_PUSH_CONFIRMED=1'; then
    exit 0
  fi
  cat >&2 <<'PUSH_MSG'
BLOCKED: git push requires explicit user confirmation.

IMPORTANT: You MUST ask the user for confirmation BEFORE pushing. Do NOT push without an explicit answer.

Ask the user: "Should I push these changes?" and WAIT for their response.

After the user confirms, run the push with the confirmation marker:
  GIT_PUSH_CONFIRMED=1 git push [your original push arguments]

Do NOT proceed without explicit user confirmation.
PUSH_MSG
  exit 2
fi

DANGEROUS_PATTERNS=(
  "git reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  '(^|[[:space:]])git[[:space:]]+checkout([[:space:]]+--)?[[:space:]]+\.([[:space:]]|$)'
  '(^|[[:space:]])git[[:space:]]+restore([[:space:]]+--)?[[:space:]]+\.([[:space:]]|$)'
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: command matches dangerous pattern '$pattern'. The user has prevented you from doing this." >&2
    exit 2
  fi
done

exit 0
