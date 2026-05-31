---
layout: default
title: "System Design - L5 Architecture"
parent: "System Design"
grand_parent: "SK Interview"
nav_order: 10
permalink: /system-design/l5-architecture/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [System Design - L5 Architecture](#system-design---l5-architecture) | medium |
| 2 | [Multi-Region Active-Active Architecture](#multi-region-active-active-architecture) | medium |

---

# Multi-Region Active-Active Architecture

---
id: SSD-018
title: Multi-Region Active-Active Architecture
category: System Design
difficulty: ★★★
interview_weight: high
asked_at: Staff/Principal
seniority: principal
tags: #multi-region, #active-active, #global-distribution, #geo-routing, #conflict-resolution
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Active-active multi-region: all regions actively serve traffic (no standby region
> waiting). Traffic is geo-routed to the nearest region (Anycast DNS, CDN). Data
> is replicated asynchronously across regions. Challenges: write conflicts (same
> record updated in two regions simultaneously), cross-region latency, and split-brain
> (network partition isolating regions). Solutions: CRDTs or last-write-wins for
> conflict-free data; global transaction coordinator (expensive) for consistency.
> Cost: significantly higher than single-region. Use only when: global user base
> requiring low latency, and RTO < 5 minutes.

**3 minutes:**
> Active-active contrasts with active-passive (one primary region, one standby
> region). Active-passive: lower complexity, but the standby region does nothing
> until failover (wasted capacity). Failover takes minutes (DNS TTL, health check
> propagation). Active-active: both regions serve traffic, reducing latency for
> users near each region. But: every write must be replicated, and writes to the
> same record from two regions create conflicts.
>
> Conflict strategies: (1) Last-Write-Wins (LWW): timestamp-based, simple, loses
> concurrent writes. (2) CRDTs: data structures that merge without conflicts
> (counters, sets, maps). (3) Operational Transformation: merge concurrent edits
> (Google Docs). (4) Global transaction coordinator: single source of truth,
> negates active-active performance benefits. For e-commerce: user cart is a CRDT
> (add-only set); order creation uses a global coordinator (exactly-once guarantee).
>
> DNS routing: Anycast routes users to the nearest POP. Route53 latency routing
> or geolocation routing: region selection per user request. Health checks: if
> region fails, DNS routes around it within 60-120 seconds.

**Blank Mind Recovery:**

**(1) Restate:** "Multi-region active-active = all regions serve real traffic,
all regions replicate data to each other."

**(2) Why hard:** "If user in US and EU update the same record at the same time:
who wins? How do we detect and resolve this conflict?"

**(3) When to use:** "User base is global and needs <100ms latency. And RTO <
5 minutes (single region failure = that region's users rerouted instantly)."

---

### 📘 Concept Explanation

**Active-active vs active-passive:**

```
Active-passive (simpler):
  Region US: primary (serving all traffic)
  Region EU: standby (replica, not serving traffic)

  Write: US -> written, replicated to EU (async)
  Read:  US -> served locally
  Failover:
    US fails -> DNS updated -> users routed to EU
    Cutover time: DNS TTL (60-300 seconds) + health check detection
    RTO: 1-5 minutes

  Wasted capacity: EU region running but serving no traffic
  Cost: 2x single-region infrastructure cost (wasted standby)

Active-active:
  Region US: serving US+Americas users
  Region EU: serving EU+APAC users

  Write: US users -> US writes; EU users -> EU writes
  Both: async replicate to each other
  Read: served locally (<5ms vs 150ms cross-region)

  Failure:
    US fails -> DNS reroutes US users to EU
    EU: serves full global traffic
    RTO: 60-120 seconds (DNS TTL + health check)
    Capacity: EU must handle full global traffic on failover
              (surge capacity: normally 50%, can serve 100%)

  Conflict risk: same record written in US and EU simultaneously
  Conflict rate: depends on data model
    User session data: user tied to one region (no conflicts)
    Shared inventory: high conflict risk

Multi-region data replication:
  Async replication: lag 50-200ms between regions
  Sync replication: write doesn't complete until all regions ACK
    (prohibitively slow: 150ms cross-region RTT added to every write)

  Most active-active: async replication
  Implication: region can serve slightly stale data
  Trade-off: AP (eventual consistency for reads) to get active-active
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Conflict resolution patterns:**

```
Last-Write-Wins (LWW):
  Each write: timestamp from local clock
  Conflict: higher timestamp wins
  Problem: clock skew (clocks drift, NTP can't prevent all skew)
  AWS DynamoDB global tables: uses LWW with vector clocks
  Use: user preferences, session data, non-critical overwrites
  Risk: concurrent writes -> one is silently lost

CRDTs (Conflict-free Replicated Data Types):
  Data structures designed for concurrent updates without conflicts
  G-Counter: increment-only counter (add from each region, sum all)
    US counter: [5, 0] (US incremented 5, EU incremented 0)
    EU counter: [0, 3] (US incremented 0, EU incremented 3)
    Merge: [5, 3] -> total = 8
    No conflict: merging is additive

  G-Set: add-only set
    US adds: {A, B}
    EU adds: {B, C}
    Merge: {A, B, C} (union)
    No conflict

  OR-Set (Observed-Remove Set): add + remove
    Add: tag each element with unique ID
    Remove: tag the specific add (not the element value)
    Merge: union of adds minus union of removes
    Resolves: add-remove concurrency

  Use cases for CRDTs:
    Shopping cart: OR-Set (add/remove items)
    Page view counter: G-Counter
    Social media likes: G-Counter
    Collaborative document: more complex CRDT (RGA)

Global transaction coordinator (for strict consistency):
  Write: client sends to coordinator (global, single region)
  Coordinator: 2PC across all regions -> commit
  All regions: see the write simultaneously
  Latency: coordinator RTT (150ms if coordinator is US, from EU user)
  Use: financial transactions, inventory decrement (exactly-once)
  Cost: coordinator = bottleneck, defeats active-active performance goal
  When to use: small subset of operations requiring strict consistency
               (route most operations to local; route consistency-critical to coordinator)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

```java
// DynamoDB Global Tables: active-active with automatic replication
// AWS SDK Java v2

@Configuration
public class DynamoDbConfig {

    @Bean
    public DynamoDbClient dynamoDbClient() {
        // Connect to LOCAL region (writes go here, async replicated)
        return DynamoDbClient.builder()
            .region(Region.of(System.getenv("AWS_REGION")))
            .credentialsProvider(
                DefaultCredentialsProvider.create())
            .build();
    }
}

@Service
public class UserSessionService {

    private final DynamoDbClient dynamo;
    private static final String TABLE = "user-sessions";

    // Write to local region: DynamoDB replicates to other regions
    public void updateSession(String userId,
                               String sessionData) {
        // Conditional write: fail if conflicting update
        // (optimistic locking using version attribute)
        try {
            Map<String, AttributeValue> item = Map.of(
                "userId", AttributeValue.fromS(userId),
                "sessionData", AttributeValue.fromS(sessionData),
                "lastUpdated", AttributeValue.fromS(
                    Instant.now().toString()),
                "region", AttributeValue.fromS(
                    System.getenv("AWS_REGION")));

            dynamo.putItem(PutItemRequest.builder()
                .tableName(TABLE)
                .item(item)
                .build());
        } catch (ConditionalCheckFailedException e) {
            // Conflict: another region updated first
            // LWW: DynamoDB global tables handle this automatically
            // (most recent timestamp wins)
            log.warn("Write conflict for user {}: {}", userId, e);
        }
    }

    // Read from local region: may be slightly stale
    // (if user was just updated in another region)
    public Optional<String> getSession(String userId) {
        GetItemResponse response = dynamo.getItem(
            GetItemRequest.builder()
                .tableName(TABLE)
                .key(Map.of("userId",
                    AttributeValue.fromS(userId)))
                .build());

        return Optional.ofNullable(
            response.item().get("sessionData"))
            .map(AttributeValue::s);
    }
}
```

> **Code walkthrough:** DynamoDB Global Tables handles multi-region replication
> automatically. The application writes to the local region (same AWS_REGION
> as the pod); DynamoDB asynchronously replicates to all configured regions
> within 1-2 seconds. Reads from the local region may be slightly stale (up to
> the replication lag). For user session data (last login, cart, preferences):
> this eventual consistency is acceptable - if a US user and EU user somehow
> edit the same session simultaneously, LWW resolution (most recent timestamp
> wins) is acceptable. For inventory decrements (order a product): DynamoDB
> conditional expressions with version tracking prevent overselling even with
> async replication.

```java
// CRDT: G-Counter for page views (multi-region safe)
@Service
public class PageViewCrdtCounter {

    private final RedisTemplate<String, String> redis;
    private final String regionId =
        System.getenv("AWS_REGION");

    // Increment in local region's bucket
    public void incrementPageView(String pageId) {
        String key = "pv:" + pageId + ":region:" + regionId;
        redis.opsForValue().increment(key, 1);
        // Cross-region sync: separate async job replicates
        // region-specific counters to peer Redis clusters
    }

    // Merge counts from all regions (G-Counter sum)
    public long getTotalPageViews(String pageId,
                                   List<String> allRegions) {
        // Read this region's count
        long localCount = Optional.ofNullable(
            redis.opsForValue().get(
                "pv:" + pageId + ":region:" + regionId))
            .map(Long::parseLong).orElse(0L);

        // Read other regions' replicated counts
        long otherCount = allRegions.stream()
            .filter(r -> !r.equals(regionId))
            .mapToLong(region -> {
                String replicaKey =
                    "pv:" + pageId + ":replica:" + region;
                return Optional.ofNullable(
                    redis.opsForValue().get(replicaKey))
                    .map(Long::parseLong).orElse(0L);
            }).sum();

        return localCount + otherCount;
        // G-Counter merge: SUM (idempotent, no conflict)
    }
}
```

> **Code walkthrough:** The G-Counter CRDT splits the counter by region. Each
> region increments only its own bucket (no concurrent writes to the same key
> from multiple regions). Async replication copies each region's count to the
> others. The merge operation is a sum of all region buckets - always correct,
> never conflicts. If replication is delayed: the total is slightly low (missing
> recent increments from other regions). Eventually consistent (once replication
> catches up: correct). This pattern applies to: like counts, view counts, event
> counters, usage metrics - any counter that only increments and doesn't need
> exact consistency.

```java
// Active-active failover: geo-routing + health check
// Spring Boot health indicator to signal regional health
@Component
public class RegionalHealthIndicator
        implements HealthIndicator {

    private final DatabaseHealthCheck dbCheck;
    private final CacheHealthCheck cacheCheck;

    @Override
    public Health health() {
        boolean dbHealthy = dbCheck.isHealthy();
        boolean cacheHealthy = cacheCheck.isHealthy();

        if (dbHealthy && cacheHealthy) {
            return Health.up()
                .withDetail("region", getRegion())
                .withDetail("db", "healthy")
                .withDetail("cache", "healthy")
                .build();
        }

        // Return DOWN: Route53 health check fails
        // -> DNS removes this region from rotation
        // -> Traffic rerouted to other regions
        return Health.down()
            .withDetail("region", getRegion())
            .withDetail("db", dbHealthy ? "ok" : "FAIL")
            .withDetail("cache", cacheHealthy ? "ok" : "FAIL")
            .build();
    }
}
// Route53 health check: polls /actuator/health every 30 seconds
// DOWN response: removes this region's IP from DNS answer
// Users: DNS TTL expires -> get other region's IP
```

> **Code walkthrough:** The health indicator integrates with Route53's health
> check system. Route53 polls the `/actuator/health` endpoint every 30 seconds.
> When the region's DB fails: health returns DOWN. Route53 detects: marks this
> region's DNS record as unhealthy. On the next DNS query: Route53 returns only
> healthy regions. DNS TTL for geo-routing records: typically 60 seconds.
> Total failover time: 30s (health check) + 60s (DNS TTL) = ~90 seconds.
> During that 90 seconds: some users still route to the failing region (DNS
> cached TTL). Those requests fail. Application must handle gracefully (retry
> with other region or show friendly error).

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Active-active multi-region means all regions are actively serving user traffic,
> not just one. Users in the US are served by the US region, users in Europe
> by the EU region. DNS routing directs users to the nearest region. If one region
> fails, DNS reroutes all users to the other. The hard part is data: if a user
> updates their cart in the US and EU at the same moment, you need to decide which
> update wins. Different strategies like last-write-wins or CRDT handle this.

**Senior / Staff:**
> The design decision I focus on first: "which data needs global consistency?"
> Most data doesn't. User sessions, preferences, carts: local consistency is fine.
> Financial transactions, inventory: require global coordination. Split the data:
> route consistency-critical writes to a global coordinator (accepting the latency);
> route everything else to the local region. The coordinator doesn't need to handle
> 90% of traffic - just the 10% requiring exact consistency. This hybrid approach
> gets the performance benefits of active-active for most operations while maintaining
> correctness for critical ones. The anti-pattern: treating all data as equally
> critical and either adding coordinator overhead to everything (negates active-active
> benefits) or ignoring conflicts everywhere (causes financial errors).

---

### ⚠️ Common Misconceptions

**Misconception: "Active-active provides zero-downtime and higher availability than active-passive."**
Active-active improves latency (serve users locally) and reduces failover time.
But it doesn't eliminate downtime: DNS failover takes 60-120 seconds even in
active-active. Availability difference between active-active and active-passive
is small (both provide 99.99%+ if designed correctly). The main benefits are:
(1) lower latency for geographically distributed users, (2) no cold-start on
failover (other region is already warm). The cost: conflict resolution complexity,
2x+ data replication, operational complexity. Don't choose active-active primarily
for "higher availability" - choose it for "lower latency" and "no warm-up on failover."

---

### 🚨 Failure Modes and Diagnosis

**Failure: Split-brain during inter-region network partition**
Symptom: two regions serving traffic, receiving writes, but inter-region
replication link fails. Both regions diverge (different state).
When partition heals: conflicting writes present in both regions.
Detection: replicate a known "heartbeat" record every 30 seconds;
alert if replication lag > 60 seconds.
Response protocol: if partition lasts > 5 minutes: consider routing all writes
to one "primary" region (temporary active-passive mode) to prevent conflict
accumulation. After healing: reconcile conflicts using conflict resolution policy.
Prevention: multi-region replication over redundant network paths (AWS Direct
Connect + internet routing as fallback).

---

### 🎯 Interview Deep-Dive

**Timing:** Hard ★★★ - 12 questions.

---

#### Q1 - How does geo-routing work and what are its failure modes?

DNS-based geo-routing: direct users to the nearest healthy region.

```
Mechanisms:

1. DNS Geo-routing (Route53 geolocation):
  User in Europe: DNS resolves to EU region IP
  User in US: DNS resolves to US region IP
  Based on: client IP geolocation (IP -> country/region database)
  Accuracy: ~99% (VPN users, CDN nodes: may resolve incorrectly)

2. DNS Latency-based routing (Route53):
  Measures: actual latency from multiple probe points to each region
  Routes to: lowest-latency region for the user's location
  More accurate than geolocation (doesn't rely on IP-to-country mapping)

3. Anycast routing (CDN / Cloudflare):
  Same IP: announced by multiple POPs around the world
  BGP: routes traffic to nearest POP by network topology
  Ultra-fast: BGP routing < 1ms to identify nearest POP
  CDN: Cloudflare, Fastly, Akamai use Anycast for edge nodes

Failure modes:

1. DNS TTL too long:
  Region fails -> Route53 marks unhealthy -> removes from DNS
  Client: has cached old DNS (still sends to failed region)
  TTL: 30-60 seconds recommended (lower = faster failover, more DNS queries)
  During TTL window: some requests fail (acceptable in 99.9% SLA)

2. DNS failover too slow:
  Health check: every 30 seconds
  Threshold: 3 consecutive failures = mark unhealthy (90 seconds)
  + DNS TTL: 60 seconds
  Total: 150 seconds failover time
  Improvement: Route53 health check every 10 seconds + TTL 10 seconds
  Tradeoff: 10 second TTL = 10x DNS queries (cost, increased DNS load)

3. GEO routing error:
  VPN user in US: IP resolves to EU country -> routed to EU
  Result: higher latency (user is actually in US)
  Mitigation: latency-based routing (measures actual RTT, not IP location)

4. BGP hijacking (rare, catastrophic):
  Attacker announces someone else's IP prefix
  Traffic: routed to attacker's servers
  Prevention: RPKI (Route Origin Validation) for BGP announcements
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The DNS TTL is a critical tuning knob for
active-active failover. Too long (300+ seconds): slow failover, users experience
extended outage. Too short (< 10 seconds): DNS infrastructure flooded with queries,
recursive resolvers may not respect short TTLs. The practical sweet spot: 30-60
seconds TTL for health check records. Production tip: most Route53 health checks
use a 10-second interval with a threshold of 2-3 failures = 20-30 seconds to
detect failure. Add 60 seconds TTL: total failover < 90 seconds. Below that:
diminishing returns (DNS resolver behavior unpredictable below 30s TTL).

---

#### Q2 - How do you handle data consistency with multi-region writes?

Multi-region write consistency: the central challenge.

```
Consistency requirements analysis:
  Classify all data by conflict risk + consequence:

  Low risk + low consequence (use async + LWW):
    User profile updates (name, avatar)
    Application settings
    Non-financial counters (view counts)
    Strategy: LWW or CRDT, no coordinator needed

  Medium risk + medium consequence (use async + version vector):
    Shopping cart
    Social media posts
    User-generated content
    Strategy: version vectors + merge on read
              User always reads their latest version (session consistency)

  High risk + high consequence (use synchronous global coordinator):
    Financial transactions (debit/credit)
    Inventory decrement (prevent overselling)
    Unique constraints (username uniqueness across regions)
    Strategy: route to global coordinator, accept 150ms+ latency
              or: use distributed lock (ZooKeeper across regions)

Version vectors (conflict detection):
  Each write: assigned a vector clock (per-region counter)
    US: {US:3, EU:0}  (US made 3 writes, EU made 0)
    EU: {US:1, EU:5}  (EU made 5 writes, US made 1 write seen by EU)

  Conflict detection:
    US version: NOT <= EU version (EU doesn't have US:2, US:3)
    EU version: NOT <= US version (US doesn't have EU:2-5)
    -> CONFLICT: both have changes not seen by the other
    -> Merge needed (application-specific logic or CRDTs)

  Amazon Dynamo (original paper): vector clocks + "return to client for resolution"
  Cassandra: LWW (simpler, loses writes on concurrent updates)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The classification exercise (low/medium/high
risk and consequence) should be done explicitly for every active-active design.
Most data is low-risk; treating all data as high-risk (route everything to a global
coordinator) defeats the purpose. The Amazon Dynamo paper's "shopping cart" example
is canonical: the cart uses a G-Set (items can be added). If a user adds item A
in US and item B in EU concurrently, the merged cart has both items - the correct
outcome. No data loss, no conflict. The financial transaction case is different:
"user's balance is $100, US deducts $100, EU deducts $100 simultaneously" must
be caught. The balance can't go negative. This requires the global coordinator
(or a distributed lock with fencing).

---

#### Q3 - How do you implement active-active for a database like PostgreSQL?

PostgreSQL active-active: multi-master replication options.

```
PostgreSQL native: does NOT support multi-master
  PostgreSQL: one primary (writes), multiple standbys (reads)
  This is active-passive, not active-active

Options for PostgreSQL-based active-active:

1. Citus (distributed PostgreSQL):
  Shards data across nodes
  Each shard: one primary (one region)
  Shard for key K: always writes to shard's region
  Not truly active-active: write for key K goes to specific region

2. CockroachDB:
  Distributed SQL with active-active support
  Multi-region: "regional by row" - rows pinned to a region
  User from US: their data stored in US
  US region down: US user data available from EU (replication)
  True active-active for rows pinned to alive regions

3. AWS Aurora Global Database:
  One primary region (writes)
  Secondary regions: read replicas (< 1 second lag)
  Failover: promote secondary to primary (60-120 seconds)
  This is active-active for READS; write failover = active-passive

4. Vitess:
  MySQL sharding + routing
  Multi-region: similar to Citus (shard-specific writes)

5. Application-level partitioning:
  Partition users by region (US users -> US DB, EU users -> EU DB)
  Cross-region user data: rare edge case (VPN, travel)
  Handles edge case: replicate user to other region on first visit
  (read-your-own-writes: user's session tied to originating region)

  Real-world: most large-scale active-active systems
  (Netflix, Uber, Amazon): application-level partitioning
  Not database-level multi-master
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The practical truth about active-active at
scale: it's mostly application-level partitioning + async replication, not
true multi-master database. Netflix: content and user data partitioned by region;
global data (movie catalog) replicated read-only. Uber: driver/rider matching
is local (a driver in NYC can't match a rider in London). Global data: user accounts.
The "active-active" label applies to the infrastructure (multiple regions serving
traffic) but write partitioning limits conflict risk. True multi-master databases
(CockroachDB, Google Spanner) are used when you need strong consistency across
regions without application-level partitioning - at the cost of cross-region
latency on every write.

---

#### Q4 - How do you design for region failover with minimal disruption?

Region failover design: graceful handling of full region failure.

```
Failover triggers:
  Region completely down (all services unavailable)
  Specific service down in one region (partial failure)
  Performance degradation (latency spike makes region "unhealthy")
  Planned maintenance (scheduled region failover test)

Failover architecture:

1. Load shedding vs failover:
  Region A: 50% degraded (slow, not down)
  Option 1: fail ALL traffic from A to B
    Risk: region B capacity insufficient (normally 50% load each)
    Result: cascading failure (B also overloads)
  Option 2: shed 80% of traffic from A to B (keep 20% in A)
    A handles: only its critical traffic
    B: gets 80% (can handle if designed for surge)
    Gradual: as A recovers, re-shift traffic back

2. Capacity planning for failover:
  Each region: sized for 100% of traffic (not 50%)
  Cost: 2x infrastructure (each region at full capacity, normally at 50%)
  Alternative: autoscaling headroom
    Normal: 50% capacity
    Failover trigger: scale out to 100% capacity
    Risk: autoscaling takes 3-5 minutes (gap before capacity available)

3. Database failover:
  Async replication: failing region may have recent uncommitted writes
  On failover: those writes are lost (replication lag)
  RPO (Recovery Point Objective): typically 30 seconds (replication lag)
  Acceptable? Depends on data type:
    Financial transactions: NOT acceptable (need sync replication or coordinator)
    User sessions: acceptable (user re-authenticates)

4. Stateful services:
  In-progress requests: fail on region failure
  Client retry: with backoff to other region
  Session state: stored in other region (replication lag)
    User may need to re-login (session not yet replicated)
    Acceptable trade-off vs synchronous session replication cost

5. DNS failover speed:
  Route53 with low TTL (30s): 60-90 second total failover time
  For lower RTO: pre-warm DNS at failover region
    both regions' DNS records always in client's cache
    on failure: failed region returns errors -> client uses other region
    Application retry: faster than DNS failover
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The RPO (Recovery Point Objective) for
active-active with async replication is determined by the replication lag, not
by the architecture. If your replication lag is typically 500ms but spikes to
30 seconds under load: your RPO is 30 seconds, not 500ms. Monitor replication
lag continuously; set an SLO (replication lag < 5 seconds); alert when exceeded.
For financial systems: if replication lag exceeds the RPO threshold, consider
temporarily routing all writes to the region with the most complete replica
(temporary active-passive mode) until the lag recovers. Explicit, documented,
tested failover runbooks prevent ad-hoc decisions during incidents.

---

#### Q5 - How do you handle user authentication in multi-region active-active?

Authentication in multi-region: JWTs vs session state.

```
Session-based auth (traditional):
  User logs in -> server creates session -> session stored in Redis
  Request: session ID in cookie -> lookup in Redis

  Problem in multi-region:
    Login: session created in US Redis
    Request to EU: session not in EU Redis -> 401
    Solution: replicate Redis across regions (with async lag)
    Risk: session created in US, immediate request to EU:
          session not yet replicated -> login failure

JWT-based auth (preferred for multi-region):
  User logs in -> server creates JWT -> returns to client
  JWT: signed with private key, contains claims (sub, roles, exp)
  Request: JWT in Authorization header
  Verification: any region can verify (uses public key, no DB lookup)

  Multi-region JWT advantages:
    Stateless: no cross-region session lookup
    Each region: verifies JWT independently (public key is static)
    Rotate signing keys: publish new public key, old JWTs still valid until exp

  Implementation:
    Auth service: runs in each region (or global single region)
    JWT: 15-minute expiry (short = less risk if stolen)
    Refresh token: stored in DB (region-replicated)

  Cross-region login flow:
    User in EU logs in -> EU auth service issues JWT
    User's browser: stores JWT (localStorage or cookie)
    Request to US region: JWT in header -> US verifies signature
    No cross-region session lookup needed

Token revocation:
  JWT is valid until expiry (15 min)
  Revocation: "logout" or "password changed" -> user's JWT still valid for 15 min
  Strict revocation: maintain revocation list in global Redis
    All regions: check revocation list on JWT validation
    Cross-region: fast (< 1ms Redis lookup)
  Pragmatic: short JWT TTL (15 min) makes strict revocation unnecessary for most apps
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The JWT refresh token flow is the critical
design for multi-region auth. The short-lived JWT (15 minutes) is verified
stateless by any region. The refresh token (long-lived, stored in DB) is used
to get a new JWT when the old one expires. The refresh token lookup must be
consistent: if the user logs out (revoke refresh token) in EU, and immediately
requests a new JWT in US using the old refresh token: US must see the revocation.
This requires either: (1) refresh token lookup in a globally-replicated DB (DynamoDB
Global Tables), or (2) short refresh token TTL (1 hour) - after logout, the
refresh token expires in max 1 hour, new JWTs can't be issued. Design decision:
strict logout semantics vs simplicity.

---

#### Q6 - How do you handle split-brain in an active-active multi-region setup?

Split-brain in multi-region: what happens when regions can't communicate.

```
Scenario: US and EU are both active, inter-region link fails
  US: continues serving US users, writing to US database
  EU: continues serving EU users, writing to EU database
  No replication: both regions diverge

Detection:
  Replication heartbeat: each region sends "I am alive" to other region
  Heartbeat stored: replicated table with region + timestamp
  Alert: if other region's heartbeat > 60 seconds ago
         -> potential partition

During split-brain:
  Both regions: continue serving traffic (availability maintained)
  Data: diverging (different writes in each region)
  Conflicts: accumulating

Manual + automated response:

Option 1: Continue and resolve later:
  Both regions: keep serving (AP choice)
  After healing: merge conflicts per conflict resolution policy
  Good for: low-conflict data (user sessions, preferences)
  Bad for: financial data (can't undo double-spends)

Option 2: Route all writes to one region:
  Split-brain detected: region with most traffic = "temporary primary"
  Other region: becomes read-only (stops accepting writes)
  After healing: replicate writes to the read-only region, resume
  Good for: any data where conflict is unacceptable
  Requires: application support for read-only mode
            + fast detection + routing update

Option 3: Reject writes during partition:
  Both regions: stop accepting writes (CP choice)
  Users: read-only until partition heals
  Good for: financial systems (can't risk conflicts)
  Bad for: user-facing apps (users see errors)

Implementation:
  Each region: monitors cross-region replication lag
  If lag > 60s: switch to "read-only write mode"
    - Still accept: reads, idempotent operations
    - Queue: writes that can't be committed without cross-region check
    - Alert: ops team (manual decision to continue or go read-only)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The split-brain response should be pre-planned
and tested, not decided during an incident. For each critical data type: document
"on inter-region partition, what is the expected behavior?" Financial transactions:
stop accepting writes (route to coordinator region). Shopping carts: continue
accepting writes (CRDT merge after healing). The untested assumption "this will
never happen" leads to improvised responses during incidents that cause worse
outcomes. Chaos engineering exercise: disable inter-region replication for 30
minutes in a lower environment; verify that the system behaves according to the
documented policy. Fix gaps before production.

---

#### Q7 - What is the cost model for active-active multi-region?

Active-active cost analysis: quantifying the investment.

```
Cost components vs single-region:

1. Compute: 2x (or 3x for 3-region)
  Each region: must handle full traffic capacity
  (Capacity for N region failover: each region handles N * normal traffic)
  Normal operation: each region at 50% capacity
  Failover: one region takes 100% (scale out: 5-10 min delay)

  Cost: 2x normal compute + 50% autoscaling headroom
  Comparison: active-passive = same if standby has the same capacity

2. Data replication traffic:
  Inter-region data transfer: expensive (AWS: $0.02/GB cross-region)
  At 10TB data transferred/day: $200/day = $6000/month
  Large write workloads: replication cost significant

3. Database licensing:
  CockroachDB / Google Spanner: price per vCPU in each region
  Additional region = additional licensing cost

4. Global load balancer:
  Route53 latency routing: $0.60 per million queries
  Anycast CDN: per-request pricing

5. Operational complexity:
  Engineering time: more complex deployment, testing, incident response
  Team size: typically 20-30% more SRE/infra time for multi-region

When is active-active worth it:
  Latency requirement:
    < 100ms for global users: need regional POPs
    Single US region: EU users get 150ms+ -> active-active justified

  RPO requirement:
    < 60 seconds: active-active (async replication)
    Active-passive: RPO = replication lag (similar)
    Sync replication: RPO = 0 (but prohibitive latency cost)

  RTO requirement:
    < 90 seconds: active-active (DNS failover)
    Active-passive DNS failover: 1-5 minutes (similar if planned)
    Active-active advantage: no cold-start (other region already warm)

  Compliance:
    Data residency: EU data must stay in EU -> multi-region required regardless
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The most common miscalculation: treating
active-active cost as "2x single region." The hidden costs are: data replication
traffic (can exceed compute cost for write-heavy workloads), operational team
overhead (on-call for two regions, complex deployments), and testing overhead
(chaos tests, failover drills). Before committing to active-active: quantify
the engineering cost explicitly. Many teams find: active-active is 2.5-3x the
cost of single-region when including the operational overhead. The business
justification must cover this full cost. Alternatives to full active-active:
CDN for static content (reduces global latency with much lower cost), read
replicas in each region (reduces read latency without the write complexity).

---

#### Q8 - How would you test a multi-region active-active system?

Testing strategy: verifying correctness and resilience.

```
Testing pyramid for multi-region:

1. Unit tests: conflict resolution logic
  CRDT merge: given two diverged states, verify correct merge
  LWW: given two writes with timestamps T1 and T2, verify T2 wins
  Vector clock comparison: given two version vectors, detect conflict correctly

2. Integration tests: replication correctness
  Write in US region, verify EU region shows the same data
  Verify replication lag < SLO (e.g., < 2 seconds)
  Test conflict: concurrent writes to same key -> verify resolution matches policy

3. Chaos engineering (production-like environment):
  Test 1: Region failover
    - Terminate all instances in US region
    - Measure: time for EU to receive 100% traffic
    - Verify: no requests permanently lost (retried by client)
    - Verify: EU handles load without degradation
    - Restore US: measure time to rejoin without data loss

  Test 2: Network partition (split-brain)
    - Block inter-region replication traffic (keep regional traffic)
    - Verify: both regions continue serving (availability preserved)
    - Write to both regions: conflicting data
    - Restore replication: verify conflicts resolved per policy
    - Verify: no permanent data loss (post-partition reconciliation)

  Test 3: Replication lag spike
    - Throttle replication bandwidth
    - Verify: replication lag detected, alert fires
    - Verify: system correctly reports stale data (if monitoring checks)
    - Verify: no data corruption after lag resolves

  Test 4: DNS failover
    - Force Route53 health check to fail
    - Measure: DNS failover time
    - Verify: all new requests route to healthy region
    - Verify: in-flight requests to failed region: handled correctly

4. Load test with geo-routing:
  Simulate traffic from US and EU simultaneously
  Verify: US traffic routes to US, EU to EU (latency < 50ms each)
  Verify: at 2x normal load (simulating failover load): no degradation
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The split-brain chaos test is the most
critical and least commonly run. Teams deploy active-active systems without
testing "what happens if the two regions can't see each other for 10 minutes?"
The answer determines whether the system makes the correct trade-off between
availability (both serve traffic, accumulate conflicts) and consistency (one
becomes read-only). This test reveals: does the system detect the partition?
Does the conflict resolution logic work? Does the post-partition reconciliation
complete without manual intervention? Without this test: the first real partition
is the test. The GameDay format (scheduled, cross-team chaos exercise) is the
production-tested way to run this: schedule 2 hours, invite relevant teams,
document the runbook, execute, debrief.

---

#### Q9 - How do you handle compliance and data residency in multi-region?

Data residency: legal requirements on where data is stored and processed.

```
GDPR (EU): EU personal data must be stored in EU (or adequate countries)
CCPA (California): residents' data rights (less strict on location)
Data Localization (China, Russia, India): citizen data must stay in country

Architecture for data residency:

1. Data classification:
  Personal data (PII): must stay in region/country
  Non-PII business data: can be stored globally
  Aggregate/anonymized: can be stored globally

2. Region-specific data stores:
  EU region: EU PostgreSQL cluster (EU data only)
  US region: US PostgreSQL cluster (US data only)
  Shared (non-PII): global DynamoDB or Cassandra

3. User routing to correct region:
  EU user: must be served by EU region (data in EU)
  US user: can be served by US region
  User moves: create account in EU, vacation to US
    -> US region doesn't have their data
    -> Options:
      A. Always route to home region (EU user -> EU, even from US)
         Latency: 150ms from US, but compliant
      B. Replicate user data to US (violates data residency)
      C. Keep sessions in home region, query home region from US region
         US region acts as proxy for EU user -> routes to EU data

4. Audit logging:
  GDPR: requires records of data processing
  Audit log: stored in EU (for EU data processing events)
  Not replicated to US (EU data residency for EU audit)

5. Encryption and key management:
  EU data: encrypted with EU KMS keys (AWS KMS in eu-west-1)
  US data: encrypted with US KMS keys (AWS KMS in us-east-1)
  Cross-region access: denied at KMS level (key policy)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Data residency compliance is not just a
storage question; it's a processing question. GDPR covers "processing" of personal
data, not just storage. If EU user data flows through a US region for any reason
(analytics pipeline, ML training, log aggregation): that's processing in the US,
which may require legal basis (Standard Contractual Clauses, adequacy decision).
The engineering implication: data pipelines must respect residency. Analytics
data warehouse: separate EU cluster for EU user analytics; no joining EU and US
user data in a US pipeline. DPA (Data Processing Agreement) and SCCs must cover
any cross-region transfer. This is a legal + engineering collaboration, not just
an engineering decision.

---

#### Q10 - What are the alternatives to full active-active for global distribution?

Alternatives: different trade-offs on the cost/complexity spectrum.

```
Full active-active:
  All regions serve reads AND writes
  Highest: complexity, conflict risk, cost
  Benefit: lowest latency globally, fastest failover

Active-active reads, active-passive writes:
  All regions: serve reads (from local replica)
  One region: primary (all writes)
  Reads: local (low latency)
  Writes: always go to primary (150ms from EU user to US primary)
  Use: read-heavy workloads (product catalog, social media feeds)
  No write conflicts (single write primary)

CDN for static content + single-region API:
  CDN: serves 80-90% of requests (HTML, JS, CSS, images)
  Single-region API: handles remaining 10-20% (authenticated, dynamic)
  Latency: CDN responses < 50ms globally; API 150-200ms for remote users
  Cost: fraction of full active-active
  Use: most content websites, SaaS apps without strict latency SLO

Read replicas in every region:
  Primary: one region (writes)
  Read replicas: every major region
  Read: local replica (< 10ms) with 1-2s replication lag
  Write: goes to primary (latency for remote regions)
  No conflict: single write primary
  Use: reporting, search, product catalogs

Edge computing (Cloudflare Workers, Lambda@Edge):
  Logic runs at CDN edge (100+ global locations)
  Handles: personalization, A/B testing, auth, request routing
  Data: still in primary region or CDN KV store
  Latency: <50ms for edge logic globally
  Limitation: edge workers have limited compute/storage

Decision framework:
  Strict latency SLO (< 50ms write globally): active-active (expensive)
  Tolerate 150ms writes: active-active reads, active-passive writes
  Most reads are cacheable: CDN (cheapest, lowest complexity)
  Large read-to-write ratio (10:1+): read replicas per region
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Most applications should start with CDN +
single-region API, not active-active. The business case for active-active
must be explicitly justified: "Our users globally need < X ms write latency
and we have $ Y budget." Many organizations choose active-active for prestige
or "in case we need it" without the business justification. The result: 3x
infrastructure cost + engineering complexity with no user-visible benefit
(because write latency from EU to US primary is 150ms, which is below human
perception threshold for most interactions). Optimize after measuring, not before.

---

#### Q11 - Design an active-active order processing system for a global e-commerce platform.

System design: global e-commerce with active-active for orders.

```
Requirements:
  Users in US, EU, APAC (3 major regions)
  Product catalog: 10M products, read-heavy
  Orders: 500K/day globally (peak: 10K/min during sales)
  SLO: < 200ms API P99 globally
  Compliance: EU data residency (GDPR)
  RTO: < 60 seconds on region failure

Architecture:

1. Traffic routing:
  Cloudflare: Anycast DNS, geo-routing
  3 regions: us-east-1, eu-west-1, ap-southeast-1
  Each region: sized for 100% global traffic (failover headroom)

2. Product catalog (read-heavy, non-PII):
  DynamoDB Global Tables: all 3 regions
  Replication: async, < 1 second lag acceptable
  Read: local region (< 5ms)
  Write (admin updates): any region, auto-replicated
  Conflict policy: LWW (product update by admin, no concurrent conflicts)

3. User accounts (GDPR: must know user's home region):
  On signup: determine home region by user's location
  Store in: user profile ("home_region": "eu-west-1")
  User data: stored only in home region + encrypted backup
  Requests from non-home region: proxy to home region
    US user on vacation in EU: requests proxied US -> EU reads
    Acceptable: 150ms proxy latency (compliant, user in EU occasionally)

4. Order processing:
  Order creation: conflict-critical (exactly-once, inventory check)
  Architecture: regional order service + global inventory coordinator

  Step 1: Regional order service receives request
  Step 2: Call global inventory coordinator (sync: 150ms cross-region)
  Step 3: Inventory coordinator: atomic decrement + reserve
  Step 4: Inventory reserved -> regional order service creates order
  Step 5: Order stored in regional DynamoDB + replicated globally

  Why global coordinator for inventory:
    Inventory = shared mutable state (limited stock)
    Active-active without coordinator: overselling (two regions sell same item)
    Coordinator: accepts 150ms latency for inventory operations

5. Order history (read-heavy, GDPR):
  EU users' order history: stored in eu-west-1
  US users' order history: stored in us-east-1
  Cross-region read: rare (vacation case) -> proxy to home region

Failover:
  Region failure: Cloudflare health checks -> reroute traffic (< 60s)
  Inventory coordinator failure: elect new coordinator (etcd leader election)
    New coordinator elected: < 15 seconds (Raft)
  During failover: order creation temporarily slower (global coordinator reroutes)
  Order reads: still fast (local replicas available)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The hybrid model - active-active for reads
and eventually-consistent data, global coordinator for inventory - is the
practical production pattern. Netflix, Amazon, and large e-commerce platforms
use variants of this. The inventory coordinator doesn't handle 90% of traffic
(product browsing, order history, user profile reads): those are active-active.
Only order creation (inventory decrement) routes to the coordinator. At 500K
orders/day: that's ~6 orders/second - easily handled by a single coordinator
region. The key design principle: identify the minimal set of operations requiring
global coordination; route everything else to local. This maximizes the benefit
of active-active while maintaining correctness for the operations that need it.

---

#### Q12 - How do you manage schema migrations in a multi-region active-active database?

Schema migrations: safely deploying DB changes across all regions.

```
Problem:
  Single-region migration:
    Step 1: stop writes (maintenance window)
    Step 2: run migration
    Step 3: deploy new code
    Step 4: resume writes
  Simple but: downtime

  Multi-region migration:
    Can't stop writes in all regions simultaneously (defeats active-active purpose)
    Can't migrate one region while other is running different schema
    Code at different versions across regions? Dangerous if reading each other's data

  Solution: expand-contract (rolling migration)

Expand phase (backward compatible changes):
  Step 1: Add new column with NULL default
    ALTER TABLE orders ADD COLUMN currency VARCHAR(3) DEFAULT NULL;
    SQL is backward compatible: old code writes NULL, new code writes 'USD'
  Step 2: Deploy NEW code to ONE region
    New code: writes currency field; reads currency field (NULL = default to USD)
    Old code (other regions): still writing without currency field (OK: defaults to NULL)
    Both codes work with both schema states
  Step 3: Deploy new code to remaining regions
    All regions: running new code
  Step 4: Backfill old rows
    UPDATE orders SET currency = 'USD' WHERE currency IS NULL;
    Run in batches (avoid table lock)

Contract phase (remove old behavior):
  Step 5: Make column NOT NULL (now all rows have values)
    ALTER TABLE orders ALTER COLUMN currency SET NOT NULL;
  Step 6: Remove backward compatibility code
    New code: no longer handles NULL currency

Anti-patterns:
  Rename a column: breaks active-active immediately
    (Other region's code still reads old column name -> errors)
  Drop a column: other regions' code reads it -> errors
  Add NOT NULL without default: other regions can't write -> errors
  Change data type: other regions send wrong type -> errors

Multi-region migration tools:
  Flyway / Liquibase: schema version tracking
  Run migration: per-region in sequence
  Verify: each region at same version before proceeding
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The expand-contract pattern is the only safe
way to do schema migrations in active-active systems without downtime. It requires
additional discipline: every migration must be decomposed into backward-compatible
steps. Rename column: add new column + copy data + migrate code to new column +
remove old column (4 separate deploy cycles). This is slower than single-region
migrations but maintains availability. The engineering culture requirement: no
migration can be merged that isn't backward-compatible with the current production
code. Automated migration validation in CI: spin up the current schema, apply the
migration, verify old code still works. This catches breaking migrations before
they reach production.

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*



