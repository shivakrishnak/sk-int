# Validation Rules - Critical Notes for Content Generation

## File: scripts/file_validation_rules.ps1 (28 rules)

---

## R02 - No Em Dashes
- `—` (U+2014) is FORBIDDEN everywhere - use regular hyphen `-`
- Common violation: `DS-001 — Keyword Name` → use `DS-001 - Keyword Name`
- Common violation: `Critical — Asked...` → use `Critical - Asked...`

---

## R06 - Code Line Length
- Validator enforces MAX 100 chars (not 70 as stated in spec prose)
- Skipped for: mermaid, bash, sh, shell, yaml, json, xml, text, powershell, etc.

---

## R07 - ASCII Diagram Width
- Validator enforces MAX 80 chars (not 59 as stated in spec prose)

---

## R08 - H3 Must Be Preceded by `---`
- Every `###` heading must have `---` within 3 lines before it (with blank lines OK)

---

## R09 - Code/Diagram Walkthroughs Required
- Every closing ``` must be followed within 3 lines by `> **Code walkthrough:**`
- Mermaid blocks: `> **Diagram walkthrough:**`
- DUAL ASCII+Mermaid pairs: ONE shared walkthrough after Mermaid is sufficient

---

## R10 - DUAL Diagram Format
- Every ```mermaid block must be PRECEDED by an ASCII block within 30 lines
- No standalone mermaid blocks allowed

---

## R12 - Interview Deep-Dive Question Counting - CRITICAL FORMAT
```
**[JUNIOR] Q1 - Question text here?
**[MID] Q2 - Another question?
**[SENIOR] Q3 - Senior-level question?
**[STAFF] Q4 - Staff-level question?
```
- Line MUST START with `**[` (e.g. `**[JUNIOR]`, `**[MID]`, `**[SENIOR]`, `**[STAFF]`)
- Alternative: `1. **[JUNIOR]` also works
- WRONG: `**Q1.` or `---\n**Q1.` or `Q1.` - these are NOT counted
- Minimums: easy=7, medium=9, hard=12

---

## R18 - No Duplicate Lines
- 50+ char non-heading lines must not repeat verbatim in the same file
- Exception: `*What separates good from great` and `**Interview Weight:**` lines

---

## R19 - Blank Mind Recovery Format
```markdown
**Blank Mind Recovery:**

**(1) Restate:** "..."

**(2) First principles:** "..."

**(3) Bridge:** "..."
```
- Must use bold `**...**` for heading AND step labels
- Each step MUST be a separate paragraph (blank line between each step)
- WRONG: bare `(1) Restate:` without `**...**`

---

## R20 - Keyword Navigation Block - MANDATORY
Must appear within 30 lines after frontmatter closes:
```markdown
## Keywords in This File

{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 1 | [Name](#anchor) | critical |
```
- `{: .no_toc }` on next line after `## Keywords in This File`
- Skips index.md files only

---

## R21 - All 10 Sections Required Per Keyword - CRITICAL
The validator detects ALL `# H1` headings in body as keyword boundaries.
Every keyword block MUST contain ALL 10 section headers:

| Section | Header Pattern | OMIT allowed? |
|---|---|---|
| Model Answer | `### 🎯 Model Answer` | Never |
| Concept Explanation | `### 📘 Concept Explanation` | Never |
| Code Example | `### 💻 Code Example` | Yes - explicit note required |
| Answers by Seniority | `### 🎓 Answers by Seniority` | Never |
| Common Misconceptions | `### ⚠️ Common Misconceptions` | Never |
| Failure Modes | `### 🚨 Failure Modes` | Never |
| Interview Deep-Dive | `### 🎯 Interview Deep-Dive` | Never |
| Comparison Table | `### ⚖️ Comparison` | Yes - explicit note required |
| System Design | `### 🏛️ System Design` | Yes - explicit note required |
| Diagram | `### 📊 Diagram` | Yes - explicit note required |

OMIT note format: `*(Omit: reason)*` must appear under the section header.

**CRITICAL**: The validator sees ALL H1s as keyword boundaries:
- Do NOT add a spurious `# File Title` H1 after frontmatter
- Do NOT add `# Keyword Name` before the actual keyword block with a
  secondary frontmatter block under it
- The FIRST content after `## Keywords...` nav block should be `# Keyword Name`

---

## R22 - render_with_liquid: false
- Required in every content file frontmatter (not index.md)

---

## R23 - No Duplicate YAML Keys
- No duplicate keys in frontmatter block

---

## R24 - parent: must match index.md title: exactly
- parent: "Data Structures" must match index.md `title: "Data Structures"`

---

## R26 - Required Frontmatter Fields
Content files need: `layout`, `title`, `parent`, `nav_order`, `permalink`, `render_with_liquid`
Topic index.md needs: `title`, `nav_order`, `has_children`
Topic index.md MUST NOT have: `parent`, `layout`, `permalink`

---

## R28 - Liquid Raw Protection
- Code blocks with `{{ }}` or `{% %}` must be wrapped:
```
{% raw %}
```java
{{ someTemplate }}
```
{% endraw %}
```
- `{% raw %}` on line BEFORE opening ``` fence
- `{% endraw %}` on line AFTER closing ``` fence

---

## Correct Keyword H1 Format
```markdown
# Keyword Name
```
- NO emoji prefix (no 🌱, ★, etc.)
- NO ID prefix (no DS-001, etc.)
- NO em dash (no `—`)
- Plain text only: `# What Are Data Structures and Why They Matter`

## Correct Frontmatter Structure (no second frontmatter block)
```markdown
---
layout: default
title: "Topic - Subtopic"
parent: "Topic Name"
nav_order: 1
permalink: /topic/subtopic/
render_with_liquid: false
---

## Keywords in This File

{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 1 | [Keyword](#anchor) | critical |

---

# Keyword Name
```
- No second `---...---` YAML block in content body
- No id:, category:, asked_at:, seniority:, tags:, status: fields in content

## R12 Q&A Block Format
```markdown
**[JUNIOR] Q1 - What is X?**

[Question answer here 200-500 words]

*What separates good from great:* ...

---

**[MID] Q2 - How does Y work?**
```
- Line starts with `**[LEVEL]` (no leading whitespace)
- LEVEL must be: JUNIOR, MID, SENIOR, or STAFF
