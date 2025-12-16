---
description: Create a GitHub Issue with a polished specification through interactive Q&A.
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

## 1. Validate Repository

Follow the **Repository Validation Workflow** in `@{file:context/git.md}`.

**After validation, you have:** `username`, `owner`, `repo`

**If validation fails:** Display the error and **STOP**.

---

## 2. Parse Arguments & Detect Issue Type

### Parse `--parent` Flag (Optional)

Check if the user input contains `--parent #N`:

**Accepted formats:**
- `--parent #42` or `--parent 42`
- `--parent https://github.com/owner/repo/issues/42`

**If `--parent` flag is found:**
- Extract the parent issue number
- Validate parent exists by calling `github_issue_read` with:
  - method: "get"
  - owner: repository owner
  - repo: repository name
  - issue_number: parent issue number
- **If parent not found:**
  - Display: "Parent issue #[issue_number] not found in this repository"
  - **STOP**
- **If parent found:**
  - Store `parentIssueNumber` for later use

### Detect Issue Type

Follow the **Issue Type Detection** pattern in `@{file:context/pmp.md}`.

Analyze the user's input (excluding the --parent portion, which is already stored as `parentIssueNumber`) to infer the issue type.

Use the type indicators and detection flow from `@{file:context/pmp.md}#issue-type-detection`.

**Store:** `issueType` = Feature | Task | Bug

---

## 3. Get Description (if needed)

**If description is empty or was only a type indicator:**
- Based on `issueType`, ask the appropriate question:
  - Feature: "What feature would you like to create an issue for?"
  - Task: "What task or maintenance work needs to be done?"
  - Bug: "What bug or issue are you experiencing?"
- **STOP and WAIT** for response

---

## 4. Extract Key Concepts

Follow the **Extract Key Concepts Pattern** in `@{file:context/pmp.md}`.

Based on `issueType`, extract relevant information from the user's description.

**Mark critical gaps with `[NEEDS CLARIFICATION]` (maximum 3)**

---

## 5. Information Gathering (Q&A)

Follow the **Information Gathering Pattern** in `@{file:context/pmp.md}`.

Generate clarifying questions based on gaps identified and issue type.

Use the Q&A depth, rules, and common questions from `@{file:context/pmp.md}#information-gathering-pattern`.

---

## 6. Complexity Assessment

**Before generating the draft**, analyze complexity using `@{file:context/pmp.md}#complexity-assessment`.

### Assessment

Analyze the extracted key concepts and Q&A responses using the **Complexity Signals** from `@{file:context/pmp.md}`:
- Multiple independent deliverables?
- Broad scope across multiple components?
- Estimated effort exceeds 1-3 days?
- Would result in unfocused PR (500+ lines)?

### Decision

Follow the **Decision Flow** from `@{file:context/pmp.md}#decision-flow`:

**If appropriately sized (leaf issue):**
- Store: `isLeaf = true`
- Continue to step 7a (Generate Leaf Draft)

**If too large:**
- Store: `isLeaf = false`
- Store: `needsBreakdown = true`
- Continue to step 7b (Generate Parent + Breakdown)

**If uncertain:**
- Follow the uncertain prompt from `@{file:context/pmp.md}#decision-flow`
- If "A" → Store `isLeaf = false`, `needsBreakdown = true`. Continue to step 7b.
- If "B" → Store `isLeaf = true`. Continue to step 7a.

---

## 7a. Generate Leaf Issue Draft

**Only if `isLeaf = true`**

Follow the **Leaf Issue Format** in `@{file:context/pmp.md}#issue-body-formats`.

### Title Generation

Follow the **Issue Title Patterns** in `@{file:context/pmp.md}#issue-title-patterns`.

### Body Generation

Based on `issueType`, use the appropriate template:

| Type | Template |
|------|----------|
| Feature | `@{file:template/gh.issue.create.feature.md}` |
| Task | `@{file:template/gh.issue.create.task.md}` |
| Bug | `@{file:template/gh.issue.create.bug.md}` |

Fill each section with concrete details derived from the user's description and Q&A responses.

**Include Clarifications section (only if Q&A occurred in step 5):**
- Add the Q&A log in a collapsible `<details>` block
- Format: Q: [question] → A: [answer]

**Continue to step 8 (Draft Review).**

---

## 7b. Breakdown Path

**Only if `needsBreakdown = true`**

Follow the **Breakdown Presentation Pattern** in `@{file:context/pmp.md}`.

**Parameters:**
- `issueType`: from step 2
- `issueContext`: "This issue"
- `allowSingleOption`: `true`
- `showRedistributionNote`: `false`

### Command-Specific Response Handling

| Response | Action |
|----------|--------|
| **"yes"** (Feature/Task) | Store: `autoCreateSubIssues = true`, `subIssueTitles`, and `subIssueTypes` arrays from breakdown. Continue to step 7c. |
| **"umbrella"** (Bug) | Store: `autoCreateSubIssues = true`, `subIssueTitles`, and `subIssueTypes` arrays from breakdown. Continue to step 7c. |
| **"single"** | User chose not to break down. Store: `isLeaf = true`, `needsBreakdown = false`. Continue to step 7a (Generate Leaf Draft). |
| **"task"** (Bug) | Display guidance to create as Task instead. **STOP** |
| **"edit"** | Ask "What would you like to change?", **STOP and WAIT**, apply changes, re-present. |
| **"cancel"** | Display: "Cancelled. No issue created." **STOP** |

---

## 7c. Generate Parent Issue Draft

**Only if breakdown was approved**

### Title Generation

Follow the **Issue Title Patterns** in `@{file:context/pmp.md}#issue-title-patterns`.

Parent titles should be broader than sub-issue titles.

### Body Generation

Use the **Parent Issue Format** template from `@{file:context/pmp.md}#parent-issue-format`.

Fill in:
- Overview: High-level description from user's input (2-3 sentences)
- Scope: What this parent issue covers at a high level
- Sub-issues: List from breakdown (will be updated with actual numbers after creation)
- Acceptance Criteria: Parent-level criteria

**Continue to step 8 (Draft Review).**

---

## 8. Draft Review (Mandatory)

Present the complete draft following `@{file:context/cmd.md}#draft-review-pattern`:

**If `needsBreakdown = true` (Parent Issue):**

```markdown
**Here's the Parent [Feature/Task/Bug] Issue draft:**

**Type:** [Feature/Task/Bug]
**Title:** [Generated title]

**Body:**

[Generated parent body - full content]

**Sub-issues to be created:**
1. [Sub-issue title 1] ([Type])
2. [Sub-issue title 2] ([Type])
3. [Sub-issue title 3] ([Type])

---

How would you like to proceed?
- **"yes"** → Create the parent issue and all sub-issues
- **"edit"** → Tell me what to change
- **"cancel"** → Abort without creating
```

**Otherwise (Leaf Issue):**

```markdown
**Here's the [Feature/Task/Bug] Issue draft:**

**Type:** [Feature/Task/Bug]
**Title:** [Generated title]

**Body:**

[Generated body - full content]

---

How would you like to proceed?
- **"yes"** → Create the Issue
- **"edit"** → Tell me what to change
- **"cancel"** → Abort without creating
```

**STOP and WAIT** for explicit confirmation.

**If "edit":** Handle per `@{file:context/cmd.md}#draft-review-pattern`.

**If "yes":** Continue to step 9 (Create GitHub Issue).

**If "cancel":**
- Display: "Cancelled. No issue created."
- **STOP**

**NEVER create the issue without explicit "yes".**

---

## 9. Create GitHub Issue

After receiving explicit confirmation ("yes"):

### 9a. Create the Issue

Call `github_issue_write` with:
- method: "create"
- owner: repository owner
- repo: repository name
- title: the approved title
- body: the approved body
- type: the issue type (Feature, Task, or Bug)

**Handle the response:**

**If success:**
- Extract from response:
  - `createdIssueId` - the `id` field (database/node ID) - used for API linking
  - `createdIssueNumber` - the `number` field (issue number) - used for display
  - `createdIssueUrl` - the issue URL
- **Note:** The `github_sub_issue_write` API requires the database ID (`id` field), not the issue number.
- Continue to step 9b

**If error:**
- Display the error message from the response
- Suggest remediation steps based on error
- **STOP**

---

### 9b. Link to Parent (If --parent Was Provided)

**If `parentIssueNumber` was set in step 2:**

Call `github_sub_issue_write` with:
- method: "add"
- owner: repository owner
- repo: repository name
- issue_number: parentIssueNumber
- sub_issue_id: createdIssueId (must be the `id` field, not `number`)

**If linking fails:**
- Display warning: "Issue #[createdIssueNumber] was created but could not be linked to parent #[parentIssueNumber]"
- Display error details
- Continue (issue was still created successfully)

---

### 9c. Create Sub-issues (If Breakdown Was Approved)

**If `autoCreateSubIssues = true`:**

Follow the **Execute Breakdown Pattern** (for `/gh.issue.create`) in `@{file:context/pmp.md}`:

**Parameters:**
- parentIssueNumber: `createdIssueNumber` (from step 9a)
- subIssueTitles: from step 7b
- subIssueTypes: from step 7b
- isExistingIssue: `false`

After sub-issues are created, update the parent body with actual issue numbers.

---

## 10. Report Success & Next Steps

Based on `parentIssueNumber`, `needsBreakdown`, `autoCreateSubIssues`, provide appropriate output:

### If `--parent` Was Provided (Created as Sub-issue)

```markdown
**Created [Feature/Task/Bug] Issue #[issue_number]:** [title]

**URL:** [url]
**Linked as sub-issue of:** #[parentIssueNumber]

**Next steps:**
- Review the issue on GitHub
- Run `/gh.issue.edit #[issue_number]` if you need to refine or break down further
- Run `/gh.issue.develop #[issue_number]` when ready to start work
```

### If Sub-issues Were Created (`autoCreateSubIssues = true`)

Follow the **Report Sub-issue Creation Pattern** in `@{file:context/pmp.md}`:

**Parameters:**
- parentIssueNumber: `createdIssueNumber` (from step 9a)
- createdSubIssues: from step 9c
- failedSubIssues: from step 9c

### If Standard Leaf Issue (No Breakdown)

```markdown
**Created [Feature/Task/Bug] Issue #[issue_number]:** [title]

**URL:** [url]

**Next steps:**
- Review the issue on GitHub
- Run `/gh.issue.develop #[issue_number]` to create a branch, Draft PR, and start work
```

---

Follow the **Command Completion Pattern** in `@{file:context/cmd.md}`.
