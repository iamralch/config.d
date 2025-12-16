# Feature Issue Template

Template for generating Feature GitHub Issue bodies via `/gh.issue.create`.

---

## Issue Body Structure

```markdown
## Context

[1-2 sentences describing what this feature does and why it matters to users]

## Non-Functional Requirements

- **NFR-001**: [Security/Performance/Scalability constraint]
- **NFR-002**: [Cross-cutting quality requirement]

## Acceptance Criteria

[High-level success criteria for the entire feature]

## Out of Scope

- [Explicitly excluded item 1]
- [Explicitly excluded item 2]
```

---

## Section Guidelines

> **When breaking down into sub-issues:** See `@{file:context/pmp.md}#content-redistribution-pattern` for how each section is handled.
>
> **Feature-specific handling:**
> - **NFRs** → Preserve in parent (cross-cutting, applies to all sub-issues)

### Context
- 1-2 sentences maximum
- Describe the **what** and **why**
- Written for stakeholders, not developers
- No implementation details

### Non-Functional Requirements (Optional)
- Include only if cross-cutting quality constraints apply
- **Security**: Password hashing, encryption, auth requirements
- **Performance**: Response times, throughput, scaling
- **Reliability**: Uptime, error handling, graceful degradation
- **Usability**: Accessibility, mobile support, UX constraints
- Must be testable/verifiable
- Apply to all user stories in this feature
- Omit this section entirely if no NFRs are relevant

### Acceptance Criteria
- High-level success criteria for the feature
- Technology-agnostic (no implementation details)
- Verifiable conditions that indicate the feature is complete
- **Parent issues:** No Acceptance Criteria section needed - sub-issues contain the real criteria, and GitHub's sub-issue panel shows progress
- **Leaf issues:** Specific, testable criteria for the individual deliverable (e.g., "User can reset password via email link", "Error message displays when password is invalid")

### Out of Scope
- Explicitly list what is NOT included
- Prevents scope creep
- Clarifies boundaries for implementation

---

## Notes

- For parent issues with sub-issues, GitHub's native sub-issue tracking displays the breakdown
