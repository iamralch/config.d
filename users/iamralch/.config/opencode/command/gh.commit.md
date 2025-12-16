---
description: Create a git commit with AI-generated conventional commit message.
---

> Follow conversation rules in `@{file:context/cmd.md}`
> Use local git operations as documented in `@{file:context/git.md}`
> Supports `--yes` flag per `@{file:context/cmd.md}#global-flags`

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

---

## 1. Parse Arguments

Extract flags from user input:

| Flag | Variable | Default |
|------|----------|---------|
| `--yes` | `autoApprove` | `false` |
| `--dry-run` | `dryRun` | `false` |
| `--all` / `-a` | `stageAll` | `false` |
| `--amend` | `amendCommit` | `false` |

**Passthrough arguments:**

Any other flags not listed above should be stored as `passthroughArgs` to be passed directly to `git commit`. Common passthrough flags include:

- `--signoff` / `-s`: Add Signed-off-by trailer
- `--no-verify`: Skip pre-commit and commit-msg hooks
- `--allow-empty`: Allow empty commits
- `--author="Name <email>"`: Override author

**Filtered arguments (never pass through):**

- `-m` / `--message`: OpenCode generates the message
- `-F` / `--file`: OpenCode generates the message

**Store parsed values for later use.**

---

## 2. Stage Changes (If Requested)

**If `stageAll` is `true`:**

Per `@{file:context/git.md}#stage-all-tracked-files`:

```bash
git add -u
```

This stages all modifications and deletions of tracked files (the staging behavior of `git commit -a`).

---

## 3. Check for Staged Changes

Per `@{file:context/git.md}#get-staged-changes`:

```bash
git diff --staged
```

**If diff is empty:**
- Display: "No staged changes found. Please stage your changes with `git add` before running `/gh.commit`."
- **STOP**

Store result as `stagedDiff`.

---

## 4. Generate Commit Message

Using `@{file:template/gh.commit.md}`:

1. Follow the **Instructions** section
2. Analyze `stagedDiff` to determine commit type, scope, and content
3. Generate a complete conventional commit message

**Input to provide for generation:**

- Staged diff content (`stagedDiff`)

**Output:** Plain text commit message (subject + blank line + body). No markdown formatting.

---

## 5. Parse Generated Content

Extract from the generated message:

- **`commitSubject`:** First line (the subject)
- **`commitBody`:** Everything after the first blank line (may be empty)
- **`commitMessage`:** Full message (subject + blank line + body)

**Validation:**

| Check | Action |
|-------|--------|
| Subject is empty | Regenerate content |
| Subject exceeds 72 characters | Truncate to 69 characters + `...` |
| Subject contains `<type>`, `<description>`, or bracket placeholder (e.g., `[...]`) | Regenerate content |

---

## 6. Handle Dry Run

**If `dryRun` is `true`:**

Output **ONLY** the following - no additional commentary, logs, todos, or completion messages:

```markdown
**Dry Run - Generated Commit Message**

**Amend:** $amendCommit
**Passthrough Args:** $passthroughArgs (or "None")

<!-- COMMIT_MESSAGE_START -->
$commitMessage
<!-- COMMIT_MESSAGE_END -->
```

**STOP immediately after this output.** Do not follow Command Completion Pattern. Do not add summaries, suggestions, or status messages.

---

## 7. Draft Review

**If `autoApprove` is `true`:** Skip to step 8.

Present the draft following `@{file:context/cmd.md}#draft-review-pattern`:

```markdown
**Here's the commit message draft:**

**Amend:** Yes/No
**Passthrough Args:** $passthroughArgs (or "None")

**Message:**

$commitMessage

---

How would you like to proceed?
- **"yes"** → Create the commit
- **"edit"** → Tell me what to change
- **"cancel"** → Abort without committing
```

**STOP and WAIT** for explicit confirmation.

**If "edit":** Handle per `@{file:context/cmd.md}#draft-review-pattern`.

**If "yes":** Continue to step 8.

**If "cancel":**
- Display: "Cancelled. No commit created."
- Follow the **Command Completion Pattern** in `@{file:context/cmd.md}`.

**NEVER create the commit without explicit "yes" (unless `--yes` flag).**

---

## 8. Create Commit

Build the commit command:

**If `amendCommit` is `true`:**

Per `@{file:context/git.md}#amend-previous-commit`:

```bash
git commit --amend -m "$commitMessage" $passthroughArgs
```

**Otherwise:**

Per `@{file:context/git.md}#create-commit`:

```bash
git commit -m "$commitMessage" $passthroughArgs
```

**Handle the response:**

**If success:**
- Extract the commit hash from output (typically shown as `[branch hash] message`)
- Continue to step 9

**If error:**
- Display the error message
- Common errors:
  - "nothing to commit" → No staged changes (should be caught in step 3)
  - "pre-commit hook failed" → Hook rejected the commit; suggest `--no-verify` to bypass
  - "commit-msg hook failed" → Hook rejected the message; suggest editing or `--no-verify`
- **STOP**

---

## 9. Report Success

**If `amendCommit` is `true`:**

```markdown
**Amended commit:** $commitSubject

**Full message:**

```text
$commitMessage
```

**Next steps:**
- Use `git push --force` if the commit was already pushed
- Continue working or create a PR
```

**Otherwise:**

```markdown
**Created commit:** $commitSubject

**Full message:**

```text
$commitMessage
```

**Next steps:**
- Push with `git push` when ready
- Continue working or create a PR
```

Follow the **Command Completion Pattern** in `@{file:context/cmd.md}`.
