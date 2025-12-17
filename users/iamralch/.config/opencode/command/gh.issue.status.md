---
description: Load and display context for an issue - specification, hierarchy, and implementation plan (if PR exists).
agent: dev
---

> Use GitHub MCP tools as documented in `@{file:context/mcp.md}`
> Use local git operations as documented in `@{file:context/git.md}`

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

## 2. Parse Issue Number

Follow the **Parse Issue Number Pattern** in `@{file:context/cmd.md}`.

---

## 3. Fetch Issue

Follow the **Fetch Issue Pattern** in `@{file:context/mcp.md}`.

**Store:**

- `issueTitle` - Issue title
- `issueBody` - Issue body (the specification)
- `issueState` - open/closed
- `issueType` - Feature/Task/Bug
- `issueUrl` - Issue URL

**If issue is closed:**

- Warn: "Note: This issue is closed."
- (Continue anyway - user may want to review)

---

## 4. Check Issue Hierarchy

Check if the issue is part of a hierarchy (has parent or has children).

### 4a. Check for Parent Issues

Use the **Get Parent Issue** operation from `@{file:context/git.md}`.

**If parent exists (200 response):**

- Store: `parentIssueNumber`, `parentIssueTitle`, `parentIssueState`
- Recursively check for grandparent using the same operation
- Store the full chain: `issueHierarchy = [grandparent, parent, current]`
- Stop when you get a 404 (no parent), after 10 levels (prevent excessive recursion), or if an issue number repeats (circular reference detected)

**If no parent (404 response):**

- Set `hasParent = false`

### 4b. Check for Sub-issues (Children)

Call `github_issue_read` with:

- method: `"get_sub_issues"`
- owner: `[owner]`
- repo: `[repo]`
- issue_number: `[issueNumber]`

**On error:**
- If 401/403 → Display auth error and **STOP**
- If 404 → Treat as no sub-issues (set `hasChildren = false`)
- If other error → Display error message and **STOP**

**If sub-issues exist:**

- Store: `subIssues = [{number, title, state}, ...]`
- Calculate: `closedSubIssues`, `totalSubIssues`, `subIssueProgress`
- Set `hasChildren = true`

**If no sub-issues:**

- Set `hasChildren = false`

### 4c. Determine Issue Role

- If `hasChildren = true` AND `hasParent = true` → `issueRole = "parent"` (middle of hierarchy - has both parent and children)
- If `hasChildren = true` AND `hasParent = false` → `issueRole = "parent"` (top-level parent)
- If `hasChildren = false` AND `hasParent = true` → `issueRole = "leaf"` (bottom of hierarchy)
- If `hasChildren = false` AND `hasParent = false` → `issueRole = "standalone"`

---

## 5. Find Associated PR

**If `issueRole = "parent"`:**

- Skip PR lookup (parent issues don't have PRs)
- Set `hasPR = false`
- Continue to step 8

**If `issueRole = "leaf"` OR `issueRole = "standalone"`:**

Call `github_list_pull_requests` with:

- owner: `[owner]`
- repo: `[repo]`
- state: `"open"`

**On error:**
- If 401/403 → Display auth error and **STOP**
- If other error → Display error message and **STOP**

**On success:**
Filter results: Find PR where `head.ref` (the branch name field) matches pattern `[type]-[issueNumber]` where type is `feature`, `task`, or `bug`

**If matching PR found:**

- Store: `prNumber`, `prTitle`, `prBranch`, `prBody`, `prUrl`, `prDraft`
- Set `hasPR = true`
- Continue to step 6

**If no open PR found:**

- Set `hasPR = false`
- Skip to step 8

---

## 6. Check/Checkout Branch

**Only if `hasPR = true`:**

Use branch operations from `@{file:context/git.md}`.

**Get current branch and compare with PR branch (`prBranch`):**

Store: `currentBranch` = result of "Get Current Branch" operation

**If already on correct branch (`currentBranch == prBranch`):**

- Set `onCorrectBranch = true`
- Continue to step 7

**If on different branch:**

- Set `onCorrectBranch = false`
- Ask: "Switch to branch `[prBranch]`? (yes/no)"
- **STOP and WAIT**
- If yes → Checkout using **"Switch to Existing Branch"** operation, set `onCorrectBranch = true`, then continue to step 7
- If no → Continue to step 7 (stay on current branch, `onCorrectBranch` remains false)

**If branch doesn't exist locally:**

- Set `onCorrectBranch = false`
- Warn: "Branch `[prBranch]` not found locally."
- Ask: "Would you like me to check it out? (yes/no)"
- **STOP and WAIT**
- If yes → Use **"Switch to Existing Branch"** (remote only) from `@{file:context/git.md}`, set `onCorrectBranch = true`, then continue to step 7
- If no → Continue to step 7 (don't block context display, `onCorrectBranch` remains false)

---

## 7. Sync with Remote and Parse PR Content

**Only if `hasPR = true`:**

### 7a. Sync with Remote

Use sync operations from `@{file:context/git.md}`.

**Fetch latest:** Use **"Fetch Latest from Remote"**

**Check if behind remote:**

- If behind → Warn: "Your branch is {count} commit(s) behind origin."
- Ask: "Pull latest changes? (yes/no)"
- **STOP and WAIT**
- If yes → Use **"Pull Latest Changes"**, then continue to step 7b
- If no → Continue to step 7b without pulling (local state may differ from remote; changes made locally won't include remote updates)

**Check for uncommitted changes:**

- If dirty → Warn: "You have uncommitted local changes."
- (Continue anyway - informational only)

### 7b. Parse Technical Approach

Search PR body for `## Technical Approach` section.

**If found:**

- Extract stack, key files, and design decisions
- Set `hasApproach = true`

**If not found:**

- Set `hasApproach = false`

### 7c. Parse Implementation Plan

Search PR body for `## Implementation Plan` section.

**If found:**

- Extract phases and tasks
- Parse task status: `- [ ]` = pending, `- [x]` = complete
- Calculate: `completedTasks`, `totalTasks`, `progress`
- Identify: `nextTask` = first incomplete task
- Set `hasPlan = true`

**If not found:**

- Set `hasPlan = false`

---

## 8. Display Context

Display context automatically based on issue role.

### Header (All Roles)

```markdown
## Context: Issue #[issueNumber]

**Issue:** #[issueNumber] - [issueTitle]
**Type:** [issueType]
**State:** [issueState]
[If hasPR:]
**PR:** #[prNumber] - [prTitle] ([if prDraft: "Draft", else: "Open"])
**Branch:** `[prBranch]`
[If hasPR AND onCorrectBranch = false:]
**Note:** You are on branch `[currentBranch]`, expected `[prBranch]`
```

---

### For Parent Issues (`issueRole = "parent"`)

```markdown
---

### Hierarchy

**This is a parent issue with [totalSubIssues] sub-issues.**

**Progress:** [closedSubIssues]/[totalSubIssues] complete ([subIssueProgress]%)

| Sub-issue | Title | State |
|-----------|-------|-------|
| #[sub1] | [title] | [state] |
| #[sub2] | [title] | [state] |
| #[sub3] | [title] | [state] |

---

**Next steps:**

- Run `/gh.issue.status #[sub-issue]` on individual sub-issues to see their context
- Run `/gh.issue.develop #[sub-issue]` on a sub-issue to start work
```

**STOP** (parent issues don't have implementation plans)

---

### For Leaf Issues (`issueRole = "leaf"`)

```markdown
---

### Hierarchy

**Parent:** #[parentIssueNumber] - [parentIssueTitle] ([parentIssueState])
[If grandparent exists:]
**Grandparent:** #[gpNumber] - [gpTitle] ([gpState])
```

Then continue to **Specification Section** below.

---

### For Standalone Issues (`issueRole = "standalone"`)

No hierarchy section. Continue to **Specification Section** below.

---

### Specification Section (Leaf/Standalone)

```markdown
---

### Specification

**Context:**
[Context section from issue body]

**[User Stories / Objective / Summary]:** (Feature → User Stories, Task → Objective, Bug → Summary)
[Extracted content]

**Acceptance Criteria:**
[List of acceptance criteria]

[If Feature or Task (not Bug):]
**Out of Scope:**
[List of excluded items]
```

---

### Technical Approach Section (Leaf/Standalone with PR)

**If `hasPR = true` AND `hasApproach = true`:**

```markdown
---

### Technical Approach

**Stack:** [Language/Runtime] | [Framework] | [Testing]

**Key Files:**
[List of key files]

**Design Decisions:**
[List of decisions with rationale]
```

**If `hasPR = true` AND `hasApproach = false`:**

```markdown
---

### Technical Approach

_No Technical Approach defined in PR._
```

---

### Implementation Plan Section (Leaf/Standalone with PR)

**If `hasPR = true` AND `hasPlan = true`:**

```markdown
---

### Implementation Plan

**Progress:** [completedTasks]/[totalTasks] tasks ([progress]%)

**Completed:**

- [x] T001 [Description]
- [x] T002 [Description]

**Remaining:**

- [ ] T003 [Description] ← Next
- [ ] T004 [Description]
```

**If `hasPR = true` AND `hasPlan = false`:**

```markdown
---

### Implementation Plan

_No Implementation Plan found in PR._
```

---

## 9. Ready to Continue

Based on context, provide appropriate guidance for leaf/standalone issues:

> **Note:** Parent issues stop at step 8 and do not reach this step.

### If Leaf/Standalone WITH PR and tasks remain

```markdown
---

**Context loaded. Ready to continue.**

**Next task:** [nextTask description]

Run `/gh.issue.work` to continue implementation.
```

### If Leaf/Standalone WITH PR and all tasks complete

```markdown
---

**All tasks complete!**

Ready to finalize:

1. Run `gh pr ready` to mark PR as ready for review
2. After review, run `gh pr merge` to merge
```

### If Leaf/Standalone WITH PR but no plan

```markdown
---

**No implementation plan found.**

The PR may have been created manually. Run `/gh.issue.develop #[issueNumber]` to regenerate with a proper plan.
```

### If Leaf/Standalone WITHOUT PR

```markdown
---

**No Pull Request found for this issue.**

Run `/gh.issue.develop #[issueNumber]` to create a branch, Draft PR, and Implementation Plan.
```

---

Follow the **Command Completion Pattern** in `@{file:context/cmd.md}`.
