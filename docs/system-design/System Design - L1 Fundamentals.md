---
layout: default
title: "System Design - L1 Fundamentals"
parent: "System Design"
grand_parent: "SK Interview"
nav_order: 2
permalink: /system-design/l1-fundamentals/
render_with_liquid: false
---

# System Design - L1 Fundamentals

---

# Scalability Fundamentals

---
id: SSD-004
title: Scalability Fundamentals
category: System Design
difficulty: ★☆☆
interview_weight: high
asked_at: Mid/Senior
seniority: mid
tags: #scalability, #horizontal, #vertical, #stateless
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Scalability is a system's ability to handle increased load by adding resources.
> Vertical scaling: add more resources to one machine (CPU, RAM). Horizontal
> scaling: add more machines. Stateless services scale horizontally easily
> (any instance can handle any request). Stateful services are harder (state
> must be replicated or partitioned). The design goal: keep application servers
> stateless; externalize state to databases and caches.

**3 minutes:**
> Scalability has two dimensions: scale-up (vertical) and scale-out (horizontal).
> Vertical has a hard ceiling (largest available machine), costs grow super-linearly,
> and creates a single point of failure. Horizontal is theoretically unlimited,
> costs grow linearly, and provides redundancy.
>
> The prerequisite for horizontal scaling: statelessness. If a server holds
> session state (in-memory sessions), a load balancer can't route requests to
> any server - it must send the same user to the same server (sticky sessions).
> Sticky sessions prevent true horizontal scaling. Solution: externalize sessions
> to Redis or a database. Now any server can handle any user.
>
> Beyond statelessness: horizontal scaling requires coordination for
> consistency (if 3 DB servers, which is authoritative?), routing (load balancer),
> and distributed state management. Database sharding is the hardest scaling
> challenge: once you shard, cross-shard queries become complex.

**Blank Mind Recovery:**

**(1) Restate:** "Scalability is how you make a system handle more load.
Vertical means bigger machines. Horizontal means more machines."

**(2) First principles:** "When a single machine can't handle the load, you have
two options: make the machine more powerful, or add more machines. The first has
a ceiling; the second doesn't. The challenge with more machines: they need to
coordinate."

**(3) Bridge:** "A restaurant scaling: vertical = hire a better chef who cooks
faster. Horizontal = open more restaurants. Horizontal works only if each
restaurant can independently serve customers (stateless). If every restaurant
needs to check one central customer preference database, that database becomes
the bottleneck."

---

### 📘 Concept Explanation

**Vertical vs Horizontal scaling:**

```
Vertical Scaling (Scale Up):
  Current: 4 CPU, 16 GB RAM
  After: 32 CPU, 256 GB RAM

  Benefits: simple (no code changes), strong consistency
            (single data source)
  Limits: most powerful machines are exponentially expensive
          hard ceiling (biggest machine on market)
          single point of failure
  Use when: small teams, early stage, DB scaling start

Horizontal Scaling (Scale Out):
  Current: 1 server
  After: 10 servers behind load balancer

  Benefits: near-infinite scale, fault tolerant
            commodity hardware (cheap)
  Challenges: statelessness required, coordination,
              consistency across instances

  Use when: high availability needed, stateless services,
            cost efficiency at scale

Stateless vs Stateful services:
  Stateless: no instance-local state
    - Any request can go to any instance
    - Load balancer can use round-robin
    - Scaling: add/remove instances freely
    - Examples: REST API server, web server

  Stateful: instance holds state
    - Must route same user to same instance
    - Sticky sessions (bad for scaling)
    - OR: externalize state to shared storage
    - Examples: WebSocket servers (active connections)

Database scaling path:
  1. Single primary (read + write)
  2. Add read replicas (scale reads)
  3. Caching layer (scale hot reads further)
  4. Vertical scale primary (scale writes initially)
  5. Sharding (scale writes horizontally - complex)
```

---

### 💻 Code Example

```java
// BAD: stateful session (prevents horizontal scaling)
@RestController
public class CartController {

    // Server-side session: must route to same server
    private final HttpSession session;

    @PostMapping("/cart/add")
    public void addItem(@RequestBody CartItem item) {
        List<CartItem> cart =
            (List<CartItem>) session.getAttribute("cart");
        if (cart == null) cart = new ArrayList<>();
        cart.add(item);
        session.setAttribute("cart", cart);
    }
}
// Problem: cart lives in this server's memory
// Load balancer routes user to different server -> empty cart
// Requires sticky sessions -> defeats horizontal scaling

// GOOD: externalized state (enables horizontal scaling)
@RestController
@RequiredArgsConstructor
public class CartController {

    private final CartRepository cartRepository;

    @PostMapping("/cart/add")
    public void addItem(
            @RequestHeader("X-User-Id") String userId,
            @RequestBody CartItem item) {
        // State in Redis (any server can access)
        cartRepository.addItem(userId, item);
    }
}

// CartRepository backed by Redis:
@Repository
public class CartRepository {
    private final RedisTemplate<String, CartItem> redis;

    public void addItem(String userId, CartItem item) {
        String key = "cart:" + userId;
        redis.opsForList().rightPush(key, item);
        redis.expire(key, 7, TimeUnit.DAYS);
    }
}
// Now ANY server handles ANY user's cart requests
// Horizontal scaling: just add more CartController instances
// Session state = Redis (shared, persistent)
```

> **Code walkthrough:** The BAD example uses HttpSession which stores cart
> data in JVM memory. The server remembers the cart, but only that specific
> server. When a load balancer routes the same user to a different server,
> the cart is gone. The GOOD example stores cart in Redis using a user ID key.
> Redis is an external shared store accessible by all instances. Any server
> can serve any user. Adding 10 more application servers: just point them at
> the same Redis. Cart state is unaffected. The key principle: "Can I terminate
> this server instance and restart it without losing user data?" If yes:
> the service is stateless. If no: externalize the state.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Scalability means the system can handle more load. You can scale up (bigger
> machine) or scale out (more machines). Scale-out requires that servers
> don't hold local state - all state goes to a shared database or cache.
> That way, a load balancer can send any request to any server.

**Senior / Staff:**
> The hardest scalability challenge is the write path. Read replicas handle
> read scale. Caching handles hot-read scale. But writes must go through
> the primary DB, and eventually the primary becomes the bottleneck.
> Options: CQRS (separate write model, optimized for writes), write-ahead log
> (Postgres WAL, Kafka as commit log), or sharding (split data across multiple
> DBs). Sharding is operationally expensive: cross-shard transactions require
> distributed coordination, resharding is disruptive, and shard hot spots
> (one shard getting all traffic) require rebalancing. Good shard key selection
> is the difference between smooth horizontal write scaling and continuous ops pain.

---

### ⚠️ Common Misconceptions

**Misconception: "Auto-scaling handles all scale issues."**
Auto-scaling adds application servers. It does NOT scale the database
(adding DB instances requires configuration, replication, schema changes).
Auto-scaling is only effective if application servers are the bottleneck.
If the DB is the bottleneck: adding app servers makes it worse (more
connections to the DB). Monitor to find the actual bottleneck before scaling.

---

### 🚨 Failure Modes and Diagnosis

**Failure: N+1 query problem under load**
Symptom: page load fast with 10 users, slow with 1000 users.
Cause: N+1 queries (1 query to get list + N queries for each item).
At low load: 100 DB queries per page. At high load: 100K queries/sec on DB.
Fix: eager loading (JOIN), batch loading (WHERE id IN (...)).
Diagnosis: enable slow query log, count queries per request in testing.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

#### Q1 - What is the CAP theorem's relationship to scalability?

CAP says: distributed systems can only guarantee 2 of 3:
- Consistency: all nodes see the same data at the same time
- Availability: every request gets a response (not an error)
- Partition tolerance: system works despite network partitions

For scalable distributed systems: P (partition tolerance) is not optional
(networks DO partition). So the real choice: C or A during partition.

CP systems (sacrifice availability during partition):
- Choose: return error rather than stale data
- Examples: ZooKeeper, HBase, Mongo (with strong consistency)
- Use: financial transactions, inventory, anything where wrong data is worse than no data

AP systems (sacrifice consistency during partition):
- Choose: return potentially stale data rather than error
- Examples: Cassandra, DynamoDB, CouchDB
- Use: social feeds, product listings, anything where slightly stale is OK

Scalability impact:
- CP: writes may block until replicated -> lower write throughput
- AP: writes to any node, replicate async -> higher write throughput

*What separates good from great:* CAP is about network partition behavior.
In normal operation (no partition), most systems can provide both C and A.
The real-world question: "How often are there partitions in your datacenter?"
Within one datacenter: partitions are rare. Across datacenters: partitions
are common. This is why single-DC systems often ignore CAP (low partition risk)
but multi-region systems must choose explicitly.

---

#### Q2 - How does load balancing contribute to scalability?

Load balancer distributes requests across servers:

```
Client requests -> [LB] -> [Server 1]
                        -> [Server 2]
                        -> [Server 3]

LB algorithms:
  Round-robin: 1->2->3->1->2->3 (equal distribution)
  Weighted: faster servers get more requests
  Least connections: route to server with fewest active requests
  IP hash: same client IP -> same server (poor man's sticky sessions)
  L7 routing: route by URL path (/api -> API servers, /static -> static servers)

LB types:
  L4 (TCP/IP): routes by IP/port, fast, no content inspection
  L7 (HTTP): routes by URL, headers, cookies - more flexible, slower

Health checks:
  LB pings each server every N seconds
  Unhealthy server: removed from pool
  Healthy again: added back
  -> No manual intervention, automatic failover
```

*What separates good from great:* The load balancer itself is a single point
of failure. Solution: active-passive LB pair (one active, one standby with
VIP failover) or anycast routing (multiple LBs with same IP, BGP routing).
Cloud providers abstract this: AWS ALB is inherently HA, auto-scales.
On-premise: HAProxy + keepalived + floating IP. The LB is where you also
implement rate limiting, SSL termination (moves crypto off app servers),
and request routing for A/B testing and canary deployments.

---

#### Q3 - What are the different types of database scaling?

```
Vertical scaling (scale-up):
  Upgrade server: more CPU, RAM, faster SSD
  Simple, no code changes
  Hard limit: biggest available machine
  Single point of failure unless replicated

Read replicas (scale reads):
  Primary handles writes (single source of truth)
  1-N replicas handle reads (async replication)
  Scale: 1 primary + 5 replicas = 6x read capacity
  Lag: replicas may be seconds behind primary
  Use: read-heavy workloads (social media, catalogs)

Caching (scale hot reads):
  Redis/Memcached in front of DB
  Cache hit: ~1ms response
  Cache miss: DB query + cache population
  Hit rate 90%: only 10% of reads hit DB
  Use: static-ish data with high read rate

Connection pooling (scale connections):
  DB connections are expensive (100-1000 max per instance)
  PgBouncer, HikariCP pool connections
  100 app servers * 10 connections each = 1000 (within limit)
  Without pooling: 100 servers * 100 threads each = 10K (over limit)

Sharding (scale writes horizontally):
  Partition data: shard key determines which DB
  User ID % N -> shard N
  Each shard handles writes for its partition
  Cross-shard queries: expensive (scatter-gather)
  Resharding: difficult, requires data migration
```

*What separates good from great:* Start at the top of the list, not the bottom.
Caching is faster to implement than sharding and handles most read bottlenecks.
Read replicas handle read scaling before sharding. Sharding is the last resort
because it changes the data model and makes certain queries impossible or expensive.
Many successful systems never need sharding (correct sizing + caching + replicas
handles it). The teams that shard early pay a high operational price; those
that shard only when necessary defer the complexity until it's proven necessary.

---

#### Q4 - What is the two-phase scaling approach for databases?

Phase 1: Read scaling (most systems stop here)
```
Start: 1 primary, all traffic
  -> Primary CPU: 80%+ (mostly reads)

Add read replicas:
  Reads: go to replicas
  Writes: go to primary
  Result: Primary CPU: 20% (writes only)
          Read capacity: 5x (with 5 replicas)
```

Phase 2: Write scaling (if still needed)
```
Reads handled by replicas and cache.
Primary CPU: still high -> write bottleneck.

Options:
  A. Vertical scale primary (simplest)
  B. CQRS: separate write model (Event Store)
  C. Sharding by user ID, region, or date range
```

Phase 2 is where most teams struggle. The sharding decision:
- What is the shard key? (must distribute writes evenly)
- How to handle cross-shard transactions?
- How to reshard when data grows?

Most systems:
- Phase 1 sufficient for 99% of use cases
- Phase 2 needed at very high write rates (10K+ writes/sec)
- Phase 2 complexity: adopt only when proven necessary

*What separates good from great:* The two-phase approach matches real growth
patterns. Companies start with a single DB, add replicas when reads bottleneck,
add caching when hot-reads bottleneck, and reach for sharding only if write
rates are genuinely high. Premature sharding is a common mistake in "designing
for scale" scenarios where the actual scale doesn't warrant it. In an interview:
show you know the full progression, not just the end state.

---

#### Q5 - How do CDNs contribute to scalability?

CDN (Content Delivery Network): geographically distributed caches.

```
Without CDN:
  User in Japan -> requests image -> origin server in USA
  Round trip: ~200ms (cross-Pacific latency)
  Origin serves image: 1MB
  Bandwidth: origin pays for every byte

With CDN:
  User in Japan -> requests image -> CDN edge in Tokyo
  Cache HIT: ~10ms (local datacenter)
  Cache MISS: CDN fetches from origin, caches in Tokyo
  Next request: always from Tokyo edge
  Origin bandwidth: only pays for unique assets (CDN fetches once)

CDN benefits:
  Latency: 10ms (local edge) vs 150-200ms (cross-continent)
  Bandwidth offloading: 90% cache hit = 90% less origin traffic
  DDoS protection: CDN edge absorbs volumetric attacks
  Availability: CDN serves cached content if origin is down

CDN caching rules:
  Cache: static assets (images, CSS, JS, videos)
         with long Cache-Control: max-age (hours to years)
  Don't cache: authenticated user data, frequently changing data,
               private content (unless signed URLs)
```

*What separates good from great:* CDN cache invalidation is operationally
tricky. Once an asset is in CDN edge caches globally, you can't instantly
remove it. Solutions: (1) versioned URLs (image-v3.png, never same URL twice),
(2) short TTL for mutable assets (trade off: more origin traffic), (3) CDN
API purge (slow: 30-60 seconds to propagate globally). Best practice: static
assets use content-hash URLs (webpack, Vite do this automatically) and
never expire. Mutable assets use short TTL or key/version in URL.

---

#### Q6 - What is auto-scaling and when does it help?

Auto-scaling automatically adds/removes server instances based on metrics:

```
Horizontal Pod Autoscaler (Kubernetes):
  Scale out: when CPU > 70% for 5 minutes
  Scale in: when CPU < 30% for 30 minutes
  Min replicas: 2, Max replicas: 20

  Trigger metrics:
  - CPU utilization (most common)
  - Memory utilization
  - Request queue length (SQS queue depth)
  - Custom metrics (Prometheus: requests/sec)

Auto-scaling behavior:
  Normal: 2 replicas (CPU 40%)
  Traffic spike: CPU hits 80% -> scale to 4 replicas
  Sustained high traffic: scale to 10 replicas
  Traffic drops: scale in (with delay to prevent thrash)

What auto-scaling helps with:
  - Traffic spikes (flash sales, viral content)
  - Cost optimization (fewer instances at night)
  - Gradual load increases

What auto-scaling does NOT help with:
  - Database bottleneck (app scaling makes DB worse)
  - Memory leaks (scaling out doesn't fix the leak)
  - Instant traffic spikes (scale-out takes 2-5 minutes)
  - Stateful services with local state
```

*What separates good from great:* Auto-scaling has a lag of 2-5 minutes
(time to provision, start, warm up new instance). For flash sales or
celebrity tweets: the spike arrives before auto-scaling responds. Solution:
pre-warm (schedule scale-out before known events) or use Lambda/serverless
(cold start ~100ms vs instance cold start ~3 min). Also: scale-in is conservative
by design. If you scale in too aggressively, you scale out again immediately
(thrashing). The rule: scale out fast (on first sign of load), scale in slow
(wait 30+ minutes of low load before reducing).

---

#### Q7 - How does sharding work and what are the trade-offs?

Sharding partitions data across multiple DB instances:

```
Unsharded: 1 DB, all users
  Table: users (100M rows)
  Single primary handles all writes

Sharded by user_id:
  Shard 1: user_id 0-33M   (1 DB instance)
  Shard 2: user_id 33M-66M (1 DB instance)
  Shard 3: user_id 66M-100M(1 DB instance)

  Lookup: user_id = 50M -> Shard 2
  Routing: application maps user_id to shard

  Write scale: 3x (each shard handles 1/3 of writes)
  Read scale: 3x (each shard holds 1/3 of data)

Problems with sharding:
  Cross-shard queries:
    "Find all users who signed up last week"
    -> must query all shards -> scatter-gather
    -> N times more expensive (N = shard count)

  Shard hotspots:
    user_id hashing distributes evenly initially
    Some users more active -> shard imbalance
    Solution: consistent hashing (see SSD-003)

  Resharding:
    Adding shard 4 to reduce load:
    Move user_id 66M-75M from Shard 3 to Shard 4
    -> DB copy + switchover -> downtime or complex migration

  Cross-shard transactions:
    Order spans user data (shard A) + inventory (shard B)
    No ACID across shards without distributed transaction
    Solution: saga pattern (compensating transactions)
```

*What separates good from great:* Shard key selection is the most important
decision in sharding. A good shard key: uniformly distributed, never grows
monotonically (auto-increment IDs concentrate recent data on one shard),
and minimizes cross-shard queries. Twitter uses tweet ID as shard key for
tweets (snowflake ID with time component distributed across shards). Facebook
shards user data by user ID. Instagram uses a modified snowflake that embeds
the shard ID in the ID. The sharding library (Vitess for MySQL) handles
routing transparently. The goal: developers write normal SQL; sharding is
transparent at the infrastructure layer.

---

# Reliability and Availability

---
id: SSD-005
title: Reliability and Availability
category: System Design
difficulty: ★☆☆
interview_weight: high
asked_at: Mid/Senior
seniority: mid
tags: #reliability, #availability, #fault-tolerance, #resilience
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Reliability means the system produces correct results. Availability means
> the system responds to requests. A system can be available but unreliable
> (returns wrong answers). High availability requires: no single points of failure,
> health checks with automatic failover, graceful degradation, and circuit breakers.
> The Five Nines (99.999%) means 5.26 minutes of downtime per year - achievable
> only with redundancy at every layer.

**3 minutes:**
> Availability = Uptime / Total Time. 99.9% = 8.76 hours downtime/year.
> Achieving high availability requires redundancy: multiple instances of each
> component. If one fails: others continue. The challenge: every dependency
> reduces system availability (series reliability). System with 5 components
> each at 99.9% = 99.5% (multiplicative degradation).
>
> Fault tolerance patterns: circuit breaker (stop calling failing services),
> retry with exponential backoff (retry transient failures), timeout (don't
> wait forever), bulkhead (isolate failures to one part), failover (switch to
> backup on failure). Graceful degradation: return cached data when the live
> source is down. Users see slightly stale data instead of an error.
>
> Health checks are how the system knows about failures. Liveness probe: is
> the process alive? Readiness probe: is it ready to receive traffic? Kubernetes
> uses both; liveness failure restarts the pod, readiness failure removes it from
> the load balancer pool.

**Blank Mind Recovery:**

**(1) Restate:** "Reliability and availability are about making systems that
keep working when things go wrong."

**(2) First principles:** "Hardware fails. Software has bugs. Networks partition.
The question is not whether failure happens but whether the system can continue
serving users when it does."

**(3) Three techniques:** Redundancy (multiple copies), Failover (automatic
switch to backup), Graceful Degradation (serve partial results rather than
error).

---

### 📘 Concept Explanation

**Reliability patterns:**

```
Circuit Breaker:
  Normal: requests flow through
  Errors exceed threshold: circuit OPENS
    -> fail fast (return error immediately)
    -> no more requests to failing service
  After timeout: circuit HALF-OPEN
    -> allow one probe request
    -> if success: circuit CLOSES (normal)
    -> if fail: circuit stays OPEN

  Benefit: prevents cascade failure
  Without: 1 slow service -> callers wait -> timeout
           callers timeout -> THEIR callers wait -> cascade

Retry with Exponential Backoff:
  Attempt 1: immediate
  Attempt 2: wait 1 second
  Attempt 3: wait 2 seconds
  Attempt 4: wait 4 seconds
  Max: 5 attempts
  With jitter: add random 0-500ms to prevent thundering herd

  Apply to: transient failures (network blip, temporary overload)
  Don't apply to: 4xx errors (client error, retry won't help)

Timeout:
  Every network call MUST have a timeout
  Without timeout: one slow service -> all threads blocked -> OOM
  Aggressive timeout (100ms) + circuit breaker = resilient

Bulkhead:
  Isolate resources per downstream service
  Service A: thread pool of 20 threads
  Service B: thread pool of 20 threads
  If Service B hangs: its 20 threads fill up
  Service A's 20 threads unaffected
  Without bulkhead: shared thread pool -> both fail together
```

---

### 💻 Code Example

```java
// Circuit Breaker with Resilience4j
@Service
public class UserProfileService {

    @CircuitBreaker(
        name = "userService",
        fallbackMethod = "getUserFallback")
    @Retry(name = "userService")
    @TimeLimiter(name = "userService")
    public CompletableFuture<UserProfile> getUser(
            String userId) {
        return CompletableFuture.supplyAsync(() ->
            userServiceClient.getProfile(userId));
    }

    // Fallback: return cached/default profile
    public CompletableFuture<UserProfile> getUserFallback(
            String userId, Throwable ex) {
        log.warn("User service unavailable for {}: {}",
            userId, ex.getMessage());
        // Return cached profile or anonymous default
        return CompletableFuture.completedFuture(
            profileCache.getOrDefault(
                userId, UserProfile.anonymous()));
    }
}
```

```yaml
# application.yml - Resilience4j config
resilience4j:
  circuitbreaker:
    instances:
      userService:
        sliding-window-size: 10
        failure-rate-threshold: 50    # 50% failures -> open
        wait-duration-in-open-state: 10s
        permitted-calls-in-half-open: 3
  retry:
    instances:
      userService:
        max-attempts: 3
        wait-duration: 500ms
        retry-exceptions:
          - java.io.IOException
          - java.net.ConnectException
  timelimiter:
    instances:
      userService:
        timeout-duration: 2s
```

> **Code walkthrough:** The three Resilience4j annotations stack:
> TimeLimiter wraps the call with a 2-second timeout. Retry retries up to 3 times
> on IOException or ConnectException (transient errors). CircuitBreaker counts
> failures across calls and opens if 50% fail within the 10-call window.
> The fallback method is called when ALL attempts fail (after retry) OR when
> the circuit is open (fail-fast). The fallback returns cached data, keeping
> the user experience functional even when the user service is down.
> The combination: retry handles transient blips, circuit breaker handles
> sustained failures, timeout prevents hanging threads.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> High availability means the system keeps working even when some parts fail.
> You achieve this by having multiple copies of everything (redundancy), health
> checks that detect failures, and load balancers that route around failed
> instances. A circuit breaker prevents your service from repeatedly calling
> a service that's already down - instead it fails fast and tries again after
> a timeout.

**Senior / Staff:**
> The reliability challenge is the failure cascade: one slow service causes
> callers to block threads; blocked threads mean the caller can't serve other
> requests; caller's callers see failures; entire system degrades. Defense: timeout
> (bound the wait), circuit breaker (stop calling failed services), bulkhead
> (isolate thread pools per downstream). Combined: total thread pool exhaustion
> is impossible because each downstream has bounded resources. Additionally:
> design for graceful degradation. If the recommendation service fails, show
> popular items instead of an error. If the user service fails, show cached
> profile instead of "User not found." Partial functionality beats total failure.

---

### ⚠️ Common Misconceptions

**Misconception: "Redundancy alone guarantees availability."**
Redundancy prevents single-node failures. But all redundant nodes can fail
simultaneously (software bug, datacenter power, shared dependency).
Active-active multi-region helps but adds latency and consistency complexity.
True availability = redundancy + isolation + graceful degradation + proven failover.
Untested failover is not failover - it's hope. Chaos engineering tests that
failover actually works.

---

### 🚨 Failure Modes and Diagnosis

**Failure: Retry storm (retry amplification)**
Symptom: downstream service recovering, but load keeps it down.
Cause: all callers retry simultaneously on failure recovery.
A service that fails -> all callers retry -> 10x traffic spike on recovery
-> overwhelms recovering service -> fails again -> loop.
Fix: exponential backoff + jitter (randomizes retry timing),
circuit breaker (only probe with 1 request in half-open state).

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

#### Q1 - What is the difference between reliability, availability, and durability?

**Reliability:** System produces correct results.
- Measured: error rate (% of requests returning wrong results)
- Example: database returns correct data, not stale/corrupted

**Availability:** System responds to requests (not necessarily correctly).
- Measured: uptime % (time system responds vs. total time)
- Formula: MTBF / (MTBF + MTTR)
  - MTBF: Mean Time Between Failures
  - MTTR: Mean Time To Repair

**Durability:** Data is not lost.
- Measured: % of data retained over time
- Example: S3 provides 11 nines (99.999999999%) durability
- Durability != availability: S3 file exists (durable) but bucket may be temporarily unreachable

**Relationships:**
- Available but unreliable: returns wrong answers quickly
- Reliable but unavailable: correct when up, but often down
- Durable but unavailable: data safe but can't access it

*What separates good from great:* In system design, each requires a different
mechanism. Reliability: validated inputs, checksums, idempotent operations.
Availability: redundancy, failover, circuit breakers. Durability: replication
across AZs/regions, write-ahead log, backups. A naive "just make it reliable"
answer conflates the three. S3's 11 nines durability is achieved through
erasure coding across 3+ AZs; availability is 99.99% (separate concern).
An interview answer that separates these three is senior-level thinking.

---

#### Q2 - How do you design for zero-downtime deployments?

Zero-downtime requires traffic to continue during code swap:

```
Blue-Green Deployment:
  Blue: current production
  Green: new version
  Step 1: deploy green (no traffic)
  Step 2: test green directly
  Step 3: switch LB: all traffic -> green
  Step 4: old blue available for instant rollback
  Rollback: switch LB back to blue (seconds)
  Problem: double infrastructure cost during transition

Canary Deployment:
  Step 1: deploy new version to 1% of servers
  Step 2: monitor error rates, latency for canary
  Step 3: if healthy: gradually increase % (1->10->50->100)
  Step 4: if problems: route 0% to canary (rollback)
  Benefit: production validation with minimal blast radius
  Problem: two versions running simultaneously
           (backward-compatible API required)

Rolling Deployment:
  Step 1: update 1 of 10 servers (10% capacity during update)
  Step 2: verify healthy (readiness probe passes)
  Step 3: update next server
  Step 4: continue until all updated
  Kubernetes: RollingUpdate strategy does this automatically
  Problem: two versions serving traffic simultaneously
```

Database changes in zero-downtime:
- Expand-contract pattern:
  1. Add new column (nullable, no defaults required)
  2. Deploy code that writes both old and new column
  3. Migrate data (backfill new column)
  4. Deploy code that reads new column
  5. Remove old column

*What separates good from great:* Database migrations are the hardest part of
zero-downtime deployment. Application servers are stateless (swap freely).
DB schema changes are stateful (must be backward-compatible). The expand-contract
pattern (also called: parallel change, strangler fig at schema level) ensures
both old and new code can run simultaneously. Tools: Flyway/Liquibase handle
migration scripts but don't enforce compatibility. The developer must ensure
each migration is backward-compatible. The deployment pipeline should check:
"Can the current production code (pre-deploy) run against the new schema?"

---

#### Q3 - What are health checks and how do they work?

Health checks verify a service is healthy before sending traffic:

```
Types of health checks:

1. Process-level health check:
   Is the process running? (TCP connect on port 8080)
   Simple: if process crashes, health check fails

2. HTTP health check:
   GET /actuator/health
   Returns: {"status": "UP"}
   Can verify DB connection, cache connection, disk space

3. Deep health check:
   Verify actual functionality:
   - Can connect to DB and run a query?
   - Can reach dependent services?
   - Is queue consumer processing?
   Risk: deep checks have side effects, can fail for wrong reasons

Kubernetes health check types:
  Liveness probe:
    - Fails: pod RESTARTED
    - Use for: deadlocks, OOM, unrecoverable state
    - Interval: 10s, timeout: 5s, fail threshold: 3
    - 30 seconds before pod restarted

  Readiness probe:
    - Fails: pod REMOVED from service endpoints
             (no traffic, but not restarted)
    - Use for: still starting, temporarily unavailable
    - Ensures traffic only when pod is READY

  Startup probe (K8s 1.16+):
    - Fails until app says it's started
    - Prevents premature liveness failure for slow-starting apps
```

*What separates good from great:* The wrong health check is worse than no
health check. A health check that includes downstream service reachability
(is DB healthy?) makes your pod unavailable when the DB has a transient blip,
even though your app could serve cached requests. Rule: readiness probe =
can I serve traffic right now? Liveness probe = am I in a recoverable state?
The DB health check belongs in the readiness probe (don't send traffic if I
can't reach DB), not the liveness probe (a DB blip shouldn't restart my pod).

---

#### Q4 - How does a distributed system handle partial failures?

Partial failure: some components work, others don't.

```
Example: checkout page
  Components: user service, cart service, payment service,
              notification service, inventory service

Full failure: all down (easy: show error page)

Partial failure: payment service is down
  Option 1: show "Service unavailable" for entire checkout
    -> Bad: user can't buy anything, loses sale
  Option 2: graceful degradation
    -> Disable checkout button, show "Payment service unavailable.
       Your cart is saved. Try again soon."
    -> Better: partial functionality preserved

Partial failure: notification service is down
  Option 1: checkout fails (notification service errors propagate)
    -> Bad: notification is non-critical, should not block checkout
  Option 2: async notification with retry
    -> Checkout succeeds, notification queued
    -> Queue retries until notification service recovers
    -> User gets email delayed, not missing

Partial failure: inventory service is slow
  Option 1: checkout waits (timeout: 30 seconds)
    -> Bad: user waiting 30 seconds = abandonment
  Option 2: timeout (2 seconds) + fallback
    -> Proceed with checkout, verify inventory async
    -> If inventory check fails: cancel + refund + notify
    -> Trade-off: oversell risk vs. user experience
```

*What separates good from great:* Partial failures require explicit decisions
about which services are "critical path" (must succeed for operation to complete)
vs "non-critical" (operation succeeds even if these fail). This classification
should be documented and enforced in code (circuit breaker with fallback vs
direct call with no fallback). Payment is critical path. Notification is not.
Recommendation service is not. Making this explicit prevents the "someone added
a dependency and now checkout is down because the recommendation service is slow"
incident that happens in real systems.

---

#### Q5 - What is fault injection and why is it important?

Fault injection deliberately introduces failures to test resilience:

```
Types of fault injection:
  Network failures: drop packets, add latency, partition
  Service failures: kill pods, return errors
  Resource failures: fill disk, exhaust CPU/memory
  Dependency failures: make DB unavailable, slow responses

Chaos Engineering (Netflix model):
  Chaos Monkey: randomly terminates EC2 instances in production
    -> If system can't handle random termination:
       fix the resilience gap before real failure does
  Chaos Kong: terminates entire availability zones
    -> Tests regional failover
  Latency Monkey: injects latency into service calls
    -> Tests circuit breakers, timeouts

Why in production?
  Staging never matches production exactly
  Traffic patterns, data volumes, timing: all different
  Failures that only manifest under production conditions
    -> Must be tested in production

Beginner approach: fault injection in staging
  -> At least tests the obvious resilience gaps
  -> Safer than production experiments

Advanced: game days
  Schedule time to break production intentionally
  Entire team observes the failure mode
  Verify monitoring detects it, runbooks work, recovery time
```

*What separates good from great:* Chaos engineering requires mature monitoring
and on-call practices as prerequisites. Running Chaos Monkey without first
ensuring that failures trigger alerts and on-call responses just creates
undetected outages. The prerequisite: observability (metrics, logs, traces)
and incident response. The benefit: teams that practice failure recovery
recover faster in real incidents because they've rehearsed. MTTR (Mean Time
To Recover) decreases with chaos engineering experience.

---

#### Q6 - How do you design for graceful degradation?

Graceful degradation: serve partial results instead of errors when components fail.

```
Design patterns for graceful degradation:

1. Feature flags + fallback:
   if (featureService.isEnabled("recommendations")) {
       return recommendationService.get(userId);
   } else {
       return popularItems.getTopTen();  // fallback
   }

2. Stale cache fallback:
   Cache TTL: 5 minutes (normal)
   Service unavailable:
     -> Extend TTL: serve 1-hour-old cache
     -> User sees slightly stale data, not error

3. Placeholder content:
   Image service down:
   -> Return placeholder image URL
   -> Not blank space or error

4. Read-only mode:
   DB primary down, replicas up:
   -> Disable write operations
   -> Serve reads from replicas
   -> Display: "Read-only mode. Writes temporarily disabled."

5. Progressive enhancement (web):
   JavaScript fails:
   -> HTML still renders with basic functionality
   -> No JS = no enhanced features, but core works

Graceful degradation decision matrix:
   Component fails    -> Fallback
   Recommendation svc -> Top items by category
   User profile svc   -> Anonymous/default profile
   Search svc         -> Empty results + message
   Inventory svc      -> Proceed, check async
   Payment svc        -> Queue for later (high risk: money)
   Auth svc           -> Fail closed (don't allow access)
```

*What separates good from great:* The fallback design must be explicit in code
review. The question: "What does this endpoint return if service X is down?"
If the answer is "error 500" for a non-critical service: design gap. If the
answer is "we return a cached response" for a critical service where staleness
would cause harm (account balance): wrong fallback. Every service dependency
needs an explicit decision: fail open (serve partial/stale), fail closed (return
error), or transparent (don't route to failing service). Security-sensitive
components (auth, authorization): always fail closed.

---

#### Q7 - What is SLA/SLO/SLI and how do they relate to system design?

```
SLI (Service Level Indicator):
  The actual measurement
  Examples:
    - Request success rate (% 2xx responses)
    - P99 latency (milliseconds)
    - Error rate (% 5xx responses)
    - Availability (% time service responds)

SLO (Service Level Objective):
  Internal target for SLI
  Examples:
    - 99.9% of requests succeed (SLI < 0.1% error rate)
    - P99 latency < 200ms
    - System available 99.95% of time
  SLO is what you design for

SLA (Service Level Agreement):
  External contract (with legal consequences if violated)
  Usually lower than SLO (internal target + safety margin)
  Examples:
    - AWS EC2 SLA: 99.99% monthly uptime
    - If violated: 10% service credit
  SLA = SLO - safety margin

Error Budget:
  SLO 99.9% availability ->
    Error budget = 0.1% = 8.76 hours/year
    Engineering teams can "spend" error budget on deployments
    When budget exhausted: freeze deployments, focus on reliability

Design implications:
  SLO drives architecture decisions:
    99.9% -> N+1 redundancy within one datacenter
    99.99% -> Multi-AZ with auto-failover
    99.999% -> Multi-region active-active
  Each nines costs: compute, complexity, operational burden
```

*What separates good from great:* Error budgets are the key insight that makes
SLOs actionable. A team with 8.76 hours/year error budget can have roughly 3
deployments that each cause 3-hour outages. When budget runs low: the system
itself tells you to slow down and invest in reliability rather than features.
This is a data-driven way to balance feature velocity with reliability work.
Google's SRE book popularized this; it's now standard practice at mature
engineering organizations. The design question: what SLO is the product team
committing to? That SLO determines the architecture.

---

# Latency vs Throughput

---
id: SSD-006
title: Latency vs Throughput
category: System Design
difficulty: ★☆☆
interview_weight: medium
asked_at: Mid/Senior
seniority: mid
tags: #latency, #throughput, #performance, #littles-law
status: draft
version: 1
---

### 🎯 Model Answer

**30 seconds:**
> Latency is how long one request takes (milliseconds). Throughput is how many
> requests complete per second (QPS). They are related by Little's Law:
> Throughput = Concurrency / Latency. Optimizing for low latency (fast individual
> responses) often means not batching, using memory-first access, and minimizing
> hops. Optimizing for high throughput often means batching, pipelining, and
> saturating resources. Most user-facing systems optimize latency; background
> processing optimizes throughput.

**3 minutes:**
> Latency and throughput are often at odds. A batch processing system achieves
> high throughput by accumulating work and processing it all at once - but each
> item waits for the batch to fill. A streaming system processes each item
> immediately - low latency, lower throughput (no batching efficiency).
>
> Little's Law connects them: L = λW, where L = average items in system,
> λ = throughput (items/second), W = latency (time in system). If your system
> has 100 concurrent requests and each takes 100ms: throughput = 100 / 0.1 = 1000
> requests/second. To double throughput: either double concurrency (add servers)
> OR halve latency.
>
> The latency target determines architecture. <1ms: in-memory only (Redis).
> <10ms: local SSD. <100ms: can afford one network hop. <1000ms: can afford
> multiple hops + DB. >1000ms: acceptable for heavy computation.
> Every millisecond of latency budget determines what you can afford in the call chain.

**Blank Mind Recovery:**

**(1) Restate:** "Latency = speed of one request. Throughput = how many requests
per second."

**(2) First principles:** "A fast factory line (high throughput) might process
each item slowly if items wait in queue. A custom shop (low latency) completes
each item fast but can only do a few at a time."

**(3) Little's Law:** Throughput = Concurrency / Latency. To increase throughput:
add concurrency (more threads/servers) or reduce latency (faster processing).

---

### 📘 Concept Explanation

**The latency-throughput relationship:**

```
Little's Law:
  L = λ * W
  L = average number of items in system
  λ = throughput (items/sec)
  W = average latency (time per item)

Rearranged:
  λ = L / W
  Throughput = Concurrency / Latency

Example:
  Web server with 100 threads
  Each request takes 100ms
  Max throughput = 100 / 0.1s = 1000 requests/sec

  Latency doubles to 200ms (slow DB query):
  Max throughput = 100 / 0.2s = 500 requests/sec
  Latency directly halves throughput!

Queue buildup:
  Arrival rate > throughput -> queue grows
  Queue grows -> latency grows (items wait in queue)
  Latency grows -> throughput drops further (Little's Law)
  Cycle: overload -> growing queue -> death spiral

Latency percentiles:
  P50 (median): 50% of requests are this fast or faster
  P95: 95% are this fast; 1 in 20 is slower
  P99: 99% are this fast; 1 in 100 is slower
  P999: 99.9% are this fast; 1 in 1000 is slower

  Long tail: P50=10ms, P99=500ms
  The 1% slow requests often represent:
  - Database query misses index (full table scan)
  - GC pause (Java stop-the-world)
  - Cache miss + slow DB query
  - Lock contention
```

**Latency budget:**

```
P99 latency budget: 200ms (requirement)

Component latencies:
  Network (client -> server): ~10ms
  API Gateway: ~5ms
  Service A: ~50ms
    - Cache lookup: ~2ms
    - Cache miss -> DB: ~30ms
  Service B call: ~50ms
    - Network: ~5ms
    - Processing: ~20ms
    - Response: ~5ms
  Response serialization: ~5ms
  Network (server -> client): ~10ms

Total: 10+5+50+50+5+10 = 130ms (within 200ms budget)

If P99 SLO is 200ms and P99 is 180ms:
  20ms headroom
  Can't add another service call (~50ms) without SLO violation
  Must optimize existing calls before adding
```

---

### 💻 Code Example

```java
// BAD: synchronous chain (latency adds up)
@GetMapping("/dashboard")
public Dashboard getDashboard(String userId) {
    // 3 serial calls = 3 * ~50ms = 150ms minimum
    UserProfile profile = userService.get(userId);  // 50ms
    List<Order> orders = orderService.get(userId);  // 50ms
    List<Recommendation> recs =
        recoService.get(userId);  // 50ms
    return new Dashboard(profile, orders, recs);
    // Total: ~150ms P50, ~500ms P99
}

// GOOD: parallel calls (latency = max, not sum)
@GetMapping("/dashboard")
public Dashboard getDashboard(String userId) {
    // 3 parallel calls = max(~50ms each) = ~50ms P50
    CompletableFuture<UserProfile> profileFuture =
        CompletableFuture.supplyAsync(
            () -> userService.get(userId));
    CompletableFuture<List<Order>> ordersFuture =
        CompletableFuture.supplyAsync(
            () -> orderService.get(userId));
    CompletableFuture<List<Recommendation>> recoFuture =
        CompletableFuture.supplyAsync(
            () -> recoService.get(userId));

    // Wait for all three (parallel, not serial)
    CompletableFuture.allOf(
        profileFuture, ordersFuture, recoFuture).join();

    return new Dashboard(
        profileFuture.join(),
        ordersFuture.join(),
        recoFuture.join());
    // Total: ~50ms P50 (3x improvement!)
}
```

> **Code walkthrough:** The BAD example makes 3 service calls sequentially.
> Each call is ~50ms P50. Total: 150ms. At P99 (each call 200ms): 600ms.
> The GOOD example makes all 3 calls in parallel using CompletableFuture.supplyAsync().
> The calls start simultaneously. Total wait = max(50, 50, 50) = 50ms P50.
> The P99 improvement is even more significant: max(200, 200, 200) = 200ms
> (vs 600ms serial). This is the single most impactful latency optimization
> for aggregation endpoints. Prerequisite: each service call must be independent
> (no result of A needed by B or C).

```java
// Measuring P99 latency with Micrometer
@Service
public class OrderService {

    private final MeterRegistry meterRegistry;

    public Order getOrder(Long orderId) {
        Timer.Sample sample = Timer.start(meterRegistry);
        try {
            Order order = orderRepository.findById(orderId)
                .orElseThrow();
            // Record success latency
            sample.stop(Timer.builder("order.get.latency")
                .tag("status", "success")
                .register(meterRegistry));
            return order;
        } catch (Exception ex) {
            sample.stop(Timer.builder("order.get.latency")
                .tag("status", "error")
                .register(meterRegistry));
            throw ex;
        }
    }
}

// In Prometheus:
// order_get_latency_seconds{status="success",quantile="0.99"}
// -> P99 latency for successful order gets

// Grafana alert:
// IF order_get_latency_p99 > 0.5 (500ms)
// -> alert: SLO breached
```

> **Code walkthrough:** Micrometer's Timer records both duration and count.
> The tag "status" lets you distinguish success vs error latency. In Prometheus,
> histograms with quantile labels expose P50/P95/P99. The important detail:
> instrument both the happy path AND error path. If errors are slow (DB timeout:
> 30 seconds), the P99 includes those errors. Knowing that errors are slow
> (vs fast failures) helps diagnose whether circuit breakers or timeouts need
> adjustment.

---

### 🎓 Answers by Seniority

**Junior / Mid:**
> Latency is how fast a single request is answered (milliseconds). Throughput
> is how many requests the system handles per second. To reduce latency:
> cache hot data in memory, make service calls in parallel instead of serial,
> reduce the number of hops. To increase throughput: add more servers, use
> connection pooling, process in batches for background tasks.

**Senior / Staff:**
> Little's Law makes the latency-throughput relationship quantitative.
> If my service has 200 concurrent requests and P50 latency is 50ms:
> throughput = 200 / 0.05 = 4000 QPS. If I optimize latency from 50ms to 25ms:
> throughput doubles to 8000 QPS WITHOUT adding servers. This is why latency
> optimization is often more cost-effective than horizontal scaling.
> Conversely: if DB queries suddenly take 500ms instead of 50ms (10x slowdown),
> my throughput drops from 4000 QPS to 400 QPS - causing a queue build-up that
> makes latency worse, causing more queue build-up - a death spiral.
> Monitoring P99 latency and having circuit breakers that fail fast prevent
> this cascade.

---

### ⚠️ Common Misconceptions

**Misconception: "P50 latency is the most important metric."**
P50 is median - it reflects the typical user experience. But P99 represents
the tail experience: 1 in 100 users waits at least P99 milliseconds.
At 1M QPS: 10,000 users/second experience P99 latency. High P99 while
low P50 indicates: most requests are fast but occasional slow requests
(cache misses, GC pauses, lock contention). Fix P99 to fix the worst user experience.

---

### 🚨 Failure Modes and Diagnosis

**Failure: GC pauses causing P99 spikes**
Symptom: P50 = 10ms, P99 = 1000ms (100x difference).
Cause: Java stop-the-world GC pauses every few seconds.
Diagnosis: GC logs, Micrometer jvm.gc.pause metric.
Fix: tune GC (G1GC or ZGC for lower pauses), reduce object allocation,
increase heap size to reduce GC frequency.

---

### 🎯 Interview Deep-Dive

**Timing:** Easy ★☆☆ - 7 questions.

---

#### Q1 - What is the difference between P50, P95, and P99 latency?

```
Given 100 requests sorted by latency:
  10ms, 12ms, ..., 50ms (P50), ..., 100ms (P95), ..., 500ms (P99), 2000ms

P50 (median): 50th percentile
  50ms = half of requests complete in 50ms or less
  Represents typical user experience

P95: 95th percentile
  100ms = 95% of requests complete in 100ms or less
  Represents most users' experience including slower cases

P99: 99th percentile
  500ms = 99% complete in 500ms or less
  Represents users who experience the tail

P999: 99.9th percentile
  2000ms = 2 seconds for 0.1% of requests
  1 in 1000 users waits 2 seconds

Why percentiles matter:
  At 1M QPS:
  P95 = 100ms: 50,000 users/sec see >= 100ms
  P99 = 500ms: 10,000 users/sec see >= 500ms
  P999 = 2s: 1,000 users/sec see >= 2 seconds

  Percentile-based SLOs:
  "P99 < 200ms" is more meaningful than "average < 100ms"
  Average hides outliers; percentiles expose the tail
```

*What separates good from great:* High P99 with low P50 indicates a bimodal
distribution - two types of requests. Fast path (cache hit, P50) and slow
path (cache miss + DB, P99). Investigation: log a sample of P99 requests with
full traces. Usually reveals: missing cache, N+1 query, lock wait, GC pause.
The fix targets the slow path specifically. Average-based SLOs are dangerous
because you can have terrible P99 with excellent P50 - average looks fine,
10,000 users/sec suffer.

---

#### Q2 - How does queue theory help understand system performance?

Queue theory models: arrival rate, service rate, queue length, wait time.

```
M/M/1 Queue model (simplest):
  λ = arrival rate (requests/sec)
  μ = service rate (max requests/sec with 1 server)
  ρ = utilization = λ/μ

  When ρ < 1: queue stable (service faster than arrivals)
  When ρ >= 1: queue grows without bound (system overloaded)

  Average wait time (in queue): ρ / (μ(1-ρ))

  Example:
  λ = 900 req/sec, μ = 1000 req/sec
  ρ = 0.9 (90% utilization)
  Wait = 0.9 / (1000 * (1-0.9)) = 9ms

  Increasing load:
  λ = 990 req/sec, ρ = 0.99
  Wait = 0.99 / (1000 * 0.01) = 99ms (11x longer!)

  λ = 999 req/sec, ρ = 0.999
  Wait = 0.999 / (1000 * 0.001) = 999ms (110x longer!)

Key insight: near 100% utilization, latency explodes
  -> Never run components at >70-80% utilization
  -> Keep headroom for traffic spikes
```

*What separates good from great:* The queue model explains why adding capacity
has diminishing returns when you're near saturation. At 99% utilization,
reducing by 1% (from 99% to 98%) halves the queue latency. But getting from
99% to 80% requires 5x improvement. This is why systems under extreme load need
traffic shedding (load shedding / circuit breaking) rather than just more capacity
- you can't add capacity fast enough to handle a sudden 10x traffic spike.
The defensive pattern: keep systems at max 70% utilization in normal operation
to absorb 2-3x spikes without queue buildup.

---

#### Q3 - What is the impact of serialization on latency and throughput?

Serialization (converting objects to bytes for transmission) has measurable cost:

```
Serialization benchmarks (rough order of magnitude):
  Java object -> JSON (Jackson): ~1-10 microseconds per object
  Java object -> Protobuf: ~0.1-1 microseconds per object
  Java object -> Avro: ~0.5-2 microseconds per object

At 100K QPS with 10 microseconds JSON overhead:
  CPU time for JSON: 100K * 10us = 1 second of CPU/sec
  With 4 CPUs: 25% CPU just for JSON serialization

At 1M QPS:
  JSON: 10 seconds of CPU/sec -> needs 10+ CPU cores just for serialization
  Protobuf: 1 second of CPU/sec -> 10x reduction

Payload size impact:
  JSON response: 1 KB
  Protobuf response: 300 bytes (3x smaller)
  At 1M QPS:
  JSON bandwidth: 1M * 1KB = 1 GB/sec
  Protobuf bandwidth: 1M * 300B = 300 MB/sec
  -> 3x bandwidth reduction = 3x CDN/network cost reduction
```

*What separates good from great:* JSON's human readability is a development
and debugging benefit, not a performance benefit. For external APIs: JSON
(interoperability). For internal service-to-service calls at high volume:
Protobuf or Avro. gRPC (uses Protobuf) is the standard for high-performance
internal microservices. REST+JSON is the standard for external APIs.
The decision point: if internal calls exceed 100K QPS with significant
payload sizes, measure and compare. Below that: JSON is fine. The engineering
cost of Protobuf IDL management must pay for itself.

---

#### Q4 - How do you optimize the critical path latency?

Critical path: the longest sequence of operations that determines total latency.

```
Example: Checkout flow
  Sequential (current):
    1. Validate cart: 20ms
    2. Check inventory: 30ms (can be parallel)
    3. Calculate price: 15ms (can be parallel)
    4. Charge payment: 100ms (must be last, sequential)
    5. Create order: 20ms
    6. Send confirmation: 30ms (async, non-critical path)
    Total sequential: 215ms

  Optimized (parallelize where possible):
    Step 1 -> [Step 2 || Step 3] -> Step 4 -> Step 5
    1. Validate cart: 20ms
    2+3. Parallel: max(30ms, 15ms) = 30ms
    4. Charge payment: 100ms
    5. Create order: 20ms
    Step 6: async (off critical path)
    Total: 20 + 30 + 100 + 20 = 170ms (21% improvement)

  Further optimization: cache inventory + pricing
    Cache hit: ~2ms each (vs 30ms, 15ms DB calls)
    New critical path: 20 + max(2,2) + 100 + 20 = 142ms
    (34% improvement from caching alone)
```

*What separates good from great:* Critical path analysis shows which operations
are worth optimizing. The payment call (100ms) dominates. Caching inventory
(30ms -> 2ms) saves 28ms - significant as a % of non-payment time, but only
a 13% overall improvement because payment still dominates. To improve overall
latency: either reduce payment latency (negotiate SLAs with payment processor,
pre-authorize), or parallelize all pre-payment steps. The architectural insight:
put the most latency-sensitive operation last (payment) and parallelize everything
before it.

---

#### Q5 - What is connection pooling and how does it affect throughput?

Creating DB connections is expensive (~100ms per connection):

```
Without connection pool:
  Request arrives
  -> Create new DB connection (100ms)
  -> Execute query (10ms)
  -> Close connection
  Total: 110ms, mostly overhead
  1000 requests/sec: 1000 * 100ms = 100 seconds of connection time
  -> Connection establishment is the bottleneck

With HikariCP connection pool:
  On startup: create 10 connections (once)
  Request arrives
  -> Acquire connection from pool (<1ms)
  -> Execute query (10ms)
  -> Return connection to pool
  Total: 11ms
  10x fewer connections to DB (fewer TCP connections, less DB memory)
  Throughput limited by: pool size * (1/query_time)
  = 10 * (1/0.01s) = 1000 QPS from 1 server

Pool sizing:
  Too small: requests wait for connection (latency spike)
  Too large: DB overwhelmed (too many concurrent queries)
  Rule of thumb: (number of cores * 2) + disk spindles
    For 4-core server: (4*2) + 1 = ~9 connections
    HikariCP default: 10 connections
    Adjust based on: query duration, CPU vs I/O bound queries
```

*What separates good from great:* Connection pool exhaustion is a common
production issue. Symptoms: "HikariPool - Connection is not available, request
timed out" in logs. Cause: requests take longer than usual (slow queries, network
issue) -> all connections in use -> new requests wait -> timeout. Fix: increase
pool size (short term), fix slow queries (long term). Monitoring: pool pending
connections metric (hikaricp.pending.connections). Alert if >0 for >30 seconds.
The real fix is always the slow query - more connections mask the problem.

---

#### Q6 - How does caching reduce latency and increase throughput?

Caching moves frequently accessed data closer to the compute:

```
Latency comparison:
  L1 CPU cache: ~1 ns
  L2 CPU cache: ~4 ns
  RAM: ~100 ns
  Redis (network + memory): ~500 us (500,000 ns)
  DB (network + SSD): ~5 ms (5,000,000 ns)
  DB (network + HDD): ~50 ms (50,000,000 ns)

  Redis vs HDD DB: 100,000x faster
  Redis vs SSD DB: 10,000x faster
  In-process cache vs Redis: 500x faster

Throughput calculation:
  Without cache:
    DB: 10K QPS max
    Application: needs 100K QPS
    -> Need 10 DB instances (or caching)

  With Redis cache (90% hit rate):
    Redis: 100K QPS (90% served from cache)
    DB: 10K QPS (10% cache misses)
    -> Single DB instance sufficient

Cache sizing with Pareto:
  Total data: 100 GB
  20% of data = 80% of requests:
    20 GB in cache handles 80K of 100K QPS from cache
    DB sees only 20K QPS (cache misses + 20% non-cacheable)
  Cache hit rate: 80%
  DB reduction: 80%
```

*What separates good from great:* Cache hit rate is the key metric.
80% hit rate = 5x reduction in DB load. 99% hit rate = 100x reduction.
To maximize hit rate: (1) choose the right TTL (too short = frequent misses,
too long = stale data), (2) pre-warm on startup, (3) use LRU eviction
(evict least recently used first, keeping hot data). The anti-pattern:
caching large objects (videos, images) in Redis. Redis is RAM; RAM is expensive.
Cache metadata (IDs, URLs) in Redis; serve binary data from CDN or blob storage.

---

#### Q7 - What is the relationship between concurrency and latency under load?

As concurrency increases, latency eventually increases due to:

```
1. Lock contention:
   More concurrent requests -> more threads competing for locks
   Thread acquiring lock: low latency
   Thread waiting for lock: latency = lock_holder_time + wait

2. CPU scheduling:
   CPU cores = physical parallelism limit
   More threads than cores -> context switching overhead
   Context switch: ~1-10 microseconds per switch
   At high concurrency: context switching dominates

3. Queue buildup (Little's Law):
   Throughput limited by slowest component
   If arrivals > service rate -> queue grows
   Every item in queue adds to latency

4. Cache/memory pressure:
   More concurrent threads -> larger working set
   Working set exceeds CPU cache -> more cache misses
   Cache miss -> RAM or disk access -> higher latency

Practical implication:
  Optimal concurrency = number of CPUs (CPU-bound work)
  Optimal concurrency = more (I/O-bound, thread waits for I/O)

  Virtual threads (Java 21+):
    Lightweight: millions possible without OS thread overhead
    Ideal for I/O-bound workloads (HTTP calls, DB queries)
    CPU-bound: still limited by core count
```

*What separates good from great:* The optimal concurrency number is not infinite
and not one - it depends on the workload. CPU-bound: one thread per core
(no context switching). I/O-bound: many threads per core (while one thread waits
for I/O, others use CPU). Java 21 virtual threads allow I/O-bound workloads
to use 10,000+ "threads" without OS thread overhead. This eliminates the need
for reactive programming (CompletableFuture chains) for most I/O-bound cases:
write synchronous-looking code, Java virtualizes the concurrency. The residual
challenge: shared state (databases, caches) still has limited throughput -
the bottleneck moves from thread management to resource capacity.
