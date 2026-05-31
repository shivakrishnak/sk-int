# GitHub Copilot - Workspace Instructions

This workspace is **SK Interview** - an interview-focused technical reference with deep Q&A for every concept. Built with **Just the Docs** (Jekyll) following the **Interview Mastery Dictionary v1.0** spec.

---

## Workspace Structure

```
southstar/
  _config.yml                 Jekyll/just-the-docs config
  Gemfile                     Ruby dependencies
  .editorconfig  .gitignore  .markdownlint.json
  README.md  LICENSE  CONTRIBUTING.md

  docs/                       Published content
    index.md                  Homepage
    {topic}/                  Topic folders (java/, spring/, etc)
      index.md                Topic landing page
      {Topic} - {Subtopic}.md Content files (★★★=1 kw, ★★☆=2 kw, ★☆☆=3 kw per file)

  spec/                       Generation specs (excluded from build)
    interview_content_generator.md  Master generation spec v1.0
    topics_registry.md        Topic-to-folder mapping + level coverage
    README.md                 Contributor entry point

  scripts/                    Automation (excluded from build)
    generate_topics.ps1       Topic + keyword generation
    generate_content.ps1      Batch content generation (5 modes)
    validate.ps1              Pre-commit validator

  .github/
    copilot-instructions.md   This file
    agents/
      interview.agent.md      /interview - full generation agent
    instructions/
      interview.instructions.md   Auto-attaches under docs/, spec/, scripts/
    prompts/
      generate-entries.prompt.md     @generate-entries
    workflows/
      deploy.yml              Jekyll build + GitHub Pages deploy
    dependabot.yml            Weekly bundler + github-actions updates

  .githooks/pre-commit        Local hook (enable via core.hooksPath)
  .vscode/                    Editor settings + recommended extensions
```

## How Instructions Load

| Context                                          | What loads automatically                           |
| ------------------------------------------------ | -------------------------------------------------- |
| Any interaction                                  | This file (lean overview + shared rules)           |
| Editing `docs/**`, `spec/**`, `scripts/**` files | + `.github/instructions/interview.instructions.md` |
| Using `/interview` agent                         | Agent instructions + reads spec on demand          |
| Using `@generate-entries`                        | Prompt-specific instructions + agent tools         |

## Shared Rules

### Encoding Safety

- Always use `pwsh` (PowerShell 7+), NEVER `powershell.exe`
- UTF-8 without BOM: `[System.Text.UTF8Encoding]::new($false)`
- Python path: `$env:USERPROFILE\.local\bin\python3.14.exe`

### Formatting

- No em dashes anywhere - use regular hyphens only
- Code lines: max 70 characters
- ASCII diagrams: max 59 characters wide
- **Liquid safety:** Every content file frontmatter MUST include
  `render_with_liquid: false`. This is belt-and-suspenders over the
  global `_config.yml` default (which is unreliable across Jekyll
  versions when `Gemfile.lock` is not committed). Code examples with
  `{{ }}` or `{% %}` (GitHub Actions, Docker inspect, Prometheus, JSX,
  Angular templates, CSS custom properties) do NOT need
  `{% raw %}` / `{% endraw %}` wrappers - the per-file frontmatter
  flag handles it. Do NOT add `{% raw %}` tags.
  NOTE: `assets/` is excluded - the just-the-docs theme SCSS files
  use Liquid `{% include %}` for CSS generation.
- Diagrams: DUAL format - ASCII block first (universal fallback),
  then Mermaid block immediately below (MAY enhance using native features
  like click events, custom shapes, data charts). Supported Mermaid types
  (all 17): `flowchart`, `sequenceDiagram`, `classDiagram`, `stateDiagram-v2`,
  `erDiagram`, `C4Context`, `gantt`, `timeline`, `requirementDiagram`,
  `journey`, `mindmap`, `block`, `pie`, `xychart-beta`, `sankey-beta`,
  `quadrantChart`, `gitGraph`
- Every code block MUST be followed by `> **Code walkthrough:**` (3-6 sentences
  covering ALL five dimensions: (1) WHAT IT SHOWS: concept or behaviour
  illustrated. (2) KEY MECHANISM: what the runtime/compiler/library does
  step-by-step internally. (3) WHY IT MATTERS: real-world production consequence.
  (4) WHAT BREAKS: exact symptom when misapplied - error message, silent failure,
  or performance cliff. (5) TAKEAWAY: one transferable rule to internalise.
  A bare code block without this walkthrough is a spec violation.)
- Every code block MUST specify language after opening triple backtick.
- Every ASCII diagram MUST be followed by `> **Diagram walkthrough:**`
  (3-5 sentences: (1) WHAT IT DEPICTS, (2) HOW TO READ IT naming each node,
  (3) KEY RELATIONSHIP, (4) EDGE CASE on failure path, (5) INSIGHT senior notices).
- Every Mermaid block MUST be preceded by a 1-2 sentence prose description AND
  followed by `> **Diagram walkthrough:**` using the same five-dimension structure.
  For DUAL blocks one shared walkthrough after the Mermaid block is sufficient.
- Use `# Keyword Name` as keyword separators within a content file
  (Jekyll renders the first H1 as the page title; subsequent H1s act
  as in-page section anchors)
- Bold-label lines (`**LABEL:** value`) must each be separated by a blank line
- Blockquote (`>`) reserved for: One analogy (Section 5.6), Mental Model
  (Section 5.9), Code walkthrough, Diagram walkthrough, just-the-docs callouts
- BAD pattern before GOOD pattern in all code examples
- Every `###` heading preceded by `---` with blank lines

### YAML (frontmatter in docs/)

- **Navigation frontmatter is required** for just-the-docs sidebar rendering.
  Without it, pages render as plain Markdown with no sidebar entry.
  Topic `index.md` required fields: `title`, `nav_order`, `has_children`
  Content files required fields: `layout`, `title`, `parent`, `nav_order`, `permalink`, `render_with_liquid: false`
- **Topic index files (`docs/{topic}/index.md`) MUST NOT have `parent`, `layout`,
  or `permalink`** - adding `parent` nests them under another page instead of root level.
- **Project metadata fields are optional** (`keywords`, `status`, `difficulty_range`,
  `version`, `topic`, `subtopic`). Add only when used by generation scripts.
- File MUST start at byte 0 with `---` (no BOM, no whitespace)
- Double-quote any title value containing `: ` (colon + space)
- just-the-docs nav keys: `nav_order`, `parent`, `has_children`,
  `grand_parent`, `nav_exclude`, `search_exclude`

### Git Workflow

```bash
# Commit every 5 created files (non-negotiable)
git add docs/
git commit -m "feat: add interview <Topic> - batch <N>"

# Do NOT git push
# Do NOT commit single files - always batch of 5
```

**Batch Commit Rules (Non-Negotiable):**

- Commit every **5 created files** (never single files)
- Only commit files that were **created** (not just modified)
- If fewer than 5 remain at the end, commit all remaining
- Do NOT `git push`

## Content Quality Constitution (Non-Negotiable)

<!-- Canonical source: .github/instructions/interview.instructions.md -->
<!-- Duplicated here intentionally: this file loads in ALL sessions, not only docs/spec/scripts edits. -->
<!-- When interview.instructions.md is auto-loaded both copies are visible; when it is not (e.g. non-docs session), this copy enforces the rules. -->

### GATE 2 - QUALITY GATE: MANDATORY SECTION CHECKLIST (HARD STOP)

Before writing ANY keyword to disk, ALL 10 sections below must exist in the output.
A section that is "implied" or "will be added next" does NOT count.
Validator rule R21 enforces this at pre-commit.

Conditional sections must appear with an explicit `*(Omit: reason)*` note when
not applicable. Silent omissions are NEVER acceptable.

| # | Option C Section | Header | Required |
|---|---|---|---|
| 2 | Model Answer | `### 🎯 Model Answer` (30s + 3min + Blank Mind Recovery) | **ALWAYS - no OMIT** |
| 3 | Concept Explanation | `### 📘 Concept Explanation` (all 8 sub-sections) | **ALWAYS - no OMIT** |
| 4 | Code Example | `### 💻 Code Example` | **ALWAYS** - code OR explicit OMIT + reason |
| 5 | Answers by Seniority | `### 🎓 Answers by Seniority` (Junior/Mid + Senior/Staff) | **ALWAYS - no OMIT** |
| 6 | Common Misconceptions | `### ⚠️ Common Misconceptions` | **ALWAYS - no OMIT** |
| 7 | Failure Modes | `### 🚨 Failure Modes and Diagnosis` | **ALWAYS - no OMIT** |
| 8 | Interview Deep-Dive | `### 🎯 Interview Deep-Dive` | **ALWAYS (CAPSTONE) - no OMIT** |
| 9 | Comparison Table | `### ⚖️ Comparison Table` | **ALWAYS** - table OR explicit OMIT for ★☆☆ |
| - | System Design | `### 🏛️ System Design` | **ALWAYS** - design OR explicit OMIT for non-★★★ |
| - | Diagram | `### 📊 Diagram` | **ALWAYS** - diagram OR explicit OMIT for non-visual |

**⚠️ Most frequently dropped sections - audit findings across 694 files:**
Verify these 4 sections are present BEFORE writing any keyword to disk:
- `### 📘 Concept Explanation` - 30 files missing (most commonly dropped)
- `### 🚨 Failure Modes and Diagnosis` - 35 files missing across 7 topics
- `### ⚠️ Common Misconceptions` - 25+ files missing
- `### 🎯 Interview Deep-Dive` - truncated in L6/META files for several topics

**⛔ HARD STOP triggers:**
- Any section header (rows 2-10 above) missing from the output
- Section §2 missing `**Blank Mind Recovery:**` block
- Section §8 questions below minimum (★☆☆:7, ★★☆:9, ★★★:12)
- A conditional section silently absent (no header, no OMIT note)
- `spec/interview_content_generator.md` not read in this session

Every keyword entry MUST pass the Quality Constitution.
Full details in `spec/interview_content_generator.md` Section 6.

### GATE 3 - POST-WRITE FILE VERIFICATION (Non-Negotiable)

After EVERY keyword write to disk, grep the actual written file for all
mandatory section headers before updating index.md or continuing.
Memory confirmation is insufficient - the file must be checked directly.

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
# No output = GATE 3 PASS. Any output = FAIL - fix before proceeding.
```

### Eight Quality Tests (ALL must pass)

| #   | Test               | Core Question                                        |
| --- | ------------------ | ---------------------------------------------------- |
| 1   | Search Again?      | Would a serious engineer need to look elsewhere?     |
| 2   | Feynman            | Could a smart beginner understand without confusion? |
| 3   | Senior Engineer    | Would a senior engineer still learn something?       |
| 4   | Staff Engineer     | Would a staff/principal engineer respect this?       |
| 5   | Production Reality | Could someone diagnose a real issue after reading?   |
| 6   | Retention          | Will the reader remember this next month?            |
| 7   | Decision           | Could the reader decide when to use or avoid this?   |
| 8   | Scale              | What changes at 10x, 100x, 1000x?                    |

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

Before outputting: _"Would an experienced engineer say 'Damn - this is
genuinely excellent'?"_ If uncertain: rewrite. Masterclass = target.

## Quick Reference

| Item               | Location                                         |
| ------------------ | ------------------------------------------------ |
| Full spec          | `spec/interview_content_generator.md`            |
| Topic registry     | `spec/topics_registry.md`                        |
| Topic generator    | `scripts/generate_topics.ps1`                    |
| Content generator  | `scripts/generate_content.ps1`                   |
| Validator          | `scripts/validate.ps1`                           |
| Auto-instructions  | `.github/instructions/interview.instructions.md` |

**Version Registry:** `SPEC_VERSION` = 1, `SPEC_LABEL` = v1.0

## Default Behaviour

- When asked to work on interview content: read `spec/interview_content_generator.md` for the
  full v1.0 spec (ONCE per session, first keyword only). Subsequent
  keywords use the condensed rules in
  `.github/instructions/interview.instructions.md` (auto-loaded)
- When generating a NEW topic from scratch: read `spec/topics_generator.md` for the
  full keyword generation spec (37 rules, 36 checks), and `spec/topics_registry.md` for
  the level-coverage framework, then generate keywords covering L0-L6 + META
- When asked to generate/create/upgrade entries, apply all rules
  automatically without confirmation
- When editing files under `docs/`, `spec/`, or `scripts/`, the interview
  instructions auto-load with the 8-section Option C structure and Q&A rules
