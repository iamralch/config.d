# Project Management Patterns

Shared patterns for issue planning, complexity assessment, and work breakdown.

---

## Terminology

| Term | Definition |
|------|------------|
| **Leaf issue** | An issue sized for direct implementation (no sub-issues). Work happens here. |
| **Parent issue** | An issue that coordinates work via sub-issues. Not implemented directly. |
| **Sub-issue** | A child of a parent issue. Can itself be a leaf or parent (if further broken down). |

---

## Issue Type Detection

Keywords and patterns for detecting issue types from user input.

### Type Indicators

| Type | Keywords & Patterns |
|------|---------------------|
| **Feature** | "add", "new", "implement", "create", "enable", "allow users to", "support for", "introduce" |
| **Task** | "update", "upgrade", "refactor", "migrate", "clean up", "maintain", "rename", "reorganize", "improve" (without new functionality) |
| **Bug** | "fix", "broken", "error", "fails", "doesn't work", "crash", "issue with", "bug", "wrong", "incorrect" |

### Detection Flow

**For new issues (e.g., `/gh.issue.create`):**

**If type is clear from description:**
- Confirm with user: "This sounds like a **[Feature/Task/Bug]**. Is that correct? (yes, or specify: feature/task/bug)"
- **STOP and WAIT**
- If user confirms ("yes") → Use inferred type
- If user specifies different type → Use their choice
- If response is unclear (e.g., "maybe", "not sure", off-topic) → Re-ask: "Please confirm the issue type: feature, task, or bug?"

**If type is ambiguous:**
- Ask: "What type of issue is this?"
  - **Feature** - New functionality or capability
  - **Task** - Maintenance, refactoring, updates
  - **Bug** - Something is broken or not working correctly
- **STOP and WAIT**

**Store:** `issueType` = Feature | Task | Bug

**For existing issues (e.g., `/gh.issue.edit`):**
- Do NOT ask the user to confirm the inferred type
- The issue already exists with established context
- Use the type from the API response if available, otherwise infer silently

---

## Content Quality Assessment

Evaluate whether an issue has sufficient detail for analysis and breakdown.

### "Thin" Issue Signals

| Type | "Rich" (Sufficient Detail) | "Thin" (Needs Enrichment) |
|------|----------------------------|---------------------------|
| **Feature** | Has user story OR clear capability + acceptance criteria OR scope definition | Roughly < 50 words, no acceptance criteria, no scope, vague "add X" |
| **Task** | Has clear objective + target component + success criteria | Roughly < 30 words, vague target, no defined outcome |
| **Bug** | Has symptom + repro steps OR expected behavior | Roughly < 30 words, no repro steps, just "X is broken" |

### Assessment Flow

1. Count words in issue body (excluding markdown formatting)
2. Check for presence of key sections based on type
3. Determine if issue is "rich" or "thin"

**If "thin" issue detected:**
- Display:
  ```markdown
  **Issue #[issue_number] lacks sufficient detail for analysis.**

  Would you like me to ask clarifying questions to enrich this issue?
  - **"yes"** → Start Q&A to gather more details
  - **"no"** → Proceed with best-effort analysis
  ```
- **STOP and WAIT**
- If "yes" → Follow **Information Gathering Pattern**
- If "no" → Continue with complexity assessment

**If "rich" issue:**
- Continue with complexity assessment

---

## Extract Key Concepts Pattern

Extract structured information from issue content based on issue type.

### For Features

| Concept | Look For |
|---------|----------|
| **Actors** | Who uses this? (users, admins, systems) |
| **Actions** | What do they want to do? |
| **Data** | What entities or information are involved? |
| **Constraints** | Any boundaries, limitations, or requirements mentioned? |

### For Tasks

| Concept | Look For |
|---------|----------|
| **Target** | What component/system is affected? |
| **Objective** | What is the end goal? |
| **Scope** | What's included in this work? |

### For Bugs

| Concept | Look For |
|---------|----------|
| **Symptom** | What's broken? What fails? |
| **Trigger** | What action causes the bug? |
| **Expected** | What should happen instead? |
| **Environment** | Any version/OS/context mentioned? |

### Usage

1. Analyze the issue content (user input or existing issue body)
2. Extract each concept based on issue type
3. Mark missing critical concepts with `[NEEDS CLARIFICATION]` (maximum 3 - prioritize gaps that block implementation: missing scope > missing success criteria > missing context)
4. Store extracted concepts for use in complexity assessment and breakdown

**Output:** Structured concepts that inform Q&A questions and complexity analysis.

---

## Information Gathering Pattern

Interactive Q&A to gather sufficient detail for issue creation or enrichment.

### Q&A Depth by Type

| Type | Depth | Question Focus |
|------|-------|----------------|
| **Feature** | 3-5 questions | Scope, user stories, acceptance criteria, edge cases |
| **Task** | 1-2 questions | Objective clarity, boundaries |
| **Bug** | 2-3 questions | Reproduction steps, environment, expected behavior |

### Rules

- Ask **ONE question at a time**
- **STOP and WAIT** for response before next question
- Stop early if user says "done", "skip", or "that's all"
- Focus questions on gaps identified in **Extract Key Concepts**

### Answer Validation

| Response Type | Action |
|---------------|--------|
| Vague or ambiguous | Ask a follow-up clarification |
| Contradicts previous answer | Point out the conflict, ask which to use |
| "done" or "skip" | Stop Q&A, proceed with what you have |
| Off-topic or counter-question | Briefly address their question, then re-ask the original |
| Clear and actionable | Record and move to next question |

### Common Questions by Type

**Feature:**
1. Who is the primary user for this feature?
2. What is the core goal they want to achieve?
3. What does success look like? (acceptance criteria)
4. Are there any edge cases or error scenarios to handle?
5. What is explicitly out of scope?

**Task:**
1. What is the specific outcome you want to achieve?
2. Are there any constraints or dependencies to consider?

**Bug:**
1. What are the exact steps to reproduce this issue?
2. What environment are you seeing this in? (OS, version, browser)
3. Does this happen every time, or intermittently?

### Output

After Q&A completion:
- Store all Q&A responses
- Update extracted key concepts with new information
- Proceed to draft generation or complexity assessment

---

## Clarifications Section Format

Standard format for including Q&A clarifications in issue bodies.

**When to include:** Only add this section if a Q&A session occurred during issue creation or enrichment.

**Format:**

```markdown
---

<details>
<summary>Clarifications</summary>

### Session [YYYY-MM-DD]

- **Q**: [Question asked] → **A**: [Answer provided]
- **Q**: [Question asked] → **A**: [Answer provided]

</details>
```

**Guidelines:**
- Use collapsible `<details>` block to reduce visual noise
- Include session date for context and auditing
- Format each Q&A pair on a single line with `→` separator
- Place at the end of the issue body, after all main sections
- Multiple sessions can be added if issue is edited multiple times

**Usage:** Referenced by all issue templates (`@{file:template/gh.issue.create.*.md}`).

---

## Complexity Assessment

Analyze issues to determine if they're appropriately sized for implementation.

### Complexity Signals (All Types)

| Signal | Suggests Too Large |
|--------|-------------------|
| **Multiple independent deliverables** | 3+ user stories (Feature), 3+ task groups (Task), 3+ bugs (Bug) |
| **Broad scope** | Multiple unrelated system components |
| **Estimated effort** | Likely exceeds 3 developer days (issues should be completable in 1-3 days) |
| **PR reviewability** | Would result in unfocused PR (500+ lines, multiple concerns) |

> **Note:** "1-3 days" refers to focused developer time for a single contributor. The goal is issues small enough to be completed, reviewed, and merged in one iteration cycle.

### Assessment by Type

**Feature issues:**
- Parse the issue body for context and requirements
- Identify user stories (explicit or implicit from requirements)
- Count independent user stories that could be delivered separately
- Look for patterns: "users can X and Y and Z" suggests multiple stories

**Task issues:**
- Parse the issue objective and context
- Identify distinct task groups that are unrelated
- Look for tasks spanning different system areas
- Check if tasks could be done independently by different developers

**Bug issues:**
- Parse the issue summary and repro steps
- Check if multiple distinct bugs are bundled together
- Identify if fix requires multiple unrelated changes
- Bugs are typically leaf issues (single fix)

### Decision Flow

| Complexity Signals | Assessment | Action |
|--------------------|------------|--------|
| 0-1 signals | **Appropriately sized (leaf issue)** | Ready for implementation - proceed to `/gh.issue.develop` |
| 2 signals | **Uncertain** | Ask user to decide (see prompt below) |
| 3+ signals | **Too large** | Offer breakdown |

**Uncertain if signals are mixed or borderline:**
- 2 complexity signals present (borderline case)
- Conflicting signals (e.g., broad scope but estimated effort < 1 day)
- Bootstrapping detected but adds only moderate work (5-10 additional tasks)

**If uncertain, STOP and WAIT:**

Ask: "This issue seems moderately complex. Would you like me to:\n  A) Break it down into smaller sub-issues\n  B) Proceed as-is (ready for implementation)"
- If "A" → Continue to breakdown path (step varies by command)
- If "B" → Mark as ready for implementation (step varies by command)

---

## Breakdown Principles

When breaking down large issues into sub-issues:

- **Vertical slices**: Each sub-issue delivers end-to-end functionality
- **Independent**: Sub-issues can be worked on and merged separately
- **Sized right**: Each sub-issue should be completable in a single PR (roughly 1-3 developer days)
- **Complete**: All sub-issues together cover the parent's scope

### Sub-issue Count Guidelines

| Parent Complexity | Sub-issues |
|-------------------|------------|
| Moderately large | 2-3 |
| Large | 3-4 |
| Very large | 4-5 |

**Never exceed 5 sub-issues** - if breakdown analysis identifies more than 5 pieces, create a hierarchy: group related items into 2-4 parent sub-issues, each of which can be further broken down via `/gh.issue.edit` after creation.

---

## Issue Title Patterns

Title patterns for issues and sub-issues by type.

### Feature Titles

**Patterns:**
- `User can [action]`
- `[Capability] for [user type]`
- `[Feature] [outcome]`
- `[Component] [specific capability]`

**Examples:**
- `User can authenticate via OAuth`
- `User can reset password via email`
- `Dashboard displays real-time metrics`
- `Export functionality for report data`
- `User can filter search results by date`

### Task Titles

**Patterns:**
- `Update [component/dependency]`
- `Refactor [area]`
- `Migrate [from] to [to]`
- `Extract [component]`
- `Clean up [area]`

**Examples:**
- `Extract authentication logic to service`
- `Refactor database connection handling`
- `Update dependencies to latest versions`
- `Migrate from REST to GraphQL`
- `Clean up unused utility functions`

### Bug Titles

**Patterns:**
- `[Component] fails when [action]`
- `[Error] when [doing something]`
- `[Thing] not working in [context]`
- `Fix [specific symptom]`

**Examples:**
- `Fix login timeout on slow connections`
- `Dashboard correctly displays UTC timestamps`
- `API returns 500 when request body is empty`
- `Search fails when query contains special characters`

---

## Issue Body Formats

Different formats for leaf issues (ready for implementation) vs parent issues (overview with sub-issues).

### Leaf Issue Format

Leaf issues contain detailed content ready for implementation. Use the appropriate template based on type:

| Type | Template |
|------|----------|
| Feature | `@{file:template/gh.issue.create.feature.md}` |
| Task | `@{file:template/gh.issue.create.task.md}` |
| Bug | `@{file:template/gh.issue.create.bug.md}` |

### Parent Issue Format

Parent issues provide an overview and reference their sub-issues. Use this format:

```markdown
## Overview

[High-level description of the feature/task/bug collection - 2-3 sentences]

## Scope

[What this parent issue covers at a high level]

## Non-Functional Requirements (if applicable)

[Preserved from original - cross-cutting quality constraints that apply to all sub-issues]

## Out of Scope

[Preserved from original - boundaries for the whole effort]
```

> **Notes:**
> - Overview and Scope are required; Non-Functional Requirements (NFRs) and Out of Scope are optional
> - GitHub's sub-issue panel shows linked sub-issues and progress

### Choosing the Format

| Scenario | Format |
|----------|--------|
| Issue is appropriately sized (leaf) | Leaf Issue Format |
| Issue needs breakdown | Parent Issue Format |
| Creating sub-issues | Leaf Issue Format (each sub-issue) |
| Converting leaf to parent during breakdown | Restructure to Parent Issue Format |

---

## Breakdown Presentation Pattern

Unified pattern for presenting breakdown proposals. Used by both `/gh.issue.create` and `/gh.issue.edit`.

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `issueType` | Feature \| Task \| Bug | The type of issue being broken down |
| `issueContext` | string | "This issue" (for create) or "Issue #[N]" (for edit) |
| `subIssueTitles` | array | List of proposed sub-issue titles |
| `subIssueTypes` | array | Inferred type for each sub-issue |
| `allowSingleOption` | boolean | Whether to show "single" option (true for create, false for edit) |
| `showRedistributionNote` | boolean | Whether to show content redistribution note (false for create, true for edit) |

### Step 1: Generate Breakdown

Based on `issueType`:
- **Feature:** Follow **Breakdown Flow: Feature** - identify user stories/capabilities, generate sub-issue titles (see Sub-issue Count Guidelines for counts: 2-3 for moderately large, 3-4 for large, 4-5 for very large)
- **Task:** Follow **Breakdown Flow: Task** - identify task groups/system areas, generate sub-issue titles per Sub-issue Count Guidelines
- **Bug:** Follow **Breakdown Flow: Bug** - identify distinct bugs/fixes bundled together

### Step 2: Infer Sub-issue Types

Follow the **Sub-issue Type Inference** pattern.

### Step 3: Present for Approval

**If Feature or Task:**

```markdown
**[issueContext] is too large for a single implementation.**

I recommend breaking it down into [N] sub-issues:

1. **[Sub-issue title 1]** ([Type])
2. **[Sub-issue title 2]** ([Type])
3. **[Sub-issue title 3]** ([Type])

*Sub-issue types inferred from titles. Use "edit" to change.*

[If showRedistributionNote = true:]
**Note:** The current issue will be converted to a parent issue, and its content will be redistributed to the sub-issues.

---

How would you like to proceed?
- **"yes"** → Create [parent issue with these sub-issues / sub-issues and restructure parent]
- **"edit"** → Modify the breakdown
[If allowSingleOption = true:]
- **"single"** → Create as single issue (no breakdown)
- **"cancel"** → [Abort without creating / Show commands to create manually]
```

**If Bug:**

```markdown
**[issueContext] appears to contain multiple distinct issues.**

I identified:

1. **[Bug/fix 1]** ([Type])
2. **[Bug/fix 2]** ([Type])
3. **[Bug/fix 3]** ([Type])

*Sub-issue types inferred from titles. Use "edit" to change.*

[If showRedistributionNote = true:]
**Note:** The current issue will be converted to a parent issue, and its content will be redistributed to the sub-issues.

---

How would you like to proceed?
- **"umbrella"** → [Create parent bug with these sub-issues / Keep as parent, create sub-issues]
[If allowSingleOption = true:]
- **"single"** → Create as single bug (no breakdown)
- **"task"** → Display task conversion guidance, **STOP**
- **"cancel"** → [Abort without creating / Show commands to create manually]
```

**STOP and WAIT** for explicit confirmation.

### Step 4: Handle Response

**Common responses:**

| Response | Action |
|----------|--------|
| **"edit"** | Ask "What would you like to change?", apply changes, re-present breakdown |

**Feature/Task responses:**

| Response | Condition | Action |
|----------|-----------|--------|
| **"yes"** | always | Execute breakdown (create sub-issues) |
| **"single"** | if `allowSingleOption` | Create as single leaf issue |
| **"cancel"** | always | If create: "Cancelled. No issue created." STOP. If edit: Print manual commands, STOP |

**Bug responses:**

| Response | Condition | Action |
|----------|-----------|--------|
| **"umbrella"** | always | Execute breakdown (create sub-issues) |
| **"single"** | if `allowSingleOption` | Create as single leaf bug |
| **"task"** | always | Display task conversion guidance, STOP |
| **"cancel"** | always | If create: "Cancelled. No issue created." STOP. If edit: Print manual commands, STOP |

### Task Conversion Guidance (For Bugs)

When user selects "task" for a bug that contains multiple distinct issues, display:

```markdown
**Converting to Task**

If this issue represents maintenance or cleanup work rather than a bug fix, you can create it as a Task instead.

**To create as a Task:**
- For new issue: Re-run `/gh.issue.create` and describe it as maintenance/refactoring work
- For existing issue: Update via API using `github_issue_write` with `type: "Task"`, or edit the issue type on GitHub

**When to use Task instead of Bug:**
- Multiple unrelated changes bundled together → Task with sub-tasks
- Cleanup triggered by a bug → Task (the bug is a symptom, not the work)
- Refactoring that incidentally fixes issues → Task
- Technical debt reduction → Task

**If this is genuinely multiple bugs:**
Choose "umbrella" to create a parent bug with sub-issues for each distinct bug.
```

**STOP**

---

## Breakdown Flow: Feature

Break down large Features into smaller, independently deliverable feature sub-issues.

**Identify work units:**
- User stories (explicit or implicit from requirements)
- Distinct capabilities (separate user-facing functions)
- Independent components with user value

**Feature-specific guidance:**
- Each sub-issue should deliver **end-to-end user value** (vertical slice)
- User should be able to **test/demo each sub-issue independently**
- Avoid horizontal slices (e.g., "backend for X", "frontend for X" as separate issues)
- Ask: "Could we release this sub-issue alone and users would benefit?"

**Generate sub-issue titles:**
- Follow **Issue Title Patterns > Feature Titles**
- Patterns: `User can [action]`, `[Capability] for [user type]`
- Ensure each is independent and deliverable

---

## Breakdown Flow: Task

Break down large Tasks into smaller, logically grouped task sub-issues.

**Identify work units:**
- Task groups (related operations that belong together)
- System areas (different components/modules affected)
- Phases (logical ordering of work)

**Task-specific guidance:**
- Each sub-issue should be a **logical unit of work**
- Consider **dependencies**: Can these be done in parallel or must they be sequential?
- Consider **ordering**: Does one task enable or block another?
- Avoid mixing unrelated system areas in a single sub-issue

**Generate sub-issue titles:**
- Follow **Issue Title Patterns > Task Titles**
- Patterns: `Update [component]`, `Refactor [area]`, `Extract [component]`
- Ensure each is independent where possible

---

## Breakdown Flow: Bug

Bugs are typically leaf issues. If analysis reveals multiple distinct bugs bundled together, offer breakdown.

**Identify distinct issues:**
- Look for multiple symptoms or failure modes
- Check if different components are affected
- Identify if fixes are independent

**Generate sub-issue titles:**
- Follow **Issue Title Patterns** (Bug patterns)
- Each should represent a single fix

---

## Breakdown Path Selection

When breakdown is needed, select the appropriate flow based on `issueType`.

**Process:**

1. **Infer sub-issue types** for all proposed sub-issues:
   - Follow the **Sub-issue Type Inference** pattern

2. **Select breakdown flow** based on `issueType`:

   **If Feature:**
   - Follow **Breakdown Flow: Feature**
   - Present with options: "yes" / "edit" / "cancel" (or "single" for `/gh.issue.create`)

   **If Task:**
   - Follow **Breakdown Flow: Task**
   - Present with options: "yes" / "edit" / "cancel" (or "single" for `/gh.issue.create`)

   **If Bug:**
   - Follow **Breakdown Flow: Bug**
   - Present with options: "umbrella" / "task" / "cancel"

3. **Handle responses** as defined in each flow

### Response Handling Summary

| Issue Type | Response | Action |
|------------|----------|--------|
| Feature/Task | "yes" | Execute breakdown |
| Feature/Task | "edit" | Modify and re-present |
| Feature/Task | "single" | Create as single issue (create only) |
| Feature/Task | "cancel" | Print manual commands, STOP |
| Bug | "umbrella" | Execute breakdown (keep as parent) |
| Bug | "task" | Display task conversion guidance, STOP |
| Bug | "cancel" | Print manual commands, STOP |

**Usage:** Both `/gh.issue.create` and `/gh.issue.edit` use this pattern to handle breakdown consistently.

---

## Sub-issue Type Inference

When generating a breakdown, each sub-issue should have its type inferred from its title.

**Process:**

For each sub-issue title in the breakdown, use the **Type Indicators** table from Issue Type Detection (the keywords/patterns, NOT the full Detection Flow with user confirmation):

1. Analyze the title for type indicators (keywords, patterns)
2. Infer the most appropriate type: Feature, Task, or Bug
3. Store the result in a `subIssueTypes` array

> **Note:** Do NOT prompt the user to confirm inferred types for sub-issues. Infer silently based on the title content.

**Store:** `subIssueTypes = [type1, type2, type3, ...]`

**Examples:**

| Sub-issue Title | Inferred Type | Reason |
|-----------------|---------------|--------|
| "Fix login timeout on slow connections" | Bug | "Fix" keyword |
| "User can export dashboard as PDF" | Feature | "User can" pattern |
| "Refactor authentication middleware" | Task | "Refactor" keyword |
| "Update dependencies to latest versions" | Task | "Update" keyword |
| "Add password reset functionality" | Feature | "Add" new capability |

**Usage:** This pattern is used in both `/gh.issue.create` (Step 7b) and `/gh.issue.edit` (Step 10) when generating breakdowns.

---

## Create Sub-issues Pattern

Standard pattern for creating multiple sub-issues and linking them to a parent issue.

**Prerequisites:**
- `parentIssueNumber`: The parent issue number
- `subIssueTitles`: Array of sub-issue titles
- `subIssueTypes`: Array of inferred types (from Sub-issue Type Inference)
- `subIssueBodies`: (Optional) Array of bodies - if provided, use these; otherwise generate using Leaf Issue template
- Repository context: `owner`, `repo`

**Process:**

Loop through each sub-issue (index `i`):

1. **Create the issue**
   
   Call `github_issue_write` with:
   - method: "create"
   - owner: `[owner]`
   - repo: `[repo]`
   - title: `subIssueTitles[i]`
   - body: `subIssueBodies[i]` (if available) or generate using appropriate Leaf Issue template based on `subIssueTypes[i]`
   - type: `subIssueTypes[i]`

2. **Link to parent**
   
   Call `github_sub_issue_write` with:
   - method: "add"
   - owner: `[owner]`
   - repo: `[repo]`
   - issue_number: `[parentIssueNumber]`
   - sub_issue_id: created issue ID from step 1

3. **Handle errors**
   
   - If creation fails: Store failed title, continue with remaining sub-issues
   - If linking fails: Warn but continue (issue exists, just not formally linked)

**After all sub-issues:**
- Store arrays of: `createdSubIssues = [{number, title, url}, ...]`
- Store array of: `failedSubIssues = [title1, title2, ...]`

**Error Handling:**
- Partial success is acceptable (some created, some failed)
- Always continue with remaining sub-issues after a failure
- Report both successes and failures at the end

**Reference:** See `@{file:context/mcp.md}#create-sub-issue-pattern` for detailed API usage.

---

## Print Sub-issue Commands Pattern

Format for outputting commands when user chooses "cancel" during breakdown.

**Prerequisites:**
- `parentIssueNumber`: The parent issue number
- `subIssueTitles`: Array of sub-issue titles

**Output Format:**

```markdown
**Create these sub-issues:**

\```
/gh.issue.create "[Sub-issue title 1]" --parent #[parentIssueNumber]
\```

\```
/gh.issue.create "[Sub-issue title 2]" --parent #[parentIssueNumber]
\```

\```
/gh.issue.create "[Sub-issue title 3]" --parent #[parentIssueNumber]
\```

**After creating each sub-issue, run `/gh.issue.edit` on it if needed.**
```

**STOP** after displaying commands.

**Usage:** When user chooses "cancel" during breakdown, display these commands instead of auto-creating sub-issues.

---

## Report Sub-issue Creation Pattern

Standard format for reporting created sub-issues after auto-creation.

**Prerequisites:**
- `parentIssueNumber`: The parent issue number
- `createdSubIssues`: Array of successfully created sub-issues
- `failedSubIssues`: Array of titles that failed to create (may be empty)

**Success Report Format:**

```markdown
**Created [N] sub-issues for #[parentIssueNumber]:**
- #[number1] - [title1]
- #[number2] - [title2]
- #[number3] - [title3]

**Next steps:**
- Review the parent and sub-issues on GitHub
- Run `/gh.issue.edit #[sub-issue]` on each sub-issue to add details if needed
- Run `/gh.issue.develop #[sub-issue]` to start work on individual sub-issues
```

**If any sub-issue creation failed, also show:**

```markdown
**Failed sub-issues** (create these manually):

\```
/gh.issue.create "[Failed title 1]" --parent #[parentIssueNumber]
\```

\```
/gh.issue.create "[Failed title 2]" --parent #[parentIssueNumber]
\```
```

**STOP** after displaying the report.

---

## Content Redistribution Pattern

When breaking down an existing leaf issue, redistribute its content to sub-issues and convert the leaf to a parent.

**Prerequisites:**
- `parentIssueNumber`: The issue being broken down
- `originalBody`: The current issue body (leaf format)
- `subIssueTitles`: Array of sub-issue titles from breakdown
- `subIssueTypes`: Array of inferred types
- `extractedConcepts`: Key concepts extracted from original issue

**Process:**

### Step 1: Extract Content for Sub-issues

For each sub-issue title, identify relevant content from the original issue:

1. Analyze which requirements/sections relate to each sub-issue
2. Extract relevant:
   - Requirements/user stories
   - Acceptance criteria
   - Technical details
   - Constraints specific to that sub-issue

**Content Handling Terms:**
- **Preserve in parent** = Keep in parent body only; do not include in sub-issues
- **Adapt per sub-issue** = Rewrite specifically for each sub-issue based on its scope
- **Copy to sub-issues** = Duplicate as-is to each sub-issue
- **Distribute to sub-issues** = Split relevant portions to relevant sub-issues only

**Section Handling (All Types):**
- **Context/Summary/Objective** → Summarize in parent Overview; adapt per sub-issue
- **Acceptance Criteria** → Distribute to sub-issues
- **Out of Scope** → Preserve in parent

> **Type-specific handling:** See the relevant template for additional sections.

**Store:** `subIssueBodies = [body1, body2, body3, ...]`

### Step 2: Generate Sub-issue Bodies

For each sub-issue, generate a body using the **Leaf Issue Format**:

- Use appropriate template based on `subIssueTypes[i]`
- Include extracted content from step 1
- Apply type-specific section handling from the relevant template
- Include relevant acceptance criteria distributed from the parent

### Step 3: Generate New Parent Body

Convert the original issue to **Parent Issue Format**:

```markdown
## Overview

[Summarize the original issue objective in 2-3 sentences]

## Scope

[High-level scope from original issue]

## Non-Functional Requirements (if applicable)

[Preserve from original - cross-cutting quality constraints]

## Out of Scope

[Preserve from original - boundaries for the whole effort]
```

> **Note:** Acceptance criteria are distributed to sub-issues. NFRs and Out of Scope remain in parent as they apply to all sub-issues. GitHub's sub-issue panel shows completion progress.

**Store:** `newParentBody`

### Step 4: Update Parent Issue on GitHub

Call `github_issue_write` with:
- method: "update"
- owner: `[owner]`
- repo: `[repo]`
- issue_number: `[parentIssueNumber]`
- body: `newParentBody`

**Output:**
- `newParentBody`: The restructured parent body
- `subIssueBodies`: Array of bodies for each sub-issue

---

## Execute Breakdown Pattern

Execute sub-issue creation after user confirms a breakdown with "yes".

**Prerequisites:**
- `parentIssueNumber`: The parent issue number
- `subIssueTitles`: Array of sub-issue titles
- `subIssueTypes`: Array of inferred types (from Sub-issue Type Inference)
- `isExistingIssue`: Boolean - true if breaking down existing issue (from `/gh.issue.edit`)
- `originalBody`: If `isExistingIssue`, the original issue body

**Process:**

### For `/gh.issue.edit` (Breaking Down Existing Issue)

1. **Redistribute content**

   Follow the **Content Redistribution Pattern** above.
   
   **Parameters:**
   - parentIssueNumber: from prerequisites
   - originalBody: from prerequisites
   - subIssueTitles: from prerequisites
   - subIssueTypes: from prerequisites

2. **Create sub-issues with extracted content**

   Follow the **Create Sub-issues Pattern**, passing `subIssueBodies` from step 1.

3. **Report results**

   Follow the **Report Sub-issue Creation Pattern** above.

### For `/gh.issue.create` (Creating New Parent + Sub-issues)

1. **Parent issue already created**

   The parent issue was created in step 9a of `/gh.issue.create`. Its body is already in **Parent Issue Format**.

2. **Create sub-issues**

   Follow the **Create Sub-issues Pattern**.
   
   **Parameters:**
   - parentIssueNumber: newly created parent issue number
   - subIssueTitles: from prerequisites
   - subIssueTypes: from prerequisites

3. **Update parent with sub-issue references**

   Call `github_issue_write` with:
   - method: "update"
   - owner: `[owner]`
   - repo: `[repo]`
   - issue_number: `[parentIssueNumber]`
   - body: parent body with sub-issue numbers filled in

4. **Report results**

   Follow the **Report Sub-issue Creation Pattern** above.

**STOP**

---

## Bootstrapping Detection

Identify when an issue requires foundational setup work before implementation can begin.

**Usage:**
- **Complexity assessment:** Estimate from issue description to determine if breakdown is needed
- **Implementation planning:** Scan codebase to generate Phase 1 setup tasks

### Bootstrapping Signals

| Signal | What to Look For | Examples |
|--------|------------------|----------|
| **New module/component** | Feature mentions area that doesn't exist in codebase | "Add authentication system" (no auth/ directory exists) |
| **New dependencies** | Feature requires external libraries not in manifest | "Use Redis for caching" (no redis in package.json) |
| **New configuration** | Feature needs env vars, config files, or setup | "Connect to Stripe API" (no Stripe config exists) |
| **Greenfield area** | No existing code in this domain/layer | "Add GraphQL API" (no GraphQL code exists) |
| **Database changes** | New tables, migrations, or schema updates needed | "Store user preferences" (no preferences table) |
| **API integrations** | Third-party service integration required | "Send emails via SendGrid" (no email service) |

### Impact on Complexity Assessment

**Bootstrapping increases implementation complexity:**
- **Without bootstrapping:** Feature builds on existing foundation → Lower complexity
- **With bootstrapping:** Feature requires foundation building → Higher complexity

**When assessing issue size:**
- Count bootstrapping tasks as part of total work
- Each bootstrapping signal typically adds 1-3 setup tasks
- Multiple signals may compound (e.g., new module + new dependency + config)

**Example:**
- "Add password reset endpoint" (existing auth system) → Simple (3-5 tasks)
- "Add authentication system with password reset" (no auth) → Complex (12+ tasks, includes bootstrapping)

### Impact on Implementation Plan

**Phase 1: Setup must include bootstrapping tasks when detected:**

| Signal Detected | Phase 1 Tasks |
|-----------------|---------------|
| **New module/component** | Create directory structure, base files, exports |
| **New dependencies** | Add to package manifest, install, verify compatibility |
| **New configuration** | Create config files, add env var templates, update docs |
| **Greenfield area** | Set up layer structure, establish patterns, add integration points |
| **Database changes** | Create migration files, update schema, add seed data |
| **API integrations** | Add client library, create service wrapper, add credentials management |

**Bootstrapping tasks ALWAYS come first in Phase 1:**
- You can't implement features without the foundation
- Setup tasks block core implementation tasks
- Order: Bootstrapping → Code-level setup → Core implementation

**Task format examples:**
- `- [ ] T001 Create directory structure in \`src/features/auth/\`` (bootstrapping)
- `- [ ] T002 Install dependencies: passport, jsonwebtoken in \`package.json\`` (bootstrapping)
- `- [ ] T003 Create config/auth.ts for auth configuration` (bootstrapping)
- `- [ ] T004 Create AuthService interface in \`src/features/auth/types.ts\`` (code-level setup)

---

## Issue Readiness Check

After complexity assessment, determine the next step:

| Status | Guidance |
|--------|----------|
| **Ready (leaf issue)** | "Run `/gh.issue.develop #[issue_number]` to create a branch, Draft PR, and Implementation Plan." |
| **Needs breakdown** | Offer breakdown inline (in `/gh.issue.create`) or suggest `/gh.issue.edit #[issue_number]` |
| **Has sub-issues** | "Run `/gh.issue.edit` on each sub-issue if needed, then `/gh.issue.develop` to start work on individual sub-issues." |
| **Broken down** | "Parent issue #[N] created with [M] sub-issues. Run `/gh.issue.develop` on each sub-issue when ready." |

---

## Check for Existing Sub-issues

When analyzing an existing issue, check if it already has sub-issues.

### API Call

Call `github_issue_read` with:
- method: `"get_sub_issues"`
- owner: `[owner]`
- repo: `[repo]`
- issue_number: `[issueNumber]`

### If Issue Has Sub-issues

Display context-appropriate guidance based on the command:

**For `/gh.issue.edit`:**

```markdown
**Issue #[issue_number] is a parent issue with [N] sub-issues:**

- #[sub1] - [title]
- #[sub2] - [title]
- #[sub3] - [title]

**Actions:**
- Edit a sub-issue: `/gh.issue.edit #[sub-issue-number]`
- Add a sub-issue: `/gh.issue.create "title" --parent #[issue_number]`
- Break down a sub-issue further: `/gh.issue.edit #[sub-issue-number]`

**To edit the parent overview directly, use GitHub UI.**
```

**STOP**

**For `/gh.issue.develop`:**

```markdown
**Cannot develop Issue #[issue_number]: This is a parent issue with sub-issues.**

This issue has [N] sub-issues that should be worked on individually:
- #[sub1] - [title] ([state])
- #[sub2] - [title] ([state])
- #[sub3] - [title] ([state])

**Next steps:**
- Work on individual sub-issues using `/gh.issue.develop #[sub-issue-number]`
- Once all sub-issues are complete, close the parent issue
```

**STOP** - Parent issues cannot be developed directly.

### If No Sub-issues

- For `/gh.issue.edit`: Continue with content quality assessment
- For `/gh.issue.develop`: Continue with issue type validation
- For other contexts: Continue with complexity assessment
