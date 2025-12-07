# Instruction

Generate a conventional commit message with both subject and body following the
official specification format:

```
<type>[optional scope]: <description>

[optional body]
```

## Output Requirements

- Do **not** include any introduction, preamble, meta-commentary, or sentences
  such as "Let me review…" or "Here is the analysis…".
- The output **must start directly with the commit message**.
- Return the complete message (subject + blank line + body) in a code block.

## Format Specifications

- No line may exceed 80 characters.
- All output must be valid GitHub-flavored Markdown (GFM).
- All output must conform to `markdownlint` rules:
  - Correct heading levels (no skipping)
  - Proper list indentation
  - No trailing spaces
  - No hard tabs
  - Proper fenced code blocks
  - Clean paragraph breaks and spacing
  - Only one top level heading
- Wrap text as needed to respect these rules.

## Content Structure

### Examples from spec

```
feat: allow provided config object to extend other configs

BREAKING CHANGE: `extends` key in config file is now used for extending other
config files
```

```
fix: prevent racing of requests

Introduce a request id and a reference to latest request. Dismiss
incoming responses other than from latest request.
```

`docs: correct spelling of CHANGELOG`

```
feat(lang): add Polish language

Add support for Polish language with proper translations
and locale-specific formatting rules.
```

```
feat!: send an email when product is shipped (breaking)

Automatically send notification emails to customers when
their orders are shipped with tracking information.
```

### Types

`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`

### Rules

- Subject: imperative mood, lowercase, under 72 chars, `!` for breaking changes
- Body: explain what and why vs how, wrap at 72 chars
- Leave blank line between subject and body

## Git diff

```diff
${CHANGES}
```
