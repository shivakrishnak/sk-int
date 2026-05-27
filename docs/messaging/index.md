---
title: "Messaging and Event-Driven"
nav_order: 15
has_children: true
---

# Messaging and Event-Driven

Apache Kafka, RabbitMQ, event-driven architecture, pub/sub patterns,
event sourcing, CQRS, Saga pattern, outbox pattern, dead letter queues,
schema evolution (Avro/Protobuf), and exactly-once semantics.

## Files

| File | Level | Keywords | Status |
| ---- | ----- | -------- | ------ |
| [Messaging - L0 Orientation](Messaging%20-%20L0%20Orientation.md) | L0 | 4 | draft   |
| [Messaging - L1 Foundations](Messaging%20-%20L1%20Foundations.md) | L1 | 5 | draft   |
| [Messaging - L2 Kafka](Messaging%20-%20L2%20Kafka.md) | L2 | 5 | draft   |
| [Messaging - L2 RabbitMQ and Patterns](Messaging%20-%20L2%20RabbitMQ%20and%20Patterns.md) | L2 | 5 | draft   |
| [Messaging - L3 Event Patterns](Messaging%20-%20L3%20Event%20Patterns.md) | L3 | 5 | draft   |
| [Messaging - L3 Advanced Integration](Messaging%20-%20L3%20Advanced%20Integration.md) | L3 | 5 | draft   |
| [Messaging - L4 Production Depth](Messaging%20-%20L4%20Production%20Depth.md) | L4 | 5 | draft   |
| [Messaging - L5 Architecture](Messaging%20-%20L5%20Architecture.md) | L5 | 4 | draft   |
| [Messaging - L6 Theory](Messaging%20-%20L6%20Theory.md) | L6 | 2 | draft   |
| [Messaging - META Patterns](Messaging%20-%20META%20Patterns.md) | META | 3 | draft   |

**Keywords:** 43 | **Files:** 10 | **Status:** complete

---

## Keyword Registry

### Messaging - L0 Orientation

| #   | Keyword                                     | Difficulty | Status  |
| --- | ------------------------------------------- | ---------- | ------- |
| 1   | Event-Driven Architecture Overview          | ★☆☆        | draft   |
| 2   | Messaging Systems Landscape                 | ★☆☆        | draft   |
| 3   | Synchronous vs Asynchronous Communication   | ★☆☆        | draft   |
| 4   | Pub/Sub vs Point-to-Point Queues            | ★☆☆        | draft   |

### Messaging - L1 Foundations

| #   | Keyword                                     | Difficulty | Status  |
| --- | ------------------------------------------- | ---------- | ------- |
| 1   | Message Queue Fundamentals                  | ★☆☆        | draft   |
| 2   | Apache Kafka Core Concepts                  | ★☆☆        | draft   |
| 3   | RabbitMQ Core Concepts                      | ★☆☆        | draft   |
| 4   | Message Serialization Formats               | ★★☆        | draft   |
| 5   | Message Delivery Guarantees                 | ★★☆        | draft   |

### Messaging - L2 Kafka

| #   | Keyword                                     | Difficulty | Status  |
| --- | ------------------------------------------- | ---------- | ------- |
| 1   | Kafka Producers and Consumer API            | ★★☆        | draft   |
| 2   | Kafka Topics Partitions and Offsets         | ★★☆        | draft   |
| 3   | Consumer Groups and Rebalancing             | ★★☆        | draft   |
| 4   | Kafka Configuration and Tuning              | ★★☆        | draft   |
| 5   | Message Ordering Guarantees in Kafka        | ★★☆        | draft   |

### Messaging - L2 RabbitMQ and Patterns

| #   | Keyword                                     | Difficulty | Status  |
| --- | ------------------------------------------- | ---------- | ------- |
| 1   | RabbitMQ Exchanges and Routing              | ★★☆        | draft   |
| 2   | Dead Letter Queues and Retry                | ★★☆        | draft   |
| 3   | Message Acknowledgment Patterns             | ★★☆        | draft   |
| 4   | Poison Message Handling                     | ★★☆        | draft   |
| 5   | Message TTL Priority and Expiry             | ★★☆        | draft   |

### Messaging - L3 Event Patterns

| #   | Keyword                                     | Difficulty | Status  |
| --- | ------------------------------------------- | ---------- | ------- |
| 1   | Event Sourcing Pattern                      | ★★★        | draft   |
| 2   | Outbox Pattern                              | ★★★        | draft   |
| 3   | Saga Pattern for Distributed Transactions   | ★★★        | draft   |
| 4   | CQRS with Event-Driven Architecture         | ★★★        | draft   |
| 5   | Exactly-Once Semantics                      | ★★★        | draft   |

### Messaging - L3 Advanced Integration

| #   | Keyword                                     | Difficulty | Status  |
| --- | ------------------------------------------- | ---------- | ------- |
| 1   | Kafka Streams Processing                    | ★★★        | draft   |
| 2   | Schema Evolution with Avro and Protobuf     | ★★★        | draft   |
| 3   | Kafka Connect and Integration Patterns      | ★★★        | draft   |
| 4   | Reactive Messaging with SmallRye            | ★★★        | draft   |
| 5   | Event Store Design and Implementation       | ★★★        | draft   |

### Messaging - L4 Production Depth

| #   | Keyword                                     | Difficulty | Status  |
| --- | ------------------------------------------- | ---------- | ------- |
| 1   | Kafka Performance Tuning                    | ★★★        | draft   |
| 2   | Consumer Lag Diagnosis and Resolution       | ★★★        | draft   |
| 3   | Message Loss Prevention Strategies          | ★★★        | draft   |
| 4   | Messaging Anti-Patterns                     | ★★★        | draft   |
| 5   | Event-Driven Security Patterns              | ★★★        | draft   |

### Messaging - L5 Architecture

| #   | Keyword                                     | Difficulty | Status  |
| --- | ------------------------------------------- | ---------- | ------- |
| 1   | Event-Driven Architecture at Scale          | ★★★        | draft   |
| 2   | Event Mesh and Multi-Cluster Kafka          | ★★★        | draft   |
| 3   | Messaging Platform Migration                | ★★★        | draft   |
| 4   | Event-Driven Microservices Orchestration    | ★★★        | draft   |

### Messaging - L6 Theory

| #   | Keyword                                     | Difficulty | Status  |
| --- | ------------------------------------------- | ---------- | ------- |
| 1   | Distributed Ordering and Consensus Theory   | ★★★        | draft   |
| 2   | Event-Driven Formal Models                  | ★★★        | draft   |

### Messaging - META Patterns

| #   | Keyword                                     | Difficulty | Status  |
| --- | ------------------------------------------- | ---------- | ------- |
| 1   | Event-Driven Decision Framework             | ★★★        | draft   |
| 2   | Messaging Pattern Selection Model           | ★★★        | draft   |
| 3   | Eventual Consistency Mental Model           | ★★★        | draft   |
