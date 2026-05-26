---
title: "Hibernate"
nav_order: 7
has_children: true
---

# Hibernate

Hibernate ORM: SessionFactory, entity mapping, caching strategies,
fetching, dirty checking, locking, batch processing, and production
diagnostics. From basic CRUD to diagnosing LazyInitializationException
at 3 AM.

## Files

| File | Level | Keywords | Status |
| ---- | ----- | -------- | ------ |
| [Hibernate - L0 Orientation](Hibernate%20-%20L0%20Orientation.md) | L0 | 4 | complete |
| [Hibernate - L1 Foundations](Hibernate%20-%20L1%20Foundations.md) | L1 | 5 | complete |
| [Hibernate - L2 Mapping](Hibernate%20-%20L2%20Mapping.md) | L2 | 5 | complete |
| [Hibernate - L2 Caching and Fetching](Hibernate%20-%20L2%20Caching%20and%20Fetching.md) | L2 | 5 | complete |
| [Hibernate - L3 Internals](Hibernate%20-%20L3%20Internals.md) | L3 | 5 | complete |
| [Hibernate - L3 Advanced Features](Hibernate%20-%20L3%20Advanced%20Features.md) | L3 | 5 | complete |
| [Hibernate - L4 Production Depth](Hibernate%20-%20L4%20Production%20Depth.md) | L4 | 5 | complete |
| [Hibernate - L5 Architecture](Hibernate%20-%20L5%20Architecture.md) | L5 | 3 | complete |
| [Hibernate - L6 Theory](Hibernate%20-%20L6%20Theory.md) | L6 | 2 | complete |
| [Hibernate - META Patterns](Hibernate%20-%20META%20Patterns.md) | META | 2 | complete |

**Keywords:** 41 | **Files:** 10 | **Status:** complete

---

## Keyword Registry

### Hibernate - L0 Orientation

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | ORM Concept and Why Hibernate          | ★☆☆        | draft   |
| 2   | Hibernate vs JDBC Trade-offs           | ★☆☆        | draft   |
| 3   | Hibernate Ecosystem and Versions       | ★☆☆        | draft   |
| 4   | Hibernate vs JPA Relationship          | ★☆☆        | draft   |

### Hibernate - L1 Foundations

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | SessionFactory and Session             | ★☆☆        | draft   |
| 2   | Entity Mapping with @Entity and @Id    | ★☆☆        | draft   |
| 3   | Basic CRUD with Hibernate              | ★☆☆        | draft   |
| 4   | HQL Hibernate Query Language           | ★★☆        | draft   |
| 5   | Hibernate Configuration and Dialects   | ★★☆        | draft   |

### Hibernate - L2 Mapping

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | One-to-One and One-to-Many Mappings    | ★★☆        | draft   |
| 2   | Many-to-Many with Join Tables          | ★★☆        | draft   |
| 3   | Inheritance Mapping Strategies         | ★★☆        | draft   |
| 4   | Embedded Objects and Components        | ★★☆        | draft   |
| 5   | Collection Mappings                    | ★★☆        | draft   |

### Hibernate - L2 Caching and Fetching

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | Eager vs Lazy Loading                  | ★★☆        | draft   |
| 2   | First-Level Cache Session Cache        | ★★☆        | draft   |
| 3   | Second-Level Cache                     | ★★★        | draft   |
| 4   | N+1 Problem Detection                  | ★★★        | draft   |
| 5   | Query Cache                            | ★★☆        | draft   |

### Hibernate - L3 Internals

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | Hibernate Session States               | ★★★        | draft   |
| 2   | Dirty Checking and Automatic Flush     | ★★★        | draft   |
| 3   | Optimistic Locking with @Version       | ★★★        | draft   |
| 4   | Pessimistic Locking Strategies         | ★★★        | draft   |
| 5   | Cascade Types and Orphan Removal       | ★★☆        | draft   |

### Hibernate - L3 Advanced Features

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | Batch Processing and Bulk Operations   | ★★★        | draft   |
| 2   | Native SQL Queries and Result Set Mapping | ★★☆     | draft   |
| 3   | Hibernate Interceptors and Listeners   | ★★★        | draft   |
| 4   | Multi-tenancy Strategies               | ★★★        | draft   |
| 5   | Hibernate Security HQL Injection and Sensitive Data | ★★★ | draft   |

### Hibernate - L4 Production Depth

| #   | Keyword                                        | Difficulty | Status  |
| --- | ---------------------------------------------- | ---------- | ------- |
| 1   | LazyInitializationException Root Cause         | ★★★        | draft   |
| 2   | Hibernate Performance Anti-Patterns            | ★★★        | draft   |
| 3   | Connection Pool Tuning for Hibernate           | ★★★        | draft   |
| 4   | Hibernate Statistics and Slow Query Detection  | ★★★        | draft   |
| 5   | Schema Migration with Hibernate and Flyway     | ★★★        | draft   |

### Hibernate - L5 Architecture

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | Hibernate in Microservices             | ★★★        | draft   |
| 2   | Hibernate vs R2DBC Decision Framework  | ★★★        | draft   |
| 3   | ORM Layer Architecture Decisions       | ★★★        | draft   |

### Hibernate - L6 Theory

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | Object-Relational Impedance Mismatch   | ★★★        | draft   |
| 2   | Hibernate SPI and Extension Model      | ★★★        | draft   |

### Hibernate - META Patterns

| #   | Keyword                                | Difficulty | Status  |
| --- | -------------------------------------- | ---------- | ------- |
| 1   | ORM Anti-Pattern Recognition           | ★★☆        | pending |
| 2   | Hibernate Interview Mental Model       | ★★☆        | pending |
