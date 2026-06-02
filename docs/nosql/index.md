---
title: "NoSQL"
nav_order: 31
has_children: true
---

# NoSQL

Interview-focused reference for NoSQL databases and polyglot persistence.
Zero to mastery: from document stores and key-value basics to
distributed consistency, data modeling patterns, and production tuning.
Covers all seniority levels from junior to staff/principal.

{: .note }
Every entry follows the **Interview Mastery Dictionary v1.0** Option C
format: Model Answer, Concept Explanation, Code Example, Answers by
Seniority, Common Misconceptions, Failure Modes, Interview Deep-Dive.

## Files

| nav_order | File | Level | Difficulty | Keywords | Status |
|-----------|------|-------|------------|----------|--------|
| 1 | NoSQL - L0 Orientation.md | L0 | ★☆☆ | 3 | complete |
| 2 | NoSQL - L1 Key-Value Stores.md | L1 | ★☆☆ | 3 | complete |
| 3 | NoSQL - L1 Document Stores.md | L1 | ★☆☆ | 3 | complete |
| 4 | NoSQL - L2 Advanced MongoDB.md | L2 | ★★☆ | 2 | complete |
| 5 | NoSQL - L2 Column Family Stores.md | L2 | ★★☆ | 2 | complete |
| 6 | NoSQL - L3 Data Modeling.md | L3 | ★★☆ | 2 | complete |
| 7 | NoSQL - L3 Advanced Redis.md | L3 | ★★☆ | 2 | complete |
| 8 | NoSQL - L3 Design Decisions.md | L3 | ★★☆ | 2 | complete |
| 9 | NoSQL - L4 LSM Tree Internals.md | L4 | ★★★ | 1 | complete |
| 10 | NoSQL - L4 Hot Partitions.md | L4 | ★★★ | 1 | complete |
| 11 | NoSQL - L4 Redis Production.md | L4 | ★★★ | 1 | complete |
| 12 | NoSQL - L4 Cassandra Production.md | L4 | ★★★ | 1 | complete |
| 13 | NoSQL - L5 Architecture.md | L5 | ★★★ | 1 | complete |
| 14 | NoSQL - L5 Migration.md | L5 | ★★★ | 1 | complete |
| 15 | NoSQL - L6 Theory.md | L6 | ★★☆ | 2 | complete |
| 16 | NoSQL - META Patterns.md | META | ★☆☆ | 3 | complete |

**Total: 16 files, 30 keywords**

---

## Keyword Registry

### File 1 - L0 Orientation (nav_order 1)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | SQL vs NoSQL: When and Why | ★☆☆ | draft |
| 2 | NoSQL Database Categories | ★☆☆ | draft |
| 3 | CAP Theorem Applied to NoSQL | ★☆☆ | draft |

### File 2 - L1 Key-Value Stores (nav_order 2)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 4 | Redis Data Structures and Commands | ★☆☆ | draft |
| 5 | Redis Caching Patterns | ★☆☆ | draft |
| 6 | Key-Value Store Design Patterns | ★☆☆ | draft |

### File 3 - L1 Document Stores (nav_order 3)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 7 | MongoDB: Documents, Collections, and CRUD | ★☆☆ | draft |
| 8 | MongoDB Indexing Fundamentals | ★☆☆ | draft |
| 9 | Schema Design in Document Databases | ★☆☆ | draft |

### File 4 - L2 Advanced MongoDB (nav_order 4)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 10 | MongoDB Aggregation Pipeline | ★★☆ | draft |
| 11 | MongoDB Replication and Replica Sets | ★★☆ | draft |

### File 5 - L2 Column Family Stores (nav_order 5)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 12 | Cassandra Data Model and Partition Keys | ★★☆ | draft |
| 13 | DynamoDB: Tables, Indexes, and Capacity Modes | ★★☆ | draft |

### File 6 - L3 Data Modeling (nav_order 6)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 14 | NoSQL Data Modeling Patterns and Denormalization | ★★☆ | draft |
| 15 | Consistency Levels in Distributed NoSQL | ★★☆ | draft |

### File 7 - L3 Advanced Redis (nav_order 7)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 16 | Redis Persistence: RDB vs AOF | ★★☆ | draft |
| 17 | Redis Cluster and High Availability | ★★☆ | draft |

### File 8 - L3 Design Decisions (nav_order 8)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 18 | NoSQL Anti-patterns and Misuse | ★★☆ | draft |
| 19 | Polyglot Persistence Decision Framework | ★★☆ | draft |

### File 9 - L4 LSM Tree Internals (nav_order 9)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 20 | LSM Tree Internals and Compaction | ★★★ | draft |

### File 10 - L4 Hot Partitions (nav_order 10)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 21 | Hot Partition Diagnosis and Mitigation | ★★★ | draft |

### File 11 - L4 Redis Production (nav_order 11)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 22 | Redis Production Patterns: Eviction, Memory, and Failures | ★★★ | draft |

### File 12 - L4 Cassandra Production (nav_order 12)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 23 | Cassandra Production Tuning and Tombstone Management | ★★★ | draft |

### File 13 - L5 Architecture (nav_order 13)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 24 | Polyglot Persistence Architecture | ★★★ | draft |

### File 14 - L5 Migration (nav_order 14)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 25 | NoSQL Migration Strategies from Relational Databases | ★★★ | draft |

### File 15 - L6 Theory (nav_order 15)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 26 | Dynamo Paper: Eventual Consistency and Gossip Protocols | ★★☆ | draft |
| 27 | PACELC Theorem and Consistency-Latency Trade-offs | ★★☆ | draft |

### File 16 - META Patterns (nav_order 16)

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 28 | Database Selection Framework | ★☆☆ | draft |
| 29 | NoSQL Mental Models | ★☆☆ | draft |
| 30 | Trade-off Reasoning for Data Storage | ★☆☆ | draft |

