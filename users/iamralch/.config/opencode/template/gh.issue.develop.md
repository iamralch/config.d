# PR Body Template for Draft PR

Template for generating Draft PR bodies via `/gh.issue.develop`.

---

## Body Structure

```markdown
## Context

[From issue Context section - what problem are we solving and why?]

## Technical Approach

**Stack:** [Language/Runtime] | [Framework] | [Testing]

**Key Files:**
- `path/to/file.ts` - [Purpose of this file]
- `path/to/other.ts` - [Purpose of this file]

**Design Decisions:**
- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

## Implementation Plan

### Phase 1: Setup
- [ ] T001 [Task description] in `path/to/file`
- [ ] T002 [Task description] in `path/to/file`

### Phase 2: Core Implementation
- [ ] T003 [Task description] in `path/to/file`
- [ ] T004 [Task description] in `path/to/file`
- [ ] T005 [Task description] in `path/to/file`

### Phase 3: Testing & Polish
- [ ] T006 [Task description] in `path/to/file`
- [ ] T007 [Task description] in `path/to/file`


```

---

## Section Guidelines

### Context

- Copy directly from the issue's Context section
- This explains **what** we're building and **why**
- Keep it concise (1-2 paragraphs)
- Should be clear to someone who hasn't read the issue

### Technical Approach

**Stack:**
- Detected from codebase scan (check manifest files like `package.json`, `go.mod`, `Cargo.toml`, etc.)
- Format: `Language/Runtime | Framework | Testing`
- Example: `TypeScript/Bun | Hono | Vitest`
- Example: `Go 1.21 | None | stdlib testing`

**Key Files:**
- List 3-7 main files that will be created or modified
- Include the file path and a brief purpose comment
- Follow existing project structure conventions
- Help the reviewer understand the scope at a glance

**Design Decisions:**
- List 2-4 non-obvious technical choices
- Each decision should have a clear rationale
- Focus on **why**, not **what** (code shows what)
- Examples:
  - "Using dependency injection for testability"
  - "Storing state in memory (requirements don't mention persistence)"
  - "Validating input at API boundary (fail fast)"

---

## Implementation Plan

### Task Granularity

Adapt task detail based on feature complexity:

| Complexity | Total Tasks | Indicators |
|------------|-------------|------------|
| **Simple** | 3-5 | Single user story, few requirements, no new dependencies |
| **Medium** | 6-10 | 2-3 user stories, moderate requirements, some new code |
| **Complex** | 10-15 | Multiple user stories, many requirements, architectural changes |

### Phase Guidelines

**Phase 1: Setup**
- **Bootstrapping tasks** (if needed - see `@{file:context/dev.md}#bootstrapping-detection`)
  - New module/component directory structure
  - New dependencies installation
  - New configuration files
  - Database migrations
  - API integration scaffolding
- **Code-level setup tasks**
  - Base classes/interfaces
  - Route/endpoint definitions
  - Initial data structures
- Typically 1-4 tasks (more if bootstrapping required)

**Phase 2: Core Implementation**
- Main feature implementation
- Derived from issue Context + Acceptance Criteria
- Each task should be completable in one focused session (30-120 minutes)
- Typically 3-8 tasks depending on complexity (max 8 per phase)
- **If exceeding 8 tasks:** Create additional phases (Phase 2a, 2b, or "Phase 2: Core - Part 1", "Phase 2: Core - Part 2") to keep each phase focused and reviewable

**Phase 3: Testing & Polish**
- Tests based on Acceptance Criteria
- Documentation updates
- Code cleanup and refactoring
- Typically 2-4 tasks

---

## Task Format

Each task MUST include:
- **Task ID**: Sequential number (`T001`, `T002`, etc.) - continuous across all phases
- **File path**: Where applicable, include the target file/directory in backticks
- **Checkbox**: GitHub-style `- [ ]` for tracking

**Format:**
```markdown
- [ ] T001 Description with `path/to/file`
```

**Examples:**
- `- [ ] T001 Create directory structure in \`src/features/auth/\`` ✓
- `- [ ] T003 Create UserModel in \`src/models/user.ts\`` ✓
- `- [ ] Create auth module` ✗ (missing ID and path)

---

## Deriving Tasks from Issue Spec

| Issue Section | Maps To |
|---------------|---------|
| Context | Background context for Phase 2 task planning |
| Acceptance Criteria | Phase 2 core tasks, Phase 3 test tasks |
| Non-Functional Requirements | Phase 3 validation tasks (Feature issues only) |
| Out of Scope | (Explicitly avoid) (Feature/Task issues only) |

> **NFR validation example:** If an NFR states "Response time < 200ms", derive a task like: `- [ ] T012 Add performance test validating <200ms response in \`tests/perf/\``

**Deriving tasks:**
- Derive implementation tasks from Acceptance Criteria
- Each acceptance criterion typically becomes 1-2 tasks in Phase 2

---

## Quality Checklist

Before presenting the draft, verify:

- [ ] Context section is clear and from the issue
- [ ] Stack detection matches the actual codebase
- [ ] File paths follow existing project structure
- [ ] Design decisions have clear rationale
- [ ] Tasks have sequential IDs (T001, T002, ...)
- [ ] Tasks include file paths in backticks
- [ ] Tasks are appropriately sized (1 session each)
- [ ] All checkboxes use `[ ]` format (not `[x]`)
- [ ] Issue link points to correct issue number

---

## Common Patterns

### For TypeScript/Bun projects
```markdown
**Stack:** TypeScript/Bun | [Framework or None] | Vitest

**Key Files:**
- `src/features/[feature]/handler.ts` - Main handler implementation
- `src/features/[feature]/types.ts` - Type definitions
- `tests/[feature]/handler.test.ts` - Unit tests
```

### For Go projects
```markdown
**Stack:** Go 1.21 | [Framework or None] | stdlib testing

**Key Files:**
- `internal/[feature]/handler.go` - Main handler
- `internal/[feature]/types.go` - Type definitions
- `internal/[feature]/handler_test.go` - Unit tests
```

### For Python projects
```markdown
**Stack:** Python 3.12 | [Framework] | pytest

**Key Files:**
- `src/[feature]/handler.py` - Main implementation
- `src/[feature]/types.py` - Type definitions
- `tests/test_[feature].py` - Unit tests
```

---

## Notes on Draft PR

This is a **Draft PR** created at the start of work:
- The Implementation Plan is the primary content
- Tasks will be checked off as work progresses
- The PR body can be updated anytime
- When all tasks are complete, mark PR as "Ready for Review"
- At that point, optionally expand the PR body with more details (testing, impact, etc.)