---
description: Start work on a GitHub Issue by creating a branch, generating an implementation plan, and creating a draft PR.
agent: dev
---

> Use GitHub MCP tools as documented in `@{file:context/mcp.md}`
> Use local git operations as documented in `@{file:context/git.md}`
> For sub-issue checks, use `@{file:context/pmp.md}#check-for-existing-sub-issues`
> Supports `--yes` flag per `@{file:context/cmd.md}#global-flags`

---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

---

## Command Flow

This command executes in three phases:

1. **Phase 1 (Steps 1-8): Validate & Gather Information** - Read-only operations, no confirmation needed
2. **Phase 2 (Step 9): Review & Confirm** - MANDATORY STOP - Review plan and get explicit confirmation
3. **Phase 3 (Steps 10-16): Execute Actions** - Write operations executed only after "yes"

---

# Phase 1: Validate & Gather Information

**Read-only operations - No confirmation required**

---

## 1. Validate Repository

Follow the **Repository Validation Workflow** in `@{file:context/git.md}`.

**After validation, you have:** `username`, `owner`, `repo`

**If validation fails:** Display the error and **STOP**.

---

## 2. Parse Issue Number

Follow the **Parse Issue Number Pattern** in `@{file:context/cmd.md}`.

---

## 3. Fetch Issue

Follow the **Fetch Issue Pattern** in `@{file:context/mcp.md}`.

**Additional handling for this command:**

After fetching:

- Extract the specification sections from the body (sections vary by issue type - see `@{file:template/gh.issue.create.feature.md}`, `@{file:template/gh.issue.create.task.md}`, `@{file:template/gh.issue.create.bug.md}`)
- Store the issue title, type, and body for later use

**If issue is closed:**
- Warn: "**Note:** Issue #[issue_number] is closed."
- Ask: "Starting work on a closed issue is unusual. Continue anyway? (yes/no)"
- **STOP and WAIT**
- If "no" → **STOP**
- If "yes" → Continue

**Required sections by type:**
| Type | Required Sections |
|------|-------------------|
| Feature | Context, Acceptance Criteria |
| Task | Context, Objective, Acceptance Criteria |
| Bug | Summary, Steps to Reproduce, Expected Behavior, Actual Behavior, Acceptance Criteria |

> **Note:** Other template sections (e.g., Environment, Additional Context for bugs) are recommended but not required for validation.

**If body is missing required sections:**

- Warn: "This issue doesn't appear to have a standard specification format."
- Ask: "Would you like to proceed anyway? (yes/no)"
- **STOP and WAIT**
- If "no" → **STOP**
- If "yes" → Continue to step 4

---

## 4. Check for Sub-issues (Block Parent Development)

Follow the **Check for Existing Sub-issues** pattern in `@{file:context/pmp.md}`.

**Parent issues (those with sub-issues) cannot be developed directly.**

Use the `/gh.issue.develop` variant of the pattern output.

**If issue has sub-issues:** Display the blocking message and **STOP**.

**If no sub-issues:** Continue to step 5.

---

## 5. Validate Issue Type (Required for Branch Creation)

Check if the issue has a type assigned. **Issue type is required** for branch creation.

**Check issue type from the fetched issue data:**

- If `type` field exists and is valid (Feature, Task, Bug) → Store type for branch creation
- If `type` is null, empty, or invalid → **STOP** and prompt user

**If no valid type is found:**

```markdown
**Cannot create branch: Issue #[issue_number] doesn't have a type assigned.**

Issue type is required to create a properly named branch.
Valid types: Feature, Task, Bug

Please:

1. Edit the issue on GitHub to assign a type, OR
2. Ensure the issue was created with a type

**STOP** - Cannot proceed without issue type.
```

**Branch naming:** See `@{file:context/git.md}#branch-naming-convention`

---

## 6. Check for Existing PR

Call `github_list_pull_requests` with:

- owner: repository owner
- repo: repository name
- state: "open"

**On error:**
- If 401/403 → Display auth error and **STOP**
- If other error → Display error message and **STOP**

**On success:**
Search for a PR where `head.ref` (the branch name) matches the expected branch name `[type]-[number]`.

**If multiple PRs match** (edge case - shouldn't normally happen):

- Use the most recently updated PR
- Warn: "Multiple PRs found for this branch. Using the most recent: #[prNumber]"

**If PR already exists:**

- Display: "**A Pull Request already exists for Issue #[issue_number]**"
- Display PR URL, title, and status
- Ask: "Would you like to:\n A) View the existing PR\n B) Continue anyway (will create duplicate PR)\n C) Cancel"
- **STOP and WAIT**
- If "A" → Display PR details and **STOP**
- If "B" → Continue to step 7
- If "C" → **STOP**

**If no PR exists:**

- Continue to step 7

---

## 7. Scan Codebase

Analyze the existing codebase to understand the tech stack and patterns.

**Detect tech stack by checking for:**

| File             | Check                      | Indicates                            |
| ---------------- | -------------------------- | ------------------------------------ |
| `package.json`   | Read dependencies, scripts | Node.js/Bun, frameworks, test runner |
| `bun.lockb`      | Exists                     | Bun runtime                          |
| `tsconfig.json`  | Read config                | TypeScript settings                  |
| `go.mod`         | Read module                | Go project                           |
| `Cargo.toml`     | Read package               | Rust project                         |
| `pyproject.toml` | Read config                | Python project                       |
| `.opencode/`     | Exists                     | OpenCode project                     |

**Identify project structure:**

- Source directory: `src/`, `lib/`, `pkg/`, `internal/`
- Test directory: `tests/`, `test/`, `__tests__/`
- Existing patterns: API style, module organization

**Look for similar existing features:**

- How are similar problems solved in this codebase?
- What patterns should be followed for consistency?

---

## 8. Generate PR Body

Follow the template structure and guidelines in `@{file:template/gh.issue.develop.md}`.

**Inputs from previous steps:**

- Issue body (Step 3) → Context section
- Codebase scan (Step 7) → Technical Approach (Stack, Key Files, Design Decisions)
- Issue specification (Step 3) → Implementation Plan tasks

**Generate the PR body with:**

1. **Context** - Copy from issue's Context section
2. **Technical Approach** - From codebase scan
3. **Implementation Plan** - Derive tasks from issue spec (see template for task generation guidelines)

**Refer to `@{file:template/gh.issue.develop.md}` for:**

- Complete body structure
- Section formatting guidelines
- Task derivation from issue sections
- Bootstrapping detection (Phase 1 setup tasks)
- Task format requirements (ID, checkbox, file path)
- Complexity-based task counts
- Quality checklist

Store the generated PR body for review in Step 9.

---

# Phase 2: Review & Confirm

**MANDATORY STOP - Present plan and get explicit confirmation**

---

## 9. Draft Review (MANDATORY - STOP AND WAIT)

> **If `--yes` flag is set:** Skip this prompt and proceed directly to Phase 3 (step 10).

> ⚠️ **NO ACTIONS HAVE BEEN EXECUTED YET**
>
> Steps 1-8 only gathered information. The following actions will ONLY happen after you confirm with "yes".

Present a summary of all planned actions and the PR body:

```markdown
**Ready to start work on Issue #[issue_number]: [title]**

**Actions that WILL be executed upon confirmation:**

1. Create branch: `[type]-[number]` and check it out
2. Create empty commit: `git commit --allow-empty -m "Start work on #[issue_number]"`
3. Push branch to remote with upstream tracking
4. Assign issue to: @[username]
5. Create Draft Pull Request
6. Assign Pull Request to: @[username]

**Pull Request Body:**

[Generated PR body - full content]

---

How would you like to proceed?

- **"yes"** → Execute all actions and create Draft PR
- **"edit"** → Modify the PR body
- **"cancel"** → Abort without making changes
```

**STOP and WAIT** for explicit confirmation.

**If "edit":**
Follow the **Draft Review Pattern** "edit" handling in `@{file:context/cmd.md}#draft-review-pattern`.

**If "cancel":**

- Display: "Cancelled. No changes made."
- **STOP**

**If "yes":**

- Continue to Phase 3

**NEVER proceed without explicit "yes".**

---

# Phase 3: Execute Actions

**Write operations - Only executed after explicit confirmation**

---

## 10. Create Typed Branch

Follow the branch operations documented in `@{file:context/git.md}`.

### 10.0 Get Default Branch

Use the **"Get Default Branch"** operation from `@{file:context/git.md}` to determine `[default-branch]`.

Store the result as `defaultBranch` for use in subsequent steps.

### 10.1 Check for Uncommitted Changes

Use the **"Check for Uncommitted Changes"** operation from `@{file:context/git.md}`.

**If uncommitted changes exist:**

- Display: "You have uncommitted changes in your working directory."
- Suggest: `git stash` or `git commit -am "WIP"`
- Display: "Please commit or stash your changes before starting work on this issue."
- **STOP** - Branch creation requires a clean working directory

### 10.2 Create Branch with Issue Link

Use **"Create and Checkout Branch Linked to Issue"** from `@{file:context/git.md}`.

**If success:** Continue to step 11

**If error contains "already exists":** Continue to step 10.3

**If other error:** Display error, suggest manual fallback, **STOP**

### 10.3 Handle Existing Branch (Fallback)

**Step 1:** Use **"Check if Branch Exists"** from `@{file:context/git.md}` to determine location (local/remote/both).

**Step 2:** Use **"Switch to Existing Branch"** from `@{file:context/git.md}` to checkout.

- If local only: Ask user to confirm checkout first. If "no" → **STOP**

**Step 3 (remote branches only):** Check for closed PR:

- Call `github_list_pull_requests` with state: `"closed"`, filter by head branch
- If closed PR found:
  - Warn: "A closed PR (#[number]) exists for this branch."
  - Ask: "A) Create new PR anyway, B) Reopen existing PR, C) Cancel"
  - **STOP and WAIT**
  - If "A" → Continue to step 4
  - If "B" → Reopen via `github_update_pull_request`, display success, **STOP**
  - If "C" → **STOP**

**Step 4:** Use **"Check Branch Has Commits"** from `@{file:context/git.md}`.

- If commits exist → Skip to step 14 (Create Draft PR)
- If no commits → Continue to step 11 (Create Empty Commit)

---

## 11. Create Empty Commit

Create an empty commit to allow Draft PR creation:

Use git operations from `@{file:context/git.md}`.

```bash
git commit --allow-empty -m "Start work on #[issue_number]"
```

**If success:**

- Note commit SHA
- Proceed to step 12

**If error:**

- Display error message
- **STOP**

---

## 12. Push Branch to Remote

Use push operations from `@{file:context/git.md}`.

Use **"Push Branch with Upstream"** operation.

**If push fails:**

- Display error
- For common push errors, see **"Common Errors"** in `@{file:context/git.md}#common-errors`
- **STOP**

**If success:**

- Proceed to step 13

---

## 13. Assign Issue to Self

Get current user from step 1 (`github_get_me` result).

Call `github_issue_write` with:

- method: "update"
- owner: repository owner
- repo: repository name
- issue_number: the issue number
- assignees: [current username]

**If success:**

- Note the assignee username
- Proceed to step 14

**If error:**

- Warn: "Could not assign issue to you: [error message]"
- Note: This is non-blocking, continue to step 14

---

## 14. Create Draft PR

Call `github_create_pull_request` with:

- owner: `[owner]`
- repo: `[repo]`
- title: `[issueTitle]`
- body: `[Generated PR body]`
- head: `[branchName]`
- base: `[defaultBranch]`
- draft: `true`

**If PR creation fails:**

- Display the error message
- Provide troubleshooting guidance
- **STOP**

**If success:**

- Extract PR number and URL from response
- Proceed to step 15

---

## 15. Assign PR to Self

After PR creation, assign the current user to the PR.

Run Bash command:

```bash
gh pr edit [prNumber] --add-assignee "@me"
```

**If success:**

- Note the assignment
- Proceed to step 16

**If error:**

- Warn: "Could not assign PR to you: [error message]"
- Note: This is non-blocking, continue to step 16

---

## 16. Report Success & STOP

Present the final success summary:

```markdown
**Started work on Issue #[issue_number]:** [title]

**Branch:** `[actual-branch-name]` (checked out)
**Assigned to:** @[username]
**Draft PR:** [PR URL]

**What you can do next:**

- Review the implementation plan in the PR
- Run `/gh.issue.work` to begin implementing tasks
- Run `/gh.issue.status` later to restore context
- Update the PR body anytime to refine the plan
```

---

Follow the **Command Completion Pattern** in `@{file:context/cmd.md}`.
