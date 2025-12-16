# Command Standards

Shared standards for all `/gh.*` commands.

---

## Conversation Rules

> **THIS IS A CONVERSATION, NOT A SCRIPT.**

- Ask **ONE question at a time**
- **STOP and WAIT** for user response before proceeding
- **NEVER** assume or infer missing information
- **NEVER** batch multiple questions together
- **NEVER** create or modify GitHub resources without explicit confirmation

### STOP vs STOP and WAIT

| Directive | Meaning |
|-----------|---------|
| **STOP** | End the command entirely. Do not proceed further. |
| **STOP and WAIT** | Pause execution and wait for user input before continuing. |

---

## Draft Review Pattern

Before creating any GitHub resource (Issue, Pull Request, Comment), show a draft for review.

**Format:**
```markdown
**Here's the [Resource Type] draft:**

**Title:** [Generated title]  ← (omit if resource has no title, e.g., body-only updates)

**Body:**
[Generated body content]

---

How would you like to proceed?
- **"yes"** → Create the [Resource]
- **"edit"** → Tell me what to change
- **"cancel"** → Abort without creating
```

**Rules:**
- **STOP and WAIT** for explicit confirmation
- Standard responses: "yes", "edit", or "cancel" (some commands offer additional options)
- **NEVER** create without explicit "yes"

**If user says "edit":**
1. Ask: "What would you like to change?"
2. **STOP and WAIT** for their response
3. Apply only the requested changes
4. Re-present the updated draft
5. **STOP and WAIT** again for confirmation

---

## Q&A Rules

When asking clarifying questions, follow the **Information Gathering Pattern** in `@{file:context/pmp.md}` (includes Q&A depth, answer validation, and common questions by type).

---

## Global Flags

All `/gh.*` commands support these flags:

### `--yes`

Skip all confirmation prompts. Automatically approves:
- Draft reviews (proceeds as if user said "yes")
- Push confirmations
- Merge/close confirmations
- Branch creation confirmations

**Does NOT skip:**
- **Validation errors** - Authentication failures, missing repositories, invalid issue numbers
- **Blocking conditions** - Uncommitted changes that prevent branch operations, missing required data
- **Q&A questions** - Clarifying questions during issue creation/editing
- **Confirmations that require user judgment** - Branch switching, pulling changes

**Note:** Some warnings are informational only (e.g., "Your branch is behind remote") and don't block progress. Users can address these conversationally.

### Flag Effects by Command

| Command | `--yes` skips |
|---------|---------------|
| `/gh.commit` | Draft review confirmation |
| `/gh.issue.create` | Draft review confirmation |
| `/gh.issue.edit` | Draft review confirmation |
| `/gh.issue.develop` | Draft review, push confirmation |
| `/gh.issue.status` | *(none - read-only command)* |
| `/gh.issue.work` | Task confirmations |
| `/gh.pr.create` | Draft review, push confirmation |
| `/gh.pr.review` | Draft review, event mismatch confirmation |

---

## Common Command Patterns

These patterns appear across multiple commands. Reference them instead of duplicating.

### Command Header Pattern

All command files start with this header:

```markdown
> Follow conversation rules in `@{file:context/cmd.md}`
> Use GitHub MCP tools as documented in `@{file:context/mcp.md}`
> Use local git operations as documented in `@{file:context/git.md}`
```

Add this line if the command supports `--yes` flag:
```markdown
> Supports `--yes` flag per `@{file:context/cmd.md}#global-flags`
```

### Parse Issue Number Pattern

For commands that work with Issues:

```markdown
## Parse Issue Number

Extract issue number from user input:
- If `$ARGUMENTS` contains `#[N]` → use `N`
- If `$ARGUMENTS` contains only digits → use that number
- If `$ARGUMENTS` contains a GitHub issue URL (`https://github.com/owner/repo/issues/N`) → extract `N`
- If `$ARGUMENTS` is empty → **STOP and prompt:**

\```markdown
**Which Issue?**

Please provide the Issue number (e.g., `#123` or `123`):
\```

Store the parsed number as `issueNumber`.
```

---

## Command Completion Pattern

All commands MUST end with this pattern to prevent unwanted automatic continuation:

```markdown
**Command complete.**

> ⛔ **DO NOT CONTINUE AUTOMATICALLY**
> 
> - Do NOT run any other commands
> - Do NOT begin implementing tasks
> - Do NOT suggest next actions beyond what's listed above

**STOP** - The command is finished. Return control to the user.
```

**When to use:**
- At the end of EVERY command file
- After completing the command's primary objective
- Before listing "What you can do next" suggestions

**Customization:**
- Adjust the bullet points based on the specific command
- Keep the core message: "STOP - command is finished"
