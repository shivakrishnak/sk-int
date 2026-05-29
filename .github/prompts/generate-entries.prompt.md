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

## ⛔ CONFIRMED FAILURES - NON-NEGOTIABLE HARD RULES

<!-- Gate 1 is also in interview.instructions.md (auto-loads for docs/spec/scripts). -->
<!-- Retained here as a safety net for cold invocations where the instructions file may not yet be loaded. -->

They are permanently prohibited. Violation = file is REJECTED, not written.

**FAILURE 1 - Spec not read:** NEVER generate any entry without first reading
`spec/interview_content_generator.md` in full in the current session. Generating
from memory or conversation summaries produces wrong headers. ALWAYS read the spec.

### GATE 1 - SPEC MUST BE READ BEFORE ANY GENERATION (Fixes Failure 1)

**RULE:** Before generating ANY entry, read `spec/interview_content_generator.md` in full.

Generating from memory, conversation summaries, or abbreviated notes is PROHIBITED.
The spec defines exact section IDs, exact `###` headers, exact emoji, mandatory
subsections, and TYPE-specific adaptations that cannot be reproduced from memory.
Any entry generated without reading the spec WILL contain wrong headers and MUST be
regenerated from scratch.

**ENFORCEMENT:** If the model has not confirmed reading `spec/interview_content_generator.md`
in the current session since the last context reset, it MUST read it before writing
any file. No exceptions. This is the first step of every generation workflow.

### GATE 2 - QUALITY GATE: ALL MANDATORY SECTIONS MUST BE IN OUTPUT (Fixes missed sections)

**RULE:** Before writing any keyword to disk, confirm ALL 10 section headers
are present in the planned output. A section that is "implied" or "will be
added next" does NOT count - it must exist in THIS output block.

**ALL 10 sections required per keyword - NON-NEGOTIABLE:**

Conditional sections must appear with an explicit `*(Omit: reason)*` note when
not applicable. Silent omissions are NEVER acceptable.

| # | Option C Section | Header | Rule |
|---|---|---|---|
| 2 | Model Answer | `### 🎯 Model Answer` (30s + 3min + Blank Mind Recovery) | ALWAYS - no OMIT |
| 3 | Concept Explanation | `### 📘 Concept Explanation` (all 8 sub-sections) | ALWAYS - no OMIT |
| 4 | Code Example | `### 💻 Code Example` | ALWAYS - code OR explicit OMIT + reason |
| 5 | Answers by Seniority | `### 🎓 Answers by Seniority` (Junior/Mid + Senior/Staff) | ALWAYS - no OMIT |
| 6 | Common Misconceptions | `### ⚠️ Common Misconceptions` | ALWAYS - no OMIT |
| 7 | Failure Modes | `### 🚨 Failure Modes and Diagnosis` | ALWAYS - no OMIT |
| 8 | Interview Deep-Dive | `### 🎯 Interview Deep-Dive` (CAPSTONE) | ALWAYS - no OMIT |
| 9 | Comparison Table | `### ⚖️ Comparison Table` | ALWAYS - table OR explicit OMIT for ★☆☆ |
| - | System Design | `### 🏛️ System Design` | ALWAYS - design OR explicit OMIT for non-★★★ |
| - | Diagram | `### 📊 Diagram` | ALWAYS - diagram OR explicit OMIT for non-visual |

**⛔ HARD STOP - Do NOT write the file if:**
- Any section header (rows 2-10 above) is missing from the output
- Section §2 does not contain a `**Blank Mind Recovery:**` block
- Section §8 (Interview Deep-Dive) has fewer than the minimum questions
  (★☆☆: 7, ★★☆: 9, ★★★: 12)
- A conditional section is silently absent (no header, no OMIT note)
- `spec/interview_content_generator.md` has not been read in this session

**Recovery:** Immediately append any missing section before updating index.md.
Validator rule R21 catches all 10 sections at pre-commit and blocks the commit.

---

Generate complete, spec-compliant v1.0 keyword entries for interview
mastery files using keyword-batch mode (★★★=1/file, ★★☆=2/file, ★☆☆=3/file — 1 call per file).

**Target:** `${input:target:File path or topic name (e.g. docs/java/Java - Collections.md or Java)}`
**Batch size:** `${input:batchSize:Keywords per call - ★★★=1, ★★☆=2 max, ★☆☆=3 max. Do NOT increase.}`

---

## Phase 0 - Discover work items

1. If `target` is a file path: read `{topic}/index.md` Keyword Registry
   to get the keyword list and status for this file. If no index.md
   exists, stop — create index.md with Keyword Registry first.
2. If `target` is a topic name: list files in `docs/{topic}/`,
   identify files with unfilled keywords
3. For each file, detect progress:
   - Scan file body for `# KEYWORD NAME` headings with real content
     (not `[TODO:]` or `[FILL:]` stubs below them)
   - Cross-reference against index.md Keyword Registry status column
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

Work within these per-call limits. Exceeding them truncates the response.

| Difficulty | Keywords/Call | Why |
| ---------- | ------------- | --- |
| Hard (★★★)  | 1             | 12 Q&As ≈ 6,000-8,000 words |
| Medium (★★☆)| 2 max         | 9 Q&As each ≈ 8,000-10,000 words total |
| Easy (★☆☆)  | 3 max         | 7 Q&As each ≈ 6,000-7,500 words total |

For each keyword in the batch:

### 2a. Determine keyword context

- Keyword name (from index.md Keyword Registry for this file)
- Difficulty (infer from level band: L0/L1 = easy, L2/L3 = medium,
  L4+ = hard; or from keyword name if complexity is obvious)
- Topic and subtopic (from file path `docs/{topic}/{Topic} - {Subtopic}.md`)

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
- Diagrams: DUAL format (ASCII first, then Mermaid below). Types: flowchart, sequenceDiagram, stateDiagram-v2, classDiagram, erDiagram, mindmap, timeline, xychart-beta, gantt, gitGraph
- BAD pattern always before GOOD pattern
- Bold-label lines (`**LABEL:** value`) separated by blank lines
- No em dashes - use hyphens
- Interview Deep-Dive: question count by difficulty (7/9/12 min)
- Each Q: tag + why-they-ask + likely-follow-up + complete answer
- Each A: 200-500 words, end with "What separates good from great"
- Keywords separated by double horizontal rules

### 2c. Write to file

**ALWAYS use `create_file` tool to a temp path, then copy:**

```pwsh
# New file (first keyword):
Copy-Item "_tmp_kw.md" "docs/{topic}/{File}.md" -Force

# Append (subsequent keywords):
Get-Content "_tmp_kw.md" | Add-Content "docs/{topic}/{File}.md" -Encoding UTF8
```

NEVER use PowerShell here-strings (`@'...'@`) or
`[System.IO.File]::WriteAllText()` with inline content - both fail
silently for content > 5KB.

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
3. In `{topic}/index.md` Keyword Registry, update all completed keywords
   for this file to `draft` or `complete` status

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
