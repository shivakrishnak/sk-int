---
layout: default
title: "Data Structures - L5 Architecture"
parent: "Data Structures"
nav_order: 14
permalink: /data-structures/l5-architecture/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 1 | [Custom Data Structure Design for Production Systems](#custom-data-structure-design-for-production-systems) | high |

---

# Custom Data Structure Design for Production Systems

**Difficulty:** ★★★

**Interview Weight:** High

---

### 🎯 Model Answer

**30 seconds:**
Designing a custom data structure for production means solving a specific access pattern problem that no off-the-shelf structure handles optimally. The process: (1) characterize the dominant operations and their frequencies; (2) identify which standard structure has the closest fit; (3) augment or compose structures to cover the gap; (4) analyze time/space trade-offs and validate with benchmarks. The classic examples: LRU cache (HashMap + doubly linked list), median stream (two heaps), time-range rate limiter (sliding window with ring buffer), and interval tree (BST augmented with max-interval endpoint).

**3 minutes:**
The engineering discipline of custom data structure design follows a systematic process:

Phase 1 - Access pattern analysis: identify the set of operations the structure must support, their frequency ratio (how often each is called), and their latency requirements.

Phase 2 - Standard structure fit: which existing structure handles the most critical operation best? A HashMap is O(1) for point lookup. A heap is O(log n) for priority access. A sorted array is optimal for static range queries.

Phase 3 - Gap identification: what operations does the standard structure handle poorly? HashMap: no ordering (range queries O(n)). Heap: no arbitrary delete (O(n)). Sorted array: O(n) insert.

Phase 4 - Augmentation or composition: to fill the gap, either augment an existing structure (add extra fields at each node, e.g., subtree max for interval trees) or compose two structures (HashMap + doubly linked list for LRU, two heaps for median stream).

Phase 5 - Invariant definition: define the invariant that keeps the two structures synchronized. LRU invariant: every key in the HashMap has a corresponding node in the doubly linked list; the list maintains LRU order. Two-heap median invariant: max-heap (lower half) and min-heap (upper half) differ in size by at most 1.

Phase 6 - Validation: prove each operation maintains the invariant. Then benchmark with realistic access patterns.

**Blank Mind Recovery:**
**(1) Process:** "Identify operations + frequencies -> pick closest standard structure -> identify gap -> augment or compose -> define invariant -> validate + benchmark."
**(2) LRU:** "HashMap (O(1) lookup) + doubly linked list (O(1) eviction). Map stores node reference for O(1) move-to-front."
**(3) Median stream:** "Max-heap (lower half) + min-heap (upper half). Invariant: size difference <= 1."
**(4) Key principle:** "Custom structures are composed from primitives. The invariant between primitives is the hard part."

---

### 📘 Concept Explanation

**What it is:**
Custom data structure design is the engineering practice of building a structure to serve a specific combination of operations that no off-the-shelf structure handles optimally. It relies on augmentation (adding state to existing nodes) and composition (combining multiple structures sharing an invariant).

**The problem it solves:**
Real systems have complex access patterns that span multiple structure types: both O(1) lookup AND ordered iteration AND O(1) eviction. No single structure handles all three. Custom design composes structures to meet all requirements.

**LRU Cache: the canonical composition example:**

```
Operations needed:
  get(key) -> value: O(1)
  put(key, value): O(1), evict LRU item if at capacity

HashMap alone: O(1) get/put, but no ordering
  -> cannot find LRU item without O(n) scan

Doubly Linked List alone: O(1) add/remove by node reference,
  ordering maintained by position (MRU at head, LRU at tail)
  -> cannot find item by key without O(n) scan

Composition:
  HashMap<key, ListNode*>: O(1) lookup by key
  DoublyLinkedList: MRU at head, LRU at tail
  HashMap value stores DIRECT REFERENCE to list node

Invariant:
  1. Every key in HashMap has exactly one ListNode in list
  2. List order = recency order (MRU head, LRU tail)
  3. ListNode contains key + value

Operations:
  get(key):
    1. HashMap.get(key) -> node: O(1)
    2. Move node to list head: O(1) (pointer rearrangement)
    3. Return node.value: O(1)
    Total: O(1)

  put(key, value):
    1. If key exists: update node.value, move to head: O(1)
    2. If at capacity: remove tail from list + HashMap: O(1)
    3. Create new node, add to list head + HashMap: O(1)
    Total: O(1)
```

> **Diagram walkthrough:** LRU Cache implemented as HashMap + doubly linked list composition. The key relationship: the HashMap stores node REFERENCES (pointers to doubly-linked list nodes), not just values. This is the crucial detail that enables O(1) move-to-front: when a key is accessed, the HashMap lookup gives the node reference in O(1), and rearranging the doubly linked list pointers is O(1) (no traversal needed). Without storing node references, move-to-front would require O(n) list traversal. Edge case: when put() causes eviction, the LRU tail node's key must be removed from the HashMap. The ListNode must store the key (not just the value) so the HashMap can be updated during eviction. Insight: the composition works because each structure handles one dimension: HashMap handles O(1) key-based access; DoublyLinkedList handles O(1) order-preserving add/remove. The shared state (node references in the HashMap) is what couples them into a single coherent structure.

**Two-heap median stream:**

```
Operations needed:
  addNum(n): insert a number into the stream
  findMedian() -> double: return current median

Sorted array: O(n) insert, O(1) median
Min-heap alone: O(log n) insert, O(1) min only
  -> no O(1) median access

Composition: two heaps
  maxHeap: stores lower half of numbers (max at top)
  minHeap: stores upper half of numbers (min at top)

Invariant:
  1. |maxHeap.size - minHeap.size| <= 1
  2. maxHeap.top() <= minHeap.top()
     (all lower-half values <= all upper-half values)

addNum(n):
  if maxHeap.empty or n <= maxHeap.top():
    maxHeap.offer(n)
  else:
    minHeap.offer(n)
  // Rebalance: ensure invariant (1) holds
  if maxHeap.size > minHeap.size + 1:
    minHeap.offer(maxHeap.poll())
  else if minHeap.size > maxHeap.size + 1:
    maxHeap.offer(minHeap.poll())

findMedian():
  if maxHeap.size == minHeap.size:
    return (maxHeap.top() + minHeap.top()) / 2.0
  else if maxHeap.size > minHeap.size:
    return maxHeap.top()
  else:
    return minHeap.top()
// All operations O(log n)
```

> **Diagram walkthrough:** Median stream using two heaps. The invariant has two components: (1) size balance (neither heap is more than 1 element larger than the other) ensures the median is accessible at the top of one or both heaps; (2) order invariant (max of lower half <= min of upper half) ensures the two halves are correctly partitioned. The key relationship: when a new number is added that breaks the order invariant (n > maxHeap.top() should go to minHeap), it is routed to minHeap; after routing, if the size invariant is violated, the top element of the larger heap is moved to the smaller heap. Each addNum takes O(log n) for heap insertion/removal. Edge case: duplicate elements are handled naturally by the heaps (both max-heap and min-heap support duplicates). The invariant ensures correctness regardless of duplicates. Insight: the two-heap approach works because medians are a "boundary element" problem - you need the largest element of the smaller half. Heaps are optimal for this: max-heap gives the largest element of the smaller half in O(1).

**Interval tree (augmented BST):**

```
Operations needed:
  insert(interval): add interval [lo, hi]
  queryOverlap(point): find all intervals containing point
  queryOverlap(interval): find all overlapping intervals

Sorted array by lo: O(log n) lower bound, but
  -> to find all overlapping: must scan many intervals

Augmented BST: standard BST on interval.lo as key,
  augmented with maxHigh at each node =
  max of all hi values in this subtree.

Invariant:
  node.maxHigh = max(node.hi, node.left.maxHigh,
                     node.right.maxHigh)

queryOverlap(point):
  if root.lo <= point <= root.hi: add root to results
  if left child exists AND left.maxHigh >= point:
    recurse left (left subtree may contain overlap)
  if right child exists AND right.lo <= point:
    recurse right (right subtree may contain overlap)

Why maxHigh enables pruning:
  If left.maxHigh < point: no interval in left subtree
  can contain point (all hi values < point). Skip entire
  left subtree -> O(log n + k) for k results.
```

> **Diagram walkthrough:** Interval tree as an augmented BST. Each node stores the maximum high-endpoint (maxHigh) of all intervals in its subtree. The key relationship: maxHigh enables subtree pruning - if a subtree's maximum hi is less than the query point, no interval in that subtree can contain the point, allowing O(1) subtree elimination. Without this augmentation, every interval query requires O(n) full BST traversal. The augmentation invariant (maxHigh = max of node.hi, left.maxHigh, right.maxHigh) is maintained on insert by updating ancestors on the path from inserted node to root (O(log n) updates). Edge case: when an interval is deleted, maxHigh must be recomputed along the ancestor path. If the deleted interval had the maximum hi in its subtree, the parent's maxHigh may decrease. Insight: augmentation is the key technique for custom data structures built on BSTs - store per-subtree aggregates (max, sum, count) at each node. The augmented field enables O(log n) queries that would otherwise require O(n) scans.

---

### 💻 Code Example

**LRU Cache - complete production implementation:**

```java
class LRUCache {
    private final int capacity;
    private final Map<Integer, Node> map;
    // Sentinel head/tail for boundary handling
    private final Node head, tail;

    private static class Node {
        int key, val;
        Node prev, next;
        Node(int k, int v) { key = k; val = v; }
    }

    public LRUCache(int capacity) {
        this.capacity = capacity;
        this.map = new HashMap<>(capacity * 2);
        head = new Node(0, 0); // MRU sentinel
        tail = new Node(0, 0); // LRU sentinel
        head.next = tail;
        tail.prev = head;
    }

    public int get(int key) {
        Node n = map.get(key);
        if (n == null) return -1;
        moveToFront(n);    // update recency
        return n.val;
    }

    public void put(int key, int value) {
        Node n = map.get(key);
        if (n != null) {
            n.val = value;
            moveToFront(n);
            return;
        }
        if (map.size() == capacity) {
            // Evict LRU: node just before tail sentinel
            Node lru = tail.prev;
            remove(lru);
            map.remove(lru.key);
        }
        Node newNode = new Node(key, value);
        addToFront(newNode);
        map.put(key, newNode);
    }

    private void moveToFront(Node n) {
        remove(n);
        addToFront(n);
    }

    private void remove(Node n) {
        n.prev.next = n.next;
        n.next.prev = n.prev;
    }

    private void addToFront(Node n) {
        n.next = head.next;
        n.prev = head;
        head.next.prev = n;
        head.next = n;
    }
}
// Time: O(1) all operations
// Space: O(capacity)
// Sentinel nodes eliminate null checks for head/tail edge cases
```

> **Code walkthrough:** Complete LRU Cache implementation with sentinel nodes. The KEY MECHANISM: sentinel head and tail nodes eliminate boundary condition checks - addToFront and remove operations work identically for all nodes without special-casing the first or last node. The map stores Node references (not just values) enabling O(1) node removal via the doubly linked list pointer manipulation. WHY IT MATTERS: Java's LinkedHashMap(initialCapacity, loadFactor, true) implements LRU with accessOrder=true - in production, use LinkedHashMap rather than reimplementing. But understanding the underlying composition is required to extend it (e.g., add TTL expiry, add statistics, or make it concurrent). WHAT BREAKS: forgetting to update the map when the LRU node is evicted (map.remove(lru.key)) creates a memory leak where the map grows unboundedly while the list is correctly bounded. TAKEAWAY: sentinel nodes are the implementation pattern for doubly linked list operations - they make all cases look the same, eliminating the most common source of off-by-one bugs.

---

### 🎓 Answers by Seniority

**Junior / Mid-level:**
Custom data structures combine standard structures to support multiple operations efficiently. LRU cache = HashMap (O(1) lookup) + doubly linked list (O(1) ordered eviction). Median stream = max-heap (lower half) + min-heap (upper half). The pattern: identify the operations you need, find which standard structure serves each, compose them with a shared invariant. The invariant is the contract between the two structures and must be maintained after every operation.

**Senior / Staff-level:**
At production scale, custom data structure design includes thread safety, serialization, memory layout, and observability. Thread-safe LRU: either global lock (simple, limits throughput), segmented locking (divide into N segments, each independently locked), or lock-free (compare-and-swap, extremely complex). Caffeine (Java) uses W-TinyLFU, a sophisticated approximate LRU with admission filter and frequency sketch - measurably better than pure LRU for real workloads. At staff level: know that custom data structures accumulate operational debt - every custom structure requires custom debugging, custom serialization, custom monitoring. The decision to build custom vs use an existing solution must account for this lifecycle cost. An off-the-shelf structure that is 20% less efficient but has 10 years of production hardening is often the correct choice.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Composition is just using two data structures"**
Reality: composition requires a shared invariant that MUST be maintained after every operation. Two structures that are used together but not kept in sync via an invariant are not a composed data structure - they are two separate structures. The invariant definition and the proof that every operation maintains it is the engineering work.

**Misconception 2: "Augmentation adds a small constant-time overhead"**
Reality: augmentation adds O(path length) overhead to every update. For a BST augmented with subtree max: every insert must update maxHigh on the O(log n) ancestor path. For a self-balancing BST, rotations must also update maxHigh of the rotated nodes. The augmentation overhead equals the path length, which is O(log n) for balanced BSTs.

**Misconception 3: "A custom data structure is always more efficient"**
Reality: custom structures add implementation complexity, debugging difficulty, and maintenance burden. Use a custom structure only when profiling proves an existing structure is the bottleneck. The simplest correct implementation is almost always preferable to a clever custom structure.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Invariant violation in composed data structure causes incorrect results**
- Symptom: LRU cache evicts wrong entry; median is incorrect; interval query returns wrong results
- Cause: one operation updates one structure but fails to update the other, or updates in wrong order
- Diagnosis: add invariant assertion after every operation (test-only): in LRU, assert every HashMap key corresponds to exactly one list node and vice versa; in median stream, assert maxHeap.top() <= minHeap.top()
- Fix: make invariant maintenance explicit and atomic; test every operation with edge cases (empty, single element, capacity boundary)

**Failure 2: Memory leak in composed structure during delete operation**
- Symptom: memory grows continuously; heap usage increases even with constant active element count
- Cause: delete removes from one structure but not the other; stale entries accumulate in the HashMap
- Diagnosis: add element count assertions: map.size() must equal list.size() after every operation
- Fix: identify all paths through delete that modify one structure and ensure the other is also updated; use a code review checklist: "does this path update ALL structures?"

**Failure 3: Race condition in concurrent composed structure**
- Symptom: under concurrent access, LRU cache returns null for keys that exist; median is wrong
- Cause: get() reads from HashMap and moves node to front as two non-atomic operations; another thread can evict the same node between the HashMap.get() and moveToFront()
- Diagnosis: run with Helgrind (Valgrind) or Java Thread Sanitizer; look for lock order violations
- Fix: use a single lock protecting both structures; or use Caffeine's lock-free implementation; never access composed structures from multiple threads without explicit synchronization

---

### 🎯 Interview Deep-Dive

| Timing | Questions |
|--------|-----------|
| Opening (0-3 min) | LRU, basic composition |
| Mid (3-10 min) | Custom design problems |
| Deep-dive (10-20 min) | Production, invariants |

**[JUNIOR] Q1 - [CODING] Design an LRU Cache with O(1) get and put.**

Use HashMap + doubly linked list composition (described in Concept Explanation). Key implementation points:

1. HashMap maps key -> ListNode (the node reference, not just the value).
2. ListNode stores both key AND value (key needed for eviction: when tail node is evicted, its key must be removed from HashMap).
3. Use sentinel head/tail nodes to simplify boundary cases.
4. put() with existing key: update value, move to front (don't evict, don't add duplicate).
5. put() with new key at capacity: evict tail (remove from list AND map), then add new node to front AND map.

Invariant: every key in map has exactly one node in list; every node in list has exactly one key in map.

*What separates good from great:* Remembering that ListNode must store the KEY (not just value) so that eviction can update the HashMap. A HashMap<key, ListNode> where ListNode only stores value can't clean up the HashMap on eviction without an O(n) map scan.

**[JUNIOR] Q2 - [CODING] Find the median from a data stream.**

Use two heaps: maxHeap for the lower half, minHeap for the upper half. Invariant: |maxHeap.size - minHeap.size| <= 1. maxHeap.top() <= minHeap.top().

addNum(n): decide which heap to add to based on maxHeap.top(). Then rebalance: if either heap exceeds the other by more than 1, move one element.

findMedian(): if sizes equal -> (maxHeap.top() + minHeap.top()) / 2.0. If maxHeap larger -> maxHeap.top(). If minHeap larger -> minHeap.top().

All operations O(log n). Space O(n).

*What separates good from great:* The rebalancing step after every add - explaining WHY it's needed (to maintain the size invariant) and showing the direction is always "move top of larger heap to smaller heap."

**[MID] Q3 - [CODING] Design a data structure that supports insert, delete, and getRandom in O(1).**

Requirements: O(1) insert, O(1) delete, O(1) getRandom (each element equally likely).

Problem: getRandom requires O(1) random access by index -> array. Delete from arbitrary position in array -> O(n) (must shift). Delete by key from array -> O(n) (must find index).

Composition: ArrayList + HashMap.
- ArrayList stores elements (for O(1) getRandom via random index).
- HashMap maps element -> index in ArrayList (for O(1) element lookup).

Insert(x): append to ArrayList, add index to HashMap. O(1).
Delete(x): find index in HashMap: O(1). Swap x with last element in ArrayList: O(1). Update HashMap for swapped element's new index: O(1). Remove last element from ArrayList: O(1). Remove x from HashMap: O(1). Total: O(1).
getRandom(): Random.nextInt(size) -> ArrayList.get(random index): O(1).

Invariant: HashMap[elem] == index such that ArrayList[index] == elem.

*What separates good from great:* The delete trick: swap with last element before removing. This makes delete O(1) by avoiding the "shift all elements" problem, and the HashMap is updated to reflect the swapped element's new index.

**[MID] Q4 - [CODING] Design an interval tree to find all intervals overlapping a query interval.**

Use an augmented BST where each node stores an interval [lo, hi] and a maxHigh field = maximum hi of all intervals in its subtree.

Insert([lo, hi]): insert into BST keyed on lo. Update maxHigh on path from inserted node to root (or use recursive insert that propagates maxHigh upward). O(log n).

queryOverlap([qlo, qhi]):
  if current interval overlaps [qlo, qhi] (not to the left and not to the right): add to results.
  Go left if left child exists AND left.maxHigh >= qlo (left subtree might overlap).
  Go right if right child exists AND current.lo <= qhi (right subtree lo values might overlap).

Expected O(log n + k) for k results with balanced BST.

*What separates good from great:* Explaining the pruning condition: left.maxHigh < qlo means ALL intervals in the left subtree end before qlo, so none can overlap a query starting at qlo. This is why the maxHigh augmentation enables O(log n) tree pruning.

**[MID] Q5 - [TRADE-OFF] When should you build a custom data structure vs use an existing library?**

Use an existing library when:
1. The access pattern matches a well-known structure (LRU -> Caffeine, sorted map -> TreeMap, priority queue -> PriorityQueue).
2. The existing library has been production-tested at scale (Caffeine has years of production use at Netflix, GitHub, etc.).
3. The performance gap is < 20%. Building and maintaining a custom structure for a 10% speedup rarely justifies the engineering cost.
4. The team must maintain the system long-term. Custom structures require custom debugging.

Build custom when:
1. The access pattern is genuinely novel (no existing structure handles it).
2. Profiling proves the existing structure is a performance bottleneck.
3. The custom structure will be reused across many systems (justify the investment).
4. Memory is severely constrained (custom structures can be more memory-efficient by packing fields).

Default: start with the simplest existing solution. Profile. Optimize only when profiling proves necessity.

*What separates good from great:* Quantifying the decision: build custom only if profiling shows > 2x performance improvement that is achievable and the structure will be used frequently enough to justify the maintenance burden.

**[SENIOR] Q6 - [PRODUCTION] Design a thread-safe O(1) LRU cache for a high-traffic service.**

Problem: the naive LRU (HashMap + doubly linked list with a single lock) serializes all get() and put() calls. At 1M requests/sec, a single-lock LRU becomes a bottleneck.

Solutions in order of complexity:

1. Read-mostly: ConcurrentHashMap for map, lock on list operations only. Problem: get() still needs to move-to-front, which requires the list lock. Not truly concurrent reads.

2. Segmented locking: partition the LRU into N shards by key hash. Each shard has its own HashMap + list + lock. get() and put() for key k operate on shard k % N. N shards = N-way parallelism. Simple, effective for even key distribution.

3. W-TinyLFU (Caffeine): uses a frequency sketch (Count-Min Sketch) + admission filter + segmented LRU. Approximate LRU - eviction decisions are probabilistic, not exactly LRU. Lock-free window cache + protected/probationary segments. 10x higher throughput than single-lock LRU. Production recommendation for Java.

4. CLOCK algorithm: approximate LRU with O(1) eviction using a "clock hand" that scans for entries with access bit=0. Simpler than true LRU, similar hit rate, avoids list manipulation.

*What separates good from great:* Recommending Caffeine with W-TinyLFU for production Java (Guava's CacheBuilder wraps Caffeine internally since Guava 23.6+) - demonstrating knowledge of current production tools rather than just describing the theoretical design.

**[SENIOR] Q7 - [ARCHITECTURE] Design a sliding window rate limiter data structure.**

Operations: allow(requestId, timestamp) -> bool: return true if the request is within the rate limit; false otherwise.

Requirement: allow N requests per W seconds sliding window.

Naive: maintain a list of all timestamps within the last W seconds. allow() adds timestamp, removes old timestamps, checks count. O(n) per call where n is requests per window. Not O(1).

Ring buffer approach:
- Bucket size: divide W into B buckets (e.g., W=60s, B=60, each bucket=1s).
- Ring buffer of B counters: count[bucket_index].
- Current bucket: timestamp / bucket_size % B.
- allow(ts): increment current bucket's counter. Remove stale buckets (those older than W). If total count <= N: allow. Else: deny.
- Total count: sum of all B counters. O(B) per call. For B=60: O(60) = acceptable.

Sliding window log (exact): maintain a sorted deque of timestamps. allow(ts): add ts to deque, remove all timestamps older than ts-W. If deque.size() <= N: allow. O(1) amortized (each timestamp added once, removed once).

Token bucket (production): counter + timestamp of last refill. allow(ts): tokens_available = min(N, tokens + (ts - last_refill) * rate). If tokens_available >= 1: decrement, allow. Else: deny. O(1). Used by most production rate limiters (Nginx, AWS API Gateway, Redis INCR+EXPIRE).

*What separates good from great:* Presenting three approaches with different trade-offs (exact vs approximate, memory vs computation) and naming the token bucket as the production standard - demonstrating awareness of how the theoretical structure maps to production implementations.

**[SENIOR] Q8 - [DEBUGGING] Your custom data structure's invariant was violated. How do you diagnose and fix?**

Step 1: reproduce with a small test case. If the invariant violation was observed in production, add logging of every operation and reproduce in a test environment. The violation often appears immediately with a specific sequence of operations.

Step 2: add invariant assertions. For every operation (insert, delete, query), add a checkInvariant() method that verifies the invariant holds. Enable in test; disable in production (or run on 0.1% of requests in production for continuous monitoring).

Step 3: identify which operation breaks the invariant. Binary search: if 10K operations cause the violation, add invariant check after every 1K, 500, 100, ... until the failing operation is isolated.

Step 4: trace the failing operation. For the identified operation, add step-by-step state logging. Find the exact line where the invariant is broken.

Step 5: verify the fix. The fix must make the invariant true for every code path through the operation, including edge cases (empty, single element, at-capacity).

Invariant verification code for LRU:

```java
private void checkInvariant() {
    assert map.size() == listSize() :
        "map.size=" + map.size()
        + " listSize=" + listSize();
    Node curr = head.next;
    while (curr != tail) {
        assert map.containsKey(curr.key) :
            "list node not in map: " + curr.key;
        assert map.get(curr.key) == curr :
            "map points to wrong node for: "
            + curr.key;
        curr = curr.next;
    }
}
```

> **Code walkthrough:** Invariant checking for LRU cache. The KEY MECHANISM: three checks: (1) sizes match (catches one-structure updates without the other); (2) every list node key exists in the map (catches list updates without map update); (3) map points to the correct node (catches stale map entries after node moves). WHY IT MATTERS: invariant assertions catch violations immediately at the operation that causes them, rather than at the read that observes them (which may be much later and in different code). WHAT BREAKS: running invariant checks in production adds O(n) overhead to every operation. Use sampling (1% of operations) or enable only on demand. TAKEAWAY: invariant checking is the automated test strategy for custom data structures - make the invariant executable and assert it in every test.

**[STAFF] Q9 - [ARCHITECTURE] Design a data structure for a high-frequency trading order book.**

Order book requirements:
- Add order (price, quantity, buy/sell): O(log n).
- Cancel order (orderId): O(1).
- Fill order (orderId, quantity): O(1) (partial fill).
- Best bid: O(1) (highest buy price).
- Best ask: O(1) (lowest sell price).
- Level-2 data: all price levels with total quantity: O(depth).

Level is a price level with total quantity and a queue of orders at that price.

Data structures:
1. Two PriorityQueues: maxHeap for buys (bids), minHeap for asks. Get best bid/ask in O(1). Problem: cancel order requires O(n) scan.

2. Solution: HashMap<orderId, OrderRef> + TreeMap<price, Level> + per-level Queue<Order>.
   - HashMap maps orderId -> Order (for O(1) cancel/fill by ID).
   - TreeMap maps price -> Level (for O(log n) add price level, O(1) best bid/ask via lastKey()/firstKey()).
   - Level is a doubly linked list (FIFO queue) of orders at this price level (for time-priority ordering within a level).

addOrder(price, qty, side): find/create Level in TreeMap, add Order to Level's queue, add to HashMap. O(log n).
cancelOrder(id): HashMap.get(id) -> Order. Remove Order from Level's queue (O(1) with doubly linked list + Order storing its own node reference). If Level is empty, remove from TreeMap. O(log n) for TreeMap remove, O(1) for queue remove.
bestBid(): bids TreeMap.lastKey(). O(1) (TreeMap lastKey is O(log n) in Java 8, O(1) in java.util.TreeMap.firstKey()).

*What separates good from great:* The per-level FIFO queue detail (time-priority ordering within a price level) and storing Order's own node reference in the doubly linked list for O(1) cancel - demonstrating that real order book design requires price-priority AND time-priority, not just price-priority.

**[STAFF] Q10 - [THEORY] Prove that any LRU replacement policy requires at least O(1) amortized time per operation or O(n) space overhead beyond the base cache.**

Lower bound argument:

LRU must track the recency order of all n elements in the cache. The recency order is a total ordering over n elements. Changing the recency order (which happens on every access) requires modifying the data structure to reflect the new ordering.

Any total ordering of n elements requires Omega(n log n) bits to represent (there are n! orderings, and log_2(n!) = Omega(n log n) bits). The recency ordering changes on every access.

For any access that moves element e from position k (from most-recent) to position 1 (most-recent): the change is equivalent to a move operation in the sorted sequence. In a comparison-based model, updating a position-k element to position 1 requires Omega(log n) comparisons in general (you must know the relative order of all elements).

The O(1) amortized solution (doubly linked list): achieves O(1) by exploiting the fact that move-to-front always moves to a fixed position (the front). This is NOT a general sort operation. The doubly linked list stores pointers that enable O(1) relinking regardless of the element's current position. This requires O(n) extra space (the list nodes) beyond the base HashMap.

Conclusion: O(1) operations require O(n) extra space (the doubly linked list). If you want less than O(n) extra space, operations must be > O(1).

*What separates good from great:* Identifying that the O(1) LRU solution exploits the specific structure of move-to-front (always moves to one fixed position) rather than a general ordering update - and proving this requires O(n) extra space.

**[STAFF] Q11 - [PRODUCTION] Design a time-series data structure for real-time anomaly detection on 1M metrics.**

Requirements: 1M metrics, each as a sliding window of the last 60 minutes at 1-minute resolution (60 data points). Detect anomaly if latest value deviates > 3 sigma from the window mean/stddev. Latency: < 1ms per detection query.

Data structure per metric (60-element sliding window):

Fixed-size ring buffer (60 elements). On each new data point: insert at current position, advance pointer, evict oldest. O(1) insert.

For anomaly detection (mean and stddev):
- Naive: recalculate mean from 60 values on each insert: O(60) = O(1) for fixed window size. Acceptable for 1M metrics at 1 update/minute = 1M updates/minute.
- Better: maintain running sum and sum-of-squares. On insert: sum += new - old (Welford's online algorithm for stddev). O(1) per update.

Welford's algorithm:
  M = running mean, S = sum of squared deviations
  On new value x, old value old_x (removed from window):
    diff1 = x - old_x
    new_count = count (fixed = 60)
    new_mean = M + diff1 / count
    diff2 = x - new_mean
    diff3 = old_x - M
    S = S + diff2 * (x - M) + diff3 * (old_x - new_mean)
    ...

For simplicity at 60 elements: recalculate per minute is 60M operations/minute = 1M/sec = within CPU budget.

Total memory: 1M metrics * 60 * 8 bytes (double) = 480MB. Fits in RAM.

*What separates good from great:* Welford's online algorithm for numerically stable running stddev update - and the judgment that for fixed window size W=60, recalculating mean/stddev from scratch per update (60M ops/min) is within CPU budget without needing Welford's optimization, and recognizing that simplicity should be preferred.

**[STAFF] Q12 - [ARCHITECTURE] What makes a data structure "production-ready" beyond correctness?**

Production-readiness dimensions beyond correctness:

1. Performance predictability: worst-case latency, not just average. A hash table with O(1) average but O(n) worst case (during resize) is unacceptable for latency-sensitive systems. Use incrementally resizable hash tables (like Java's ConcurrentHashMap which uses segmented resizing).

2. Memory safety: no buffer overflows, no use-after-free, no double-free. In Java: avoid raw arrays where possible; use bounds-checked structures. In C++: use RAII, unique_ptr, span.

3. Concurrent safety: clearly documented thread safety guarantees. Either thread-safe (with documented performance characteristics under contention) or explicitly not-thread-safe (with clear indication that external synchronization is required).

4. Serialization: must be serializable to disk and deserializable correctly. Custom structures may need custom serialization code. Test round-trip (serialize -> deserialize -> re-serialize; compare).

5. Observability: expose metrics: size, capacity, hit rate (for caches), eviction rate, operation latency histograms. A black-box data structure is unacceptable in production.

6. Graceful degradation: behavior under resource exhaustion (OOM, disk full) must be defined. Does the structure fail fast (throw OOM) or degrade (drop entries)? The choice must match system requirements.

7. Upgrade path: as the system grows, can the structure be migrated to a larger version without downtime? If not, the upgrade path must be planned at design time.

*What separates good from great:* The observability point - a production data structure must expose metrics (size, hit rate, latency) through the same monitoring infrastructure as the rest of the system. A structure that cannot be monitored cannot be operated.

---

### ⚖️ Comparison Table

| Custom Structure | Composition | Core invariant | All-ops complexity |
|-----------------|-------------|----------------|-------------------|
| LRU Cache | HashMap + DLL | Map[k] = ListNode, list is recency-ordered | O(1) get/put/evict |
| Median Stream | MaxHeap + MinHeap | |sizes| <= 1, maxHeap.top <= minHeap.top | O(log n) add, O(1) median |
| O(1) Insert/Delete/Random | ArrayList + HashMap | map[x] = index, list[index] = x | O(1) all |
| Interval Tree | BST + maxHigh aug | node.maxHigh = max(hi in subtree) | O(log n+k) overlap |
| LFU Cache | HashMap + FreqMap + DLL | freq map groups by access count | O(1) get/put |
| Rate Limiter (token) | Counter + Timestamp | tokens regenerate at rate r | O(1) allow |
| Order Book | TreeMap + HashMap + DLL | map[price]=level, map[id]=order | O(log n) add, O(1) cancel |

---

### 🏛️ System Design

**Design a distributed cache with approximate LRU eviction for 1TB of data across 100 nodes.**

**Requirements:** 1TB total cache, 100 nodes, 10MB/s per node write rate, P99 get latency < 1ms, ~LRU eviction, O(1) get/set.

**Architecture:**

```
Distributed LRU Cache Architecture:

Client -> Consistent Hash Ring -> Node selection O(log N)
             |
        Node i (10GB local cache)
             |
      Local LRU: Segmented HashMap + DLL
        - 256 segments (locks)
        - Each segment: HashMap<key, Node*>
          + DLL (MRU head, LRU tail)
        - Eviction: LRU tail of each segment

Per-node memory layout:
  10GB / 64-byte avg entry = 156M entries/node
  156M * (HashMap + Node overhead):
    Node: key_hash(8) + value_ptr(8) + prev(8)
          + next(8) = 32 bytes
    HashMap entry: 8 bytes (pointer to Node)
  Total overhead per entry: ~40 bytes
  10GB data + 40/64 * 10GB overhead = 16.25GB per node
  -> 64GB RAM per node (4:1 headroom for peaks)
```

> **Diagram walkthrough:** Distributed LRU cache with consistent hashing and per-node segmented LRU. The consistent hash ring provides O(log N) node selection for N=100 nodes. Each node implements a local LRU using segmented locking (256 segments) to enable 256-way concurrent access without global contention. The memory layout analysis is critical for capacity planning: each 64-byte data entry requires ~40 bytes of structure overhead (HashMap pointers, doubly linked list prev/next, hash storage). For 10GB of data per node, the actual RAM requirement is ~16GB minimum. With 4:1 headroom for peaks (hot key concentration, GC pressure): 64GB RAM per node. Edge case: a hot key receiving 1M requests/second in a single-lock LRU causes serialization at that lock. Segmented locking distributes hot keys across segments, but if all hot keys hash to the same segment, performance degrades. Use segment count = power of 2 with uniform key hash distribution. Insight: the move-to-front operation in each get() is the bottleneck at high throughput - W-TinyLFU avoids move-to-front for most accesses using a probabilistic admission filter, achieving 10x higher throughput at the cost of "approximate LRU" rather than "exact LRU."

---

### 📊 Diagram

```
Custom Data Structure Composition Patterns:

Pattern 1: O(1) lookup + O(1) ordered access
  Structure: HashMap + Doubly Linked List
  HashMap: key -> node_ref (O(1) lookup)
  DLL:     ordered sequence (O(1) reorder)
  Invariant: map[k] = node, node in list
  Example: LRU Cache, LinkedHashMap

Pattern 2: O(1) rank + O(log n) update
  Structure: MaxHeap + MinHeap
  MaxHeap: lower half, max accessible in O(1)
  MinHeap: upper half, min accessible in O(1)
  Invariant: |sizes| <= 1, max <= min
  Example: Median Stream

Pattern 3: O(log n) subtree queries
  Structure: BST + per-node aggregate
  BST: sorted structure
  Aggregate: e.g., max, sum, count per subtree
  Invariant: node.agg = f(left.agg, right.agg, node)
  Example: Interval Tree, Order Statistics Tree

Pattern 4: O(1) all three operations
  Structure: ArrayList + HashMap
  ArrayList: O(1) random access by index
  HashMap:   O(1) lookup by value -> index
  Invariant: map[v] = i, list[i] = v
  Example: Insert/Delete/GetRandom in O(1)
```

> **Diagram walkthrough:** Four canonical custom data structure composition patterns. The key relationship: each pattern solves a specific "gap" in standard structures: HashMap has O(1) lookup but no ordering; DLL has O(1) ordering but no lookup -> compose them. MaxHeap has O(1) max access but can't split; two heaps split the domain -> compose them. BST has O(log n) search but no subtree aggregates -> augment with per-node aggregate. ArrayList has O(1) random access but O(n) delete -> HashMap adds O(1) lookup for delete-by-swap. Edge case: all four patterns require strict invariant maintenance after every operation. The invariant is what makes the composition coherent rather than just two unrelated structures. Insight: these four patterns cover the majority of "design a data structure" interview questions. Recognizing which pattern applies is the key skill: if the problem requires O(1) for two conflicting operations, it's usually pattern 1 or 4 (compose with HashMap). If it requires O(1) boundary access on a split domain, it's pattern 2. If it requires subtree range queries, it's pattern 3.
