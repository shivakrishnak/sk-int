---
layout: default
title: "NoSQL - L1 Key-Value Stores"
parent: "NoSQL"
nav_order: 2
permalink: /nosql/l1-key-value-stores/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Redis Data Structures and Commands](#redis-data-structures-and-commands) | ★☆☆ |
| 2 | [Redis Caching Patterns](#redis-caching-patterns) | ★☆☆ |
| 3 | [Key-Value Store Design Patterns](#key-value-store-design-patterns) | ★☆☆ |

---

# Redis Data Structures and Commands

---

### 🎯 Model Answer

**30 seconds:**
> Redis is an in-memory data structure server. Beyond simple key-value storage, it
> provides native data structures: Strings (counters, cached values), Hashes (objects),
> Lists (queues, stacks), Sets (unique members), Sorted Sets (ranked leaderboards), and
> HyperLogLog (approximate cardinality). Each data structure has dedicated atomic
> commands. Redis processes commands in a single-threaded event loop, making all
> operations inherently thread-safe.

**3 minutes (Senior):**
> Redis's power is its native data structures. Strings are the building block: they
> hold bytes, integers, or serialized JSON; INCR/DECR are atomic counter operations.
> Hashes store objects as field-value pairs (HSET/HGET/HINCRBY); more memory-efficient
> than one key per field. Lists (LPUSH/RPOP) implement queues and stacks; BRPOP is a
> blocking pop for work queues. Sets (SADD/SMEMBERS/SINTERSTORE) implement membership
> tracking and set operations. Sorted Sets (ZADD/ZRANGEBYSCORE/ZREVRANK) implement
> leaderboards, rate limiters by score, and geospatial indexes. HyperLogLog (PFADD/
> PFCOUNT) provides approximate unique visitor counts with fixed 12 KB memory regardless
> of cardinality. Streams (XADD/XREAD) are an append-only log with consumer groups,
> similar to a lightweight Kafka. The key: choose the right data structure so Redis
> does the work server-side; moving data to the application to process is slower and
> loses atomicity.

**Framework:** Data Type -> Native Commands -> Atomic Operations -> Server-Side Processing

**Blank Mind Recovery:**

**(1) Restate:** "Redis data structures: String (counter/cache), Hash (object), List
(queue), Set (unique members), Sorted Set (leaderboard/ranking), HyperLogLog (unique
count estimate), Stream (event log)."

**(2) First principles:** "Redis keeps data in RAM and processes commands in a single
thread. All operations are O(1) or O(log N) with atomic execution. The data structures
expose domain-specific operations (INCR, ZINCRBY, LRANGE) that execute server-side
without round-trips."

**(3) Bridge:** "Redis data structures are like specialized containers in a workshop.
A String is a number counter. A List is a queue. A Sorted Set is a scoreboard that
sorts automatically. You do not read the scoreboard, re-sort it in your head, and put
it back; you ask the scoreboard to rank, and it answers."

---

### 📘 Concept Explanation

**Redis Data Structures:**

```text
REDIS DATA STRUCTURES AT A GLANCE:

  STRING       SET/GET/INCR/DECR/APPEND
  (bytes/int)  Counters, cached HTML, session data
               INCR: atomic; no race conditions
               SETEX key 3600 value  -- TTL in one op

  HASH         HSET/HGET/HMGET/HINCRBY/HGETALL
  (object)     User profile, product attributes
               More memory-efficient than one key/field
               HINCRBY user:123 login_count 1

  LIST         LPUSH/RPUSH/LPOP/RPOP/BRPOP/LRANGE
  (queue)      Task queues, recent items, feed
               BRPOP: blocking pop (wait for item)
               LRANGE key 0 9  -- recent 10 items

  SET          SADD/SREM/SMEMBERS/SINTERSTORE
  (unique)     Tags, online users, visited pages
               SINTERSTORE: intersection stored in key
               SCARD key  -- count members

  SORTED SET   ZADD/ZRANGEBYSCORE/ZREVRANK/ZINCRBY
  (ranked)     Leaderboards, time-ordered events,
               rate limiters by timestamp
               ZREVRANK leaderboard user:1  -- rank

  HYPERLOGLOG  PFADD/PFCOUNT/PFMERGE
  (approx)     Unique visitors, distinct queries
               Fixed 12 KB memory; ~0.81% error
               PFCOUNT hll:2024-01-15  -- estimate

  STREAM       XADD/XREAD/XREADGROUP/XACK
  (log)        Event sourcing, lightweight Kafka
               Consumer groups; persistent messages
               XADD events * user_id 123 action login
```

> **Code walkthrough:** (1) WHAT IT SHOWS: all seven Redis data structures with their
> primary commands and canonical use cases. (2) KEY MECHANISM: each data structure
> exposes domain operations that execute server-side atomically; INCR is not "GET + add
> + SET"; it is a single atomic O(1) operation in the server; ZINCRBY is not "ZSCORE +
> add + ZADD"; it is atomic and never produces a race condition between read and write.
> (3) WHY IT MATTERS: server-side operations are faster (no round-trip for read then
> write) and atomic (no race conditions); applications that retrieve data to process
> in application code lose both advantages. (4) WHAT BREAKS: using the wrong data
> structure for the problem; storing JSON strings in Redis instead of Hashes means you
> must deserialize the entire JSON to update one field; Hashes allow HINCRBY for atomic
> field updates without reading the whole object. (5) TAKEAWAY: match the Redis data
> structure to the domain model; use Hashes for objects, Sorted Sets for anything ranked,
> Sets for unique membership, and Strings only for simple values and counters.

---

### 💻 Code Example

```python
import redis

r = redis.Redis(host='localhost', port=6379,
                decode_responses=True)

# STRING: atomic counter
# BAD: Read-Modify-Write with race condition
count = int(r.get("page_views") or 0)
count += 1
r.set("page_views", count)
# PROBLEM: two concurrent processes can both read
# 100, both set 101 -> lost increment

# GOOD: atomic INCR
count = r.incr("page_views")
# Atomic, no race condition, returns new value
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the BAD pattern of GET + increment + SET for
> a counter, and the GOOD pattern using INCR. (2) KEY MECHANISM: Redis's single-threaded
> event loop processes one command at a time; INCR is a single command; it cannot be
> interleaved with another INCR; the GET/SET pattern uses two commands with a gap in
> between where another GET can occur, producing a lost update. (3) WHY IT MATTERS:
> page view counters on high-traffic pages receive thousands of increments per second;
> a race condition in the BAD pattern loses increments silently, producing undercounted
> metrics. (4) WHAT BREAKS: if the key does not exist, INCR initializes it to 1 (which
> is correct); GET returns None and `int(None or 0)` is 0, which is also correct for
> the first increment; however, GET + SET breaks under concurrency while INCR does not.
> (5) TAKEAWAY: use INCR/INCRBY/DECR for all numeric counters; never use GET + SET for
> counter updates.

```python
# SORTED SET: real-time leaderboard
r.zadd("game:leaderboard",
       {"user:alice": 1500,
        "user:bob": 2100,
        "user:carol": 1800})

# Increment score atomically
r.zincrby("game:leaderboard", 150, "user:alice")

# Get top 10 (descending order)
top_10 = r.zrevrange(
    "game:leaderboard", 0, 9, withscores=True
)
# Returns: [(b'user:bob', 2100), ...]

# Get rank of a specific user (0-indexed from top)
rank = r.zrevrank("game:leaderboard", "user:bob")
# Returns: 0 (first place)

# Get users within score range
players = r.zrangebyscore(
    "game:leaderboard", 1700, 2000
)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: Redis Sorted Set operations for a real-time
> game leaderboard: batch insert, atomic score increment, top-N query, rank query, and
> range query. (2) KEY MECHANISM: the Sorted Set stores members with float scores in a
> skip list + hash table; ZINCRBY atomically increments a score; ZREVRANGE retrieves
> members in descending score order in O(log N + M) where M is the range size; ZREVRANK
> returns the 0-indexed rank in O(log N). (3) WHY IT MATTERS: implementing a leaderboard
> in a relational database requires ORDER BY + LIMIT queries that scan all rows for
> ranking; the Redis Sorted Set skip list provides O(log N) rank queries and O(log N + M)
> range queries at any scale. (4) WHAT BREAKS: Sorted Sets have O(log N) insertions and
> updates; for very high-frequency score updates (millions per second), the Sorted Set
> becomes a bottleneck; use a pipeline or batched ZINCRBY to reduce round-trip overhead.
> (5) TAKEAWAY: use Sorted Sets for any ranked list that needs O(log N) rank queries;
> leaderboards, time-ordered event sets, priority queues, and any "top N" query are
> natural Sorted Set use cases.

```python
# HASH: user session/profile object
# BAD: JSON string (requires full deserialize to update)
import json
user_data = {"user_id": 123, "name": "Alice",
             "login_count": 42, "premium": True}
r.set("user:123", json.dumps(user_data))
# To increment login_count, must GET -> deserialize
# -> increment -> serialize -> SET (race condition!)

# GOOD: Hash (each field is independent)
r.hset("user:123", mapping={
    "name": "Alice",
    "login_count": 42,
    "premium": "true"
})

# Atomic field increment (no race condition)
r.hincrby("user:123", "login_count", 1)

# Read only needed fields
name, count = r.hmget("user:123",
                       "name", "login_count")
# No deserialization overhead; only read needed fields
```

> **Code walkthrough:** (1) WHAT IT SHOWS: JSON string storage vs Hash storage for user
> profiles, demonstrating that Hashes allow atomic field updates and partial reads without
> deserializing the entire object. (2) KEY MECHANISM: Redis Hash is a dictionary stored
> server-side; HINCRBY updates one field atomically without touching other fields;
> HMGET reads only specified fields in a single round-trip without reading the entire
> Hash. (3) WHY IT MATTERS: for user session data that is read and written frequently
> (login_count, last_seen, premium status), Hash provides atomic per-field operations
> that the JSON String pattern cannot; updating login_count from 42 to 43 does not
> require reading name or premium. (4) WHAT BREAKS: Hashes store all values as strings
> in Redis (HINCRBY works because Redis internally parses the integer); storing binary
> data or complex nested objects in Hash fields requires serialization anyway; for deeply
> nested objects, JSON + String may be simpler than a flat Hash. (5) TAKEAWAY: use Hash
> for objects with multiple fields that are independently updated; use String + JSON for
> objects that are always read and written as a unit.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Redis is not just a key-value store; it has native data structures with specialized
> commands. Use Strings for counters (INCR), Hashes for objects (HSET/HGET), Lists for
> queues (LPUSH/RPOP), Sets for unique membership (SADD/SISMEMBER), and Sorted Sets
> for leaderboards (ZADD/ZREVRANK). The key principle: let Redis do the work server-side
> using the right data structure instead of getting a value, processing it in application
> code, and putting it back.

---

**Senior / Staff (5+ years):**
> Redis data structure selection determines throughput, memory efficiency, and
> correctness. Choosing String + JSON for an object that needs per-field atomic updates
> creates unnecessary round-trips and race conditions. Choosing List for a time-ordered
> set where duplicates must be excluded (use Set instead) produces incorrect behavior.
> For high-throughput operations, use pipeline and MULTI/EXEC (WATCH-based optimistic
> locking) to batch commands and reduce round-trips. For complex atomic operations, Lua
> scripts (EVAL) execute atomically in the single-threaded event loop. The production
> concern: Redis is in-memory; memory monitoring and eviction policy (allkeys-lru vs
> volatile-lru) must match the use case.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Redis is just a cache."**

Redis started as a cache but has evolved into a full data structure server. Redis Streams
are comparable to a lightweight Kafka for event streaming with consumer groups. Redis
Pub/Sub provides publish-subscribe messaging. Redis Modules (RedisBloom, RedisGraph,
RedisTimeSeries) extend it further. Redis Cluster provides horizontal scale for data
that exceeds single-node memory. Many production systems use Redis as a primary store
for specific data types (sessions, leaderboards, rate limiters) not as a cache in front
of another database.

**Misconception 2: "Redis operations are not atomic."**

All individual Redis commands are atomic - they execute in the single-threaded event
loop without interruption. Compound operations can be made atomic using MULTI/EXEC
(transactions) or Lua scripts (EVAL). WATCH provides optimistic locking: if the watched
key changes between WATCH and EXEC, the transaction is aborted and can be retried.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Using wrong data structure causing memory inefficiency.**

Symptom: Redis memory usage grows unexpectedly; each user occupies multiple kilobytes.
Root cause: storing one Redis key per user profile field (`user:123:name`,
`user:123:email`) instead of one Hash per user; key overhead per entry is 64-80 bytes;
for 1 million users with 10 fields each, this is 640-800 MB of key overhead alone.
Fix: use Hash to store all user fields under one key; Hash entries have minimal overhead
per field once the Hash is created.

**Failure Mode 2: Blocking LRANGE reading the entire list.**

Symptom: Redis slowlog shows LRANGE commands taking milliseconds on large lists.
Root cause: LRANGE with a large range (LRANGE key 0 -1) scans the entire list; for
a list with millions of entries, this is O(N).
Fix: use a bounded list (LTRIM key 0 9999 after each LPUSH) to cap the list size;
never use LRANGE 0 -1 on an unbounded list in production.

---

### ⚖️ Comparison Table

| Data Structure | Time Complexity | Memory Use | Best For |
|---|---|---|---|
| **String** | O(1) set/get | Low | Counters, simple values, cached HTML |
| **Hash** | O(1) field ops | Low per field | Objects with independent fields |
| **List** | O(1) push/pop, O(N) index | Medium | Queues, stacks, recent items |
| **Set** | O(1) add/remove, O(N) smembers | Medium | Unique members, set operations |
| **Sorted Set** | O(log N) add/rank | High | Leaderboards, time-ordered sets |
| **HyperLogLog** | O(1) | Fixed 12 KB | Unique count estimates |
| **Stream** | O(1) append | Medium | Event log, consumer groups |

---

### 🏛️ System Design

*(Omit: L1 foundational keyword; system design context in L4 Redis Production entry.)*

---

### 📊 Diagram

```text
REDIS SORTED SET SKIP LIST STRUCTURE:

  ZADD leaderboard 2100 "bob"
  ZADD leaderboard 1800 "carol"
  ZADD leaderboard 1650 "alice"

  Internal skip list (ascending by score):
  Level 3:  [1650 alice] -------> [2100 bob]
  Level 2:  [1650 alice] -> [1800 carol] -> [2100 bob]
  Level 1:  [1650 alice] -> [1800 carol] -> [2100 bob]

  ZREVRANGE 0 -1: bob(2100), carol(1800), alice(1650)
  ZREVRANK bob: 0  (O(log N) lookup via skip list)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the skip list data structure underlying
> a Redis Sorted Set, showing three levels for three members. (2) HOW TO READ IT: each
> level is a forward-pointer linked list; higher levels skip more elements; a search
> starts at the highest level and drops down when it overshoots, reducing comparisons.
> (3) KEY RELATIONSHIP: the skip list provides O(log N) rank queries and O(log N)
> insertions, making it efficient for the leaderboard pattern; the hash table alongside
> the skip list allows O(1) score lookup by member name (ZSCORE). (4) EDGE CASE: for
> very high cardinality Sorted Sets (millions of members), each member uses approximately
> 60-80 bytes; a 1 million member leaderboard uses ~60-80 MB of RAM; plan memory
> accordingly. (5) INSIGHT: a senior engineer notes that Redis uses a compact encoding
> for small Sorted Sets (< 128 members, scores as shorts) called ziplist (now listpack);
> the skip list is only used above the threshold; this makes small Sorted Sets very
> memory-efficient.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Redis data structures, atomicity |
| Application | 2 | Data structure selection |
| Mechanism | 2 | Internal implementation |
| Trade-off | 1 | Memory vs features |

---

**[MID] Q1 (Definition): What Redis data structures do you know and when would you use each?**

Seven main data structures:

String: bytes with a maximum size of 512 MB. Use for: simple cached values, counters
(INCR/DECR), computed HTML fragments (SETEX with TTL), session tokens.

Hash: field-value pairs within one key. Use for: user profiles, product attributes,
configuration objects. Allows per-field atomic updates (HINCRBY).

List: ordered collection of strings, insertion at either end. Use for: FIFO queues
(LPUSH + BRPOP for worker tasks), recent activity feeds (LPUSH + LTRIM), stacks.

Set: unordered collection of unique strings. Use for: unique visitors, tags, online
users, set operations (union, intersection, difference via SUNIONSTORE, SINTERSTORE).

Sorted Set: members with float scores, sorted by score. Use for: leaderboards, time-
series indexes (score = timestamp), rate limiters (score = timestamp, ZREMRANGEBYSCORE
removes old entries), priority queues.

HyperLogLog: probabilistic structure for unique count estimates. 12 KB fixed memory.
~0.81% error rate. Use for: unique daily active users, distinct queries, cardinality
estimation where an approximation is sufficient.

Streams: append-only log with consumer groups. Use for: event sourcing, audit logs,
lightweight message bus with persistent messages and group acknowledgment.

*What separates good from great:* The memory encoding thresholds. Redis uses compact
encodings for small structures (listpack for small Hashes and Sorted Sets, intset for
integer Sets). Knowing these thresholds (Hash: 128 fields max, 64 bytes per value for
listpack) allows you to design keys that stay in the compact encoding; this can reduce
memory usage by 50-70% compared to the full data structure encoding.

---

**[MID] Q2 (Application): Implement a rate limiter using Redis.**

A sliding window rate limiter using Sorted Sets:

Logic: store each request as a Sorted Set member with the current timestamp as the
score. To check the rate: remove all members older than the window, then count remaining
members. If count < limit, add the current request.

This can be implemented atomically using Lua:

```lua
-- KEYS[1] = rate limit key
-- ARGV[1] = current timestamp (ms)
-- ARGV[2] = window size (ms)
-- ARGV[3] = max requests in window
local key = KEYS[1]
local now = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local limit = tonumber(ARGV[3])
-- Remove entries older than window
redis.call("ZREMRANGEBYSCORE", key, 0,
           now - window)
-- Count current entries in window
local count = redis.call("ZCARD", key)
if count < limit then
    -- Add current request
    redis.call("ZADD", key, now,
               now .. math.random())
    redis.call("EXPIRE", key, window / 1000 + 1)
    return 1  -- allowed
end
return 0  -- rate limited
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a Lua script for an atomic sliding window
> rate limiter using Redis Sorted Sets, where each request is a member scored by its
> timestamp. (2) KEY MECHANISM: the Sorted Set maintains requests by timestamp; ZREMRANGEBYSCORE
> removes requests outside the window in O(log N + M) where M is the removed count;
> ZCARD counts remaining requests in O(1); the Lua script executes atomically, preventing
> race conditions between the check and add steps. (3) WHY IT MATTERS: Lua scripts execute
> in the Redis single-threaded event loop atomically; no two scripts can interleave; this
> is the correct way to implement read-modify-write operations in Redis when MULTI/EXEC
> would be too complex. (4) WHAT BREAKS: the Sorted Set stores one entry per request;
> for very high-volume APIs (millions of requests per second), the Sorted Set grows large;
> use EXPIRE on the key and ZREMRANGEBYSCORE to keep it bounded; alternatively, use a
> simpler fixed-window counter (INCR + EXPIRE) for lower precision requirements. (5)
> TAKEAWAY: use Lua scripts for atomic multi-step Redis operations; Lua eliminates the
> WATCH-MULTI-EXEC complexity and executes server-side without round-trips.

*What separates good from great:* The fixed window vs sliding window trade-off. A fixed
window rate limiter (INCR + EXPIRE) allows up to 2x the limit in the boundary period
(burst at end of window + burst at start of next window). A sliding window (Sorted Set)
prevents this burst but uses more memory. For most API rate limiting, the fixed window
is sufficient and uses O(1) memory per key; the sliding window is appropriate when
the burst behavior of fixed windows causes user experience issues.

---

**[SENIOR] Q3 (Mechanism): How does Redis's single-threaded model provide atomicity?**

Redis processes all commands in a single-threaded event loop. There is one thread that:
reads the command from the socket, executes it, and writes the response. No two commands
execute simultaneously; there is no concurrent access to the data structures.

This means:
- All individual commands are inherently atomic; no interleaving is possible.
- INCR is a single command; it cannot be interleaved with another INCR.
- MULTI/EXEC transactions execute without interleaving (no other commands between EXEC
  and completion).
- Lua scripts execute atomically; the entire script completes before any other command.

Why not use locks: Redis does not need locks because there is only one thread executing
commands. A traditional mutex-based approach would add overhead; the single-threaded
model avoids this overhead while providing the same safety guarantee.

Performance of the single-threaded model: Redis handles 100,000-200,000+ operations
per second on a single core. The bottleneck is typically network I/O, not the single-
threaded execution model. Redis 6.0+ introduced I/O threads for network processing
while keeping command execution single-threaded.

*What separates good from great:* The distinction between command atomicity and
operation atomicity. Single commands are atomic; but an application-level operation
that requires multiple commands is not atomic unless wrapped in MULTI/EXEC or Lua.
A "get balance, check, decrement" operation uses three commands; another client can
execute commands between them. This is why Redis operations that require
read-modify-write must use MULTI/EXEC (with WATCH) or Lua scripts.

---

**[SENIOR] Q4 (Application): When would you use HyperLogLog instead of a Set?**

HyperLogLog provides an approximate count of unique elements using fixed memory (12 KB),
regardless of how many unique elements are added. A Set provides an exact count but uses
memory proportional to the number of unique elements.

Use HyperLogLog when:
- The exact count is not required; an approximation (±0.81% error) is acceptable.
- The cardinality could be very large (millions or billions of unique values).
- Memory is a constraint.

Example: daily unique visitors. A website with 10 million unique visitors per day would
require ~100 MB of memory for a Set (10 characters per visitor ID on average). The same
data in HyperLogLog uses 12 KB with ±0.81% error. The error is: 10,000,000 ± 81,000.
For analytics purposes (reporting "approximately 10 million unique visitors"), this is
acceptable.

Use Set when:
- Exact count is required.
- Membership queries are needed (SISMEMBER: "has user X visited today?").
- The cardinality is small enough that Set memory is not a concern.

HyperLogLog cannot answer "has user X been added?" - it only counts; use it for
cardinality estimation, not membership testing.

*What separates good from great:* PFMERGE for distributed cardinality. HyperLogLogs
from multiple sources can be merged with PFMERGE to get the cardinality of the union.
For example: each web server maintains a HyperLogLog for its unique visitors; PFMERGE
combines all servers' HyperLogLogs to get the global unique count. This is not possible
with Sets without moving all data to one place; HyperLogLog merging maintains the
12 KB constraint regardless of how many sources are merged.

---

**[SENIOR] Q5 (Trade-off): What are the trade-offs between Redis Pub/Sub and Redis Streams?**

Redis Pub/Sub: fire-and-forget messaging. Messages are delivered to all current
subscribers and immediately discarded. If a subscriber is not connected when a message
is published, it misses the message. No persistence; no consumer groups; no message
acknowledgment.

Use Pub/Sub for: real-time notifications where missed messages are acceptable (chat
notifications, cache invalidation signals, live dashboard updates).

Redis Streams: persistent append-only log with consumer groups. Messages are stored
until explicitly deleted. Consumer groups allow multiple consumers to process messages
with acknowledgment (XACK); if a consumer fails, the message is redelivered. XREAD
with a last-seen ID allows a consumer to replay messages from any point.

Use Streams for: event sourcing, audit logs, task queues with delivery guarantees,
integrations requiring exactly-once or at-least-once processing.

*What separates good from great:* The comparison with Kafka. Redis Streams and Kafka
serve similar use cases (persistent message log, consumer groups) but with different
trade-offs: Redis Streams are bounded by available memory; Kafka is bounded by disk.
Redis Streams are appropriate for short-lived events (processed within minutes to hours)
or low-volume events (millions per day, not billions); Kafka handles terabytes of
persistent events at high throughput. Redis Streams have lower operational overhead
for small-scale needs; Kafka is the correct choice for large-scale, high-durability
event streaming.

---

**[SENIOR] Q6 (Mechanism): How does Redis handle persistence and what are the trade-offs?**

Redis has two persistence mechanisms: RDB (snapshots) and AOF (append-only file).

RDB (Redis Database file): periodic point-in-time snapshots. Redis forks the process,
and the child writes the snapshot to disk. The main process continues serving requests.
- Pros: compact files; faster restart (load one snapshot file); low I/O overhead during
  normal operation.
- Cons: data loss between snapshots (if redis crashes 10 minutes after a 5-minute
  snapshot, lose 10 minutes of data); fork() on large datasets causes brief latency spike
  (copy-on-write triggers page faults).

AOF (Append-Only File): logs every write command. On restart, Redis replays the log.
Three sync policies:
- `always`: sync after every write (safest; highest disk I/O).
- `everysec`: sync once per second (default; lose at most 1 second of data).
- `no`: let OS decide (fastest; potentially lose more data).

- Pros: much lower data loss than RDB (1 second with `everysec`); human-readable log.
- Cons: larger file size than RDB; slower restart (replay entire log); log compaction
  (BGREWRITEAOF) required periodically.

Redis 7+ RDB+AOF hybrid: AOF stores the RDB snapshot + AOF delta since the snapshot.
Best of both: fast restart (load snapshot) + low data loss (AOF for recent changes).

*What separates good from great:* The `appendfsync everysec` performance implication.
With `appendfsync always`, Redis performs one `fdatasync()` call per write; on a spinning
disk, this limits writes to ~200-400 per second (disk IOPS bound). With `everysec`, Redis
performs one `fdatasync()` per second regardless of write count; this allows 100K+
writes per second while accepting at most 1 second of data loss. For most production
use cases, `everysec` is the correct trade-off; `always` is only appropriate for Redis
acting as a primary database for critical data.

---

**[SENIOR] Q7 (Application): How do you implement a distributed lock in Redis?**

The Redlock algorithm (Antirez) provides a distributed lock with reasonable safety
guarantees. However, it has important caveats.

Simple Redis lock (single instance):

```python
import uuid, time

def acquire_lock(r, lock_name: str,
                 ttl_seconds: int = 10) -> str | None:
    lock_id = str(uuid.uuid4())
    # NX: set only if not exists
    # EX: expiry in seconds (prevents deadlock)
    acquired = r.set(
        f"lock:{lock_name}", lock_id,
        nx=True, ex=ttl_seconds
    )
    return lock_id if acquired else None

def release_lock(r, lock_name: str,
                 lock_id: str) -> bool:
    # Lua: compare-and-delete atomically
    # Prevents releasing another process's lock
    script = """
    if redis.call("get", KEYS[1]) == ARGV[1] then
        return redis.call("del", KEYS[1])
    else
        return 0
    end
    """
    result = r.eval(script, 1,
                    f"lock:{lock_name}", lock_id)
    return bool(result)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a distributed Redis lock using SET NX EX
> for atomic acquire and a Lua script for safe release. (2) KEY MECHANISM: `SET NX EX`
> is atomic: if the key does not exist, it sets the value and expiry in one command;
> if it exists, it returns nil; the TTL ensures the lock is released even if the holder
> crashes; the Lua release script compares the lock value before deleting to prevent
> releasing another process's lock (if the TTL expired and another process acquired). (3)
> WHY IT MATTERS: a TTL-less lock causes deadlock if the holder crashes; a lock release
> without comparison causes incorrect release if the TTL expired and the lock was
> re-acquired by another process. (4) WHAT BREAKS: the single-node lock is not safe
> against Redis node failure; if the Redis master fails before the lock key is replicated
> to the slave, two processes can hold the lock simultaneously (promoted slave has no
> lock key, another process acquires it). (5) TAKEAWAY: use the single-instance lock
> for non-critical mutual exclusion; for safety-critical distributed locking (financial
> operations, inventory reservation), use Redlock (multiple Redis instances) or a CP
> system like Zookeeper.

*What separates good from great:* The Redlock controversy. Martin Kleppmann (Designing
Data-Intensive Applications author) and Redis creator Antirez had a public debate about
Redlock's safety guarantees. Kleppmann's critique: in the presence of clock drift and
process pauses (GC stop-the-world), Redlock does not guarantee mutual exclusion.
Antirez's counter: in practical deployments, these conditions are rare. The conclusion:
for truly safety-critical locking (where two processes holding the lock simultaneously
is catastrophic), use fencing tokens (a monotonically increasing token from a consensus
system like Zookeeper or etcd); for locks where brief double-acquisition is tolerable,
Redlock is sufficient.

---

---

# Redis Caching Patterns

---

### 🎯 Model Answer

**30 seconds:**
> Redis caching follows four main patterns: Cache-Aside (application checks cache, on
> miss fetches from DB and populates cache), Read-Through (cache fetches from DB on
> miss transparently), Write-Through (writes go to both cache and DB), and Write-Behind
> (writes go to cache, async flush to DB). The most common pattern is Cache-Aside.
> Key concerns: cache invalidation (when to evict), TTL strategy (how long to cache),
> and cache stampede prevention (what happens when many requests miss simultaneously).

**3 minutes (Senior):**
> Cache-Aside is the standard pattern: the application queries the cache first; on a
> miss, queries the DB and populates the cache with a TTL. This decouples the cache
> from the database and works with any database. The main risks: stale data (if DB
> changes but cache is not invalidated), cache stampede (multiple concurrent misses
> for the same key all hit the DB), and thundering herd (cache warmup after restart).
> Write-Through provides stronger consistency (cache and DB always in sync) but adds
> write latency (both stores must complete). Write-Behind increases write throughput
> but risks data loss (cache eviction or crash before DB flush). TTL strategy: use
> jitter (TTL ± random offset) to prevent synchronized expiry. Cache stampede prevention:
> use probabilistic early expiration or mutex locks to prevent concurrent re-computation.

**Framework:** Cache Hit -> Fast Path. Cache Miss -> DB Query -> Cache Population -> TTL

**Blank Mind Recovery:**

**(1) Restate:** "Cache-Aside: check cache, miss = query DB + populate cache. Write-
Through: write DB and cache together. Write-Behind: write cache first, DB async. TTL
strategy prevents stale data; jitter prevents synchronized expiry."

**(2) First principles:** "A cache exploits temporal locality: recently accessed data
is likely to be accessed again. It reduces database load by serving repeated reads
from memory. The tradeoff: cached data can become stale; the system must decide how
stale is acceptable."

**(3) Bridge:** "Redis caching is like a waiter taking orders. Cache-Aside: waiter
checks their notepad (cache), asks the kitchen (DB) if not found, writes it down.
Write-Through: waiter writes to notepad AND kitchen simultaneously. Write-Behind:
waiter writes to notepad immediately, updates kitchen later (faster service, risk
if notepad is lost)."

---

### 📘 Concept Explanation

**Four Caching Patterns:**

```text
CACHING PATTERNS:

  CACHE-ASIDE (most common):
    Read:  app -> cache -> hit: return
                        -> miss: DB -> cache -> return
    Write: app -> DB (cache invalidated or expires via TTL)
    Pros:  simple; DB is source of truth
    Cons:  cache miss penalty (2 round-trips);
           stale data until TTL expires or invalidated

  READ-THROUGH:
    Read:  app -> cache (miss) -> cache fetches DB
           app only ever talks to cache
    Write: same as cache-aside
    Pros:  application is simpler; cache handles misses
    Cons:  first request always slow; cache must
           support DB query logic

  WRITE-THROUGH:
    Write: app -> cache -> cache writes DB -> return
    Read:  app -> cache (always hit for written data)
    Pros:  cache always current; no stale data for writes
    Cons:  write latency (both stores must complete);
           cache stores data that may never be read

  WRITE-BEHIND (write-back):
    Write: app -> cache -> return (fast)
           cache flushes to DB asynchronously
    Read:  app -> cache (always hit for cached data)
    Pros:  lowest write latency; DB absorbs write bursts
    Cons:  risk of data loss if cache crashes before flush;
           complex recovery; inconsistency window
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the four main caching patterns with their
> read/write flows, advantages, and disadvantages. (2) KEY MECHANISM: each pattern
> represents a different trade-off between consistency, latency, and complexity;
> Cache-Aside is application-managed (the application logic decides when to populate
> and invalidate the cache); Read-Through and Write-Through are cache-managed (the cache
> layer handles DB interactions transparently). (3) WHY IT MATTERS: choosing the wrong
> pattern causes either data staleness (Cache-Aside with no invalidation), write latency
> (Write-Through on a hot write path), or data loss risk (Write-Behind without durable
> cache). (4) WHAT BREAKS: Write-Behind with a volatile Redis configuration (no
> persistence); if Redis crashes before flushing to DB, written data is lost; Write-Behind
> requires Redis persistence (AOF) to be meaningful. (5) TAKEAWAY: start with Cache-Aside
> for read-heavy data; the DB is always the source of truth; move to Write-Through for
> data that must always be current in the cache; only use Write-Behind for extreme write
> throughput requirements where data loss risk is acceptable.

---

### 💻 Code Example

```python
import redis
import json
import time
import random

r = redis.Redis(decode_responses=True)

# BAD: Cache-Aside without TTL jitter
# Synchronized expiry causes stampede
def get_user_bad(user_id: str):
    cached = r.get(f"user:{user_id}")
    if cached:
        return json.loads(cached)

    user = db.get_user(user_id)
    # All users set with same TTL: expire at same time
    r.setex(f"user:{user_id}", 3600,
            json.dumps(user))
    return user
    # If 10,000 users all cached at time T,
    # all expire at T+3600: stampede at T+3600
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a Cache-Aside implementation without TTL
> jitter that creates a synchronized expiry problem. (2) KEY MECHANISM: when cache
> entries for popular data are all created at approximately the same time (server
> restart, cache flush), they all expire at approximately the same time; at expiry, all
> concurrent requests for those keys miss the cache simultaneously and all hit the
> database. (3) WHY IT MATTERS: a cache stampede can overwhelm the database; if 10,000
> product pages are cached and all expire at the same second, the database receives
> 10,000 concurrent queries; this can cause cascading failures. (4) WHAT BREAKS: any
> batch operation that populates many cache keys with identical TTLs (bulk cache warmup,
> regular cache rebuild) creates this problem. (5) TAKEAWAY: always add jitter to TTLs
> for keys that might expire in a synchronized wave.

```python
# GOOD: Cache-Aside with TTL jitter and stampede prevention
def get_user_good(user_id: str):
    cached = r.get(f"user:{user_id}")
    if cached:
        return json.loads(cached)

    # Mutex: prevent stampede for same key
    lock_key = f"lock:user:{user_id}"
    lock_id = str(time.time())
    acquired = r.set(lock_key, lock_id,
                     nx=True, ex=5)

    if not acquired:
        # Another request is fetching; wait and retry
        time.sleep(0.05)
        cached = r.get(f"user:{user_id}")
        return json.loads(cached) if cached else None

    try:
        user = db.get_user(user_id)
        # Jitter: TTL = 3600 ± random 0-600 seconds
        ttl = 3600 + random.randint(0, 600)
        r.setex(f"user:{user_id}", ttl,
                json.dumps(user))
        return user
    finally:
        # Release lock (only if still ours)
        r.delete(lock_key)

def warm_cache_with_jitter(user_ids: list):
    """Populate cache with spread expiry."""
    pipe = r.pipeline()
    for uid in user_ids:
        user = db.get_user(uid)
        # Spread TTLs over a 30-min window
        ttl = 3600 + random.randint(0, 1800)
        pipe.setex(f"user:{uid}", ttl,
                   json.dumps(user))
    pipe.execute()
```

> **Code walkthrough:** (1) WHAT IT SHOWS: Cache-Aside with a mutex lock to prevent
> stampede for the same key, TTL jitter to prevent synchronized expiry, and pipelined
> cache warmup with spread TTLs. (2) KEY MECHANISM: the mutex (SET NX EX) ensures only
> one request fetches from the DB when a key misses; other concurrent requests wait and
> retry from the cache; jitter spreads expiry over a time window, preventing synchronized
> waves; pipelining the warmup reduces round-trips from N to 1. (3) WHY IT MATTERS:
> the mutex pattern is the practical production solution for cache stampede; it limits
> database fan-out from N concurrent misses to 1 query per key. (4) WHAT BREAKS: the
> retry-and-return-None path (if lock not acquired and cache is still empty) can cause
> application errors; in production, the retry should loop with exponential backoff
> until the cache is populated or a timeout is reached. (5) TAKEAWAY: implement jitter
> always on cache TTLs; implement mutex or probabilistic early expiration for hot keys
> that are expensive to recompute.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Cache-Aside is the most common Redis caching pattern: check the cache first; on a
> miss, query the database, store in the cache with a TTL, and return the result. Use
> TTL to control staleness. Common problems: cache stampede (many requests miss at the
> same time), stale data (cache not updated when DB changes). Prevent stampede with TTL
> jitter (add a random offset to TTL so entries do not all expire together).

---

**Senior / Staff (5+ years):**
> Caching is a consistency-latency trade-off. Cache-Aside is correct for data where
> stale reads are acceptable (product descriptions, user profiles). Write-Through is
> correct for data that must be current (inventory counts, rate limits). The operational
> risks: cache stampede (use mutex or probabilistic early expiration), cache hot-key
> (one key getting millions of requests per second, overwhelming single Redis node - use
> local in-process cache in front of Redis for extreme hot keys), and cache poisoning
> (invalid data written to cache - use checksums or schema validation before caching).

---

### ⚠️ Common Misconceptions

**Misconception 1: "Caching always improves performance."**

Caching improves performance for repeated reads of the same data. For unique queries
(every request is for a different key), cache hit rate is zero and the cache adds latency
(cache check + miss + DB query vs direct DB query). Profile the hit rate before adding
a cache; a hit rate below 70-80% rarely provides meaningful benefit.

**Misconception 2: "Cache invalidation is easy - just set a TTL."**

TTL-based invalidation allows stale data to be served for up to TTL duration after a
change. For many use cases this is acceptable; for others (inventory, pricing, user
status), serving stale data causes business problems. Explicit invalidation (delete
the cache key when the DB record changes) prevents stale reads but adds coupling
between the write path and cache management.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Cache stampede on popular content.**

Symptom: database CPU spikes at regular intervals (matching the TTL of popular cached
content); application latency increases; error rates rise.
Diagnosis: `redis-cli --hotkeys` to find keys with high access rates; check `OBJECT
ENCODING` and TTL on those keys; correlate DB spike timing with TTL expiry patterns.
Fix: TTL jitter, mutex-based cache locking, or probabilistic early expiration (fetch
the value slightly before TTL expires to avoid a complete miss).

**Failure Mode 2: Cold cache after Redis restart.**

Symptom: after a Redis restart or failover, database load spikes dramatically as all
cache misses hit the database.
Root cause: all cache entries were lost; the warm-up period creates a thundering herd.
Fix: (1) pre-warm the cache before switching traffic; (2) enable Redis persistence
(RDB/AOF) so the cache survives planned restarts; (3) implement circuit breakers that
limit parallel cache-miss DB queries during warm-up.

---

### ⚖️ Comparison Table

| Pattern | Write Latency | Read Latency (miss) | Consistency | Data Loss Risk |
|---|---|---|---|---|
| **Cache-Aside** | Low (DB only) | High (2 round-trips) | Eventual (TTL) | None |
| **Read-Through** | Low (DB only) | High (cache fetches) | Eventual (TTL) | None |
| **Write-Through** | High (both stores) | Low (always cached) | Strong | None |
| **Write-Behind** | Very Low (cache only) | Low (always cached) | Eventual | High (cache crash) |

---

### 🏛️ System Design

*(Omit: L1 foundational keyword; caching system design in L4 Redis Production entry.)*

---

### 📊 Diagram

```text
CACHE-ASIDE FLOW WITH STAMPEDE PREVENTION:

  Multiple requests for user:123 (cache miss)
    |
    +-- Request A -> cache miss
    |     -> acquire lock (success)
    |     -> query DB -> store in cache -> release lock
    |     -> return user data
    |
    +-- Request B -> cache miss
    |     -> acquire lock (FAIL - A holds it)
    |     -> wait 50ms, retry cache read
    |     -> cache HIT (A populated it)
    |     -> return user data
    |
    +-- Request C -> cache HIT (after A populated)
          -> return user data (no DB query)

  Without mutex: A, B, C all query DB simultaneously
  With mutex: only A queries DB; B and C read cache
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the cache stampede prevention pattern
> where a mutex ensures only one request queries the database for the same missing key.
> (2) HOW TO READ IT: three requests arrive simultaneously for the same missing key;
> Request A acquires the lock and queries the DB; B acquires the lock, fails, waits, and
> reads from cache after A populates it; C arrives after A has already populated the cache.
> (3) KEY RELATIONSHIP: the mutex converts N parallel DB queries into 1 DB query + N-1
> cache reads; this is the "herding" prevention; the database sees 1 query instead of N.
> (4) EDGE CASE: if Request A crashes while holding the lock (before populating the cache),
> the lock TTL (5 seconds) automatically expires; the next request acquires the lock and
> retries; this is why the lock must have a TTL. (5) INSIGHT: a senior engineer notes that
> the mutex pattern works for moderate concurrency; for extremely hot keys (millions of
> requests per second for the same key), the mutex becomes a bottleneck; use a local in-
> process cache (e.g., Caffeine in Java, functools.lru_cache in Python) in front of Redis
> to absorb the hot-key traffic before it reaches Redis.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Caching patterns, trade-offs |
| Mechanism | 2 | TTL, stampede prevention |
| Application | 2 | Pattern selection, cache invalidation |
| Scenario | 1 | Cold cache, hot key |

---

**[MID] Q1 (Definition): What is Cache-Aside and what are its trade-offs?**

Cache-Aside (also called Lazy Loading) is the most commonly used caching pattern:

Read path: the application checks the cache first. On a cache hit, the cached value
is returned. On a cache miss, the application queries the database, stores the result
in the cache with a TTL, and returns the result.

Write path: the application writes to the database. The cache entry is either
invalidated (deleted) immediately, or allowed to expire via its TTL.

Advantages: simplicity (the cache only contains data that has actually been requested);
the database is always the source of truth; cache failures degrade to DB queries
gracefully.

Disadvantages: cache miss penalty (two round-trips: cache miss + DB query + cache
write); brief staleness after writes (between write and TTL expiry or explicit
invalidation); risk of thundering herd on cache restart.

When appropriate: read-heavy workloads where stale reads are acceptable (product
descriptions, blog posts, user profiles that change infrequently).

*What separates good from great:* The cache invalidation strategy. TTL-based expiry
allows stale data for up to TTL duration after each write. Event-driven invalidation
(delete the cache key immediately after a successful DB write) reduces the staleness
window to near-zero but adds coupling between the write path and cache management.
For data that changes frequently (user settings, inventory), event-driven invalidation
is worth the added complexity; for data that changes rarely (product descriptions),
TTL is sufficient.

---

**[MID] Q2 (Application): How do you handle cache invalidation for a user profile that is updated by multiple services?**

Cache invalidation across multiple services is the distributed cache coherence problem.
Approaches:

TTL-based expiry: each service writes its changes to the database; the cache TTL
eventually expires and the next read gets the updated value. Simple; eventual
consistency; acceptable when staleness is tolerable (minutes).

Event-driven invalidation: when a service updates the user profile in the database,
it publishes a `user_profile_updated` event (via Kafka or Redis Pub/Sub). All services
subscribed to this event invalidate their cached version.
- Consistent: cache is invalidated immediately after the DB update.
- Challenge: the service writing the DB update and the cache invalidation event are
  two operations; if the service crashes after the DB write but before the event
  publish, the cache is never invalidated. Use the Outbox Pattern (write the event to
  a DB table in the same transaction; a background process publishes events from the
  outbox) for reliability.

Write-Through: one service owns the write path; it always writes to both DB and cache.
All other services only read from the cache.
- Consistent: cache is always in sync with DB.
- Limitation: only one service can write; multi-writer scenarios break Write-Through
  consistency.

*What separates good from great:* The Outbox Pattern for reliable event publishing.
The most common failure in event-driven cache invalidation is the "write DB, crash
before publishing event" scenario. The Outbox Pattern writes the invalidation event
to a database table in the same transaction as the data change; a background process
(change data capture or polling) publishes the events reliably. This ensures that
every DB change that should invalidate the cache eventually publishes the invalidation
event, even if the writing service crashes.

---

**[SENIOR] Q3 (Mechanism): What is a cache stampede and how do you prevent it?**

A cache stampede (also called a thundering herd) occurs when many concurrent requests
all miss the cache for the same key simultaneously. All requests then query the
database concurrently for the same data.

Conditions: a high-traffic key expires; or the cache is cold after a restart; or
a key is explicitly invalidated.

Prevention techniques:

TTL Jitter: add a random offset to TTLs so popular keys do not all expire at the same
time. Instead of `TTL = 3600`, use `TTL = 3600 + random(0, 600)`. Prevents synchronized
expiry for keys populated together (bulk warmup).

Mutex Lock: use a Redis lock (SET NX EX) to ensure only one request fetches from the
database. Other concurrent requests wait and retry from the cache after the lock is
released. Prevents N concurrent DB queries for the same key.

Probabilistic Early Expiration (XFetch algorithm): start refreshing the cache key
slightly before it expires. Each request has a probability of refreshing based on
how close to expiry the key is; the probability increases as expiry approaches. No
lock needed; the refresh is distributed across requests.

Local In-Process Cache: for extreme hot keys (millions of requests per second), add
a local in-memory cache in front of Redis. Each application instance caches the hot
key locally for a few seconds; cache misses in local cache hit Redis; only Redis misses
hit the database.

*What separates good from great:* The "per-key vs global" stampede distinction.
A global stampede (all cache keys miss simultaneously) occurs after a full cache
restart; the solution is pre-warming the cache before switching traffic and using
persistence (RDB/AOF) to survive planned restarts. A per-key stampede (one popular
key expires) is handled by mutex or probabilistic expiration. The two scenarios
require different solutions; most discussions address only per-key stampedes.

---

**[SENIOR] Q4 (Application): How do you design a caching layer for a high-traffic API with strict freshness requirements?**

Strict freshness requirements conflict with caching's fundamental purpose (serve stale
data from cache). The solution is minimizing the staleness window while maximizing
cache hit rate.

Strategy 1 - Write-Through with very short TTL:
- All writes go to both DB and cache simultaneously.
- TTL is very short (10-30 seconds) as a safety net against missed writes.
- Hit rate is high (data is always in cache after write); freshness is near-real-time.
- Cost: write latency increases (two stores must complete); cache stores data that
  may never be read.

Strategy 2 - Cache-Aside with explicit invalidation:
- Cache-Aside for reads; explicit cache key deletion on every write.
- The staleness window is reduced to the propagation delay of the invalidation call.
- Use the Outbox Pattern to ensure invalidation events are never lost.
- Hit rate depends on the read/write ratio; low for write-heavy data.

Strategy 3 - Cache Versioning:
- Instead of invalidating the cached key, write new data to a new version key
  (`user:123:v42` where 42 is a monotonic version counter).
- Store the current version number in a separate key.
- Reads: fetch current version, then fetch `user:{id}:v{version}`.
- Writes: write new data to new version key, then increment version atomically.
- Old versions expire via TTL; no invalidation needed; no cache stampede.
- Clients see stale data only if they read the version before the increment and
  the data key before the new version is written.

*What separates good from great:* The "strict freshness" definition. "Strict freshness"
means different things: never serve data more than 5 seconds stale (requires very short
TTL or Write-Through), never serve data written before my last write (requires session
consistency), or never serve data from before a specific event (requires event-tagged
versioning). Define the exact freshness requirement before choosing a strategy; the
strategies above have different cost profiles for different freshness semantics.

---

**[SENIOR] Q5 (Scenario): Redis is consuming 80% of available memory. How do you diagnose and address this?**

Memory pressure in Redis can be diagnosed and addressed systematically.

Diagnosis:
1. `redis-cli INFO memory` - shows used_memory, maxmemory, mem_fragmentation_ratio.
2. `redis-cli --bigkeys` - scans for the largest keys; identify any unexpectedly large
   keys (unbounded lists, very large Hashes).
3. `redis-cli --hotkeys` - identifies the most frequently accessed keys; determines
   if specific keys should be evicted or moved to a different storage tier.
4. `redis-cli MEMORY USAGE key_name` - reports memory used by a specific key.
5. Check the eviction policy: `CONFIG GET maxmemory-policy`.

Common causes and fixes:
- Unbounded data structures: keys with TTL=0 (no expiry) that grow indefinitely;
  fix: add TTL or LTRIM/EXPIRE on write.
- TTL not set: cached objects without TTL never expire; fix: audit all cache writes
  to confirm TTL is always set.
- Fragmentation: mem_fragmentation_ratio > 1.5 indicates memory fragmentation; fix:
  `MEMORY PURGE` (active defrag) or restart Redis.
- Eviction policy misconfiguration: if maxmemory-policy is `noeviction`, Redis returns
  OOM errors when memory is full; change to `allkeys-lru` for cache use cases.

*What separates good from great:* The memory capacity planning model. Redis memory
usage = (number of keys) * (key size + value size + key overhead ~64 bytes + data
structure overhead). For example: 10 million session keys of 500 bytes each = 5 GB
for values + 640 MB key overhead = ~5.6 GB minimum. Always add 30-50% headroom for
fragmentation, replication, and peak usage. Monitor `used_memory / maxmemory` and
alert at 70% to allow time for capacity response before hitting 80%.

---

**[SENIOR] Q6 (Mechanism): What is Redis eviction and how do you choose the right policy?**

Redis eviction is the process of removing keys when the memory usage reaches `maxmemory`.
The eviction policy determines which keys are removed.

Available policies:
- `noeviction`: return OOM error on write when memory is full. Use only when Redis
  holds data that must not be lost (primary store, not cache).
- `allkeys-lru`: evict least recently used keys from all keys. Standard cache policy:
  the hottest data stays in cache.
- `volatile-lru`: evict LRU keys only from keys that have a TTL set. Useful when
  mixing persistent data (no TTL) with cache data (with TTL).
- `allkeys-lfu`: evict least frequently used keys. Better than LRU for skewed access
  patterns where some keys are hot for a long period.
- `volatile-ttl`: evict keys with the shortest remaining TTL first. Useful when you
  want to evict data closest to expiry.
- `allkeys-random`: evict random keys. Only for data where all keys are equally valuable
  (rare in practice).

Choosing the right policy:
- Pure cache (all data is replaceable): `allkeys-lru` (simple, effective).
- Mixed persistent + cache: `volatile-lru` (protect no-TTL keys, evict TTL-bearing
  cache keys).
- Heavily skewed access (a few very hot keys): `allkeys-lfu` (protects hot keys from
  eviction; LRU evicts a key that was hot 1 hour ago but cold now).

*What separates good from great:* The LFU vs LRU distinction for cache workloads.
LRU evicts the least recently used key; a key that was accessed 1 million times 5
minutes ago but not in the last minute is evicted before a key accessed once in the
last second. LFU tracks access frequency; the key accessed 1 million times is protected.
For workloads with long-lived popular content (product pages, top articles), LFU
provides better hit rates than LRU because it protects the most frequently accessed
keys regardless of recency.

---

**[SENIOR] Q7 (Trade-off): When should you NOT use Redis as a cache?**

Redis is not the right caching layer in several scenarios:

Data exceeds available memory: Redis is in-memory; a cache that requires more data
than available RAM requires either a larger instance (expensive) or an on-disk cache
(Memcached with storage backends, Varnish for HTTP). For caches in the hundreds of
gigabytes, a disk-backed cache or CDN is more cost-effective.

Cache hit rate is too low: if every request is for a different key (user-specific
queries with high uniqueness), the hit rate is near zero; the cache adds latency with
no benefit; better to optimize the database query directly.

Compliance requires no intermediate storage: some compliance regimes (PCI-DSS for
raw card data) prohibit storing data in additional systems; adding a cache layer may
expand the compliance scope.

The data changes faster than it is read: if a key is written once and read once before
expiring, the cache adds write overhead with no read benefit; measure the read/write
ratio for each data type before caching.

*What separates good from great:* The cost-per-query analysis. Redis is not free;
RAM is expensive, and Redis clusters have operational overhead. Evaluate: (DB query
cost) * (cache miss rate reduction) vs (Redis operational cost). For a database query
costing $0.001 (compute time, connection overhead) reduced by 90% with Redis providing
90% hit rate: savings per 1M requests = $900. Compare to Redis cluster cost. If the
math does not work, the cache is not worth it.

---

---

# Key-Value Store Design Patterns

---

### 🎯 Model Answer

**30 seconds:**
> Key-value stores require careful key design because the key IS the query. Key patterns:
> use composite keys (namespace:entity_id:attribute) to group related data, enable range
> scans, and avoid collisions. Common patterns: Hash-field for object decomposition,
> sorted set for ranked/time-ordered data, key expiry for TTL-based data lifecycle, and
> key tagging for cache invalidation groups. The fundamental rule: design the key for
> the access pattern; you cannot query by value in a pure key-value store.

**3 minutes (Senior):**
> Key-value store design is schema design where the schema is in the key structure.
> The key determines: what data is stored together, how data is retrieved, what range
> scans are possible, and how long data lives (TTL). Key design patterns: namespace
> prefixes (`user:`, `session:`, `counter:`) separate data types and enable `KEYS user:*`
> scans (careful: KEYS blocks; use SCAN instead). Composite keys (`stats:2024-01:user:123`)
> enable time-range-like queries in systems that support sorted keys. Object decomposition:
> store each field as a separate key (`user:123:name`) or as a Hash (`user:123` with
> fields); the Hash is more efficient. Lookup tables: to find data by a non-primary
> attribute (find user by email), maintain a secondary index as a separate key
> (`email:alice@example.com` -> `user_id:123`). TTL patterns: session keys expire on
> inactivity; cache keys expire after freshness period; reservation keys expire if
> not committed.

**Framework:** Namespace -> Entity -> Attribute -> TTL

**Blank Mind Recovery:**

**(1) Restate:** "Key design is the schema. Use namespace:entity_id for grouping.
Secondary indexes are separate keys mapping non-primary attributes to IDs. TTL is the
data lifecycle mechanism."

**(2) First principles:** "Key-value stores only look up by exact key. Every data
access that is not by the primary key requires a secondary index (another key). The
key designer must enumerate all access patterns and create a key for each."

**(3) Bridge:** "Designing keys in a key-value store is like designing a filing cabinet.
The folder label (key) determines what goes together and how you find it. To find files
by date, you need a date-organized folder. To find by client name, you need a name-
organized folder. The same 'file' might need multiple folders."

---

### 📘 Concept Explanation

**Key Design Principles:**

```text
KEY DESIGN PATTERNS:

  NAMESPACE PREFIX:
    user:123          -- user entity
    session:abc123    -- session entity
    counter:page:home -- named counter
    Purpose: separate data types; avoid collisions

  COMPOSITE KEY:
    stats:2024-01:user:123   -- monthly user stats
    events:2024-01-15:order  -- daily event partition
    Purpose: logical grouping; human-readable;
    some stores (Cassandra) enable range scans

  OBJECT DECOMPOSITION:
    BAD:  user:123 -> JSON blob
    GOOD: user:123 (Hash with fields)
    BEST: user:123:name, user:123:email (separate keys)
    Trade-off: separate keys = more memory overhead;
    Hash = atomic per-field ops; JSON = atomic bulk

  SECONDARY INDEX (lookup by non-primary):
    email:alice@example.com -> user_id:123
    username:alice -> user_id:123
    Purpose: find entity by attribute that is not
    the primary key; must maintain on write

  TTL PATTERNS:
    session:TOKEN  TTL=1800    (30 min inactivity)
    cache:URL      TTL=3600    (1 hour freshness)
    lock:KEY       TTL=10      (prevent deadlock)
    reservation:ID TTL=600    (10 min to commit)
    otp:USER       TTL=300     (5 min OTP validity)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: five key design patterns with the purpose and
> trade-off of each. (2) KEY MECHANISM: the namespace prefix prevents collisions between
> different data types that happen to have the same ID; without namespacing, `user:123`
> and `order:123` could be confused; secondary indexes are separate keys that must be
> kept in sync with the primary key on every write. (3) WHY IT MATTERS: key design
> decisions are very hard to change after data is in production; a poorly designed key
> structure (no namespaces, JSON blobs everywhere) becomes expensive to refactor;
> designing the key structure at the start with all access patterns in mind prevents
> this. (4) WHAT BREAKS: using KEYS pattern for production lookup (`KEYS user:*` returns
> all user keys); KEYS is O(N) and blocks Redis; in production, use SCAN with a match
> pattern for iterative non-blocking iteration. (5) TAKEAWAY: design key structures the
> way you design a database schema: enumerate all access patterns first, then design a
> key for each pattern; never use KEYS in production code.

---

### 💻 Code Example

```python
import redis
import json

r = redis.Redis(decode_responses=True)

# Pattern 1: Secondary index for lookup by email
def create_user(user_id: str, email: str,
                name: str):
    # Primary record
    r.hset(f"user:{user_id}", mapping={
        "name": name,
        "email": email,
        "created_at": "2024-01-15"
    })
    # Secondary index: email -> user_id
    r.set(f"email:{email}", user_id)

def lookup_by_email(email: str):
    user_id = r.get(f"email:{email}")
    if not user_id:
        return None
    return r.hgetall(f"user:{user_id}")

# Clean delete: must remove all index entries
def delete_user(user_id: str):
    # Get email before deleting (to remove index)
    email = r.hget(f"user:{user_id}", "email")
    if email:
        r.delete(f"email:{email}")  # Remove index
    r.delete(f"user:{user_id}")
    # Atomically: use MULTI/EXEC or Lua
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a secondary index pattern where a user can
> be looked up by email address in addition to user_id; the secondary index key maps
> email to user_id; the lookup requires two steps: resolve email to user_id, then
> fetch the user record. (2) KEY MECHANISM: on creation, two Redis operations create
> the primary record (Hash) and the secondary index (String); on deletion, both must
> be removed atomically to prevent orphaned index entries. (3) WHY IT MATTERS: without
> the secondary index, finding a user by email requires scanning all users; in Redis
> this means iterating with SCAN and checking each record, which is O(N); the secondary
> index provides O(1) lookup at the cost of maintaining the index on every write. (4)
> WHAT BREAKS: if the user creation partially fails (primary written, secondary fails),
> the email lookup returns a user_id that has no corresponding primary record; use
> MULTI/EXEC or Lua to make the creation atomic. (5) TAKEAWAY: maintain all secondary
> indexes within a single atomic operation; partial index writes create orphaned entries
> that cause confusing lookup failures.

```python
# Pattern 2: TTL-based session with sliding expiry
def create_session(user_id: str,
                   session_token: str) -> str:
    session_data = {
        "user_id": user_id,
        "created": "2024-01-15T10:00:00"
    }
    # 30 minutes TTL
    r.setex(f"session:{session_token}", 1800,
            json.dumps(session_data))
    return session_token

def get_session(session_token: str):
    key = f"session:{session_token}"
    data = r.get(key)
    if not data:
        return None  # Expired or invalid

    # Sliding expiry: reset TTL on each access
    # (session extends 30min from last activity)
    r.expire(key, 1800)
    return json.loads(data)

# Pattern 3: Rate limiter with fixed window
def check_rate_limit(user_id: str,
                     max_requests: int = 100,
                     window_seconds: int = 60):
    key = f"rl:{user_id}:{window_seconds}"
    # INCR: creates key at 1 if not exists
    count = r.incr(key)
    if count == 1:
        # First request in window: set TTL
        r.expire(key, window_seconds)
    return count <= max_requests
```

> **Code walkthrough:** (1) WHAT IT SHOWS: two patterns: sliding-expiry sessions using
> EXPIRE to reset TTL on each access, and a fixed-window rate limiter using INCR with
> EXPIRE. (2) KEY MECHANISM: the sliding session uses `r.expire(key, 1800)` on every
> session read; the TTL is reset to 30 minutes from now, implementing "session expires
> after 30 minutes of inactivity" semantics; if the user is active, the session never
> expires. The rate limiter uses INCR (atomic counter) and EXPIRE (set TTL on first
> increment) to create a window; the key expires after the window, resetting the counter.
> (3) WHY IT MATTERS: sliding expiry is a common requirement for user sessions; the
> `SETEX + expire on access` pattern implements it correctly without race conditions
> (EXPIRE is atomic). (4) WHAT BREAKS: the rate limiter has a race condition: INCR
> returns 1, then the process crashes before EXPIRE is called; the key persists
> indefinitely with count=1; subsequent requests see count 2, 3, etc., and the rate
> limit never resets; fix: use `SET key 0 NX EX window_seconds` to set the key with
> TTL in one operation, then INCR separately. (5) TAKEAWAY: for TTL-based patterns,
> always set the TTL atomically with the initial value (SETEX, SET EX, SET NX EX) rather
> than in a separate EXPIRE call to avoid the race condition.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Key design is how you organize data in a key-value store. Use namespaced keys like
> `user:123` to separate data types. For lookups by non-primary attributes (find user
> by email), create a secondary index as a separate key (`email:alice@example.com` ->
> `user:123`). Use TTL for data with natural expiry (sessions, caches, OTPs). Never
> use KEYS in production (use SCAN instead - KEYS blocks Redis).

---

**Senior / Staff (5+ years):**
> Key design in a key-value store is the equivalent of schema design in a relational
> database. The difference: every access pattern must be anticipated at design time
> because the key-value store cannot query by value. For each access pattern, there
> must be a key that points to the data needed for that pattern. Key design decisions
> that are hard to change after data is in production: naming conventions, composite
> key structure, Hash vs String for objects, and secondary index maintenance strategy.
> Invest time in key design before writing the first byte.

---

### ⚠️ Common Misconceptions

**Misconception 1: "KEYS pattern is fine for development; just do not use it in production."**

KEYS blocks the Redis event loop for the duration of the scan. In development with 1,000
keys, KEYS is fast. In production with 10 million keys, KEYS can block Redis for seconds,
causing all other clients to time out. Any code that uses KEYS in development will
eventually be deployed to production. Use SCAN from the start; it is non-blocking and
provides the same iteration capability.

**Misconception 2: "Key-value stores do not need schema design."**

No-schema is a myth. The schema is in the key structure, the value format (JSON, msgpack,
binary), and the naming conventions. A poorly designed "schema" (inconsistent key naming,
mixed value formats, no secondary indexes) is just as hard to work with as a poorly
designed SQL schema - and harder to refactor because there is no ALTER TABLE equivalent.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Orphaned secondary index entries.**

Symptom: email lookup returns a user_id that no longer exists; application receives
null after the second lookup; data inconsistency between index and primary record.
Root cause: delete or update of the primary record did not atomically remove/update
the secondary index.
Fix: wrap all index-maintaining operations in MULTI/EXEC or Lua scripts; if already
in production, run a periodic cleanup job that validates all secondary index entries
against their primary records.

**Failure Mode 2: Key proliferation from missing TTLs.**

Symptom: Redis memory grows unboundedly; redis-cli --bigkeys shows many keys without
TTL; eventually OOM errors.
Root cause: keys created without TTL that should have natural expiry (temporary state,
cache entries, session data).
Fix: `redis-cli --scan --pattern "cache:*" | xargs -L 1 redis-cli TTL` to audit TTLs;
add TTL to all cache and session keys; implement a coding standard that requires TTL
for specific key namespaces.

---

### ⚖️ Comparison Table

| Pattern | Access Speed | Memory Use | Consistency Risk | Complexity |
|---|---|---|---|---|
| **Simple Key-Value** | O(1) | Low | Low | Low |
| **Hash for Object** | O(1) per field | Efficient | Low | Low |
| **Secondary Index** | O(1) primary, O(1) index | Medium (2 keys) | Medium (index drift) | Medium |
| **SCAN-based iteration** | O(N) total | Low | None | Medium |
| **Sorted Set Index** | O(log N) | Medium | Low | Medium |

---

### 🏛️ System Design

*(Omit: L1 foundational keyword; system design context in L5 Architecture entry.)*

---

### 📊 Diagram

```text
KEY-VALUE SCHEMA: User with Email Lookup

  PRIMARY KEY:
  +------------------+---------------------+
  | user:123 (Hash)  | name: "Alice"       |
  |                  | email: "a@e.com"    |
  |                  | created: "2024-01"  |
  +------------------+---------------------+

  SECONDARY INDEX:
  +--------------------+----------+
  | email:a@e.com (Str)| "123"    |
  +--------------------+----------+

  LOOKUP BY EMAIL:
  GET email:a@e.com  -> "123"
  HGETALL user:123   -> {name, email, created}
  Total: 2 round-trips (vs O(N) scan)
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: the two-key structure for a user record
> with a secondary index for email lookup: primary Hash and secondary String index. (2)
> HOW TO READ IT: the primary key is a Hash with all user fields; the secondary index is
> a String key (email address) pointing to the user_id; lookup by email requires two
> Redis operations: GET the index, then HGETALL the primary. (3) KEY RELATIONSHIP: the
> secondary index key and primary key must be kept in sync; when the email changes, the
> old index key must be deleted and a new one created; when the user is deleted, the
> index key must also be deleted. (4) EDGE CASE: if two users try to register with the
> same email simultaneously, both could check the index (not present), and both attempt
> to create; use SETNX (SET if Not eXists) on the email index key as the "claim" step;
> the one that succeeds gets the email. (5) INSIGHT: a senior engineer notes that the
> secondary index pattern scales linearly; each additional lookup attribute requires
> one additional index key per user; a user with 3 lookup attributes (email, username,
> phone) requires 4 keys total (1 primary + 3 indexes); this is the cost of flexible
> lookup in a key-value store.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Key design, secondary indexes |
| Application | 2 | Pattern selection, TTL strategy |
| Mechanism | 2 | Atomic operations, SCAN |
| Scenario | 1 | Key proliferation, index drift |

---

**[MID] Q1 (Definition): How do you structure keys in a Redis key-value store?**

Key structure should be: `namespace:entity_type:id:attribute` where each component
adds specificity.

Namespace: separates logical domains; prevents key collisions between services.
Example: `users:`, `orders:`, `cache:`, `session:`, `counter:`.

Entity type: the kind of entity. Example: `user`, `product`, `event`.

ID: the unique identifier. Usually a UUID, database ID, or hash.

Attribute (optional): for storing specific attributes of the entity separately.
Example: `user:123:profile`, `user:123:settings`.

Separator: use `:` as the separator (convention); some use `/` or `_`.

Examples:
- `session:abc123ef` - session token lookup.
- `user:123` - user Hash (all fields).
- `cache:product:456` - cached product data.
- `counter:page:home` - page view counter.
- `lock:resource:789` - distributed lock.
- `rate:user:123:1735689600` - rate limit bucket.

*What separates good from great:* The scan-safe key design. If you ever need to iterate
over all keys of a type (for monitoring, migration, or cleanup), the namespace prefix
enables efficient SCAN with a match pattern (`SCAN 0 MATCH user:* COUNT 100`). Keys
without consistent namespacing require full scans of all keys. Document the namespace
conventions in a project-level ADR (Architecture Decision Record) so all services
follow the same structure.

---

**[MID] Q2 (Application): How do you implement "find user by email" in Redis?**

Redis does not support querying by value. To find a user by email, you need a secondary
index: a separate key that maps the email to the user's ID.

Creation:
```python
def create_user(user_id: str, email: str,
                name: str):
    pipe = r.pipeline()
    # Primary record
    pipe.hset(f"user:{user_id}",
              mapping={"name": name, "email": email})
    # Secondary index
    pipe.set(f"email:{email}", user_id)
    pipe.execute()  # Atomic pipeline
```

> **Code walkthrough:** (1) WHAT IT SHOWS: atomic creation of a user Hash and email
> secondary index using a Redis pipeline. (2) KEY MECHANISM: pipeline batches both
> operations into a single network round-trip; both are sent and executed together;
> note that pipeline is not a transaction (not MULTI/EXEC) - if one operation fails,
> the other may succeed; for strict atomicity, use MULTI/EXEC. (3) WHY IT MATTERS:
> unbatched creation (two separate calls) risks a partial state where the primary is
> created but the index is not, or vice versa; batching reduces this window and improves
> performance. (4) WHAT BREAKS: pipeline is not atomic; if the Redis server restarts
> between the two commands, partial state can occur; for truly atomic index creation,
> use MULTI/EXEC or Lua. (5) TAKEAWAY: use pipeline for performance batching; use
> MULTI/EXEC or Lua for atomicity; they are different tools.

Lookup:
```python
def find_by_email(email: str):
    user_id = r.get(f"email:{email}")
    if not user_id:
        return None
    return r.hgetall(f"user:{user_id}")
```

> **Code walkthrough:** (1) WHAT IT SHOWS: two-step email lookup: resolve email to
> user_id via the secondary index, then fetch the primary record. (2) KEY MECHANISM:
> two network round-trips; first `GET email:{email}` returns the user_id string; second
> `HGETALL user:{id}` returns all user fields. (3) WHY IT MATTERS: this is the correct
> approach for secondary lookups; the alternative (SCAN all user keys and check email
> field) is O(N) and blocks Redis. (4) WHAT BREAKS: race condition between the two
> round-trips; if the user is deleted between the first and second call, the second
> returns nil; handle nil gracefully. (5) TAKEAWAY: two-step lookups via secondary
> indexes are the standard pattern; handle nil at both steps.

*What separates good from great:* The uniqueness enforcement. The secondary index
should enforce email uniqueness: use `SETNX email:{email} user_id` (set if not exists);
if it returns 0, the email is already taken; only proceed to create the user if SETNX
succeeds. This prevents two users from having the same email without a separate
uniqueness check.

---

**[SENIOR] Q3 (Mechanism): Why is SCAN safer than KEYS in production?**

KEYS: `KEYS pattern` iterates all keys in the database and returns matches. It is an
O(N) operation where N is the total number of keys. During execution, the Redis event
loop is blocked; no other commands are processed. On a Redis instance with 10 million
keys, KEYS can block for seconds.

SCAN: `SCAN cursor MATCH pattern COUNT hint` iterates incrementally. Each call processes
a slice of the keyspace and returns a cursor for the next call. When the cursor returns
to 0, the iteration is complete. Each call is O(1) amortized (processes COUNT keys
per call). Other commands execute normally between SCAN calls.

Practical impact:
- KEYS on a Redis with 1 million keys: ~100 ms block (depending on server and key size).
- KEYS on a Redis with 100 million keys: ~10 seconds block; all clients time out.
- SCAN is safe at any scale: each call processes COUNT (default 10) keys; total
  iteration is O(N) spread across many calls.

*What separates good from great:* The SCAN guarantees. SCAN does not guarantee ordering;
it may return duplicates if a key is added during iteration; it may skip keys added
after the scan starts. For migration or cleanup operations where consistency matters,
account for these edge cases: use a Set to track already-processed keys to skip
duplicates; scan multiple times if completeness is required. For monitoring (count
keys of a type), duplicates and skips are acceptable.

---

**[SENIOR] Q4 (Application): How do you handle TTL for a session store?**

Session TTL strategy depends on the required behavior: fixed lifetime (session expires
N minutes after creation regardless of activity) or sliding lifetime (session expires
after N minutes of inactivity).

Fixed lifetime:
```python
r.setex(f"session:{token}", 3600, session_data)
# Session expires 1 hour after creation; no renewal
```

> **Code walkthrough:** (1) WHAT IT SHOWS: fixed-lifetime session where TTL is set at
> creation and never renewed; the session expires 1 hour after creation regardless of
> how recently it was used. (2) KEY MECHANISM: SETEX sets the key and TTL in a single
> atomic operation; the TTL counts down from creation time; accessing the session does
> not reset the TTL. (3) WHY IT MATTERS: fixed lifetime is simpler to reason about for
> security; an attacker who steals a session token can only use it until the fixed expiry,
> not indefinitely as long as they keep using it. (4) WHAT BREAKS: poor user experience
> for long sessions; a user who works for 90 minutes is logged out even if active. (5)
> TAKEAWAY: use fixed lifetime for security-sensitive sessions; use sliding lifetime for
> user-facing applications where session persistence is expected.

Sliding lifetime (expire on inactivity):
```python
def get_session_sliding(token: str):
    key = f"session:{token}"
    data = r.get(key)
    if not data:
        return None
    # Reset TTL: session extends from last activity
    r.expire(key, 1800)
    return json.loads(data)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: sliding-lifetime session where the TTL is
> reset to 30 minutes on every access. (2) KEY MECHANISM: EXPIRE updates the TTL of an
> existing key; it does not modify the value; if the user is active, the session never
> expires; if inactive for 30 minutes, the key expires and the session is invalidated.
> (3) WHY IT MATTERS: this is the expected behavior for most web application sessions:
> "stay logged in until I stop using the app." (4) WHAT BREAKS: the GET and EXPIRE are
> two separate commands; between them, the session could expire; use GETEX (Redis 6.2+)
> which atomically gets the value and resets the TTL in a single command. (5) TAKEAWAY:
> use GETEX for sliding-expiry reads in Redis 6.2+; it eliminates the GET + EXPIRE
> race condition in a single command.

*What separates good from great:* The session invalidation design. Both patterns rely
on TTL for expiry. But some events require immediate invalidation regardless of TTL:
logout, password change, permission change. For these, explicitly delete the session
key (`DEL session:{token}`) on the triggering event. Do not wait for the TTL; a user
who logs out should not have a valid session for the remaining TTL period.

---

**[SENIOR] Q5 (Scenario): A Redis key-value store is being used for feature flags. As feature flags are accessed millions of times per second, what design considerations apply?**

Feature flags read millions of times per second create a "hot key" problem: a single
Redis key is accessed at a rate that exceeds what Redis can handle for that key.

Redis single-thread bottleneck: even with Redis handling 1 million requests per second
total, a single key accessed 1 million times per second means all Redis capacity is
consumed by one key.

Solutions:

Local in-process cache: each application instance caches all feature flags locally
(in memory) with a short TTL (5-10 seconds). Redis is only queried on cache miss or
TTL expiry. Reduces Redis load from O(requests) to O(application instances per TTL).

Client-side caching (Redis 6.0+): Redis supports server-assisted client-side caching;
clients subscribe to invalidation notifications; the cache is invalidated only when
the value changes, not on a TTL. This provides lower staleness than TTL while reducing
Redis load.

Read replica with local caching: route feature flag reads to Redis replicas; scale
read capacity by adding replicas; add local in-process cache in front.

Redis Cluster for sharding: if multiple feature flags are hot (not just one), Cluster
shards keys across nodes; the hot key problem per node is reduced.

*What separates good from great:* The "flag evaluation pushdown" architecture. Instead
of hitting Redis on every request, use a feature flag SDK (LaunchDarkly, Flagsmith)
that fetches all flags on startup and streams updates via WebSocket or Server-Sent
Events. Flag evaluations happen entirely in-process (no network); Redis (or any
datastore) is only involved in flag updates, not flag reads. This is the correct
architecture for million-RPS feature flag evaluation.

---

**[SENIOR] Q6 (Mechanism): How do you prevent data corruption when multiple services write to the same Redis key?**

Multiple services writing to the same key creates a concurrent update problem. Solutions
depend on the required semantics.

Last-Write-Wins (SET): the default. Two services both SET the same key; the last write
wins. Acceptable when the latest value is always correct (TTL refresh, simple override).

Atomic Increment (INCR, HINCRBY): for numeric values, use atomic increment instead of
read-modify-write. Eliminates the race condition for counter updates.

Optimistic Locking (WATCH-MULTI-EXEC):
```python
with r.pipeline() as pipe:
    while True:
        try:
            pipe.watch("user:123")  # Watch for changes
            current = pipe.hgetall("user:123")
            # Process based on current value
            new_value = compute_new_value(current)
            pipe.multi()
            pipe.hset("user:123", "field", new_value)
            pipe.execute()  # Fails if watched key changed
            break
        except redis.WatchError:
            continue  # Retry if key was modified
```

> **Code walkthrough:** (1) WHAT IT SHOWS: optimistic locking using WATCH-MULTI-EXEC
> to detect concurrent modifications and retry. (2) KEY MECHANISM: WATCH marks a key
> for monitoring; if any watched key is modified by another client between WATCH and
> EXEC, EXEC returns nil and the transaction is aborted; the application retries from
> the beginning. (3) WHY IT MATTERS: optimistic locking is appropriate when conflicts
> are rare (low contention); it allows concurrent reads without blocking and only
> detects conflicts at commit time. (4) WHAT BREAKS: high contention causes many retries;
> if the key is modified constantly, the WATCH-MULTI-EXEC loop never succeeds; in this
> case, use a distributed lock or INCR instead. (5) TAKEAWAY: use WATCH-MULTI-EXEC for
> low-contention updates where the value must be read before writing; use INCR/HINCRBY
> for high-contention numeric updates; use distributed locks for complex multi-step
> operations.

*What separates good from great:* The Lua script approach for complex atomic operations.
When an operation requires multiple steps that must be atomic (and MULTI/EXEC is too
cumbersome), a Lua script executes entirely in the Redis single-threaded event loop
without interleaving. Lua provides conditional logic (if-then-else), multi-key
operations, and the ability to return multiple values. Use Lua for: check-then-act
operations, operations across multiple keys, and any sequence of commands that must
be atomic.

---

**[SENIOR] Q7 (Trade-off): When should you use Redis vs a relational database for session storage?**

Redis for session storage:
- Pros: sub-millisecond reads; horizontal scale (Redis Cluster); TTL-native (sessions
  expire automatically without cleanup jobs); simple key lookup (no JOIN).
- Cons: in-memory (must configure persistence for durability); additional infrastructure
  to operate; sessions lost if Redis restarts without persistence.

Relational database (PostgreSQL) for session storage:
- Pros: durable by default; ACID transactions; existing infrastructure (no new component);
  can join session data with user data.
- Cons: slower than Redis for high-frequency reads; session cleanup requires a cron job
  (DELETE WHERE expires < NOW()); does not scale as easily for high-frequency reads.

Decision:
- High-traffic applications (> 10,000 sessions/second): Redis. PostgreSQL will become
  a bottleneck for high-frequency session reads at this scale.
- Low-to-medium traffic, simplicity preferred: PostgreSQL sessions. Avoids Redis
  infrastructure; sessions are durable by default; no separate infrastructure to operate.
- Mixed: PostgreSQL as the source of truth; Redis as the session cache; sessions are
  written to PostgreSQL on login and cached in Redis for fast access; Redis TTL matches
  session TTL; Redis miss falls back to PostgreSQL.

*What separates good from great:* The "sticky sessions" anti-pattern. Before Redis
was widely used, many applications used sticky sessions (all requests from a user
go to the same server, which holds the session in memory). Sticky sessions prevent
horizontal scaling: adding a server does not help users stuck to existing servers.
Redis-based sessions (or database-based) allow stateless application servers: any
server can handle any request because the session is in the shared store. This is
the correct architecture for horizontal scale.
