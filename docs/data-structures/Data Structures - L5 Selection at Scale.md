---
layout: default
title: "Data Structures - L5 Selection at Scale"
parent: "Data Structures"
nav_order: 13
permalink: /data-structures/l5-selection-at-scale/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 1 | [Data Structure Selection at Scale](#data-structure-selection-at-scale) | high |

---

# Data Structure Selection at Scale

**Difficulty:** ★★★

**Interview Weight:** High

---

### 🎯 Model Answer

**30 seconds:**
Data structure selection at scale is a multi-dimensional decision driven by access patterns, cardinality, latency requirements, and the operational cost of the choice. The key insight: the "best" data structure depends on the read/write ratio, whether the dominant operation is point lookup, range query, or aggregation, and whether the dataset fits in memory. At 10x scale, a HashMap becomes a distributed hash table. At 100x, your B+ Tree index becomes an LSM Tree. At 1000x, your in-memory sorted set becomes Redis Cluster.

**3 minutes:**
The selection framework:

Step 1 - Characterize the access pattern:
- Point lookup (key -> value): hash table (O(1) average) or B+ Tree (O(log n) guaranteed).
- Range query (all keys in [a,b]): sorted structure (B+ Tree, skip list) or columnar store.
- Aggregation (sum, count, max): columnar layout (cache-efficient full scans).
- Mixed: separate read and write paths (CQRS with different data structures per query type).

Step 2 - Characterize the write pattern:
- Write-heavy: LSM Tree (append-only) over B+ Tree (random writes).
- Read-heavy: B+ Tree or sorted array (optimize read performance, accept write overhead).
- Mixed: B+ Tree for balanced workloads.

Step 3 - Scale dimension:
- Fits in L1 (32KB): any structure; choose for correctness/simplicity.
- Fits in L3 (8MB): prefer sequential layouts (Eytzinger, B+ Tree with 64-byte nodes).
- Fits in RAM: B+ Tree or skip list; avoid O(n) full scans.
- Exceeds RAM: LSM Tree for writes; B+ Tree for reads; sharded distributed hash table.
- Multi-machine: consistent hashing for key-based distribution; replicated sorted indexes for range queries.

Step 4 - Operational constraints:
- Concurrent access: skip list (CAS lock-free) or B+ Tree with lock coupling.
- Persistence: B+ Tree + WAL for durability.
- Compaction pressure: LSM Tree requires background compaction; must be accounted for in capacity planning.

**Blank Mind Recovery:**
**(1) Key dimensions:** "Access pattern (point/range/aggregate). Write ratio (read-heavy/write-heavy). Scale (fits in L1/L3/RAM/disk/multi-machine). Concurrency."
**(2) Core rules:** "Write-heavy -> LSM Tree. Read-heavy range -> B+ Tree. Concurrent sorted -> skip list. Exact membership -> hash table. Approximate membership -> Bloom filter."
**(3) Scale rules:** "10x: add indices. 100x: switch storage engine. 1000x: distribute."
**(4) Anti-pattern:** "Premature optimization - a HashMap is correct at 10K elements. Optimize only when profiling proves it necessary."

---

### 📘 Concept Explanation

**What it is:**
Data structure selection at scale is the engineering discipline of choosing the appropriate data structure for a given workload by analyzing access patterns, scale, and operational constraints - then revisiting the choice as scale changes.

**The problem it solves:**
A data structure optimal at 1K elements may fail at 1M (doesn't fit in cache) or 1B (doesn't fit in RAM). A structure optimal for read-heavy workloads may cause I/O saturation under write-heavy workloads. Systematic selection avoids premature or inappropriate optimization.

**The selection decision tree:**

```
Data Structure Selection Decision Tree:

Q1: What is the primary operation?
  |
  +--[point lookup by key]--> HashMap (exact key)
  |                        or B+ Tree (range too)
  |                        or Bloom Filter (exist check)
  |
  +--[range query by key]--> B+ Tree or Skip List
  |                       or Sorted Array (static)
  |
  +--[aggregation/scan]--> Column store / Array
  |                     or Bitmap index
  |
  +--[priority / ordering]--> Heap / B+ Tree

Q2: What is the write pattern?
  |
  +--[write-heavy (>50% writes)]--> LSM Tree
  |                               or Append-only log
  |
  +--[read-heavy (>80% reads)]--> B+ Tree
  |                             or Sorted immutable files
  |
  +--[balanced]--> B+ Tree (default)

Q3: Does data fit in memory?
  |
  +--[yes, fits in L1/L2]--> Any; prefer simple
  |
  +--[yes, fits in RAM]--> Hash table or B+ Tree
  |
  +--[no, requires disk]--> B+ Tree (random reads)
                          or LSM Tree (sequential writes)

Q4: Is concurrent access required?
  |
  +--[yes, high contention]--> Skip list (CAS)
  |                          or ConcurrentHashMap
  |
  +--[yes, mostly reads]--> Lock-free reads + copy-on-write
  |
  +--[no]--> Any sequential structure
```

> **Diagram walkthrough:** Data structure selection decision tree with four hierarchical decision levels: primary operation, write pattern, memory fit, and concurrency. The key relationship: each level narrows the viable choices. A system requiring point lookup + write-heavy + disk-based naturally selects LSM Tree; a system requiring range queries + read-heavy + in-memory naturally selects B+ Tree or skip list. Edge case: "balanced" read/write workloads (50/50) with disk storage favor B+ Tree for OLTP patterns (small transactions, point lookups) but favor LSM Tree for OLAP-adjacent patterns (bulk inserts, sequential scans). Insight: the decision tree is not prescriptive - it guides initial selection, and the correct answer is always validated by profiling. A theoretically optimal choice that is difficult to operate (complex tuning, poor tooling) should be avoided in favor of a simpler "good enough" choice with better operational characteristics.

**Scale dimension analysis - how requirements change:**

```
Access Pattern Evolution at Scale:

Scale     | N elements | Typical fit | Optimal structure
----------|------------|-------------|--------------------
Tiny      | < 1K       | L1 cache    | ArrayList + linear
Small     | < 64K      | L2 cache    | HashMap / TreeMap
Medium    | < 8M       | L3 cache    | HashMap / B+ Tree
Large     | < 500M     | RAM         | B+ Tree / LSM Tree
Huge      | < 1T       | Single disk | LSM Tree + Bloom
XL        | > 1T       | Multi-disk  | Distributed LSM
Extreme   | > 1P       | Multi-node  | Consistent hash shards

Rule of thumb (memory):
  10K int entries    = 40KB  (L2 cache)
  100K int entries   = 400KB (L2 cache)
  1M int entries     = 4MB   (L3 cache, barely)
  10M int entries    = 40MB  (RAM)
  100M int entries   = 400MB (RAM)
  1B int entries     = 4GB   (RAM, large)
  10B int entries    = 40GB  (RAM, server)
  100B int entries   = 400GB (disk required)

Turning points:
  At n=1M:   Consider if data fits in L3 cache
  At n=100M: Consider disk-backed structures
  At n=10B:  Consider distributed storage
```

> **Diagram walkthrough:** Scale dimension table mapping element counts to memory tiers and optimal data structures. The key relationship: as n grows, the optimal structure shifts from simple (ArrayList for tiny) to cache-optimized (B+ Tree) to disk-optimized (LSM Tree) to distributed. The turning points at n=1M (L3 boundary), n=100M (RAM boundary), and n=10B (single-machine RAM boundary) are the critical scale inflection points. Edge case: cloud-native systems often have larger RAM (256GB-2TB per node) which shifts the turning points significantly. Know your hardware before assuming which scale tier applies. Insight: the scale dimension is often the most important selection criterion in practice - a data structure choice that works perfectly at 10M elements may need to be completely replaced at 1B elements. Building the system to make this transition possible (clean interfaces, pluggable storage) is as important as the initial selection.

**Write-heavy vs read-heavy structure comparison:**

```java
// Pattern: write-heavy workload - use LSM Tree approach
// (Analogous to what Cassandra, RocksDB do)

// BAD: B+ Tree for write-heavy workload
// Each insert potentially requires random disk write
// Under 100K inserts/second: random I/O saturates
class WriteHeavyBTree {
    // B+ Tree: each insert traverses tree,
    // modifies leaf page, potentially splits pages.
    // Random write at any leaf page in the tree.
    // For 100M record B-Tree: leaf pages scattered
    // across the entire file. Each insert = random I/O.
    // Random I/O: SSD ~70K IOPS, HDD ~200 IOPS
    // At 100K inserts/sec: need 100K IOPS -> SSD saturated
}

// GOOD: LSM Tree for write-heavy workload
// All writes go to in-memory MemTable (sorted)
// Flush to disk as sequential SSTable files
// Background compaction merges SSTables
class WriteHeavyLSMTree {
    // MemTable: in-memory skip list or red-black tree
    // 100K inserts/sec -> MemTable fills in ~1 second
    // Flush: write MemTable sequentially to disk
    //   Sequential write: SSD ~500MB/s = far faster than
    //   100K random writes at 4KB each = 400MB/s but
    //   with seek overhead -> LSM wins by 10x
    // Read: check MemTable, then SSTables (Bloom filter
    //   eliminates 99% of unnecessary SSTable reads)
}
// LSM Tree write throughput: 10-100x B+ Tree
// LSM Tree read throughput: 3-5x worse than B+ Tree
// Decision: >50% writes -> LSM Tree
```

> **Code walkthrough:** Write-heavy workload comparison between B+ Tree and LSM Tree approach. The KEY MECHANISM: B+ Tree write requires finding the correct leaf page (O(log n) = random seeks) and modifying it in-place. LSM Tree write goes to MemTable (in memory, no I/O) and is later flushed sequentially. Sequential disk writes are 10-100x faster than random writes on both SSD and HDD. WHY IT MATTERS: at 100K inserts/second to a 100M-record B+ Tree, the leaf pages are scattered across the entire data file. Each insert requires a random I/O. SSDs handle ~70K-100K random 4KB writes/second; this workload saturates the SSD at 100K inserts/sec. LSM Tree avoids random writes entirely. WHAT BREAKS: LSM Trees have write amplification (data is re-written multiple times during compaction). For a 10-level LSM Tree, write amplification factor of 10-30x means 100K logical writes/sec requires 1-3M physical writes/sec to disk. Monitor I/O utilization; excessive write amplification saturates disk bandwidth. TAKEAWAY: write amplification is the primary LSM Tree cost - for write-heavy workloads, the no-random-write benefit outweighs write amplification; for balanced workloads, B+ Tree may be better.

---

### 💻 Code Example

**Decision framework implementation:**

```java
// Framework: choose data structure based on profiled
// access pattern and scale

class DataStructureSelector {

    enum PrimaryOp { POINT_LOOKUP, RANGE_QUERY,
                     AGGREGATION, PRIORITY }
    enum WriteRatio { READ_HEAVY, BALANCED, WRITE_HEAVY }
    enum Scale { IN_CACHE, IN_MEMORY, ON_DISK,
                 DISTRIBUTED }

    static String recommend(
        PrimaryOp op, WriteRatio writes, Scale scale
    ) {
        return switch (op) {
            case POINT_LOOKUP -> switch (scale) {
                case IN_CACHE, IN_MEMORY ->
                    writes == WriteRatio.WRITE_HEAVY
                    ? "ConcurrentHashMap (lock-free)"
                    : "HashMap (simple)";
                case ON_DISK ->
                    writes == WriteRatio.WRITE_HEAVY
                    ? "RocksDB (LSM Tree)"
                    : "BTreeMap (B+ Tree)";
                case DISTRIBUTED -> "DynamoDB / Redis Cluster";
            };
            case RANGE_QUERY -> switch (scale) {
                case IN_CACHE -> "Sorted array (Eytzinger)";
                case IN_MEMORY ->
                    "TreeMap / ConcurrentSkipListMap";
                case ON_DISK ->
                    writes == WriteRatio.WRITE_HEAVY
                    ? "Cassandra (LSM + range query)"
                    : "PostgreSQL B+ Tree index";
                case DISTRIBUTED ->
                    "Cassandra / HBase / Bigtable";
            };
            case AGGREGATION -> switch (scale) {
                case IN_CACHE, IN_MEMORY ->
                    "int[] with SIMD (columnar)";
                case ON_DISK ->
                    "Parquet + DuckDB (columnar)";
                case DISTRIBUTED ->
                    "ClickHouse / BigQuery";
            };
            case PRIORITY -> "PriorityQueue / d-ary heap";
        };
    }
}
// Usage:
// recommend(RANGE_QUERY, WRITE_HEAVY, ON_DISK)
//   -> "Cassandra (LSM + range query)"
// recommend(POINT_LOOKUP, READ_HEAVY, IN_MEMORY)
//   -> "HashMap (simple)"
```

> **Code walkthrough:** Decision framework mapping access pattern, write ratio, and scale to specific production data structures. The KEY MECHANISM: the three-dimensional switch statement encodes the principal selection criteria: primary operation type, write ratio, and scale tier. Each cell maps to a specific production technology with a brief rationale. WHY IT MATTERS: this framework makes implicit engineering knowledge explicit and consistent across a team. New engineers applying the framework will make decisions consistent with experienced engineers' judgment. WHAT BREAKS: the framework is a starting point, not a final answer. Every recommendation must be validated by profiling the actual workload. Production systems often have mixed access patterns (70% point lookup + 20% range + 10% aggregation) that don't fit any single category. TAKEAWAY: use the three dimensions (operation type, write ratio, scale) to get to 2-3 candidate structures, then validate with benchmarks at the actual expected workload size.

**Anti-pattern: wrong data structure at scale:**

```java
// Anti-pattern 1: LinkedList for random access
// BAD: O(n) access time, O(n) cache misses
List<User> users = new LinkedList<>();
User find = users.get(500_000); // traverses 500K nodes
// Time: 500K * 100ns cache miss = 50ms for one lookup

// FIX: ArrayList O(1) random access
List<User> users = new ArrayList<>();
User find = users.get(500_000); // O(1) array index
// Time: 1 cache miss = 100ns

// Anti-pattern 2: HashMap for sorted access
// BAD: HashMap has O(1) point lookup but no order
Map<Long, Order> orders = new HashMap<>();
// Get orders in date range: must scan ALL entries
orders.values().stream()
    .filter(o -> o.date >= start && o.date <= end)
    .collect(toList()); // O(n) scan of entire map!

// FIX: TreeMap or ConcurrentSkipListMap O(log n + k)
NavigableMap<Long, Order> orders = new TreeMap<>();
orders.subMap(start, true, end, true)
    .values(); // O(log n + k) range scan

// Anti-pattern 3: B+ Tree for pure writes
// BAD: random disk writes at 100K inserts/sec
// (described in Concept Explanation section)
// FIX: LSM Tree (described above)
```

> **Code walkthrough:** Three classic anti-patterns of wrong data structure selection at scale. The KEY MECHANISM: LinkedList.get(n) is O(n) because it must traverse n pointers; ArrayList.get(n) is O(1) direct array index computation. HashMap.values().stream().filter() is O(total_entries) because HashMap has no ordering guarantee. TreeMap.subMap() is O(log n + k) because the B+ Tree ordered structure allows direct navigation to the range start. WHY IT MATTERS: these anti-patterns are commonly found in production code written for small datasets that was never revisited as scale grew. At 10K elements, LinkedList.get(5000) takes 0.5ms (acceptable). At 1M elements, it takes 50ms (unacceptable). WHAT BREAKS: using TreeMap when HashMap is sufficient adds O(log n) overhead per lookup for no benefit when ordering is not needed. Don't over-engineer. TAKEAWAY: the "get by index" pattern demands ArrayList/array; the "iterate in sorted order" pattern demands TreeMap/skip list. Recognizing these access pattern signatures is the key skill.

---

### 🎓 Answers by Seniority

**Junior / Mid-level:**
Match data structure to access pattern: point lookup -> HashMap; sorted range -> TreeMap; priority -> heap; existence check -> Bloom filter; write-heavy sorted -> LSM Tree. Consider scale: data fits in L3 cache (8MB) -> any structure works; data in RAM -> prefer cache-friendly sequential layouts; data on disk -> B+ Tree (reads) or LSM Tree (writes). Common anti-patterns: LinkedList where ArrayList suffices, HashMap where TreeMap needed for range queries, B+ Tree for write-heavy workloads.

**Senior / Staff-level:**
At production scale, data structure selection is a system-level decision involving write amplification, read amplification, space amplification, and operational complexity. The RUM conjecture (Read-Update-Memory) states you cannot minimize all three simultaneously: any data structure has trade-offs among read amplification, update amplification, and memory amplification. LSM Trees minimize write amplification but have high read amplification (multiple SSTables to check) and high space amplification (multiple versions). B+ Trees balance read and write but have high memory amplification (page splits, fill factor). In practice: choose the structure that minimizes the amplification factor for your dominant operation, and accept higher amplification on the non-dominant operations. At staff level, the decision includes operability: an LSM Tree requires capacity planning for compaction I/O spikes; a hash table requires rehashing capacity. The "boring" choice (B+ Tree for OLTP, hash table for point lookups) is often right because it has known operational behavior at scale.

---

### ⚠️ Common Misconceptions

**Misconception 1: "The best data structure is always the one with the lowest Big-O"**
Reality: O-notation hides constant factors and cache behavior. For n < 1000, an O(n^2) insertion sort with excellent cache behavior outperforms O(n log n) merge sort. For concurrent access, a lock-based B+ Tree may outperform a lock-free skip list due to lower constant factors. Benchmark with the actual workload and scale.

**Misconception 2: "LSM Trees are always better than B+ Trees"**
Reality: LSM Trees optimize write performance at the cost of read performance (read amplification from multiple SSTables) and background CPU/disk usage (compaction). For read-heavy workloads (>80% reads), B+ Trees outperform LSM Trees significantly. RocksDB documentation recommends B+ Trees for read-heavy OLTP workloads.

**Misconception 3: "Distributed data structures are just larger versions of single-node structures"**
Reality: distribution introduces new failure modes (network partition, split-brain), consistency trade-offs (CAP theorem), and operational complexity (rebalancing, resharding). A distributed hash table is NOT a HashMap with more nodes - it requires consistent hashing, replication protocols, and failure detection. The jump from single-node to distributed is a qualitative, not quantitative, change.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Data structure choice causes latency SLA breach at scale**
- Symptom: P99 latency increases from 2ms to 200ms as dataset grows from 100K to 10M
- Cause: data structure fit in L3 cache (8MB) at 100K; overflows to RAM at 10M; O(log n) cache misses go from L3 latency (40ns) to RAM latency (100ns); 2.5x per miss * 20 misses = 50x degradation
- Diagnosis: plot P99 latency vs dataset size; look for cliff at ~2M entries (8MB L3 boundary). Confirm with perf LLC-miss measurement
- Fix: switch to B+ Tree with 64-byte nodes (reduces levels from 27 to 9 for 10M elements); or add an in-memory cache layer (LRU for hot keys)

**Failure 2: LSM Tree compaction spikes cause intermittent latency spikes**
- Symptom: normally P99 = 10ms; occasionally P99 = 1000ms; correlates with compaction
- Cause: LSM Tree compaction reads all SSTables at one level and writes a new merged SSTable; this I/O burst competes with foreground reads/writes for disk bandwidth
- Diagnosis: RocksDB stats: `db.GetProperty("rocksdb.stats")` shows compaction pending bytes; correlate latency spikes with compaction start times in log
- Fix: rate-limit compaction I/O (RocksDB: CompactionOptions.max_subcompactions, options.rate_limiter); provision separate disks for compaction and foreground I/O; accept higher space amplification to reduce compaction frequency

**Failure 3: HashMap causes GC pressure at large scale**
- Symptom: application has frequent long GC pauses; heap is 80% occupied even though useful data is much smaller
- Cause: Java HashMap uses Entry<K,V> objects (linked list nodes). 1M entries = 1M Entry objects + key + value objects. Entry has 16-byte header + key ref + value ref + next ref + hash = ~32 bytes. 1M entries = 32MB just for Entry objects, plus key and value objects.
- Diagnosis: JFR heap analysis; filter by HashMap$Entry class; check count and total retained size
- Fix: use Trove or Eclipse Collections primitive maps (avoids boxing overhead); or use an off-heap map (Chronicle Map, MapDB); or replace with a single array (open addressing) if key type allows

---

### 🎯 Interview Deep-Dive

| Timing | Questions |
|--------|-----------|
| Opening (0-3 min) | Selection criteria, basic trade-offs |
| Mid (3-10 min) | Scale scenarios, specific structures |
| Deep-dive (10-20 min) | System design, adversarial scenarios |

**[JUNIOR] Q1 - [CONCEPT] What are the primary criteria for selecting a data structure?**

1. Access pattern: what operations are needed? Point lookup (by key), range query (all keys between a and b), aggregation (sum, count, max over a field), priority (smallest/largest first). Each maps to different optimal structures.

2. Write/read ratio: how often is data modified vs read? Write-heavy (>50% inserts/updates) -> prefer LSM Tree or append-only. Read-heavy (>80% reads) -> prefer B+ Tree or hash table optimized for reads.

3. Scale: how large is the dataset? Fits in L1 cache (<32KB) -> any structure works. Fits in L3 cache (<8MB) -> prefer sequential layouts. Fits in RAM (<server RAM) -> B+ Tree or hash table. Exceeds RAM -> disk-backed structure (B+ Tree, LSM Tree).

4. Ordering requirements: do you need sorted iteration or range queries? If yes: sorted structure (B+ Tree, TreeMap, skip list). If no: hash table (simpler, O(1) average).

5. Concurrency: multiple threads? -> lock-free (skip list, ConcurrentHashMap) or lock-based B+ Tree with lock coupling.

*What separates good from great:* Knowing to check BOTH the access pattern AND scale before selecting - the theoretically correct structure (B+ Tree for range queries) may be wrong at a specific scale tier (at 100 elements, sorted ArrayList with binary search is simpler and equally fast).

**[JUNIOR] Q2 - [CODING] Given a stream of user events, how would you find the top 10 most active users?**

A sorted structure is needed. Options:
- Sort all users by event count and take top 10: O(n log n) with O(n) space. Works if n is small.
- Maintain a min-heap of size 10: O(n log 10) = O(n). Space O(10). Best approach.

```java
// Top-K using min-heap
PriorityQueue<Map.Entry<String, Integer>> topK =
    new PriorityQueue<>(10,
        Comparator.comparingInt(Map.Entry::getValue));
Map<String, Integer> counts = new HashMap<>();

for (Event e : stream) {
    counts.merge(e.userId(), 1, Integer::sum);
}

for (var entry : counts.entrySet()) {
    topK.offer(entry);
    if (topK.size() > 10)
        topK.poll(); // remove min (lowest count)
}
// topK contains top 10 by count (min at head)
```

> **Code walkthrough:** Top-K using min-heap of size k. The KEY MECHANISM: maintain a min-heap of the top-k elements seen so far. When a new element's count exceeds the heap minimum, replace the minimum with the new element. The heap always contains the k largest elements seen. WHY IT MATTERS: this is O(n log k) time and O(k) space - far better than O(n log n) full sort. For k=10, log k = 3.3, so this is essentially O(n). WHAT BREAKS: using a MAX-heap of size k requires keeping the k SMALLEST in the heap and checking if the new element is larger than the heap minimum - easy to get backwards. A min-heap with heap.size() > k -> heap.poll() (remove minimum) always keeps the k LARGEST. TAKEAWAY: min-heap for top-K is the canonical interview pattern; memorize: maintain min-heap of size k, poll when exceeding k.

**[MID] Q3 - [TRADE-OFF] Compare HashMap, TreeMap, and LinkedHashMap. When would you use each?**

HashMap: O(1) average get/put/remove. No ordering. Best for pure point lookup with no ordering requirement. Under load factor 0.75, resize occurs (O(n) rehash). Thread-unsafe (use ConcurrentHashMap for concurrent access). Use when: fast key-value lookup, no iteration order needed.

TreeMap: O(log n) get/put/remove. Maintains sorted order by key (Red-Black Tree internally). Supports subMap(), headMap(), tailMap() for range queries. Use when: need sorted iteration, range queries, or closest-key queries (floorKey, ceilingKey).

LinkedHashMap: O(1) get/put/remove. Maintains insertion order (or access order if constructed with accessOrder=true). Access-order mode is a natural LRU cache implementation (removeEldestEntry override). Use when: need insertion-order iteration or LRU cache.

Decision:
- "Find user by ID" -> HashMap
- "Find all users with IDs 100-200" -> TreeMap (subMap)
- "LRU cache of recent queries" -> LinkedHashMap(accessOrder=true)
- "Iterate keys in insertion order" -> LinkedHashMap

*What separates good from great:* Knowing that LinkedHashMap with accessOrder=true is the standard Java LRU cache building block - often simpler than implementing a doubly linked list + HashMap from scratch.

**[MID] Q4 - [SYSTEM] How would you design the data layer for a leaderboard service with 10M users and 100K score updates/second?**

Requirements analysis:
- Point lookup (get user rank): O(log n) acceptable.
- Range query (top 100 users): O(log n + 100) = O(log n).
- Score updates: 100K/sec.
- Scale: 10M users.

Candidate structures:
1. HashMap<userId, score>: O(1) score update. Cannot answer rank query without scanning all users (O(n)).
2. B+ Tree or TreeMap: O(log n) rank query (with span augmentation). O(log n) score update (delete old score, insert new). 100K updates/sec * 2 O(log n) operations = 200K O(log n) operations/sec. Feasible.
3. Skip list with span augmentation (Redis ZSET pattern): O(log n) for both ZRANK and ZADD. Redis achieves ~500K ops/sec.
4. Sorted array: O(n) for update (must find and re-sort). Not suitable for 100K updates/sec.

Solution: Redis Sorted Set (ZSET) per leaderboard. ZADD for score updates (O(log n)). ZRANK for user rank (O(log n)). ZRANGE for top-k (O(log n + k)). At 100K updates/sec: Redis single-thread handles ~500K ops/sec -> 1 Redis instance suffices. Bloom filter not needed (all operations are on existing users).

*What separates good from great:* The span augmentation detail - a standard skip list or B+ Tree cannot answer ZRANK in O(log n) without augmenting each node with the count of nodes below it. Redis augments skip list nodes with "span" for this purpose. This distinction (skip list vs augmented skip list) separates correct from deep understanding.

**[MID] Q5 - [DEBUGGING] Your production database B+ Tree index has grown to 5x the data size. Diagnose.**

5x index/data ratio indicates severe page fragmentation or index bloat.

Step 1: measure actual fill factor. B+ Tree pages have a fill factor (typically 70-90%). A new page is 90% full. After many random inserts and deletes, pages can be as low as 30-40% full (fragmented). 3x fill factor reduction = 3x bloat.

Step 2: check for sequential vs random key inserts. Sequential inserts (monotonically increasing keys like auto-increment IDs) fill B+ Tree pages nearly 100%. Random key inserts cause page splits at random points, leaving pages 50% full on average. 50% fill = 2x bloat.

Step 3: check for "half-dead" pages. After deletes, pages may have few remaining entries but not be merged with neighbors (some B+ Tree implementations defer merges). Many sparse pages = bloat.

Step 4: run VACUUM FULL (PostgreSQL) or OPTIMIZE TABLE (MySQL) or equivalent index rebuild. This reads all data and writes a fresh B+ Tree with pages at target fill factor.

Diagnosis: check pg_relation_size() vs pg_total_relation_size() in PostgreSQL; large difference = index bloat. Also check pg_stat_user_tables.n_dead_tup for dead tuple count.

*What separates good from great:* Understanding that sequential key inserts produce near-100% fill factor while random key inserts produce ~50% fill factor (average case for a split that creates two half-full pages) - and knowing this is why auto-increment primary keys are preferred over UUID primary keys in B+ Tree indexed tables.

**[SENIOR] Q6 - [ARCHITECTURE] Explain the RUM conjecture and how it guides data structure selection.**

RUM conjecture (Idreos et al., Harvard SEAS, 2016): it is impossible to simultaneously minimize all three amplification factors in a data structure:
- Read amplification (R): how many extra reads are needed beyond the minimum to answer a query.
- Update amplification (U): how many extra writes are needed beyond the minimum to perform an update.
- Memory amplification (M): how much extra space is used beyond the minimum to store the data.

Any data structure lies on the RUM trade-off surface: minimizing two of the three necessarily increases the third.

Examples:
- Sorted array: R=1 (binary search is optimal), U=n (insert requires shifting), M=1. Optimal for reads only.
- Log-structured (append-only log): R=n (full scan to find any element), U=1 (pure append), M=variable (compaction reduces). Optimal for writes only.
- B+ Tree: R=log_B n (reasonable), U=log_B n (reasonable), M=1.3x (fill factor overhead). Balanced.
- LSM Tree: R=O(levels) (multiple SSTables to check), U=1 (MemTable append), M=L (multiple versions during compaction). Write-optimized.
- Hash table: R=O(1) (best for point lookup), U=O(1) (amortized), M=2x (load factor overhead). Point-lookup optimal.

Application: identify which amplification factor is most critical for your workload. Write-dominated: accept R/M to minimize U (choose LSM Tree). Read-dominated point lookups: accept M to minimize R/U (choose hash table).

*What separates good from great:* Naming the RUM conjecture and applying it to specific structures - demonstrating theoretical framework knowledge rather than ad-hoc selection. The conjecture gives a principled reason WHY you can't have everything: any optimization for one axis costs another.

**[SENIOR] Q7 - [TRADE-OFF] When would you choose a columnar store over a row store?**

Row stores: each row stored contiguously. All columns of a row are adjacent in memory. Optimal for: fetching all columns of a specific row (OLTP point lookup), updates to individual rows (UPDATE WHERE pk = x), small transactions.

Columnar stores: each column stored contiguously. All values of a column are adjacent in memory. Optimal for: aggregate queries over one column (SELECT SUM(revenue)), filtering on a subset of columns, full table scans on analytical queries, high compression (same-type adjacent values compress 5-10x).

Decision:
- OLTP (many small transactions, point lookups): row store (PostgreSQL, MySQL).
- OLAP (large scans, aggregations, few columns per query): column store (Parquet, DuckDB, ClickHouse, Redshift).
- Mixed HTAP: separate row store for writes + columnar store for analytics (replicated), or hybrid like SQL Server with columnstore indexes.

At scale: for 1B rows with 20 columns, SELECT SUM(revenue) FROM orders:
- Row store: read all 20 columns * 1B rows = 20B * avg_col_size = 200GB scanned.
- Column store: read only revenue column = 8B * 8 bytes = 64GB scanned. 3x less I/O.
- Column store with compression: revenue as delta-encoded int16: 64GB -> 16GB. 12.5x less I/O.

*What separates good from great:* The compression argument for columnar storage - same-type adjacent data compresses 5-10x better than interleaved mixed-type row data. This amplifies the I/O reduction beyond the "fewer columns read" benefit alone.

**[SENIOR] Q8 - [PRODUCTION] How does consistent hashing handle data structure selection at the distributed scale?**

At single-node scale: HashMap gives O(1) point lookup. At distributed scale (more data than one machine holds), you need to decide which machine holds which key.

Naive approach: machine = hash(key) % numMachines. Problem: when a machine is added or removed, nearly every key remaps to a different machine. For n machines and n+1 machines: ~n/n+1 fraction of all keys change machine. For 1M keys and 10 machines: adding one machine remaps 909K keys.

Consistent hashing: arrange machines on a ring of hash values (0 to 2^32). Each key maps to the next machine clockwise on the ring. Adding/removing a machine redistributes only 1/n of keys.

Data structure implication: consistent hashing is a distributed data structure selection concern:
- Each node's local storage: any structure appropriate for its key range (B+ Tree for sorted keys, hash table for point lookups).
- The routing layer: consistent hash ring determines which node. O(log n) ring lookup for n machines.
- Virtual nodes: each physical machine has many virtual nodes on the ring for balanced load distribution.

At Cassandra/DynamoDB scale: each node holds a B+ Tree (Cassandra) or LSM Tree (DynamoDB) for its key partition. The consistent hashing ring routes requests; the local structure handles them.

*What separates good from great:* Understanding that consistent hashing is the routing layer, and the data structure on each node is a separate concern. The composition is: consistent hash ring (routing, O(log n)) + per-node B+ Tree or LSM Tree (storage, O(log n)) = distributed sorted key-value store with O(log n) total operations.

**[STAFF] Q9 - [ARCHITECTURE] Design a data structure for a social network's "mutual friends" feature at 1B users.**

Problem: given two users A and B, find their mutual friends. Naive: intersection of two adjacency lists. If A has 500 friends and B has 500 friends: O(500 + 500) = O(1000). Fast for single pair.

Scale challenge: popular users may have 1M+ followers. Intersection of two 1M-follower lists = O(2M) = too slow for real-time.

Approach 1 - Sorted adjacency lists: store each user's friend list as a sorted array. Intersection = merge join: O(min(|A|, |B|)) with O(1) extra space. For A=500 friends, B=1M followers: O(500) - dominated by the smaller list. Fast.

Approach 2 - Bloom filter index: each user has a Bloom filter of their friends. Mutual friend check: for each friend f of A, query B's Bloom filter for f. O(|A| * k) where k = hash function count. 1% FPR means 1% of non-friends appear as mutual friends. For 500 friends: 5 false positives. Acceptable for pre-filter.

Approach 3 - LSM Tree with composite keys: store edges as (userId, friendId) in a sorted LSM Tree. Range scan (A, *) gives all friends of A. Sorted merge of two range scans gives mutual friends. O(|A| + |B|) with sequential I/O (fast on SSD).

Production recommendation: sorted adjacency lists on disk (sharded by userId using consistent hashing). Hot users' lists cached in RAM. For mutual friends: serve from cache if both users are hot; fallback to sorted array merge join from disk. Pre-compute mutual friend counts for the most common "celebrity vs normal user" pairs using batch processing (Spark).

*What separates good from great:* The observation that sorted adjacency lists enable O(min(|A|, |B|)) intersection via merge join - the classic "smaller set drives the join" optimization. This is why Twitter and LinkedIn use sorted adjacency lists rather than hash-based friend sets for intersection queries.

**[STAFF] Q10 - [THEORY] How does the choice between eager vs lazy deletion affect data structure performance at scale?**

Eager deletion: remove the element immediately when delete is called. B+ Tree: find leaf, remove key, possibly merge underflowing pages. O(log n) I/O.

Lazy deletion: mark the element as deleted (tombstone) without physically removing it. LSM Tree: add a tombstone record (key + delete marker) to the MemTable. The key is logically deleted but physically present until compaction. O(1) I/O (tombstone is just an append).

Trade-offs:
- Space: lazy deletion uses more space (both original data and tombstone). During compaction, both must be read and merged. Heavy-delete workloads with infrequent compaction = large space amplification.
- Read performance: eager deletion: deleted key is gone, no extra work on reads. Lazy deletion: reads must check tombstones (Bloom filter eliminates most, but not all overhead). In the worst case (many tombstones), read amplification increases.
- Write performance: eager deletion: O(log n) I/O = random write. Lazy deletion: O(1) append = sequential write. 10-100x faster.
- Compaction cost: lazy deletion defers cost to compaction. Compaction must be scheduled carefully (not during peak traffic hours). Compaction spikes cause latency spikes.

At scale: delete-heavy workloads (user data deletion for GDPR compliance, TTL expiry) can accumulate millions of tombstones in an LSM Tree. Each subsequent read must scan tombstones. Cassandra recommendation: tombstone_warn_threshold = 1000; abort queries with > 100K tombstones. Fix: schedule aggressive compaction after bulk deletes.

*What separates good from great:* Knowing Cassandra's tombstone handling limitations (query abort threshold) and the GDPR deletion pattern as a real-world example of delete-heavy workloads that stress LSM Tree tombstone management.

**[STAFF] Q11 - [ARCHITECTURE] What is write amplification in LSM Trees and how do you measure and mitigate it?**

Write amplification: the ratio of bytes physically written to storage per byte of logical data written. For LSM Trees: each byte written to the MemTable is eventually compacted multiple times as it moves from level 0 to level n.

Measurement: WA = total_bytes_written_to_disk / total_bytes_of_logical_writes.

For a typical 10-level LSM Tree with level size ratio 10: each level-k -> level-(k+1) compaction rewrites all of level k. A byte first written at level 0 is rewritten at level 1, 2, ..., n-1. Total rewrites: sum over levels = n. For n=10: WA = 10.

In practice: RocksDB typical WA = 10-30 for mixed workloads. For sequential write workloads: WA = 2-4 (most data written once, some compaction). For random write workloads: WA = 30-50 (each byte rewritten many times due to overlapping key ranges).

Mitigation:
1. Increase level size ratio: fewer levels = fewer rewrites. Trade: more space amplification per level.
2. Compression: compress each SSTable. Less bytes to write per compaction. Trade: CPU cost.
3. Tiered compaction (Cassandra STCS): compact only when enough SSTables accumulate at a level. Lower WA but higher read amplification.
4. Leveled compaction (RocksDB): each level has guaranteed no key overlap. Lower read amplification but higher WA.
5. FIFO compaction: for time-series data, just delete oldest files when full. WA = 1. Only for monotonically increasing keys with TTL.

RocksDB stat: `db.GetProperty("rocksdb.stats")` includes "Write Amplification" metric. Monitor regularly; WA > 30 = compaction strategy needs tuning.

*What separates good from great:* Knowing the specific WA metric in RocksDB (rocksdb.stats) and the trade-off between tiered (lower WA, higher read amp) vs leveled (higher WA, lower read amp) compaction strategies - and being able to state which to choose based on workload.

**[STAFF] Q12 - [SYSTEM] Design a data layer for a global time-series metric store at 1 trillion data points.**

Scale: 1 trillion data points = 10^12. At 16 bytes each = 16TB.

Architecture:

1. Write path: time-series data arrives at ~10M data points/sec globally. Partition by (metric_name, time_bucket). Each partition streams to a regional LSM Tree (like InfluxDB or Prometheus remote write). LSM Tree chosen for write throughput (no random I/O).

2. Storage tiers:
   - Hot (0-24h): in-memory skip list or MemTable. Full resolution. ~1TB/day.
   - Warm (1-30d): on-disk LSM Tree, delta-encoded timestamps, ZSTD compression. ~15TB/month.
   - Cold (30d+): columnar Parquet on object storage (S3/GCS). Highly compressed (~5-10x). ~15TB/month * 12 = 180TB/year.

3. Query path: for time range queries (fetch metric X from t_start to t_end):
   - Bloom filter: check if any data exists in the time range partition.
   - If hot: serve from MemTable / in-memory structure.
   - If warm: range scan the LSM Tree leaf files.
   - If cold: download Parquet partition, columnar decode, return aggregated result.

4. Data structure at each tier:
   - MemTable: red-black tree sorted by (metric_id, timestamp).
   - Warm LSM Tree: SSTable with composite key (metric_id, timestamp). Range scan = forward scan on sorted key.
   - Cold Parquet: columnar; scan only timestamp and value columns. Predicate pushdown eliminates unneeded row groups.

5. Aggregation: pre-compute rollups (1-min avg, 5-min avg, 1-hour avg) as separate metrics. Reduces query I/O by 60x for long-range queries.

*What separates good from great:* The tiered storage architecture (MemTable -> LSM Tree -> columnar Parquet) with different data structures at each tier matched to the access pattern (write-heavy hot tier -> LSM; read-once cold tier -> columnar) - and the rollup pre-computation as the key scalability mechanism for long-range time queries.

---

### ⚖️ Comparison Table

| Dimension | HashMap | TreeMap | B+ Tree | LSM Tree | Skip List | Bloom Filter |
|-----------|---------|---------|---------|----------|-----------|-------------|
| Point lookup | O(1) avg | O(log n) | O(log_B n) | O(log n) + bloom | O(log n) exp | O(k) |
| Range query | N/A | O(log n+k) | O(log_B n+k) | O(log n+k) | O(log n+k) | N/A |
| Insert | O(1) avg | O(log n) | O(log_B n) | O(1) amort | O(log n) exp | O(k) |
| Delete | O(1) avg | O(log n) | O(log_B n) | O(1) tombstone | O(log n) exp | N/A (standard) |
| Ordered iter | No | Yes O(n) | Yes O(n) | Yes O(n) | Yes O(n) | No |
| Concurrent | ConcHashMap | External sync | Lock coupling | MemTable lock | CAS lock-free | External sync |
| Disk-optimized | No | No | Yes | Yes | No | Memory only |
| Space | O(n) 2x | O(n) 3x | O(n) 1.3x | O(n) 1.5-3x | O(n) 2x | O(n) 0.15x |

---

### 🏛️ System Design

**Design the indexing layer for an e-commerce catalog with 1B products, 10K searches/second.**

**Requirements:** Full-text search, category filtering, price range filtering, facets (count by category, brand), 50ms P99 latency, 1B products.

**Data structure selection per operation:**
- Full-text search: inverted index (term -> sorted list of product IDs). Lookup = intersection of posting lists = O(|posting lists| * log n).
- Price range: B+ Tree index on price field. Range scan O(log n + k).
- Category filter: bitmap index. 1B products, 1000 categories = 1000 bitmaps of 1B bits each = 125MB total. AND/OR operations with SIMD = O(n/64) per filter.
- Facet counts: pre-aggregated counters per (category, brand) updated at write time. O(1) read.

**Architecture:**

```
E-Commerce Catalog Data Layer:

Product ID (uint64) -> Product Document (JSON)
  Stored in: distributed hash map (sharded by product_id)
  Read: O(1) point lookup by ID

Search indexes (inverted index per term):
  term -> sorted array of product_ids
  Stored in: Lucene/Elasticsearch (inverted index + B+ Tree)
  Read: O(log V + |results|) where V = vocabulary size

Price index:
  price -> product_id (B+ Tree, disk-backed)
  Read: subMap(minPrice, maxPrice) O(log n + k)

Category bitmap (per category):
  bit[product_id] = 1 if product in category
  Stored in: Roaring Bitmap (compressed sparse bitmap)
  AND = intersection: O(n/64) with SIMD
  Size: 1000 categories * 125MB/1B bits = 125GB total
```

> **Diagram walkthrough:** E-commerce catalog data layer with distinct data structures per operation type. Each operation has a specialized structure: full-text search uses inverted index (best for text matching), price filtering uses B+ Tree (best for range queries), category filtering uses bitmap index (best for set intersection). The key relationship: no single data structure serves all four operations optimally - system-level data structure selection means choosing multiple structures and composing them. Facet counts (pre-aggregated) are the critical optimization: computing "number of products in each category matching the search" from raw data requires scanning all results; pre-aggregated counters make this O(1). Edge case: a search returning 10M results with bitmap AND operations is still fast (O(10M/64) = O(156K) SIMD operations). But materializing those 10M product IDs into a response is O(10M) - always add LIMIT and pagination. Insight: the data layer is purpose-built with different structures per query type. This is "polyglot persistence" at the data structure level - matching the structure to the access pattern, not the tool to the problem.

---

### 📊 Diagram

```
Data Structure Selection Matrix:

         | Point  | Range  | Agg    | Write  | Disk
---------|--------|--------|--------|--------|------
HashMap  | O(1)   | N/A    | N/A    | O(1)   | No
B+ Tree  | O(lBn) | O(lBn) | scan   | O(lBn) | Yes
LSM Tree | O(lgn) | O(lgn) | scan   | O(1)   | Yes
Skip List| O(lgn) | O(lgn) | scan   | O(lgn) | No
Bloom F. | O(k)*  | N/A    | N/A    | O(k)   | No
Bitmap   | O(1)   | O(n/B) | O(n/B) | O(1)   | Poss.

(*) = approximate only
lBn = log_B(n), lgn = log(n)

Decision summary:
  Need O(1) exact lookup?  -> HashMap
  Need sorted range?       -> B+ Tree or Skip List
  Write-heavy + disk?      -> LSM Tree
  Exist check only?        -> Bloom Filter
  Bit-level set ops?       -> Bitmap
  Priority/top-k?          -> Heap
```

> **Diagram walkthrough:** Data structure selection matrix mapping five operations (point lookup, range, aggregation, write, disk-backed) to common structures. The key relationship: no structure excels at all five dimensions simultaneously - LSM Tree wins on write latency but loses on point lookup vs HashMap. B+ Tree is the "balanced generalist" (good at point lookup, range, disk) but not optimal for write-heavy workloads. The decision summary provides the primary selection rule for each access pattern. Edge case: Bloom filter is listed for point lookup but only provides approximate membership (false positives) - it is not a replacement for HashMap for exact lookup. Bloom filter is used as a PRE-FILTER before accessing the actual structure (e.g., check Bloom filter before reading from disk-backed LSM Tree). Insight: real systems compose multiple structures from this matrix - an LSM Tree WITH a Bloom filter (per SSTable) combines write-optimal storage with near-O(1) negative lookup performance. Understanding which structures complement each other is staff-level knowledge.
