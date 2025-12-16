# GitHub Operations Guide

Guidelines for GitHub operations using the GitHub MCP server tools.

---

## Tool Categories

### Repository & Authentication
| Tool | Purpose |
|------|---------|
| `github_get_me` | Get authenticated user details (verify auth works) |

### Issues
| Tool | Purpose |
|------|---------|
| `github_issue_read` | Get issue details, comments, sub-issues, labels |
| `github_issue_write` | Create or update issues (title, body, assignees, labels, state) |
| `github_sub_issue_write` | Link sub-issues to parent issues |
| `github_add_issue_comment` | Add a comment to an issue |

### Pull Requests
| Tool | Purpose |
|------|---------|
| `github_pull_request_read` | Get PR details, diff, status, files, comments, reviews |
| `github_create_pull_request` | Create a new pull request (supports draft) |
| `github_update_pull_request` | Update PR (title, body, state, reviewers, draft status) |
| `github_list_pull_requests` | List PRs with filters |
| `github_pull_request_review_write` | Create, submit, or delete PR reviews |

---

## Common Operation Patterns

These patterns appear across multiple commands. Reference them instead of duplicating.

### Fetch Issue Pattern

Standard pattern for fetching issue details:

```markdown
## Fetch Issue

Call `github_issue_read`:
- method: `"get"`
- owner: `[owner]`
- repo: `[repo]`
- issue_number: `[issueNumber]`

**On success:** Store issue details (title, body, type, state, url)

**On error:**
- If 404 → **STOP and report:** "Issue #[issueNumber] not found in [owner]/[repo]"
- If 401/403 → **STOP and report:** "Authentication failed. Run `gh auth login`"
- Other errors → **STOP and report** the error message
```

### Create Sub-issue Pattern

Standard pattern for creating and linking a sub-issue to a parent:

```markdown
## Create Sub-issue

**Step 1: Create the issue**

Call `github_issue_write`:
- method: `"create"`
- owner: `[owner]`
- repo: `[repo]`
- title: `[sub-issue title]`
- body: [Use appropriate Leaf Issue template based on type - see `@{file:context/pmp.md}#issue-body-formats`]
- type: `[issueType]` (silently inferred using Issue Type Detection from `@{file:context/pmp.md}` - no user confirmation for sub-issues)

**On success:** 
- Extract and store from response:
  - `subIssueId` - the `id` field (database/node ID) - used for API linking
  - `subIssueNumber` - the `number` field (issue number) - used for display
  - `subIssueUrl` - the issue URL
- Continue to Step 2

> **Note:** The `github_sub_issue_write` API requires the database ID (`id` field) for linking, not the issue number.

**On error:** 
- Display error message
- If in a batch creation loop, continue with remaining sub-issues
- Otherwise **STOP**

**Step 2: Link to parent**

Call `github_sub_issue_write`:
- method: `"add"`
- owner: `[owner]`
- repo: `[repo]`
- issue_number: `[parentIssueNumber]`
- sub_issue_id: `[subIssueId]` (must be the `id` field, not `number`)

**On success:** 
- Sub-issue successfully linked to parent
- Parent issue will show sub-issue in "Sub-issues" section

**On error:** 
- Display warning: "Sub-issue #[subIssueNumber] created but could not be linked to parent #[parentIssueNumber]"
- Display error details
- This is non-blocking - the sub-issue exists, just not formally linked
- Continue (sub-issue can be manually linked later)
```

**Usage Notes:**
- Always create the issue first, then link it
- Linking failure is non-blocking (issue still exists)
- Sub-issue type is inferred from the title using Issue Type Detection (can be different from parent)
- Body should use the appropriate Leaf Issue template based on type

---

## Tool Selection Guide

| Task | Use This Tool |
|------|---------------|
| Check if authenticated | `github_get_me` |
| Read issue spec | `github_issue_read` (method: get) |
| Read issue comments | `github_issue_read` (method: get_comments) |
| Create new issue | `github_issue_write` (method: create) |
| Assign issue to self | `github_issue_write` (method: update, assignees) |
| Close issue | `github_issue_write` (method: update, state: closed) |
| Add comment to issue | `github_add_issue_comment` |
| Link sub-issue to parent | `github_sub_issue_write` |
| Get sub-issues of an issue | `github_issue_read` (method: get_sub_issues) |
| Get parent of an issue | Bash: `gh api` (see `@{file:context/git.md}#get-parent-issue`) |
| Check PR status | `github_pull_request_read` (method: get) |
| Get PR diff | `github_pull_request_read` (method: get_diff) |
| Get PR files changed | `github_pull_request_read` (method: get_files) |
| Create draft PR | `github_create_pull_request` (draft: true) |
| Assign PR to self | Bash: `gh pr edit <pr-number> --add-assignee "@me"` |
| Update PR | `github_update_pull_request` |
| Find PR for branch | `github_list_pull_requests` with `head: "[owner]:[branch-name]"` filter (where `owner` is the branch owner, typically the repo owner for non-fork PRs; use `page` and `perPage` params if >30 PRs) |
| Submit PR review (approve) | `github_pull_request_review_write` (method: create, event: APPROVE) |
| Submit PR review (request changes) | `github_pull_request_review_write` (method: create, event: REQUEST_CHANGES) |
| Submit PR review (comment) | `github_pull_request_review_write` (method: create, event: COMMENT) |
| Create pending review | `github_pull_request_review_write` (method: create, no event) |
| Submit pending review | `github_pull_request_review_write` (method: submit_pending) |
| Delete pending review | `github_pull_request_review_write` (method: delete_pending) |

---

## Error Handling

### Authentication Errors
- "401" or "Unauthorized" → Run `gh auth login`
- "403" or "Forbidden" → Check repository access permissions

### Not Found Errors
- Issue/PR not found → Verify number and repository
- Repository not found → Check owner/repo spelling, access

### Validation Errors
- Invalid issue type → Use "Feature", "Task", or "Bug" (Title Case, exact match required)
- Missing required fields → Check tool documentation

> **Issue Type Casing:**
> - API type values: `Feature`, `Task`, `Bug` (Title Case)
> - Branch prefixes: `feature/`, `task/`, `bug/` (lowercase) - see `@{file:context/git.md}`

---

## Best Practices

1. **Always verify auth first** - Call `github_get_me` before operations
2. **Use specific methods** - `github_issue_read` with method parameter for different operations
3. **Check state before actions** - Verify PR is open before updating
4. **Handle errors gracefully** - Check for 404/401/403 and provide actionable guidance
