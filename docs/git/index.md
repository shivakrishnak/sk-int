---
title: "Git"
nav_order: 20
has_children: true
---

# Git

Interview-focused reference for Git version control.
Zero to mastery: from basic commits and branching to rebasing strategies,
monorepo workflows, and internal object model.
Covers all seniority levels from junior to staff/principal.

{: .note }
Every entry follows the **Interview Mastery Dictionary v1.0** Option C
format: Model Answer, Concept Explanation, Code Example, Answers by
Seniority, Common Misconceptions, Failure Modes, Interview Deep-Dive.

## Files

| nav_order | File | Level | Difficulty | Keywords | Status |
|-----------|------|-------|------------|----------|--------|
| 1 | Git - L0 Orientation.md | L0 | ★☆☆ | 3 | complete |
| 2 | Git - L1 Core Operations.md | L1 | ★☆☆ | 3 | complete |
| 3 | Git - L1 Collaboration.md | L1 | ★☆☆ | 3 | complete |
| 4 | Git - L2 History Rewriting.md | L2 | ★★☆ | 2 | complete |
| 5 | Git - L2 Branching Strategies.md | L2 | ★★☆ | 2 | complete |
| 6 | Git - L3 Debugging and Recovery.md | L3 | ★★☆ | 2 | complete |
| 7 | Git - L3 Hooks and Automation.md | L3 | ★★☆ | 2 | complete |
| 8 | Git - L3 Advanced Workflows.md | L3 | ★★☆ | 2 | complete |
| 9 | Git - L4 Internals.md | L4 | ★★★ | 1 | complete |
| 10 | Git - L4 Performance.md | L4 | ★★★ | 1 | complete |
| 11 | Git - L4 Packfiles.md | L4 | ★★★ | 1 | complete |
| 12 | Git - L4 Submodules.md | L4 | ★★★ | 1 | complete |
| 13 | Git - L5 Release Engineering.md | L5 | ★★★ | 1 | complete |
| 14 | Git - L5 Large Scale.md | L5 | ★★★ | 1 | complete |
| 15 | Git - L6 Theory.md | L6 | ★★☆ | 2 | complete |
| 16 | Git - META Patterns.md | META | ★☆☆ | 3 | complete |

**Total: 16 files, 30 keywords**

---

## Keyword Registry

### File 1 - L0 Orientation (nav_order 1)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | What Is Version Control and Why Git Won | ★☆☆ | draft |
| 2 | Git Mental Model: Content-Addressable Storage | ★☆☆ | draft |
| 3 | Git Ecosystem and Workflow Overview | ★☆☆ | draft |

### File 2 - L1 Core Operations (nav_order 2)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 4 | Commits, Staging Area, and Working Tree | ★☆☆ | draft |
| 5 | Branches and HEAD | ★☆☆ | draft |
| 6 | Remote Repositories: Push, Pull, and Fetch | ★☆☆ | draft |

### File 3 - L1 Collaboration (nav_order 3)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 7 | Merging Strategies: Fast-Forward vs Merge Commit | ★☆☆ | draft |
| 8 | Conflict Resolution | ★☆☆ | draft |
| 9 | .gitignore and .gitattributes | ★☆☆ | draft |

### File 4 - L2 History Rewriting (nav_order 4)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 10 | Rebasing and Interactive Rebase | ★★☆ | draft |
| 11 | Cherry-pick and Stash | ★★☆ | draft |

### File 5 - L2 Branching Strategies (nav_order 5)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 12 | GitFlow vs Trunk-Based Development | ★★☆ | draft |
| 13 | Feature Flags and Branch Lifetime | ★★☆ | draft |

### File 6 - L3 Debugging and Recovery (nav_order 6)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 14 | Git Bisect and Blame for Bug Diagnosis | ★★☆ | draft |
| 15 | Reflog and Disaster Recovery | ★★☆ | draft |

### File 7 - L3 Hooks and Automation (nav_order 7)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 16 | Git Hooks and Pre-commit Workflows | ★★☆ | draft |
| 17 | Signed Commits and Supply Chain Security | ★★☆ | draft |

### File 8 - L3 Advanced Workflows (nav_order 8)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 18 | Monorepo Strategies with Git | ★★☆ | draft |
| 19 | Git Anti-patterns and Common Team Failures | ★★☆ | draft |

### File 9 - L4 Internals (nav_order 9)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 20 | Git Object Model: Blobs, Trees, Commits, and Tags | ★★★ | draft |

### File 10 - L4 Performance (nav_order 10)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 21 | Git at Scale: Shallow Clones, Sparse Checkout, Partial Clone | ★★★ | draft |

### File 11 - L4 Packfiles (nav_order 11)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 22 | Git Packfiles, Delta Compression, and GC | ★★★ | draft |

### File 12 - L4 Submodules (nav_order 12)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 23 | Git Submodules and Subtrees: When and Why | ★★★ | draft |

### File 13 - L5 Release Engineering (nav_order 13)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 24 | Release Engineering and Git Workflow Architecture | ★★★ | draft |

### File 14 - L5 Large Scale (nav_order 14)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 25 | Large-Scale Git: Microsoft VFS, Meta Sapling | ★★★ | draft |

### File 15 - L6 Theory (nav_order 15)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 26 | DAG Theory and Content-Addressable Storage | ★★☆ | draft |
| 27 | Merkle Trees in Version Control Systems | ★★☆ | draft |

### File 16 - META Patterns (nav_order 16)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 28 | Collaboration Patterns and Code Review Workflows | ★☆☆ | draft |
| 29 | Git Decision Framework: When to Rebase vs Merge | ★☆☆ | draft |
| 30 | Version Control Mental Models | ★☆☆ | draft |
