# Bug Issue Template

Template for generating Bug GitHub Issues via `/gh.issue.create`.

---

## Issue Body Structure

```markdown
## Summary

[Brief description of the bug - what's broken]

## Severity

[Critical / High / Medium / Low]

## Steps to Reproduce

1. [First step]
2. [Second step]
3. [Third step]

## Expected Behavior

[What should happen]

## Actual Behavior

[What actually happens - include error messages if any]

## Environment

- **OS:** [e.g., macOS 14.0, Ubuntu 22.04]
- **Version:** [e.g., v1.2.3, commit hash]
- **Browser/Runtime:** [if applicable]

## Acceptance Criteria

- [ ] Bug is no longer reproducible
- [ ] Regression test added (if non-trivial bug)

## Additional Context

[Screenshots, logs, related issues, workarounds]
```

---

## Section Guidelines

> **When breaking down into sub-issues:** See `@{file:context/pmp.md}#content-redistribution-pattern` for how each section is handled.
>
> **Bug-specific handling:**
> - **Steps to Reproduce** → Adapt per sub-issue
> - **Expected/Actual Behavior** → Adapt per sub-issue
> - **Environment** → Copy to sub-issues
> - **Additional Context** → Distribute to sub-issues

### Summary
- One sentence describing what's broken
- Focus on the symptom, not the cause
- Be specific about what fails

### Severity
- **Critical**: System unusable, data loss, security vulnerability, no workaround
- **High**: Major feature broken, significant impact, workaround is painful
- **Medium**: Feature partially broken, moderate impact, workaround exists
- **Low**: Minor issue, cosmetic, edge case, easy workaround

### Steps to Reproduce
- Numbered list, specific steps
- Anyone should be able to reproduce following these
- Include test data/inputs if relevant
- Minimum steps needed to trigger the bug

### Expected vs Actual Behavior
- Clear contrast between what should happen and what does
- Include error messages verbatim
- Screenshots if visual bug

### Environment
- OS and version
- Application/library version
- Browser/runtime if applicable
- Helps identify environment-specific issues

### Acceptance Criteria
- Bug no longer reproducible (required)
- Regression test added (recommended for non-trivial bugs)
- Keep it simple - bug fixes have clear success criteria
- **Parent bugs (umbrella):** No Acceptance Criteria section needed - sub-issues contain the real criteria, and GitHub's sub-issue panel shows progress
- **Leaf bugs:** The criteria above apply

### Additional Context
- Screenshots, stack traces, logs
- Related issues or PRs
- Known workarounds
- Frequency (always, sometimes, rare)

---

## Notes

- See `@{file:context/pmp.md}#parent-issue-format` for parent issue handling and GitHub's sub-issue tracking
