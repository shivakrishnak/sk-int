---
mode: agent
description: "Generate or fill interview keyword content using keyword-batch mode (1-3 keywords at a time)"
tools:
  - read_file
  - replace_string_in_file
  - multi_replace_string_in_file
  - run_in_terminal
  - file_search
  - grep_search
---

> **Version Registry** - `SPEC_VERSION` = **1** | `SPEC_LABEL` = **v1.0**

# Generate Interview Content (keyword-batch)

Generate complete v1.0 interview mastery content for the next unfilled
keywords in a file. Works with both new files (frontmatter only) and
files with existing `[FILL:]`/`[TODO:]` stubs.

## Voice

Precise like Josh Bloch. Clear like Martin Fowler. Intuitive like
Feynman. Production-scarred like a senior systems architect.
Interview-ready like a FAANG bar raiser.

## Core Rules (non-negotiable)

1. **Generate complete 19-section content** for each keyword
2. **BAD before GOOD** in all code examples
3. **Code lines max 70 chars**, ASCII diagrams max 59 chars wide. Diagrams: DUAL format (ASCII first, then Mermaid below). Types: flowchart, sequenceDiagram, stateDiagram-v2, classDiagram, erDiagram, mindmap
4. **Bold-label lines** (`**LABEL:** value`) must each be separated by a blank line
5. **Min 4 misconception rows**, min 3 failure modes per keyword
6. **Interview Q&A must have COMPLETE answers** (200-500 words each)
7. **No em dashes** anywhere - use hyphens only
8. **UTF-8 no BOM** - no special characters in YAML frontmatter

## Quality Constitution (Non-Negotiable)

Every keyword MUST pass ALL eight quality tests.
Full spec: `spec/interview.md` Section 5.

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

## Section-Specific Rules (condensed)

| Section             | Key Rule                                                                                        |
| ------------------- | ----------------------------------------------------------------------------------------------- |
| TL;DR               | Max 25 words. What + why. Zero jargon.                                                          |
| Problem             | WORLD WITHOUT IT -> BREAKING POINT -> INVENTION MOMENT -> EVOLUTION                             |
| 30 Seconds          | One line (15 words) + One analogy (blockquote) + One insight                                    |
| First Principles    | 3 invariants -> derived design -> gain/cost -> essential/accidental                             |
| Mental Model        | Blockquote analogy + bullet mapping + "breaks down" sentence                                    |
| Five Levels         | L1-L5 + Senior-to-Staff Leap (required for medium/hard)                                         |
| Code Example        | BAD then GOOD. Real-world, not toy. Include test/verify.                                        |
| Quick Reference     | 11 fields + 3 things to remember + interview one-liner                                          |
| Mastery Checklist   | 5 indicators: EXPLAIN/DEBUG/DECIDE/BUILD/EXTEND                                                 |
| Misconceptions      | Min 4 rows. Most dangerous first.                                                               |
| Failure Modes       | Min 3. Symptom/Root Cause/Diagnostic (real command)/Fix/Prevention                              |
| Interview Deep-Dive | Min 7 Qs for easy, 9 for medium, 12 for hard. Tags + full answers + "What separates good/great" |
| Related Keywords    | Prerequisites / Builds on this / Alternatives - 2-3 each                                        |

## Sizing (words per keyword)

| Concept Type                  | Target Words |
| ----------------------------- | ------------ |
| Tiny (single-purpose, atomic) | 600-1,000    |
| Medium (one mechanism)        | 1,200-2,500  |
| Foundational (multi-faceted)  | 3,000-5,000  |

## Workflow

1. Read the target file - extract `keywords:` and `difficulty_range:` from frontmatter
2. Detect which keywords are already complete (have real content, not stubs)
3. Pick next 1-3 unfilled keywords (1 for hard, 2-3 for easy/medium)
4. Generate complete 19-section content for each keyword in the batch
5. Write content to file (append or replace stubs)
6. Report: `Completed keyword N of M: [name]`
7. Auto-continue to next batch until all keywords complete
8. Verify: grep for `[TODO:` and `[FILL:` - must return zero

## Invocation

```
Generate content for: docs/java/Java - Basics.md
```

Or with specific keywords:

```
Generate content for: docs/java/Java - Basics.md
Keywords: Variables and Data Types, Operators and Control Flow
Difficulty: easy
```

Work through keywords in batch. Do NOT attempt all keywords in one pass.

## Commit Rules (Non-Negotiable)

- Commit every **5 created files** (never single files)
- Only commit files that were **created** (not just modified)
- If fewer than 5 remain at the end, commit all remaining at once
- Do NOT `git push`

```pwsh
git add docs/
git commit -m "feat: add interview <Topic> - batch <N>"
```
