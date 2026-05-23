---
layout: default
title: "System Design - Case Studies"
parent: "System Design"
grand_parent: "Interview Mastery"
nav_order: 5
permalink: /interview/system-design/case-studies/
topic: System Design
subtopic: Case Studies
keywords:
  - URL Shortener
  - Rate Limiter
  - News Feed and Timeline
  - Chat System
  - Notification System
difficulty_range: medium to hard
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [URL Shortener](#url-shortener)
- [Rate Limiter](#rate-limiter)
- [News Feed and Timeline](#news-feed-and-timeline)
- [Chat System](#chat-system)
- [Notification System](#notification-system)

# URL Shortener

**TL;DR** - Design a URL shortening service (like bit.ly) that converts long URLs to short codes, redirects short URLs to originals, and handles billions of redirects per day. Core challenge: generating unique, short, collision-free codes at scale.
---

### 🔥 The Problem This Solves

Long URLs are hard to share (SMS character limits, print media, verbal communication). A URL shortener maps a 200-character URL to a 7-character code, provides analytics (click counts), and enables link management (expiration, editing destination).
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - Back-of-Envelope Estimation**

```
Requirements:
  100M new URLs/day, 100:1 read:write ratio

Writes: 100M / 86400 = ~1,200 URLs/sec
Reads:  1,200 * 100 = ~120,000 redirects/sec
Peak:   3x = ~360,000 redirects/sec

Storage (10 years):
  100M/day * 365 * 10 = 365B records
  Each: shortUrl(7B) + longUrl(200B) + meta(100B)
       = ~300B per record
  Total: 365B * 300B = ~110 TB

Short code length:
  Base62 (a-z, A-Z, 0-9): 62^7 = 3.5 trillion
  365B URLs over 10 years -> 7 chars is enough
```

**Level 2 - High-Level Design**

```
           +-----------+
Client --> | API       | --> Read: Cache (Redis)
           | Gateway   |         |miss
           +-----------+     Database (read replica)
                |
           Write path:
           ID Generator --> Database (primary)
                        --> Cache (write-through)
```

**API Design:**

```
POST /api/shorten
  Body: { "longUrl": "https://...",
          "customAlias": "my-link",
          "expiresAt": "2025-12-31" }
  Response: { "shortUrl": "https://short.ly/Ab3xK9" }

GET /{shortCode}
  Response: 301 Redirect to original URL
  (301 = permanent, browser caches. Use 302 if
   you need to track every click)
```

**Level 3 - Short Code Generation (The Core Problem)**

**Option A: Hash-based**

```
MD5("https://long-url.com") = "5d41402abc4b..."
Take first 7 chars -> "5d41402"
Collision? Append counter and rehash

Pros: Deterministic (same URL = same code)
Cons: Collisions require retry, hash computation
```

**Option B: Counter-based (preferred)**

```
Global counter: 1, 2, 3, ...
Convert to Base62:
  1 -> "1", 62 -> "10", 3844 -> "100"

Counter sources:
  - Auto-increment DB (simple, bottleneck at scale)
  - Snowflake ID (distributed, 64-bit unique)
  - Range-based: each server gets a range
    Server 1: 1-1,000,000
    Server 2: 1,000,001-2,000,000
    No coordination after range assignment
```

**Option C: Pre-generated keys**

```
Offline key generation service:
  Pre-generates millions of unique 7-char keys
  Stores in key_db (two tables: unused, used)

  Server requests batch of 1000 keys
  Marks batch as "assigned" (atomic)
  Server uses keys from its local pool

  Pros: No collision checking, no coordination
  Cons: Key management complexity, wasted keys
```

**Level 4 - Deep Dive: Scaling and Optimization**

**Cache strategy (handles 360K reads/sec):**

```
Read path:
  1. Check Redis cache (99% hit rate for popular URLs)
  2. Cache miss -> read from DB replica
  3. Write to cache (TTL = 24h)

  Redis cluster: 3 nodes, ~100K ops/sec each
  = 300K ops/sec (handles peak)

  Cache eviction: LRU (least recently used)
  Hot URLs (popular links) stay cached
```

**Analytics:**

```
Every redirect -> log event (async):
  { shortCode, timestamp, ip, userAgent, referrer }
  -> Kafka -> Analytics pipeline
  -> Real-time: count in Redis (INCR)
  -> Batch: Kafka -> S3 -> Spark -> dashboard
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

```
+-------------------------------------------+
| WHAT IT IS  | [TODO: 1-line definition]   |
| PROBLEM     | [TODO: What pain it solves]  |
| KEY INSIGHT | [TODO: Core principle]       |
| USE WHEN    | [TODO: Primary use case]     |
| AVOID WHEN  | [TODO: When not to use]      |
| ANTI-PATTERN| [TODO: Common misuse]        |
| TRADE-OFF   | [TODO: What you give up]     |
| ONE-LINER   | [TODO: Interview summary]    |
| KEY NUMBERS | [TODO: 2-3 critical thresholds]  |
| TRIGGER   | [TODO: 5-7 word mental model]  |
| OPENING   | [TODO: First sentence depth]   |
+-------------------------------------------+
```
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for URL Shortener. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: How do you handle custom aliases and prevent abuse?**

_Why they ask:_ Tests edge case handling and security thinking.

_Strong answer:_

**Custom aliases:**

```
POST /api/shorten
  { "longUrl": "...", "customAlias": "my-sale" }

1. Check if alias is taken:
   SELECT FROM urls WHERE short_code = 'my-sale'
2. If taken -> 409 Conflict
3. If available -> INSERT with custom code
4. Reserve common words (blocklist):
   "admin", "api", "login", "help" -> rejected
```

**Abuse prevention:**

- Rate limiting: 100 URLs/hour per user (authenticated), 10/hour anonymous
- Blocklist: check destination URL against malware/phishing lists (Google Safe Browsing API)
- Link preview: `GET /api/preview/{code}` shows destination before redirect
- Expiration: default 2 years, max 10 years, min 1 hour
- CAPTCHA for anonymous users creating > 5 links
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Rate Limiter

**TL;DR** - A rate limiter controls how many requests a client can make in a time window, protecting services from abuse, DDoS, and resource exhaustion. Core algorithms: Token Bucket (smooth, bursty), Sliding Window (precise), Fixed Window (simple). Typically implemented at the API Gateway with Redis as the counter store.
---

### 🔥 The Problem This Solves

A single misbehaving client sends 100K requests/second, consuming all server threads. Legitimate users get 503 errors. Without rate limiting, one bad actor can take down the entire service. Also needed: API monetization tiers (free=100/day, pro=10K/day).
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - Back-of-Envelope Estimation**

```
System: API serving 10M requests/day
Rate limit: 100 requests/minute per user
Users: 1M registered

Counter storage:
  Per user: userId(8B) + count(4B) + window(8B) = 20B
  1M users: 20MB in Redis (trivial)

QPS to rate limiter:
  10M/day = ~115 req/sec average
  Peak (10x): ~1,150 req/sec
  Each request = 1 Redis operation
  Single Redis handles 100K ops/sec (plenty)
```

**Level 2 - High-Level Design**

```
Client -> API Gateway -> Rate Limiter -> Service
                             |
                         Redis (counters)

Response headers:
  X-RateLimit-Limit: 100
  X-RateLimit-Remaining: 42
  X-RateLimit-Reset: 1640000000

If over limit:
  HTTP 429 Too Many Requests
  Retry-After: 30
```

**Level 3 - Core Algorithms**

**Token Bucket (most popular):**

```
Bucket: capacity=100, refill=10 tokens/sec

Request arrives:
  If tokens > 0: take 1 token, allow request
  If tokens == 0: reject (429)

Tokens refill continuously:
  After 1 sec of no requests: 10 new tokens
  Max tokens = capacity (100)

Allows bursts: 100 rapid requests (drain bucket)
  then steady 10/sec as tokens refill
```

```java
public class TokenBucket {
    private final int capacity;
    private final double refillRate; // tokens/sec
    private double tokens;
    private long lastRefillTime;

    public synchronized boolean allowRequest() {
        refill();
        if (tokens >= 1) {
            tokens -= 1;
            return true;
        }
        return false;
    }

    private void refill() {
        long now = System.nanoTime();
        double elapsed =
            (now - lastRefillTime) / 1e9;
        tokens = Math.min(capacity,
            tokens + elapsed * refillRate);
        lastRefillTime = now;
    }
}
```

**Sliding Window Log (most precise):**

```
Store timestamp of each request in sorted set:

ZADD rate:user42 1640000001 "req1"
ZADD rate:user42 1640000002 "req2"
...

Check count in current window:
ZCOUNT rate:user42 (now-60s) now
If count >= limit -> reject

Remove old entries:
ZREMRANGEBYSCORE rate:user42 0 (now-60s)

Pros: Exact count, no boundary issues
Cons: Memory (stores every timestamp)
```

**Fixed Window Counter (simplest):**

```
Key: rate:{userId}:{minute}
INCR rate:user42:2024-01-15T10:05
IF count > limit -> reject
EXPIRE key 60

Problem: Boundary burst
  10:04:55 -> 100 requests (allowed)
  10:05:05 -> 100 requests (allowed, new window)
  200 requests in 10 seconds!

Fix: Sliding Window Counter (weighted average
  of current and previous window)
```

**Level 4 - Distributed Rate Limiting**

**Multi-node synchronization:**

```
Problem: 4 API Gateway nodes, each with local counter.
  User sends 25 requests to each node = 100 total
  Each node sees 25 (under limit of 100)
  But total is 100 (at or over limit)

Solution A: Centralized (Redis)
  All nodes check/increment same Redis key
  Accurate but adds 1 Redis RTT per request (~1ms)

Solution B: Local + Sync
  Each node has local counter
  Periodically sync to centralized store
  Less accurate (window of inaccuracy)
  No per-request Redis call

Solution C: Sticky sessions
  Route same user to same node (IP hash)
  Local counter is accurate per user
  But: uneven load if one user is heavy
```

**Rate limiting by multiple dimensions:**

```
Layer 1: Per user (100 req/min)
Layer 2: Per IP (1000 req/min - catches bots)
Layer 3: Per endpoint (POST /orders: 10/min)
Layer 4: Global (100K req/sec total capacity)

All must pass for request to proceed.
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

```
+-------------------------------------------+
| WHAT IT IS  | [TODO: 1-line definition]   |
| PROBLEM     | [TODO: What pain it solves]  |
| KEY INSIGHT | [TODO: Core principle]       |
| USE WHEN    | [TODO: Primary use case]     |
| AVOID WHEN  | [TODO: When not to use]      |
| ANTI-PATTERN| [TODO: Common misuse]        |
| TRADE-OFF   | [TODO: What you give up]     |
| ONE-LINER   | [TODO: Interview summary]    |
| KEY NUMBERS | [TODO: 2-3 critical thresholds]  |
| TRIGGER   | [TODO: 5-7 word mental model]  |
| OPENING   | [TODO: First sentence depth]   |
+-------------------------------------------+
```
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Rate Limiter. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: Design a rate limiter for a multi-tier API (free/pro/enterprise). How do you handle distributed counting?**

_Why they ask:_ Tests system design across functional and non-functional requirements.

_Strong answer:_

**Tiered limits:**

```
Free:       100 req/day,   10 req/min
Pro:        10K req/day,  100 req/min
Enterprise: 1M  req/day, 5000 req/min
```

**Architecture:**

```
Request -> API Gateway -> Check API key
  -> Lookup tier from cache (Redis hash)
  -> Rate limit check (Redis):
     Key: rl:{apiKey}:{minute}
     INCR + EXPIRE (atomic via Lua script)
     Compare against tier limit
  -> If allowed: forward to service
  -> If blocked: 429 + Retry-After header
```

**Redis Lua script (atomic check + increment):**

```lua
local key = KEYS[1]
local limit = tonumber(ARGV[1])
local window = tonumber(ARGV[2])

local current = redis.call('INCR', key)
if current == 1 then
    redis.call('EXPIRE', key, window)
end
if current > limit then
    return 0  -- rejected
end
return 1  -- allowed
```

**Distributed (multi-region):**

- Redis cluster per region for per-minute limits (local, fast)
- Daily limits: sync across regions every 10 seconds
- Over-counting by ~1%: acceptable (better to slightly over-limit than under-limit)
- Enterprise SLA: dedicated rate limiter instance (no noisy neighbor)

**Graceful degradation:**

- If Redis is down: allow all requests (fail open) with local in-memory rate limiter as fallback
- Never fail closed (reject all) due to rate limiter failure - that's a self-inflicted outage
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# News Feed and Timeline

**TL;DR** - Design a social media news feed (like Twitter/Facebook) that shows each user a personalized, ranked timeline. Core challenge: fan-out (1 post from a user with 10M followers must appear in 10M timelines). Two approaches: fan-out-on-write (pre-compute) vs fan-out-on-read (compute at read time).
---

### 🔥 The Problem This Solves

User follows 500 people. Each posts multiple times daily. Building a real-time feed by querying "all posts from all followed users, sorted by time" requires joining 500 users' posts at read time - too slow at scale.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - Back-of-Envelope Estimation**

```
Users: 500M DAU
Posts: 2 posts/day per active user = 1B posts/day
Feed reads: 10 feed views/day per user = 5B reads/day
Read QPS: 5B / 86400 = ~58K reads/sec, peak ~175K

Average user follows: 200 people
Celebrity (> 100K followers): ~50K accounts

Storage per post:
  postId(8B) + userId(8B) + text(300B) + meta(100B)
  = ~400B per post

Timeline cache per user:
  200 posts * 8B postId = 1.6KB per user
  500M users * 1.6KB = ~800GB (fits in Redis cluster)
```

**Level 2 - High-Level Design**

```
Post creation:
  User -> Post Service -> DB (posts table)
    -> Fan-out Service -> write to followers' timelines

Feed read:
  User -> Feed Service -> Timeline Cache (Redis)
    cache miss -> build from followed users' posts
```

**Level 3 - Fan-out Strategies (The Core Trade-off)**

**Fan-out-on-write (push model):**

```
User A posts:
  -> Get A's followers: [B, C, D, ... 10K users]
  -> For each follower:
     LPUSH timeline:{followerId} postId
  -> 10K writes to Redis

Feed read for B:
  LRANGE timeline:B 0 199
  -> Instant! Pre-computed.

Pros: Fast reads (pre-computed)
Cons: Slow writes for celebrities
  Celeb with 10M followers:
  1 post = 10M timeline writes (~100 seconds!)
```

**Fan-out-on-read (pull model):**

```
User A posts:
  -> Write to A's posts list only
  -> 1 write. Done.

Feed read for B:
  -> Get B's following list: [A, C, D, ...]
  -> Fetch recent posts from each
  -> Merge + sort by timestamp
  -> Return top 200

Pros: Fast writes, no fan-out delay
Cons: Slow reads (merge N users' posts at read time)
  Following 500 users = 500 queries + merge
```

**Hybrid approach (what Twitter does):**

```
Regular users (< 10K followers):
  Fan-out-on-write (pre-compute timelines)

Celebrities (> 10K followers):
  Don't fan out. Store posts separately.

Feed read:
  1. Get pre-computed timeline (fast, from cache)
  2. Get celebrity posts (small number of queries)
  3. Merge and rank

  99% of posts are from regular users (pre-computed)
  Only merge ~10-50 celebrity feeds at read time
```

**Level 4 - Feed Ranking and Optimization**

**Ranking pipeline:**

```
Raw timeline (chronological):
  [post1_t10, post2_t9, post3_t8, ...]

Ranking model:
  Score(post) =
    w1 * recency +
    w2 * engagement(likes, comments, shares) +
    w3 * userAffinity(how often reader interacts
         with author) +
    w4 * contentRelevance(ML model) -
    penalty(already seen similar content)

Ranked timeline:
  [post3(score:92), post1(score:85), post2(score:70)]
```

**Cache invalidation:**

```
Timeline cache (Redis):
  Key: timeline:{userId}
  Value: sorted list of postIds
  TTL: 24 hours

  New post by followed user:
    LPUSH timeline:{followerId} newPostId
    LTRIM timeline:{followerId} 0 799 (keep 800 max)

  User unfollows someone:
    Remove that user's posts from timeline
    Or: rebuild timeline (simpler)
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

```
+-------------------------------------------+
| WHAT IT IS  | [TODO: 1-line definition]   |
| PROBLEM     | [TODO: What pain it solves]  |
| KEY INSIGHT | [TODO: Core principle]       |
| USE WHEN    | [TODO: Primary use case]     |
| AVOID WHEN  | [TODO: When not to use]      |
| ANTI-PATTERN| [TODO: Common misuse]        |
| TRADE-OFF   | [TODO: What you give up]     |
| ONE-LINER   | [TODO: Interview summary]    |
| KEY NUMBERS | [TODO: 2-3 critical thresholds]  |
| TRIGGER   | [TODO: 5-7 word mental model]  |
| OPENING   | [TODO: First sentence depth]   |
+-------------------------------------------+
```
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for News Feed and Timeline. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: A celebrity with 50M followers posts. How do you handle the fan-out without delaying their post?**

_Why they ask:_ Tests the hybrid fan-out design and priority handling.

_Strong answer:_

**Don't fan out for celebrities. Pull at read time.**

```
Celebrity posts:
  -> Write to celebrity_posts table (1 write)
  -> Update celebrity's post cache (Redis)
  -> Notify online followers via WebSocket
     (only currently connected users, not all 50M)

Follower reads feed:
  1. Fetch pre-computed timeline (regular users' posts)
  2. Fetch celebrity posts for followed celebrities:
     - User follows 5 celebrities
     - 5 Redis reads (cached post lists)
     - Each returns last 10 posts
  3. Merge 50 celebrity posts with pre-computed timeline
  4. Rank and return top 200

  Total extra latency: ~5ms (5 Redis reads + merge)
```

**Celebrity threshold:**

- Follower count > 10K -> mark as celebrity
- Periodically recalculate (users gain/lose followers)
- Celebrity flag cached with user profile

**For online followers (real-time):**

- Push notification via WebSocket (only connected users)
- Pre-compute for active users only (signed in last 24h)
- Inactive users: build timeline on-demand when they return
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Chat System

**TL;DR** - Design a real-time messaging system (like WhatsApp/Slack) supporting 1:1 chats and group chats. Core challenges: real-time delivery via WebSockets, message ordering, offline message delivery, and scaling persistent connections across millions of users.
---

### 🔥 The Problem This Solves

Users expect messages delivered in real-time (< 200ms) with guaranteed delivery (even if recipient is offline), correct ordering (messages in a conversation appear in the order sent), and multi-device sync. HTTP polling is too slow and wasteful.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - Back-of-Envelope Estimation**

```
DAU: 500M
Messages/day: 500M * 40 msgs = 20B messages/day
Message QPS: 20B / 86400 = ~230K messages/sec
Peak: ~700K messages/sec

Concurrent connections:
  500M DAU, 30% online at peak = 150M WebSocket connections
  Each connection: ~10KB memory
  150M * 10KB = 1.5TB RAM for connections
  1.5TB / 64GB per server = ~24 chat servers (minimum)

Storage:
  Message: 200B avg (text + metadata)
  20B/day * 200B = 4TB/day
  5 years: ~7PB (use tiered storage)
```

**Level 2 - High-Level Design**

```
Sender -> WebSocket -> Chat Server -> Message Queue
              |                           |
         Connection    +------------------+
         Manager       |
              |     Message Store (DB)
              |        |
         Recipient <- WebSocket <- Chat Server
         (online)

         Recipient (offline):
           -> Push notification (APNs/FCM)
           -> Messages stored, delivered on reconnect
```

**Level 3 - Core Components**

**Connection management:**

```
User connects:
  -> WebSocket to Chat Server (sticky)
  -> Register in Redis:
     user:{userId} -> {serverId, connectionId}
  -> Heartbeat every 30s (detect disconnect)

User disconnects:
  -> Remove from Redis registry
  -> Mark as offline

Sending message to User B:
  1. Lookup: WHERE is User B connected?
     Redis: user:B -> server-3
  2. Route message to server-3
     (via message queue or direct gRPC)
  3. Server-3 pushes to B's WebSocket
```

**Message flow (1:1 chat):**

```java
// Sender sends message
Message {
    messageId: "uuid-1234",
    conversationId: "conv-AB",
    senderId: "userA",
    recipientId: "userB",
    text: "Hello!",
    timestamp: 1640000001,
    sequenceNum: 42  // per-conversation ordering
}

// Processing:
1. Validate (auth, content moderation)
2. Persist to message store
3. Route to recipient:
   a. Online -> push via WebSocket
   b. Offline -> store in unread queue
      + push notification
4. ACK to sender (double checkmark)
5. Read receipt from recipient (blue checkmark)
```

**Group chat:**

```
Group: 500 members
Message sent to group:
  -> Persist once (in group messages table)
  -> Fan out to online members via WebSocket
  -> Offline members: increment unread counter
  -> On reconnect: fetch unread messages

Optimization for large groups:
  Don't fan out delivery status per-member
  "Delivered to group" = delivered to server
  Individual read receipts only for small groups
```

**Level 4 - Ordering and Consistency**

**Message ordering challenge:**

```
Problem: Network latency varies
  User A sends msg1 at t=0, msg2 at t=1
  msg2 arrives at server before msg1 (network reorder)

Solution: Per-conversation sequence number
  Client assigns local sequence number
  Server reorders by sequence within conversation

  Alternatively: Server assigns sequence number
  using atomic counter per conversation
  (Redis INCR on conv:{conversationId}:seq)
```

**Multi-device sync:**

```
User logged in on Phone + Laptop:
  Both connected via WebSocket

Message for User A:
  -> Deliver to ALL of A's active connections
  -> Redis: user:A -> [{server1, phone},
                        {server2, laptop}]
  -> Push to both

Sync on reconnect:
  Client sends: "last seen sequenceNum = 150"
  Server sends: all messages with seq > 150
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

```
+-------------------------------------------+
| WHAT IT IS  | [TODO: 1-line definition]   |
| PROBLEM     | [TODO: What pain it solves]  |
| KEY INSIGHT | [TODO: Core principle]       |
| USE WHEN    | [TODO: Primary use case]     |
| AVOID WHEN  | [TODO: When not to use]      |
| ANTI-PATTERN| [TODO: Common misuse]        |
| TRADE-OFF   | [TODO: What you give up]     |
| ONE-LINER   | [TODO: Interview summary]    |
| KEY NUMBERS | [TODO: 2-3 critical thresholds]  |
| TRIGGER   | [TODO: 5-7 word mental model]  |
| OPENING   | [TODO: First sentence depth]   |
+-------------------------------------------+
```
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Chat System. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: How do you guarantee message delivery even when the recipient is offline for days?**

_Why they ask:_ Tests reliability design for async messaging.

_Strong answer:_

**Delivery guarantee layers:**

```
Layer 1: Persistent storage
  Every message written to durable store
  BEFORE delivery attempt
  (message survives any crash)

Layer 2: Undelivered queue per user
  Redis sorted set: undelivered:{userId}
  Score = timestamp, Member = messageId

  Online: deliver via WebSocket, remove from queue
  Offline: stays in queue until reconnect

Layer 3: Reconnection sync
  Client reconnects:
    -> Send "lastSeqNum: 150"
    -> Server: fetch messages with seq > 150
       from message store
    -> Deliver batch
    -> Client ACKs each message
    -> Server removes from undelivered queue

Layer 4: Push notification
  If offline > 5 seconds:
    -> Send push notification (APNs/FCM)
    -> "You have 3 new messages from Alice"
    -> Coalesce multiple messages into one push
```

**What about device storage limits?**

```
Keep last 10K messages on device (SQLite)
Older messages: fetch from server on scroll-up
Server retention: 5 years in tiered storage
  - Hot (< 30 days): SSD (fast)
  - Warm (30 days - 1 year): HDD
  - Cold (> 1 year): S3/Glacier (cheap)
```

**End-to-end encryption consideration:**

```
Messages encrypted client-side (Signal protocol)
Server stores ciphertext (can't read messages)
Multi-device: each device has its own key pair
  Message encrypted N times (once per device)
  Server stores N ciphertexts per message
```
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]


---

---

# Notification System

**TL;DR** - Design a notification system that delivers push notifications, emails, SMS, and in-app notifications to millions of users with low latency, guaranteed delivery, and user preferences. Core challenges: multi-channel routing, deduplication, rate limiting, and handling provider failures.
---

### 🔥 The Problem This Solves

Users need to be notified about events (order shipped, payment received, friend request) across multiple channels. Each user has different preferences (email for orders, push for messages, no SMS). Without a centralized system, every service implements its own notification logic - inconsistent, unmaintainable, and users get spammed.
---

### 📘 Textbook Definition

[TODO: 2-4 sentences. Formal. Technically precise.]
---

### ⏱️ Understand It in 30 Seconds

**One line:**
[TODO: 15 words max. Zero jargon.]

**One analogy:**
> [TODO: 2-3 sentence real-world analogy.]

**One insight:**
[TODO: What separates knowing the name from understanding it.]
---

### 🔩 First Principles Explanation

**CORE INVARIANTS:**
1. [TODO: Always true about this concept]
2. [TODO: Always true about this concept]
3. [TODO: Always true about this concept]

**DERIVED DESIGN:**
[TODO: How the invariants force the design.]

**THE TRADE-OFFS:**
**Gain:** [TODO]
**Cost:** [TODO]

**ESSENTIAL vs ACCIDENTAL COMPLEXITY:**
**Essential:** [TODO]
**Accidental:** [TODO]
---

### 🧠 Mental Model / Analogy

> [TODO: Primary analogy in blockquote.]

- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]
- "[TODO: Analogy element]" -> [technical element]

Where this analogy breaks down: [TODO: 1 sentence.]
---

### 📶 Gradual Depth - Five Levels

**Level 1 - Back-of-Envelope Estimation**

```
Users: 100M
Notifications/day: 500M (5 per user avg)
Peak: 3x average = ~17K notifications/sec

Channel distribution:
  Push: 60% = 300M/day
  Email: 30% = 150M/day
  SMS: 5% = 25M/day
  In-app: 100% = 500M/day (always stored)

Provider costs:
  Push (APNs/FCM): free
  Email (SES): $0.10/1000 = $15K/day
  SMS (Twilio): $0.0075/msg = $187K/day
  -> SMS is expensive, use sparingly
```

**Level 2 - High-Level Design**

```
Event Source      Notification Service     Channels
+-----------+     +------------------+     +-------+
| Order Svc |---->|                  |---->| APNs  |
| Payment   |---->| Priority Queue   |---->| FCM   |
| Social    |---->| + Router         |---->| Email  |
| Marketing |---->| + Preferences    |---->| SMS    |
+-----------+     | + Rate Limiter   |---->| In-App |
                  | + Template Engine|     +-------+
                  +------------------+
                         |
                    Notification DB
                    (delivery status)
```

**Level 3 - Core Components**

**Notification routing:**

```java
// Event arrives
NotificationEvent event = {
    userId: "user-42",
    type: "ORDER_SHIPPED",
    templateId: "order-shipped-v2",
    data: { orderId: "123", trackingUrl: "..." },
    priority: "HIGH"
};

// Route based on user preferences:
UserPreferences prefs = prefsService.get("user-42");
// prefs: { ORDER_SHIPPED: [PUSH, EMAIL],
//          MARKETING: [EMAIL],
//          SOCIAL: [PUSH, IN_APP] }

// For ORDER_SHIPPED -> send PUSH + EMAIL
// Always store in-app notification
```

**Priority queue design:**

```
3 priority queues:
  CRITICAL: payment failures, security alerts
    -> Process immediately, all channels
  HIGH: order updates, friend requests
    -> Process within 30 seconds
  LOW: marketing, recommendations
    -> Process within 5 minutes, rate-limited

Kafka topics:
  notifications-critical (3 partitions)
  notifications-high (10 partitions)
  notifications-low (5 partitions)

Consumers: more workers on critical/high queues
```

**Deduplication:**

```
Problem: Event published twice (at-least-once),
  user gets 2 identical notifications.

Solution: Idempotency key per notification
  Key = hash(userId + eventType + eventId)

  Redis: SETNX dedup:{key} 1 EX 86400
  If already exists -> skip (duplicate)

  Also prevents:
  - "Your order shipped" sent 3 times
  - Same marketing email sent twice
```

**Level 4 - Reliability and Provider Failover**

**Multi-provider with fallback:**

```
Push notification delivery:
  1. Try FCM (Android) or APNs (iOS)
  2. If FCM fails (timeout/5xx):
     -> Retry 3x with exponential backoff
  3. If still failing:
     -> Fallback to SMS (if critical)
     -> Or queue for retry in 1 hour
  4. After 24h of failures:
     -> Mark device token as invalid
     -> Remove from notification targets

Email delivery:
  Primary: Amazon SES
  Fallback: SendGrid
  If SES returns 429 (throttled):
    -> Route to SendGrid
    -> Alert ops (SES quota issue)
```

**Rate limiting per user:**

```
Rules:
  Max 3 push notifications/hour per user
  Max 1 email/day for marketing
  Max 1 SMS/week for non-critical
  No limit for critical (security alerts)

Implementation:
  Redis: rl:push:{userId}:{hour} INCR
  If count > 3 -> hold in queue, deliver next hour

  Coalescing:
  If 5 notifications queued in same hour:
    -> Combine into single push:
    "You have 5 new updates"
```

**Notification analytics:**

```
Track per notification:
  - Sent timestamp
  - Delivered timestamp (provider callback)
  - Opened timestamp (tracking pixel for email,
    push open callback)
  - Clicked timestamp (redirect URL tracking)

Metrics dashboard:
  - Delivery rate by channel (target: >99% push,
    >95% email)
  - Open rate (push: ~5-10%, email: ~20-30%)
  - Click-through rate
  - Unsubscribe rate (should be < 0.5%)
```




**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics.
 What would you change if redesigning today?
 How does this compose at extreme scale?]
---

### How It Works (Mechanism)

[TODO: Internal mechanics. Data flow. Key steps.
 4-8 sentences covering implementation details.]
---

### 🔄 Complete Picture - End-to-End Flow

**NORMAL FLOW:**
[TODO] -> [TODO] -> [THIS CONCEPT <- YOU ARE HERE]
       -> [TODO]

**FAILURE PATH:**
[TODO: cascade -> observable symptom]

**WHAT CHANGES AT SCALE:**
[TODO: 2-3 sentences on behaviour at 10x/100x/1000x load.]
---

### 📌 Quick Reference Card

```
+-------------------------------------------+
| WHAT IT IS  | [TODO: 1-line definition]   |
| PROBLEM     | [TODO: What pain it solves]  |
| KEY INSIGHT | [TODO: Core principle]       |
| USE WHEN    | [TODO: Primary use case]     |
| AVOID WHEN  | [TODO: When not to use]      |
| ANTI-PATTERN| [TODO: Common misuse]        |
| TRADE-OFF   | [TODO: What you give up]     |
| ONE-LINER   | [TODO: Interview summary]    |
| KEY NUMBERS | [TODO: 2-3 critical thresholds]  |
| TRIGGER   | [TODO: 5-7 word mental model]  |
| OPENING   | [TODO: First sentence depth]   |
+-------------------------------------------+
```
---

### ✅ Mastery Checklist

**You've mastered this when you can:**
1. **EXPLAIN:** [TODO: Teach to a junior in 2 min without notes]
2. **DEBUG:** [TODO: Diagnose a specific failure from symptoms]
3. **DECIDE:** [TODO: Choose this vs alternative under pressure]
4. **BUILD:** [TODO: Implement/configure in production context]
5. **EXTEND:** [TODO: Apply principle to a different domain]---

### 💡 The Surprising Truth

[TODO: 2-4 sentences. One counterintuitive fact.
 Specific. Makes this concept permanently memorable.]
---

### ⚖️ Comparison Table

[TODO: Include if 2+ named alternatives exist for Notification System. Otherwise remove this section.]
---

### ⚠️ Common Misconceptions

| # | Misconception | Reality |
|---|---------------|---------|
| 1 | [TODO] | [TODO] |
| 2 | [TODO] | [TODO] |
| 3 | [TODO] | [TODO] |
| 4 | [TODO] | [TODO] |
---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 2: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]

**Failure Mode 3: [TODO]**
**Symptom:** [TODO]
**Root Cause:** [TODO]
**Diagnostic:**
```
[TODO: real diagnostic command]
```
**Fix:** [TODO: BAD then GOOD]
**Prevention:** [TODO]
---

### 🎯 Interview Deep-Dive

**Q1: A flash sale starts and 10M users need to be notified simultaneously. How do you handle the spike?**

_Why they ask:_ Tests scalability under burst load.

_Strong answer:_

**Problem:** 10M notifications in < 1 minute. Normal throughput: 17K/sec. Need: 170K/sec (10x).

**Pre-scheduling:**

```
1. Marketing team schedules sale notification
   for 10:00 AM, 3 days in advance

2. Pre-processing (night before):
   - Resolve user preferences for 10M users
   - Generate personalized content
   - Pre-render email templates
   - Store in "ready to send" queue
   - Batch by channel:
     Push: 8M messages (pre-formatted)
     Email: 6M messages (pre-rendered)

3. At 10:00 AM: release pre-built batches
   - Push: FCM supports batch API (1000/request)
     8M / 1000 = 8K API calls
     100 workers * 80 calls each = done in ~30s
   - Email: SES batch (50 emails/call)
     6M / 50 = 120K API calls
     50 workers * 2400 calls = ~2 min
```

**Infrastructure scaling:**

```
Auto-scale notification workers:
  CloudWatch alarm on queue depth
  If queue > 100K -> scale to 200 workers
  Pre-warm: schedule scale-up 5 min before sale

Provider limits:
  FCM: ~500K msg/sec (no practical limit)
  APNs: ~100K msg/sec per connection
  SES: request limit increase to 1M/day

  If hitting SES limit:
    -> Overflow to SendGrid
    -> Both providers in parallel
```

**Staggered delivery (prevent thundering herd):**

```
Don't send 10M pushes at exactly 10:00:00
  -> 10M users open app simultaneously
  -> Backend crushed by 10M requests

Instead: stagger over 5 minutes
  Batch 1 (10:00:00): 2M users
  Batch 2 (10:01:00): 2M users
  ...
  Batch 5 (10:04:00): 2M users

Users in batch 1: loyal customers (priority)
Users in batch 5: least active (lower priority)
```

**Q2: How do you handle notification preferences across channels without it becoming a maintenance nightmare?**

_Why they ask:_ Tests data model design for preferences.

_Strong answer:_

**Preference model:**

```json
{
  "userId": "user-42",
  "channels": {
    "push": {
      "enabled": true,
      "quiet_hours": { "start": "22:00", "end": "08:00" }
    },
    "email": { "enabled": true, "frequency": "daily_digest" },
    "sms": { "enabled": false }
  },
  "categories": {
    "ORDER_UPDATES": ["push", "email"],
    "SOCIAL": ["push"],
    "MARKETING": ["email"],
    "SECURITY": ["push", "email", "sms"]
  },
  "unsubscribed": ["MARKETING"]
}
```

**Resolution order:**

```
1. Global channel enabled? (push=true)
2. Category subscribed? (not in unsubscribed)
3. Category channel preference? (ORDER -> push+email)
4. Quiet hours? (push suppressed 10pm-8am)
5. Rate limit? (< 3 push/hour)
6. Regulatory compliance? (GDPR consent check)

Final decision: send or suppress, per channel
```

**Default preferences (new users):**

- All categories enabled
- Push + in-app for everything
- Email for orders and security only
- SMS for security only
- Quiet hours: 10pm - 8am local time
---

### 🔗 Related Keywords

**Prerequisites (understand these first):**
- [TODO] - [why needed]
- [TODO] - [why needed]

**Builds on this (learn these next):**
- [TODO] - [what it adds]
- [TODO] - [what it adds]

**Alternatives / Comparisons:**
- [TODO] - [when to prefer it]
- [TODO] - [when to prefer it]
