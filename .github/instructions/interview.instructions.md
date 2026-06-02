---
applyTo: "docs/**, spec/**, scripts/**"
description: "Rules for generating and editing Interview Mastery Dictionary v1.0 content - Option C hybrid format (8 sections), keyword-batch generation, Q&A format"
---

> **Version Registry** - `SPEC_VERSION` = **1** | `SPEC_LABEL` = **v1.0**

## ⛔ CONFIRMED FAILURES - NON-NEGOTIABLE HARD RULES

They are permanently prohibited. Violation = file is REJECTED, not written.

**FAILURE 1 - Spec not read:** NEVER generate any entry without first reading
`spec/interview_content_generator.md` in full in the current session. Generating
from memory or conversation summaries produces wrong headers. ALWAYS read the spec.

**FAILURE 2 - Partial section generation (most common recurring failure):**
Files written to disk with fewer than all mandatory sections. A production
audit across 694 files found 35 files in 7 topics with missing sections.
The 4 most frequently dropped sections (in order of recurrence):

1. `### 📘 Concept Explanation` - 30 files missing (Quarkus all 10, GraalVM
   all 10, Micronaut most) - generation started from wrong/truncated template
2. `### 🚨 Failure Modes and Diagnosis` - 35 files missing (7 topics) -
   silently omitted near end of long responses under length pressure
3. `### ⚠️ Common Misconceptions` - 25+ files missing - same dropout pattern
4. `### 🎯 Interview Deep-Dive` - Observability L6+META, Java EE L6+META -
   response truncated before the CAPSTONE section

Fix: GATE 3 mandatory post-write verification. NEVER mark a keyword `draft`
without running Gate 3 on the actual written file (not from memory).

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

**RULE:** Before writing any keyword to disk, confirm ALL mandatory sections
are present in the planned output block. A section that is "implied" or
"will be added next" does NOT count - it must exist in THIS output.

**ALL 10 sections required per keyword - NON-NEGOTIABLE (source: interview.instructions.md + spec/interview_content_generator.md):**

Conditional sections must appear with an explicit `*(Omit: reason)*` note when not applicable.
Silent omissions are NEVER acceptable - the section header MUST always be present.

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

**⚠️ Most frequently dropped sections - verify these FIRST before writing:**
- `### 📘 Concept Explanation` - most commonly missing; never skip
- `### 🚨 Failure Modes and Diagnosis` - frequently omitted near end of output
- `### ⚠️ Common Misconceptions` - frequently omitted near end of output
- `### 🎯 Interview Deep-Dive` - CAPSTONE; truncated in long responses

**⛔ HARD STOP - Do NOT write the file if:**
- Any section header (rows 2-10 above) is missing from the output
- Section §2 does not contain a `**Blank Mind Recovery:**` block
- Section §8 (Interview Deep-Dive) has fewer than the minimum questions
  (★☆☆: 7, ★★☆: 9, ★★★: 12)
- A conditional section is silently absent (no header, no OMIT note)
- `spec/interview_content_generator.md` has not been read in this session

**Recovery:** Immediately append any missing section before updating index.md.
Validator rule R21 catches all 10 sections at pre-commit and blocks the commit.

### GATE 3 - POST-WRITE FILE VERIFICATION (Fixes Failure 2)

**RULE:** After EVERY keyword write to disk, verify the actual written file
contains all mandatory section headers before updating index.md status or
continuing to the next keyword. Memory is not sufficient - check the file.

**Run after every write (replace {topic}/{File} with actual path):**

```pwsh
$f = "docs/{topic}/{File}.md"
@(
  "### 🎯 Model Answer",
  "### 📘 Concept Explanation",
  "### 🎓 Answers by Seniority",
  "### ⚠️ Common Misconceptions",
  "### 🚨 Failure Modes and Diagnosis",
  "### 🎯 Interview Deep-Dive"
) | ForEach-Object {
  if ((Get-Content $f -Raw) -notmatch [regex]::Escape($_)) {
    Write-Host "MISSING: $_" -ForegroundColor Red
  }
}
# No output = GATE 3 PASS. Any output = FAIL.
```

**Gate 3 FAIL:** Append every missing section immediately. Re-run the
command. Do NOT update index.md status to `draft` until output is empty.

---

# Interview Mastery Dictionary - Auto-Loaded Instructions

> These instructions auto-attach when editing files under `docs/`,
> `spec/`, or `scripts/`. Full generation spec: `spec/interview_content_generator.md` (v1.0).
> This file contains condensed generation rules sufficient for producing
> content after reading the full spec once per session.

## Workspace Structure

```
southstar/
  _config.yml                 Jekyll/just-the-docs config
  Gemfile                     Ruby dependencies
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
    generate_topics.ps1
    generate_content.ps1
    validate.ps1
```

## Prompts (in .github/prompts/)

| Prompt              | Purpose                                       |
| ------------------- | --------------------------------------------- |
| `@generate-entries` | Generate keyword content (keyword-batch mode) |

## Content Structure - Option C Hybrid (8 Sections per Keyword)

Every keyword generates these sections in this order.
Full rules for each section are in the Condensed Generation Reference below.

| #   | Heading                              | Required           | Source Rules                |
| --- | ------------------------------------ | ------------------ | --------------------------- |
| 1   | `# Keyword Name` + Interview Weight  | Always             | -                           |
| 2   | `### 🎯 Model Answer`                | Always             | CGR §5, §8                  |
| 3   | `### 📘 Concept Explanation`         | Always             | CGR §3, §4, §6, §7, §9, §10 |
| 4   | `### 💻 Code Example`                | If programmatic    | CGR §11                     |
| 5   | `### 🎓 Answers by Seniority`        | Always             | CGR §8                      |
| 6   | `### ⚠️ Common Misconceptions`       | Always             | CGR §16                     |
| 7   | `### 🚨 Failure Modes and Diagnosis` | Always             | CGR §17                     |
| 8   | `### 🎯 Interview Deep-Dive`         | Always (CAPSTONE)  | CGR §18                     |
| 9   | `### ⚖️ Comparison Table`            | ★★☆ and above only | CGR §15                     |

**Section order is fixed.** Do not reorder or skip mandatory sections.

> **CGR-to-Option-C mapping:**
>
> - CGR §§3,4,6,7,9,10 (Problem, Definition, First Principles, Mental
>   Model, How It Works, End-to-End Flow) -> Option C **§3 Concept Explanation**
> - CGR §5 (Understand in 30s) -> Option C **§2 Model Answer** (TL;DR + insight)
> - CGR §8 (Five Levels) -> Option C **§5 Answers by Seniority**
> - CGR §11 (Code Example) -> Option C **§4 Code Example** (conditional)
> - CGR §15 (Comparison Table) -> Option C **§9 Comparison Table** (conditional)
> - CGR §§16,17,18 -> Option C **§§6,7,8** directly
> - CGR §§12,13,14,19 (Quick Ref, Checklist, Surprising Truth, Related KW)
>   are absorbed into the nearest relevant Option C section or omitted.

## Interview Deep-Dive Section Rules (Section 8 - CAPSTONE)

- **Min questions by difficulty:** easy=7, medium=9, hard=12 (no cap)
- Tag each question: `[JUNIOR]` `[MID]` `[SENIOR]` `[STAFF]`
- Per question: question → `*Why they ask:*` → `*Likely follow-up:*`
- Per answer: 200-500 words, complete structured spoken answer
- End every answer: `*What separates good from great:*`
- Include **timing guidelines table** at section start (5-row)
- Include **interviewer type adaptation table** at section end
- Cover ≥5 of 9 categories: CONCEPTUAL, DEBUGGING, ARCHITECTURE,
  TRADE-OFF, PRODUCTION, HANDS-ON, SYSTEM DESIGN, COMPARISON, BEHAVIORAL
- Mandatory per keyword: 1 DEBUGGING + 1 TRADE-OFF question
- Mandatory for ★★☆+: 1 BEHAVIORAL question (STAR format)
- Question order: foundational → advanced → expert
- No duplicate questions across keywords in the same file

## Jekyll / Liquid Safety

**Rule:** Every content file frontmatter MUST contain
`render_with_liquid: false`. This flag is REQUIRED but INSUFFICIENT on
its own - Jekyll's Liquid PARSER scans page content BEFORE checking the
flag (confirmed with `error_mode: warn` in `_config.yml`), emitting
Liquid Exceptions/warnings for `{{ }}` and `{% %}` inside code blocks.

**Mandatory frontmatter field - REQUIRED in every content file:**
```yaml
render_with_liquid: false
```
Place it as the last field before the closing `---`.

**MANDATORY for code blocks containing `{{ }}` or `{% %}` patterns:**

Any code fence with Liquid-like patterns MUST be wrapped with
`{% raw %}` / `{% endraw %}` tags placed OUTSIDE the fence.

```
{% raw %}
```yaml
${{ secrets.TOKEN }}
```
{% endraw %}
```

- Place `{% raw %}` on the line IMMEDIATELY BEFORE the opening ` ``` `
- Place `{% endraw %}` on the line IMMEDIATELY AFTER the closing ` ``` `
- These tags are consumed by the Liquid parser; they do NOT appear in
  rendered output
- Patterns requiring protection: `{{ }}`, `{% %}` - includes GitHub
  Actions (`${{ secrets.X }}`), Docker inspect (`{{.State.Pid}}`),
  Prometheus (`{{ $value | humanize }}`), JSX (`style={{ color: 'red' }}`),
  Angular (`{{ count }}`), CSS custom properties, Helm templates, etc.

Validation rule R28 in `scripts/file_validation_rules.ps1` enforces this
at pre-commit. R28 fails with an error if any code block contains
unprotected Liquid patterns.

**If a build breaks with a Liquid Exception in a docs file:**
- Wrap the offending code fence with `{% raw %}` / `{% endraw %}`
  (outside the fence, not inside)
- Ensure `render_with_liquid: false` is in frontmatter
- Run `scripts/validate.ps1` to check R28 across all files
- Run `_fix_liquid_raw.ps1` (workspace root) to auto-fix all files


## Formatting Rules

- Code lines: max 70 characters
- ASCII diagrams: max 59 characters wide
- Diagrams: DUAL format - ASCII block first, then equivalent Mermaid block
  immediately below. All standard Mermaid types supported; common types:
  `flowchart`, `sequenceDiagram`, `stateDiagram-v2`, `classDiagram`,
  `erDiagram`, `mindmap`, `timeline`, `xychart-beta`, `gantt`, `gitGraph`
- Paragraphs: max 5 sentences
- BAD pattern before GOOD pattern in all code examples
- Every `###` heading preceded by `---` with blank lines
- Keywords within a file separated by double horizontal rules
- No em dashes anywhere - use regular hyphens only
- Bold-label lines (`**LABEL:** value`) must each be separated by a blank line
- Use `# Keyword Name` as keyword separators within content files
  (Jekyll renders the first H1 as the page title)
- Every code block MUST be followed by `> **Code walkthrough:**` (3-6 sentences
  covering ALL five dimensions - a bare code block is a spec violation):
  (1) WHAT IT SHOWS: concept or behaviour illustrated.
  (2) KEY MECHANISM: what the runtime/compiler/library does step-by-step.
  (3) WHY IT MATTERS: real-world consequence in production if used
      correctly or incorrectly.
  (4) WHAT BREAKS: exact symptom when misapplied - error message,
      silent failure, or performance cliff.
  (5) TAKEAWAY: one transferable rule the reader should internalise.
- Always specify language after opening triple backtick (e.g. ` ```java `).
- ASCII diagrams: max 59 characters wide (ESCAPE HATCH: up to 79 chars only if
  adjacent prose description exists AND content is genuinely clearer at that
  width; >79 → split or convert to Mermaid-only).
- Every ASCII diagram MUST be followed by `> **Diagram walkthrough:**`
  (3-5 sentences covering ALL five dimensions):
  (1) WHAT IT DEPICTS: name the system, flow, or structure.
  (2) HOW TO READ IT: walk left-to-right or top-to-bottom, naming each
      key node and arrow explicitly.
  (3) KEY RELATIONSHIP: most important dependency, bottleneck, or
      decision point.
  (4) EDGE CASE: what happens on the error/failure path shown, or why
      none is depicted.
  (5) INSIGHT: what a senior engineer notices that a junior overlooks.
- Every Mermaid block MUST be preceded by a 1-2 sentence prose description
  (accessibility alt-text) AND followed by `> **Diagram walkthrough:**`
  using the same five-dimension structure above.
- For DUAL blocks (ASCII + Mermaid): one shared walkthrough AFTER the Mermaid
  block is sufficient - do not duplicate.

### Blank Mind Recovery Format (Mandatory - R19)

Every keyword Model Answer section MUST include a Blank Mind Recovery block.
The block appears AFTER the 3-minute blockquote, BEFORE the `---` separator.

**Required format (Format A - standalone block):**

```markdown
**Blank Mind Recovery:**

**(1) Restate:** "You are asking about [TOPIC] - let me walk through
[KEY ASPECTS]."

**(2) First principles:** "From first principles, [CORE CONCEPT].
[KEY CONSTRAINT OR MECHANISM]."

**(3) Bridge:** "[CONCRETE ANALOGY that maps the concept to something
familiar]."
```

**Rules (validated by R19):**

- `**Blank Mind Recovery:**` must use bold (`**...**`) - not bare text
- Step labels must be bold: `**(1) Restate:**`, `**(2) First principles:**`,
  `**(3) Bridge:**` - never bare `(1) Restate:`
- Each step must be its own paragraph (blank line between steps)
- Multiple steps MUST NOT appear on the same line
- Line max 70 chars (same as all prose)

**Format B (table row - L0/L1 compact format only):**

In L0/L1 files that use the compact Interview Deep-Dive table, "Blank mind
recovery" (lowercase) appears as the last table row with a one-liner cue.
This format is intentional for L0/L1 and is NOT checked by R19.

## Encoding Rules

- UTF-8 without BOM
- Always use `pwsh` (PowerShell 7+), NEVER `powershell.exe`
- `[System.Text.UTF8Encoding]::new($false)` only for small writes (< 2KB)
- Python: `$env:USERPROFILE\.local\bin\python3.14.exe`
- No emojis in YAML frontmatter

### File Write Protocol (MANDATORY - prevents silent failures)

NEVER write keyword content using PowerShell here-strings (`@'...'@`)
or `[System.IO.File]::WriteAllText()` with inline content.
Large content (> 5KB) triggers interactive `>>` prompts or silently fails.

**Writing a new file (first keyword):**

1. `create_file` tool -> `_tmp_kw.md` (workspace root)
2. `Copy-Item "_tmp_kw.md" "docs/{topic}/{File}.md" -Force`
3. Verify: `read_file` first 20 lines

**Appending to existing file (subsequent keywords):**

1. `create_file` tool -> `_tmp_kw.md` (keyword block only, no frontmatter)
2. `Get-Content "_tmp_kw.md" | Add-Content "docs/{topic}/{File}.md" -Encoding UTF8`
3. Verify: `grep_search` for new keyword heading in the target file

### Batch Size Limits (HARD CAP - prevents output length overflow)

| Difficulty | Keywords/Call | Reason |
| ---------- | ------------- | ------ |
| Hard (★★★)  | 1             | 12 Q&As + 10 sections ≈ 6,000-8,000 words |
| Medium (★★☆)| 2 max         | 9 Q&As each + 10 sections ≈ 8,000-10,000 words |
| Easy (★☆☆)  | 3 max         | 7 Q&As each ≈ 6,000-7,500 words total |

> Violating these limits causes the model response to be cut off mid-keyword,
> producing incomplete output that fails Gate 2 validation.

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

## File Frontmatter (Required for Navigation)

Every file under `docs/` MUST start with a frontmatter block.
Frontmatter drives the just-the-docs sidebar navigation hierarchy.
Without it, pages render as plain Markdown with no sidebar entry.

### Root index (`docs/index.md`)

```yaml
---
layout: default
title: "SK Interview"
nav_order: 1
has_children: true
permalink: /
---
```

### Topic index (`docs/{topic}/index.md`)

Topic folders appear at root level in the sidebar navigation.
Do NOT add `parent`, `layout`, or `permalink` - they cause nesting.

```yaml
---
title: "{Topic Name}" # matches the folder's display name
nav_order: N          # controls sidebar order (see nav_order Reference)
has_children: true
---
```

### Content file (`docs/{topic}/{File}.md`)

```yaml
---
layout: default
title: "{Topic} - {Subtopic}" # e.g. "Java Language - L0 Orientation"
parent: "{Topic Name}"        # must match topic index title exactly
nav_order: N                  # position within topic folder (1-based)
permalink: /{topic-slug}/{file-slug}/ # kebab-case slug
render_with_liquid: false     # MANDATORY - prevents Liquid parsing of code
---
```

> `render_with_liquid: false` is **MANDATORY** in every content file.
> The global `_config.yml` default alone is not reliable when `Gemfile.lock`
> is not committed (CI may use a different Jekyll version). Per-file
> frontmatter is the only guaranteed protection for `{{ }}` and `{% %}` in
> code examples.

### Frontmatter Rules (Non-Negotiable)

- File MUST start at byte 0 with `---` (no BOM, no leading whitespace)
- `title` must be quoted when it contains `: ` (colon + space)
- `parent` value must match the `title` of the topic index exactly
- Topic `index.md` MUST NOT have `parent` - it must be at root level
- `layout: default` is required on content files, NOT on topic index files
- `has_children: true` is required on every page that has child pages
- Do NOT add metadata keys (`keywords`, `status`, `difficulty_range`, etc.) -
  these are not used by just-the-docs and add noise to frontmatter

### nav_order Reference

| nav_order | Topic            |
| --------- | ---------------- |
| 1         | Java Language    |
| 2         | Java Core APIs   |
| 3         | Java JVM         |
| 4         | Java Concurrency |
| 5         | Java Performance |

Within each topic folder, content files are numbered 1-N in level order
(L0=1, L1=2, L2 files=3-5, L3 files=6-7, L4=8, L5=9, META=10).

## Keyword Navigation Block (Required - R20)

Every content file MUST have a keyword navigation table immediately after
the frontmatter block (before the first `# Keyword` heading). This block
lets readers jump directly to any keyword on the page.

### Required format

```markdown
---
layout: default
title: "..."
...
---

## Keywords in This File

{: .no_toc }

| #   | Keyword                      | Weight |
| --- | ---------------------------- | ------ |
| 1   | [Keyword Name Here](#anchor) | medium |
| 2   | [Keyword Name Here](#anchor) | high   |

---

# First Keyword Name
```

### Anchor generation (kramdown/Jekyll rules)

1. Take the exact heading text (without `# `)
2. Lowercase everything
3. Replace each space with `-`
4. Remove all characters except `a-z`, `0-9`, `-`
5. Do NOT collapse consecutive hyphens (`-` becomes `---`)
6. Trim leading/trailing hyphens

Examples:

- `Primitives vs References: The Two Type Universes`
  -> `#primitives-vs-references-the-two-type-universes`
- `Reflection: Class, Method, Field - Power, Cost, Security`
  -> `#reflection-class-method-field---power-cost-security`
- `java.util.concurrent: The Parallel Universe for Thread Safety`
  -> `#javautilconcurrent-the-parallel-universe-for-thread-safety`

### Rules

- `{: .no_toc }` after the `## Keywords` heading excludes it from
  the page's auto-generated table of contents
- The `Weight` column uses the exact Interview Weight value from the
  keyword (e.g. `low`, `medium`, `high`, `critical`, `low-medium`,
  `medium-high`)
- The navigation block is followed by `---` (single HR), then a blank
  line, then the first `# Keyword Name`
- Skip index.md files (they use a different keyword registry format)
- Validated by R20 in `scripts/file_validation_rules.ps1`
- Use `scripts/add_keyword_nav.ps1` to add blocks to all existing files

### Batch Commit Rules (Non-Negotiable)

- Commit every **5 created files** (never single files)
- Only commit files that were **created** (not just modified)
- If fewer than 5 remain at the end, commit all remaining at once
- Do NOT `git push`

```bash
git add docs/
git commit -m "feat: add interview <Topic> - batch <N>"
```

## Generation Workflows

**Existing topic:** `Generate interview mastery content: Topic: Java, File: Java - Collections.md`

**New topic:** `Create new interview mastery topic: Angular` (checks registry, generates keywords, creates files)

## Folder Opportunity Analysis (Mandatory Before Creating Any Topic)

Before creating a topic folder, analyze whether the topic contains
distinct sub-domains that each deserve their own folder. Never squeeze
multiple distinct sub-domains into one folder.

### Analysis Questions

1. **Does the topic have >= 2 natural sub-domains?**
   - If yes: create one folder per sub-domain
   - If no: one folder is correct
2. **Would keywords from different sub-domains confuse a reader?**
   - "JVM GC tuning" and "Java collections API" are different mental
     spaces; they belong in different folders
3. **Can the sub-domain stand alone as an interview topic?**
   - If an interviewer can spend 45 min asking only about this
     sub-domain, it deserves its own folder

### Java as the Canonical Reference

| Folder              | Sub-domain                                          |
| ------------------- | --------------------------------------------------- |
| `java-language/`    | Language spec: types, OOP, generics, lambdas,       |
|                     | modern features (records, sealed, pattern matching) |
| `java-core/`        | Platform APIs: collections, I/O, NIO, exceptions,   |
|                     | serialization, reflection, annotations              |
| `java-jvm/`         | VM internals: class loading, GC algorithms, JIT,    |
|                     | bytecode, memory model, JPMS                        |
| `java-concurrency/` | Concurrency: threads, locks, executors,             |
|                     | CompletableFuture, virtual threads (Loom)           |
| `java-performance/` | Diagnostics: JFR, async-profiler, heap dumps,       |
|                     | GC log analysis, JVM flag tuning                    |

### Canonical Groupings by Domain

| Domain      | Natural sub-domain folders                          |
| ----------- | --------------------------------------------------- |
| Language    | syntax/types + core-APIs + VM + concurrency + perf  |
| Framework   | core + advanced + internals + testing + production  |
| Database    | SQL + indexing + transactions + ORM + performance   |
| Cloud/Infra | compute + networking + storage + security + monitor |

### Never Mix in One Folder

- Language features + VM internals (different mental models)
- Core APIs + performance diagnostics (different expertise)
- Concurrency primitives + async frameworks (different abstraction)
- Business logic patterns + infrastructure concerns

### Pre-Creation Checklist

Before creating `docs/{topic}/`:

- [ ] Is this a single coherent sub-domain?
- [ ] Have I checked if a parent or sibling folder already exists?
- [ ] Would an interviewer treat this as a standalone interview area?
- [ ] Is the folder name specific enough? (never just `java/`)
- [ ] Have I run the Level Coverage verification for this sub-domain?

---

## Folder/File Rules

- One folder per main topic under `docs/` (lowercase, hyphens)
- Each folder has `index.md` listing sub-topic files
- Sub-topic files: `{Topic} - {Subtopic}.md`
- File cap by difficulty: ★★★=1 keyword, ★★☆=2 keywords, ★☆☆=3 keywords
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

**Keywords per file by difficulty: ★★★=1, ★★☆=2, ★☆☆=3.**
Split into multiple files when a level exceeds its cap. File limit
equals batch size — every file completes in one generation call.

**File structure per topic:**

- `{Topic} - L0 {Subtopic}.md` for L0 keywords (★☆☆: 3 per file)
- `{Topic} - L1 {Subtopic}.md` for L1 keywords (★☆☆: 3 per file)
- `{Topic} - L2 {Subtopic}.md` for L2 keywords (★★☆: 2 per file, split by subtopic)
- `{Topic} - L3 {Subtopic}.md` for L3 keywords (★★☆: 2 per file, split by subtopic)
- `{Topic} - L4 {Subtopic}.md` for L4 keywords (★★★: 1 per file, named by concept)
- `{Topic} - L5 {Subtopic}.md` for L5 keywords (★★★: 1 per file, named by concept)
- `{Topic} - L6 {Subtopic}.md` for L6 keywords (★★☆: 2 per file)
- `{Topic} - META {Subtopic}.md` for META keywords (★☆☆: 3 per file)

File names must be descriptive noun phrases for the content inside.
Never use sequence numbers ("Part 1", "Part 2") as subtopic names.

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

> **Content rules, not output headings.** The 19 items below define
> what to include _inside_ each Option C section - they are not H3
> headings to generate. The only output headings are the 8 (or 9)
> listed in the Option C table above. Use these rules as a checklist
> for the _content_ of each Option C section.

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

| Option C Section    | Include when...                          |
| ------------------- | ---------------------------------------- |
| 4. Code Example     | Concept has a programmatic interface     |
| 9. Comparison Table | Difficulty ★★☆ or above, 2+ alternatives |

All other Option C sections (1-3, 5-8) are always required.
Related Keywords (CGR §19) is optional - include only when the cross-
references add signal not already present in the keyword content.

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
