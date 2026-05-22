---
applyTo: "docs/**, spec/**, scripts/**"
description: "Rules for generating and editing Technical Interview Dictionary v1.0 content - 15 sections (4.1-4.15), keyword-batch generation, Q&A format"
---

> **Version Registry** - `SPEC_VERSION` = **1** | `SPEC_LABEL` = **v1.0**

# Interview Mastery Dictionary - Auto-Loaded Instructions

> These instructions auto-attach when editing files under `docs/`,
> `spec/`, or `scripts/`. Full generation spec: `spec/interview_content_generator.md` (v1.0).
> This file contains condensed generation rules sufficient for producing
> content after reading the full spec once per session.

## Workspace Structure

```
southstar/
  mkdocs.yml                  Material for MkDocs config
  docs/                       Published content
    index.md                  Homepage
    {topic}/                  Topic folders
      index.md
      {Topic} - {Subtopic}.md
  spec/                       Generation specs (excluded from build)
    interview_content_generator.md  Master generation spec v1.0
    topics_registry.md        Topic registry
    README.md
  scripts/                    Automation (excluded from build)
    scaffold_topic.py         Scaffold generator (Python 3.14)
    generate_topics.ps1
    generate_content.ps1
    validate.ps1
```

## Prompts (in .github/prompts/)

| Prompt              | Purpose                                       |
| ------------------- | --------------------------------------------- |
| `@generate-entries` | Generate keyword content (keyword-batch mode) |
| `@fill-content`     | Fill stubs or generate next keywords          |
| `@scaffold`         | Run scaffold generator (optional)             |

## Content Structure - 19 Sections per Keyword

1. Title (`# KEYWORD NAME`)
2. TL;DR (one sentence, 25 words max)
3. The Problem This Solves (World Without It / Breaking Point / Evolution)
4. Textbook Definition
5. Understand It in 30 Seconds (One line / One analogy / One insight)
6. First Principles (Invariants / Trade-offs / Essential vs Accidental)
7. Mental Model / Analogy (blockquote + mapping + breakdown)
8. Gradual Depth - Five Levels (Anyone / Junior / Mid / Senior / Distinguished + Senior-to-Staff Leap)
9. How It Works (summarized but complete mechanism)
10. Complete Picture - End-to-End Flow (normal + failure + scale)
11. Code Example (CONDITIONAL - BAD then GOOD, production-grade)
12. Quick Reference Card (11 fields + 3 things + interview one-liner)
13. Mastery Checklist (5 indicators: EXPLAIN/DEBUG/DECIDE/BUILD/EXTEND)
14. The Surprising Truth (one counterintuitive fact)
15. Comparison Table (CONDITIONAL - 2+ alternatives + Rapid Decision Tree)
16. Common Misconceptions (min 4 rows, danger-ordered)
17. Failure Modes and Diagnosis (min 3 modes with real diagnostic commands)
18. Interview Deep-Dive (CAPSTONE - scaled by difficulty)
19. Related Keywords (prerequisites / builds-on / alternatives)

## Interview Deep-Dive Rules (Critical)

- **Minimum scales by difficulty:** easy=7, medium=9, hard=12
- Every question MUST have a **complete, detailed answer** (200-500 words)
- **Tag each question** with: `[JUNIOR]` `[MID]` `[SENIOR]` `[STAFF]`
- **End every answer** with `*What separates good from great:*`
- **Add `*Likely follow-up:*`** after each `*Why they ask:*`
- **Include timing guidelines table** at section start
- **At least 1 DEBUGGING + 1 TRADE-OFF question per keyword** (mandatory)
- **At least 1 BEHAVIORAL question for medium/hard keywords**
- Must cover at least 5 of 9 question categories

## Formatting Rules

- Code lines: max 70 characters
- ASCII diagrams: max 59 characters wide
- Diagrams: DUAL format - ASCII block first, then equivalent Mermaid block
  immediately below. Types: `flowchart`, `sequenceDiagram`, `stateDiagram-v2`,
  `classDiagram`, `erDiagram`, `mindmap`
- Paragraphs: max 5 sentences
- BAD pattern before GOOD pattern in all code examples
- Every `###` heading preceded by `---` with blank lines
- Keywords within a file separated by double horizontal rules
- No em dashes anywhere - use regular hyphens only
- Bold-label lines (`**LABEL:** value`) must each be separated by a blank line
- Use `# Keyword Name` as keyword separators within content files
  (MkDocs renders the first H1 as the page title)

## Encoding Rules

- UTF-8 without BOM
- Always use `pwsh` (PowerShell 7+), NEVER `powershell.exe`
- `[System.Text.UTF8Encoding]::new($false)` for file writing
- Python: `$env:USERPROFILE\.local\bin\python3.14.exe`
- No emojis in YAML frontmatter

## Quality Constitution (Non-Negotiable)

Full spec: `spec/interview_content_generator.md` Section 6.
Every keyword MUST pass ALL eight quality tests before output.

### Eight Quality Tests

| #   | Test               | If FAIL                                                 |
| --- | ------------------ | ------------------------------------------------------- |
| 1   | Search Again?      | Reader still needs to look elsewhere = incomplete       |
| 2   | Feynman            | Smart beginner confused = rewrite                       |
| 3   | Senior Engineer    | Senior learns nothing new = too shallow                 |
| 4   | Staff Engineer     | Staff wouldn't respect this = lacks depth               |
| 5   | Production Reality | Can't diagnose real issue = add diagnostics             |
| 6   | Retention          | Won't remember next month = add memory hooks            |
| 7   | Decision           | Can't decide when to use/avoid = add decision framework |
| 8   | Scale              | No 10x/100x/1000x coverage = add scale analysis         |

### Code Example Requirements (Non-Negotiable)

Every concept with code must choose examples from these categories.
Choose based on concept complexity (minimum 2-3 categories):

1. Recognition Example - identify the pattern in existing code
2. Wrong vs Right Example - **MANDATORY** (BAD before GOOD, always)
3. Production Example - real-world, not toy
4. Failure Example - **MANDATORY** - what breaks, symptoms, fix
5. Debugging Example - diagnostic commands, log analysis
6. Scale Example - what changes under load
7. Trade-off Example - gain vs sacrifice in code
8. Internal Mechanism Example - how it works underneath
9. System Interaction Example - cross-component behavior
10. Testing/Verification Example - prove correctness

Goal: the reader understands why, when, failure, scale,
debugging, and trade-offs - not just the API.

### 10-Point Writing Standard

Every explanation must cover: (1) Intuition, (2) Mechanism, (3) Trade-off,
(4) Failure, (5) Diagnosis, (6) Scale, (7) Decision, (8) Memory,
(9) Transfer, (10) Reality

### Forbidden Patterns

- Generic textbook definitions only
- Syntax-only or toy code examples
- Vague advice ("it depends") without specifics
- Fabricated benchmarks or performance numbers
- Surface-level explanations that skip WHY
- "Best practice" claims without reasoning
- Walls of prose without structure
- Repetition across sections

### Final Gate

_"Would an experienced engineer say 'Damn - this is genuinely excellent'?"_
If uncertain: rewrite.

## File Frontmatter Format (optional in MkDocs)

MkDocs auto-discovers pages from `docs/` and reads navigation from
`mkdocs.yml`'s `nav:` block (or alphabetically if `nav:` is omitted).
Frontmatter is **optional**. When used, the supported keys are:

```yaml
---
title: "Topic - Subtopic" # Optional - overrides first H1
description: "One-line summary" # Optional - meta description
tags: [tag1, tag2] # Optional - shown via material/tags
hide: [navigation, toc] # Optional - per-page UI controls
---
```

**Project-specific keys** (not used by MkDocs, but useful for tooling):

```yaml
---
topic: Java
subtopic: Collections
keywords: # Required - drives generation
  - Keyword One
  - Keyword Two
difficulty_range: easy | medium | hard
status: in-progress | complete
version: 1
---
```

### Frontmatter Rules (when used)

- File starts at byte 0 with `---` (no BOM, no whitespace)
- `title` quoted if it contains `: ` (colon + space)
- `keywords` list of 3-5 items, must match `# KEYWORD` headings in file
- `status` is `complete` when all keywords filled, else `in-progress`
- `version` always `3`

### Batch Commit Rules (Non-Negotiable)

- Commit every **5 created files** (never single files)
- Only commit files that were **created** (not just modified)
- If fewer than 5 remain at the end, commit all remaining at once
- Do NOT `git push`

```bash
git add docs/
git commit -m "feat: add interview <Topic> - batch <N>"
```

## Scaffold Workflow (optional)

Scaffolding is no longer required for content generation. The agent
reads keywords from frontmatter and generates content directly.
Use scaffold only to preview file structure:

1. **Scaffold (optional):** `& "$env:USERPROFILE\.local\bin\python3.14.exe" scripts/scaffold_topic.py <topic>`
2. **Generate content:** Use `@generate-entries` prompt or `/interview` agent
3. **Keyword-batch:** Agent generates 1-3 keywords per pass, appends to file, auto-continues

## Generation Workflows

**Existing topic:** `Generate interview mastery content: Topic: Java, File: Java - Collections.md`

**New topic:** `Create new interview mastery topic: Angular` (checks registry, generates keywords, creates files)

## Folder/File Rules

- One folder per main topic under `docs/` (lowercase, hyphens)
- Each folder has `index.md` listing sub-topic files
- Sub-topic files: `{Topic} - {Subtopic}.md`
- Each file contains 3-5 keywords (HARD CAP: 5)
- Separator in filenames: SPACE-HYPHEN-SPACE (never em dash)

## Keyword Level Coverage (MANDATORY)

Every interview topic MUST cover ALL knowledge levels:

| Level | Icon | Name         | Min KW | What It Covers                          |
| ----- | ---- | ------------ | ------ | --------------------------------------- |
| L0    | 🌱   | Orientation  | 3-5    | Why it exists, ecosystem, before it     |
| L1    | ★☆☆  | Foundational | 4-6    | Core vocabulary, building blocks, setup |
| L2    | ★★☆  | Working      | 5-8    | Patterns, daily usage, idioms           |
| L3    | ★★☆+ | Intermediate | 5-10   | Design decisions, trade-offs, internals |
| L4    | ★★★  | Expert       | 5-10   | Production diagnostics, failure modes   |
| L5    | 🔥   | Architect    | 3-5    | Strategy, migration, governance         |
| L6    | 🔬   | Creator      | 2-3    | Theory, specification, research         |
| META  | 🧠   | Meta-Skills  | 2-3    | Transferable thinking patterns          |

**Max 5 keywords per file, min 3.** Split into multiple files if a
level has more than 5 keywords.

**File structure per topic:**

- `{Topic} - Foundations.md` for L0 + L1 keywords (max 5)
- Core working files for L2-L4 keywords (5 each)
- `{Topic} - Architecture and Strategy.md` for L5 + L6 + META (max 5)

A topic missing any level is INCOMPLETE. Always verify before generating.

---

## Condensed Generation Reference

> This section contains all rules needed to generate content after
> reading `spec/interview_content_generator.md` once. It replaces the need to re-read
> the full spec for every keyword.

### Voice

Precise like Josh Bloch. Clear like Martin Fowler. Intuitive like
Feynman. Production-scarred like a senior systems architect.
Interview-ready like a FAANG bar raiser.

### Keyword Separator

Between keywords in a file, use double horizontal rules:

```
[blank line]
---
[blank line]
---
[blank line]
```

### Section-by-Section Rules

**1. Title** - `# KEYWORD NAME` (H1, plain name, no ID prefix)

**2. TL;DR** - `**TL;DR** - [max 25 words. What + why. Zero jargon.]`

**3. The Problem This Solves** - `### 🔥 The Problem This Solves`

- Structure: WORLD WITHOUT IT (2-4 sentences) -> BREAKING POINT
  (1-2 sentences) -> INVENTION MOMENT ("This is exactly why
  [KEYWORD] was created.") -> EVOLUTION (2-3 sentences)
- 100-200 words. Show real pain, not abstract.

**4. Textbook Definition** - `### 📘 Textbook Definition`

- 2-4 sentences. Formal, precise. No analogies.

**5. Understand in 30 Seconds** - `### ⏱️ Understand It in 30 Seconds`

- **One line:** max 15 words, zero jargon
- **One analogy:** 2-3 sentences in `>` blockquote
- **One insight:** 2-3 sentences, what separates knowing vs understanding

**6. First Principles** - `### 🔩 First Principles Explanation`

- CORE INVARIANTS (3 numbered) -> DERIVED DESIGN (2-4 sentences)
  -> TRADE-OFFS (Gain/Cost) -> ESSENTIAL vs ACCIDENTAL complexity
- 150-400 words. Build from axioms to design.

**7. Mental Model** - `### 🧠 Mental Model / Analogy`

- `>` blockquote analogy -> bullet mapping (`"X" -> Y`) -> "Where
  this analogy breaks down: [1 sentence]"
- 100-200 words.

**8. Five Levels** - `### 📶 Gradual Depth - Five Levels`

- L1 anyone (2-4 sent) / L2 junior (3-5) / L3 mid (4-6) /
  L4 senior-staff (5-8) / L5 distinguished (3-5)
- **Senior-to-Staff Leap** (required): `A Senior says: "..."` /
  `A Staff says: "..."` / `The difference: [1 sentence]`

**9. How It Works** - `### ⚙️ How It Works`

- Step-by-step mechanism. ASCII diagrams encouraged (max 59 chars).
  Happy path + failure path. Summarized but complete.

**10. End-to-End Flow** - `### 🔄 Complete Picture - End-to-End Flow`

- NORMAL FLOW (ASCII with `<- YOU ARE HERE` marker) -> FAILURE PATH
  -> WHAT CHANGES AT SCALE (2-3 sentences at 10x/100x/1000x)

**11. Code Example** - `### 💻 Code Example` (CONDITIONAL: if programmatic)

- BAD then GOOD. Min 2 examples. Max 70 chars/line. Production-grade.
- End with: `**How to test / verify correctness:**` (1-3 sentences)

**12. Quick Reference Card** - `### 📌 Quick Reference Card`

- 11 fields: WHAT IT IS / PROBLEM IT SOLVES / KEY INSIGHT / USE WHEN
  / AVOID WHEN / ANTI-PATTERN / TRADE-OFF / ONE-LINER / KEY NUMBERS
  / TRIGGER PHRASE / OPENING SENTENCE
- **If you remember only 3 things:** (numbered)
- **Interview one-liner:** (quoted)

**13. Mastery Checklist** - `### ✅ Mastery Checklist`

- 5 indicators exactly: EXPLAIN / DEBUG / DECIDE / BUILD / EXTEND
- Each specific to THIS concept. 50-100 words total.

**14. Surprising Truth** - `### 💡 The Surprising Truth`

- ONE counterintuitive fact. 2-4 sentences. Genuinely surprising.

**15. Comparison Table** - `### ⚖️ Comparison Table`
(CONDITIONAL: only when 2+ alternatives exist)

- Min 4 comparison dimensions + "Best for" row
- Decision framework + Rapid Decision Tree (30 seconds)

**16. Misconceptions** - `### ⚠️ Common Misconceptions`

- Table: min 4 rows. Danger-ordered (most harmful first).
- Frame as "candidates confidently state X, but actually Y"

**17. Failure Modes** - `### 🚨 Failure Modes and Diagnosis`

- Min 3 modes. Each: Symptom / Root Cause / Diagnostic (REAL
  command: jcmd, kubectl, docker stats, etc.) / Fix (BAD->GOOD)
  / Prevention. At least 1 security mode if applicable.

**18. Interview Deep-Dive** - `### 🎯 Interview Deep-Dive` (CAPSTONE)

- Timing table at section start (5-row)
- Question count by difficulty: easy=7, medium=9, hard=12 (no cap)
- Cover at least 5 of 9 categories: CONCEPTUAL, DEBUGGING,
  ARCHITECTURE, TRADE-OFF, PRODUCTION, HANDS-ON, SYSTEM DESIGN,
  COMPARISON, BEHAVIORAL
- Mandatory per keyword: 1 DEBUGGING + 1 TRADE-OFF
- Mandatory for medium/hard: 1 BEHAVIORAL (STAR format)
- Tag each: `[JUNIOR]` `[MID]` `[SENIOR]` `[STAFF]`
- Order: foundational -> advanced -> expert
- Each Q: `*Why they ask:*` + `*Likely follow-up:*`
- Each A: 200-500 words, complete structured answer
- End each A: `*What separates good from great:*`
- No duplicate questions across keywords in same file

**19. Related Keywords** - `### 🔗 Related Keywords`

- Prerequisites (2-3 with why) / Builds on this (2-3) /
  Alternatives (2-3 with when to prefer)

### Conditional Section Decision Table

| Section              | Include when...                    |
| -------------------- | ---------------------------------- |
| 11. Code Example     | Concept has programmatic interface |
| 15. Comparison Table | 2+ named alternatives exist        |

All other sections (1-10, 12-14, 16-19) are always required.

### Depth Calibration by Difficulty

| Aspect             | Easy          | Medium      | Hard                     |
| ------------------ | ------------- | ----------- | ------------------------ |
| Level emphasis     | L1-3          | L2-4        | L3-5                     |
| Code examples min  | 2             | 3           | 4                        |
| Failure modes min  | 3             | 3           | 4                        |
| Misconceptions min | 4             | 5           | 6                        |
| Interview Qs min   | 7             | 9           | 12                       |
| Senior-Staff Leap  | encouraged    | required    | required                 |
| Comparison table   | if applicable | recommended | required if alternatives |
| BEHAVIORAL Q       | optional      | required    | required                 |

### Sizing Guide (words per keyword)

| Concept Type                  | Target Words |
| ----------------------------- | ------------ |
| Tiny (single-purpose, atomic) | 600-1,000    |
| Medium (one mechanism)        | 1,200-2,500  |
| Foundational (multi-faceted)  | 3,000-5,000  |

### Quality Anti-Patterns (NEVER)

- Generic placeholder text or textbook definitions
- Toy code examples (counter++, hello world)
- Vague failure modes ("it might cause issues")
- Interview answers as bullet summaries (must be structured narrative)
- Shallow Level 5 that repeats Level 4 with bigger words
- "It depends" without specifying exactly on what
- Fabricated benchmarks, metrics, or incident stories

### Knowledge Deduplication (multi-keyword files)

- Each keyword answers: "What NEW understanding does THIS entry provide?"
- Reference earlier keywords by name, don't re-explain
- Ensure Interview Deep-Dive Qs are unique across keywords in same file

> Full spec with entry structure, validation checklists, and
> skeleton: `spec/interview_content_generator.md`
