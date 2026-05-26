---
title: "JPA"
nav_order: 8
has_children: true
---

# JPA

Java Persistence API: EntityManager, persistence context, JPQL, Criteria
API, relationships, transactions, locking, and Spring Data JPA. From
entity lifecycle to diagnosing N+1 and OSIV anti-patterns in production.

## Files

| File | Level | Keywords | Status |
| ---- | ----- | -------- | ------ |
| [JPA - L0 Orientation](JPA%20-%20L0%20Orientation.md) | L0 | 4 | complete |
| [JPA - L1 Foundations](JPA%20-%20L1%20Foundations.md) | L1 | 5 | complete |
| [JPA - L2 Relationships](JPA%20-%20L2%20Relationships.md) | L2 | 5 | complete |
| [JPA - L2 Querying](JPA%20-%20L2%20Querying.md) | L2 | 5 | complete |
| [JPA - L3 Transactions and Locking](JPA%20-%20L3%20Transactions%20and%20Locking.md) | L3 | 5 | complete |
| [JPA - L3 Spring Data JPA](JPA%20-%20L3%20Spring%20Data%20JPA.md) | L3 | 5 | complete |
| [JPA - L4 Production Depth](JPA%20-%20L4%20Production%20Depth.md) | L4 | 5 | complete |
| [JPA - L5 Architecture](JPA%20-%20L5%20Architecture.md) | L5 | 3 | complete |
| [JPA - L6 Theory](JPA%20-%20L6%20Theory.md) | L6 | 2 | complete |
| [JPA - META Patterns](JPA%20-%20META%20Patterns.md) | META | 2 | complete |

**Keywords:** 41 | **Files:** 10 | **Status:** complete

---

## Keyword Registry

### JPA - L0 Orientation

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | JPA Overview and Purpose               | ★☆☆        | draft   |
| 2   | JPA vs JDBC vs Hibernate               | ★☆☆        | draft   |
| 3   | JPA Provider Landscape                 | ★☆☆        | draft   |
| 4   | Spring Data JPA vs JPA                 | ★☆☆        | draft   |

### JPA - L1 Foundations

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | EntityManager and Persistence Context  | ★☆☆        | draft   |
| 2   | Entity Annotations @Entity @Id @Column | ★☆☆        | draft   |
| 3   | Entity Lifecycle States                | ★★☆        | draft   |
| 4   | JPQL Basics                            | ★☆☆        | draft   |
| 5   | JPA Configuration and persistence.xml  | ★★☆        | draft   |

### JPA - L2 Relationships

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | OneToMany and ManyToOne                | ★★☆        | draft   |
| 2   | ManyToMany and Join Tables             | ★★☆        | draft   |
| 3   | Fetch Types EAGER vs LAZY              | ★★☆        | draft   |
| 4   | Cascade Types and Orphan Removal       | ★★☆        | draft   |
| 5   | Embeddable and Embedded                | ★★☆        | draft   |

### JPA - L2 Querying

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | JPQL Advanced Queries                  | ★★☆        | draft   |
| 2   | JPA Criteria API                       | ★★★        | draft   |
| 3   | Named Queries                          | ★★☆        | draft   |
| 4   | Native Queries and Result Mapping      | ★★☆        | draft   |
| 5   | DTO Projections                        | ★★☆        | draft   |

### JPA - L3 Transactions and Locking

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | JPA Transaction Management             | ★★★        | draft   |
| 2   | Optimistic Locking with @Version       | ★★★        | draft   |
| 3   | Pessimistic Locking Types              | ★★★        | draft   |
| 4   | Flush Modes and Synchronization        | ★★★        | draft   |
| 5   | JPA Callbacks and Entity Listeners     | ★★☆        | draft   |

### JPA - L3 Spring Data JPA

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | Repository Interface Hierarchy         | ★★☆        | draft   |
| 2   | Query Derivation Method Naming         | ★★☆        | draft   |
| 3   | @Query and Custom JPQL                 | ★★☆        | draft   |
| 4   | Pagination and Sorting                 | ★★☆        | draft   |
| 5   | Spring Data JPA Projections            | ★★★        | draft   |

### JPA - L4 Production Depth

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | N+1 Select Anti-Pattern                | ★★★        | draft   |
| 2   | Open Session in View Anti-Pattern      | ★★★        | draft   |
| 3   | Persistence Context Size Management    | ★★★        | draft   |
| 4   | JPA Performance Tuning Strategies      | ★★★        | draft   |
| 5   | JPA Security Native Queries and Data Exposure | ★★★  | draft   |

### JPA - L5 Architecture

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | JPA in Domain-Driven Design            | ★★★        | draft   |
| 2   | CQRS with JPA Read Models              | ★★★        | draft   |
| 3   | JPA Multi-tenancy Architecture         | ★★★        | draft   |

### JPA - L6 Theory

| #   | Keyword                                          | Difficulty | Status  |
| --- | ------------------------------------------------ | ---------- | ------- |
| 1   | Persistence Context Theory                       | ★★★        | draft   |
| 2   | JPA Specification vs Implementation Design       | ★★★        | draft   |

### JPA - META Patterns

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | JPA Anti-Pattern Catalog               | ★★☆        | draft   |
| 2   | ORM Selection Decision Framework       | ★★★        | draft   |
