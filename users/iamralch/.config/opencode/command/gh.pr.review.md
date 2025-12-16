---
description: Review a GitHub Pull Request with AI-generated analysis.
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

### 2a. Parse PR Number (Required)

Extract PR number from user input:

- If contains `#[N]` → use `N`
- If contains only digits → use that number
- If contains GitHub PR URL (`https://github.com/owner/repo/pull/N`) → extract `N`
- If empty or not found → **STOP and prompt:**

```markdown
**Which Pull Request?**

Please provide the PR number (e.g., `#123` or `123`):
```

Store as `prNumber`.

### 2b. Parse Flags

| Flag | Variable | Default |
|------|----------|---------|
| `--approve` | `reviewEvent = "APPROVE"` | - |
| `--request-changes` | `reviewEvent = "REQUEST_CHANGES"` | - |
| `--comment` | `reviewEvent = "COMMENT"` | - |
| `--yes` | `autoApprove` | `false` |
| `--dry-run` | `dryRun` | `false` |

**Event flag behavior:**

| Flags Provided | `reviewEvent` | `explicitEvent` | Behavior |
|----------------|---------------|-----------------|----------|
| None | `null` | `false` | Use analysis outcome |
| `--comment` | `"COMMENT"` | `false` | Use analysis outcome (`--comment` is default, same as no flag) |
| `--approve` | `"APPROVE"` | `true` | Force APPROVE, warn if analysis suggests otherwise |
| `--request-changes` | `"REQUEST_CHANGES"` | `true` | Force REQUEST_CHANGES, warn if analysis suggests otherwise |

**If multiple event flags provided:**
- Display: "Cannot use `--approve`, `--request-changes`, and `--comment` together. Choose one."
- **STOP**

---

## 3. Fetch PR Details

Call `github_pull_request_read` with:
- method: `"get"`
- owner: `owner`
- repo: `repo`
- pullNumber: `prNumber`

**If PR not found:**
- Display: "Pull Request #`$prNumber` not found in `$owner`/`$repo`"
- **STOP**

**If PR is not open:**
- Display: "Pull Request #`$prNumber` is `$state`. Can only review open PRs."
- **STOP**

Store: `prTitle`, `prState`, `prUrl`, `headBranch`, `baseBranch`

---

## 4. Get PR Diff

Call `github_pull_request_read` with:
- method: `"get_diff"`
- owner: `owner`
- repo: `repo`
- pullNumber: `prNumber`

**If diff is empty:**
- Display: "No changes found in PR #`$prNumber`."
- **STOP**

Store result as `diffContent`.

---

## 5. Generate Review Content

Using `@{file:template/gh.pr.review.md}`:

1. Follow the **Instructions** section
2. Use the **Review Body Structure** as the output template
3. Analyze `diffContent` and fill all sections

**Input to provide for generation:**

- PR diff content (`diffContent`)
- PR metadata: title (`prTitle`), head branch (`headBranch`), base branch (`baseBranch`)

**Output:** Complete review markdown starting with `## Summary & Outcome`.

---

## 6. Parse Generated Content

Extract from the generated review:

- **`reviewOutcome`:** Value after "**Outcome:**" - must be `Approve`, `Request Changes`, or `Comment`
- **`reviewBody`:** The full generated content

**Validation:**

| Check | Action |
|-------|--------|
| Outcome is empty | Regenerate content |
| Outcome is not `Approve`, `Request Changes`, or `Comment` | Regenerate content |

**Map outcome to API event:**

| Outcome | API Event |
|---------|-----------|
| `Approve` | `APPROVE` |
| `Request Changes` | `REQUEST_CHANGES` |
| `Comment` | `COMMENT` |

Store mapped value as `generatedEvent`.

---

## 7. Determine Final Review Event

**If `dryRun` is `true`:**
- Set `reviewEvent = generatedEvent` (use analysis outcome for dry-run preview)
- Continue to Step 8

**If `explicitEvent` is `true` (user provided `--approve` or `--request-changes`):**

Compare `reviewEvent` (from flag) with `generatedEvent` (from analysis):

**If they match:** Continue with `reviewEvent`.

**If they don't match:**

**If `autoApprove` is `true`:**
- Use `reviewEvent` from flag (auto-override, no prompt)
- Continue to Step 9

**Otherwise:**

```markdown
**Review outcome mismatch**

You requested: **$reviewEvent**
Analysis suggests: **$generatedEvent**

The review analysis found issues that don't match your requested outcome.

How would you like to proceed?
- **"override"** → Submit as $reviewEvent anyway
- **"use-analysis"** → Submit as $generatedEvent
- **"cancel"** → Abort without submitting
```

**STOP and WAIT**

- If "override" → Keep `reviewEvent` from flag
- If "use-analysis" → Set `reviewEvent = generatedEvent`
- If "cancel" → Display: "Cancelled. No review submitted." **STOP**

**If `explicitEvent` is `false` (no event flag or `--comment`):**

Set `reviewEvent = generatedEvent` (use analysis outcome).

---

## 8. Handle Dry Run

**If `dryRun` is `true`:**

Output **ONLY** the following - no additional commentary, logs, todos, or completion messages:

```markdown
**Dry Run - Generated PR Review**

**PR:** #$prNumber - $prTitle
**Event:** $reviewEvent

<!-- REVIEW_CONTENT_START -->
$reviewBody
<!-- REVIEW_CONTENT_END -->
```

**STOP immediately after this output.** Do not follow Command Completion Pattern. Do not add summaries, suggestions, or status messages.

---

## 9. Draft Review

**If `autoApprove` is `true`:** Skip to step 10.

Present the draft following `@{file:context/cmd.md}#draft-review-pattern`:

```markdown
**Here's the Pull Request Review draft:**

**PR:** #$prNumber - $prTitle
**URL:** $prUrl
**Action:** $reviewEvent

**Review Body:**

$reviewBody

---

How would you like to proceed?
- **"yes"** → Submit the Review
- **"edit"** → Tell me what to change
- **"cancel"** → Abort without submitting
```

**STOP and WAIT** for explicit confirmation.

**If "edit":** Handle per `@{file:context/cmd.md}#draft-review-pattern`.

**If "yes":** Continue to step 10.

**If "cancel":**
- Display: "Cancelled. No review submitted."
- Follow the **Command Completion Pattern** in `@{file:context/cmd.md}`.

**NEVER submit the review without explicit "yes" (unless `--yes` flag).**

---

## 10. Submit Review

Call `github_pull_request_review_write` with:
- method: `"create"`
- owner: `owner`
- repo: `repo`
- pullNumber: `prNumber`
- body: `reviewBody`
- event: `reviewEvent`

**Handle the response:**

**If success:**
- Continue to step 11

**If error:**
- Display the error message
- Common errors:
  - "Cannot approve your own pull request" → You can only comment on your own PRs
  - "Pull request review thread is outdated" → PR has new commits since diff was fetched
- **STOP**

---

## 11. Report Success

**If `reviewEvent` is `"APPROVE"`:**

```markdown
**Approved Pull Request #$prNumber:** $prTitle

**URL:** $prUrl

**Next steps:**
- PR is ready to merge (if all checks pass)
```

**If `reviewEvent` is `"REQUEST_CHANGES"`:**

```markdown
**Requested Changes on Pull Request #$prNumber:** $prTitle

**URL:** $prUrl

**Next steps:**
- Author should address the requested changes
- Re-review after changes are made
```

**If `reviewEvent` is `"COMMENT"`:**

```markdown
**Commented on Pull Request #$prNumber:** $prTitle

**URL:** $prUrl

**Next steps:**
- Review feedback has been shared
- No blocking changes requested
```

Follow the **Command Completion Pattern** in `@{file:context/cmd.md}`.
