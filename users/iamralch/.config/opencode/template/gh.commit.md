# Commit Message Template

Template for generating conventional commit messages via `/gh.commit`.

---

## Instructions

Generate a conventional commit message based on staged git changes.

Your goals are:

- Analyze the staged diff to understand what changed
- Determine the appropriate commit type and scope
- Write a clear, concise subject line
- Provide meaningful context in the body

### Output Requirements

- Do **not** include any introduction, preamble, meta-commentary, or sentences such as "Let me review…" or "Here is the commit message…"
- Return only the raw commit message (subject + blank line + body)
- Do **not** wrap the output in a code block or any other markdown formatting
- The output should be plain text suitable for direct use with `git commit -m`
- **Wrap the commit message in HTML comment delimiters** for extraction:

```
<!-- COMMIT_MESSAGE_START -->
<your commit message here>
<!-- COMMIT_MESSAGE_END -->
```

### Format Specifications

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Line length rules:**

- Subject line: Maximum 72 characters
- Body lines: Wrap at 72 characters
- Leave one blank line between subject and body

**Subject line rules:**

- Use imperative mood (e.g., "add" not "added" or "adds")
- Start with lowercase (except proper nouns)
- No period at end
- Use `!` after type/scope for breaking changes

---

## Commit Types

| Type | Description |
|------|-------------|
| `feat` | A new feature |
| `fix` | A bug fix |
| `docs` | Documentation only changes |
| `style` | Code style changes (formatting, missing semi-colons, etc.) |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding or updating tests |
| `build` | Changes to build system or dependencies |
| `ci` | Changes to CI configuration files and scripts |
| `chore` | Other changes that don't modify src or test files |

---

## Type Guidelines

### Determining the Right Type

| If the change... | Use type |
|------------------|----------|
| Adds new functionality visible to users | `feat` |
| Fixes incorrect behavior | `fix` |
| Only changes documentation/comments | `docs` |
| Only reformats code (no logic change) | `style` |
| Restructures code without changing behavior | `refactor` |
| Improves performance | `perf` |
| Adds or modifies tests | `test` |
| Changes build scripts, dependencies, tooling | `build` |
| Changes CI/CD configuration | `ci` |
| Maintenance tasks, version bumps | `chore` |

### Scope Guidelines

- Use lowercase
- Keep short (1-2 words)
- Derived from module, component, or area affected
- Examples: `auth`, `api`, `cli`, `parser`, `docs`

---

## Body Guidelines

- Explain **what** changed and **why** (not how - the diff shows how)
- Focus on motivation and context
- Reference issue numbers if applicable (e.g., "Fixes #123")
- Use bullet points for multiple items
- Leave blank line between paragraphs

---

## Examples

### Feature with Scope

```text
feat(auth): add OAuth2 provider support

Add support for OAuth2 authentication with configurable providers.
This enables single sign-on integration with enterprise identity
systems.

- Add OAuth2Client class for token management
- Implement callback handler for authorization flow
- Add provider configuration schema
```

### Bug Fix with Issue Reference

```text
fix: prevent racing of requests

Introduce a request id and a reference to latest request. Dismiss
incoming responses other than from latest request.

Fixes #123
```

### Breaking Change

```text
feat!: change config file format to YAML

BREAKING CHANGE: Configuration files must now use YAML format.
Existing JSON config files will not be recognized.

Migration guide:
1. Rename config.json to config.yaml
2. Convert JSON syntax to YAML
```

### Simple Documentation Change

```text
docs: correct spelling in README
```

### Refactor with Explanation

```text
refactor(parser): simplify token handling logic

Extract token validation into separate function to improve
readability and enable reuse across multiple entry points.
No behavioral changes.
```

### Multiple Changes (use bullets)

```text
chore: update dependencies and tooling

- Upgrade typescript to 5.3.0
- Update eslint configuration for new rules
- Pin node version to 20.x in CI
```

---

## Input

The staged changes are provided as an attached file.

Generate the commit message now.
