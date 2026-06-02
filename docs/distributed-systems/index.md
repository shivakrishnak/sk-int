---
title: "Distributed Systems"
nav_order: 63
has_children: true
---

# Distributed Systems

Interview-focused reference for distributed systems concepts.
Zero to mastery: from "what is a distributed system" to Raft consensus,
CRDTs, global-scale design, and the FLP impossibility theorem.
Covers all seniority levels from junior to staff/principal.

{: .note }
Every entry follows the **Interview Mastery Dictionary v1.0** Option C
format: Model Answer, Concept Explanation, Code Example, Answers by
Seniority, Common Misconceptions, Failure Modes, Interview Deep-Dive.

## Files

| nav_order | File | Level | Difficulty | Keywords | Status |
|-----------|------|-------|------------|----------|--------|
| 1 | Distributed Systems - L0 Orientation.md | L0 | ★☆☆ | 3 | complete |
| 2 | Distributed Systems - L1 Core Concepts.md | L1 | ★☆☆ | 3 | complete |
| 3 | Distributed Systems - L1 Clocks and Ordering.md | L1 | ★☆☆ | 3 | complete |
| 4 | Distributed Systems - L2 Replication and Sharding.md | L2 | ★★☆ | 2 | complete |
| 5 | Distributed Systems - L2 Communication Patterns.md | L2 | ★★☆ | 2 | complete |
| 6 | Distributed Systems - L2 Coordination Basics.md | L2 | ★★☆ | 2 | complete |
| 7 | Distributed Systems - L3 Consistency Patterns.md | L3 | ★★☆ | 2 | complete |
| 8 | Distributed Systems - L3 Transactions.md | L3 | ★★☆ | 2 | complete |
| 9 | Distributed Systems - L3 Resilience Patterns.md | L3 | ★★☆ | 2 | complete |
| 10 | Distributed Systems - L3 Service Architecture.md | L3 | ★★☆ | 2 | complete |
| 11 | Distributed Systems - L3 Delivery Semantics.md | L3 | ★★☆ | 2 | complete |
| 12 | Distributed Systems - L3 Security.md | L3 | ★★☆ | 2 | complete |
| 13 | Distributed Systems - L4 Raft Consensus.md | L4 | ★★★ | 1 | complete |
| 14 | Distributed Systems - L4 Paxos.md | L4 | ★★★ | 1 | complete |
| 15 | Distributed Systems - L4 CRDTs.md | L4 | ★★★ | 1 | complete |
| 16 | Distributed Systems - L4 Observability.md | L4 | ★★★ | 1 | complete |
| 17 | Distributed Systems - L4 Vector Clocks.md | L4 | ★★★ | 1 | complete |
| 18 | Distributed Systems - L4 Failure Detection.md | L4 | ★★★ | 1 | complete |
| 19 | Distributed Systems - L5 Partition Tolerance.md | L5 | ★★★ | 1 | complete |
| 20 | Distributed Systems - L5 Global Scale.md | L5 | ★★★ | 1 | complete |
| 21 | Distributed Systems - L5 Migration Strategy.md | L5 | ★★★ | 1 | complete |
| 22 | Distributed Systems - L6 Theory.md | L6 | ★★☆ | 2 | complete |
| 23 | Distributed Systems - META Patterns.md | META | ★☆☆ | 3 | complete |

**Total: 23 files, 41 keywords**

---

## Keyword Registry

### File 1 - L0 Orientation (nav_order 1)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | What Is a Distributed System | ★☆☆ | complete |
| 2 | The Eight Fallacies of Distributed Computing | ★☆☆ | complete |
| 3 | Distributed Systems Ecosystem and Landscape | ★☆☆ | complete |

### File 2 - L1 Core Concepts (nav_order 2)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 4 | CAP Theorem | ★☆☆ | complete |
| 5 | Consistency Models | ★☆☆ | complete |
| 6 | Availability and Fault Tolerance Fundamentals | ★☆☆ | complete |

### File 3 - L1 Clocks and Ordering (nav_order 3)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 7 | Logical Clocks and Lamport Timestamps | ★☆☆ | complete |
| 8 | Physical vs Logical Time in Distributed Systems | ★☆☆ | complete |
| 9 | Causality and Happens-Before Relation | ★☆☆ | complete |

### File 4 - L2 Replication and Sharding (nav_order 4)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 10 | Data Replication Strategies | ★★☆ | complete |
| 11 | Database Sharding | ★★☆ | complete |

### File 5 - L2 Communication Patterns (nav_order 5)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 12 | Remote Procedure Call and gRPC | ★★☆ | complete |
| 13 | Message Passing and Event-Driven Architecture | ★★☆ | complete |

### File 6 - L2 Coordination Basics (nav_order 6)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 14 | Leader Election | ★★☆ | complete |
| 15 | Distributed Locking | ★★☆ | complete |

### File 7 - L3 Consistency Patterns (nav_order 7)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 16 | Eventual Consistency and Convergence | ★★☆ | complete |
| 17 | Conflict Resolution Strategies | ★★☆ | complete |

### File 8 - L3 Transactions (nav_order 8)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 18 | Distributed Transactions and Two-Phase Commit | ★★☆ | complete |
| 19 | Saga Pattern | ★★☆ | complete |

### File 9 - L3 Resilience Patterns (nav_order 9)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 20 | Circuit Breaker Pattern | ★★☆ | complete |
| 21 | Distributed Monolith Anti-pattern | ★★☆ | complete |

### File 10 - L3 Service Architecture (nav_order 10)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 22 | Service Discovery | ★★☆ | complete |
| 23 | Service Mesh and Sidecar Pattern | ★★☆ | complete |

### File 11 - L3 Delivery Semantics (nav_order 11)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 24 | Idempotency in Distributed Systems | ★★☆ | complete |
| 25 | Exactly-Once Delivery Semantics | ★★☆ | complete |

### File 12 - L3 Security (nav_order 12)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 26 | mTLS and Service-to-Service Authentication | ★★☆ | complete |
| 27 | Authorization in Microservices | ★★☆ | complete |

### File 13 - L4 Raft Consensus (nav_order 13)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 28 | Raft Consensus Algorithm | ★★★ | complete |

### File 14 - L4 Paxos (nav_order 14)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 29 | Paxos Consensus Algorithm | ★★★ | complete |

### File 15 - L4 CRDTs (nav_order 15)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 30 | Conflict-free Replicated Data Types | ★★★ | complete |

### File 16 - L4 Observability (nav_order 16)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 31 | Distributed Tracing and Observability | ★★★ | complete |

### File 17 - L4 Vector Clocks (nav_order 17)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 32 | Vector Clocks and Causal Consistency | ★★★ | complete |

### File 18 - L4 Failure Detection (nav_order 18)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 33 | Failure Detection Algorithms | ★★★ | complete |

### File 19 - L5 Partition Tolerance (nav_order 19)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 34 | Designing for Network Partition Tolerance | ★★★ | complete |

### File 20 - L5 Global Scale (nav_order 20)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 35 | Global-Scale Distributed System Design | ★★★ | complete |

### File 21 - L5 Migration Strategy (nav_order 21)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 36 | Monolith to Distributed System Migration | ★★★ | complete |

### File 22 - L6 Theory (nav_order 22)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 37 | FLP Impossibility Theorem | ★★☆ | complete |
| 38 | Byzantine Fault Tolerance | ★★☆ | complete |

### File 23 - META Patterns (nav_order 23)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 39 | Resilience Mental Model | ★☆☆ | complete |
| 40 | Two Generals as Coordination Model | ★☆☆ | complete |
| 41 | DS Design Heuristics | ★☆☆ | complete |
