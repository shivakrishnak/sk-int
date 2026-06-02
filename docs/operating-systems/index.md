---
title: "Operating Systems"
nav_order: 3
has_children: true
---

# Operating Systems

Interview-focused reference for operating systems concepts.
Zero to mastery: from processes and threads to virtual memory,
file systems, scheduling algorithms, and kernel internals.
Covers all seniority levels from junior to staff/principal.

{: .note }
Every entry follows the **Interview Mastery Dictionary v1.0** Option C
format: Model Answer, Concept Explanation, Code Example, Answers by
Seniority, Common Misconceptions, Failure Modes, Interview Deep-Dive.

## Files

| nav_order | File | Level | Difficulty | Keywords | Status |
|-----------|------|-------|------------|----------|--------|
| 1 | Operating Systems - L0 Orientation.md | L0 | ★☆☆ | 3 | complete |
| 2 | Operating Systems - L1 Processes.md | L1 | ★☆☆ | 3 | complete |
| 3 | Operating Systems - L1 Memory.md | L1 | ★☆☆ | 3 | complete |
| 4 | Operating Systems - L2 Scheduling.md | L2 | ★★☆ | 2 | complete |
| 5 | Operating Systems - L2 Synchronization.md | L2 | ★★☆ | 2 | complete |
| 6 | Operating Systems - L3 IPC.md | L3 | ★★☆ | 2 | complete |
| 7 | Operating Systems - L3 File Systems.md | L3 | ★★☆ | 2 | pending |
| 8 | Operating Systems - L3 Advanced Memory.md | L3 | ★★☆ | 2 | pending |
| 9 | Operating Systems - L3 Security.md | L3 | ★★☆ | 2 | pending |
| 10 | Operating Systems - L4 Virtualization.md | L4 | ★★★ | 1 | pending |
| 11 | Operating Systems - L4 IO Models.md | L4 | ★★★ | 1 | pending |
| 12 | Operating Systems - L4 TLB and MMU.md | L4 | ★★★ | 1 | complete |
| 13 | Operating Systems - L4 Signals.md | L4 | ★★★ | 1 | complete |
| 14 | Operating Systems - L5 Architecture.md | L5 | ★★★ | 1 | complete |
| 15 | Operating Systems - L6 Theory.md | L6 | ★★☆ | 2 | complete |
| 16 | Operating Systems - META Patterns.md | META | ★☆☆ | 3 | complete |

**Total: 16 files, 31 keywords**

---

## Keyword Registry

### File 1 - L0 Orientation (nav_order 1)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | What an Operating System Does | ★☆☆ | draft |
| 2 | Kernel vs Userspace and System Calls | ★☆☆ | draft |
| 3 | OS Design Philosophies and History | ★☆☆ | draft |

### File 2 - L1 Processes (nav_order 2)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 4 | Process Model and Lifecycle | ★☆☆ | draft |
| 5 | Process vs Thread | ★☆☆ | draft |
| 6 | Context Switching | ★☆☆ | draft |

### File 3 - L1 Memory (nav_order 3)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 7 | Memory Hierarchy and Locality | ★☆☆ | draft |
| 8 | Virtual Memory and Address Spaces | ★☆☆ | draft |
| 9 | Paging and Page Tables | ★☆☆ | draft |

### File 4 - L2 Scheduling (nav_order 4)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 10 | CPU Scheduling Algorithms | ★★☆ | draft |
| 11 | Preemption and Priority Inversion | ★★☆ | draft |

### File 5 - L2 Synchronization (nav_order 5)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 12 | Mutex, Semaphore, and Condition Variables | ★★☆ | draft |
| 13 | Deadlock: Detection, Prevention, and Avoidance | ★★☆ | draft |

### File 6 - L3 IPC (nav_order 6)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 14 | Inter-Process Communication Mechanisms | ★★☆ | draft |
| 15 | Pipes, Sockets, and Shared Memory | ★★☆ | draft |

### File 7 - L3 File Systems (nav_order 7)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 16 | File System Design and Inodes | ★★☆ | pending |
| 17 | Journaling and Crash Consistency | ★★☆ | pending |

### File 8 - L3 Advanced Memory (nav_order 8)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 18 | Page Replacement Algorithms | ★★☆ | pending |
| 19 | Memory-Mapped Files and Zero-Copy | ★★☆ | pending |

### File 9 - L3 Security (nav_order 9)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 20 | OS Security Model and Privilege Escalation | ★★☆ | pending |
| 21 | OS Anti-patterns: Resource Leaks and Race Conditions | ★★☆ | pending |

### File 10 - L4 Virtualization (nav_order 10)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 22 | Container Isolation: Namespaces and Cgroups | ★★★ | pending |

### File 11 - L4 IO Models (nav_order 11)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 23 | I/O Models: Blocking, Non-blocking, Async, and epoll | ★★★ | pending |

### File 12 - L4 TLB and MMU (nav_order 12)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 24 | TLB and Memory Management Unit Internals | ★★★ | draft |

### File 13 - L4 Signals (nav_order 13)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 25 | Signals, Interrupts, and Exception Handling | ★★★ | draft |

### File 14 - L5 Architecture (nav_order 14)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 26 | OS-Level Performance Tuning for Production Systems | ★★★ | draft |

### File 15 - L6 Theory (nav_order 15)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 27 | Microkernel vs Monolithic Architecture Trade-offs | ★★☆ | draft |
| 28 | Formal Verification and OS Correctness | ★★☆ | draft |

### File 16 - META Patterns (nav_order 16)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 29 | Systems Thinking Mental Models | ★☆☆ | draft |
| 30 | Resource Management Patterns | ★☆☆ | draft |
| 31 | Debugging OS-Level Issues | ★☆☆ | draft |
