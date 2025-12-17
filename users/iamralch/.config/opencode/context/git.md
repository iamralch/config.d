# Local Git Operations Guide

Guidelines for local git operations using Bash commands. These operations complement the GitHub MCP tools which handle remote API operations.

> For state management terminology (Store, Parameters, Prerequisites), see `@{file:context/cmd.md}#state-management`

---

## Repository Validation Workflow

Before any GitHub command, perform these validation steps to ensure the user is authenticated and in a valid GitHub repository.

### Step 1: Verify Authentication

Call `github_get_me` to verify GitHub authentication.

**If authentication fails:**
- Display: "GitHub authentication required. Run: `gh auth login`"
- **STOP** - do not proceed

**If success:**
- Store the `username` for later use (e.g., assigning issues, identifying PR author)

### Step 2: Get Repository Info

Run Bash command:
```bash
git remote get-url origin
```

Parse the result to extract `owner` and `repo`:
- SSH format: `git@github.com:owner/repo.git` → extract `owner` and `repo`
- HTTPS format: `https://github.com/owner/repo.git` → extract `owner` and `repo`

**If no remote "origin":**
- Display: "Git remote 'origin' not found. Initialize git and add a GitHub remote."
- **STOP**

**If not a GitHub URL:**
- Display: "Remote is not a GitHub URL. This command only works with GitHub repositories."
- **STOP**

**If success:**
- Store `owner` and `repo` for all subsequent GitHub API operations
- Proceed to the next step in the command

### Validation Output

After successful validation, you have these variables for use in the command:

| Variable | Source | Used For |
|----------|--------|----------|
| `username` | `github_get_me` | Assigning issues, identifying user |
| `owner` | Git remote URL | All GitHub API calls |
| `repo` | Git remote URL | All GitHub API calls |

---

## Repository Information

### Get Default Branch

```bash
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
```

**Fallback:** If command fails (e.g., `refs/remotes/origin/HEAD` not set), query the remote directly:

```bash
git ls-remote --symref origin HEAD | grep 'ref:' | sed 's@.*refs/heads/@@' | sed 's@\t.*@@'
```

**Final fallback:** If both commands fail, check which common default branch exists:

```bash
git rev-parse --verify origin/main 2>/dev/null && echo "main" || (git rev-parse --verify origin/master 2>/dev/null && echo "master")
```

If none exist, use "main" as the default but warn the user: "Could not determine default branch. Assuming 'main'."

### Get Current Branch

```bash
git branch --show-current
```

---

## Branch Operations

### Branch Naming Convention

**All issue branches MUST be typed:**

| Issue Type | Branch Pattern | Example |
|------------|----------------|---------|
| Feature | `feature-[issue_number]` | `feature-42` |
| Task | `task-[issue_number]` | `task-15` |
| Bug | `bug-[issue_number]` | `bug-99` |

**Note:** Type prefix is always lowercase (`feature`, `task`, `bug`). Convert the issue type from the API (e.g., "Feature") to lowercase for the branch prefix.

**Never use:**
- `issue-[issue_number]` (untyped - not allowed)
- Custom names without issue reference

### Create and Checkout Branch Linked to Issue (Recommended)

Use `gh issue develop` to create a branch that's **formally linked** to the issue in GitHub's database. The branch will appear in the issue's "Development" section.

**Get default branch first:**
```bash
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}
```

**Create linked branch:**
```bash
gh issue develop [issue_number] --name "feature-[issue_number]" --base $DEFAULT_BRANCH --checkout
```

**Benefits:**
- Creates remote branch linked to the issue
- Creates branch from the specified base branch (via `--base`)
- Configures PR base branch automatically for `gh pr create`
- Automatically checks out locally (via `--checkout`)
- Appears in GitHub's "Development" section
- Follows branch naming convention

**Example:**
```bash
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
DEFAULT_BRANCH=${DEFAULT_BRANCH:-main}
gh issue develop 42 --name "feature-42" --base $DEFAULT_BRANCH --checkout
```

**If branch already exists:**
- Command will fail with error message
- Use "Check if Branch Exists" first to handle existing branches

### Check if Branch Exists

```bash
# Local branch
git branch --list "feature-42"

# Remote branch
git branch -r --list "origin/feature-42"

# All typed branches for an issue
git branch --list "feature-42" "task-42" "bug-42"
git branch -r --list "origin/feature-42" "origin/task-42" "origin/bug-42"
```

**If branch exists with wrong type prefix:**
- Example: Issue is Bug but `feature-42` exists (wrong type)
- Warn: "Branch `feature-42` exists but issue type is Bug (expected `bug-42`)."
- Ask: "Would you like to: A) Use existing branch anyway, B) Create correct branch `bug-42`, C) Cancel"
- **STOP and WAIT**
- If "A" → Use existing branch (accept type mismatch)
- If "B" → Create new branch with correct type prefix (the incorrect branch will remain and can be deleted manually later)
- If "C" → **STOP**

### Extract Issue Number from Branch

Parse current branch name:
```
feature-42 → 42
task-15 → 15
bug-99 → 99
```

Pattern: `[type]-[issue_number]` where type is `feature`, `task`, or `bug`

### Switch to Existing Branch

```bash
# Local branch exists
git checkout feature-42

# Remote only - create local tracking branch
git checkout -b feature-42 origin/feature-42
```

### Check Branch Has Commits

Check if a branch has commits beyond the default branch:

```bash
git log [default-branch]..[branch-name] --oneline
```

- **Empty output** → Branch has no commits (empty or just created)
- **Non-empty output** → Branch has existing work

**For remote comparison:**
```bash
git log origin/[default-branch]..[branch-name] --oneline
```

---

## Push Operations

### Push Branch with Upstream

```bash
git push -u origin feature-42
```

The `-u` flag sets up tracking so future `git push` works without specifying remote/branch.

---

## Status Checks

### Check for Uncommitted Changes

```bash
git status --porcelain
```

- Empty output → Clean working directory
- Non-empty → Has uncommitted changes

### Check if Behind Remote

```bash
git fetch origin
git rev-list --count HEAD..origin/feature-42
```

- `0` → Up to date
- `> 0` → Behind by N commits

---

## Commit Operations

### Get Staged Changes

```bash
git diff --staged
```

Returns the diff of all staged changes. Use this to analyze what will be committed.

**If output is empty:** No changes are staged for commit.

### Check for Staged Changes

```bash
git diff --staged --quiet
```

- **Exit 0:** No staged changes
- **Exit 1:** Has staged changes

Alternative using `git status`:
```bash
git diff --cached --name-only
```

Returns list of staged file names (empty if nothing staged).

### Stage All Tracked Files

```bash
git add -u
```

Stages all modifications and deletions of tracked files. Does **not** add untracked files.

**Note:** This is equivalent to `git commit -a` behavior but as a separate step.

### Create Commit

```bash
git commit -m "$commitMessage"
```

Creates a commit with the provided message.

**With additional flags:**
```bash
git commit -m "$commitMessage" --signoff --no-verify
```

Common passthrough flags:
- `--signoff` / `-s`: Add Signed-off-by trailer
- `--no-verify`: Skip pre-commit and commit-msg hooks
- `--allow-empty`: Allow empty commits
- `--author="Name <email>"`: Override author

### Amend Previous Commit

```bash
git commit --amend -m "$commitMessage"
```

Replaces the previous commit with staged changes and new message.

**Warning:** Only amend commits that haven't been pushed, or use `--force` when pushing amended commits.

---

## Issue Hierarchy Operations

### Get Parent Issue

Use the GitHub API via `gh api` to get the parent of an issue:

```bash
gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/[owner]/[repo]/issues/[issue_number]/parent
```

**On success:**
- Returns parent issue details (number, title, state, etc.)
- Use `jq` to extract specific fields: `gh api ... | jq '.number'`

**On error (no parent):**
- Returns 404 if the issue has no parent
- This means the issue is either standalone or a root parent

**Example:**
```bash
# Get parent of issue #42
gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/myorg/myrepo/issues/42/parent

# Extract just the parent issue number
gh api \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  /repos/myorg/myrepo/issues/42/parent | jq '.number'
```

**Traversing Up the Hierarchy:**
- Call this recursively to build the full hierarchy chain
- Stop when you get a 404 (reached the root)
- **Safeguards:** Limit to 10 levels max to prevent excessive recursion. Track visited issue numbers to detect circular references (stop if an issue number repeats).

> **Note:** These examples use `jq` for JSON parsing. If `jq` is not available, use the `--jq` flag built into `gh` (e.g., `gh api ... --jq '.number'`) which works identically.

**Note:** For getting sub-issues (children), use `github_issue_read` with method `"get_sub_issues"` (see `@{file:context/mcp.md}`).

---

## Sync Operations

### Fetch Latest from Remote

```bash
git fetch origin
```

### Pull Latest Changes

```bash
git pull origin feature-42
```

---

## Merge Conflict Handling

When a git operation (pull, merge, rebase) results in conflicts:

### Detect Conflicts

```bash
git status --porcelain | grep '^UU\|^AA\|^DD'
```

- `UU` = Both modified (most common)
- `AA` = Both added
- `DD` = Both deleted

### Resolution Flow

1. **Detect conflict state:**
   ```bash
   git status
   ```
   Look for "Unmerged paths" section.

2. **If conflicts detected:**
   - List conflicting files to the user
   - **STOP and WAIT** - Ask: "Merge conflicts detected in [N] files. Would you like me to attempt automatic resolution, or will you resolve manually?"
   - If "automatic" → Attempt resolution (favor incoming changes or contextual merge)
   - If "manual" → Display file list and **STOP**

3. **After resolution:**
   ```bash
   git add <resolved-files>
   git commit -m "Resolve merge conflicts"
   ```

### Abort Operations

If conflicts cannot be resolved:

```bash
# Abort merge
git merge --abort

# Abort rebase  
git rebase --abort

# Abort pull (if mid-merge)
git merge --abort
```

> **Note:** Always warn the user before aborting, as this discards in-progress merge work.

---

## Pull Request Operations

### Get Diff Between Branches

```bash
git diff origin/$baseBranch...origin/$headBranch
```

Returns the diff of changes in `headBranch` that are not in `baseBranch`.

**Note:** The three-dot (`...`) syntax shows changes since the branches diverged, which is what GitHub uses for PR diffs.

### Get Commit Log Between Branches

```bash
git log origin/$baseBranch..origin/$headBranch --oneline
```

Returns one-line summaries of commits in `headBranch` that are not in `baseBranch`.

**Note:** The two-dot (`..`) syntax shows commits reachable from `headBranch` but not from `baseBranch`.

### Check if Branch Exists on Remote

```bash
git rev-parse --verify origin/$branchName 2>/dev/null
```

- **Success (exit 0):** Branch exists on remote
- **Failure (exit non-zero):** Branch not found on remote

### Check for Existing Pull Request

Use `github_list_pull_requests` per `@{file:context/mcp.md}#tool-selection-guide`:

- Filter by `head: "[owner]:[branchName]"` to find PRs from a specific branch
- Filter by `base: "[baseBranch]"` to match target branch
- Filter by `state: "open"` to find active PRs

**Example:** Find open PR for `feature-42` targeting `main`:
- owner: repository owner
- repo: repository name
- head: `owner:feature-42`
- base: `main`
- state: `open`

---

## Error Handling

### Common Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| "not a git repository" | Not in a git repo | Initialize with `git init` or navigate to repo |
| "remote origin not found" | No origin remote | Add with `git remote add origin URL` |
| "branch already exists" | Local branch exists | Checkout existing or use different name |
| "uncommitted changes" | Dirty working directory | Commit, stash, or discard changes |
| "rejected - non-fast-forward" | Remote has new commits | Pull/rebase before push |

### Pre-operation Checks

Before branch operations:
1. Check if in a git repository
2. Check if origin remote exists
3. Check for uncommitted changes (warn if dirty)

Before push operations:
1. Check if branch has commits
2. Check if remote branch exists (for force push safety)

---

## Integration with GitHub MCP

| Operation | Local (Bash) | Remote (MCP) |
|-----------|--------------|--------------|
| Get repo info | `git remote get-url origin` | `github_get_me` (for auth) |
| Create branch | `git checkout -b` | N/A |
| Create linked branch | `gh issue develop` | N/A |
| Push branch | `git push -u origin` | N/A |
| Check branch status | `git status`, `git branch` | N/A |
| Get issue | N/A | `github_issue_read` |
| Get parent issue | `gh api .../issues/N/parent` | N/A |
| Get sub-issues | N/A | `github_issue_read` (get_sub_issues) |
| Create PR | N/A | `github_create_pull_request` |
| Update PR | N/A | `github_update_pull_request` |

**Workflow:**
1. Use Bash for local git operations (checkout, commit, push)
2. Use GitHub MCP for remote API operations (issues, PRs, comments)
3. Combine both for full workflows (see command files)
