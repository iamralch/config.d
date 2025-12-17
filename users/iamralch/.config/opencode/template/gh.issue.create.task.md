# Task Issue Template

Template for generating Task/Chore GitHub Issues via `/gh.issue.create`.

---

## Issue Body Structure

```markdown
## Context

[What needs to be done and why - 1-2 sentences]

## Objective

[Clear statement of the goal]

## Acceptance Criteria

[How we know it's done]

## Out of Scope

[What this doesn't include]
```

---

## Section Guidelines

> **When breaking down into sub-issues:** See `@{file:context/pmp.md}#content-redistribution-pattern` for how each section is handled.

### Context
- 1-2 sentences maximum
- What maintenance/update is needed and why
- No implementation details

### Objective
- Single clear statement of the goal
- What state should we be in after this is done?

### Acceptance Criteria
- How we verify the task is complete
- Usually simpler than Feature criteria
- **Parent tasks:** No Acceptance Criteria section needed - sub-issues contain the real criteria, and GitHub's sub-issue panel shows progress
- **Leaf tasks:** Specific criteria for the individual task

### Out of Scope
- What this task does NOT include
- Prevents scope creep

---

## Notes

- See `@{file:context/pmp.md}#parent-issue-format` for parent issue handling and GitHub's sub-issue tracking
- Sub-issues can be any type (Task, Feature, or Bug) based on the work needed
