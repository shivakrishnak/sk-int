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

1. If `target` is a file path: read frontmatter to get keywords list
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
- medium keywords: 1-2 per batch
- easy keywords: 2-3 per batch

For each keyword in the batch:

### 2a. Determine keyword context

- Keyword name (from frontmatter)
- Difficulty (from `difficulty_range:` or infer from keyword complexity)
- Topic and subtopic (from frontmatter `topic:` and `subtopic:`)

### 2b. Generate complete v1.0 entry

Apply all rules from `.github/instructions/interview.instructions.md`
(auto-loaded). All 19 sections required in order. Conditional section
decisions:

| Section              | Include when...                    |
| -------------------- | ---------------------------------- |
| 11. Code Example     | Concept has programmatic interface |
| 15. Comparison Table | 2+ named alternatives exist        |

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

## Quality Constitution (Non-Negotiable)

Every keyword MUST pass ALL eight quality tests.
Full spec: `spec/interview_content_generator.md` Section 6.

**Voice:** Precise like Josh Bloch. Clear like Martin Fowler. Intuitive like
Feynman. Production-scarred like a senior systems architect.
Interview-ready like a FAANG bar raiser.

**Eight Tests (all must pass):**

1. Search Again? - reader never needs to look elsewhere
2. Feynman - smart beginner understands without confusion
3. Senior Engineer - senior still learns something useful
4. Staff Engineer - staff/principal respects this explanation
5. Production Reality - reader can diagnose real issues
6. Retention - reader remembers this next month
7. Decision - reader knows when to use or avoid
8. Scale - 10x/100x/1000x behavior covered

**Code Example Requirements (Non-Negotiable):**

Every concept with code - choose based on complexity (min 2-3):

1. Recognition Example - identify pattern in existing code
2. Wrong vs Right - MANDATORY (BAD before GOOD, always)
3. Production Example - real-world, not toy
4. Failure Example - MANDATORY - what breaks, symptoms, fix
5. Debugging Example - diagnostic commands, log analysis
6. Scale Example - what changes under load
7. Trade-off Example - gain vs sacrifice in code
8. Internal Mechanism Example - how it works underneath
9. System Interaction Example - cross-component behavior
10. Testing/Verification Example - prove correctness

Goal: reader understands why, when, failure, scale, debugging,
and trade-offs - not just the API.

**10-Point Writing Standard:**
Intuition, Mechanism, Trade-off, Failure, Diagnosis, Scale,
Decision, Memory, Transfer, Reality

**Forbidden:** Generic definitions, toy examples, vague advice,
fabricated numbers, surface explanations, "best practice" without
reasoning, walls of prose, repetition across sections.

**Final Gate:** "Would an experienced engineer say 'Damn - this is
genuinely excellent'?" If uncertain: rewrite. Masterclass = target.

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
2. Count `# ` headings - must match `keywords:` count in frontmatter
3. Verify `version: 3` and update `status: complete` in frontmatter
