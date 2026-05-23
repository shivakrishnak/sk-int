# Specifications — Contributor & Agent Reference

This folder is the authoritative source for the **Technical Interview Mastery** content model, keyword taxonomy, and topic registry. It is **excluded from the published site** (`exclude_docs` in `mkdocs.yml`) — for contributors, agents, and automation only.

---

## Spec Files

| File                                                             | Purpose                                                                                                                                                            |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| [interview_content_generator.md](interview_content_generator.md) | Master generation spec — 9 sections per keyword (4.1–4.10, 5 mandatory + 4 conditional), seniority calibration, spoken answer templates, self-validation checklist |
| [topics_generator.md](topics_generator.md)                       | Category keyword list generator — 37 rules, 33 checks, 9 knowledge levels (PRE, L0–L6, META), 5 invocation modes                                                   |
| [topics_registry.md](topics_registry.md)                         | Topic-to-folder mapping, level-coverage rubric, file organisation rules, Java/Java Concurrency planning references                                                 |
| [README.md](README.md)                                           | This file                                                                                                                                                          |

---

## How the System Works

```
topics_generator.md          interview_content_generator.md        docs/
─────────────────────   →    ──────────────────────────────   →    ──────
Keyword list per level       9-section entry per keyword            Published site
(PRE, L0–L6, META)           (5 mandatory + 4 conditional)          (MkDocs Material)
```

**Step 1** — Generate keyword list using `topics_generator.md`
**Step 2** — Generate entry content using `interview_content_generator.md`
**Step 3** — Practice using the entry's Questions & Spoken Answers (4.6), Field Q&A (4.8), and Diagram (4.10) sections

---

## How to Use These Prompts

### Step 1 — Get a keyword list (`topics_generator.md`)

Paste the spec into an AI assistant and use one of the five invocation modes:

| Mode          | When to Use                          | Input                                              |
| ------------- | ------------------------------------ | -------------------------------------------------- |
| `REGISTRY`    | New or extended topic — all levels   | `category:`, `code:`, `tier:`                      |
| `AD-HOC`      | Fill a specific level gap            | `category:`, `level:`, `existing: [IDs]`           |
| `DESCRIPTION` | Describe a topic, system plans it    | Free-text description                              |
| `SCAN`        | Audit existing keyword list for gaps | Paste current keyword list                         |
| `ROADMAP`     | Time-boxed interview prep plan       | `role:`, `time:`, `weakness:`, `target:`, `level:` |

**Invocation format (REGISTRY mode):**

```
Generate complete keyword list:
  category: Java Concurrency
  code:      JCO
  tier:      tier-3-java
  folder:    JCO-java-concurrency
  mode:      REGISTRY

Apply all 37 rules. Use all 14 output components.
```

### Step 2 — Generate entry content (`interview_content_generator.md`)

Paste the spec and invoke per keyword or in batches:

```
Generate technical interview entry for:
  ID:               JCO-014
  Keyword:          ReentrantLock
  Category:         Java Concurrency
  Difficulty:       ★★★
  Interview Weight: high
  Asked At:         FAANG, Mid-size
  Seniority:        senior, staff
```

Each entry follows the 9-section structure (4.1–4.10). Output to `docs/{topic-name}/{Topic} - L{N} {Subtopic}.md`.

### Step 3 — Practice the entry

Use the entry's own sections:

- **Section 4.6** (Questions & Spoken Answers) — speak the 🗣️ templates aloud, timed
- **Section 4.8** (Field Q&A) — simulate production failure and candidate mistake drills
- **Section 4.10** (Diagram) — draw from memory, then verify against the ASCII + Mermaid

---

## When to Read What

- **First time contributing**: start with [../CONTRIBUTING.md](../CONTRIBUTING.md), then [topics_registry.md](topics_registry.md) for the coverage map and file organisation rules.
- **Generating a new keyword**: read `interview_content_generator.md` Section 4 (9-section structure, 4.1–4.10) and Section 6 (Content Quality Rules + Self-Validation Checklist).
- **Adding a new topic category**: read `topics_generator.md` (37 rules, 9 levels) and `topics_registry.md` (level-coverage rubric, one-per-file pattern).
- **Planning interview prep**: use `topics_generator.md` ROADMAP mode with your role, time budget, and weak areas.
- **Debugging frontmatter or build errors**: read the Pre-Commit Frontmatter Verification section in `.github/agents/interview.agent.md`.

---

## Level System Quick Reference

| Level | Icon | Name          | Content Focus                             | Max Keywords/File |
| ----- | ---- | ------------- | ----------------------------------------- | ----------------- |
| PRE   | 🔑   | Prerequisites | Dependency map — prior knowledge required | 5 concepts        |
| L0    | 🌱   | Orientation   | Why it exists, ecosystem position         | 10                |
| L1    | ★☆☆  | Foundational  | Core vocabulary, building blocks          | 10                |
| L2    | ★★☆  | Working       | Common patterns, daily usage              | 7                 |
| L3    | ★★☆+ | Intermediate  | Design decisions, trade-offs              | 7                 |
| L4    | ★★★  | Expert        | Production diagnostics, failure modes     | 5                 |
| L5    | 🔥   | Architect     | Strategy, migration, at-scale governance  | 5                 |
| L6    | 🔬   | Creator       | Theory, specification, research           | 3                 |
| META  | 🧠   | Meta-Skills   | Transferable cross-domain thinking        | 5                 |

**File organisation rule:** one level per file, always. Never mix levels in a single file.

**File naming:** `{Topic} - L{N} {Subtopic}.md` → e.g., `Java - L3 Concurrency.md`
**Base path:** `docs/{topic-name}/` (lowercase, hyphens)

---

## Adding a New Topic

1. Check `topics_registry.md` — is the topic already planned?
2. Run `topics_generator.md` in REGISTRY mode to generate the keyword list (PRE through L6 + META).
3. Create stub files: one file per level, placed in `docs/{topic-name}/`. Use the level-per-file naming pattern. Respect content-capacity limits per level.
4. Generate full entries (9-section structure) using `interview_content_generator.md` for each keyword stub.
5. Update `spec/topics_registry.md` with the new category, its code, tier, and file plan.
6. Update `docs/index.md` and the tier `index.md` to add navigation links.

---

## Versioning

`SPEC_VERSION = 1`, `SPEC_LABEL = v1.0`.
Bump only after consensus and a migration plan for existing content.
Update **only the Version Registry block** at the top of each spec file — all prose uses the constants.
