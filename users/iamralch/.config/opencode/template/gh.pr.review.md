# Pull Request Review Template

Template for generating Pull Request review content via `/gh.pr.review`.

---

## Instructions

Act as a meticulous senior developer performing a code review on the provided git changes.

Your goals are:

- Identify correctness, safety, and design issues
- Suggest concrete improvements
- Clearly mark severity and outcome so it's easy to act on your feedback
- Focus on high-signal issues and avoid low-value nitpicks

### Output Requirements

- Do **not** include any introduction, preamble, meta-commentary, or sentences such as "Let me review…" or "Here is the analysis…"
- The output **must start directly with the first section heading** (`## Summary & Outcome`)
- **Replace all placeholder text** with actual content based on the PR diff
- **Omit sections with no findings** entirely rather than writing "None" for every empty section
- When omitting sections, also omit the `---` separator that would precede the omitted section
- The `## Summary & Outcome` section is always required
- **Wrap the entire review content in HTML comment delimiters** for extraction:

```
<!-- REVIEW_CONTENT_START -->
## Summary & Outcome
...
<!-- REVIEW_CONTENT_END -->
```

### Format Specifications

- All output must be valid GitHub-flavored Markdown (GFM)
- All output must conform to `markdownlint` rules:
  - Use heading level 2 (##) for main sections
  - Use heading level 3 (###) for subsections
  - Proper list indentation (2 spaces)
  - No trailing spaces
  - Proper fenced code blocks with language tags
  - Clean paragraph breaks (one blank line between paragraphs)
- Reference code locations as `file.ext:line` or `file.ext:line1-line2`

### Review Scope & Priorities

**Prioritize:**

- Objective bugs and logic errors
- Security, data-loss, and concurrency issues
- Clear violations of project guidelines
- Performance bottlenecks
- Missing error handling

**Do not flag:**

- Pure style preferences not required by project rules
- Issues linters will catch
- Pre-existing issues not introduced in this diff
- Speculative issues that cannot be validated from the diff alone

If citing a guideline violation, quote the exact rule.

---

## Review Body Structure

```markdown
## Summary & Outcome

**Summary:**
- [2-5 bullet points summarizing the change and overall impression]

**Outcome:** [Approve | Request Changes | Comment]

---

## Code Quality & Best Practices

[Review for structure, readability, maintainability, error handling.
Provide specific and actionable comments with file references.
Keep focused on changes introduced in this diff.]

---

## Potential Issues

[Format each issue as:]

**[Severity] Issue description**

- Location: `file.ext:line` or `file.ext:line1-line2`
- Details: Explanation of the issue
- Suggestion: How to fix it

---

## Tests & Coverage

[Comment on test sufficiency, missing tests for critical paths,
edge cases that need coverage, opportunities to improve test clarity.]

---

## Improvements & Suggestions

[Offer incremental, practical suggestions:
simplifications, safer patterns, useful documentation, better abstractions.
Avoid overwhelming the author with minor nits.]

---

## Action Items

**Required Changes:**
- [ ] [High] Issue description (file.ext:line)
- [ ] [Medium] Issue description (file.ext:line)

**Advisory Notes:**
- Note: Optional improvement or consideration

---

## Positive Aspects

[Highlight what was done well:
clean abstractions, solid tests, good naming, careful handling of tricky cases.]
```

---

## Section Guidelines

### Summary & Outcome (Required)

- **Summary:** 2-5 bullet points summarizing the change and your overall impression
- **Outcome:** Must be exactly one of: `Approve`, `Request Changes`, `Comment`

### Outcome Criteria

| Outcome | When to Use |
|---------|-------------|
| **Approve** | No blocking issues; code is ready to merge |
| **Request Changes** | Has High or Medium severity issues that must be fixed before merging |
| **Comment** | Has suggestions but nothing blocking; informational review |

### Severity Levels

| Severity | Description | Blocks Approval? |
|----------|-------------|------------------|
| **High** | Bugs, security issues, data loss risk | Yes |
| **Medium** | Logic issues, missing edge cases, poor error handling | Yes |
| **Low** | Minor improvements, style suggestions | No |

### Code Quality & Best Practices (If findings)

- Structure, readability, maintainability
- Conventions, naming, modularity, separation of concerns
- Error handling and edge cases
- Code duplication or unnecessary complexity

### Potential Issues (If findings)

Each issue must include:
- Severity level: `High`, `Medium`, or `Low`
- Location: File and line reference
- Details: Clear explanation
- Suggestion: How to fix

Only include issues you have high confidence in.

### Tests & Coverage (If findings)

- Sufficiency of existing tests
- Missing tests for critical paths
- Edge cases that need coverage
- Test clarity or determinism issues

### Improvements & Suggestions (If findings)

- Simplifications or refactors
- Safer or more robust patterns
- Useful documentation or comments
- Better abstractions or code organization

### Action Items (If required changes)

- **Required Changes:** Checkboxes summarizing High and Medium severity issues from the Potential Issues section
- **Advisory Notes:** Optional improvements (no checkbox)

> **Note:** Action Items provides a quick checklist for the author. Every High/Medium issue in Potential Issues should have a corresponding checkbox here.

### Positive Aspects (Recommended)

Always try to highlight something positive:
- Clean abstractions
- Solid tests
- Good naming or comments
- Careful handling of tricky cases

---

## Input

The pull request diff is provided as an attached file.

Generate the code review now.
