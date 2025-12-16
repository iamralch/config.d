---
description: Edit, analyze, or break down an existing GitHub Issue.
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

## 2. Parse Issue Number

Follow the **Parse Issue Number Pattern** in `@{file:context/cmd.md}`.

---

## 3. Fetch Issue

Follow the **Fetch Issue Pattern** in `@{file:context/mcp.md}`.

**Additional handling for this command:**

After fetching, store: issue title, body, state, and type for later use.

**Determine issue type:**

1. **Check the issue's `type` field from the API response**
   - If `type` is "Feature", "Task", or "Bug" → Use it directly
   - If `type` is null, empty, or not one of the valid types → Continue to inference below

2. **Infer type from title/body** (only if type field is not set)
   - Follow the **Issue Type Detection** pattern in `@{file:context/pmp.md}`
   - Use type indicators to infer from content
   - Do NOT ask the user to confirm the inferred type (the issue already exists with established context)

**Store:** `issueType` = Feature | Task | Bug

**Store:** `originalBody` = the fetched issue body (for potential redistribution later)

---

## 4. Check for Existing Sub-issues

Follow the **Check for Existing Sub-issues** pattern in `@{file:context/pmp.md}`.

Use the `/gh.issue.edit` variant of the pattern output.

**If issue has sub-issues:** Display the guidance and **STOP**.

**If no sub-issues:** Continue to step 5.

---

## 5. Content Quality Assessment

Follow the **Content Quality Assessment** pattern in `@{file:context/pmp.md}`.

Evaluate whether the issue has sufficient detail for analysis using the "thin" vs "rich" criteria by type.

**If "thin" issue detected:**

```markdown
**Issue #[issue_number] lacks sufficient detail for analysis.**

Would you like me to ask clarifying questions to enrich this issue?
- **"yes"** → Start Q&A to gather more details
- **"no"** → Proceed with best-effort analysis (complexity assessment may be less accurate)
```

**STOP and WAIT**

- If "yes" → Continue to step 6 (Enrichment Flow)
- If "no" → Continue to step 8 (Extract Key Concepts)

**If "rich" issue:**

```markdown
**Issue #[issue_number] is well-structured.**

Would you like to:
- **"continue"** → Analyze if this issue needs breakdown into sub-issues
- **"refine"** → Improve or change the content through Q&A first
```

**STOP and WAIT**

- If "continue" → Continue to step 8 (Extract Key Concepts)
- If "refine" → Continue to step 6 (Enrichment Flow)

---

## 6. Enrichment Flow

**Only if user chose "yes" (thin issue) or "refine" (rich issue) in step 5**

### 6a. Extract Key Concepts (Initial)

Follow the **Extract Key Concepts Pattern** in `@{file:context/pmp.md}`.

Extract what information exists and identify gaps.

### 6b. Information Gathering (Q&A)

Follow the **Information Gathering Pattern** in `@{file:context/pmp.md}`.

**For refinement of rich issues:**
- Acknowledge existing content when asking questions
- Example: "The current acceptance criteria are: [X]. Would you like to keep, modify, or replace them?"
- Focus questions on sections the user wants to change

Ask clarifying questions based on identified gaps and issue type.

### 6c. Generate Enriched Body

Based on Q&A responses, generate a new issue body:

- Use the appropriate **Leaf Issue Format** template from `@{file:context/pmp.md}#issue-body-formats`
- Preserve existing content for sections not addressed in Q&A
- Replace sections where user provided new answers
- For refinement: Q&A focuses on what user wants to change

### 6d. Review Enriched Content

Present the enriched issue for approval:

```markdown
**Here's the enriched Issue #[issue_number]:**

**Title:** [Existing title - unchanged]

**Body (Updated):**

[Generated enriched body]

---

How would you like to proceed?
- **"yes"** → Update the issue on GitHub
- **"edit"** → Tell me what to change
- **"skip"** → Keep original content, proceed with analysis (note: "skip" keeps content and continues; "cancel" aborts the command entirely)
```

**STOP and WAIT**

**If "yes":**
- Continue to step 7 (Update Issue)

**If "edit":**
Follow the **Draft Review Pattern** "edit" handling in `@{file:context/cmd.md}#draft-review-pattern`.

**If "skip":**
- Continue to step 8 without updating

---

## 7. Update Issue on GitHub

**Only if enrichment was approved**

Call `github_issue_write` with:
- method: "update"
- owner: repository owner
- repo: repository name
- issue_number: from step 2
- body: the approved enriched body

**If success:**
- Update `originalBody` with the new body
- Display: "Issue #[issue_number] updated."
- Continue to step 8

**If error:**
- Display warning and error details
- Continue to step 8 with original content

---

## 8. Extract Key Concepts

Follow the **Extract Key Concepts Pattern** in `@{file:context/pmp.md}`.

Extract structured information from the issue body (original or enriched) based on `issueType`.

---

## 9. Complexity Assessment

Follow the **Complexity Assessment** pattern in `@{file:context/pmp.md}`.

Analyze the issue using the complexity signals and assessment by type.

### Decision

Follow the **Decision Flow** from `@{file:context/pmp.md}`:

**If appropriately sized (leaf issue):**
- Continue to step 11 (Report Success)

**If too large:**
- Continue to step 10 (Breakdown Path)

**If uncertain:**
Follow the **Decision Flow** "uncertain" handling in `@{file:context/pmp.md}#decision-flow`:
- If "A" (breakdown) → Continue to step 10 (Breakdown Path)
- If "B" (proceed) → Continue to step 11 (Report Success)

---

## 10. Breakdown Path

Follow the **Breakdown Presentation Pattern** in `@{file:context/pmp.md}`.

**Parameters:**
- `issueType`: from step 3
- `issueContext`: "Issue #[issue_number]"
- `allowSingleOption`: `false`
- `showRedistributionNote`: `true`

### Command-Specific Response Handling

| Response | Action |
|----------|--------|
| **"yes"** (Feature/Task) | Continue to step 10a (Execute Breakdown). |
| **"umbrella"** (Bug) | Continue to step 10a (Execute Breakdown). |
| **"task"** (Bug) | Display task conversion guidance. **STOP** |
| **"edit"** | Ask "What would you like to change?", **STOP and WAIT**, apply changes, re-present. |
| **"cancel"** | Follow **Print Sub-issue Commands Pattern** in `@{file:context/pmp.md}`. **STOP** |

### 10a. Execute Breakdown

Follow the **Execute Breakdown Pattern** (for `/gh.issue.edit`) in `@{file:context/pmp.md}`:

**Parameters:**
- parentIssueNumber: `issue_number` (from step 2)
- subIssueTitles: from breakdown
- subIssueTypes: from breakdown
- isExistingIssue: `true`
- originalBody: `originalBody` (from step 3)

This will:
1. Redistribute content from the leaf issue to sub-issues
2. Convert the parent to **Parent Issue Format**
3. Create sub-issues with extracted content
4. Update parent with sub-issue references

Continue to step 11 (Report Success).

---

## 11. Report Success

**If appropriately sized (leaf issue - no breakdown):**

```markdown
**Issue #[issue_number] is ready for implementation.**

No breakdown needed. Run `/gh.issue.develop #[issue_number]` to create a branch, Draft PR, and Implementation Plan.
```

**If breakdown was executed:**

Follow the **Report Sub-issue Creation Pattern** in `@{file:context/pmp.md}`:

**Parameters:**
- parentIssueNumber: from step 2
- createdSubIssues: from step 10a
- failedSubIssues: from step 10a

---

Follow the **Command Completion Pattern** in `@{file:context/cmd.md}`.
