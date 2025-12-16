---
description: Start work on a GitHub Issue by creating a branch, generating an implementation plan, and creating a draft PR.
---

> Follow conversation rules in `@{file:context/cmd.md}`
> Use GitHub MCP tools as documented in `@{file:context/mcp.md}`
> Use local git operations as documented in `@{file:context/git.md}`
> Use project management patterns in `@{file:context/pmp.md}`
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

**Branch naming:** See **Branch Naming Convention** in `@{file:context/git.md}`

---

## 6. Check for Existing PR

Call `github_list_pull_requests` with:
- owner: repository owner
- repo: repository name
- state: "open"

Search for a PR where `head.ref` (the branch name) matches the expected branch name `[type]/issue-[number]`.

**If multiple PRs match** (edge case - shouldn't normally happen):
- Use the most recently updated PR
- Warn: "Multiple PRs found for this branch. Using the most recent: #[prNumber]"

**If PR already exists:**
- Display: "**A Pull Request already exists for Issue #[issue_number]**"
- Display PR URL, title, and status
- Ask: "Would you like to:\n  A) View the existing PR\n  B) Continue anyway (will create duplicate PR)\n  C) Cancel"
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

| File | Check | Indicates |
|------|-------|-----------|
| `package.json` | Read dependencies, scripts | Node.js/Bun, frameworks, test runner |
| `bun.lockb` | Exists | Bun runtime |
| `tsconfig.json` | Read config | TypeScript settings |
| `go.mod` | Read module | Go project |
| `Cargo.toml` | Read package | Rust project |
| `pyproject.toml` | Read config | Python project |
| `.opencode/` | Exists | OpenCode project |

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
4. **Issue Link** - `Relates to #[issue_number]`

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

> ⚠️ **NO ACTIONS HAVE BEEN EXECUTED YET**
> 
> Steps 1-8 only gathered information. The following actions will ONLY happen after you confirm with "yes".

Present a summary of all planned actions and the PR body:

```markdown
**Ready to start work on Issue #[issue_number]: [title]**

**Actions that WILL be executed upon confirmation:**
1. Create branch: `[type]/issue-[number]` and check it out
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

### 10.1 Check for Uncommitted Changes

Use the **"Check for Uncommitted Changes"** operation from `@{file:context/git.md}`.

**If uncommitted changes exist:**
- Display: "You have uncommitted changes in your working directory."
- Suggest: `git stash` or `git commit -am "WIP"`
- Display: "Please commit or stash your changes before starting work on this issue."
- **STOP** - Branch creation requires a clean working directory

### 10.2 Check if Branch Already Exists

Use the **"Check if Branch Exists"** operation from `@{file:context/git.md}`.

**If branch exists locally:**
- Display: "Branch `[branch-name]` already exists."
- Ask: "Would you like to check out the existing branch? (yes/no)"
- **STOP and WAIT**
- If "yes" → Checkout the branch, then check if branch has commits: `git log [default-branch]..[branch-name] --oneline`
  - If commits exist → Skip to step 14 (Create Draft PR). Issue assignment is skipped because work already started on this branch.
  - If no commits → Continue to step 11
- If "no" → **STOP**

**If branch exists only on remote:**
- Checkout and track the remote branch using: `git checkout -b [branch-name] origin/[branch-name]`
- Before creating Draft PR, check for existing closed/merged PRs for this branch:
  - Call `github_list_pull_requests` with state: `"closed"` and filter by head branch
  - If a closed PR exists, warn: "A closed PR (#[number]) exists for this branch."
  - Ask: "Would you like to: A) Create a new PR anyway, B) Reopen the existing PR, C) Cancel"
  - **STOP and WAIT**
  - If "A" → Continue to step 14 (Create Draft PR)
  - If "B" → Use `github_update_pull_request` to reopen, display "PR #[number] reopened. Run `/gh.issue.status #[issue_number]` to continue.", then **STOP**
  - If "C" → **STOP**
- If no closed PR exists:
  - Check if branch already has commits: `git log origin/[default-branch]..[branch-name] --oneline`
  - If commits exist → Skip steps 11, 12, and 13 - continue directly to step 14 (Create Draft PR). These steps are skipped because work already started on this branch.
  - If no commits → Continue to step 11 (Create Empty Commit)

### 10.3 Create New Branch with Issue Link

Use the **"Create and Checkout Branch Linked to Issue"** operation from `@{file:context/git.md}`.

This creates a branch that's formally linked to the issue in GitHub using `gh issue develop`.

**If success:**
- Note the branch name
- Proceed to step 11

**If error (branch already exists remotely):**
- The command will fail with a clear error message
- Display: "Branch already exists on remote. Use step 10.2 logic to handle."
- **STOP**

**If error (other - e.g., network issues, permission denied, unexpected failures):**
- Display the error message
- Suggest fallback: `git checkout -b [branch-name]` followed by `git push -u origin [branch-name]` (see `@{file:context/git.md}#branch-operations`)
- **STOP** and ask user how to proceed

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
- Display error and **STOP**

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

