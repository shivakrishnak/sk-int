---
layout: default
title: "System Design - META Thinking Patterns"
parent: "System Design"
grand_parent: "SK Interview"
nav_order: 11
permalink: /system-design/meta-thinking-patterns/
---

# System Design - META Thinking Patterns

---

# Back-of-Envelope Estimation

---
id: SSD-019
title: Back-of-Envelope Estimation
category: System Design
difficulty: ★☆☆
interview_weight: high
asked_at: All levels
seniority: all
tags: #estimation, #capacity-planning, #math, #scale, #fermi
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Back-of-envelope estimation: rough capacity calculation using order-of-magnitude
> math to validate system design decisions. Key numbers to memorize: 1 day = 86,400
> seconds (approx. 100K), 1 month = 2.6M seconds (approx. 3M), 1 year = 31M seconds
> (approx. 30M). Latency order: L1 cache < 1ns, RAM 100ns, SSD 100 microseconds,
> HDD 10ms, cross-region RTT 150ms. Storage: 1KB text, 10KB rich text, 100KB image,
> 1MB video minute.

**3 minutes:**
> The estimation workflow: (1) define the scale (DAU, QPS, data volume), (2) compute
> read and write QPS, (3) estimate storage, (4) estimate bandwidth, (5) validate
> assumptions against known system limits.
>
> Example: Design Twitter for 100M DAU. 100M users, 50% active daily = 50M DAU.
> Average user: reads 20 tweets, writes 0.1 tweets per day. Read QPS = 50M * 20 / 86400
> = ~12,000 QPS peak (apply 3x = 36,000 QPS). Write QPS = 50M * 0.1 / 86400 = ~60 QPS.
> Each tweet = 300 bytes. Write data = 60 * 300 bytes = 18KB/second = ~1.5GB/day.
>
> Validate: 36,000 read QPS - single MySQL read: ~10K QPS. Need 4 read replicas minimum.
> This tells you: need a caching layer (Redis handles 100K QPS). The estimation reveals
> the bottlenecks before you design anything.

**Blank Mind Recovery:**

**(1) Restate:** "Estimation: do the math first to know if your design makes sense
before explaining it."

**(2) Key workflow:** "DAU -> reads per user, writes per user -> QPS -> storage per
item -> data volume -> bandwidth -> compare to system limits."

**(3) Key numbers:** "100K seconds/day. 86K exactly. 3M seconds/month. 30M/year."

---

### 📘 Concept Explanation

**Numbers to memorize:**

```
Time:
  1 minute = 60 seconds
  1 hour = 3,600 seconds
  1 day = 86,400 seconds (~100K)
  1 month = 2.6M seconds (~3M)
  1 year = 31.5M seconds (~30M)

Data sizes:
  ASCII character = 1 byte
  Unicode character = 2-4 bytes (UTF-8)
  Tweet (280 chars) = ~300 bytes
  Small HTML page = 10KB
  JPEG image = 100KB-1MB
  1-minute video (720p) = ~100MB
  1-hour video (1080p) = ~3GB

Latency reference table:
  L1 cache hit: 0.5 ns
  L2 cache hit: 7 ns
  RAM access: 100 ns (0.1 microsecond)
  SSD random read: 100 microseconds
  HDD random read: 10 ms (100,000x RAM)
  Read 1MB from RAM: 250 microseconds
  Read 1MB from SSD: 1 ms
  Network RTT same DC: 0.5 ms
  Network RTT same region: 10 ms
  Network RTT cross-continent: 150 ms

Throughput reference:
  Single server (simple API): 10K-100K QPS
  Single MySQL: 10K-50K reads/sec
  Single Redis: 100K-1M ops/sec
  Single Kafka: 1M+ messages/sec
  Single HDD: 100 IOPS, 150 MB/s sequential
  Single SSD (SATA): 10K-80K IOPS, 500 MB/s sequential
  Single NVMe SSD: 100K-1M IOPS, 3 GB/s sequential
  Network: 1 Gbps = 125 MB/s

Availability numbers:
  99%:    3.6 days downtime/year
  99.9%:  8.7 hours downtime/year
  99.99%: 52 minutes downtime/year
  99.999%:5 minutes downtime/year
```

**Estimation workflow:**

```
Step 1: Define scale
  DAU (Daily Active Users): given or estimated
  Example: Twitter-like app, 100M registered users
  Active: 50% daily = 50M DAU

Step 2: Usage per user per day
  Read: 20 tweets/day
  Write: 0.1 tweets/day (most users read, few write)
  (Pareto principle: 20% of users generate 80% of content)

Step 3: Calculate QPS
  Write QPS = 50M * 0.1 / 86400 = ~60 QPS average
  Read QPS = 50M * 20 / 86400 = ~12,000 QPS average
  Peak = 3x average (rule of thumb): write ~180 QPS, read ~36,000 QPS

Step 4: Storage
  Per tweet: 300 bytes text + 1KB metadata = ~1.5KB
  Writes/day: 180 * 86400 = ~15M tweets/day
  Storage/day: 15M * 1.5KB = 22.5GB/day
  After 5 years: 22.5GB * 365 * 5 = ~40TB

Step 5: Bandwidth
  Read bandwidth: 36,000 QPS * 1.5KB = ~54 MB/s
  Write bandwidth: 180 QPS * 1.5KB = ~0.27 MB/s (negligible)
  With media: image attachment 10% of tweets = 10KB
    Additional: 3600 * 10KB = ~36 MB/s read
  Total read bandwidth: ~100 MB/s

Step 6: Validate + imply architecture
  60 write QPS: single DB can handle (10K QPS capacity)
    Use: single primary DB with replication
  36,000 read QPS: exceeds single MySQL (10K max)
    Need: Redis cache (handles 200K QPS)
    Cache hit rate 90%: only 3,600 QPS hits DB (manageable with 1-2 replicas)
  40TB over 5 years: Amazon S3 or sharded DB
    S3: $0.023/GB = ~$920/month for 40TB
```

---

### 💻 Code Example

*(Omit: Back-of-envelope estimation is a mathematical reasoning skill, not a code pattern. The "code" is the arithmetic and the decision chain it drives.)*

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Back-of-envelope estimation means doing rough math to figure out the scale of a
> system before designing it. You start with how many users, calculate how many
> requests per second that means, and figure out how much storage and bandwidth
> you need. The goal isn't to be exact - it's to be within an order of magnitude.
> It tells you whether you need one server or a thousand.

**Senior / Staff:**
> Estimation is how I validate that a proposed architecture isn't over or under-
> engineered. The most useful outcome: identify the bottleneck. If write QPS is
> 100 but read QPS is 100K, the design problem is read scaling, not write scaling.
> Don't design distributed write architecture for a read-heavy problem. The peak
> multiplier (3x average) comes from typical traffic patterns: 8am-10pm active
> hours means 16 hours of concentrated load vs 24-hour average. For social apps:
> use 10x for viral spikes (breaking news, celebrity tweet). For financial apps:
> 5x for market open. The multiplier encodes domain knowledge about traffic patterns.

---

### ⚠️ Common Misconceptions

**Misconception: "Estimation needs to be precise."**
Back-of-envelope is deliberately imprecise - order of magnitude is the goal.
10K QPS vs 100K QPS matters (10x difference in architecture). 10K vs 12K doesn't
(same order, same architecture). Round aggressively: 86,400 seconds -> 100K.
50M * 0.1 / 100K = 50 (not 57.87). Rounding errors compound to at most 2x.
In system design, a 2x error is noise; a 10x error requires a different architecture.

---

### 🚨 Failure Modes and Diagnosis

**Failure mode: Skipping estimation and over-complicating the design**
Symptom: candidate proposes Kafka + Redis + sharded DB for a system that
handles 100 QPS.
Cause: pattern-matching to complex architectures without validating scale.
100 QPS + 1KB responses = 100KB/s bandwidth. A single server handles this
with headroom. Over-engineering a 100 QPS system adds operational cost and
complexity with no benefit.
Rule: estimate first. Let the numbers drive the architecture. If the numbers
say simple, keep it simple.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

#### Q1 - Walk me through estimating QPS for a URL shortener.

```
URL shortener estimation:

Given: Twitter-scale URL shortener
  500M users, 100M daily active
  Each active user: creates 1 new URL per day, follows 100 short links

Step 1: Write QPS (URL creation)
  100M DAU * 1 creation/day / 86400 = ~1,200 writes/day average
  = ~1,200 / 86400 = ~1.4 writes/second average
  Wait: that seems too low. Let me recheck:
  100M * 1 / 86400 = 1,157 writes/second (not 1.4, I made an error)
  Sanity check: 100M / 100K (seconds per day) = 1,000 writes/second
  Peak: 3x = 3,000 writes/second

Step 2: Read QPS (URL redirect)
  100M DAU * 100 clicks/day = 10 billion clicks/day
  / 86400 = ~116,000 reads/second average
  Peak: 3x = ~350,000 reads/second

Step 3: Read:write ratio
  350,000 / 3,000 = ~100:1 (read-heavy)

Step 4: Storage
  URL record: short_code (7 bytes) + long_url (100 bytes) + created_at (8 bytes)
  = ~200 bytes per record
  New records/day: 1,000 * 86400 = ~86M records/day
  Storage/day: 86M * 200 bytes = ~17GB/day
  5 years: 17GB * 365 * 5 = ~31TB

Architecture implied:
  350K reads/second: single DB cannot handle
  Need: Redis cache (1M+ ops/second)
    Cache hit rate 99% (hot URLs are few, popular links get cached)
    1% cache miss: 3,500 reads/second to DB (manageable: 2-3 replicas)
  Storage: 31TB over 5 years - MySQL with sharding, or Cassandra
    Sharding: by short_code (hash-based sharding)
```

*What separates good from great:* The sanity check is critical. I made an
arithmetic error midway (1.4 instead of 1,157). Catching it by re-running the
calculation: 100M / 100K (approximation of 86400) = 1,000 - consistent with
the corrected answer. Always sanity-check: does this number feel right? URL
shorteners are used by billions of people; 1 write/second for 100M active users
would mean 1 write per 100M users per second - clearly wrong. 1,000/second
for 100M users is 1 per 100K seconds (about 28 hours per user): means each user
creates a short URL every 1-2 days. That's reasonable. The sanity check uses
domain intuition to catch math errors.

---

#### Q2 - How do you estimate storage for a photo sharing app?

```
Instagram-scale photo storage:

Users: 1 billion registered, 500M DAU
  Each DAU: uploads 0.2 photos per day
  (Not every user uploads every day; active posters: ~20% of DAU)

Photos uploaded/day: 500M * 0.2 = 100M photos/day

Photo sizes:
  Original: 3MB (12MP smartphone photo)
  Medium thumbnail: 300KB (for feed display)
  Small thumbnail: 30KB (for grid view)
  Total per photo: 3MB + 300KB + 30KB = ~3.3MB

Storage/day: 100M * 3.3MB = 330TB/day
5 years: 330TB * 365 * 5 = ~600PB (600 petabytes)

At $0.023/GB S3 standard: $0.023 * 600M GB = $13.8M/month
S3 Glacier (infrequent access): $0.004/GB
  Most photos: accessed rarely after first week
  Lifecycle policy: move to Glacier after 30 days
  Cost: only 10% at standard prices = ~$1.4M/month

Metadata storage:
  Per photo: photo_id + user_id + caption + location + tags = ~500 bytes
  100M/day * 500 bytes = 50GB metadata/day
  5 years: 50GB * 365 * 5 = ~91TB metadata
  Storage: PostgreSQL or Cassandra (91TB over 5 years is large but manageable)
```

*What separates good from great:* The lifecycle analysis (most photos: rarely
accessed after first week) is the operational insight that reduces storage cost
dramatically. Instagram's actual storage cost optimization: aggressive tiering.
Recently uploaded: S3 Standard (low latency access). 30+ days old: S3 Infrequent
Access. 1+ year old: Glacier. The engineering effort (S3 lifecycle policies) is
minimal; the cost reduction is 80-90%. In a real design: propose this tiering
as part of the architecture. "Photos older than 30 days go to Glacier" is a
single lifecycle rule. Cost awareness is part of system design at scale.

---

#### Q3 - How do you estimate latency for a distributed system?

Latency decomposition: identifying where time is spent.

```
User request lifecycle:
  DNS resolution: 10-100ms (first hit, cached thereafter: ~1ms)
  TCP handshake: 1 * RTT (0.5ms same DC, 50ms cross-region)
  TLS handshake: 2 * RTT (additional for HTTPS)
  Load balancer: < 1ms (in same DC)
  App server processing: depends on logic
  Database query: 1-50ms (simple index lookup to complex join)
  Network to DB: 0.5ms (same DC)

Estimating a typical API call:

  Client -> CDN (150ms cross-region first visit, 5ms cached)
  CDN -> API Gateway: 0.5ms
  API Gateway -> Service: 0.5ms
  Service processing: 2ms (simple logic)
  Service -> Redis cache: 0.5ms round-trip (cache hit)
  Service -> DB (cache miss 10%): 5ms
  Response path: 0.5ms + 0.5ms

  P50 (cache hit): ~10ms end-to-end
  P99: cache miss (10%): 10ms + DB call 5ms = ~15ms
  P99 with slow DB query (1% of queries): 50ms

  Client perceives: P50 < 50ms (below human perception)
  SLO: P99 < 200ms (common web SLO)

Where latency hides:
  External API calls: add external service's latency
  Serialization: JSON serialization can add 1-5ms for large payloads
  Lock contention: if DB lock wait: adds variable latency
  GC pause (Java): P99.9 spike due to stop-the-world GC
```

*What separates good from great:* The latency budget concept: define total budget
(200ms P99), then allocate: "API gateway: 5ms, service logic: 10ms, DB: 20ms,
serialization: 5ms, network: 5ms = 45ms total P50. Reserve 155ms for outliers."
When one component consistently exceeds its budget: it's the optimization target.
Distributed tracing makes this measurable: each component reports its span duration.
The latency budget forces explicit decisions: "can we afford a synchronous external
API call (200ms) within our 200ms SLO?" Answer: only if that call is the last step
and happens in the tail (P99 only). Not on the hot path.

---

#### Q4 - How do you estimate the number of servers needed?

Server count estimation: translating QPS to infrastructure.

```
Single server capacity (rule of thumb):
  CPU-bound API (complex logic, no I/O): 1,000-5,000 RPS per server
  I/O-bound API (DB calls, external): 10,000-50,000 RPS per server
  Static content serving: 100,000+ RPS per server

Example: Video streaming service
  100M DAU, each watches 2 hours of video per day

Step 1: Data transferred per day
  2 hours video = 120 minutes
  720p = ~100MB/minute -> 12GB per user per day
  100M DAU * 12GB = 1.2 exabytes/day (too much, use CDN)
  CDN handles: 95% of video traffic
  Origin servers: serve 5% of requests (cache misses)

Step 2: Concurrent viewers
  Peak viewing: 8pm-10pm = 2 hours out of 16 active hours
  Active hours: 16 hours per day
  Peak concentration: 100M * (2 hours / 16 hours) = 12.5M concurrent viewers

Step 3: Bandwidth for concurrent viewers
  Each viewer: 720p = ~2 Mbps
  12.5M * 2 Mbps = 25 Tbps total
  CDN absorbs: 95% = ~24 Tbps
  Origin needs: 5% = ~1.25 Tbps

Step 4: Server count
  Each server: 1 Gbps network interface = 1,000 Mbps
  Origin servers for bandwidth: 1.25 Tbps / 1 Gbps = 1,250 servers
  Add 50% headroom: ~2,000 servers

  CDN: Netflix uses thousands of CDN POPs globally
  Netflix's own CDN (Open Connect): 100,000+ servers worldwide
```

*What separates good from great:* The CDN absorption calculation reveals why
video streaming is feasible: without CDN, 1.2 exabytes/day would require a
data center the size of a city. CDN distributes the load to edge servers near
users. The 95% CDN hit rate is realistic for popular content (the same popular
movies are requested by millions, and CDN caches them after the first request).
For long-tail content (obscure movies): CDN hit rate is lower (50%). The
origin server sizing (for cache misses) is the critical calculation; CDN capacity
is the CDN provider's problem (Netflix, Amazon, Google all have CDN agreements
at scale).

---

#### Q5 - Walk me through estimating for a design you've never seen before.

Estimation framework for novel systems:

```
Example: Estimate for a real-time multiplayer game (MOBA, 5v5)

Step 1: Define the events
  What data is produced?
  - Player position updates: 20 times/second per player
  - Game state updates (health, scores): 10 times/second per game
  - Input events (keystrokes, clicks): 30 times/second per player

Step 2: Define the scale
  1M concurrent players = 100K concurrent games (10 players/game)

Step 3: Calculate event rates
  Position updates: 1M players * 20/sec = 20M events/second
  Input events: 1M * 30/sec = 30M events/second
  Game state: 100K games * 10/sec = 1M events/second
  Total: ~50M events/second

Step 4: Estimate message size
  Position: player_id (8 bytes) + x,y,z (12 bytes) + timestamp (8 bytes) = 28 bytes
  50M events * 28 bytes = 1.4 GB/second = 1.4 Gbps
  With overhead: ~2 Gbps

Step 5: Server capacity
  WebSocket server: handles 50K concurrent connections, 10K events/second
  For 1M players: 1M / 50K = 20 servers (connections)
  For events: 50M / 10K = 5,000 servers (too many - re-evaluate)

  Optimization: each game server handles one game (10 players)
  Game server handles: 10 players * 30 events/sec = 300 events/sec (trivial)
  100K concurrent games: 100K game servers... (too many)
  Reality: one game server handles 100 concurrent games: 100K / 100 = 1,000 servers

  Practical: 5,000-10,000 servers for 1M concurrent (actual Riot/Valve scale)
```

*What separates good from great:* When your estimate produces an unreasonable
answer (5,000 servers per event type seems high): don't accept it. Re-examine
the assumptions. The resolution here: game servers don't process all events
as individual unit operations; they process them in batches per game loop tick.
A game loop processes all inputs for one tick, sends one unified state update.
The per-tick overhead is much lower than per-event overhead. The estimation
flagged the problem; domain knowledge (game loop architecture) provides the
resolution. The skill: follow the math, then challenge the math when it produces
an outlier.

---

#### Q6 - How does estimation change for mobile vs web?

Mobile-specific estimation factors:

```
Mobile differs from web:
  Bandwidth: 4G = ~20 Mbps, 3G = ~2 Mbps, rural = <1 Mbps
  Latency: mobile adds 50-100ms (cell tower handoff, protocol overhead)
  Connection: intermittent (users go offline, reconnect)
  Battery: minimize background processing, push over polling
  Storage: limited (100-500MB app budget)

Mobile estimation adjustments:

Request size budgets:
  Mobile: target < 50KB per API response (JSON compressed)
  Web: can tolerate larger responses (unlimited broadband)
  Implication: mobile API must paginate aggressively
                (20 items vs 100 items per page)

Concurrent connections:
  Mobile: one connection per app (not browser's 6 per domain)
  Push notifications: use APNS/FCM (not persistent WebSocket)
  WebSocket on mobile: drains battery, OS may kill connection

Offline capability:
  Storage estimation: 500MB local cache for key content
  Sync on reconnect: estimate delta sync QPS
    100M mobile users, 30-minute offline average
    Each reconnect: sync events from 30 minutes
    Peak reconnects: morning commute (8am, 30M reconnects in 15 min = 33K/second)
    Design: exponential backoff on reconnect to spread load

Data efficiency:
  Compression: gzip reduces JSON 70-80%
  Protocol: Protobuf vs JSON: 5-10x smaller
  Image: serve mobile-optimized sizes (thumbnails, not originals)
```

*What separates good from great:* The morning commute reconnect spike is a real
mobile design challenge. Users on a subway lose connectivity, emerge at a station,
and all reconnect simultaneously. A poorly designed sync endpoint: 30M clients
hit the server in 15 minutes = 33K reconnect/second. Without backoff: DDoS of
your own users. With exponential jitter (each client waits 0-5 minutes randomly):
the 33K/sec spike spreads to ~100/second over 5 minutes. AWS, Apple, Google all
publish mobile development guidelines that include this exact pattern. Estimate
reconnect spikes for mobile-first apps as part of capacity planning.

---

#### Q7 - How do you verify an estimation is reasonable?

Estimation validation: sanity-checking the numbers.

```
Sanity check methods:

1. Compare to known systems:
  "My calculation: 100K QPS for Twitter"
  Reality: Twitter handles ~500K-1M QPS
  100K is the right order of magnitude (1M DAU scale, not 100M)
  If estimating 100M DAU Twitter: expect 1M QPS

  Known benchmarks:
    Gmail: 10M+ concurrent users (2010 data)
    Facebook: 3B MAU, ~50K QPS
    Netflix: 15% of all internet traffic during prime time
    AWS S3: 100T+ objects stored

2. Check the math backward:
  Forward: 100M users * 20 reads/day / 100K sec = 20K QPS
  Backward: 20K QPS * 100K sec = 2B reads/day
             2B / 100M users = 20 reads/user/day
  Consistent: forward and backward agree

3. Check unit consistency:
  "Storage: 100M records * 1KB = 100GB"
  Units: records * (bytes/record) = bytes
  100M * 1,000 bytes = 100 * 10^9 bytes = 100GB
  Consistent

4. Apply the "does it feel right?" test:
  "500TB of video per day for YouTube"
  YouTube: 500 hours of video uploaded per minute
  500 hours/min * 60 min/hour * 24 = 720,000 hours/day
  At 1 hour = 1.5GB: 720,000 * 1.5GB = ~1 PB/day
  500TB vs 1PB: within same order of magnitude for YouTube-scale
  Reasonable estimate

5. Check against infrastructure cost:
  "60 petabytes of storage"
  S3: $0.023/GB = $0.023 * 60M GB = $1.38M/month
  Is this reasonable for a large company? Yes (comparable to AWS spending)
  Is this reasonable for a startup? No (adjust design)
```

*What separates good from great:* The backward check (compute forward, verify
backward) is the most reliable mechanical validation. If forward and backward
don't agree: there's a math error. The "known systems" comparison requires
domain knowledge that accumulates over time. The goal in interviews: show the
methodology, not recall the exact numbers. "I know Twitter is roughly at this
scale, and my estimate is consistent with that order of magnitude" demonstrates
calibration. Extreme outliers (estimate is 100x more than a known comparable
system): flag them explicitly and re-examine the assumptions.

---

# Trade-off Navigation Framework

---
id: SSD-020
title: Trade-off Navigation Framework
category: System Design
difficulty: ★☆☆
interview_weight: high
asked_at: All levels
seniority: all
tags: #trade-offs, #decision-making, #cap-theorem, #consistency, #availability
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Every system design decision is a trade-off. The framework: (1) identify the
> primary constraint (latency? consistency? availability? cost? operability?),
> (2) identify what you give up for that constraint, (3) state the condition
> under which the trade-off is acceptable. "We choose eventual consistency for
> the cart service because: cart conflicts are rare, last-write-wins is acceptable
> for user intent, and the latency improvement (local reads) is worth the
> occasional inconsistency."

**3 minutes:**
> Three categories of system design trade-offs: (1) Consistency vs Availability
> (CAP theorem: choose CP or AP for distributed systems), (2) Latency vs Throughput
> (optimize for fast response OR for high volume, not always both), (3) Cost vs
> Performance (cache everything for speed, but storage cost). The interview skill:
> don't just name trade-offs, justify them for the specific context.
>
> The anti-pattern: "it depends." "It depends" is a non-answer. The senior answer:
> "For this specific context (100M DAU, read-heavy, non-financial), I choose
> eventual consistency because: (a) read latency is more important than write
> consistency for user engagement, (b) the specific conflict scenarios are low-risk
> (stale feed vs bank balance), (c) the cache hit rate (>90%) means most reads
> never touch the DB."

**Blank Mind Recovery:**

**(1) Restate:** "Trade-off: you can't optimize everything. Every choice gains
something and gives up something else."

**(2) Framework:** "(1) What's the constraint that matters most? (2) What do we
give up? (3) Is that acceptable for this specific case?"

**(3) Examples:** "SQL vs NoSQL: consistency vs flexibility. Sync vs async:
correctness vs throughput. Cache vs no cache: speed vs freshness."

---

### 📘 Concept Explanation

**Core trade-off axes:**

```
Consistency vs Availability (CAP):
  CP (Consistent, Partition-tolerant):
    + Always returns correct data
    - May be unavailable during partition
    Use: financial systems, inventory, account balances

  AP (Available, Partition-tolerant):
    + Always available (may return stale data)
    - May return inconsistent data during partition
    Use: social feeds, user preferences, shopping cart

  Decision question: "What's worse for users - stale data or unavailability?"
    Banking: stale balance -> financial error (unavailability is better)
    Twitter: stale feed -> some tweets out of order (acceptable)

Latency vs Throughput:
  Low latency: respond quickly to each request
    + User experience
    - May limit total capacity (resources per request)
    Use: user-facing APIs, real-time features

  High throughput: process many requests per unit time
    + Capacity efficiency
    - Individual requests may be slower (batching overhead)
    Use: batch processing, analytics, background jobs

  They conflict when: to reduce latency, you parallelize (use more resources per request)
  Parallelization reduces throughput capacity for other requests

Write throughput vs Read throughput:
  Optimize for writes: write to one primary, replicate asynchronously
    + High write throughput (single primary, no sync overhead)
    - Stale reads (replication lag)
  Optimize for reads: synchronous replication to all replicas before ack
    + Always-fresh reads
    - Lower write throughput (write waits for all replicas)
  Compromise: N replicas, W writes ACK before commit, R reads
    W + R > N = consistent reads

Consistency vs Performance:
  Caching: serve stale data for speed
  Index: trade write performance for read performance
  Denormalization: trade storage + write complexity for read simplicity
```

---

### 💻 Code Example

*(Omit: Trade-off navigation is a design reasoning skill, not a code pattern. The examples below illustrate trade-offs in code decisions.)*

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Trade-offs are about what you gain and what you give up. If I add a cache, I get
> faster reads but I might serve stale data. If I shard the database, I can handle
> more data but cross-shard queries become complicated. Every system design decision
> has this structure. I try to identify what the most important requirement is
> (latency? consistency?) and optimize for that, accepting the cost.

**Senior / Staff:**
> The meta-skill in trade-off navigation: be explicit about what you're NOT
> optimizing for. "I'm choosing Cassandra for this use case because I need
> high write throughput and horizontal scaling. I'm giving up: ACID transactions,
> complex queries (JOIN), and strong consistency. The use case (time-series
> event logs) doesn't need any of those, so the trade-off is favorable. For the
> payment processing service in the same system: I choose PostgreSQL (strong
> consistency, ACID) and accept the lower write throughput. One system, two
> data stores, each chosen for the specific requirements of that service."

---

### ⚠️ Common Misconceptions

**Misconception: "There's always a right answer."**
System design questions test reasoning, not recall. The interviewer wants to see:
how you frame the problem, what trade-offs you identify, and whether your choice
is consistent with the stated requirements. Two different correct answers can
both be right if the requirements differ. "Use Redis for cache" is the right
answer if you need fast reads with acceptable staleness. "Don't cache" is the
right answer if you need always-fresh data for a medical records system. The
framework matters more than the specific choice.

---

### 🚨 Failure Modes and Diagnosis

**Failure mode: Premature optimization without stated trade-off**
Symptom: adding sharding, multiple replicas, multi-region setup for a system
that handles 100 QPS with 5 engineers.
Root cause: cargo-culting Netflix architecture without the scale to justify it.
The trade-off: operational complexity, more things to fail, harder to debug.
At 100 QPS: single PostgreSQL instance handles it. Sharding adds 10x complexity
for zero benefit.
Rule: justify every piece of complexity with a specific requirement it satisfies.
"We need sharding because our read QPS (36K) exceeds a single PostgreSQL instance's
capacity (10K)." Without that justification: simpler is better.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

#### Q1 - How do you choose between SQL and NoSQL?

```
SQL (PostgreSQL, MySQL):
  + ACID transactions (data integrity guaranteed)
  + Flexible queries (JOIN, aggregation, subqueries)
  + Strong consistency (read what you wrote)
  + Mature tooling (monitoring, backup, replication)
  - Horizontal write scaling: hard (sharding is complex)
  - Schema: must define upfront, migrations are costly
  - Vertical scaling limit: biggest DB server has limits

NoSQL (Cassandra, MongoDB, DynamoDB):
  + Horizontal scaling: designed for it (partition by key)
  + Flexible schema: add fields without migration
  + High write throughput (especially Cassandra)
  - Limited transaction support (most: single-partition only)
  - Limited query flexibility (no JOIN, must design for queries)
  - Eventual consistency (configurable, but consistency = tradeoff)

Decision framework:
  Choose SQL when:
    - Relationships between entities (users -> orders -> items)
    - Transactions required (financial, inventory)
    - Query patterns: unknown or complex
    - Data integrity is critical
    - Team is familiar with SQL

  Choose NoSQL when:
    - Known, simple access patterns (get by key, scan by partition)
    - Horizontal write scale required (millions of writes/second)
    - Schemaless data (IoT events, user activity logs)
    - Time-series data (Cassandra, InfluxDB)
    - Specific NoSQL strength matches the use case

  "Can I use both?" Yes:
    User accounts: PostgreSQL (ACID, relationships)
    User activity log: Cassandra (write-heavy, time-series)
    Product search: Elasticsearch (full-text, facets)
    Session cache: Redis (fast read/write, TTL)
```

*What separates good from great:* The "choose both" answer is the production
reality. Large systems use multiple data stores, each chosen for its fit to
a specific access pattern. The anti-pattern: using the same data store for all
purposes. MongoDB for everything: acceptable for small scale, problematic when
you need transactions (payments), full-text search (product catalog), and
time-series data (event logs) - MongoDB is mediocre for all three, excellent
for none.

---

#### Q2 - When should you use synchronous vs asynchronous communication?

```
Synchronous (request-response):
  Caller: sends request, waits for response
  + Simple to reason about (request -> response -> done)
  + Immediate feedback (errors visible immediately)
  - Tight coupling (if service B is slow: service A is slow)
  - Cascading failures (B down: A returns error)

Asynchronous (message queue):
  Caller: sends message to queue, continues
  Consumer: processes message later
  + Decoupled (A doesn't wait for B)
  + Resilient (B can be down; messages queue up)
  + Throughput (A can send faster than B processes)
  - Complex (dead letter queues, idempotency, ordering)
  - Delayed feedback (B's result not immediately visible to A)
  - Eventually consistent (A can't immediately read B's result)

Decision framework:
  Use synchronous when:
    - User is waiting for the result (checkout must confirm payment)
    - Response needed immediately for next step
    - Error handling is simple (if fails: show error to user)
    - Operation is fast (< 1 second)

  Use asynchronous when:
    - Operation is slow (send email, generate PDF)
    - Result not needed immediately (notify user later)
    - High throughput needed (batch processing, event ingestion)
    - Services need decoupling (independent scaling, deployment)
    - Fire-and-forget acceptable (log event, trigger analytics)

  Hybrid pattern:
    Checkout: synchronous payment (user waits for confirmation)
              asynchronous email receipt (user doesn't wait)
              asynchronous inventory update (best-effort)
    Different steps have different consistency requirements
```

*What separates good from great:* The hybrid pattern is the practical production
approach. Identify per-operation: "does the user need this result NOW?" Payment:
yes (must confirm charge before showing "order confirmed"). Email receipt: no
(send within 30 seconds is fine). Inventory update for analytics: no (batch
update hourly is fine). This classification drives the architecture: synchronous
for the critical path, async for everything else. The critical path is as short
as possible (fewer synchronous dependencies = fewer failure points).

---

#### Q3 - How do you decide whether to cache data?

```
Caching decision framework:

Cache when:
  1. Data is read far more often than written (read/write ratio > 10:1)
  2. Data is expensive to compute (DB join, external API call)
  3. Staleness is acceptable (preferences, catalog, static data)
  4. Cache hit rate will be high (popular data, not long-tail)

Don't cache when:
  1. Data changes frequently and freshness is critical
     (current bank balance, live stock price, seat availability)
  2. Data is user-specific with unique patterns (each user reads only their data)
     (personalized data: cache for this user, wasted for others)
  3. Data volume > cache capacity with low hit rate
     (caching 1TB of rarely accessed data is just an expensive database)
  4. Write-heavy data (invalidation overhead > read benefit)

Cache invalidation strategies:
  TTL-based: cache expires after N seconds (simple, stale risk)
  Write-through: update cache on every write (fresh, write overhead)
  Write-behind: update cache, async persist to DB (fast writes, durability risk)
  Invalidation on write: delete cache entry on write (lazy re-population)

Common caching mistakes:
  Cache the wrong layer: caching DB result when the DB query is the bottleneck
  Too long TTL: stale data causes bugs (price changes, permissions changes)
  Cache stampede: TTL expires for popular key, 1000 requests simultaneously hit DB
    Fix: probabilistic early expiration (renew before expiry, not after)
         or distributed lock on cache miss (only one request rebuilds)
```

*What separates good from great:* Cache stampede is the most commonly overlooked
caching failure mode. A popular cached item (product details for a viral product)
expires. At the moment of expiry: 10,000 requests per second all see a cache miss
simultaneously. All 10,000 hit the database. Database overloads. The product stays
uncached (DB errors). Cycle repeats. Fix: "jittered TTL" - instead of exact TTL,
use TTL + random(0, 30 seconds). Different cache items expire at different times.
Or: "cache lock on miss" - first request takes a lock, queries DB, updates cache;
subsequent requests wait for the lock (or return stale value if available).

---

#### Q4 - How do you balance operational simplicity vs performance optimization?

```
Operational complexity cost:
  Each optimization: adds code complexity, infrastructure complexity, or both
  Code complexity: harder to debug, more failure modes, longer onboarding
  Infrastructure complexity: more systems to monitor, more things to fail

The 80/20 rule for optimization:
  80% of performance gain comes from 20% of optimizations
  First optimizations: easy, high-impact (add index, add cache, use CDN)
  Marginal optimizations: complex, low-impact (custom sharding, write-ahead cache)

Decision framework:
  Question: "What is the cost of NOT doing this optimization?"
    - Current system handles load? Don't optimize yet
    - Current system at 80% capacity? Plan the optimization
    - Current system at 100% capacity? Optimize now

  Prioritize simplicity at:
    - Early stage (unknowns are high, requirements change)
    - Low traffic (< 10K QPS: one PostgreSQL is fine)
    - Small team (operational complexity has higher cost with fewer people)

  Accept complexity at:
    - High traffic where simple won't scale
    - SLO requires it (P99 < 50ms: cache required)
    - Cost reduction significant (reduce AWS bill 50% with specific optimization)

YAGNI (You Ain't Gonna Need It):
  Don't add distributed caching for a 100 QPS system
  Don't add message queues for a 3-step workflow
  Don't add microservices for a 5-person team
  Add complexity when the simplest solution clearly fails
```

*What separates good from great:* "Start simple, add complexity as needed" is
the principle, but it requires the discipline to remove complexity when it's no
longer needed. Many systems accumulate optimization layers for past traffic levels:
a cache that was needed at 10K QPS but the traffic dropped to 1K (feature pivoted).
The cache remains: adding operational overhead for no benefit. Regular architectural
reviews: "is each complexity layer still earning its keep?" Removing unnecessary
complexity improves reliability (fewer things to fail) and developer velocity
(simpler systems are easier to modify).

---

#### Q5 - How do you evaluate the cost trade-off in a system design?

```
Cost dimensions in system design:
  Compute: CPU (EC2 instance hours, EKS worker nodes)
  Storage: S3, EBS, RDS storage
  Network: inter-AZ, inter-region data transfer
  Managed services: SQS, DynamoDB, ElasticSearch (per request/storage)
  Operational cost: engineering time to maintain

Cost vs performance trade-off:

Example: "Should we cache in Redis or increase DB instances?"
  More DB instances:
    Cost: $0.10/hour * 5 replicas = $0.50/hour = $360/month
    Benefit: 5x read capacity
    Operationally: simple (one system)

  Redis cache:
    Cost: r6g.large = $0.151/hour * 2 (HA pair) = ~$220/month
    Benefit: 10x read capacity (cache hit rate 90%)
    Operationally: additional system to maintain

  Redis is cheaper AND faster AND reduces DB load
  Decision: Redis (performance + cost wins)

  Counter-example: "Should we use DynamoDB global tables vs PostgreSQL replicas?"
    PostgreSQL replicas: $0.50/hour for 3 replicas = $360/month
    DynamoDB global tables: $1.25/million reads + $1.25/million writes
      At 10M reads/day: $12.5/day = $375/month (similar cost)
    DynamoDB: adds multi-region capability + managed replication
    PostgreSQL: more operational control, complex replication management
    Decision: DynamoDB if multi-region is needed; PostgreSQL if single-region sufficient

Serverless vs always-on:
  Lambda: $0.20 per 1M requests + $0.00001667 per GB-second
  EC2: $0.10/hour always on
  Lambda cheaper if: traffic < 1 req/second average
  EC2 cheaper if: traffic > 1 req/second average (constant load)
  Lambda also: no idle cost, auto-scale to zero
```

*What separates good from great:* Cost is a first-class design constraint at
companies beyond early-stage startups. Mentioning cost trade-offs proactively
in an interview shows engineering maturity. The principle: expensive resources
(compute, storage) should have utilization > 60%. Below 60%: over-provisioned
(cost waste). Above 80%: risk of saturation. The target: 60-80% average utilization
with autoscaling to handle spikes. AWS Cost Explorer and right-sizing recommendations
are the operational tools. The engineering discipline: treat cost as a metric
with an SLO ("infrastructure cost per user per month < $X").

---

#### Q6 - How do you trade off between build vs buy?

Build vs buy: make or use an existing solution.

```
Buy (use a managed service or open-source library):
  + Faster time to market (not reinventing the wheel)
  + Someone else handles: maintenance, security patches, scaling
  + Battle-tested (used by others, bugs found and fixed)
  - Cost: managed services have ongoing fees
  - Less control: can't modify internals for specific needs
  - Vendor lock-in: hard to switch away

Build:
  + Full control and customization
  + No vendor lock-in
  + Can optimize for exact use case
  - Time cost: significant engineering investment
  - Maintenance: your team owns it forever
  - Risk: bugs, security vulnerabilities are yours to fix

Decision framework:
  Buy when:
    - Problem is solved well by existing solutions
    - Your competitive advantage is elsewhere (not in this infrastructure)
    - Team doesn't have expertise in this domain
    - Time-to-market matters

  Build when:
    - Existing solutions don't meet specific requirements
    - This capability IS your competitive advantage
    - Vendor pricing is prohibitive at scale
    - You need control for compliance/security

Real examples:
  Authentication: Buy (Auth0, Cognito) vs Build (custom OIDC)
    -> Usually buy: security is complex, Auth0 is the safer choice
  Payment processing: Buy (Stripe, Braintree) vs Build
    -> Always buy for small/medium: PCI compliance alone justifies it
  Message queue: Buy (SQS, Confluent Kafka) vs Build/Self-host (Kafka)
    -> SQS: simple use cases. Self-host Kafka: high throughput, need full control
  Search: Buy (Elasticsearch managed, Algolia) vs Build
    -> Algolia: great UX, expensive at scale. Self-host ES: complex, full control

```

*What separates good from great:* The Netflix paradox: Netflix builds much of
its own infrastructure (Open Connect CDN, Hystrix circuit breaker, Eureka service
discovery, Chaos Monkey) because at their scale: AWS services don't meet the
specific requirements, and the cost of managed services is prohibitive. For a
100-person startup: the opposite is true. Buy everything, build only what's
your unique competitive advantage. The build vs buy decision shifts as scale
increases and as the product's unique requirements become clearer. Early stage:
buy everything. Growth stage: selectively build when vendor capabilities are
insufficient or too expensive.

---

#### Q7 - Walk me through a complete trade-off analysis for designing a notification system.

Notification system trade-off analysis:

```
Requirements:
  Send notifications: email, SMS, push (mobile)
  100M users, 10M notifications/day
  Types: transactional (payment confirmed), marketing (promo email)
  Latency SLO: transactional < 10 seconds, marketing < 1 hour

Trade-off 1: Single queue vs separate queues
  Option A: one queue for all notifications
    + Simple: one consumer, one codebase
    - Marketing emails block transactional if consumer is slow
    - Can't apply different rate limits (SMS: 1/sec, email: 100/sec)

  Option B: separate queues per channel + priority
    + Isolation: marketing delays don't affect transactional
    + Different consumers, different rate limits per provider
    - More queues to manage, more consumers to maintain

  Decision: separate queues. Transactional and marketing must be isolated.
  Transactional consumer: high priority, low latency processing
  Marketing consumer: batch processing, rate-limited

Trade-off 2: Delivery guarantee - at-least-once vs exactly-once
  At-least-once: guarantee delivery, risk duplicate
    Implementation: simple (retry until ACK from provider)
    User impact: duplicate email ("Your order was confirmed" x2)

  Exactly-once: prevent duplicate, more complex
    Implementation: idempotency key + deduplication window
    User impact: no duplicate

  Decision: exactly-once with idempotency
    Transactional: users complain about duplicate "your card was charged"
    Marketing: duplicates are annoying but tolerable
    Implement: notification_id in the event + deduplication table
    Provider idempotency: SendGrid, Twilio both support idempotency keys

Trade-off 3: User preference store - relational vs key-value
  Relational: full preference model (per-category, per-channel, per-frequency)
  Key-value: simple {user_id: {email: true, sms: false, push: true}}

  Decision: key-value (Redis or DynamoDB)
    Preference lookup is on the hot path: every notification
    100M users * frequent lookups: need O(1) lookup, not SQL join
    Preference schema: can be stored as JSON in DynamoDB
    Flexibility for future schema changes: add fields without migration

Summary trade-offs made:
  Separate queues: operationally complex, but isolation is non-negotiable
  At-least-once with deduplication: best UX, slightly more complex
  Key-value for preferences: fast lookups, flexible schema
```

*What separates good from great:* The structured trade-off analysis per design
decision is the format that impresses interviewers. Not "here's my design" but
"here are the options, here are the trade-offs for each option, here's which
I chose and why for this specific context." This demonstrates that you understand
the design space, not just one solution. Each decision references the stated
requirements: "transactional < 10 seconds" drives the separate-queue decision.
"Users complain about duplicate charges" drives the exactly-once decision.
Requirements justify trade-offs.

---

# Failure Mode Thinking

---
id: SSD-021
title: Failure Mode Thinking
category: System Design
difficulty: ★☆☆
interview_weight: high
asked_at: All levels
seniority: all
tags: #failure-modes, #resilience, #fault-tolerance, #chaos-engineering, #defense-in-depth
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Failure mode thinking: systematically identify how each component can fail and
> design the response. The framework: (1) What can fail? (hardware, network, software,
> human error) (2) When it fails, what does the user see? (3) How do we detect it?
> (4) How do we recover? (5) How do we prevent it? Every dependency is a potential
> failure. Design for the assumption that every dependency WILL fail, and the system
> must degrade gracefully.

**3 minutes:**
> The reliability engineering principle: design assuming failure, not hoping for
> success. If your system has 10 components each with 99% reliability:
> 0.99^10 = 90% system reliability. 10% downtime = 36 days/year. Solution: each
> component must be redundant (fail any one, system continues).
>
> Failure categories: (1) hardware (server crash, disk failure), (2) network
> (packet loss, partition, slowdown), (3) software (bug, memory leak, deadlock),
> (4) dependency (downstream service slow or down), (5) human error (wrong config,
> accidental deletion). Each category needs different mitigations.
>
> The response menu: retry with backoff (transient errors), circuit breaker (persistent
> downstream failures), timeout (prevent indefinite blocking), fallback (serve
> degraded but available), bulkhead (isolate failures, prevent cascade).

**Blank Mind Recovery:**

**(1) Restate:** "Failure mode thinking: list everything that can go wrong, then
design what happens when it does."

**(2) Framework:** "(1) What can fail? (2) What does the user see? (3) How do we
detect? (4) How do we recover?"

**(3) Key patterns:** "Retry: transient errors. Circuit breaker: persistent failures.
Timeout: prevent blocking. Fallback: degrade gracefully. Bulkhead: isolate failures."

---

### 📘 Concept Explanation

**Failure mode catalog:**

```
Hardware failures:
  Server crash: instance terminates unexpectedly
  Disk failure: data loss or corruption
  Memory error: bit flip (ECC RAM mitigates but doesn't eliminate)
  Mitigation:
    Redundant instances (multiple pods, auto-healing K8s)
    Disk redundancy (RAID, EBS replication)
    Regular backups + tested restore procedures

Network failures:
  Packet loss: network congestion, flaky links
  Network partition: two parts of network can't communicate
  High latency: congestion, routing issues
  DNS failure: DNS resolver down, expired TTL
  Mitigation:
    Retry with exponential backoff (packet loss)
    Circuit breaker (partition)
    Timeouts (high latency)
    Multiple DNS resolvers

Software failures:
  Application bug: unhandled exception, logic error
  Memory leak: OOM kill, gradual performance degradation
  Deadlock: threads waiting forever
  Infinite loop: CPU spike, unresponsive
  Mitigation:
    Crash recovery (supervisor process, K8s restart policy)
    Liveness probes (detect frozen pods, restart them)
    Memory limits (force OOM before system exhaustion)
    Load testing (catch memory leaks before production)

Dependency failures:
  Downstream slow: response time spikes
  Downstream down: returns errors or times out
  Downstream overloaded: returns 503 or drops connections
  Mitigation:
    Timeout + retry (slow responses)
    Circuit breaker (persistent failures)
    Fallback response (serve cached or degraded data)

Human errors:
  Config mistake: wrong flag, wrong value
  Deployment bug: new version with breaking change
  Accidental data deletion: DROP TABLE in production
  Mitigation:
    Config validation (pre-commit checks, CI validation)
    Canary deployments (catch bugs with small traffic before full rollout)
    Backup + restore + point-in-time recovery for databases
    Delete confirmation + soft delete patterns
```

---

### 💻 Code Example

```java
// Resilience4j: circuit breaker + retry + timeout + fallback
@Service
public class ProductService {

    private final ExternalInventoryClient inventory;

    @CircuitBreaker(name = "inventory-service",
                   fallbackMethod = "getInventoryFallback")
    @Retry(name = "inventory-service")
    @TimeLimiter(name = "inventory-service")
    public CompletableFuture<InventoryStatus> getInventory(
            String productId) {
        return CompletableFuture.supplyAsync(() ->
            inventory.getStock(productId));
    }

    // Fallback: called when circuit is OPEN or retries exhausted
    public CompletableFuture<InventoryStatus> getInventoryFallback(
            String productId, Throwable t) {
        log.warn("Inventory fallback for product {}: {}",
            productId, t.getMessage());
        // Return: "unknown" status (show product, don't show stock count)
        return CompletableFuture.completedFuture(
            InventoryStatus.unknown());
    }
}
```

```
# application.yml: Resilience4j config
resilience4j:
  circuitbreaker:
    instances:
      inventory-service:
        failure-rate-threshold: 50   # open at 50% failure
        slow-call-rate-threshold: 50 # open if 50% calls > threshold
        slow-call-duration-threshold: 2s
        wait-duration-in-open-state: 30s
        permitted-number-of-calls-in-half-open-state: 5
  retry:
    instances:
      inventory-service:
        max-attempts: 3
        wait-duration: 500ms
        retry-on-result-predicate: ...
        retry-exceptions:
          - java.io.IOException
          - java.util.concurrent.TimeoutException
        ignore-exceptions:
          - com.example.ClientException  # 4xx: don't retry
  timelimiter:
    instances:
      inventory-service:
        timeout-duration: 3s
```

> **Code walkthrough:** Resilience4j applies four layers of resilience to the
> inventory service call. TimeLimiter: fail fast after 3 seconds (prevents thread
> blocking). Retry: up to 3 attempts on transient failures (IOException, timeout);
> ignores 4xx client errors (retrying a 400 is pointless). CircuitBreaker: opens
> if failure rate > 50% over a sliding window; stays open 30 seconds (gives
> downstream time to recover). Fallback: returns "unknown" inventory status when
> the circuit is open or retries exhausted. The product page still renders; it
> just shows "availability unknown" instead of a stock count. Degraded but
> available = correct behavior when inventory service is down.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Failure mode thinking means assuming things will go wrong and planning for it.
> Instead of "the database will always be available," I think "what happens when
> the database is unavailable for 30 seconds?" Then I design: retry, cache the
> last-known response, show an error with a retry button. The goal is that a single
> component failure doesn't cause the entire system to fail.

**Senior / Staff:**
> The failure modes I always design for explicitly: (1) the dependency that was
> "always available" during development is slow in production. Timeout is the
> defensive answer (never wait more than X seconds for any dependency). (2) A
> new deployment with a bug that only manifests under production load. Circuit
> breaker + canary deployment catches this. (3) The gradual memory leak that
> makes the service slower over hours. Liveness probe + restart policy handles it.
> The senior practice: for each external dependency call in code review, ask
> "what happens when this is slow? What happens when it returns an error?" If the
> answer is "the caller's thread blocks indefinitely" or "unhandled exception
> crashes the service" - that's a required fix before merge.

---

### ⚠️ Common Misconceptions

**Misconception: "We have 99.9% uptime from our cloud provider, so we have 99.9% reliability."**
Cloud provider uptime is the availability of the physical infrastructure, not
your application. Your application can be down while the infrastructure is up
(app bug, OOM, misconfigured health check, DB schema migration). Application
reliability = probability that all components (app, DB, cache, dependencies)
are working correctly. With 10 components at 99.9% each: 99.9%^10 = 99%.
Cloud SLAs also don't cover all failure modes: AZ outages, service degradation,
API rate limits. Design for failure at the application layer; don't rely on
cloud SLAs for application-level reliability.

---

### 🚨 Failure Modes and Diagnosis

**Failure mode: cascading failure from downstream timeout**
Symptom: ServiceA is slow or down. Investigation: ServiceA is slow because it's
waiting on ServiceB, which is slow because it's waiting on ServiceC, which has
a slow query. The slowness propagates backward: ServiceC slow -> ServiceB queues
up calls -> threads exhausted -> ServiceA queues up calls -> threads exhausted
-> frontend times out.
Diagnosis: distributed trace shows which component has the first timeout.
Prevention: timeout + circuit breaker at every service boundary. ServiceA: fails
fast after 3 seconds to ServiceB (doesn't wait 30 seconds). ServiceB: fails fast
to ServiceC. Cascade stops at the first circuit breaker.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

#### Q1 - How do you design for partial failure?

Partial failure: some services work, others don't.

```
Scenario: e-commerce product page
  Components: product details, reviews, recommendations, inventory status
  Failure: recommendation service down

Naive design (tight coupling):
  Product page: calls all 4 services synchronously
  Recommendation service down: product page returns 500
  Users: can't view ANY products
  Root cause: one non-critical service brings down the entire page

Partial failure tolerant design:
  Priority tiers:
    Critical: product details, price (required for page to load)
    Non-critical: reviews, recommendations, inventory status

  Execution:
    Critical: synchronous call, hard requirement
    Non-critical: asynchronous calls with timeout + fallback

  Product page render:
    product-details: required (if fails: return 404)
    recommendations: optional (if fails: render "You may also like" section
                               with fallback (show top sellers)
    reviews: optional (if fails: hide review section, show "reviews unavailable")
    inventory: optional (if fails: show "check availability" button)

  User sees:
    Product details: always shown
    Recommendations: may show generic recommendations
    Reviews: may be hidden
    Inventory: may show generic "check availability"

  User does NOT see: error page from recommendation service failure
```

*What separates good from great:* Degraded responses require explicit design
for each non-critical component. "If reviews service is unavailable: show reviews
section as empty with 'Reviews are loading'" is better than silently hiding the
section (users wonder if there are no reviews) or showing an error. The fallback
UX is a product decision, not just an engineering decision. Engineers and product
managers should jointly define: "what does the user see when X is unavailable?"
Document these fallback states in the product spec, implement them in code,
test them explicitly (turn off each service, verify correct degraded behavior).

---

#### Q2 - How do you implement timeout and retry correctly?

Timeout and retry: the most common resilience mechanisms.

```
Timeout: fail fast if dependency is too slow
  Without timeout: thread blocked indefinitely
  Thread pool exhausted: service can't accept new requests
  Result: service down because downstream is slow

  Timeout value selection:
    Too short: false positives (legitimate slow requests fail)
    Too long: not protective (threads blocked too long)
    Rule: P99 latency of dependency * 2-3x
    If dependency P99 = 100ms: set timeout at 200-300ms
    If dependency P99 = 500ms: set timeout at 1-1.5 seconds

Retry: try again on transient failure
  When to retry:
    YES: network timeout, transient server error (503), connection reset
    NO: client error (400 bad request, 401 unauthorized, 404 not found)
         (retrying a 400: the request won't magically become valid)
    NO: non-idempotent operations without idempotency key
         (POST /orders: retrying may create duplicate orders)

  Retry configuration:
    Max attempts: 3 (don't retry forever)
    Initial delay: 100ms
    Backoff: exponential (200ms, 400ms)
    Jitter: +/- 50ms (prevents thundering herd)
    Total max wait: ~1 second (3 attempts with backoff)

  Retry with idempotency:
    POST /orders with Idempotency-Key: {uuid}
    Server: if same key used twice: return same response (not duplicate)
    Client: can safely retry with same key

  Combination:
    Timeout(500ms) + Retry(3, exponential) + CircuitBreaker
    Total max time: ~3 seconds (3 * 500ms * 2 backoff) before circuit opens
```

*What separates good from great:* The combination of timeout AND retry requires
careful math. If timeout = 3 seconds and retry = 3 attempts: one failed request
could block a thread for 9 seconds before giving up. With circuit breaker: after
the circuit opens, subsequent calls fail immediately (no timeout wait). The
engineering discipline: explicitly calculate "worst case: how long does one failed
request take?" and ensure it fits within the caller's SLO. If checkout service
SLO is 5 seconds and payment call can take 9 seconds (3 retries * 3s timeout):
checkout will always breach its SLO when payment is down. Reduce timeout + retry
budget to fit within the caller's SLO.

---

#### Q3 - What is a bulkhead pattern and when do you use it?

Bulkhead: isolate failures to prevent cascade.

```
Problem without bulkhead:
  Service: one shared thread pool (200 threads)
  Payment service: slow (3 seconds per call)
  Payment calls: use 180/200 threads
  Other operations (product search, user lookup): wait for threads
  Payment slowness: starves all other operations

Bulkhead pattern:
  Separate thread pools per dependency:
    Payment-service pool: 50 threads (max)
    Inventory-service pool: 50 threads (max)
    Default pool: 100 threads (for everything else)

  Payment service slow: uses all 50 payment threads
  Other services: unaffected (use their own pools)
  Blast radius: contained to payment-related calls

  Resilience4j Bulkhead:
    @Bulkhead(name = "payment-service",
              type = Bulkhead.Type.THREADPOOL)
    public CompletableFuture<PaymentResult> processPayment(...) {
        ...
    }

    resilience4j:
      thread-pool-bulkhead:
        instances:
          payment-service:
            maxThreadPoolSize: 50
            coreThreadPoolSize: 20
            queueCapacity: 100

When to use:
  You have multiple types of dependencies with different performance profiles
  One slow dependency should NOT impact others
  High-volume + mixed critical/non-critical operations

When NOT to use:
  Single responsibility: service calls only one downstream
  Simple system: overhead not worth it
```

*What separates good from great:* The bulkhead sizing is a capacity planning
exercise. "50 threads for payment service" is the correct choice only if: max
concurrent payment calls < 50 (otherwise you'll queue/reject legitimate requests).
Calculate: payment QPS * average payment latency = concurrent calls.
10 QPS * 500ms = 5 concurrent payment calls normally. 50 thread pool: 10x headroom
for spikes. 500 QPS during sale: 500ms * 500ms = 250 concurrent. Bulkhead of 50
is too small for peak. Adjust: 300 thread pool for payment during peak. This
sizing exercise should be done per dependency based on actual traffic patterns.

---

#### Q4 - How do you approach chaos engineering?

Chaos engineering: deliberately break things to find failure modes.

```
Chaos engineering principles:
  Run experiments in production (controlled)
  Validate: hypothesis "the system handles this failure gracefully"
  Find: weakness before users do

Netflix Simian Army (original chaos tools):
  Chaos Monkey: randomly terminates EC2 instances
  Chaos Gorilla: terminates an entire availability zone
  Latency Monkey: injects latency into network calls
  Conformity Monkey: finds instances not following best practices

Chaos experiment template:
  1. Hypothesis: "If Redis goes down, product pages still serve from DB with
     acceptable latency (<500ms P99)"
  2. Steady state: define "normal" metrics (P99 200ms, error rate <0.1%)
  3. Inject failure: stop Redis, monitor for 5 minutes
  4. Observe: did error rate spike? Did latency exceed 500ms?
  5. Rollback: restart Redis
  6. Analysis: did hypothesis hold? What failed unexpectedly?
  7. Fix: address any unexpected behaviors

Start small:
  Phase 1: lower environments (staging/pre-prod)
  Phase 2: canary (5% of production pods)
  Phase 3: full production (with runbook + on-call ready)

Common first experiments:
  Kill one pod (should auto-restart, no user impact)
  Kill one dependency (circuit breaker should protect)
  Add 100ms latency to DB (should stay within SLO)
  Fill disk to 90% (should alert, not crash)
```

*What separates good from great:* The hypothesis-driven approach is what separates
chaos engineering from random destruction. "I believe this system handles X failure"
is the hypothesis. The experiment validates or invalidates it. Without a hypothesis:
chaos experiments find failure modes but don't teach you anything beyond "it broke."
With a hypothesis: the experiment either confirms resilience (good) or reveals a
gap in the hypothesis (a failure path you hadn't considered). Netflix's chaos
engineering culture: failures in production are expected and used as learning
opportunities. The goal isn't zero failures; it's ensuring failures are handled
gracefully and learned from systematically.

---

#### Q5 - How do you detect failures before users report them?

Proactive monitoring: finding failures before users notice.

```
Alert pyramid:
  User-facing metrics (most important):
    Error rate > 0.1% (real user errors)
    P99 latency > SLO (real user slowness)
    Availability < 99.9%
    Alert: immediate page to on-call

  Infrastructure metrics:
    CPU > 80% for 5 minutes
    Memory > 85%
    Disk > 90%
    DB connections > 80% of max
    Alert: warning, investigate during business hours

  Pre-failure indicators:
    Memory leak: memory growing 1% per hour (will OOM in 100 hours)
    Disk growing faster than expected (will fill in 48 hours)
    Error rate trending up (not yet at alert threshold but increasing)
    Alert: inform, plan remediation

Synthetic monitoring:
  Scheduled probe: make a real API call every minute
  Verify: successful response, correct data, within latency SLO
  Alert: if probe fails (before real users hit the issue)
  Tools: AWS CloudWatch Canaries, Pingdom, Datadog Synthetics

Anomaly detection:
  Normal pattern: Monday-Friday traffic, daily peaks at 9am
  Anomaly: Saturday 3am traffic spike (bot attack? data pipeline error?)
  Alert: traffic 3x above expected for this time

Distributed tracing alerts:
  P99 trace shows: DB query taking 2 seconds (was 50ms yesterday)
  Alert: slow DB query (before user-facing latency breach)
  Diagnosis: check EXPLAIN ANALYZE, identify missing index
```

*What separates good from great:* Synthetic monitoring (proactive probes) catches
failure modes that metrics miss. A service can have 0% error rate from real users
(no users hitting it) while being completely broken. Synthetic monitoring probes
the service even when there are no real users (off-peak, after a deployment).
The probe exercises the critical path: login -> get product -> add to cart -> checkout.
If any step fails: alert fires. The probe is the first "user" after every deployment.
Failure in synthetic monitoring = deployment issue, not a real-user issue.
This prevents deploying broken code to users.

---

#### Q6 - What is defense-in-depth for system reliability?

Defense-in-depth: multiple independent layers of protection.

```
Principle: no single layer is infallible
  If layer 1 fails: layer 2 catches it
  Multiple independent layers: very low probability all fail simultaneously

Example: Preventing data loss for order database

Layer 1: RAID/EBS replication (disk level)
  OS-level protection against disk hardware failure
  EBS: automatically replicates within AZ (behind the scenes)
  Recovery: transparent (no data loss, no action needed)

Layer 2: DB replication (synchronous standby)
  PostgreSQL streaming replication to standby in same region
  Primary fails: promote standby (seconds to minutes)
  Recovery: change connection string, RDS Multi-AZ: automatic

Layer 3: Automated backups (daily snapshots)
  Daily EBS snapshot to S3
  Point-in-time recovery: restore to any second in the last 35 days
  Recovery: hours (restore new DB from snapshot)

Layer 4: Cross-region backup
  S3 Cross-Region Replication: copies backups to another region
  Primary region destroyed (hurricane, datacenter fire): recover from other region
  Recovery: hours to days

Layer 5: Application-level audit log
  Every order write: append to immutable audit log (separate Kinesis + S3)
  Audit log: independent of DB (separate system)
  Recovery: reconstruct DB from audit log (complex, last resort)

Production incident:
  Developer: accidentally DELETE FROM orders (human error)
  Layer 1-2: no help (the DELETE was a valid DB operation)
  Layer 3: restore to 5 minutes before DELETE (PITR)
  RTO: 30 minutes. RPO: 5 minutes (5 minutes of orders re-entered or recovered from Layer 5)
```

*What separates good from great:* The DELETE FROM orders scenario is a real
production incident that has happened at numerous companies. The postmortem
lesson: PITR (Point-In-Time Recovery) is the safety net for human errors.
AWS RDS PITR: restore to any second in the last 35 days. The procedure:
(1) identify the timestamp just before the accidental deletion, (2) restore
to a new DB instance at that timestamp, (3) extract the lost data, (4) insert
into production DB. RTO: 30-60 minutes. The prevention: soft deletes (mark
records as deleted, don't physically DELETE), database access controls (app user
has no DELETE permission, only admin service accounts), SQL review gates in
deployment pipelines (flag any DDL/DML that affects row counts significantly).

---

#### Q7 - How do you design for graceful degradation?

Graceful degradation: maintain partial functionality when a component fails.

```
Degradation tiers:
  Tier 1 (full functionality): all features work
  Tier 2 (degraded): non-critical features off, core works
  Tier 3 (minimal): only the most critical feature works
  Tier 4 (offline): show maintenance page, queue requests

Example: music streaming service

Tier 1 (normal):
  Stream music, search songs, recommendations, social features, offline sync

Tier 2 (music-service fine, recommendation-service down):
  Stream music: YES (core)
  Search: YES (core)
  Recommendations: NO -> show "Popular songs" (cached fallback)
  Social: NO -> hide social panel
  Offline sync: YES (background process)

Tier 3 (music-service partially degraded):
  Stream music: YES (most important)
  Search: cached results only (may be slightly stale)
  Recommendations: NO
  New features (upload, sharing): NO

Tier 4 (music-service down):
  Maintenance page: "We're experiencing issues. Your music will be back soon."
  Offline cache: if app has cached songs, play from local cache
  Queue: user actions (playlist changes) queued, synced when back

Implementation:
  Feature flags: can disable features per-flag (LaunchDarkly, Unleash)
  On failure: set flag to "disabled" automatically (circuit breaker drives flag)
  User impact: targeted ("recommendations are temporarily unavailable")
  Engineering: clear ownership per degradation mode
```

*What separates good from great:* Graceful degradation requires product + engineering
alignment on "what is the minimum viable experience?" For Spotify: playing music
is non-negotiable. Everything else (recommendations, social, discovery): nice to have.
This hierarchy drives technical decisions: music streaming is on a separate, highly
isolated service from recommendations. Recommendation service failure: never touches
music streaming infrastructure. The separation is both organizational (different teams)
and technical (different services, different data stores). The degradation tier model
is documented, tested in chaos experiments, and known by the on-call team. When
paged at 2am: the on-call knows "if recommendation service is down: users still stream,
set this feature flag, acknowledge the alert, fix in the morning."
