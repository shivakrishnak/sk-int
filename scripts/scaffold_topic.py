#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
scaffold_topic.py
=================
Pre-generates scaffold interview content files with [FILL:...] stubs.

Each scaffold has:
  - Correct YAML frontmatter
  - All 19 required sections per keyword with [FILL:...] stubs
  - Proper --- separators between keywords and sections
  - Keyword TOC at top of file

The AI only needs to replace [FILL:...] stubs with actual content.
Reduces AI output by ~50% and eliminates structural errors.

Usage:
  python scripts/scaffold_topic.py <topic-folder>
  python scripts/scaffold_topic.py java
  python scripts/scaffold_topic.py java-concurrency
  python scripts/scaffold_topic.py hibernate
  python scripts/scaffold_topic.py --file "java/Java - Basics.md"

Reads existing stub files, extracts keywords from frontmatter,
generates full scaffold structure for each keyword.
"""

import os
import re
import sys
from pathlib import Path

# Resolve repo root from this file's location (scripts/scaffold_topic.py -> repo root).
BASE = Path(__file__).resolve().parent.parent
DOCS_BASE = BASE / "docs"


def read_frontmatter(path: Path) -> dict:
    """Extract YAML frontmatter fields from an existing file."""
    text = path.read_text(encoding="utf-8", errors="replace")
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    fm_text = text[3:end]
    fields = {}
    keywords = []
    in_keywords = False
    for line in fm_text.splitlines():
        if re.match(r"^keywords:", line):
            in_keywords = True
            continue
        if in_keywords:
            m = re.match(r"^\s+-\s+(.+)", line)
            if m:
                keywords.append(m.group(1).strip())
            else:
                in_keywords = False
        m = re.match(r"^(\w[\w_]*):\s*(.*)$", line)
        if m and not in_keywords:
            fields[m.group(1)] = m.group(2).strip().strip('"\'')
    if keywords:
        fields["_keywords"] = keywords
    return fields


def keyword_to_anchor(kw: str) -> str:
    """Convert keyword to markdown anchor."""
    anchor = kw.lower()
    anchor = re.sub(r"[()&/,]", "", anchor)
    anchor = re.sub(r"[^a-z0-9\s-]", "", anchor)
    anchor = re.sub(r"\s+", "-", anchor.strip())
    return re.sub(r"-+", "-", anchor).strip("-")


def build_keyword_scaffold(keyword: str, difficulty: str = "mixed") -> str:
    """Build scaffold for a single keyword within an interview file."""
    kw_upper = keyword.upper()

    return f"""# {keyword}

**TL;DR** - [FILL: one sentence, max 25 words. What + why, zero jargon.]

---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
[FILL: 2-4 sentences. Concrete scenario showing the pain.]

**THE BREAKING POINT:**
[FILL: 1-2 sentences. What crashes/slows/breaks.]

**THE INVENTION MOMENT:**
"This is exactly why {keyword} was created."

**EVOLUTION:**
[FILL: 2-3 sentences. predecessor -> current -> future direction]

---

### 📘 Textbook Definition

[FILL: 2-4 sentences. Formal, precise, technically complete. Bold **{keyword}** on first mention.]

---

### ⏱️ Understand It in 30 Seconds

**One line:** [FILL: max 15 words, zero jargon]

**One analogy:**
> [FILL: 2-3 sentence real-world analogy]

**One insight:** [FILL: what separates knowing the name from understanding it. 2-3 sentences.]

---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [FILL: always true about this concept]
2. [FILL: always true about this concept]
3. [FILL: always true about this concept]

**DERIVED DESIGN:**
[FILL: how invariants force the design. 2-4 sentences.]

**THE TRADE-OFFS:**
**Gain:** [FILL: what you get]
**Cost:** [FILL: what you sacrifice]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [FILL: inherent to the problem]
**Accidental:** [FILL: from current tooling/ecosystem]

---

### 🧠 Mental Model / Analogy

> [FILL: primary analogy in blockquote. Concrete everyday object/process.]

- "[FILL: analogy element]" -> [technical element]
- "[FILL: analogy element]" -> [technical element]
- "[FILL: analogy element]" -> [technical element]

Where this analogy breaks down: [FILL: 1 sentence]

---

### 📶 Gradual Depth - Five Levels

**Level 1 - What it is (anyone can understand):**
[FILL: plain English, no jargon, 2-4 sentences]

**Level 2 - How to use it (junior developer):**
[FILL: basic usage, common patterns. 3-5 sentences + code if applicable]

**Level 3 - How it works (mid-level engineer):**
[FILL: internals, data structures, algorithms. 4-6 sentences]

**Level 4 - Production mastery (senior/staff engineer):**
[FILL: design decisions, edge cases, cross-system reasoning. 5-8 sentences]

**The Senior-to-Staff Leap:**
A Senior says: "[FILL: correct but conventional understanding]"
A Staff says: "[FILL: next-level abstraction or cross-system insight]"
The difference: [FILL: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[FILL: cross-domain pattern recognition, what would you redesign, expert heuristics. 3-5 sentences]

---

### ⚙️ How It Works

[FILL: step-by-step technical walkthrough. Include ASCII diagram if 3+ steps. Max 59 chars wide.]

---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[FILL: ASCII flow diagram. Mark THIS concept with <- YOU ARE HERE. Max 59 chars wide.]

**FAILURE PATH:**
[FILL: cascade when this fails -> observable symptom]

**WHAT CHANGES AT SCALE:**
[FILL: 2-3 sentences on behavior at 10x/100x/1000x load]

---

### 💻 Code Example

**BAD - [FILL: antipattern name]:**
```java
// BAD: [FILL: why this fails]
[FILL: code, max 70 chars/line]
```

**GOOD - [FILL: correct pattern name]:**
```java
// GOOD: [FILL: why this works]
[FILL: code, max 70 chars/line]
```

**How to test / verify correctness:**
[FILL: 1-3 sentences on testing strategy]

---

### 📌 Quick Reference Card

**WHAT IT IS:** [FILL: 1 sentence]
**PROBLEM IT SOLVES:** [FILL: 1 sentence]
**KEY INSIGHT:** [FILL: 1 sentence]
**USE WHEN:** [FILL: conditions]
**AVOID WHEN:** [FILL: conditions]
**ANTI-PATTERN:** [FILL: common misuse]
**TRADE-OFF:** [FILL: gain vs cost]
**ONE-LINER:** [FILL: memorable metaphor]
**KEY NUMBERS:** [FILL: 2-3 critical thresholds/defaults]
**TRIGGER PHRASE:** [FILL: 5-7 words activating full mental model]
**OPENING SENTENCE:** [FILL: first sentence showing immediate depth]

**If you remember only 3 things:**
1. [FILL: most important insight]
2. [FILL: key trade-off or constraint]
3. [FILL: production gotcha that bites everyone]

**Interview one-liner:**
"[FILL: 30-second interview explanation showing depth]"

---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [FILL: teach to junior in 2 min without notes]
2. **DEBUG:** [FILL: diagnose specific failure from symptoms]
3. **DECIDE:** [FILL: choose this vs alternative under pressure]
4. **BUILD:** [FILL: implement/configure in production context]
5. **EXTEND:** [FILL: apply principle to different domain]

---

### 💡 The Surprising Truth

[FILL: exactly ONE counterintuitive fact. 2-4 sentences. Specific, accurate, memorable.]

---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [FILL: dangerous wrong belief] | [FILL: actual truth] |
| 2 | [FILL: wrong belief] | [FILL: actual truth] |
| 3 | [FILL: wrong belief] | [FILL: actual truth] |
| 4 | [FILL: wrong belief] | [FILL: actual truth] |

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [FILL: name]**
**Symptom:** [FILL: observable in production]
**Root Cause:** [FILL: why it happens]
**Diagnostic:**
```
[FILL: real diagnostic command]
```
**Fix:** [FILL: BAD then GOOD approach]
**Prevention:** [FILL: how to prevent]

**Failure Mode 2: [FILL: name]**
**Symptom:** [FILL]
**Root Cause:** [FILL]
**Diagnostic:**
```
[FILL: real diagnostic command]
```
**Fix:** [FILL]
**Prevention:** [FILL]

**Failure Mode 3: [FILL: name]**
**Symptom:** [FILL]
**Root Cause:** [FILL]
**Diagnostic:**
```
[FILL: real diagnostic command]
```
**Fix:** [FILL]
**Prevention:** [FILL]

---

### 🎯 Interview Deep-Dive

| Question Type | Target Duration | Signals |
|---------------|-----------------|---------|
| Conceptual | 45-90 seconds | Direct, confident |
| Debugging | 90-150 seconds | Systematic diagnosis |
| Architecture | 120-180 seconds | Trade-off exploration |
| Trade-off | 60-120 seconds | Decision framework |
| Behavioral | 60-120 seconds | Clear STAR structure |

**Q1 [JUNIOR]: [FILL: scenario-based conceptual question]**

*Why they ask:* [FILL: what skill this probes]
*Likely follow-up:* [FILL: what they ask next]

**Answer:**
[FILL: complete structured answer. 200-500 words. Include code/diagrams as needed.]

*What separates good from great:* [FILL: 1 sentence]

---

**Q2 [MID]: [FILL: debugging or trade-off question]**

*Why they ask:* [FILL]
*Likely follow-up:* [FILL]

**Answer:**
[FILL: complete answer with production depth]

*What separates good from great:* [FILL]

---

**Q3 [SENIOR]: [FILL: architecture or production question]**

*Why they ask:* [FILL]
*Likely follow-up:* [FILL]

**Answer:**
[FILL: complete answer demonstrating system-level thinking]

*What separates good from great:* [FILL]

---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [FILL: keyword] - [why needed]
- [FILL: keyword] - [why needed]

**Builds on this (learn these next):**
- [FILL: keyword] - [what it adds]
- [FILL: keyword] - [what it adds]

**Alternatives / Comparisons:**
- [FILL: keyword] - [when to prefer]"""


def build_file_scaffold(file_path: Path, fm: dict) -> str:
    """Build complete scaffold for an interview sub-topic file."""
    title = fm.get("title", file_path.stem)
    topic = fm.get("topic", "Unknown")
    subtopic = fm.get("subtopic", "Unknown")
    keywords = fm.get("_keywords", [])
    difficulty = fm.get("difficulty_range", "mixed")
    version = 1  # target version (SPEC_VERSION = 1, v1.0)

    # Build YAML
    kw_yaml = "\n".join(f"  - {kw}" for kw in keywords)

    # Build TOC
    toc = "\n".join(
        f"- [{kw}](#{keyword_to_anchor(kw)})" for kw in keywords
    )

    # Build keyword sections
    kw_sections = []
    for i, kw in enumerate(keywords):
        kw_sections.append(build_keyword_scaffold(kw, difficulty))
        if i < len(keywords) - 1:
            kw_sections.append("\n---\n\n---\n")

    all_keywords = "\n".join(kw_sections)

    return f"""---
title: "{title}"
topic: {topic}
subtopic: {subtopic}
keywords:
{kw_yaml}
difficulty_range: {difficulty}
status: in-progress
version: {version}
---

**Keywords covered in this file:**

{toc}

{all_keywords}
"""


def process_file(file_path: Path) -> None:
    """Process a single interview file - read frontmatter, generate scaffold."""
    fm = read_frontmatter(file_path)
    keywords = fm.get("_keywords", [])

    if not keywords:
        print(f"  SKIP: {file_path.name} - no keywords in frontmatter")
        return

    content = build_file_scaffold(file_path, fm)

    # Write UTF-8 no BOM
    file_path.write_text(content, encoding="utf-8")

    fill_count = content.count("[FILL:")
    print(f"  OK: {file_path.name} - {len(keywords)} keywords, "
          f"{fill_count} [FILL:] stubs, {len(content)} bytes")


def process_topic(topic_folder: str) -> None:
    """Process all files in a topic folder."""
    topic_dir = DOCS_BASE / topic_folder
    if not topic_dir.is_dir():
        print(f"ERROR: folder not found: {topic_dir}")
        sys.exit(1)

    md_files = sorted([
        f for f in topic_dir.glob("*.md")
        if f.name != "index.md"
    ])

    if not md_files:
        print(f"ERROR: no .md files found in {topic_dir}")
        sys.exit(1)

    print(f"\n{'='*60}")
    print(f"INTERVIEW SCAFFOLD: {topic_folder}")
    print(f"Files: {len(md_files)}")
    print(f"{'='*60}\n")

    total_keywords = 0
    total_fills = 0

    for f in md_files:
        fm = read_frontmatter(f)
        kw_count = len(fm.get("_keywords", []))
        process_file(f)
        total_keywords += kw_count

    print(f"\n{'='*60}")
    print(f"DONE: {len(md_files)} files, {total_keywords} keywords scaffolded")
    print(f"{'='*60}\n")


def main():
    if len(sys.argv) < 2:
        print("Usage:")
        print("  python scripts/scaffold_topic.py <topic-folder>")
        print("  python scripts/scaffold_topic.py java")
        print("  python scripts/scaffold_topic.py --file \"java/Java - Basics.md\"")
        sys.exit(1)

    if sys.argv[1] == "--file":
        if len(sys.argv) < 3:
            print("ERROR: --file requires a path argument")
            sys.exit(1)
        file_path = DOCS_BASE / sys.argv[2]
        if not file_path.exists():
            print(f"ERROR: file not found: {file_path}")
            sys.exit(1)
        process_file(file_path)
    else:
        process_topic(sys.argv[1])


if __name__ == "__main__":
    main()
