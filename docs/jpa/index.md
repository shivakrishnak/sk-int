---
title: "JPA"
nav_order: 12
has_children: true
---

# JPA

Java Persistence API and Hibernate: entity mapping, relationships,
JPQL, Spring Data JPA, caching, transactions, N+1 diagnosis, and
production ORM patterns.

## Files

| File | Level | Keywords | Status |
|------|-------|----------|--------|
| JPA - L0 Orientation.md | L0 | 3 | complete |
| JPA - L1 Entity Mapping.md | L1 | 3 | complete |
| JPA - L1 Queries.md | L1 | 3 | complete |
| JPA - L2 Fetch Strategies.md | L2 | 2 | complete |
| JPA - L2 Transactions.md | L2 | 2 | complete |
| JPA - L2 Performance.md | L2 | 2 | complete |
| JPA - L3 Locking.md | L3 | 2 | complete |
| JPA - L3 Caching.md | L3 | 2 | complete |
| JPA - L3 Schema.md | L3 | 2 | complete |
| JPA - L4 Internals.md | L4 | 1 | complete |
| JPA - L4 Anti-Patterns.md | L4 | 1 | complete |
| JPA - L4 Production.md | L4 | 1 | complete |
| JPA - L5 Architecture.md | L5 | 1 | complete |
| JPA - L5 Migration.md | L5 | 1 | complete |
| JPA - L6 Theory.md | L6 | 2 | complete |
| JPA - META Patterns.md | META | 3 | complete |

## Keyword Registry

### JPA - L0 Orientation.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 1 | What JPA Is and Why It Exists: ORM vs JDBC | ★☆☆ | complete |
| 2 | JPA vs Hibernate vs Spring Data JPA: The Ecosystem | ★☆☆ | complete |
| 3 | Setting Up JPA: EntityManagerFactory and Persistence Context | ★☆☆ | complete |

### JPA - L1 Entity Mapping.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 4 | Entity Basics: @Entity, @Id, @Column, and @Table | ★☆☆ | complete |
| 5 | Relationship Mappings: @OneToOne, @OneToMany, @ManyToMany | ★☆☆ | complete |
| 6 | Inheritance Mapping Strategies: TABLE_PER_CLASS, JOINED, SINGLE_TABLE | ★☆☆ | complete |

### JPA - L1 Queries.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 7 | JPQL Fundamentals: Entity Queries and Named Queries | ★☆☆ | complete |
| 8 | Criteria API Basics: Type-Safe Dynamic Queries | ★☆☆ | complete |
| 9 | Spring Data JPA: Repository and Query Method Derivation | ★☆☆ | complete |

### JPA - L2 Fetch Strategies.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 10 | Lazy vs Eager Loading: FetchType and LazyInitializationException | ★★☆ | complete |
| 11 | N+1 Problem: Detection, Diagnosis, and Fix | ★★☆ | complete |

### JPA - L2 Transactions.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 12 | JPA Transactions: @Transactional and Persistence Context Lifecycle | ★★☆ | complete |
| 13 | Entity Lifecycle: Managed, Detached, Removed, and Persist Cascades | ★★☆ | complete |

### JPA - L2 Performance.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 14 | JPA Query Performance: Named Queries, Projections, and DTO Mapping | ★★☆ | complete |
| 15 | Batch Operations: saveAll, Bulk Update/Delete with @Query | ★★☆ | complete |

### JPA - L3 Locking.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 16 | Optimistic Locking: @Version and Conflict Resolution | ★★☆ | complete |
| 17 | Pessimistic Locking: LockModeType and Deadlock Avoidance | ★★☆ | complete |

### JPA - L3 Caching.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 18 | First-Level Cache: Persistence Context as Cache | ★★☆ | complete |
| 19 | Second-Level Cache: EhCache, Caffeine, and Cache Region Strategy | ★★☆ | complete |

### JPA - L3 Schema.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 20 | Schema Generation and Database Migration: Liquibase vs Flyway with JPA | ★★☆ | complete |
| 21 | Advanced Mapping: @Embeddable, @ElementCollection, and Converter | ★★☆ | complete |

### JPA - L4 Internals.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 22 | Hibernate Session Internals: Flush Modes and Write-Behind Cache | ★★★ | complete |

### JPA - L4 Anti-Patterns.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 23 | JPA Anti-Patterns: N+1, Cartesian Product, and Cross Join at Scale | ★★★ | complete |

### JPA - L4 Production.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 24 | JPA Production Diagnostics: Query Logging, Slow Query Analysis, Connection Pool Tuning | ★★★ | complete |

### JPA - L5 Architecture.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 25 | JPA at Scale: Aggregates, Repository Pattern, and Domain Model Design | ★★★ | complete |

### JPA - L5 Migration.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 26 | JPA Migration Strategy: EclipseLink to Hibernate, Hibernate 5 to 6 | ★★★ | complete |

### JPA - L6 Theory.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 27 | JPA Specification vs Implementation: JSR 338 and Provider Contracts | ★★☆ | complete |
| 28 | Object-Relational Impedance Mismatch: Theoretical Foundations | ★★☆ | complete |

### JPA - META Patterns.md

| # | Keyword | Difficulty | Status |
|---|---------|------------|--------|
| 29 | JPA Decision Framework: When ORM Helps and When It Hurts | ★☆☆ | complete |
| 30 | Repository Pattern vs Active Record vs Service Layer | ★☆☆ | complete |
| 31 | JPA Testing Strategy: @DataJpaTest and Test Database Management | ★☆☆ | complete |
