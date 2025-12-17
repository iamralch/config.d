# Pull Request Template

Template for generating Pull Request content via `/gh.pr.create`.

---

## Instructions

Generate a clear, professional pull-request description based on git changes.

### Output Requirements

- Do **not** include any introduction, preamble, meta-commentary
- The output **must start with a single-line title prefixed with `#`**
- The title **must be exactly one line** (no line breaks within the title)
- The title should be a concise summary of the change (max 72 characters)
- After the title line, **must include a single blank line**, then the remaining sections
- **Replace all HTML comments** (`<!-- ... -->`) with actual content based on the git diff
- **Replace all placeholder text** (e.g., `[PR Title - ...]`, `path/to/tests`) with real values
- For sections not applicable to this PR, write "N/A" or "None" - do not leave placeholders
- **Wrap the entire PR content in HTML comment delimiters** for extraction:

```
<!-- PR_CONTENT_START -->
# PR Title here

PR body content here...
<!-- PR_CONTENT_END -->
```

### Format Specifications

- All output must be valid GitHub-flavored Markdown (GFM)
- All output must conform to `markdownlint` rules:
  - Use heading level 1 (#) for the PR title (first line only)
  - Use heading level 2 (##) for main sections
  - Use heading level 3 (###) for subsections
  - Proper list indentation (2 spaces)
  - No trailing spaces
  - Proper fenced code blocks with language tags
  - Clean paragraph breaks (one blank line between paragraphs)
- Reference code locations as `file.ext:line` or `file.ext:line1-line2`

---

## PR Body Structure

```markdown
# [PR Title - one line, max 72 characters]

## Context / Problem Statement
<!-- What problem does this PR solve? Why is it needed? -->

## High-Level Summary
<!-- Brief overview of what changed and why -->

## Risk Level
<!-- Check one -->
- [ ] Low (docs, tests, internal refactor)
- [ ] Medium (behavior change, non-critical path)
- [ ] High (core logic, data integrity, security, perf-critical)

---

## Detailed Technical Breakdown

### Behavior & Execution Flow
<!-- How the code behaves after this change -->

### Design & Architectural Decisions
<!-- Key tradeoffs, patterns, and alternatives -->

### Alternatives Considered
<!-- Other approaches evaluated and why they were rejected -->

### Assumptions & Edge Cases
<!-- Implicit assumptions, risks, edge conditions -->

---

## Testing & Validation
- [ ] **Unit Tests:** Added coverage in `path/to/tests`
- [ ] **Integration Tests:** Verifies flow X → Y
- [ ] **Manual Verification:**
    1. Run with flags `...`
    2. Input payload `{...}`
    3. Verify output `...`

---

## Impact Assessment
- **Breaking Changes:** <!-- Yes / No -->
- **Performance:** <!-- Improved / Regressed / No change -->
- **Security:** <!-- Auth, data handling, trust boundaries -->
- **Observability:** <!-- Metrics, logs, alerts -->

---

## Rollout & Deployment
- [ ] **Migrations:** Database migrations required?
- [ ] **Feature Flags:** Is this behind a flag?
- [ ] **Dependencies:** New env vars, secrets, or libraries?

---

## Post-Merge Notes
<!--
- Follow-up tasks
- Known limitations
- Monitoring expectations
-->

---

## Checklist
- [ ] Code follows project style (fmt/lint passed)
- [ ] Self-review performed
- [ ] Documentation updated
- [ ] Comments added for complex logic
```

---

## Section Guidelines

> **Handling N/A sections:** If a section doesn't apply to the PR (e.g., no migrations, no breaking changes), explicitly write "N/A" or "None" rather than leaving placeholders or omitting the section. This makes it clear the section was considered.

### Title
- Max 72 characters
- Concise summary of the change
- Use imperative mood ("Add feature" not "Added feature")

### Context / Problem Statement
- 1-2 sentences explaining the problem being solved
- Why is this change needed?

### High-Level Summary
- Brief overview of what changed
- High-level approach taken

### Risk Level
- Check exactly one option
- Consider: scope of change, criticality of affected code, data integrity

### Detailed Technical Breakdown
- **Behavior & Execution Flow:** How the code works after this change
- **Design & Architectural Decisions:** Key tradeoffs and patterns used
- **Alternatives Considered:** Other approaches and why they were rejected
- **Assumptions & Edge Cases:** Implicit assumptions and edge conditions

### Testing & Validation
- Check applicable items
- Be specific about test locations and verification steps

### Impact Assessment
- Answer each item concisely
- Be explicit about breaking changes

### Rollout & Deployment
- Check applicable items
- Note any special deployment requirements

### Post-Merge Notes
- Follow-up tasks or known limitations
- Monitoring expectations

### Checklist
- Self-review checklist before requesting review

---

## Input

The git diff and commit log are provided as attached files.

Generate the PR title and description now.
