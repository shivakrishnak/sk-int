# SK Interview - Content Generation Rules

# Repo: c:\ASK\Mastery\southstar

# Workspace: Interview Mastery Dictionary v1.0 (Material for MkDocs)

# Last updated: 2026-05-23

## CRITICAL MISTAKES - never repeat

### M1 - Context window overload before generation (CRITICAL)

- Cause: reading spec/interview_content_generator.md (1000+ lines) AND
  interview.instructions.md (1200+ lines) AND index.md BEFORE generating
- Result: context window consumed, nothing left for actual content
- Fix: interview.instructions.md auto-loads for docs/**, spec/**, scripts/\*\*
  Trust it. Only read full spec ONCE per session for the very first keyword.
  Read ONLY the Keyword Registry sub-section from index.md (not the full file).

### M2 - replace_string_in_file fails on files >~1,500 lines

- Cause: rendering/whitespace differences in how the tool processes large content
- Symptom: "string not found" even when text appears correct
- Fix: ALWAYS use PowerShell Add-Content for keywords 2+ in any file:
  ```
  $content = @'...'@
  Add-Content -Path $file -Value $content -Encoding UTF8
  ```
- Pattern: create_file for keyword 1, Add-Content for keywords 2 through N

### M3 - File-level generation causes output limit timeouts

- Cause: all 5 keywords in one pass = 15,000-25,000 words
- Fix: keyword-batch strategy - 1 per batch (hard), 2 (medium), 3 (easy)

### M4 - Frontmatter as keyword source breaks when frontmatter is absent

- Frontmatter is OPTIONAL in this project (MkDocs does not require it)
- Fix: ALWAYS read {topic}/index.md Keyword Registry as primary source
  Fall back to frontmatter keywords: field only if index.md does not exist

### M5 - Version field conflict (version: 3 vs version: 1)

- interview.instructions.md previously said version: 3 (wrong)
- Canonical value: version: 1 (matches SPEC_VERSION constant)
- All files now fixed; verify with grep "version: 3" returning zero matches

### M6 - Outdated file naming in agent.md caused wrong filenames

- Old: Foundations.md, Architecture and Strategy.md
- Correct: L0 Orientation.md, L1 Foundations.md, L5 Architecture.md, META Patterns.md
- Always check index.md for exact registered filenames before creating files

### M7 - "19 sections" vs "8 Option C sections" confusion

- The 19 CGR items are CONTENT RULES for what goes inside 8 output sections
- Never say "generate 19 sections" - say "generate 8 Option C sections"

### M8 - Quality rules duplicated across 4 files (resolved)

- Quality Constitution, Code Examples, 10-Point Standard, Forbidden Patterns
  were duplicated verbatim in agent.md, instructions.md, both prompt files
- Fix: single source in interview.instructions.md; all others reference it
- Verification: grep "Quality Constitution" should only appear in instructions.md

---

## OPTIMIZATION TECHNIQUES

### O1 - Keyword-batch sizing (exact numbers, non-negotiable)

- hard keywords: 1 per batch
- medium keywords: 2 per batch
- easy keywords: 3 per batch

### O2 - File write pattern

- Keyword 1: create_file with full content (includes H1 title of file)
- Keywords 2+: PowerShell Add-Content append (NEVER replace_string_in_file)
- Separator between keywords: blank line + --- + blank line + --- + blank line

### O3 - Context-lean reads

- Read ONLY the Keyword Registry sub-section of index.md (grep/search for it)
- When appending, read only the LAST 30 LINES of the target file for anchor
- Do NOT re-read the full file - previous keywords are irrelevant context

### O4 - No spec re-reads after first keyword

- Full spec is ONLY read for the very first keyword of a session
- interview.instructions.md (auto-loaded) has all rules for subsequent keywords
- This saves ~1,200 lines of context per keyword batch

### O5 - Single-pass generation

- Produce all sections for one keyword in one continuous output block
- Never split a single keyword across multiple tool calls

### O6 - Auto-continue without asking

- After completing a keyword batch: report progress, then auto-continue
- Never ask "shall I continue?" - keep generating until scope is done
- Only stop for: complete scope / unrecoverable error / explicit user pause

---

## PROCESS IMPROVEMENT TECHNIQUES

### P1 - Index.md is the ONLY source of truth for keywords

- Status values in Keyword Registry: pending / draft / complete
- pending = not started, generate next batch
- draft = content written, not yet reviewed
- complete = reviewed and approved

### P2 - File creation checks before writing

- Always verify the file does NOT already exist before create_file
- Always verify the file DOES exist before Add-Content append
- Use Test-Path to confirm before each write operation

### P3 - Commit cadence: every 5 CREATED files

- Count only created files (not modified files like index.md)
- git add docs/
- git commit -m "feat: add interview <Topic> - batch <N>"
- NEVER git push

### P4 - Cross-file audit pattern (for spec/instruction maintenance)

- Before major changes: inventory all spec/instruction files
- Build cross-file comparison matrix for each rule type
- Identify: duplicates, conflicts, missing rules, stale patterns
- Fix: establish single source of truth, others reference it
- Verify: grep for patterns that should no longer exist

### P5 - Diagram and code walkthrough are mandatory (from workspace rules)

- Every code block: > **Code walkthrough:** (3-6 sentences)
- Every diagram: > **Diagram walkthrough:** (3-5 sentences)
- DUAL diagram blocks: one shared walkthrough after the Mermaid block

---

## CURRENT STATE (java-language topic)

| File                              | Status   | Keywords |
| --------------------------------- | -------- | -------- |
| Java Language - L0 Orientation.md | complete | 5/5      |
| Java Language - L1 Foundations.md | complete | 5/5      |
| Java Language - L2 Object Model   | pending  | 0/5      |
| Java Language - L2 Generics       | pending  | 0/5      |
| Java Language - L2 Functional     | pending  | 0/5      |
| Java Language - L3 Type System    | pending  | 0/5      |
| Java Language - L3 Modern Java    | pending  | 0/5      |
| Java Language - L4 Internals      | pending  | 0/4      |
| Java Language - L5 Architecture   | pending  | 0/3      |
| Java Language - META Patterns     | pending  | 0/3      |

Remaining: 38 keywords across 8 files
Commits needed: 2 (5 files each, last batch has 3 files - commit at end)
