---
mode: agent
description: "Generate interview mastery content for keywords in a file using keyword-batch mode (1-3 at a time)"
tools:
  - read_file
  - replace_string_in_file
  - multi_replace_string_in_file
  - run_in_terminal
  - file_search
  - grep_search
---

# Interview Mastery - Entry Generator (v1.0)

> **Version Registry** - `SPEC_VERSION` = **1** | `SPEC_LABEL` = **v1.0**

Generate complete, spec-compliant v1.0 keyword entries for interview
mastery files using keyword-batch mode (1-3 keywords per pass).

**Target:** `${input:target:File path or topic name (e.g. docs/java/Java - Collections.md or Java)}`
**Batch size:** `${input:batchSize:Keywords per batch (default: 3, use 1 for hard keywords)}`

---

## Phase 0 - Discover work items

1. If `target` is a file path: read `{topic}/index.md` Keyword Registry
   to get the keyword list and status for this file. If no index.md
   exists, fall back to frontmatter `keywords:` field.
2. If `target` is a topic name: list files in `docs/{topic}/`,
   identify files with unfilled keywords
3. For each file, detect progress:
   - Read the `keywords:` array from YAML frontmatter
   - Scan file body for `# KEYWORD NAME` headings with real content
     (not `[TODO:]` or `[FILL:]` stubs below them)
   - Report: `N of M keywords complete in {file}`

If all keywords are complete, stop - nothing to generate.

---

## Phase 1 - Read spec (first keyword only)

For the FIRST keyword in this session, read the full spec:

```
spec/interview_content_generator.md
```

For all subsequent keywords, use the condensed generation rules in
`.github/instructions/interview.instructions.md` (auto-loaded).

---

## Phase 2 - Generate keyword content

Work **one batch at a time**. Batch size adapts to difficulty:

- hard keywords: 1 per batch
- medium keywords: 2 per batch
- easy keywords: 3 per batch

For each keyword in the batch:

### 2a. Determine keyword context

- Keyword name (from frontmatter)
- Difficulty (from `difficulty_range:` or infer from keyword complexity)
- Topic and subtopic (from frontmatter `topic:` and `subtopic:`)

### 2b. Generate complete v1.0 entry

Apply all rules from `.github/instructions/interview.instructions.md`
(auto-loaded). Generate all 8 Option C sections in order (plus §9
Comparison Table when applicable). Conditional section decisions:

| Option C Section    | Include when...                          |
| ------------------- | ---------------------------------------- |
| §4 Code Example     | Concept has a programmatic interface     |
| §9 Comparison Table | Difficulty ★★☆ or above, 2+ alternatives |

**Critical rules - apply for every keyword:**

- Every `###` preceded by `---` with blank lines
- ASCII diagrams max 59 chars; code lines max 70 chars
- Diagrams: DUAL format (ASCII first, then Mermaid below). Types: flowchart, sequenceDiagram, stateDiagram-v2, classDiagram, erDiagram, mindmap
- BAD pattern always before GOOD pattern
- Bold-label lines (`**LABEL:** value`) separated by blank lines
- No em dashes - use hyphens
- Interview Deep-Dive: question count by difficulty (7/9/12 min)
- Each Q: tag + why-they-ask + likely-follow-up + complete answer
- Each A: 200-500 words, end with "What separates good from great"
- Keywords separated by double horizontal rules

### 2c. Write to file

- **New/empty file**: write frontmatter + keyword content
- **File with stubs**: replace `[TODO:]`/`[FILL:]` sections for
  the current keyword, or append after last completed keyword
- **Partially complete file**: append after last completed keyword,
  before any remaining stubs

Use UTF-8 without BOM.

---

## Quality Standard

> All quality rules are in `.github/instructions/interview.instructions.md`
> (auto-loaded). Applies in full: Quality Constitution (8 tests), Code
> Example Requirements (10 categories), 10-Point Writing Standard, Forbidden
> Patterns, Final Gate, and Voice. Every keyword MUST pass all eight tests.
> Full spec: `spec/interview_content_generator.md` Section 6.

### 2d. Report and continue

After each batch:

- `Completed keyword N of M: [keyword name]`
- `Remaining: [list]`
- Auto-continue to next batch without pausing

---

## Phase 3 - Commit

Commit in batches of **5 created files** (non-negotiable):

```pwsh
git add docs/
git commit -m "feat: add interview <Topic> - batch <N>"
```

**Batch Rules:**

- Do NOT commit single files - wait until 5 files are created
- Only count **created** files (not just modified)
- If fewer than 5 remain at the end, commit all remaining
- Do NOT `git push`

---

## Phase 4 - Verify

After all keywords in a file are complete:

1. Grep for `[TODO:` and `[FILL:` - must return zero matches
2. Check `{topic}/index.md` Keyword Registry - all keywords for this
   file must show `draft` or `complete` status (no `pending` remaining)
3. If frontmatter is present: verify `version: 1` and update
   `status: complete` when all keywords are filled

---

## Invocation Examples

**Specific file:**

```
Generate content for: docs/java-language/Java Language - L1 Foundations.md
```

**File with specific keywords:**

```
Generate content for: docs/java-language/Java Language - L2 Object Model.md
Keywords: Inheritance and Polymorphism, Abstract Classes vs Interfaces
Difficulty: medium
```

**Full topic (all pending files):**

```
Generate all remaining content for: java-language
```

Work through keywords in batch order. Do NOT attempt all keywords in one pass.
