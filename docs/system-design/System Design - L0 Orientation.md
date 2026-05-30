---
layout: default
title: "System Design - L0 Orientation"
parent: "System Design"
grand_parent: "SK Interview"
nav_order: 1
permalink: /system-design/l0-orientation/
render_with_liquid: false
---

# System Design - L0 Orientation

---

# What is System Design

---
id: SSD-001
title: What is System Design
category: System Design
difficulty: ★☆☆
interview_weight: low
asked_at: Mid/Senior
seniority: mid
tags: #system-design, #orientation, #architecture
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> System design is the process of defining the architecture, components,
> interfaces, and data flow to satisfy specified requirements at scale.
> In interviews: you are asked to design a real-world system (URL shortener,
> Twitter, Netflix) and must reason about scale, reliability, and trade-offs.
> It tests whether you can think like an architect: beyond code, to infrastructure,
> databases, caching, networking, and failure modes.

**3 minutes:**
> System design covers two broad areas: (1) the technical concepts (databases,
> caches, load balancers, queues, CDNs, APIs) and (2) how to reason about
> combining them to meet requirements. In an interview: you start with requirements
> (functional: what it does; non-functional: how well - QPS, latency, availability),
> estimate scale (100K requests/day vs 100M), then design the system component
> by component, justifying each decision.
>
> The core trade-offs that appear in every design: consistency vs availability
> (CAP theorem), latency vs throughput, storage cost vs query speed, complexity
> vs simplicity, vertical vs horizontal scaling. No design is perfect - every
> choice has costs. The interview tests whether you know the costs.

**Blank Mind Recovery:**

**(1) Restate:** "System design is designing how a software system is structured:
what components it has, how they communicate, and how it handles scale."

**(2) First principles:** "Any software system takes input, processes it, and
produces output. At scale, processing becomes distributed across many machines.
System design is making the decisions about that distribution: where does
computation happen, where does data live, how does information flow."

**(3) Bridge:** "Designing a system is like designing a city. The city has
roads (networks), buildings (servers), power grid (databases), post office
(messaging), hospitals (monitoring). Each serves a purpose. The architect
decides the layout to handle the population (scale) with the needed services
(requirements)."

---

### 📘 Concept Explanation

**What it is:**
System design is the discipline of defining the architecture of large-scale
software systems. It encompasses component selection, data modeling, API design,
infrastructure topology, and failure handling.

**Core components in most system designs:**

```
Frontend (clients)
    |
    | HTTPS
    v
CDN / DNS Load Balancer
    |
    | Routes to region
    v
API Gateway / Load Balancer
    |
    | Routes to service
    v
Application Servers (horizontally scaled)
    |
    +-- Cache (Redis/Memcached)
    |     |
    |     +-- Cache Hit -> return fast
    |     +-- Cache Miss -> go to DB
    |
    +-- Database (SQL or NoSQL)
    |     |
    |     +-- Primary (writes)
    |     +-- Replica(s) (reads)
    |
    +-- Message Queue (Kafka/RabbitMQ)
          |
          +-- Async processing
          +-- Decoupling producers/consumers
```

**What an interviewer evaluates:**
1. Requirements clarification (functional + non-functional)
2. Capacity estimation (QPS, storage, bandwidth)
3. API design (what endpoints/contracts)
4. Data modeling (what data, which DB type, schema)
5. High-level design (components and connections)
6. Deep dive on chosen components
7. Bottleneck identification and scaling solutions
8. Failure modes and resilience

---

### 💻 Code Example

*(Omit: L0 orientation - no code, architecture is the focus)*

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> System design is about how you structure a large software application.
> Instead of thinking about code, you think about components: web servers,
> databases, caches, and how they connect. In interviews, you'll be asked to
> design something like a URL shortener and talk about how many users it handles,
> where data is stored, and what happens when servers fail.

**Senior / Staff:**
> System design is architectural reasoning under constraints. The constraints
> are always: scale (QPS, data volume), latency requirements, consistency
> requirements, budget, and team capability. Every design decision is a trade-off.
> The senior interview evaluates: do you know the trade-offs, do you apply them
> correctly to the given context, and can you evolve a simple design toward
> handling real-world failure modes?

---

### ⚠️ Common Misconceptions

**Misconception: "There is a single correct answer to a design question."**
Every system design has valid alternatives. A relational DB vs. a document DB
for a given problem can both be correct choices with different trade-offs.
The interview tests your reasoning about the trade-offs, not selection of a
magic answer. "It depends" is correct IF followed by "...on X, Y, Z, and
here's my reasoning."

---

### 🚨 Failure Modes and Diagnosis

**Interview Failure Mode: Jumping into solution without requirements**
Starting to design without clarifying scale and requirements produces
an architecture optimized for the wrong problem. First questions:
- Daily active users? Peak QPS?
- Read-heavy or write-heavy?
- Consistency requirements (banking vs. social media)?
- Latency requirements (<100ms? <1s?)
- Global or regional?

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

#### Q1 - What is the first thing you do when given a system design question?

Clarify requirements before designing anything:

**Functional requirements:** What does the system DO?
- What are the core use cases? (Post a tweet, view a feed, follow users)
- What is OUT of scope? (Analytics, ads, DMs if you're focused on feed)
- What is the read/write pattern? (Timeline: mostly read; posting: write)

**Non-functional requirements:** How well must it work?
- Scale: How many users? Peak QPS? Data volume per day?
- Latency: P99 latency target? (<100ms for critical paths)
- Availability: 99.9%? 99.99%? (8.7 hours/year vs 52 minutes/year downtime)
- Consistency: Strong (banking) or eventual (social media)?
- Durability: Can we afford to lose a few writes? (Usually no)

Example clarification for "Design Twitter":
- 300M monthly active users, 100M daily
- 500M tweets/day (posted)
- Read rate ~10-100x write rate (feeds are read far more than posted)
- Timeline latency: <300ms
- Availability: 99.99%
- Global users but OK with slight consistency delay

*What separates good from great:* The requirements clarification is NOT a
formality - it fundamentally changes the design. 1,000 QPS vs. 1,000,000 QPS
requires different databases. Strong consistency vs. eventual consistency
requires different replication strategies. A candidate who designs the same
system regardless of scale is red-flagged. Requirements define the design;
design without requirements is guessing.

---

#### Q2 - What is the difference between functional and non-functional requirements?

**Functional requirements:** What the system does.
- Users can post tweets (140 chars)
- Users can follow other users
- Users see a timeline of tweets from followed users
- Tweets can include images/videos

**Non-functional requirements:** How well it does it.
- Availability: 99.99% uptime (52 minutes downtime/year)
- Latency: P99 timeline load < 300ms
- Scalability: handle 100K QPS read, 10K QPS write
- Durability: no tweet lost once acknowledged
- Consistency: eventual (user may see tweets seconds late)
- Compliance: GDPR (data deletion capability)

The key difference: functional requirements define the API contract.
Non-functional requirements define the operational envelope.

*What separates good from great:* Non-functional requirements drive
the architectural decisions more than functional requirements. A tweet system
with 1K QPS can use a single Postgres instance. At 1M QPS: you need sharding,
read replicas, caching, CDN for media. The functional requirements ("post a tweet")
don't change. The non-functional requirements (scale, latency) determine
the entire infrastructure. Senior engineers start with NFRs because they know
NFRs drive architecture.

---

#### Q3 - What are the common system components and when is each used?

| Component | Purpose | When to add |
|-----------|---------|------------|
| Load Balancer | Distribute traffic | Any multi-instance deployment |
| CDN | Cache static content near users | Static files, global users |
| API Gateway | Rate limit, auth, routing | Microservices, external APIs |
| Cache | Fast reads of hot data | Read-heavy, slow DB queries |
| SQL Database | ACID transactions, relations | Financial, user data, complex queries |
| NoSQL Database | Scale writes, flexible schema | High write rate, varying schema |
| Message Queue | Async processing, decoupling | High-throughput writes, decoupled services |
| Blob Storage | Binary files (images, video) | Media upload/storage |
| Search Engine | Full-text search, complex queries | Search functionality |

*What separates good from great:* Every component has a cost: operational
complexity, latency hop, consistency model. Adding a cache means managing
cache invalidation. Adding a queue means handling message ordering and
at-least-once delivery. Adding a CDN means content freshness management.
Good architects add components only when the alternative is worse. Over-engineering
(adding Kafka to a 100 QPS system) is as bad as under-engineering (single Postgres
for 1M QPS).

---

#### Q4 - How do you estimate capacity in a system design interview?

Back-of-envelope estimation steps:

```
Example: Design a URL shortener
1. Users: 100M daily active users
2. Write rate: 10% create short URLs
   = 10M URLs/day = 100K URLs/hour = ~30 URLs/sec
3. Read rate: 10:1 read:write ratio (typical)
   = 300 reads/sec
4. Storage (5 years):
   10M URLs/day * 365 * 5 = 18.25 billion URLs
   Each URL ~500 bytes: 18.25B * 500B = ~9 TB
5. Bandwidth:
   Writes: 30/sec * 500B = 15 KB/sec (negligible)
   Reads: 300/sec * 500B = 150 KB/sec (negligible)
   (redirects are small - just HTTP 301/302)
6. Cache:
   Pareto: 20% of URLs get 80% of traffic
   Hot URLs: cache top 20% = 3.6B * 500B ≈ 1.8TB
   Feasible in Redis cluster
```

Key estimation shortcuts:
- 1 day = 86,400 sec ≈ 100K sec (easy math: divide by 100K)
- 1 million requests/day = ~12/second
- 1 billion = 1K million
- 1 byte = 8 bits
- Character (UTF-8) = 1-4 bytes, assume 1 for ASCII

*What separates good from great:* The exact numbers don't matter - the ORDER
OF MAGNITUDE does. 300 QPS vs 300K QPS changes the design completely.
The goal is not precision but identifying: single server vs cluster, one
DB vs sharding, no cache vs massive cache. Round aggressively. State
assumptions explicitly. "Assuming 10% daily active of monthly users" is a
reasonable assumption; state it so the interviewer can correct it.

---

#### Q5 - What are the most important system design trade-offs to know?

**1. Consistency vs Availability (CAP Theorem):**
Can't have both during network partition. Choose C (banking) or A (social media).

**2. Latency vs Throughput:**
Optimize for fast individual responses (low latency) vs many requests/second
(high throughput). Batch processing trades latency for throughput.

**3. SQL vs NoSQL:**
SQL: strong consistency, complex queries, foreign keys.
NoSQL: horizontal scale, flexible schema, eventual consistency.

**4. Horizontal vs Vertical scaling:**
Vertical: bigger machine (simpler, limited ceiling).
Horizontal: more machines (complex, near-infinite scale).

**5. Push vs Pull delivery:**
Push (server sends to client): low latency, high server load.
Pull (client asks server): simple, potential for stale data.

**6. Normalization vs Denormalization:**
Normalized: less storage, consistent, slower reads (joins).
Denormalized: more storage, fast reads, harder writes.

*What separates good from great:* Trade-offs are not binary choices.
Most systems combine strategies: SQL for financial data, NoSQL for user
activity logs. Strong consistency for account balances, eventual consistency
for social feeds. The sophistication is in knowing WHICH data needs which
guarantees and applying the appropriate solution to each. "Use NoSQL for
everything" or "always use SQL" are both wrong.

---

#### Q6 - What is the difference between latency and throughput?

**Latency:** Time to complete ONE request (milliseconds).
- P50 latency: median request time
- P99 latency: 99th percentile (1 in 100 is this slow or slower)
- P999 latency: 99.9th percentile (long tail)

**Throughput:** Requests completed per unit time (requests/second, QPS).

Relationship:
```
Little's Law: L = λ * W
  L = number of requests in system
  λ = throughput (arrival rate)
  W = latency (time in system)

If you want to double throughput (λ):
  Double the number of workers (L), or
  Halve the latency (W)

High throughput != low latency:
  A batching system: high throughput, high latency
  (waits for batch before processing)
  A streaming system: lower throughput, lower latency
  (processes each item immediately)
```

*What separates good from great:* Optimizing for the wrong metric is a common
mistake. Payment processing: optimize latency (user waits for transaction).
Report generation: optimize throughput (many reports, latency less critical).
Log processing: optimize throughput (millions of events, each processed in batch).
The question to ask: "Does the user wait for this operation?" If yes: optimize
latency. If no (background processing): optimize throughput. If both: disaggregate
the synchronous (low latency) from asynchronous (high throughput) paths.

---

#### Q7 - What is availability and how do you calculate it?

**Availability = Uptime / (Uptime + Downtime)**

Common availability targets:

| Availability | Downtime/year | Downtime/month | Use case |
|-------------|--------------|----------------|---------|
| 99% (2 nines) | 3.65 days | 7.2 hours | Internal tools |
| 99.9% (3 nines) | 8.76 hours | 43.8 min | Most web apps |
| 99.99% (4 nines) | 52 minutes | 4.4 min | Financial systems |
| 99.999% (5 nines) | 5.26 min | 26 sec | Payment processing |

**System availability with dependencies:**
```
If system has components A and B, both required (series):
  System availability = A * B
  99.9% * 99.9% = 99.8%

If system has 2 servers (parallel, either can serve):
  System availability = 1 - (1-A) * (1-B)
  = 1 - 0.001 * 0.001 = 99.9999%
```

**Achieving high availability:**
- Redundancy: multiple instances, no SPOF
- Failover: health checks, automatic routing around failures
- Graceful degradation: serve cached data when DB is down
- Circuit breaker: fail fast instead of waiting for timeout

*What separates good from great:* SLAs (Service Level Agreements) define
the availability commitment. SLOs (Service Level Objectives) are internal
targets. SLIs (Service Level Indicators) are the actual measurements.
A payment processor might have SLA = 99.99%, SLO = 99.995% (internal target
with margin), SLI = measured uptime. When designing: agree on the SLO first
because it determines infrastructure costs (3 nines = commodity hardware,
5 nines = redundant everything at every layer).

---

# System Design Interview Framework

---
id: SSD-002
title: System Design Interview Framework
category: System Design
difficulty: ★☆☆
interview_weight: high
asked_at: Mid/Senior
seniority: mid
tags: #system-design, #interview-framework, #process
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> The framework: (1) Clarify requirements - functional + non-functional,
> (2) Estimate scale - QPS, storage, bandwidth, (3) Define APIs - inputs/outputs,
> (4) Data model - what data, which DB, (5) High-level design - draw the boxes
> and arrows, (6) Deep dive - pick one component and go deep, (7) Address
> bottlenecks - how do you scale each component. Spend 5 minutes on steps 1-2,
> 10 minutes on 3-5, 10-15 minutes on deep dives.

**3 minutes:**
> The framework structures 45 minutes of design thinking into a coherent
> narrative. Requirements clarification prevents designing the wrong system.
> Scale estimation sizes the components correctly. API design forces you to
> think about the interface before the implementation. Data modeling forces
> explicit choices about storage type and schema. High-level design creates
> the skeleton; deep dives fill in the meat.
>
> The interviewer signals when to go deeper. Watch for: "How would you handle X?"
> or "That's interesting, tell me more about Y." These are depth signals.
> Also watch for: "OK, let's move on." - a signal the interviewer wants breadth.
>
> The biggest failure modes: (1) jumping into solution before requirements, (2)
> overcomplicating the initial design (start simple, evolve), (3) not addressing
> the actual scale (designing for 100 QPS when told 100K), (4) no trade-off
> discussion (every choice has alternatives).

**Blank Mind Recovery:**

**(1) Restate:** "You want me to walk through how I approach a system design interview."

**(2) First principles:** "Any large system has the same fundamental parts:
clients that make requests, servers that process them, data stores that persist
results. The framework structures how you reason about each part."

**(3) Framework recall:**
Requirements -> Scale -> API -> Data -> Design -> Deep Dive -> Bottlenecks.
Think: "What does it DO, How MUCH can it handle, What DATA does it store,
HOW do the pieces connect, WHERE does it break."

---

### 📘 Concept Explanation

**The 7-step framework:**

```
STEP 1: Requirements (5 min)
  Functional: core use cases, in/out of scope
  Non-functional: QPS, latency, availability, consistency
  Clarifying questions: "Is this global or regional?"
                        "Read-heavy or write-heavy?"
                        "How fresh does data need to be?"

STEP 2: Capacity Estimation (3-5 min)
  QPS: users * actions/day / 86400
  Storage: writes/day * record_size * retention_years
  Bandwidth: QPS * avg_response_size
  Cache size: hot data percentage * total_data

STEP 3: API Design (5 min)
  Define endpoints: POST /tweets, GET /timeline/{userId}
  Request/response schema
  Authentication approach

STEP 4: Data Model (5 min)
  Entities: User, Tweet, Follow, Like
  DB choice: SQL (relations + consistency) or
             NoSQL (scale + flexible schema)
  Schema sketch: tables/collections + key fields

STEP 5: High-Level Design (10 min)
  Draw components: clients, CDN, LB, servers, DB, cache, queue
  Show data flow for top use cases
  Identify read vs write paths

STEP 6: Deep Dive (10-15 min)
  Pick critical component (usually the hardest)
  Go deep: algorithms, data structures, specific tech
  Example: timeline generation algorithm, sharding strategy

STEP 7: Bottlenecks and Scaling (5 min)
  Where does this design fail at 10x scale?
  How would you fix each bottleneck?
  Trade-offs of your choices

TIMING:
  45 min total: ~5+5+5+5+10+10+5 = 45 min
  Don't rush step 1 (requirements) even if interviewer pushes
```

---

### 💻 Code Example

*(Omit: framework is process-oriented, not code-oriented)*

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> In a system design interview, I follow a structured approach: first I ask
> clarifying questions to understand the scale and requirements, then I estimate
> the numbers (how many users, requests per second), design the APIs, choose
> the data storage, sketch the architecture, and finally discuss how to handle
> failures and scale. I spend about 5 minutes on requirements before starting
> to draw anything.

**Senior / Staff:**
> The framework is a tool, not a script. I use it to ensure I cover all
> necessary dimensions, but I adapt based on the problem. For a storage-heavy
> problem (YouTube), I spend more time on data modeling and storage tier.
> For a real-time problem (chat), I focus on the push/notification mechanism.
> For a computation-heavy problem (ranking algorithm), I focus on the algorithm
> deep dive. The goal: demonstrate judgment about where complexity lives in
> this specific system. Generic designs that could be "any system" don't impress.
> Domain-specific decisions (why Cassandra for this use case, why this sharding key)
> show depth.

---

### ⚠️ Common Misconceptions

**Misconception: "I need to design a perfect system."**
No system design is complete in 45 minutes. The interviewer knows this.
They are evaluating: do you know the building blocks, do you reason about
trade-offs, do you evolve the design when given new constraints, do you know
what you don't know. A candidate who says "this is the right design" with
no trade-off discussion fails. A candidate who says "this design works at
100K QPS; to reach 1M QPS I'd need to add X, which trades Y for Z" passes.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode: Designing in silence**
Not talking through your reasoning. The interviewer can't evaluate reasoning
they can't hear. Fix: narrate every decision. "I'm choosing Postgres here
because we have complex relational queries and need ACID guarantees. If we
were write-heavy at 1M QPS I'd consider Cassandra."

**Failure Mode: Over-engineering from the start**
Starting with Kafka, multiple microservices, and distributed caches before
establishing simple design. Fix: start with the simplest design that works
(single server, single DB), then evolve to handle scale. "Let's start simple
and identify where we'd hit limits."

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

#### Q1 - How do you handle an interviewer who keeps adding requirements?

This is intentional. Interviewers add requirements to test adaptability:

**Strategy:**
1. "That's a good addition. Let me think about how it affects the design."
2. Identify which component the new requirement impacts
3. Modify only that component (avoid redesigning everything)
4. State the trade-off: "Adding real-time updates changes the polling model
   to a push model. This adds WebSocket servers and increases complexity.
   Worth it if latency requirement is sub-second."

**Types of curveball requirements:**
- "Now make it work globally" -> Multi-region, CDN, data locality
- "Now add real-time notifications" -> WebSocket/SSE push mechanism
- "Now make it work offline" -> Client-side caching, sync protocol
- "What if the DB goes down?" -> Failover, read replicas, circuit breaker

*What separates good from great:* Graceful adaptation is what distinguishes
senior engineers. Requirements change in production too. Demonstrating that
your design has isolation (components that can change independently) shows
architectural maturity. "I'd change only the notification service; the rest
of the design stays the same" is better than "I'd need to redesign everything."

---

#### Q2 - How do you decide when to use a message queue?

Message queues decouple producers from consumers:

**Use a queue when:**
- Producer is faster than consumer (absorb bursts)
- Work can be done asynchronously (email, notification, log processing)
- You need at-least-once delivery guarantee
- Multiple consumers need same events (fan-out)
- You want to retry failed work

**Don't use a queue when:**
- Synchronous response required (user waiting for result)
- Strict ordering required with high throughput (hard with distributed queue)
- Message volume is low (added complexity for no benefit)
- Transactions must span message and data (2PC across DB+queue is complex)

Example decision:
- POST /order (user waits for confirmation): direct call to order service
- Send confirmation email: queue (async, user doesn't wait)
- Charge credit card: direct + async retry on failure
- Update inventory: queue after order confirmed (decoupled)

*What separates good from great:* Queues introduce complexity: message
ordering, idempotency (at-least-once means duplicate processing is possible),
dead-letter queues for failed messages, consumer group management. The benefit
must outweigh this cost. Queues shine for: high write bursts (queue absorbs
spike, consumers process steadily), fanout (one event triggers many services),
durable work (don't lose the job if service restarts). For simple, low-volume
async work: use @Async in your service. Introduce Kafka when volume justifies
the operational overhead.

---

#### Q3 - How do you handle the database bottleneck in a system design?

Database is the most common bottleneck. Options:

**Read-heavy bottleneck:**
1. Add read replicas (sync replication, reads go to replicas)
2. Add cache layer (Redis, Memcached - for hot data)
3. CDN for cacheable content (further out caching)
4. Denormalize (pre-compute expensive joins)

**Write-heavy bottleneck:**
1. Vertical scale (bigger server) - limited ceiling
2. Horizontal sharding (partition by user ID, tweet ID)
3. Write-optimized storage (LSM-tree: Cassandra, RocksDB)
4. Async writes (queue + batch processing)
5. CQRS (separate read and write models)

**Storage bottleneck:**
1. Archive old data (cold storage: S3 + Glacier)
2. Compress data
3. Use blob storage for large objects (images, video)

*What separates good from great:* The order matters: read replicas before
sharding (simpler, no application changes), caching before read replicas
(if data is cacheable). Sharding is the last resort for writes because it
makes cross-shard queries complex and eliminates some JOIN capabilities.
A good answer identifies the bottleneck type first, then applies appropriate
solution in order of ascending complexity.

---

#### Q4 - When do you use SQL vs NoSQL?

```
Choose SQL (Relational) when:
  - Data has clear relationships (foreign keys)
  - ACID transactions required (banking, inventory)
  - Complex queries (joins, aggregations, filters)
  - Schema is stable and well-defined
  - Team has SQL expertise
  Examples: Users, orders, financial records

Choose NoSQL when:
  - High write throughput (Cassandra: 100K writes/sec)
  - Flexible/evolving schema (MongoDB documents)
  - Simple access patterns (key-value: Redis, DynamoDB)
  - Massive scale (petabyte-scale: Bigtable, Cassandra)
  - Graph data (Neo4j, AWS Neptune)
  - Time series (InfluxDB, TimescaleDB)
  Examples: User activity logs, IoT data, social graph

Hybrid (use both):
  SQL: user accounts, orders, billing
  NoSQL: user activity feeds, session storage, leaderboards
```

*What separates good from great:* The SQL vs NoSQL decision is not just about
scale. Eventual consistency of NoSQL is a programming model change: your
application must handle the case where data read is slightly stale. For
shopping carts (acceptable), for account balance (not acceptable). The
"right" database depends on the consistency, query complexity, and scale
requirements of that specific data - not a global choice for the whole system.

---

#### Q5 - How do you handle authentication in a system design?

Authentication flow:

```
1. Client sends credentials (username/password)
2. Auth service verifies against credential store
3. Issues JWT token (signed, contains user ID + roles)
4. Client stores token (browser: httpOnly cookie or localStorage)
5. Subsequent requests: include Bearer token in header
6. API Gateway validates token (verify signature)
7. Extract user ID from token, forward to service
8. Service trusts user ID in header (already verified)

JWT validation at API Gateway:
  - Verify signature (HMAC-SHA256 with secret key)
  - Check expiration (exp claim)
  - Check issuer (iss claim)
  - No DB call needed (stateless)

Refresh token pattern:
  Access token: short-lived (15 min), stateless
  Refresh token: long-lived (7 days), stored in DB
  When access token expires:
    Client sends refresh token
    Auth service validates (checks DB)
    Issues new access + refresh token pair
    Old refresh token invalidated
```

*What separates good from great:* The discussion of WHERE to store tokens
reveals security awareness. httpOnly cookies prevent JavaScript access (XSS
protection) but require CSRF protection. localStorage is accessible to
JavaScript (XSS risk) but no CSRF concern. The secure choice: httpOnly
cookie with SameSite=Strict for web clients. Mobile clients use secure
storage (Keychain/KeyStore). The token validation happens at the API Gateway
or service mesh, not in each service - this prevents security logic drift
across services.

---

#### Q6 - What is the difference between horizontal and vertical scaling?

**Vertical scaling (scale up):** Bigger single machine.
- More CPU, RAM, faster storage
- Simple: no application changes, no distributed systems complexity
- Limited: largest machines are expensive and have a ceiling
- Single point of failure (one machine = any hardware failure = downtime)
- Use when: early stage, when app can't be distributed easily

**Horizontal scaling (scale out):** More machines.
- Add more instances of same service
- Requires load balancing
- Application must be stateless (or state externalized to DB/cache)
- Near-infinite scale (add more machines as needed)
- Fault tolerant (one machine fails, others continue)
- Use when: vertical limit reached, need high availability

```
Vertical scaling journey for a web app:
  1 CPU, 1GB RAM -> 4 CPU, 8GB RAM -> 16 CPU, 64GB RAM
  At some point: can't go bigger, or too expensive

Horizontal scaling:
  1 instance -> 3 instances -> 100 instances
  Load balancer distributes traffic
  Database is the last thing to scale horizontally (hardest)
```

*What separates good from great:* The boundary between vertical and horizontal
is not binary. Databases are typically scaled vertically first (read replicas
= limited horizontal), then with sharding (true horizontal). Web servers are
horizontally scaled easily (stateless). Heavy computation (ML inference) is
vertically scaled first (GPU machines). The practical advice: scale vertically
until cost or availability requirements force horizontal. Horizontal scaling
adds distributed systems complexity - don't introduce it before necessary.

---

#### Q7 - How do you decide which component to deep dive on?

Deep dive selection criteria:

**Pick the component that:**
1. Is most novel/complex for this specific problem
2. Is the most common interview focus (data storage, algorithm, or key service)
3. Has the biggest impact on meeting the requirements
4. The interviewer has signaled interest in

**For common system designs:**
- URL shortener: hash generation algorithm, collision handling
- Twitter: timeline generation algorithm (fan-out strategy)
- YouTube: video storage and streaming (chunking, CDN)
- Chat: message delivery, online presence
- Search: indexing, ranking, fuzzy matching

**What to cover in deep dive:**
1. The algorithm or data structure used
2. How it scales (horizontally? vertically?)
3. Failure modes (what if this component fails?)
4. Specific technology choice and why (Cassandra vs MySQL for this)

*What separates good from great:* The best deep dives connect back to the
non-functional requirements. "I'm choosing this approach because our P99
latency requirement is 100ms. The naive approach would be 500ms for timeline
generation; this pre-computation approach is 10ms. The trade-off: 10x more
storage and write amplification, but that's acceptable given our scale."
Every design decision should trace back to a requirement. This shows systems
thinking, not just technical knowledge.

---

# Scale Mental Models

---
id: SSD-003
title: Scale Mental Models
category: System Design
difficulty: ★☆☆
interview_weight: medium
asked_at: Mid/Senior
seniority: mid
tags: #system-design, #scale, #mental-models, #estimation
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Key scale mental models: (1) Powers of 10 - know the orders of magnitude for
> latency, storage, and throughput. (2) The Pareto principle - 20% of data gets
> 80% of traffic (cache it). (3) Little's Law - throughput = concurrency / latency.
> (4) The knee of the curve - every system has a saturation point beyond which
> adding load degrades performance faster. (5) The 3 pillars: CPU, memory, I/O -
> every bottleneck is one of these.

**3 minutes:**
> Mental models help you reason about scale without precise calculations.
> Powers of 10 for latency: L1 cache = 1ns, RAM = 100ns, SSD = 100 microseconds,
> network within datacenter = 500 microseconds, HDD = 10ms, cross-continent = 150ms.
> A system that reads from HDD instead of memory is 100,000x slower. This
> immediately tells you: hot data must be in memory.
>
> The Pareto principle for caching: 20% of URLs get 80% of traffic. Cache that
> 20% in memory. You've served 80% of traffic from memory (fast) and only 20%
> from disk (slow). This halves the DB load for 80% of requests.
>
> Amdahl's Law for parallelism: if 10% of your computation is serial,
> the maximum speedup from parallelism is 10x (1/0.1), no matter how many
> machines you add. Identify serial bottlenecks before adding parallel resources.

**Blank Mind Recovery:**

**(1) Restate:** "Scale mental models are approximations that help reason about
system performance at large scale without precise calculation."

**(2) Key numbers to remember:** 1K, 1M, 1B; nanoseconds/microseconds/milliseconds;
KB/MB/GB/TB; bytes per common data types.

**(3) Bridge:** "Mental models are navigation tools. You don't need GPS precision
to know that driving west from New York will eventually reach the Pacific Ocean.
Scale models don't need precision - they need to tell you the right direction:
cache or don't cache, single DB or shard, sync or async."

---

### 📘 Concept Explanation

**The latency numbers every engineer should know:**

```
Memory access:           ~100 ns  (0.1 microseconds)
SSD read:               ~100 us  (100 microseconds = 0.1 ms)
Datacenter network:     ~500 us  (0.5 ms)
HDD read:               ~10 ms   (10,000 microseconds)
Cross-continent (USA->Europe): ~150 ms

RATIOS (intuition):
Memory vs HDD:    10,000x faster (100ns vs 10ms)
SSD vs HDD:       100x faster
Datacenter vs memory: 5000x slower than memory
Cross-continent + HDD: 15,000x+ slower than memory read

Implication:
If hot data fits in memory -> keep it in memory (Redis)
If reads hit HDD -> you're 10,000x slower than cache hit
If service calls cross-region -> 150ms added per hop
Minimize network hops in critical path
```

**Storage size mental models:**

```
1 ASCII character = 1 byte
1 emoji = 4 bytes (UTF-8)
1 UUID = 16 bytes (128 bits)
1 timestamp = 8 bytes (int64)
1 tweet = ~140 bytes (text)
1 user record = ~1 KB
1 thumbnail (100x100) = ~10 KB
1 profile photo = ~1 MB
1 minute of 720p video = ~50 MB
1 minute of 4K video = ~375 MB

Storage scale:
  1 million records * 1 KB = 1 GB
  1 billion records * 1 KB = 1 TB
  1 billion records * 1 MB = 1 PB (petabyte!)

Sanity check: if you have 1B users with 1MB each
-> 1 PB storage. Is that feasible? Yes, but expensive.
Recommendation: store thumbnails, not originals
-> 1B * 10KB = 10 TB. Much more feasible.
```

**Throughput benchmarks (order of magnitude):**

```
Single commodity server:
  Web server (nginx): ~100K requests/sec
  Postgres: ~10K-100K simple queries/sec
  Redis: ~100K-1M operations/sec
  Kafka: ~1M messages/sec
  Elasticsearch: ~10K complex queries/sec

Network:
  1 Gbps NIC: 125 MB/sec = 1M small packets/sec
  10 Gbps NIC: 1.25 GB/sec
  Datacenter link: 10-100 Gbps

Object storage (S3):
  S3 PUT: ~3500/sec per prefix
  S3 GET: ~5500/sec per prefix
  Add more prefixes (sharding) to scale beyond this
```

---

### 💻 Code Example

*(Omit: mental models are conceptual, not code)*

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Key numbers: memory access is 100 nanoseconds, SSD is 100 microseconds (1000x
> slower), HDD is 10 milliseconds (100,000x slower than memory). This tells you
> why we use caches - if hot data fits in memory, every access is fast. A single
> Postgres server handles about 10,000-100,000 simple queries per second.
> At 1 million QPS, you need multiple DB servers and caching.

**Senior / Staff:**
> Mental models guide architecture decisions without precise measurement.
> The latency numbers tell you: any operation that touches HDD in the critical
> path of a user request is suspect (10ms * multiple calls = 50-100ms just on
> I/O). The Pareto principle tells you: if you can cache the top 20% of data,
> you handle 80% of traffic from memory. Amdahl's Law tells you: find the
> serial bottleneck first; adding parallel resources beyond it doesn't help.
> Benchmarks tell you: when you need more than 100K QPS from a database, you're
> looking at caching, read replicas, or sharding.

---

### ⚠️ Common Misconceptions

**Misconception: "NoSQL is always faster than SQL."**
NoSQL is often optimized for specific access patterns (key-value, column family),
not universally faster. Redis (in-memory) is faster than Postgres (disk) because
of the storage medium, not the DB model. Postgres with SSD + proper indexing
outperforms Cassandra on the Cassandra node for many query types. The comparison
is always: for THIS access pattern at THIS scale, which is faster?

---

### 🚨 Failure Modes and Diagnosis

**Failure: Underestimating the impact of serialization**
Every HTTP request involves: JSON parse + serialize (CPU), network hop (latency),
possibly gzip compression (CPU). At 100K QPS: 100K * parse time per second.
If JSON parse takes 100 microseconds: 10 seconds of CPU per second -> impossible.
Use Protocol Buffers (10-100x faster than JSON) for high-throughput internal services.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

#### Q1 - What is the "thundering herd" problem and how do you prevent it?

Thundering herd: when many clients simultaneously request the same resource
(usually after a cache miss) and all hit the DB at once:

```
Normal flow:
  Request -> Cache HIT -> fast response

Cache expiry / cold start:
  Time T: cache key expires
  N requests arrive simultaneously
  All get Cache MISS (key still expired)
  All N requests sent to DB simultaneously
  DB overwhelmed -> slow -> timeouts

Prevention strategies:

1. Cache locking (most common):
   First thread: Cache MISS -> acquire lock -> fetch from DB
   Other threads: see lock -> wait
   First thread: populate cache -> release lock
   Other threads: Cache HIT
   Cost: added latency for waiting threads
   Benefit: DB hit = 1 instead of N

2. Staggered expiry (randomize TTL):
   Instead of TTL = 3600 seconds for all keys:
   TTL = 3600 + random(0, 300) seconds
   Keys expire at different times
   DB load spreads out

3. Pre-warming (proactive cache reload):
   Before cache expires: background job refreshes it
   Cache TTL = 1 hour, refresh at 55 minutes
   No cache misses in production

4. Background refresh with stale reads:
   Cache hit (even if expired): return stale value immediately
   Background: refresh cache asynchronously
   User gets fast response (slightly stale)
```

*What separates good from great:* The best solution depends on data type.
Static content (product catalog): pre-warming works well. User-specific data
(user profile): staggered expiry prevents synchronized expiry. High-traffic
shared data (trending topics): cache locking or stale-while-revalidate.
The stale-while-revalidate pattern (return stale immediately, refresh async)
gives the best user experience at the cost of brief staleness - acceptable
for most non-financial data.

---

#### Q2 - How does consistent hashing help with distributed caching?

Simple modulo hashing problem:
```
3 cache nodes: node = hash(key) % 3
Add 4th node: node = hash(key) % 4
~75% of keys now map to different nodes -> cache miss storm
```

Consistent hashing solution:
```
Hash ring (0 to 2^32):
  Each node occupies a position on the ring
  Lookup: hash the key, go clockwise to next node

  Node A at 0
  Node B at 100
  Node C at 200

  key1 hashes to 50 -> goes to Node B
  key2 hashes to 150 -> goes to Node C
  key3 hashes to 250 -> wraps around to Node A

Adding Node D at position 150:
  Only keys between 100 and 150 move to Node D
  ~25% of keys remapped (not 75%)
  Rest of keys: unchanged
```

Virtual nodes (for even distribution):
```
Node A: positions 10, 110, 210
Node B: positions 40, 140, 240
Node C: positions 70, 170, 270
-> Each physical node has N virtual positions
-> Even distribution even with few physical nodes
```

*What separates good from great:* Consistent hashing is used in Redis Cluster,
Amazon Dynamo, Apache Cassandra, and Riak. The ring topology also provides
natural locality: keys between two node positions always go to the same node.
Replication: each key is stored on K consecutive nodes (clockwise). If one
node fails, the next node takes over its key range. The hash ring is a foundational
concept that appears in distributed databases, load balancers, and CDNs.

---

#### Q3 - What is Amdahl's Law and how does it affect scaling?

Amdahl's Law: the maximum speedup from parallelization is limited by the
serial fraction of work.

```
Speedup = 1 / (S + (1-S)/P)
  S = serial fraction (cannot be parallelized)
  P = number of parallel processors
  (1-S) = parallel fraction

Example: S = 0.1 (10% serial)
  P=2:  1/(0.1 + 0.9/2) = 1/0.55 = 1.82x
  P=10: 1/(0.1 + 0.9/10) = 1/0.19 = 5.26x
  P=100: 1/(0.1 + 0.9/100) = 1/0.109 = 9.17x
  P=inf: 1/0.1 = 10x MAXIMUM (even with infinite machines)

If S = 0.1 (10% serial): max speedup = 10x
If S = 0.25 (25% serial): max speedup = 4x
If S = 0.5 (50% serial): max speedup = 2x
```

System design implications:
- Identify serial bottlenecks before horizontal scaling
- Single-threaded Redis: serial within Redis. Scale by sharding (Redis Cluster)
- Leader election in Paxos/Raft: serial (leader processes all writes)
  -> limits write throughput to leader's capacity
- DB transactions requiring global locks: serial
  -> shard to different lock domains

*What separates good from great:* Amdahl's Law explains why simply adding
more servers doesn't solve all scale problems. If your write path goes through
a single leader (common in consensus protocols), horizontal scaling readers
doesn't help write throughput. The solution: identify the serial component,
then either reduce it (make more parallel) or shard across multiple leaders
(each leader handles a partition). Kafka's partition model is Amdahl-aware:
each partition has one leader. Add partitions to add parallel write capacity.

---

#### Q4 - How do you estimate QPS from daily active users?

```
QPS estimation formula:
  QPS = (DAU * actions_per_user_per_day) / 86400

Example: Twitter
  DAU = 100M
  Actions/user/day:
    View timeline: 5 times
    Scroll (load more): 20 tweets per view * 5 = 100 reads
    Post: 0.1 tweets/day (most users don't post daily)
    Like: 10 likes/day
    Search: 1 search/day
  Total actions = ~120 per user per day

  QPS = 100M * 120 / 86400
      = 12B / 86400
      = ~140K QPS

  Peak QPS (3x average for peak hours):
      = ~420K QPS

Write QPS (posts only):
  100M * 0.1 / 86400 = 116 posts/sec (very low)

Read vs Write ratio: ~1000:1 (read-heavy)
  -> Design for read scale (caching, read replicas)
  -> Writes are rarely the bottleneck for Twitter-like systems
```

*What separates good from great:* The action distribution matters. Twitter
is 99%+ read. Instagram is similar. A commenting system is more balanced.
An IoT data ingest system is write-heavy. The read/write ratio determines
whether to optimize the read path (caching, CDN, read replicas) or write path
(message queues, write-optimized storage, sharding). Always ask "is this
read-heavy or write-heavy?" because it changes the entire design.

---

#### Q5 - How do you estimate storage requirements?

```
Storage estimation:

Example: Design Twitter (5-year storage)
  Users: 100M DAU, 500M registered
  Tweets: 500M tweets/day
  Media: 10% of tweets have images

  Text storage:
    500M tweets/day * 280 bytes = 140 GB/day
    5 years: 140 GB * 365 * 5 = 255 TB

  Image storage:
    500M * 10% = 50M images/day
    Average image: 200 KB (compressed)
    50M * 200KB = 10 TB/day
    5 years: 10 TB * 365 * 5 = 18.25 PB

  User data:
    500M users * 1 KB = 500 GB (negligible)

  Total (5 years): ~18 PB (dominated by images)

  This tells you:
  - Text: relational DB feasible (255 TB = sharding needed)
  - Images: must use object storage (S3/GCS/Azure Blob)
    NOT relational DB. Never store binary in relational DB.
  - Media serving: CDN is mandatory (18 PB can't serve from origin)
```

*What separates good from great:* Storage estimation reveals which tier is
needed. Under 10 TB: single server or small cluster. Under 1 PB: commodity
cluster. Over 1 PB: object storage or distributed file system. It also reveals
bottlenecks: if images dominate, image serving cost and CDN cache hit rate
matter more than DB query performance. Always separate estimation by data type
(text vs media) because they need different storage tiers.

---

#### Q6 - What is the "back of the envelope" calculation for bandwidth?

```
Bandwidth = QPS * average_response_size

Example: Twitter timeline
  QPS: 140K reads/sec
  Response: 20 tweets * 280 bytes each
           + 20 thumbnails * 10 KB each
           = 5.6 KB + 200 KB = ~200 KB per response

  Bandwidth = 140K * 200 KB = 28 GB/sec = 224 Gbps

  Is 224 Gbps feasible?
  - 1 datacenter uplink: 100-400 Gbps? Possible but tight.
  - Solution: CDN handles most image bandwidth.
    CDN cache hit rate: 80-90%
    Origin bandwidth: 224 * 10% = 22.4 Gbps -> feasible

  Key: CDN is not optional at this scale.
       Without CDN: 224 Gbps from origin = infeasible.
```

*What separates good from great:* Bandwidth estimation drives CDN decision.
At hundreds of Gbps, CDN is mandatory. At tens of Gbps, CDN is strongly
recommended. Under 1 Gbps, CDN is optional but beneficial for global latency.
Bandwidth also drives cost: cloud egress is expensive ($0.08-0.12/GB).
At 28 GB/sec: 28 * 86400 * $0.09 = $217K/day in egress alone. CDN with
its high cache hit rate + often cheaper CDN pricing can reduce this 10x.
Cost engineering is a real part of system design.

---

#### Q7 - How do you reason about failure rates at scale?

At scale, rare events become frequent:

```
Hard drive failure rate: ~1% per year
  1 drive: 1% chance of failure per year
  1000 drives: 10 drives fail per year (almost 1/month)
  10,000 drives: 100 drives fail per year (2/week)

Implication: at 10,000 drives, disk failure is routine.
  Design for it: replication (RAID, distributed storage)
  Don't be surprised by it: monitoring + auto-replace

Server failure rate: ~3% per year
  100 servers: 3 failures per year (once per 4 months)
  10,000 servers: 300 failures per year (almost daily)

Software bug rate:
  With 1M requests/day and 0.001% bug rate:
  10 errors/day (visible, logs fill up)

"9s" perspective:
  99.9% availability = 1 failure in 1000 requests
  At 1M QPS: 1000 failures/sec = unusable
  At 1M QPS: 99.999% required = 10 failures/sec = manageable

  The right availability target scales with traffic.
  1M QPS * (1 - 0.99999) = 10 errors/sec acceptable
```

*What separates good from great:* Failure rate reasoning leads to the correct
architecture conversation. "At our scale, this will fail daily - how do we
handle it?" Changes the question from "how do we prevent failure?" (impossible)
to "how do we tolerate failure?" (achievable). Chaos engineering (Netflix's Chaos
Monkey) operationalizes this: if failures are routine, test them in production
to ensure the recovery mechanism works. Systems that handle failures gracefully
are more reliable than systems that prevent failures rarely.
