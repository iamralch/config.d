# Developer Patterns

Reusable patterns for technical implementation, code quality, and development workflow.

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

## Implementation Planning Patterns

### Task Sizing Guidelines

Tasks should be:
- **Atomic**: One logical unit of work
- **Testable**: Can verify completion
- **Estimable**: 30-120 minutes each (one pomodoro to one 2-hour focused session)
- **Independent**: Minimal dependencies on other tasks (where possible)

> **Agile/XP sizing:** A well-sized task fits within a single focused work session. If a task exceeds 2 hours, consider splitting it.

### Task Ordering Principles

1. **Setup before implementation**: Bootstrapping tasks first
2. **Foundation before features**: Core abstractions before use cases
3. **Tests alongside code**: Test tasks follow implementation tasks
4. **Integration last**: Wire things together after components exist

---

## Code Quality Patterns

### Before Implementation

- Understand existing patterns in the codebase
- Follow established conventions
- Check for similar implementations to reference

### During Implementation

- Write clean, readable code
- Add appropriate comments for complex logic
- Follow the project's coding style

### After Implementation

- Verify the work compiles/runs
- Run relevant tests if applicable
- Check for unintended side effects
