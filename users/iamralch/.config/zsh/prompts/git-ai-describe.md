# Instruction

Generate a clear, professional pull-request description based on these git
changes.

## Output Requirements

- Do **not** include any introduction, preamble, meta-commentary, or sentences
  such as "Let me review…" or "Here is the analysis…".
- The output **must start directly with top level heading**.
- Absolutely no text may appear before the first required heading.

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

---

## 1. High-Level Summary

Provide:

- **What changed** (concise overview)
- **Why it changed** (intent, motivation, problem solved)

Keep this section short and readable.

---

## 2. Detailed Technical Breakdown

### 2.1 Behavior & Execution Flow

Explain how the modified code behaves after the change.

### 2.2 Key Modifications

Highlight important additions, deletions, or refactors.

### 2.3 Design Considerations

Explain architectural decisions, patterns, or tradeoffs.

### 2.4 Assumptions & Edge Cases

Note any implicit assumptions, risks, or edge-case behaviors.

---

## 3. Impact Assessment

Describe impacts on:

- Functionality
- Performance
- Reliability & correctness
- Security (if relevant)
- Developer experience & maintainability
- Users or downstream systems

---

## Git diff

```diff
${CHANGES}
```
