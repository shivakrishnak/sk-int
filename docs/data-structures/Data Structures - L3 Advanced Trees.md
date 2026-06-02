---
layout: default
title: "Data Structures - L3 Advanced Trees"
parent: "Data Structures"
nav_order: 6
permalink: /data-structures/l3-advanced-trees/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 1 | [Red-Black Trees and Self-Balancing BSTs](#red-black-trees-and-self-balancing-bsts) | critical |
| 2 | [Trie (Prefix Tree)](#trie-prefix-tree) | high |

---

# Red-Black Trees and Self-Balancing BSTs

**Difficulty:** ★★☆

**Interview Weight:** Critical

---

### 🎯 Model Answer

**30 seconds:**
A Red-Black Tree is a self-balancing BST where each node is colored red or black, and four invariants maintain a balanced structure: the root is black, red nodes have only black children, every path from any node to its null leaves has the same number of black nodes, and null leaves are black. These rules guarantee height at most 2 log n, ensuring O(log n) worst-case for all operations. Java's TreeMap and TreeSet are backed by Red-Black Trees.

**3 minutes:**
The motivation: AVL trees guarantee strict balance (|balance factor| at most 1, height at most 1.44 log n) but pay a high rotation cost on deletions. Red-Black Trees relax the balance guarantee slightly (height at most 2 log n) in exchange for at most 2 rotations per insert and at most 3 per delete - making them faster for write-heavy mixed workloads.

The four Red-Black invariants work together to bound height. The "equal black-height" invariant (every root-to-leaf path has the same number of black nodes) means the shortest root-to-leaf path is all-black (length = black-height h_b) and the longest is alternating red-black (length = 2*h_b). So max tree height = 2 * h_b = 2 * log(n+1) - O(log n).

For interviews: you rarely need to implement a Red-Black Tree from scratch. What matters: understand WHY it is used in Java's TreeMap and C++'s std::map over AVL; know the four invariants; understand that insert/delete require recoloring and at most a fixed number of rotations; know when to use TreeMap vs HashMap vs LinkedHashMap.

**Blank Mind Recovery:**
**(1) Restate:** "Red-Black: BST with node colors where red node has only black children AND every root-to-leaf path has equal black nodes."
**(2) Height bound:** "Equal black height implies max height = 2 * black-height = 2 log n."
**(3) Why used:** "Fewer rotations per insert/delete than AVL - at most 2 insert, at most 3 delete. Preferred for general-purpose mixed workloads."
**(4) Java:** "TreeMap, TreeSet = Red-Black Tree. ConcurrentSkipListMap for concurrent sorted maps."

---

### 📘 Concept Explanation

**What it is:**
A Red-Black Tree is a BST where every node has a color attribute (RED or BLACK) satisfying four invariants that collectively bound tree height to O(log n).

**The four invariants:**

```
RB Invariants:
1. Root is BLACK
2. Null leaves (NIL sentinels) are BLACK
3. RED node's children are both BLACK
   (no two consecutive red nodes)
4. Every path from any node to
   any of its NIL leaves has the
   same number of BLACK nodes
   (equal black-height)

Example valid RB tree:
         B:7
        /     \
      R:3     R:15
      / \     /   \
    B:1  B:5 B:11 B:20
   / \ / \ / \ / \
  N  N N N N N N  N  (N = NIL, BLACK)

Black-height = 2 for every root-to-NIL path
Max height = 2 * black-height = 4
```

> **Diagram walkthrough:** A valid Red-Black Tree. B = black node, R = red node, N = NIL sentinel (black). Every path from root to NIL: root->3->1->N is 2 black nodes (root 7 and node 1); root->3->5->N is 2 black nodes (7 and 5); root->15->11->N is 2 black nodes (7 and 11). All paths equal - invariant 4 satisfied. No red node has a red child - invariant 3 satisfied. The key relationship: invariant 4 (equal black-height) guarantees the minimum path length equals the maximum path length divided by at most 2. Edge case: inserting a new node starts as RED (to avoid violating the black-height invariant); if it has a red parent, a recoloring or rotation is needed. Insight: the two invariants work together - "no consecutive red" (3) and "equal black-height" (4) jointly bound height because the black-height path gives a lower bound and the no-consecutive-red rule limits how many reds can be added between blacks.

**Why Red-Black over AVL for Java's TreeMap:**

| Property | AVL | Red-Black |
|----------|-----|-----------|
| Max height | 1.44 log n | 2 log n |
| Rotations per insert | At most 1 | At most 2 |
| Rotations per delete | O(log n) | At most 3 |
| Lookup speed | Faster | Slightly slower |
| Write overhead | Higher | Lower |
| Best use case | Read-heavy | Mixed read/write |
| Java standard library | Not included | TreeMap/TreeSet |

The decisive factor: delete. AVL delete can require O(log n) rotations cascading up to the root. Red-Black delete requires at most 3 rotations. For a general-purpose container like TreeMap with unpredictable workloads, Red-Black's bounded rotation cost is safer.

**Insert overview (not implementation):**

```java
// Use TreeMap - do NOT implement RB tree
// from scratch unless explicitly asked
TreeMap<Integer, String> map = new TreeMap<>();
map.put(7, "seven");     // O(log n)
map.put(3, "three");
map.put(15, "fifteen");

// Red-Black tree operations via TreeMap API:
map.get(7);              // O(log n) exact
map.floorKey(10);        // O(log n) <= 10
map.ceilingKey(10);      // O(log n) >= 10
map.firstKey();          // O(log n) minimum
map.lastKey();           // O(log n) maximum
map.subMap(3, 10);       // O(log n + k) range

// BAD: re-implementing sorted map manually
// GOOD: always use TreeMap for sorted maps
```

> **Code walkthrough:** Using TreeMap as the production Red-Black Tree interface. The KEY MECHANISM: Java's TreeMap exposes the full range of BST operations backed by a Red-Black Tree - no need to implement the tree directly. WHY IT MATTERS: floorKey, ceilingKey, subMap, headMap, tailMap are all O(log n) operations that only BSTs support natively. WHAT BREAKS: using HashMap when you need sorted iteration or range queries - HashMap.keySet() has no guaranteed order. TAKEAWAY: choose TreeMap when you need any ordering operations; choose HashMap when you only need O(1) exact-match lookups and order doesn't matter.

**When to use which sorted map:**

```java
// TreeMap: sorted order + range queries
TreeMap<String, Integer> wordCount
    = new TreeMap<>();
wordCount.subMap("app", "aps")
    .forEach(/* prefix search */);

// LinkedHashMap: insertion-order iteration
LinkedHashMap<String, Integer> lru
    = new LinkedHashMap<>(16, 0.75f, true) {
    protected boolean removeEldestEntry(
        Map.Entry<String, Integer> e) {
        return size() > 1000;
    }
};

// HashMap: O(1) lookups, no order needed
HashMap<String, Integer> freq
    = new HashMap<>();
```

> **Code walkthrough:** The three sorted/ordered map choices. The KEY MECHANISM: TreeMap maintains keys in compareTo() order; LinkedHashMap maintains insertion order (or access order when constructed with accessOrder=true, enabling LRU cache); HashMap maintains no order. WHY IT MATTERS: using TreeMap when you need LRU behavior (or LinkedHashMap when you need sorted range queries) is a common wrong choice that causes subtle correctness or performance bugs. WHAT BREAKS: TreeMap.subMap() is a range query that requires BST structure - if you replace TreeMap with HashMap this operation is O(n) instead of O(log n + k). TAKEAWAY: "I need sorted order" always means TreeMap; "I need insertion/access order" means LinkedHashMap; "I need fast lookups without order" means HashMap.

---

### 💻 Code Example

**Production Example: in-order range with TreeMap**

```java
// Find all employees with salary in [lo, hi]
// O(log n + k) where k = result count
NavigableMap<Integer, List<Employee>> salaryIdx
    = new TreeMap<>();

// Index by salary (multiple employees same salary)
employees.forEach(e ->
    salaryIdx.computeIfAbsent(
        e.salary, k -> new ArrayList<>()
    ).add(e)
);

// Range query: salaries between 70000 and 90000
salaryIdx.subMap(70_000, true, 90_000, true)
    .values()
    .stream()
    .flatMap(List::stream)
    .collect(Collectors.toList());
```

> **Code walkthrough:** A salary range index backed by TreeMap. The KEY MECHANISM: salaryIdx is a NavigableMap (TreeMap implements NavigableMap) - subMap(lo, inclusive, hi, inclusive) returns a view of the map for keys in [lo, hi] in O(log n + k). Multiple employees per salary are handled by mapping salary to a list. WHY IT MATTERS: this query is O(log n + k) on TreeMap vs. O(n) on HashMap; for a company with 100K employees and a narrow salary band returning 500 results, TreeMap gives 500 + 17 operations vs. 100K for HashMap. WHAT BREAKS: using a mutable Employee object as the map key - if salary changes after insertion, the index is corrupted; here salary is the key (immutable integer) and Employee is the value. TAKEAWAY: index by the field you want to range-query; use NavigableMap API (subMap, headMap, tailMap, floorKey, ceilingKey) for all ordering operations.

---

### 🎓 Answers by Seniority

**Junior / Mid-level:**
Red-Black Tree: BST where each node is red or black. Four invariants: root black, red nodes have black children only, all root-to-leaf paths have equal black-node count, null leaves are black. These guarantee height at most 2 log n. Java uses it for TreeMap/TreeSet. Prefer TreeMap over manual BST; prefer HashMap over TreeMap when ordering is not needed.

**Senior / Staff-level:**
Red-Black Trees dominate in general-purpose containers (Java TreeMap, C++ std::map, Linux kernel rbtree) because of bounded rotation cost on delete (at most 3 vs. O(log n) for AVL). The internal implementation uses a nil sentinel node for all null leaves - a single shared black sentinel eliminates null checks and simplifies rotation code. For concurrent sorted maps, ConcurrentSkipListMap (a lock-free skip list) outperforms synchronized TreeMap by orders of magnitude because skip list structural changes are localized; Red-Black rotations touch ancestor nodes requiring coordination. For write-heavy workloads, also consider LSM-Tree (RocksDB) which converts random writes to sequential appends.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Red-Black Trees are strictly balanced like AVL"**
Reality: Red-Black height can be up to 2 log n - twice the minimum. They sacrifice strict balance for lower rotation cost.

**Misconception 2: "You need to implement a Red-Black Tree in a Java interview"**
Reality: Almost never. Interviewers want to know you understand why it exists and when to use TreeMap vs other collections. Implementing from scratch is only asked at the most senior algorithm levels.

**Misconception 3: "Red-Black Trees are always faster than AVL"**
Reality: AVL trees have lower height (1.44 vs 2 log n) giving faster lookups. Red-Black wins only on write-heavy workloads where the lower rotation cost per modification outweighs the extra comparisons per lookup.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Using TreeMap when HashMap would suffice**
- Symptom: excessive GC pressure and 3-5x slower throughput vs HashMap in a lookup-heavy service
- Cause: TreeMap has O(log n) lookup vs HashMap O(1) amortized; at millions of lookups per second the constant matters
- Diagnosis: profile with JMH; compare TreeMap.get vs HashMap.get on the same keys
- Fix: if no ordering operations are used, switch to HashMap

**Failure 2: Mutable objects as TreeMap keys**
- Symptom: TreeMap.get() returns null for keys that were successfully put; inconsistent iteration order
- Cause: the key's compareTo() value changed after insertion; the key is at the wrong position
- Fix: use only immutable objects as TreeMap keys; wrap mutable objects in an immutable key record

**Failure 3: Concurrent access to TreeMap without synchronization**
- Symptom: ConcurrentModificationException or infinite loop in iterator under concurrent access
- Cause: TreeMap is not thread-safe; structural modifications invalidate iterators
- Fix: use ConcurrentSkipListMap for concurrent sorted access, or synchronize externally

---

### 🎯 Interview Deep-Dive

| Timing | Questions |
|--------|-----------|
| Opening (0-2 min) | Four invariants, height bound |
| Mid (2-8 min) | AVL vs Red-Black, Java API |
| Deep-dive (8-15 min) | Production use, scale |

**[JUNIOR] Q1 - [CONCEPT] What are the four Red-Black Tree invariants and why do they bound height?**

The four invariants:
1. The root is black.
2. All null leaf nodes (NIL sentinels) are black.
3. Red nodes have only black children (no consecutive red nodes).
4. Every path from any node to any of its null leaves has the same number of black nodes (equal black-height).

Height bound: let h_b be the black-height (number of black nodes on any root-to-leaf path - they're all equal by invariant 4). The shortest possible root-to-leaf path is all black: length h_b. The longest possible path alternates red-black: length 2*h_b (invariant 3 prevents consecutive reds). Since a complete binary tree of height h has at least 2^h - 1 nodes, and our black-height bounds contribute: n >= 2^h_b - 1, so h_b <= log(n+1). Maximum tree height = 2 * h_b <= 2 * log(n+1) = O(log n).

*What separates good from great:* Deriving the 2 log n bound from first principles - the all-black minimum path vs. alternating red-black maximum path argument - rather than just stating the result.

**[JUNIOR] Q2 - [CONCEPT] Why does Java's TreeMap use Red-Black Tree instead of AVL Tree?**

Three reasons:

1. Delete cost: AVL delete can require O(log n) rotations cascading up to root when height reductions propagate. Red-Black delete requires at most 3 rotations. For a general-purpose container with unknown workload, bounded delete cost is safer.

2. Write-heavy workloads: TreeMap is used for general-purpose sorted maps with unpredictable read/write ratios. The lower rotation overhead per modification makes Red-Black better for balanced or write-heavy workloads.

3. Implementation simplicity: the recoloring cases in Red-Black Tree reduce to a manageable set of conditions; the cascading rebalancing in AVL delete is harder to implement correctly and maintain.

AVL would be preferred for read-dominated workloads (frequent lookups, rare inserts/deletes) because the stricter balance (1.44 log n height) means fewer comparisons per search.

*What separates good from great:* Specifically quantifying the rotation difference: AVL delete O(log n) rotations vs Red-Black delete at most 3 - and explaining that this asymmetry is the decisive factor for a general-purpose container.

**[MID] Q3 - [TRADE-OFF] Compare TreeMap, HashMap, and LinkedHashMap. When do you use each?**

HashMap: O(1) average get/put/remove. No ordering. Use when: frequency counting, membership testing, cache lookups - any operation that only needs exact-match retrieval. The overwhelming default choice.

TreeMap: O(log n) get/put/remove. Keys in compareTo() sorted order. Use when: range queries (subMap, headMap, tailMap), floor/ceiling lookups, sorted iteration. 3-5x slower than HashMap for pure lookups.

LinkedHashMap: O(1) average get/put/remove. Maintains insertion order (or access order). Use when: LRU cache (override removeEldestEntry), predictable iteration order without full sorting, ordered output without sort.

ConcurrentHashMap: O(1) average, thread-safe, no ordering. Use for concurrent access without ordering needs.

ConcurrentSkipListMap: O(log n), thread-safe, sorted order. Use for concurrent sorted access (replaces synchronized TreeMap).

*What separates good from great:* Knowing ConcurrentSkipListMap as the correct concurrent alternative to TreeMap - not synchronized(new TreeMap()) which creates a global lock eliminating concurrency.

**[MID] Q4 - [SYSTEM] Design a leaderboard supporting 100K concurrent score updates and range queries.**

Requirements: fast score update per player, range query for rank, top-K retrieval, concurrent access.

Option 1 - ConcurrentSkipListMap<Integer, Set<String>> (score -> players): O(log n) insert/update, O(K log n) top-K, concurrent reads. Problem: score update requires: remove old score from old bucket, add to new bucket - two operations that must be atomic.

Option 2 - Redis Sorted Set (ZADD/ZSCORE/ZRANK/ZRANGE): atomic ZADD for score update O(log n), ZRANK for rank O(log n), ZRANGE for top-K O(K + log n). Single-threaded Redis eliminates concurrency issues.

Option 3 - Kafka + batch aggregation: stream score events to Kafka; batch aggregator (Flink/Spark Streaming) computes leaderboard every N seconds; serve reads from a read replica. Eventually consistent but handles arbitrary scale.

For 100K concurrent updates: Redis handles 100K+ operations per second (single-threaded event loop eliminates lock overhead). Sorted Set is backed by a skip list for O(log n) all operations.

*What separates good from great:* Choosing Redis Sorted Set over Java concurrent structures for this use case - Redis's atomic ZADD and native ZRANK/ZRANGE commands handle the score-update atomicity problem that Java two-operation sequences cannot solve without complex distributed locking.

**[MID] Q5 - [DEBUGGING] TreeMap iteration order is wrong. The keys are not appearing in sorted order. Diagnose.**

Primary cause: compareTo() inconsistency with equals(). TreeMap uses compareTo() for ordering; if compareTo() returns 0 for two objects that are not equal (equals() returns false), TreeMap treats them as the same key and one replaces the other.

Secondary cause: compareTo() violates the transitivity requirement. If a.compareTo(b) < 0 and b.compareTo(c) < 0 but a.compareTo(c) > 0, the sorted order is undefined and TreeMap produces wrong results.

Third cause: using a Comparator that is not consistent with equals for keys that might appear in the same sorted position.

Diagnostic:
1. Test compareTo() with the specific keys that appear out of order
2. Verify: if a.compareTo(b) == 0 then a.equals(b) should be true
3. Verify: if a.compareTo(b) < 0 and b.compareTo(c) < 0 then a.compareTo(c) < 0
4. Use Objects.compare(a, b, Comparator.naturalOrder()) and log return values

*What separates good from great:* Knowing the "consistent with equals" requirement for Comparable - TreeMap's contract requires that compareTo() == 0 implies equals() == true, and violations produce seemingly random insertion behavior.

**[SENIOR] Q6 - [PRODUCTION] How does the Linux kernel use Red-Black Trees?**

The Linux kernel uses Red-Black Trees (rbtree) extensively because they provide O(log n) worst-case with a fixed, minimal implementation in C.

Key uses:
1. CFS scheduler (Completely Fair Scheduler): each runnable process is stored in a Red-Black Tree keyed by virtual runtime. The leftmost node (minimum virtual runtime) is the next process to run. This gives fair CPU scheduling with O(log n) insert and O(1) minimum access (cached leftmost pointer).

2. Virtual memory management (vm_area_struct): each virtual memory area of a process is stored in a Red-Black Tree keyed by start address. Finding the VMA containing a given address for a page fault handler: O(log n) lookup.

3. epoll: file descriptors registered with epoll are stored in a Red-Black Tree for O(log n) registration/deregistration.

4. Ext4 file system: block extents stored in a Red-Black Tree for efficient range queries on file blocks.

The kernel implementation (lib/rbtree.c) uses a compact node structure where the color bit is stored in the lowest bit of the parent pointer (alignment guarantees the lowest bit is unused) - saving one word per node.

*What separates good from great:* Knowing the CFS scheduler detail (Red-Black Tree keyed by virtual runtime, O(1) minimum access via cached leftmost pointer) and the memory optimization (color bit packed into parent pointer).

**[SENIOR] Q7 - [ARCHITECTURE] Design a range-query-heavy time-series database index.**

Requirements: timestamp-based range queries (last 1 hour, last 24 hours, custom ranges), fast ingestion of time-ordered data, range aggregation (sum, count, average), retention policies.

Index: TreeMap<Long, DataPoint> keyed by Unix timestamp microseconds. subMap(start, end) for range queries is O(log n + k). headMap(cutoff) for retention deletion is O(1) to get the view + O(k log n) for actual deletion.

For ingestion rates above 100K/second: TreeMap contention becomes a bottleneck. Partition by time window: active write partition (last N seconds, TreeMap), sealed read-only partitions (older windows, sorted arrays). Queries span partitions: route to active tree + binary search on sealed arrays.

Compaction: merge sealed partitions into sorted arrays (SSTable pattern) for cache-efficient sequential scan and binary search. This is exactly how InfluxDB, Prometheus, and VictoriaMetrics organize time-series data.

Range aggregation: augment with subtree sum/count per node for O(log n) range sum. For sealed partitions, precompute prefix sums over the sorted arrays for O(1) range sum.

*What separates good from great:* Recognizing the partition-by-time-window pattern (active TreeMap + sealed sorted arrays) as the production approach - this is the core of TSM (Time Structured Merge) storage engines used in InfluxDB.

**[STAFF] Q8 - [ARCHITECTURE] Compare Red-Black Trees and skip lists as ordered index data structures.**

Both guarantee O(log n) operations and support range queries. They differ in implementation complexity, concurrency, and constant factors.

Red-Black Tree: deterministic O(log n). Height exactly bounded by invariants. Poor concurrency - rotations cascade, requiring locks on non-local nodes. Excellent cache performance on static data (array representation possible). Used by: Java TreeMap, C++ std::map, Linux kernel, Windows NT kernel.

Skip list: probabilistic O(log n) expected. Height bounded with high probability. Excellent concurrency - insertions and deletions modify only local nodes and their forward pointers. Slightly higher space (extra forward pointers per node, on average 2x the nodes). Used by: Java ConcurrentSkipListMap, Redis Sorted Sets, LevelDB memtable.

Concurrency winner: skip list. A lock-free skip list implementation (Harris, 2001; Java ConcurrentSkipListMap) allows non-blocking concurrent operations. A Red-Black Tree cannot be easily made lock-free because a single insert may require rotations at ancestor nodes - other threads traversing those ancestors must be synchronized.

Constant factors: Red-Black Tree has better cache performance for sequential access (array-backed trees); skip list has better cache performance for concurrent access (no false sharing between independent paths).

Decision: single-threaded sorted map = TreeMap (Red-Black, deterministic); concurrent sorted map = ConcurrentSkipListMap (skip list, lock-free); distributed sorted map = range-sharded skip lists (Redis Cluster sorted sets).

*What separates good from great:* Understanding WHY skip lists are more concurrent-friendly than Red-Black Trees - locality of structural changes - and knowing that ConcurrentSkipListMap uses a lock-free algorithm based on Mark-and-Sweep (logical deletion via mark bit before physical removal).

**[STAFF] Q9 - [THEORY] Prove that Red-Black Tree height is at most 2 log(n+1).**

Claim: a Red-Black Tree with n internal nodes has height h at most 2 * log(n+1).

Lemma: any subtree rooted at node x contains at least 2^bh(x) - 1 internal nodes, where bh(x) is the black-height of x (number of black nodes on any path from x to a null leaf, not counting x itself).

Proof by strong induction on height h(x):
- Base: h(x) = 0, x is null (NIL leaf). bh(x) = 0. Nodes = 0 = 2^0 - 1. Holds.
- Inductive step: x has children with height h(x)-1. bh(each child) >= bh(x)/2 because a child can be red (bh same as x) or black (bh = bh(x) - 1, at least bh(x)/2 for positive bh(x) >= 1). By inductive hypothesis: each child subtree has at least 2^(bh(x)/2) - 1 nodes. Total nodes in x's subtree: at least 2 * (2^(bh(x)/2) - 1) + 1 = 2^(bh(x)+1) - 1. Wait - this isn't tight. Better bound: at least 2 * 2^bh(x)/2 - 1 = 2^(bh(x)/2 + 1) - 1. Hmm.

Direct approach: n >= 2^bh(root) - 1, so bh(root) <= log(n+1). Since no path from root has more than 2*bh(root) nodes (invariant 3: no consecutive reds; invariant 4: all paths have bh(root) blacks, so at most bh(root) reds in between), h <= 2*bh(root) <= 2*log(n+1).

*What separates good from great:* Walking through the exact proof steps and recognizing the two-step argument: first bound bh by n, then bound h by bh using the no-consecutive-reds invariant.

---

### ⚖️ Comparison Table

| Property | Red-Black | AVL | Skip List | B-Tree |
|----------|-----------|-----|-----------|--------|
| Height bound | 2 log n | 1.44 log n | O(log n) expected | log_B n |
| Insert rotations | At most 2 | At most 1 | 0 (pointer updates) | 0 |
| Delete rotations | At most 3 | O(log n) | 0 | 0 |
| Concurrent support | Difficult | Very difficult | Lock-free possible | Complex |
| Space | O(n) + 1 bit | O(n) + height | O(n) avg more ptrs | O(n) |
| Disk-friendly | No | No | No | Yes |
| Java standard lib | TreeMap | No | ConcurrentSkipListMap | No |

---

### 🏛️ System Design

*(Omit: not applicable as standalone system design for Red-Black Tree specifically - it is a component within larger systems. See Senior Q7 for time-series index design using TreeMap, and Staff Q8 for detailed Red-Black vs Skip List system design comparison.)*

---

### 📊 Diagram

```
Valid Red-Black Tree insertion example:
Insert [10, 5, 15, 3, 7]:

Step 1: Insert 10 (root -> BLACK)
   B:10

Step 2: Insert 5 (red, parent black -> OK)
   B:10
   /
  R:5

Step 3: Insert 15 (red, parent black -> OK)
   B:10
   /   \
  R:5  R:15

Step 4: Insert 3 (red, parent red -> FIX)
   B:10         B:10
   /   \   =>   /   \
  R:5  R:15   B:5  B:15
  /             /
 R:3           R:3

(Recolor: parent 5 and uncle 15 both red,
 grandparent 10 is root -> just recolor
 5 and 15 to black)
```

> **Diagram walkthrough:** Building a Red-Black Tree one insertion at a time. After inserting 10 as root it is colored black (invariant 1). Inserting 5 and 15 as red children of black 10 satisfies all invariants. Inserting 3 as red child of red 5 violates invariant 3 (consecutive reds). The fix: when both parent (5) and uncle (15) are red and grandparent (10) is the root - recolor parent and uncle to black. The height remains 2 after recoloring. Key relationship: the three cases in RB insert are uncle-red (recolor), uncle-black LL/RR (single rotation), uncle-black LR/RL (double rotation). Edge case: if the grandparent was not the root after recoloring, the grandparent would temporarily become red and we'd need to check further up - this is why RB insert can cascade recolorings (but not rotations) up the tree. Insight: recolorings are cheap (no structural change); only rotations affect performance, and at most 2 rotations occur regardless of tree size.

---

---

# Trie (Prefix Tree)

**Difficulty:** ★★☆

**Interview Weight:** High

---

### 🎯 Model Answer

**30 seconds:**
A Trie (prefix tree) is a tree where each path from root to a node spells a prefix of the stored strings. Each node has up to 26 children (for lowercase letters), and insert, search, and prefix-check operations all run in O(L) where L is the string length - completely independent of the number of stored strings. Tries are the data structure behind autocomplete, spell checkers, and IP routing tables.

**3 minutes:**
A Trie trades space for speed on string operations. HashMap<String, Integer> can answer "does this word exist?" in O(L) average (hash computation), but cannot answer "give me all words starting with 'pre'" without scanning all keys. A Trie answers the prefix query in O(L + k) where k is the number of matching strings.

Each character of a string occupies one level of the trie. Searching "app" means: start at root, follow 'a' edge, follow 'p' edge, follow 'p' edge - if node exists and is marked as a word end, the word exists. No comparison with other stored strings is needed.

The space trade-off: each node may have up to 26 child references. A Trie storing 10K 5-letter words uses up to 10K * 5 * 26 * (8 bytes per reference) = 10MB. A HashMap storing the same words uses 10K * 8 bytes = 80KB. For heavy prefix querying, the space cost is justified; for pure existence checks, HashMap or a sorted array of strings with binary search is more space-efficient.

**Blank Mind Recovery:**
**(1) Restate:** "Trie: each edge represents one character; root to node spells a prefix; root to word-end node spells a stored word."
**(2) Complexity:** "All ops O(L) where L = string length. Independent of number of strings."
**(3) Use case:** "Autocomplete, prefix search, IP routing (CIDR), spell checker."
**(4) Code:** "Node has Map<Character, Node> children and boolean isWordEnd."

---

### 📘 Concept Explanation

**What it is:**
A Trie is a k-ary search tree where keys are strings, each node represents one character position, and the path from root to any node spells the prefix shared by all strings in that subtree.

**The problem it solves:**
String operations where you need to enumerate or count strings sharing a common prefix - autocomplete, spell check, IP prefix matching. Cannot be done efficiently with HashMap without scanning all keys.

**Structure:**

```
Trie storing: ["app","apple","apply","apt","bat"]

root
|-- 'a'
|   |-- 'p'
|       |-- 'p' [*]        <- "app"
|       |   |-- 'l'
|       |       |-- 'e' [*] <- "apple"
|       |       |-- 'y' [*] <- "apply"
|       |-- 't' [*]        <- "apt"
|-- 'b'
    |-- 'a'
        |-- 't' [*]        <- "bat"

[*] = isWordEnd = true
```

> **Diagram walkthrough:** A trie storing five words. Each character occupies one edge (or node). Nodes marked with [*] are word endpoints - the path from root to this node spells a complete stored word. Shared prefixes are shared nodes - "app", "apple", and "apply" all share the path root->'a'->'p'->'p'. The key relationship: all words sharing the prefix "app" are in the subtree rooted at the 'p' node at depth 3. Finding all words with prefix "app" is a DFS from that subtree root. Edge case: "app" is a word AND a prefix of "apple" - the isWordEnd flag at depth 3 handles this; without isWordEnd, "app" would not be found even though it shares the "apple" path. Insight: the trie makes all prefix operations O(L) where L is the prefix length, regardless of how many words have that prefix; a HashMap would require scanning all keys.

**Implementation:**

```java
class Trie {
    private static class Node {
        Map<Character, Node> children
            = new HashMap<>();
        boolean isWordEnd = false;
    }
    private final Node root = new Node();

    // O(L): insert word
    public void insert(String word) {
        Node curr = root;
        for (char c : word.toCharArray()) {
            curr.children.putIfAbsent(
                c, new Node());
            curr = curr.children.get(c);
        }
        curr.isWordEnd = true;
    }

    // O(L): exact search
    public boolean search(String word) {
        Node n = findNode(word);
        return n != null && n.isWordEnd;
    }

    // O(L): prefix check
    public boolean startsWith(String prefix) {
        return findNode(prefix) != null;
    }

    // O(L): navigate to end of prefix
    private Node findNode(String s) {
        Node curr = root;
        for (char c : s.toCharArray()) {
            curr = curr.children.get(c);
            if (curr == null) return null;
        }
        return curr;
    }

    // O(L + k): all words with prefix
    public List<String> withPrefix(
        String prefix
    ) {
        List<String> result = new ArrayList<>();
        Node prefixEnd = findNode(prefix);
        if (prefixEnd == null) return result;
        dfs(prefixEnd,
            new StringBuilder(prefix), result);
        return result;
    }
    private void dfs(
        Node n, StringBuilder sb,
        List<String> res
    ) {
        if (n.isWordEnd) res.add(sb.toString());
        n.children.forEach((c, child) -> {
            sb.append(c);
            dfs(child, sb, res);
            sb.deleteCharAt(sb.length() - 1);
        });
    }
}
```

> **Code walkthrough:** Complete Trie with insert, search, startsWith, and all-words-with-prefix. The KEY MECHANISM: insert traverses the trie character by character, creating nodes as needed; the last node's isWordEnd is set to true. withPrefix() uses DFS from the prefix endpoint to enumerate all words in the subtree - the StringBuilder provides O(1) append/delete to build and undo partial strings without allocation. WHY IT MATTERS: withPrefix() is O(L + k) where L is prefix length and k is total characters across all matching words - this cannot be achieved with HashMap (O(n*L) to scan all keys). WHAT BREAKS: not deleting the last character in the DFS backtrack (sb.deleteCharAt) causes the result strings to contain the characters of subsequent branches - a classic off-by-one bug in trie DFS. TAKEAWAY: always pair StringBuilder.append() with deleteCharAt() in trie DFS backtracking - the builder represents the current path from prefix root and must be exactly restored after each recursive call.

**Space optimization - compressed trie (Patricia Trie):**

```java
// BAD: Standard trie wastes nodes on long
//      single-child chains
// "interview" creates 9 single-child nodes

// GOOD: Patricia/Radix Trie compresses
//       single-child chains to one edge
//
// Storing: ["interview", "internal"]
//
// Standard trie:           Radix trie:
// i-n-t-e-r-v-i-e-w[*]    root
// i-n-t-e-r-n-a-l[*]      |-- "inter" -> node
//                                |-- "view"[*]
//                                |-- "nal"[*]
//
// Standard: 14 nodes       Radix: 3 nodes
```

> **Code walkthrough:** Patricia/Radix Trie optimization for space. The KEY MECHANISM: when a node has exactly one child, it can be merged with that child by storing the entire path as an edge label string instead of individual characters. This compresses long single-child chains from O(L) nodes to O(1) nodes. WHY IT MATTERS: for a word list where most words have long unique suffixes, standard trie space is O(total_characters); radix trie space is O(number_of_words). WHAT BREAKS: radix trie insert is more complex - inserting a word that shares a partial edge label requires splitting the edge at the split point. TAKEAWAY: standard trie for simplicity in interviews; radix/patricia trie for production (Go's net/http routing uses a radix trie for URL path matching).

---

### 💻 Code Example

**Production Example: autocomplete with frequency ranking**

```java
class AutocompleteSystem {
    private final Trie trie = new Trie();
    // Store word -> frequency
    private final Map<String, Integer> freq
        = new HashMap<>();

    public void addWord(String word, int count) {
        trie.insert(word);
        freq.merge(word, count, Integer::sum);
    }

    // Return top-K suggestions for prefix
    public List<String> suggest(
        String prefix, int k
    ) {
        List<String> candidates
            = trie.withPrefix(prefix);
        // Sort by frequency descending
        candidates.sort(
            (a, b) -> freq.getOrDefault(b, 0)
                - freq.getOrDefault(a, 0)
        );
        return candidates.subList(
            0, Math.min(k, candidates.size())
        );
    }
}
// "ap" -> ["apple" (50), "apply" (30), "apt" (10)]
```

> **Code walkthrough:** Autocomplete with frequency ranking. The KEY MECHANISM: the trie retrieves all candidate words for a prefix in O(L + k); frequency is stored separately in a HashMap; candidates are sorted by frequency for the final top-K result. WHY IT MATTERS: this separation of concerns (trie for prefix retrieval, HashMap for frequency) is simpler and more maintainable than storing frequency inside the trie nodes. WHAT BREAKS: for very large candidate sets (prefix "a" on a million-word dictionary), sorting all candidates for top-K is O(n log n) - use a min-heap of size K instead for O(n log K). TAKEAWAY: augment the trie with external frequency tracking for ranked autocomplete; for scale, store frequency at trie nodes and prune during DFS to only return the top-K without sorting all candidates.

---

### 🎓 Answers by Seniority

**Junior / Mid-level:**
Trie: tree where each path from root spells a prefix. Insert/search/prefix-check are O(L) where L = string length - independent of number of stored strings. Node has Map<Character, Node> children and boolean isWordEnd. withPrefix(p) = navigate to prefix endpoint, DFS to collect all words. Use for autocomplete, spell check, prefix queries.

**Senior / Staff-level:**
For production autocomplete at scale: standard trie per region/language partition fits in RAM (English dictionary ~500K words, average 8 chars = 4MB in standard trie). For 1M+ concurrent users, serve from read-only in-memory trie replicated across servers - no writes to shared structure. For IP routing: CIDR uses binary trie (bit-by-bit IPv4/IPv6 matching) with longest prefix match semantics - Linux kernel FIB (Forwarding Information Base) uses a multipath hash table with radix trie fallback. For typed autocomplete, precompute top-K results per prefix and cache in Redis for O(1) serve - rebuild on dictionary updates.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Trie search is O(n) where n = number of words"**
Reality: Trie search is O(L) where L = length of the search string - completely independent of how many words are stored. This is the core advantage over HashMap (which is also O(L) average but cannot do prefix queries).

**Misconception 2: "Tries are always more space-efficient than HashSets for string storage"**
Reality: Tries use O(total_characters) space, worse than a HashSet of strings (O(n*L) but with less overhead per character). Tries win on prefix queries; HashSet wins on exact-match space efficiency.

**Misconception 3: "The root node represents the first character"**
Reality: the root is empty - it has no character value. The EDGES represent characters. The first character of a word is an edge from the root to its child.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Missing isWordEnd check**
- Symptom: trie search("apple") returns true even when only "appletree" was inserted
- Cause: search checks only that the path exists, not that the last node is a word end
- Fix: return findNode(word) != null && findNode(word).isWordEnd

**Failure 2: DFS backtracking bug**
- Symptom: withPrefix() returns words with extra characters appended from sibling branches
- Cause: missing deleteCharAt after the recursive DFS call
- Fix: always pair sb.append(c) with sb.deleteCharAt(sb.length()-1) after the recursive call

**Failure 3: Memory explosion on large dictionary**
- Symptom: OutOfMemoryError when building trie from a large word list
- Cause: standard trie stores each character as a separate node with a HashMap for children - 26+ references per node
- Fix: use a character array instead of HashMap for children when alphabet is fixed (English: char[26]); or use a Patricia/Radix Trie for long-word dictionaries

---

### 🎯 Interview Deep-Dive

| Timing | Questions |
|--------|-----------|
| Opening (0-2 min) | Trie structure, O(L) complexity |
| Mid (2-8 min) | Implementation, autocomplete design |
| Deep-dive (8-15 min) | Scale, IP routing, alternatives |

**[JUNIOR] Q1 - [CONCEPT] How does a trie achieve O(L) lookup independent of dictionary size?**

A trie stores strings by character - each edge represents one character, each path from root to a node spells a prefix. To look up a word of length L, you follow exactly L edges from the root. Each step is a HashMap lookup (or array index) in the current node's children - O(1) per character.

The total work for lookup: L character steps, each O(1) = O(L). No comparison with other stored strings occurs; the trie structure physically routes you to the result.

Contrast with HashMap: HashMap computes a hash of the entire string (O(L)), then accesses one bucket (O(1)) - also O(L), but without prefix query ability.

Contrast with sorted list of strings: binary search is O(L * log n) - L characters compared at each of log n steps.

*What separates good from great:* Explaining that trie lookup is O(L) regardless of n because you follow physical edges rather than comparing against other stored strings - the structure itself encodes the routing, eliminating comparisons.

**[JUNIOR] Q2 - [CODING] Implement startsWith and search for a trie.**

```
startsWith(prefix):
1. Navigate trie following each char of prefix
2. If any char not found: return false
3. If all chars found: return true
(the node exists = the prefix exists in at
 least one stored word)

search(word):
1. Navigate trie following each char of word
2. If any char not found: return false
3. If last node reached: return node.isWordEnd
(must check isWordEnd - "apple" is stored
 but "app" may not be marked as a word)
```

> **Code walkthrough:** Pseudocode for trie's two core operations. The KEY MECHANISM: both operations traverse the same char-by-char path, but search adds one final check - isWordEnd must be true at the terminal node, because the path for "app" exists as a prefix of "apple" even when "app" was never explicitly inserted. WHY IT MATTERS: failing to check isWordEnd is the single most common trie implementation bug, causing false positives for all prefixes of stored words. WHAT BREAKS: returning true whenever the traversal completes without checking isWordEnd means startsWith and search become identical. TAKEAWAY: separate the "path exists" condition (startsWith) from the "word was inserted" condition (search = path exists AND isWordEnd = true). This is the most common interview mistake - failing to check isWordEnd.

*What separates good from great:* Immediately explaining the isWordEnd distinction and giving the counterexample - "app" is a prefix of "apple" so startsWith("app") is true after inserting "apple", but search("app") is false because only "apple" was inserted.

**[MID] Q3 - [SYSTEM] Design an autocomplete system for a mobile keyboard with 1 billion words.**

1 billion words at average 8 chars = 8 billion characters. Standard in-memory trie would use ~640GB (8B chars * 80 bytes per node) - impossible on one machine.

Optimizations:
1. Deduplicate: English has ~500K unique words. Store only unique words - trie shrinks to 4MB. Store frequencies separately.
2. Limit corpus: mobile keyboard needs only the ~100K most common words per language = 800KB trie. Fits in L2 cache.
3. Top-K pruning: during trie construction, store top-K (K=10) most frequent words at each node. Autocomplete retrieves top-K for any prefix in O(L * K) without full DFS.
4. Radix trie: compress single-child chains; reduces node count by 50-80%.

Architecture: pre-built read-only trie compiled into the app bundle. Updated via OTA update (delta compressed). User-specific personal dictionary: small supplementary trie with recency weights.

*What separates good from great:* The top-K pruning optimization (store top-K at each trie node) - this is how production autocomplete systems work, avoiding full DFS on every keystroke by storing pre-computed top results at each prefix node.

**[MID] Q4 - [TRADE-OFF] Compare Trie vs. HashMap for autocomplete. When does each win?**

HashMap wins for: exact-match queries only (O(L) hash vs O(L) trie - similar speed, HashMap uses less space); case where you just need to check "is this a valid word?"; space-critical environments.

Trie wins for: prefix queries (enumerate all words starting with X) - HashMap requires O(n*L) scan; longest prefix match (IP routing); ordered iteration over words with a given prefix; incremental character-by-character completion (each new character is one trie step from the previous result).

The decisive question: do you need prefix enumeration or longest prefix match? Yes -> trie. No -> HashMap.

Real comparison: autocomplete for search queries. User types "data s" - needs to see "data structures", "data science", "data streaming". HashMap: scan all 100K queries for prefix = 10MB of string comparisons. Trie: navigate root->'d'->'a'->'t'->'a'->' '->'s', collect subtree = 6 steps + k results.

*What separates good from great:* Quantifying the comparison - for n=100K words with prefix returning k=20 results, trie is O(L+k) vs HashMap O(n*L) = 500K comparisons. Trie is ~25000x faster for this query.

**[MID] Q5 - [CODING] How do you count the number of words in a trie that start with a given prefix?**

Option 1: DFS from prefix endpoint, count isWordEnd nodes. O(L + n_prefix) where n_prefix = all chars in matching words. Simple to implement.

Option 2: augment each trie node with a wordCount field = number of words in its subtree. Update wordCount during insert (+1) and delete (-1). Then prefix count = prefixEndNode.wordCount. O(L) query.

```java
// Augmented insert
void insert(String word) {
    Node curr = root;
    for (char c : word.toCharArray()) {
        curr.children.putIfAbsent(c, new Node());
        curr = curr.children.get(c);
        curr.wordCount++; // count in subtree
    }
    curr.isWordEnd = true;
}

int countWithPrefix(String prefix) {
    Node n = findNode(prefix);
    return n == null ? 0 : n.wordCount;
}
```

> **Code walkthrough:** Augmented trie with wordCount at each node. The KEY MECHANISM: every insert increments wordCount at every node along the insertion path, so each node accumulates the total count of words passing through it. WHY IT MATTERS: countWithPrefix becomes O(L) - traverse to the prefix endpoint and read the stored count, no DFS needed. WHAT BREAKS: forgetting to decrement wordCount during delete causes counts to drift upward over time, returning inflated prefix counts. TAKEAWAY: augmentation is the general pattern - store any aggregate at each node during insert/delete to answer O(L) subtree aggregate queries later.

Augmentation enables O(L) prefix count vs O(L + k) DFS. For k large (many matching words), augmentation wins.

*What separates good from great:* The augmentation pattern - adding wordCount (or wordsBelowCount) to each node so prefix count becomes O(L) rather than O(L + k). This generalizes: any aggregate over a subtree (count, sum, max frequency) can be computed in O(L) if augmented at insert time.

**[SENIOR] Q6 - [PRODUCTION] How does IP routing use tries?**

IP routing tables store CIDR prefixes (e.g., 192.168.1.0/24) and look up the longest matching prefix for a destination IP address.

Binary trie for IPv4: 32 levels (one per bit). Each internal node has two children: 0-bit child and 1-bit child. Each leaf (or internal node) may store a route entry. Routing lookup: traverse 32 bits of the destination IP from MSB to LSB; at each step, follow the 0 or 1 edge. Record the last route entry seen. After 32 bits, the recorded entry is the longest prefix match.

Longest prefix match: critical for routing - more specific routes (longer prefix = more bits fixed) take priority over general routes. "192.168.1.0/24 -> router A" overrides "192.168.0.0/16 -> router B" for addresses matching the /24 prefix.

Scale: internet routing table has ~900K IPv4 prefixes + ~200K IPv6 prefixes. Binary trie for 900K prefixes: ~900K * 32 = ~29M nodes at worst. Optimized: Patricia Trie (compressed) reduces to ~2M nodes.

Hardware: modern routers use TCAM (Ternary Content-Addressable Memory) for O(1) lookup - special hardware that can match all prefixes in parallel. Software fallback uses radix trie.

*What separates good from great:* Explaining longest prefix match semantics and why it requires a trie (not HashMap - you can't find the longest matching prefix in O(1) with HashMap), and mentioning TCAM as the hardware implementation that achieves O(1) routing.

**[SENIOR] Q7 - [DEBUGGING] Trie prefix search returns extra words not matching the prefix. Diagnose.**

Primary cause: DFS backtracking bug. The StringBuilder used to accumulate the current path is not restored after returning from a recursive call. Siblings get the characters from previous branches appended to their words.

Diagnostic: insert only two words with a common prefix ("app", "apt"), call withPrefix("ap"), verify output. Expected: ["app", "apt"]. If you get ["app", "apppt"] or similar, the backtracking is broken.

Fix:
```java
void dfs(Node n, StringBuilder sb, ...) {
    if (n.isWordEnd) res.add(sb.toString());
    n.children.forEach((c, child) -> {
        sb.append(c);
        dfs(child, sb, res);
        sb.deleteCharAt(sb.length() - 1); // MUST
    });
}
```

> **Code walkthrough:** DFS with correct StringBuilder backtracking. The KEY MECHANISM: sb.append(c) adds the character before recursing; sb.deleteCharAt(sb.length()-1) removes it on return, restoring the path to its pre-recursion state before visiting the next sibling. WHY IT MATTERS: without deleteCharAt, every sibling node inherits all characters from previous siblings appended to its path, producing corrupted word strings. WHAT BREAKS: using sb.setLength(sb.length()-1) instead of deleteCharAt achieves the same effect and is equally correct. TAKEAWAY: append/recurse/delete is the canonical backtracking pattern in any DFS that builds a path string - the delete is the undo step.

Secondary cause: DFS starting from root instead of prefix endpoint. All words are returned regardless of the prefix.

Tertiary cause: findNode() returning the root when the prefix is empty and the code does not handle the empty prefix case.

*What separates good from great:* Immediately identifying the StringBuilder backtracking pattern and knowing the exact fix (deleteCharAt at the same level as append) without needing to trace through the algorithm.

**[STAFF] Q8 - [ARCHITECTURE] Design a spell-checker and word-suggestion system for a production document editor.**

Requirements: detect misspelled words (real-time, as you type), suggest corrections (top-5 closest words), handle 300K-word dictionary, sub-10ms response time.

Dictionary loading: standard trie on 300K words, average 8 chars = 2.4M nodes. ~192MB in-memory. Acceptable for a desktop app; too large for mobile - use a bloom filter for existence check (O(L) with very low false positive rate) and trie only for suggestions.

Spell check: exact trie search for the typed word. O(L) - instant.

Suggestion generation: BK-tree (Burkhard-Keller tree) on the same dictionary, keyed by edit distance. BK-tree node is (word, children keyed by edit distance from parent). For a misspelled word with tolerance=2: BK-tree prunes most of the dictionary, returning only words within edit distance 2. O(D^tolerance * log n) where D is alphabet size.

Alternative: trie with DFS + edit distance bound. DFS through trie, pruning branches when minimum possible edit distance to prefix exceeds tolerance. O(L * 26^tolerance) in worst case but typically much faster for small tolerance (1-2).

Ranking suggestions: by edit distance first, then by word frequency (from a frequency corpus). Frequency data stored separately in HashMap<String, Integer>.

Real-world: iOS/Android keyboards use n-gram language models for contextual correction (not just edit distance). Google Docs uses server-side neural spell check for sentence-level corrections.

*What separates good from great:* Knowing BK-trees as the production data structure for edit-distance-bounded word lookup, and knowing that production spell checkers use language models (n-gram or neural) for context-aware correction rather than pure edit distance.

**[STAFF] Q9 - [SCALE] How would you handle a trie with 1 billion strings distributed across servers?**

1 billion strings at 10 chars average = 10B characters. Standard in-memory trie: ~800GB. Must be distributed.

Partition strategy: by first K characters. All strings starting with "a" go to server cluster A, "b" to B, etc. With K=2 and 26^2 = 676 buckets, average shard size = 1.5M strings - fits in RAM per shard.

Consistent hashing: route prefix "app..." to the shard owning "ap" prefix bucket. Each prefix query fans out to only one shard (for well-formed prefix queries starting from the beginning of words).

Cross-shard prefix queries: query hits one shard for the full prefix match. Fan-out is only needed for autocomplete returning results from multiple subtrees (not needed if prefix fully determines the shard).

Replication: each shard replicated 3x for availability. Read queries route to any replica; writes use strong consistency (Raft).

Top-K served from: each shard pre-computes top-K for its partition; a router-level aggregator merges top-K results from relevant shards and re-ranks.

Real-world: Elasticsearch uses inverted index (not trie) for full-text search at this scale; Redis Cluster uses sorted sets per prefix for type-ahead; Google Suggest uses precomputed n-gram models with MapReduce-built tries for static autocomplete vocabularies.

*What separates good from great:* Recognizing that at 1 billion strings, Elasticsearch's inverted index architecture is typically more practical than a distributed trie - inverted indexes scale horizontally with Lucene shards while distributed tries require complex prefix routing.

---

### ⚖️ Comparison Table

| Property | Trie | HashMap<String,V> | Sorted Array | BST (TreeMap) |
|----------|------|-------------------|--------------|---------------|
| Exact search | O(L) | O(L) avg | O(L log n) | O(L log n) |
| Prefix search | O(L + k) | O(n*L) | O(log n + k) | O(log n + k) |
| Longest prefix | O(L) | Not possible | O(log n) | O(log n) |
| Insert | O(L) | O(L) avg | O(n) | O(L log n) |
| Space | O(alphabet * total_chars) | O(n*L) | O(n*L) | O(n*L) |
| Best for | Prefix ops, autocomplete | Exact match | Sorted iteration | Range queries |

---

### 🏛️ System Design

*(Omit: not applicable as standalone system design here - trie is a component. See Staff Q3 for autocomplete system design at scale, and Staff Q8 for the complete spell-checker system design.)*

---

### 📊 Diagram

```
Trie insert sequence for "app","apt","bat":

After "app":         After "apt":         After "bat":
root               root               root
 |a                 |a                 |a  |b
 p                  p                  p   a
 |p[*]              |p[*] |t[*]        p[*] t[*]
                    (app) (apt)    |t[*]
                                 (app,apt,bat)

Prefix query "ap" -> subtree rooted at p(depth=2)
DFS yields: "app", "apt" in O(L + k) = O(5)
HashMap scan for "ap" prefix: O(n*L) = O(3*3)=O(9)
(worse at scale: 1M words -> 1M comparisons)
```

> **Diagram walkthrough:** Incremental trie construction for three words. After each insert, the shared prefix "a" is reused rather than duplicated. After all three words, the node at path root->'a'->'p' branches into two children: 'p' (completing "app") and 't' (completing "apt"). The key relationship: all strings sharing a prefix share the same trie path up to the point of divergence, making prefix enumeration a simple DFS over the subtree. Edge case: inserting "a" as a word after "app" requires only setting isWordEnd=true on the existing 'a' node at depth 1 - no new nodes needed. Insight: the trie's structural advantage for prefix queries is visible in the complexity comparison at the bottom - for large dictionaries the O(L + k) vs O(n*L) difference is orders of magnitude.
