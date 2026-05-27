---
layout: default
title: "Messaging - L5 Architecture"
parent: "Messaging and Event-Driven"
grand_parent: "SK Interview"
nav_order: 8
permalink: /messaging/l5-architecture/
---

# Event-Driven Architecture at Scale

🎯 Interview Weight: very high - EDA at scale is a Staff+
system design topic.

---

### 🎯 Model Answer

**30 seconds:**
> EDA at scale challenges: event ordering (cross-partition,
> cross-service), schema governance (hundreds of event types),
> consumer lag management at high throughput, event discoverability
> (what topics exist and what schemas they use), and operational
> complexity (thousands of consumer groups to monitor). Solutions:
> event catalog (Confluent Schema Registry), observability
> (Datadog + Prometheus consumer lag), and governance processes
> (event review before topic creation).

**3 minutes (Senior):**
> EDA at scale patterns:
>
> Event catalog and discoverability:
> At 10 teams, 200+ topics: no one knows what topics exist,
> who owns them, or what schemas they use.
> Solution: Confluent Schema Registry as the schema contract.
> Event documentation in Backstage or AsyncAPI specification.
> AsyncAPI: like OpenAPI but for event-driven APIs.
> Documents: topic name, schema, producers, consumers, SLAs.
>
> Consumer group management:
> 500 consumer groups in a Kafka cluster.
> Monitoring all groups' lag is critical.
> Prometheus Kafka Exporter + Grafana: dashboard showing
> lag per group, growing lag alerts.
> Dead consumer groups (inactive, non-zero lag): stale offsets
> from decommissioned services. Clean up periodically.
>
> Event schema governance:
> Schema Registry with `FULL` compatibility mode.
> Schema change reviews (like code review, but for schemas).
> Breaking changes require deprecation period + migration plan.
> Schema versioning: topic name includes version
> (`orders-v1`, `orders-v2`) or schema ID in header.
>
> Topic naming conventions:
> Establish team-wide naming: `{domain}.{aggregate}.{event-type}`
> Example: `commerce.order.placed`, `payment.charge.processed`.
> Avoids: `orders` (too generic), `data-pipeline-stage-3` (opaque).
>
> Multi-tenancy in Kafka:
> Large organizations: multiple teams sharing one Kafka cluster.
> Namespace topics by team: `team-a.orders`, `team-b.orders`.
> Or use Confluent Cloud / Redpanda Cloud: separate clusters per team.
> ACLs enforce tenant isolation.

**Blank Mind Recovery:**

**(1) Restate:** "EDA at scale: govern schemas, monitor all consumer
groups, catalog topics, enforce naming conventions."

---

### ⚖️ Comparison Table

| Scale Concern | 10 Teams | 100 Teams |
|---------------|---------|----------|
| Schema governance | Schema Registry | Schema Registry + review process |
| Topic discovery | Wiki | AsyncAPI + Backstage |
| Consumer lag monitoring | Prometheus | Datadog/New Relic + SLOs |
| Cluster management | Shared cluster | Per-team clusters |

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Schema governance + topic naming |
| Staff | 10 min | AsyncAPI + consumer group management + multi-tenancy |

---

---

# Event Mesh and Multi-Cluster Kafka

🎯 Interview Weight: high - Multi-cluster Kafka is a production
architecture for geo-distributed event streaming.

---

### 🎯 Model Answer

**30 seconds:**
> Multi-cluster Kafka: multiple Kafka clusters in different
> regions. Events need to be replicated between clusters for
> global consumption. Tools: MirrorMaker 2 (Kafka native
> replication), Confluent Replicator (enterprise), Confluent
> Cluster Linking (lower latency). An event mesh extends this:
> events flow transparently across clusters and cloud providers.
> Use case: global microservices needing events from all regions.

**3 minutes (Senior):**
> Multi-cluster Kafka replication:
>
> MirrorMaker 2 (MM2):
> Kafka Connect-based replication.
> Source cluster -> MM2 -> Target cluster.
> MM2 mirrors topics, consumer group offsets, and ACLs.
> Topic naming: `source-cluster.orders` in the target cluster.
> Consumer offset sync: consumers can failover to target cluster
> and resume from the correct offset.
>
> MirrorMaker 2 topology options:
> Active/passive: DC1 is primary. DC2 mirrors. On DC1 failure:
> consumers redirect to DC2. Events are replicated to DC2 but
> with replication lag (seconds to minutes).
> Active/active: both DCs produce and consume events. Both
> DCs mirror each other. Risk: event duplication if same event
> is replicated both ways. Need deduplication (event ID).
>
> Confluent Cluster Linking:
> Direct broker-to-broker replication. Lower latency than MM2
> (seconds vs minutes). Reads from leader without intermediate
> consumer/producer. Commercial feature.
>
> Event mesh concept:
> An abstraction layer over multiple message brokers (Kafka + RabbitMQ
> + Azure Service Bus). Events flow between brokers transparently.
> Solana Event Mesh, Solace: commercial event mesh platforms.
> Provides: discovery, routing, filtering without application changes.
> Use case: large enterprises with heterogeneous messaging infrastructure.
>
> Geo-routing considerations:
> GDPR: EU events must not leave EU clusters.
> HIPAA: patient data must stay in US clusters.
> Event mesh with geo-aware routing enforces data residency.

**Blank Mind Recovery:**

**(1) Restate:** "Multi-cluster Kafka: replicate topics across regions
via MirrorMaker 2. Active/passive = simple. Active/active = needs dedup."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | MirrorMaker 2 topology + active/passive vs active/active |
| Staff | 10 min | Event mesh + data residency + offset sync failover |

---

---

# Messaging Platform Migration

🎯 Interview Weight: high - Migrating messaging platforms
is a real-world engineering challenge tested at senior+ level.

---

### 🎯 Model Answer

**30 seconds:**
> Migrating from RabbitMQ to Kafka (or vice versa): run both
> systems in parallel during a migration window, use the strangler
> fig pattern (new services use new platform, old services stay
> on old platform), bridge consumers read from old and republish
> to new. Key challenge: consumer offset semantics differ between
> RabbitMQ (no replay) and Kafka (full replay). Migration must
> also handle in-flight messages to prevent loss.

**3 minutes (Senior):**
> Migration strategy - RabbitMQ to Kafka:
>
> Phase 1 - Dual publish:
> Publisher writes to both RabbitMQ AND Kafka simultaneously.
> Old consumers read from RabbitMQ (unchanged).
> New consumers can read from Kafka (testing in parallel).
> Risk: publisher must handle partial failure (one broker down).
> Outbox pattern helps: publish to outbox, relay delivers to both.
>
> Phase 2 - Consumer migration:
> Migrate consumers from RabbitMQ to Kafka one by one.
> Verify: consume from Kafka, check business outcomes match.
> Feature flag: consumer config selects broker.
> Roll back: flip flag back to RabbitMQ if issues.
>
> Phase 3 - Publisher migration:
> Once all consumers are on Kafka: remove RabbitMQ publishing.
> Monitor: no consumers on RabbitMQ, queue depth drops to 0.
>
> Phase 4 - Decommission:
> After 1-2 weeks with no RabbitMQ traffic: decommission.
>
> RabbitMQ -> Kafka specific challenge:
> RabbitMQ messages do not have a "replay" concept.
> Messages consumed by old consumers are gone forever.
> Solution: during dual-publish phase, keep RabbitMQ messages
> for idempotent consumption (or accept that old messages
> cannot be replayed on Kafka).
>
> Kafka -> RabbitMQ migration (unusual but possible):
> Kafka has full history. Bridge consumer reads Kafka from
> specific offset, publishes to RabbitMQ.

**Blank Mind Recovery:**

**(1) Restate:** "Migration: dual-publish -> migrate consumers -> migrate
producers -> decommission. Each phase reversible."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Dual-publish strategy + consumer migration |
| Staff | 8 min | In-flight message safety + feature flags + rollback |

---

---

# Event-Driven Microservices Orchestration

🎯 Interview Weight: high - Orchestration of complex event
flows is a Staff-level design topic.

---

### 🎯 Model Answer

**30 seconds:**
> Event-driven microservices orchestration: managing complex
> multi-step workflows across services via events. The key
> tension: choreography (services react to events independently)
> vs orchestration (a coordinator manages the workflow). At scale,
> choreography becomes unmaintainable (implicit workflow logic
> scattered across services). Orchestration tools: Temporal,
> Apache Airflow, AWS Step Functions, custom state machines.

**3 minutes (Senior):**
> Orchestration approaches:
>
> Temporal (workflow engine for microservices):
> Define workflows as code (Java, Go, Python).
> Temporal executes activities (service calls) in sequence,
> handles retries, timeouts, and compensations automatically.
> Workflow state is durable: if the Temporal worker crashes
> mid-workflow, it resumes from the last checkpoint.
> Use case: order fulfillment workflow (10 steps, 2-minute duration).
> Much simpler than a custom saga state machine.
>
> Choreography at scale - the spaghetti problem:
> 10 services each reacting to events from 5 other services.
> The workflow is implicit: understanding the full order flow
> requires reading code in 10 services.
> No central view of workflow state.
> Adding a step: modify multiple services simultaneously.
> Debugging: trace correlation IDs across 10 service logs.
>
> Orchestration at scale - the bottleneck risk:
> Central orchestrator (e.g., OrderOrchestrator service) makes
> direct calls to PaymentService, InventoryService, etc.
> Orchestrator is a coupling point: all services' availability
> affects the orchestrator.
> Mitigation: orchestrator communicates via events, not direct calls.
> This gives resilience (services can be temporarily down)
> while retaining central visibility.
>
> Process manager pattern:
> Stateful service that tracks the state of a business process.
> Reacts to events, sends commands, tracks which steps are done.
> Not an HTTP orchestrator - communicates via events.
> State persisted in a DB (or event store).

**Blank Mind Recovery:**

**(1) Restate:** "Orchestration: central coordinator for complex workflows.
Temporal for durable workflows. Choreography breaks down at scale."

---

### 🎯 Interview Deep-Dive

| Seniority | Time | Focus |
|-----------|------|-------|
| Senior | 5 min | Choreography spaghetti problem + orchestration pattern |
| Staff | 8 min | Temporal + process manager + orchestration via events |

| Interviewer Type | Emphasis |
|------------------|---------|
| Technical Panel | EDA at scale + consumer group management |
| System Design | Orchestration vs choreography + migration strategy |
| Bar Raiser | Event mesh + governance + Temporal trade-offs |
