# GitHub Copilot - Workspace Instructions

This workspace is **SK Interview** - an interview-focused technical reference with deep Q&A for every concept. Built with **Material for MkDocs** following the **Interview Mastery Dictionary v1.0** spec.

---

## Workspace Structure

```
southstar/
  mkdocs.yml                  Material for MkDocs config
  requirements.txt            Python dependencies
  .python-version             3.12
  .editorconfig  .gitignore  .markdownlint.json
  README.md  LICENSE  CONTRIBUTING.md

  docs/                       Published content
    index.md                  Homepage
    {topic}/                  Topic folders (java/, spring/, etc)
      index.md                Topic landing page
      {Topic} - {Subtopic}.md Content files (3-5 keywords each)

  spec/                       Generation specs (excluded from build)
    interview_content_generator.md  Master generation spec v1.0
    topics_registry.md        Topic-to-folder mapping + level coverage
    README.md                 Contributor entry point

  scripts/                    Automation (excluded from build)
    scaffold_topic.py         Scaffold generator (Python 3.14)
    generate_topics.ps1       Topic + keyword scaffolding
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
      scaffold.prompt.md             @scaffold
    workflows/
      deploy.yml              MkDocs build + GitHub Pages deploy
    dependabot.yml            Weekly pip + github-actions updates

  .githooks/pre-commit        Local hook (enable via core.hooksPath)
  .vscode/                    Editor settings + recommended extensions
```

## How Instructions Load

| Context                                          | What loads automatically                           |
| ------------------------------------------------ | -------------------------------------------------- |
| Any interaction                                  | This file (lean overview + shared rules)           |
| Editing `docs/**`, `spec/**`, `scripts/**` files | + `.github/instructions/interview.instructions.md` |
| Using `/interview` agent                         | Agent instructions + reads spec on demand          |
| Using `@generate-entries` / `@scaffold`          | Prompt-specific instructions + agent tools         |

## Shared Rules

### Encoding Safety

- Always use `pwsh` (PowerShell 7+), NEVER `powershell.exe`
- UTF-8 without BOM: `[System.Text.UTF8Encoding]::new($false)`
- Python path: `$env:USERPROFILE\.local\bin\python3.14.exe`

### Formatting

- No em dashes anywhere - use regular hyphens only
- Code lines: max 70 characters
- ASCII diagrams: max 59 characters wide
- Diagrams: DUAL format - ASCII block first (universal fallback),
  then Mermaid block immediately below (MAY enhance using native features
  like click events, custom shapes, data charts). Supported Mermaid types
  (all 17): `flowchart`, `sequenceDiagram`, `classDiagram`, `stateDiagram-v2`,
  `erDiagram`, `C4Context`, `gantt`, `timeline`, `requirementDiagram`,
  `journey`, `mindmap`, `block`, `pie`, `xychart-beta`, `sankey-beta`,
  `quadrantChart`, `gitGraph`
- Every code block MUST be followed by `> **Code walkthrough:**` (3-6 sentences:
  what it shows, key mechanism, why it matters, what breaks, takeaway)
- Every diagram MUST be followed by `> **Diagram walkthrough:**` (3-5 sentences).
  For DUAL blocks one shared walkthrough after the Mermaid block is sufficient
- Use `# Keyword Name` as keyword separators within a content file
  (MkDocs renders the first H1 as the page title; subsequent H1s act
  as in-page section anchors)
- Bold-label lines (`**LABEL:** value`) must each be separated by a blank line
- Blockquote (`>`) reserved for: One analogy (Section 5.6), Mental Model
  (Section 5.9), Code walkthrough, Diagram walkthrough, MkDocs admonitions
- BAD pattern before GOOD pattern in all code examples
- Every `###` heading preceded by `---` with blank lines

### YAML (when used in docs/)

- MkDocs does not require frontmatter; use only when overriding page title
  or attaching custom Material metadata (tags, hide, etc.)
- If used, file MUST start at byte 0 with `---` (no BOM, no whitespace)
- Double-quote any title value containing `: ` (colon + space)

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

Every keyword entry MUST pass the Quality Constitution.
Full details in `spec/interview_content_generator.md` Section 6.

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
| Scaffold generator | `scripts/scaffold_topic.py`                      |
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
  full keyword generation spec (34 rules, 31 checks), and `spec/topics_registry.md` for
  the level-coverage framework, then generate keywords covering L0-L6 + META
- When asked to generate/create/upgrade entries, apply all rules
  automatically without confirmation
- When editing files under `docs/`, `spec/`, or `scripts/`, the interview
  instructions auto-load with the 15-section structure and Q&A rules
