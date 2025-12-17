---
description: Execute tasks from the Implementation Plan loaded by /gh.issue.status.
agent: dev
---

> Use GitHub MCP tools as documented in `@{file:context/mcp.md}`
> Use local git operations as documented in `@{file:context/git.md}`
> Supports `--yes` flag per `@{file:context/cmd.md}#global-flags`

---

## User Input

```text
$ARGUMENTS
```

---

## 1. Load or Verify Context

This command requires context: issue specification, PR details, and implementation plan.

### Option A: Context from current session

If `/gh.issue.status` was run earlier in this conversation, use that context.

### Option B: Infer from current branch

If no context is available, attempt to infer the issue from the current git branch:

1. Get current branch name using **"Get Current Branch"** from `@{file:context/git.md}`
2. If branch matches pattern `[type]-[number]`, extract the issue number
3. Silently load context by performing the same data gathering as `/gh.issue.status`:
   - Validate repository (get owner, repo, username)
   - Fetch issue details (title, body, type, state)
   - Check issue hierarchy (parent/children)
   - Find associated PR and parse its body (technical approach, implementation plan)
   - Skip user prompts (branch switching, pulling changes)
   - Do not display output - store data for use in this command

> **Session Freshness:** If context was loaded from a previous `/gh.issue.status` in this conversation, verify the PR body hasn't changed on the remote by comparing the stored `prBody` checksum with the current remote. If different, warn: "Implementation plan may have changed since context was loaded. Run `/gh.issue.status` to refresh." Continue with stored context unless user requests refresh.

### Option C: Prompt user

If neither A nor B succeeds:

```markdown
**Context not loaded.**

Please specify the issue number: `/gh.issue.work #[issue_number]`

Or run `/gh.issue.status #[issue_number]` first to load full context.
```

**STOP and WAIT**

### Required Context

After loading, verify you have:

- Issue specification (title, body, type)
- PR details (number, title, body)
- Implementation plan (tasks with status)

**If PR not found:** Display "No Pull Request found for this issue. Run `/gh.issue.develop #[issue_number]` first." and **STOP**.

**If no implementation plan:** Display "PR exists but has no Implementation Plan section." and **STOP**.

---

## 2. Parse Options

**Options for this command:**

- No flag - Guided mode (default): confirms before and after each task
- `--yes` - Auto mode: executes all pending tasks without confirmation

**Store:**

- `mode` = "guided" | "auto"

---

## 3. Execute Based on Mode

### Mode: Guided (default)

Loop through pending tasks in order:

```markdown
**Task T003:** Create UserModel in `src/models/user.ts`

Work on this task? (yes/skip/done)
```

**STOP and WAIT** for response.

**If "yes":**

1. Implement the task (see Step 4)
2. Ask: "T003 complete. Mark as done? (yes/no)"
3. **STOP and WAIT**
4. If "yes" → Update the checkbox in PR body (see Step 5)
5. If "no" → Leave task unchecked in PR body (task remains pending)
6. Move to next pending task

**If "skip":**

- Store task ID in `skippedTasks` array
- Move to next pending task without implementing
- If no more pending tasks remain, go to Step 6 (Summary)

**If "done":**

- Exit loop, go to Step 6 (Summary)

**When all tasks processed:**

- Go to Step 6 (Summary)

---

### Mode: Auto (`--yes`)

Display notice:

```markdown
**Mode:** Auto

Executing all pending tasks without confirmation...
```

Loop through pending tasks in order:

1. Display: "**Working on T003:** Create UserModel in `src/models/user.ts`"
2. Implement the task (see Step 4)
3. Update the checkbox in PR body (see Step 5)
4. Display: "**Completed T003:** Create UserModel"
5. Move to next pending task

**When all tasks complete:**

- Go to Step 6 (Summary)

---

## 4. Implement a Task

When implementing a task:

1. **Analyze the task** - Understand what needs to be done based on:
   - Task description from implementation plan
   - Issue specification (user stories, acceptance criteria)
   - Technical approach (design decisions, key files)
   - Existing codebase context

2. **Execute the implementation** - Write code, create files, modify existing code as needed

3. **Verify the work** - Run relevant tests or checks if applicable

4. **Handle blockers** - If implementation cannot proceed:
   - Report the blocker clearly: "**Blocked:** [description of issue]"
   - Ask: "How would you like to proceed? (skip/retry/escalate)"
   - **STOP and WAIT**
   - If "skip" → Store task ID in `skippedTasks` array (task remains unchecked `[ ]` in PR), move to next task
   - If "retry" → Attempt implementation again with different approach (max 2 retries per task; after 2 retries, treat as escalate)
   - If "escalate" → Store task ID in `skippedTasks` array, note the blocker for user follow-up, move to next task

   > **Retry limits:** Each task allows at most 2 retry attempts. Track retry count per task. After the second retry fails, automatically escalate and move to the next task.

5. **Report completion:**

   ```markdown
   **Implemented T003:** Create UserModel in `src/models/user.ts`

   **Changes made:**

   - `src/models/user.ts`: Created UserModel class with validation
   - `src/models/index.ts`: Added export for UserModel
   ```

---

## 5. Update Task Checkbox in PR Body

To mark a task complete in the Pull Request body:

1. **Get the current PR body content**

   Call `github_pull_request_read` with:
   - method: `"get"`
   - owner: repository owner
   - repo: repository name
   - pullNumber: the PR number

   Extract the `body` field from the response.

2. **Find and update the task line**

   In the `## Implementation Plan` section, find: `- [ ] T003 ...`
   Replace `[ ]` with `[x]`: `- [x] T003 ...`

   **If task ID not found:**
   - Warn: "Task [ID] not found in PR body. The PR may have been modified or task ID is incorrect."
   - Ask: "Continue without updating the checkbox? (yes/no)"
   - If "yes" → Continue to next task
   - If "no" → **STOP**

   **If task already marked complete (`[x]`):**
   - Display: "Task [ID] already marked complete. Skipping update."
   - Continue to next task

3. **Save the updated PR body**

   Call `github_update_pull_request` with:
   - owner: repository owner
   - repo: repository name
   - pullNumber: the PR number
   - body: updated PR body content

**Note:** Preserve all other content in the PR body. Only modify the specific task checkbox.

---

## 6. Summary

When implementation session ends (user says "done" or all tasks complete):

```markdown
**Implementation Session Complete**

**Pull Request #[pr_number]:** [title]
**Issue:** #[issue_number]
**Progress:** [completed]/[total] tasks

**Completed this session:**

- [x] T003 Create UserModel in `src/models/user.ts`
- [x] T004 Create AuthService in `src/services/auth.ts`

**Remaining:**

- [ ] T005 Wire AuthService to controller in `src/controllers/auth.ts`

**Skipped:**

- [ ] T006 Add unit tests (if any were skipped)

---

**Next steps:**

- Run `/gh.issue.work` to continue implementation
- Run `git commit` to save your progress
- When all tasks complete, run `gh pr ready` then `gh pr merge`
```

---

Follow the **Command Completion Pattern** in `@{file:context/cmd.md}`.
