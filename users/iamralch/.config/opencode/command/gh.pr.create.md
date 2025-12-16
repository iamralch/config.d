---
description: Create a GitHub Pull Request with auto-generated description from git changes.
---

> Follow conversation rules in `@{file:context/cmd.md}`
> Use GitHub MCP tools as documented in `@{file:context/mcp.md}`
> Use local git operations as documented in `@{file:context/git.md}`
> Supports `--yes` flag per `@{file:context/cmd.md}#global-flags`

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

---

## 1. Validate Repository

Follow the **Repository Validation Workflow** in `@{file:context/git.md}`.

**After validation, you have:** `username`, `owner`, `repo`

**If validation fails:** Display the error and **STOP**.

---

## 2. Parse Arguments

Extract flags from user input:

| Flag | Variable | Default |
|------|----------|---------|
| `--base <branch>` | `baseBranch` | Repository default branch |
| `--head <branch>` | `headBranch` | Current branch |
| `--draft` | `isDraft` | `false` |
| `--yes` | `autoApprove` | `false` |
| `--dry-run` | `dryRun` | `false` |

**Store parsed values for later use.**

---

## 3. Determine Branches

### 3a. Get Head Branch

**If `--head` was provided:**
- Use the provided value as `headBranch`

**Otherwise:**
- Get current branch per `@{file:context/git.md}#get-current-branch`
- Store result as `headBranch`

**If `headBranch` is empty** (detached HEAD state):
- Display: "Cannot create PR from detached HEAD. Please checkout a branch."
- **STOP**

### 3b. Get Base Branch

**If `--base` was provided:**
- Use the provided value as `baseBranch`

**Otherwise:**
- Get default branch per `@{file:context/git.md}#get-default-branch`
- Store result as `baseBranch`

### 3c. Validate Branches Are Different

**If `headBranch` equals `baseBranch`:**
- Display: "Head branch and base branch cannot be the same ('`$headBranch`')."
- **STOP**

---

## 4. Validate Remote State

### 4a. Fetch Latest

Per `@{file:context/git.md}#fetch-latest-from-remote`:

```bash
git fetch origin
```

### 4b. Check Base Branch Exists on Remote

Per `@{file:context/git.md}#check-if-branch-exists-on-remote`:

**If fails:**
- Display: "Base branch '`$baseBranch`' not found on remote."
- **STOP**

### 4c. Check Head Branch Is Pushed

Per `@{file:context/git.md}#check-if-branch-exists-on-remote`:

**If fails** (branch not on remote):
- Display: "Branch '`$headBranch`' has not been pushed to remote."
- **If `autoApprove` is `true`:**
  - Push per `@{file:context/git.md}#push-branch-with-upstream`
  - If push fails → Display error and **STOP**
- **Otherwise:**
  - Ask: "Would you like to push it now? (yes/no)"
  - **STOP and WAIT**
  - If "yes" → Push per `@{file:context/git.md}#push-branch-with-upstream`
  - If "no" → Display: "Please push the branch manually and try again." **STOP**

### 4d. Check for Existing PR

Per `@{file:context/git.md}#check-for-existing-pull-request`:

**If a PR already exists:**
- Display: "An open PR already exists for '`$headBranch`' → '`$baseBranch`':"
- Display: "  **#[number]** [title]"
- Display: "  URL: [url]"
- **STOP**

---

## 5. Get Git Changes

### 5a. Get Diff

Per `@{file:context/git.md}#get-diff-between-branches`:

**If diff is empty:**
- Display: "No changes between '`$headBranch`' and '`$baseBranch`'. Nothing to create a PR for."
- **STOP**

Store result as `diffContent`.

### 5b. Get Commit Log

Per `@{file:context/git.md}#get-commit-log-between-branches`:

Store result as `commitLog`.

---

## 6. Generate PR Content

Using `@{file:template/gh.pr.create.md}`:

1. Follow the **Instructions** section
2. Use the **PR Body Structure** as the output template
3. Fill all sections based on `diffContent` and `commitLog`

**Input to provide for generation:**

- Git diff content (`diffContent`) showing all changes between branches
- Commit log (`commitLog`) showing commit messages for context

**Output:** Complete markdown starting with `# [Title]` line, with all HTML comments replaced by actual content.

---

## 7. Parse Generated Content

Extract title and body from the generated markdown:

- **`prTitle`:** First line with `# ` prefix removed (trim whitespace)
- **`prBody`:** Everything after the first line (skip leading blank lines)

**Validation:**

| Check | Action |
|-------|--------|
| Title is empty | Regenerate content |
| Title contains `[PR Title` or `[Title]` | Regenerate content (placeholder not replaced) |
| Title exceeds 72 characters | Use first 69 characters + `...` as title; prepend full title to body as: `**Full title:** [original title]` followed by blank line |

---

## 8. Handle Dry Run

**If `dryRun` is `true`:**

Output **ONLY** the following - no additional commentary, logs, todos, or completion messages:

```markdown
**Dry Run - Generated PR Content**

**Base:** $baseBranch
**Head:** $headBranch
**Draft:** $isDraft

<!-- PR_CONTENT_START -->
# $prTitle

$prBody
<!-- PR_CONTENT_END -->
```

**STOP immediately after this output.** Do not follow Command Completion Pattern. Do not add summaries, suggestions, or status messages.

---

## 9. Draft Review

**If `autoApprove` is `true`:** Skip to step 10.

Present the draft following `@{file:context/cmd.md}#draft-review-pattern`:

```markdown
**Here's the Pull Request draft:**

**Branches:** $headBranch → $baseBranch
**Draft:** Yes/No

**Title:** $prTitle

**Body:**

$prBody

---

How would you like to proceed?
- **"yes"** → Create the Pull Request
- **"edit"** → Tell me what to change
- **"cancel"** → Abort without creating
```

**STOP and WAIT** for explicit confirmation.

**If "edit":** Handle per `@{file:context/cmd.md}#draft-review-pattern`.

**If "yes":** Continue to step 10.

**If "cancel":**
- Display: "Cancelled. No pull request created."
- Follow the **Command Completion Pattern** in `@{file:context/cmd.md}`.

**NEVER create the PR without explicit "yes" (unless `--yes` flag).**

---

## 10. Create Pull Request

Call `github_create_pull_request` with:
- owner: `owner`
- repo: `repo`
- title: `prTitle`
- body: `prBody`
- head: `headBranch`
- base: `baseBranch`
- draft: `isDraft`

**Handle the response:**

**If success:**
- Extract from response:
  - `prNumber` - the PR number
  - `prUrl` - the PR URL
- Continue to step 11

**If error:**
- Display the error message
- Suggest remediation per `@{file:context/git.md}#common-errors`
- **STOP**

---

## 11. Report Success

**If `isDraft` is `true`:**

```markdown
**Created Draft Pull Request #$prNumber:** $prTitle

**URL:** $prUrl

**Branches:** $headBranch → $baseBranch
**Status:** Draft

**Next steps:**
- Review the PR on GitHub
- Mark as "Ready for review" when complete
```

**Otherwise:**

```markdown
**Created Pull Request #$prNumber:** $prTitle

**URL:** $prUrl

**Branches:** $headBranch → $baseBranch
**Status:** Ready for review

**Next steps:**
- Review the PR on GitHub
- Request reviewers when ready
```

Follow the **Command Completion Pattern** in `@{file:context/cmd.md}`.
