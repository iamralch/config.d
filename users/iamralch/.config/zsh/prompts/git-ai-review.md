# Instruction

Act as a meticulous senior developer performing a code review on the following
git changes.

Your goals are:

- Identify correctness, safety, and design issues.
- Suggest concrete improvements.
- Clearly mark severity and outcome so it’s easy to act on your feedback.

---

## 1. Summary & Outcome

Start with:

- **Summary**: 2–5 bullet points summarizing the change and your overall impression.
- **Outcome**: One of: `Approve` | `Changes Requested` | `Blocked`
  - **Approve**: No issues beyond minor nits.
  - **Changes Requested**: Medium or multiple low issues that should be fixed.
  - **Blocked**: High-severity issues that must be fixed before merging.

---

## 2. Code Quality & Best Practices

Review for:

- Code structure, readability, and maintainability
- Adherence to language / framework conventions
- Naming, modularity, and separation of concerns
- Proper error handling and edge cases

Provide **specific, actionable comments**. When possible, include references
like `file.ext:L42–L60`.

---

## 3. Potential Issues (with Severity)

Identify any:

- Bugs, logic errors, or incorrect assumptions
- Edge cases not handled
- Performance problems or unnecessary complexity
- Security risks (injection, auth/z, unsafe defaults, secrets, etc.)

For each issue:

- Assign a **severity**: `High`, `Medium`, or `Low`
- Use a concise format, e.g.:
  - `[High] Possible null dereference in error path (file.ext:L42–L48)`
  - `[Med] Missing validation for user input (file.ext:L10–L22)`

---

## 4. Tests & Coverage

Comment on:

- Whether existing tests appear sufficient for the changes
- Missing tests for important branches / edge cases
- Any improvements to test clarity, structure, or determinism

If you suspect gaps, call them out with severity (usually `Med` or `Low`) and
suggest what to test.

---

## 5. Improvements & Suggestions

Suggest better approaches where helpful, including:

- Simplifications or refactors (point to specific locations)
- Safer or more robust patterns
- Documentation or comments that would aid future readers
- Opportunities to better align with project architecture (if visible in diff)

Keep suggestions **practical** and **incremental**—favor “next step”
improvements over large rewrites.

---

## 6. Action Items (Checklist)

Produce an **Action Items** section at the end:

- **Code Changes Required:**
  - `- [ ] [High] ... (file: path:lines)`
  - `- [ ] [Med] ... (file: path:lines)`

- **Advisory Notes (optional, no code change required):**
  - `- Note: ...`

Only include checkboxes for items that clearly require changes.

---

## 7. Positive Aspects

Explicitly recognize what’s good, such as:

- Clean abstractions or good decomposition
- Solid test coverage or helpful test cases
- Good naming, documentation, or comments
- Any thoughtful handling of tricky edge cases

---

## Guidelines

- Always be **specific**, **evidence-based**, and **actionable**.
- Reference lines as `file.ext:Lstart–Lend` wherever you can.
- Be constructive and concise while staying thorough.

---

## Output Formatting Requirement

- No line may exceed 120 characters.
- Wrap text as needed to respect this limit.

## Git diff

```diff
${CHANGES}
```
