---
layout: default
title: "Data Structures - L3 Advanced Structures"
parent: "Data Structures"
nav_order: 7
permalink: /data-structures/l3-advanced-structures/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 1 | [Segment Trees and Range Queries](#segment-trees-and-range-queries) | high |
| 2 | [Union-Find (Disjoint Set Union)](#union-find-disjoint-set-union) | critical |

---

# Segment Trees and Range Queries

**Difficulty:** ★★☆

**Interview Weight:** High

---

### 🎯 Model Answer

**30 seconds:**
A Segment Tree is a binary tree where each node stores an aggregate (sum, min, max) over a contiguous subarray range. Leaves represent individual elements; internal nodes represent merged ranges. Build: O(n). Range query (sum, min, max over any subrange [l, r]): O(log n). Point update (change one element): O(log n). The key insight: by decomposing any query range into at most O(log n) stored segments, you get O(log n) for arbitrary range aggregates - far better than O(n) naive scan.

**3 minutes:**
Consider an array of n numbers. You want to repeatedly answer "sum of elements from index l to r" and "update element at index i to value v." Prefix sum arrays answer range queries in O(1) but require O(n) for updates. A plain array answers updates in O(1) but requires O(n) for range queries. A Segment Tree achieves O(log n) for both.

The tree structure: leaves correspond to array positions. Each internal node covers a range [left, right] and stores an aggregate over that range. The root covers [0, n-1]. A node covering [l, r] has left child covering [l, mid] and right child covering [mid+1, r]. Since each level halves the range, height is O(log n).

Range query: decompose [l, r] into at most 2*O(log n) stored segments that together exactly cover [l, r] without overlap. Sum these segments in O(log n).

Point update: update index i by walking from root to the leaf at position i, recomputing aggregates at each of O(log n) nodes on the path.

Segment trees are especially powerful with lazy propagation - range updates (add X to all elements in [l, r]) become O(log n) by deferring updates.

**Blank Mind Recovery:**
**(1) Restate:** "Segment tree: each node = aggregate over a range. Leaves = individual elements."
**(2) Complexity:** "Build O(n). Query O(log n). Point update O(log n)."
**(3) Array trick:** "Store as 1-indexed array: node i has children 2i and 2i+1. Use size 4*n."
**(4) Alternative:** "Fenwick tree (BIT) is simpler code for sum queries only; Segment tree handles any aggregate."

---

### 📘 Concept Explanation

**What it is:**
A Segment Tree is a full binary tree where:
- Leaves store individual array elements
- Each internal node stores an aggregate (sum, min, max, GCD, etc.) over the range covered by its subtree
- Total nodes: 2n - 1 for n leaves (roughly 4n when allocated as an array for safety)

**The problem it solves:**
Efficient range queries AND point updates simultaneously. Prefix sums give O(1) query but O(n) update. Segment tree gives O(log n) for both.

**Structure and array representation:**

```
Array: [2, 5, 1, 4, 9, 3]   (indices 0-5)

Segment Tree (sum):
           node 1: [0,5]=24
          /              \
   node 2:[0,2]=8    node 3:[3,5]=16
    /       \           /        \
n4:[0,1]=7 n5:[2,2]=1 n6:[3,4]=13 n7:[5,5]=3
 /   \                  /    \
n8:[0]=2 n9:[1]=5    n12:[3]=4 n13:[4]=9

Array storage (1-indexed):
Index: 1   2   3   4   5   6   7   8   9  ...
Value: 24   8  16   7   1  13   3   2   5 ...

Node i:
  left child  = 2*i
  right child = 2*i + 1
  parent      = i/2
```

> **Diagram walkthrough:** A sum segment tree on 6 elements. Each internal node stores the sum of its subarray. Node 1 (root) = 24 = total sum. Node 2 = 8 = sum of indices [0,2] = 2+5+1. Leaves at the bottom store individual elements. The key relationship: every node's value = left_child.value + right_child.value. To query sum([1,4]): decompose into stored segments - [1,1] (node 9) + [2,2] (node 5) + [3,4] (node 6) = 5+1+13 = 19. Three node reads instead of 4 array scans. Edge case: when n is not a power of 2, pad with identity values (0 for sum, infinity for min) or use n=next_power_of_2 allocation. Insight: the array storage with 1-indexed children at 2i and 2i+1 means no pointers are needed - the tree structure is implicit in index arithmetic, same as a binary heap.

**Implementation:**

```java
class SegmentTree {
    private final int[] tree;
    private final int n;

    // Build: O(n)
    SegmentTree(int[] arr) {
        n = arr.length;
        tree = new int[4 * n]; // safe allocation
        build(arr, 1, 0, n - 1);
    }
    private void build(
        int[] arr, int node, int l, int r
    ) {
        if (l == r) {
            tree[node] = arr[l];
            return;
        }
        int mid = (l + r) / 2;
        build(arr, 2*node, l, mid);
        build(arr, 2*node+1, mid+1, r);
        tree[node] = tree[2*node] + tree[2*node+1];
    }

    // Point update: O(log n)
    void update(int i, int val) {
        update(1, 0, n-1, i, val);
    }
    private void update(
        int node, int l, int r, int i, int val
    ) {
        if (l == r) {
            tree[node] = val;
            return;
        }
        int mid = (l + r) / 2;
        if (i <= mid)
            update(2*node, l, mid, i, val);
        else
            update(2*node+1, mid+1, r, i, val);
        tree[node] = tree[2*node] + tree[2*node+1];
    }

    // Range query: O(log n)
    int query(int ql, int qr) {
        return query(1, 0, n-1, ql, qr);
    }
    private int query(
        int node, int l, int r, int ql, int qr
    ) {
        if (qr < l || r < ql) return 0; // no overlap
        if (ql <= l && r <= qr)         // full overlap
            return tree[node];
        int mid = (l + r) / 2;
        return query(2*node, l, mid, ql, qr)
             + query(2*node+1, mid+1, r, ql, qr);
    }
}
```

> **Code walkthrough:** A complete sum segment tree. The KEY MECHANISM: the query function uses three cases - no overlap (return identity 0), full overlap (return stored node value), partial overlap (recurse into both children). Every query hits at most 4*log(n) nodes because at any level there are at most 2 "partial overlap" nodes and 2 "boundary" nodes. WHY IT MATTERS: the full-overlap early return is the optimization that makes O(log n) possible - once a stored segment is completely inside the query range, its aggregate is used without visiting its subtree. WHAT BREAKS: returning the wrong identity value for no-overlap (0 is correct for sum, but Integer.MAX_VALUE for min, 1 for product) will corrupt results when the query boundary falls outside the array. TAKEAWAY: the identity value for no-overlap depends on the aggregate operation - always pair the correct identity (0 for sum, MAX_VALUE for min, MIN_VALUE for max, 1 for product) with the merge operation.

**Fenwick Tree (Binary Indexed Tree) comparison:**

```java
// Fenwick Tree: simpler code, sum only
class FenwickTree {
    private final int[] bit;
    FenwickTree(int n) { bit = new int[n+1]; }

    // Add delta to index i (1-indexed)
    void update(int i, int delta) {
        for (; i < bit.length; i += i & (-i))
            bit[i] += delta;
    }

    // Prefix sum [1..i]
    int query(int i) {
        int sum = 0;
        for (; i > 0; i -= i & (-i))
            sum += bit[i];
        return sum;
    }

    // Range sum [l..r]
    int rangeQuery(int l, int r) {
        return query(r) - query(l-1);
    }
}
// i & (-i): isolates lowest set bit
// Use: prefix sums with updates
// Not suitable: range minimum queries
```

> **Code walkthrough:** Fenwick Tree (Binary Indexed Tree) for comparison with Segment Tree. The KEY MECHANISM: the bitwise trick i & (-i) isolates the lowest set bit, giving the "responsibility range" of each BIT node. Each update touches O(log n) nodes in the "upper triangle"; each prefix query touches O(log n) nodes in the "lower triangle." WHY IT MATTERS: Fenwick tree code is ~20 lines vs ~50 for segment tree and uses half the space (n+1 array vs 4n). WHAT BREAKS: Fenwick trees only support prefix aggregate operations naturally - range minimum/maximum requires modification (two Fenwick trees for max/min). TAKEAWAY: prefer Fenwick tree when you only need range sum with point updates; use segment tree for range min/max or when lazy propagation (range updates) is needed.

---

### 💻 Code Example

**Production Example: stock price range minimum query**

```java
// Min segment tree for range min queries
// Used for: min stock price in date range
class MinSegTree {
    private final int[] tree;
    private final int n;

    MinSegTree(int[] prices) {
        n = prices.length;
        tree = new int[4 * n];
        build(prices, 1, 0, n-1);
    }
    private void build(
        int[] a, int node, int l, int r
    ) {
        if (l == r) { tree[node] = a[l]; return; }
        int mid = (l + r) / 2;
        build(a, 2*node, l, mid);
        build(a, 2*node+1, mid+1, r);
        tree[node] = Math.min(
            tree[2*node], tree[2*node+1]
        );
    }

    // Min price between day ql and qr
    int queryMin(int ql, int qr) {
        return queryMin(1, 0, n-1, ql, qr);
    }
    private int queryMin(
        int nd, int l, int r, int ql, int qr
    ) {
        if (qr < l || r < ql)
            return Integer.MAX_VALUE;
        if (ql <= l && r <= qr) return tree[nd];
        int mid = (l + r) / 2;
        return Math.min(
            queryMin(2*nd, l, mid, ql, qr),
            queryMin(2*nd+1, mid+1, r, ql, qr)
        );
    }
    void updatePrice(int day, int price) {
        update(1, 0, n-1, day, price);
    }
    private void update(
        int nd, int l, int r, int i, int val
    ) {
        if (l == r) { tree[nd] = val; return; }
        int mid = (l + r) / 2;
        if (i <= mid) update(2*nd, l, mid, i, val);
        else update(2*nd+1, mid+1, r, i, val);
        tree[nd] = Math.min(
            tree[2*nd], tree[2*nd+1]
        );
    }
}
// queryMin(0, 364) = minimum price in last year
// updatePrice(today, newPrice) = O(log 365)
```

> **Code walkthrough:** Min segment tree for stock price analysis. The KEY MECHANISM: the identity for "no overlap" is Integer.MAX_VALUE (returned when the query range doesn't intersect the node's range) - taking Math.min with MAX_VALUE leaves the other side's result unchanged. WHY IT MATTERS: applications include "52-week low" (range min over 252 trading days), "maximum drawdown" (max of range max minus range min), and sliding window minimum in O(log n) per query. WHAT BREAKS: using 0 as the no-overlap identity for min query returns 0 even when no element is in range. TAKEAWAY: the no-overlap return value must be the identity element for your aggregate operation - the value X where merge(X, anything) = anything.

---

### 🎓 Answers by Seniority

**Junior / Mid-level:**
Segment tree: binary tree where each node stores aggregate over a range. Build O(n), query O(log n), update O(log n). Array-based storage: node i has children 2i and 2i+1, allocate 4n space. Key use cases: range sum, range min/max with point updates. Simpler alternative for range sum only: Fenwick tree (BIT) with O(n) space and simpler code.

**Senior / Staff-level:**
Lazy propagation extends segment trees to handle range updates (add X to all elements in [l, r]) in O(log n) by marking "lazy" tags on nodes and propagating them down only when needed. This enables O(log n) range-update + range-query on time series, spatial data, and competitive programming problems. In production: use for financial tick data aggregation, time-windowed statistics on IoT sensor streams, or 2D segment trees for spatial range queries. Persistent segment trees allow O(log n) versioned updates with O(n log n) space for all versions - used in functional persistent data structures and version history systems.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Segment tree only handles sum queries"**
Reality: segment tree handles any associative aggregate - sum, min, max, GCD, product, bitwise OR/AND, XOR, or custom merge functions.

**Misconception 2: "Prefix sum arrays are always better for range sum"**
Reality: prefix sum gives O(1) query but O(n) point update. Segment tree gives O(log n) for both. Prefix sum only wins for static arrays with no updates.

**Misconception 3: "Segment tree requires exactly n nodes"**
Reality: array-based segment tree requires 4n allocation for safety when n is not a power of 2. Allocating exactly 2n nodes causes out-of-bounds errors.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Wrong identity for no-overlap case**
- Symptom: range queries return 0 for min or Integer.MAX_VALUE for sum
- Cause: using sum identity (0) for min queries, or min identity (MAX_VALUE) for sum queries
- Fix: use operation-specific identity: sum->0, min->MAX_VALUE, max->MIN_VALUE, product->1

**Failure 2: Array allocation too small**
- Symptom: ArrayIndexOutOfBoundsException during build or query
- Cause: allocating 2n instead of 4n for the tree array
- Fix: always allocate 4*n for the tree array as a safe upper bound

**Failure 3: Off-by-one in range boundaries**
- Symptom: query([0, n-1]) returns wrong result; query results are shifted
- Cause: 0-indexed vs 1-indexed inconsistency; build called with wrong bounds
- Fix: consistently use 0-indexed leaf positions; always call build with (1, 0, n-1)

---

### 🎯 Interview Deep-Dive

| Timing | Questions |
|--------|-----------|
| Opening (0-2 min) | Motivation, complexity |
| Mid (2-8 min) | Implementation, aggregates |
| Deep-dive (8-15 min) | Lazy propagation, production |

**[JUNIOR] Q1 - [CONCEPT] Why is a segment tree better than a prefix sum array for dynamic range queries?**

Prefix sum array: build in O(n). Query sum([l,r]) = prefix[r] - prefix[l-1] in O(1). Update index i: must recompute all prefix[i..n] = O(n).

Segment tree: build in O(n). Query in O(log n). Update in O(log n).

For a static array (no updates): prefix sum is strictly better (O(1) query vs O(log n)).

For a dynamic array with frequent updates and queries: segment tree is better. If you have Q queries and U updates on an array of size n:
- Prefix sum: Q * O(1) + U * O(n) = O(Q + U*n)
- Segment tree: Q * O(log n) + U * O(log n) = O((Q+U) * log n)

For Q = U = n: prefix sum is O(n^2), segment tree is O(n log n). At n=100K: 10^10 vs 1.7 * 10^6.

*What separates good from great:* Quantifying the trade-off with Q, U, n and showing the crossover point - if updates are rare (U << Q), prefix sum wins; if updates are frequent (U close to Q), segment tree wins.

**[JUNIOR] Q2 - [CODING] Walk through a range sum query on a segment tree.**

Query sum([2, 4]) on array [2,5,1,4,9,3] (indices 0-5):

Start at root (node 1, range [0,5]). Is [2,4] fully inside [0,5]? No (partial overlap). Recurse into both children.

Left child (node 2, range [0,2]): Is [2,4] fully inside [0,2]? No (partial). Recurse.
- Left-left (node 4, range [0,1]): No overlap with [2,4]. Return identity 0.
- Left-right (node 5, range [2,2]): Fully inside [2,4]. Return tree[5] = 1.

Right child (node 3, range [3,5]): Is [2,4] fully inside [3,5]? No (partial). Recurse.
- Right-left (node 6, range [3,4]): Fully inside [2,4]. Return tree[6] = 13.
- Right-right (node 7, range [5,5]): No overlap with [2,4]. Return identity 0.

Total: 0 + 1 + 13 + 0 = 14. (Correct: arr[2]+arr[3]+arr[4] = 1+4+9 = 14.)

*What separates good from great:* Tracing the exact nodes visited (4 nodes contributing to result, 2 returning identity) and noting this is O(log n) = O(3) node visits per level, bounded by 4*height total.

**[MID] Q3 - [TRADE-OFF] When do you use a Fenwick tree vs a segment tree?**

Fenwick Tree (BIT): simpler code (~10 lines for core operations), O(n) space, O(log n) update and prefix sum. Supports range sum via prefix[r] - prefix[l-1]. Supports point updates. Does NOT support range minimum/maximum natively.

Segment Tree: more code (~50 lines), O(4n) space, O(log n) for any associative aggregate, supports lazy propagation for range updates. Handles min, max, GCD, XOR, product.

Choose Fenwick when: only range sum with point updates needed. The implementation simplicity is significant in interviews.

Choose Segment Tree when: need range min/max, need range updates (lazy propagation), or need a custom merge function (e.g., "count inversions", "maximum subarray sum").

In practice: Fenwick tree is 3x shorter to write correctly in an interview. Segment tree is the only option for range minimum with updates.

*What separates good from great:* Knowing that Fenwick trees can be extended to 2D (BIT2D) for 2D range sums, and that segment trees can be made persistent for versioned operations - two extensions that appear in advanced interviews.

**[MID] Q4 - [CODING] Explain lazy propagation and when it is needed.**

Lazy propagation handles range updates: "add 5 to all elements in [l, r]" or "set all elements in [l, r] to X."

Without lazy propagation, a range update requires O(n log n) - update each element in [l, r] individually.

With lazy propagation: mark a "lazy tag" on the node covering the update range. Propagate this tag down only when a child node is visited for a query or further update. This defers the actual work.

Example: "add 5 to all of [0, n-1]": instead of updating all n leaves, mark the root with lazy += 5 and update tree[root] += 5 * n. Next query on any range propagates the tag down as needed.

Complexity: range update O(log n), range query O(log n) - same as point operations.

Key invariant: before using any node's value in a query, push its lazy tag down to both children first.

*What separates good from great:* Explaining the lazy propagation invariant precisely - "before accessing a node's children, push the parent's lazy tag down" - and noting that forgetting to push causes stale values.

**[MID] Q5 - [SYSTEM] Design a real-time leaderboard that supports rank queries and score updates.**

Approach: augmented segment tree on score range [0, MAX_SCORE]. Each leaf represents one score value; stores the count of players with that score. Internal nodes store total player count in the score range.

Operations:
- Score update: remove player from old score (point update -1), add to new score (point update +1). O(log MAX_SCORE).
- Rank of player with score S: query count of players with score > S (sum of all scores higher than S). O(log MAX_SCORE).
- Top-K: traverse from highest score downward until K players found. O(K * log MAX_SCORE).

If MAX_SCORE = 10^6: tree has 10^6 leaves = 4*10^6 nodes at ~10MB. Acceptable.

Alternative: Redis Sorted Set. O(log n) for ZADD, ZRANK, ZRANGEBYSCORE. Production choice for most leaderboards - handles distributed access, persistence, replication.

*What separates good from great:* Representing the leaderboard as a segment tree over the score domain (not the player index) - this is the insight that makes rank queries O(log MAX_SCORE) = O(20) regardless of player count.

**[SENIOR] Q6 - [PRODUCTION] How are segment trees used in databases and analytical systems?**

Segment trees appear in databases primarily for indexing scenarios requiring efficient range aggregate queries.

InfluxDB and time-series databases: segment tree variants for time-range aggregation queries ("average CPU usage in last 1 hour"). The time axis is the array; each leaf is a time bucket; queries aggregate across arbitrary time windows.

PostgreSQL range types and exclusion constraints: internally use interval trees (which share segment tree concepts) to efficiently check for overlapping intervals.

Apache Druid: uses data sketches (theta sketches, approximate segment trees) for approximate range aggregates with O(1) space per segment.

Column stores (Vertica, ClickHouse): materialized pre-aggregates at multiple time granularities (per-second, per-minute, per-hour). Equivalent to a 3-level segment tree: query hits the coarsest granularity that fits the range, then handles the remainder at finer granularity. Roll-up query O(log time_range) instead of O(time_range).

*What separates good from great:* Connecting segment trees to columnar database roll-up aggregation (materialized at multiple granularities) - this is the real-world production pattern.

**[SENIOR] Q7 - [DEBUGGING] Your segment tree range query returns wrong results for some ranges. How do you debug?**

Step 1: verify the build. Check that tree[1] (root) equals the sum/min/max of the entire array. Print all tree values and verify manually for a small array (5-7 elements).

Step 2: test edge cases specifically: query([0,0]), query([n-1,n-1]) (single element), query([0,n-1]) (full range), query with l=r-1 (adjacent elements).

Step 3: check the identity value. For sum: no-overlap returns 0. For min: returns Integer.MAX_VALUE. Wrong identity silently corrupts partial-overlap nodes.

Step 4: verify array allocation. If tree has fewer than 4*n nodes, accessing 4*i for large i causes out-of-bounds with unchecked wrapping.

Step 5: check 0 vs 1-indexed consistency. If array is 0-indexed but tree is 1-indexed (child of node i at 2i and 2i+1), the call build(arr, 1, 0, n-1) must match the query call query(1, 0, n-1, ql, qr).

*What separates good from great:* Immediately checking the identity value - this is the most common subtle bug in segment trees and produces wrong answers for specific boundary queries that happen to hit the no-overlap case.

**[STAFF] Q8 - [ARCHITECTURE] Design a 2D range query system for geospatial data.**

Requirements: given a set of (x, y) points, answer "how many points lie in rectangle [x1,x2] x [y1,y2]?" with dynamic insertions.

2D Segment Tree: outer tree on X coordinate, each outer node contains an inner segment tree on Y coordinate. Total space O(n log n) (n outer nodes, each inner tree O(log n) on average). Range query: O(log^2 n) - O(log n) outer levels, each with O(log n) inner query.

Build: sort points by X; build outer tree over X range; for each outer node, build inner tree over Y values of points in that X range.

Alternative - Fractional Cascading: reduces 2D range query to O(log n) instead of O(log^2 n) by sharing sorted arrays between tree levels. Complex to implement.

Practical choice for geospatial: R-Tree (used in PostGIS, spatial indexes). R-Tree groups nearby points into minimum bounding rectangles, enabling O(sqrt(n)) typical query performance with good spatial locality.

*What separates good from great:* Knowing R-Tree as the production geospatial index (PostGIS, MongoDB 2dsphere, Elasticsearch geo_shape) and knowing 2D segment tree gives O(log^2 n) vs R-Tree's typical O(sqrt(n)) but different worst cases.

**[STAFF] Q9 - [THEORY] What is a persistent segment tree and how does it enable versioned queries?**

A persistent segment tree allows "snapshots" of the array at each version, supporting queries like "what was the sum of [l,r] at version k?"

Key insight: updating a leaf in a segment tree only modifies O(log n) nodes on the path from root to leaf. All other nodes are unchanged. A persistent update creates NEW copies of only those O(log n) modified nodes, keeping pointers to unchanged nodes.

Result: after n updates, there are n root pointers (one per version). Each version's tree shares unchanged subtrees with other versions. Total space: O(n log n) for n versions (each creates O(log n) new nodes). Query on any version: O(log n) using that version's root.

Applications:
1. Historical query: "how many elements were in [l,r] at time t?" - persistent segment tree on time axis
2. Order statistics: persistent segment tree on sorted values to answer "kth smallest in [l,r]" - the "merge sort tree" interview problem
3. Functional data structures: immutable segment trees enable structural sharing in purely functional languages

Build sequence: version 0 is the initial array. Version i is created by applying one update to version i-1, creating O(log n) new nodes.

*What separates good from great:* Knowing the merge sort tree application (persistent segment tree on sorted values for O(log^2 n) kth-smallest-in-range queries) and connecting persistent data structures to functional programming's structural sharing principle.

---

### ⚖️ Comparison Table

| Property | Segment Tree | Fenwick Tree | Prefix Sum | Sparse Table |
|----------|-------------|--------------|------------|--------------|
| Build | O(n) | O(n log n) | O(n) | O(n log n) |
| Point update | O(log n) | O(log n) | O(n) | N/A (static) |
| Range query | O(log n) | O(log n) | O(1) | O(1) |
| Range update | O(log n) lazy | O(log n) | O(1) mark, O(n) compute | N/A |
| Space | O(4n) | O(n) | O(n) | O(n log n) |
| Aggregates | Any assoc. | Sum only | Sum only | Idempotent (min/max) |
| Complexity | High | Low | Very low | Medium |

---

### 🏛️ System Design

*(Omit: not applicable as standalone system design - segment trees are components. See Senior Q6 for time-series database use and Mid Q5 for leaderboard system design.)*

---

### 📊 Diagram

```
Sum segment tree on [2,5,1,4,9,3]:

               [0-5]=24
              /         \
         [0-2]=8       [3-5]=16
         /    \         /     \
     [0-1]=7  [2]=1  [3-4]=13 [5]=3
     /   \            /    \
  [0]=2 [1]=5      [3]=4  [4]=9

Query([2,4]) trace:
 Root [0-5]: partial -> recurse
  Left [0-2]: partial -> recurse
    LL [0-1]: NO OVERLAP -> return 0
    LR [2-2]: FULL -> return 1
  Right [3-5]: partial -> recurse
    RL [3-4]: FULL -> return 13
    RR [5-5]: NO OVERLAP -> return 0
 Total: 0+1+13+0 = 14 ✓ (1+4+9=14)
```

> **Diagram walkthrough:** Sum segment tree with a query trace. The tree structure shows 11 nodes covering array [2,5,1,4,9,3]. Query([2,4]) visits 7 nodes total but only 2 nodes contribute to the result (the FULL overlap nodes). The key relationship: the "partial overlap" recursion at each level eliminates one half of the remaining range, bounding total nodes visited to O(log n). Edge case: the root always starts as partial overlap for any non-full-range query, starting the recursion. Insight: every query visits at most 4 nodes per level (2 partial-overlap nodes that recurse + 2 full/no-overlap nodes that return) across O(log n) levels = O(log n) total - this is the formal proof of why segment tree queries are O(log n).

---

---

# Union-Find (Disjoint Set Union)

**Difficulty:** ★★☆

**Interview Weight:** Critical

---

### 🎯 Model Answer

**30 seconds:**
Union-Find (Disjoint Set Union, DSU) is a data structure that tracks elements partitioned into disjoint sets, supporting two operations: find(x) - which set does x belong to? (returns the set's representative/root) - and union(x, y) - merge the sets containing x and y. With union by rank and path compression, both operations run in nearly O(1) amortized time (inverse Ackermann function, practically constant). Classic applications: cycle detection in graphs, Kruskal's MST, connected components.

**3 minutes:**
The core question Union-Find answers is "are x and y in the same group?" Under dynamic grouping - groups merge over time, never split. Each set is a tree; the root is the representative.

find(x) walks up the tree from x to its root - O(tree height). union(x, y) merges the two trees by making one root point to the other.

Naive implementation: O(n) find in worst case (degenerate chain). Two optimizations fix this:

1. Union by rank: always attach the smaller tree under the root of the larger tree. Keeps maximum height O(log n).

2. Path compression: during find(x), make every node on the path from x to root point directly to the root. Future finds on those nodes are O(1).

Together: amortized O(alpha(n)) per operation where alpha is the inverse Ackermann function - effectively O(1) for any practical n (alpha(n) <= 4 for n <= 10^80).

**Blank Mind Recovery:**
**(1) Restate:** "Union-Find: tracks which set each element belongs to. find() returns set's root. union() merges two sets."
**(2) Arrays:** "parent[] where parent[i] = i means i is a root. rank[] for tree height tracking."
**(3) Two optimizations:** "Union by rank (attach small tree under large). Path compression (flatten on find)."
**(4) Use case:** "Cycle detection: union two nodes; if find() returns same root, there is a cycle."

---

### 📘 Concept Explanation

**What it is:**
Union-Find maintains a forest of trees where each tree represents one disjoint set. Each element points to its parent; roots point to themselves. The root is the set's representative/identifier.

**The problem it solves:**
Dynamic connectivity: elements merge into groups over time, and you repeatedly ask "are these two elements connected?" Cannot be solved efficiently with arrays or hash sets that don't track connectivity.

**Basic structure and initialization:**

```
Initial state: 5 elements, each its own set
parent: [0, 1, 2, 3, 4]  (each is its own root)
rank:   [0, 0, 0, 0, 0]

After union(0,1):
parent: [1, 1, 2, 3, 4]  (0's parent = 1)
rank:   [0, 1, 0, 0, 0]  (1's rank increases)

     1
    /
   0

After union(2,3):
parent: [1, 1, 3, 3, 4]
rank:   [0, 1, 0, 1, 0]

   1     3
  /     /
 0     2

After union(1,3):
parent: [1, 3, 3, 3, 4]
rank:   [0, 1, 0, 1, 0]
(rank equal: attach either under other, bump root)

     3
    / \
   1   2
  /
 0
```

> **Diagram walkthrough:** Union-Find construction with 5 elements. Initially each element is its own root (parent[i] = i). After union(0,1): 0 becomes a child of 1 (lower rank attaches to higher, or arbitrary when equal). After union(2,3): same. After union(1,3): both have rank 1, so attach 1 under 3 and increment 3's rank to 2. The key relationship: the root (parent[i] = i) is the set representative - two elements are in the same set if and only if find(x) == find(y). Edge case: when ranks are equal, either root can become the new root, but the winner's rank must increment by 1. Insight: path compression and union by rank together keep the tree so flat that empirical observation shows find() takes 1-3 steps for any practical dataset.

**Implementation with both optimizations:**

```java
class UnionFind {
    private final int[] parent;
    private final int[] rank;

    UnionFind(int n) {
        parent = new int[n];
        rank = new int[n];
        for (int i = 0; i < n; i++)
            parent[i] = i;
    }

    // Find with path compression: O(alpha(n))
    int find(int x) {
        if (parent[x] != x)
            parent[x] = find(parent[x]); // compress
        return parent[x];
    }

    // Union by rank: O(alpha(n))
    boolean union(int x, int y) {
        int rx = find(x), ry = find(y);
        if (rx == ry) return false; // already same set
        // Attach smaller rank under larger
        if (rank[rx] < rank[ry]) {
            parent[rx] = ry;
        } else if (rank[rx] > rank[ry]) {
            parent[ry] = rx;
        } else {
            parent[ry] = rx;
            rank[rx]++;
        }
        return true; // successfully merged
    }

    boolean connected(int x, int y) {
        return find(x) == find(y);
    }
}
```

> **Code walkthrough:** Union-Find with path compression and union by rank. The KEY MECHANISM: find() is recursive - if x is not its own root, recursively find the root AND set parent[x] = root (path compression). This flattens the tree lazily: every node visited during any find operation gets its parent pointer updated to point directly to the root. WHY IT MATTERS: path compression turns O(log n) find into amortized O(alpha(n)) without any upfront work - the tree flattens itself through normal use. WHAT BREAKS: iterative path compression (using a second pass) avoids stack overflow for very deep trees (n > 10^5 with poor insertion order); the recursive version may overflow the call stack on pathological input before path compression has taken effect. TAKEAWAY: implement find() recursively for simplicity in interviews; use the two-pass iterative version for production code with n > 10K.

**Cycle detection in undirected graph:**

```java
// Kruskal's MST uses this exact pattern
boolean hasCycle(int V, int[][] edges) {
    UnionFind uf = new UnionFind(V);
    for (int[] edge : edges) {
        int u = edge[0], v = edge[1];
        // If u and v already in same set:
        // adding this edge creates a cycle
        if (!uf.union(u, v)) return true;
    }
    return false;
}
// Kruskal's MST: sort edges by weight,
// union each; skip if already connected.
// MST = edges added without creating a cycle.
```

> **Code walkthrough:** Cycle detection using Union-Find - a canonical interview application. The KEY MECHANISM: process edges one by one; for each edge (u, v), try to union u and v. If union() returns false (already in the same set), adding this edge would create a cycle between two already-connected nodes. WHY IT MATTERS: this is O(E * alpha(E)) for E edges - effectively O(E). Kruskal's MST uses exactly this pattern with edges sorted by weight, giving O(E log E) total (dominated by sorting). WHAT BREAKS: using visited[] arrays for cycle detection in undirected graphs requires O(V + E) DFS per query; Union-Find gives O(alpha(n)) per edge check = far better for batch processing. TAKEAWAY: Union-Find cycle detection is the right algorithm for offline edge insertion (processing all edges); DFS-based detection is better for online queries on a fixed graph.

**Path compression variants:**

```java
// Iterative path compression (two-pass)
int findIterative(int x) {
    // Pass 1: find root
    int root = x;
    while (parent[root] != root)
        root = parent[root];
    // Pass 2: compress path
    while (parent[x] != root) {
        int next = parent[x];
        parent[x] = root;
        x = next;
    }
    return root;
}
// Use for large n to avoid stack overflow
```

> **Code walkthrough:** Iterative (two-pass) path compression for production safety. The KEY MECHANISM: first pass walks from x to root without modifying anything; second pass rewrites all parent pointers from x to root to point directly to root. WHY IT MATTERS: avoids recursion stack overflow for n > 10K when trees haven't been compressed yet (early in the algorithm). WHAT BREAKS: the one-pass iterative variant ("path halving" - parent[x] = parent[parent[x]]) achieves the same amortized complexity with a single pass and is slightly simpler to implement. TAKEAWAY: for interview use the recursive version; for production code with n > 100K, use the iterative two-pass version.

---

### 💻 Code Example

**Production Example: Kruskal's Minimum Spanning Tree**

```java
int kruskalMST(int V, int[][] edges) {
    // edges[i] = [weight, u, v]
    Arrays.sort(edges,
        Comparator.comparingInt(e -> e[0]));
    UnionFind uf = new UnionFind(V);
    int mstWeight = 0, edgesAdded = 0;

    for (int[] edge : edges) {
        int w = edge[0], u = edge[1], v = edge[2];
        // Add edge only if it doesn't form a cycle
        if (uf.union(u, v)) {
            mstWeight += w;
            edgesAdded++;
            if (edgesAdded == V - 1) break;
        }
    }
    return edgesAdded == V-1 ? mstWeight : -1;
    // -1 = graph is not connected
}
// Complexity: O(E log E) for sorting
// Union-Find adds O(E * alpha(E)) = O(E)
// Total: O(E log E)
```

> **Code walkthrough:** Kruskal's MST algorithm - the canonical Union-Find application. The KEY MECHANISM: sort edges by weight; greedily add the cheapest edge that doesn't create a cycle. Union-Find detects cycles in O(alpha(n)) per edge. A valid MST has exactly V-1 edges; if fewer are added, the graph is disconnected. WHY IT MATTERS: Kruskal's is the standard MST algorithm for sparse graphs; Prim's (with a priority queue) is better for dense graphs. WHAT BREAKS: not checking edgesAdded == V-1 at the end incorrectly returns a weight for disconnected graphs. TAKEAWAY: Kruskal's equals "sort edges + Union-Find" - the entire algorithm fits in 10 lines using Union-Find, demonstrating how the right data structure transforms a complex algorithm into a simple pattern.

---

### 🎓 Answers by Seniority

**Junior / Mid-level:**
Union-Find tracks which set each element belongs to. find(x) returns the root/representative of x's set. union(x, y) merges the sets of x and y. Two optimizations: union by rank (attach smaller tree under larger) + path compression (on find, redirect nodes directly to root). Together: amortized near-O(1) per operation. Classic use: cycle detection (union both endpoints; if already same set, cycle exists), Kruskal's MST.

**Senior / Staff-level:**
Union-Find with path compression and union by rank achieves O(alpha(n)) per operation - inverse Ackermann function, bounded by 4 for any n up to 10^80. This is the known optimal complexity for this problem. Practical extensions: weighted Union-Find (track additional data per set, e.g., set size, total weight); rollback Union-Find (for offline divide-and-conquer algorithms, use union by rank without path compression to enable O(log n) rollback). For distributed connectivity (billions of nodes across servers): partition graph into shards; within-shard Union-Find for local components; merge components across shards via a higher-level Union-Find on shard boundaries.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Union-Find handles both merge and split operations"**
Reality: Union-Find only supports merge (union). Splits are not supported. For dynamic connectivity with both additions and deletions, use a link-cut tree (O(log n) per operation) or offline algorithms.

**Misconception 2: "Path compression changes the logical set structure"**
Reality: path compression only changes which node serves as the "root" - the logical partition (which elements are in the same set) is unchanged. find(x) still returns the same root for all elements in the set.

**Misconception 3: "Union by rank uses actual tree height"**
Reality: rank is an upper bound on height that doesn't always equal actual height (path compression can reduce actual height without updating rank). Using actual height would require recomputation; rank is a sufficient upper bound that achieves the same asymptotic complexity.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Forgetting path compression**
- Symptom: Union-Find operations are O(log n) instead of near-O(1); large datasets timeout
- Cause: find() walks up tree without compressing the path
- Fix: add `parent[x] = find(parent[x])` to the find() recursive call

**Failure 2: Stack overflow on large input without path compression**
- Symptom: StackOverflowError on inputs with n > 10K when trees are deep
- Cause: recursive find() before path compression has flattened the tree
- Fix: use iterative two-pass path compression for large n

**Failure 3: Union-Find for problems with splits/disconnections**
- Symptom: incorrect results when edges are removed or sets need splitting
- Cause: Union-Find only supports merges; splits are not supported
- Fix: for offline problems with edge removals, reverse time (process deletions backwards as insertions); for online problems, use a link-cut tree

---

### 🎯 Interview Deep-Dive

| Timing | Questions |
|--------|-----------|
| Opening (0-2 min) | find, union, structure |
| Mid (2-8 min) | Optimizations, cycle detection |
| Deep-dive (8-15 min) | MST, scale, variants |

**[JUNIOR] Q1 - [CONCEPT] What problem does Union-Find solve and what are its two core operations?**

Union-Find solves the dynamic connectivity problem: given a set of elements that get grouped together over time, answer "are elements x and y in the same group?"

Two operations:
1. find(x): returns the representative (root) of x's group. Two elements are in the same group if and only if find(x) == find(y).
2. union(x, y): merges the groups containing x and y into one group.

The key constraint: groups can only merge, never split. Union-Find is optimal for this restricted scenario.

Classic example: social network friend groups. Initially everyone is their own "social circle." When two people become friends (union), their circles merge. Query: "are A and B in the same friend circle?" (find(A) == find(B)?).

*What separates good from great:* Explicitly stating the "no splits" constraint - Union-Find is specifically optimal for merge-only dynamics; other data structures are needed when elements can leave a group.

**[JUNIOR] Q2 - [CODING] Implement find() with path compression.**

```java
int find(int x) {
    if (parent[x] != x)
        parent[x] = find(parent[x]);
    return parent[x];
}
```

> **Code walkthrough:** Recursive find with path compression in 3 lines. The KEY MECHANISM: the recursive call finds the root, then the assignment parent[x] = find(parent[x]) runs on the return path, redirecting x directly to the root. WHY IT MATTERS: this single-line addition transforms O(log n) find into amortized O(alpha(n)) by flattening the tree lazily on every lookup. WHAT BREAKS: on pathological input (n > 50K, degenerate tree, first find call), the recursion depth equals tree height before any compression - risk of StackOverflowError. TAKEAWAY: use the recursive version for interviews (concise, correct); use the iterative two-pass version for production code with n > 10K to prevent stack overflow.

Without path compression: find(x) walks up the tree from x to root in O(height) time. For a chain of n elements, height = O(n).

With path compression: find(x) recursively finds the root AND sets parent[x] = root directly. Future finds on x take O(1). All nodes on the path from x to root get compressed.

The compression happens lazily - only the nodes on the current find path are compressed. Over time, repeated finds flatten the tree so thoroughly that the amortized cost per find approaches O(1).

The base case: if parent[x] == x, x is the root - return x.

*What separates good from great:* Explaining that the compression happens on the return path of the recursion (parent[x] = find(parent[x]) sets the parent AFTER the recursive call returns the root), not on the way down.

**[MID] Q3 - [DEBUGGING] Union-Find is giving wrong answers - some connected nodes appear disconnected. Diagnose.**

Most common cause: find() is called without path compression, and union() is called with wrong arguments. Specifically, union(x, y) must union the ROOTS of x and y - if you do parent[x] = y instead of parent[find(x)] = find(y), you break the tree structure.

Check 1: verify the union implementation makes roots point to roots: `parent[find(x)] = find(y)` not `parent[x] = y`.

Check 2: verify find() returns the root (parent[x] == x is the base case).

Check 3: check for off-by-one in node numbering. If nodes are 1-indexed but parent array is 0-indexed, accessing node n uses parent[n] which may be out of bounds.

Check 4: if using Union-Find for graph problems, verify that the node IDs match the indices used in the parent array.

Diagnostic: manually trace a small example. Union nodes 0,1,2 into one set via union(0,1), union(1,2). Call find(0) - should return the root. Call find(2) - should return the same root.

*What separates good from great:* Identifying the "union roots, not elements" bug as the most common implementation error - calling parent[x] = y instead of parent[find(x)] = find(y).

**[MID] Q4 - [CODING] How do you use Union-Find to detect a cycle in an undirected graph?**

Algorithm: for each edge (u, v), check if find(u) == find(v). If yes, adding this edge would connect two already-connected nodes - that is a cycle. If no, union(u, v) - they are newly connected.

```java
boolean hasCycle(int V, int[][] edges) {
    UnionFind uf = new UnionFind(V);
    for (int[] e : edges) {
        if (!uf.union(e[0], e[1]))
            return true; // cycle detected
    }
    return false;
}
```

> **Code walkthrough:** Cycle detection via Union-Find. The KEY MECHANISM: union() returns false when both endpoints are already in the same set - meaning there is already a path between them, and adding this edge would create a second path = a cycle. WHY IT MATTERS: this is O(E * alpha(E)) total - practically linear, much better than running DFS for each edge independently. WHAT BREAKS: this only detects cycles in UNDIRECTED graphs; for directed graphs, union(u,v) and union(v,u) are logically the same, so a directed A->B->A cycle would be correctly detected but the undirected/directed distinction must be understood. TAKEAWAY: for undirected cycle detection during offline edge processing, Union-Find is the idiomatic approach; for directed cycle detection, use DFS with 3-color state (WHITE/GRAY/BLACK).

union() returns false when the two nodes are already in the same set - meaning adding this edge creates a cycle. This replaces DFS-based cycle detection for offline edge processing.

Time complexity: O(E * alpha(E)) - nearly O(E).

Directed graph: Union-Find does NOT work for directed cycle detection. For directed graphs, use DFS with "in-current-path" coloring (white/gray/black).

*What separates good from great:* The important distinction: Union-Find cycle detection works for UNDIRECTED graphs only. For directed graphs, DFS with 3-color marking is required - a common interview follow-up.

**[MID] Q5 - [TRADE-OFF] Compare Union-Find with DFS/BFS for connectivity queries.**

DFS/BFS for single connectivity query: O(V + E). Precompute all connected components: O(V + E). Query "are u and v connected?": O(1) after precomputation (same component ID).

Union-Find for dynamic connectivity: O(alpha(n)) per union or query. Handles online edge insertions efficiently.

Choose DFS/BFS when: static graph (no edge insertions), need to enumerate connected components explicitly, need shortest path not just connectivity.

Choose Union-Find when: graph builds incrementally (edges added one by one), only connectivity queries (not paths), processing E edges in batch (Kruskal's MST, offline connectivity).

At scale: DFS on a graph with 10M nodes takes O(10M) time and O(10M) stack space. Union-Find processes 10M edges in O(10M * alpha(10M)) = effectively O(10M) with O(n) space.

*What separates good from great:* Knowing Union-Find's advantage is specifically for incremental edge insertion - if the graph is static, precompute connected components with DFS and answer queries in O(1).

**[SENIOR] Q6 - [PRODUCTION] How is Union-Find used in distributed systems for partition detection?**

Distributed systems use Union-Find patterns for detecting network partitions (which servers are still connected?) and merging clusters.

Shard-based approach: partition nodes across servers. Each server maintains Union-Find for its local nodes. For edges within a shard, union locally. For cross-shard edges, send a "merge component" message to both shards.

Coordination: a coordinator periodically merges cross-shard information. Each shard's root node is reported to the coordinator; the coordinator runs Union-Find on shard-level roots to determine global components.

Example - Cassandra ring healing: when a node rejoins after a partition, gossip protocol propagates connectivity information. Each node maintains local Union-Find; when gossip arrives with information about a new connection, it unions the relevant components.

Challenge: distributed Union-Find must handle: concurrent updates from multiple sources, network partitions during the union operation itself, and consistency vs. availability trade-off.

*What separates good from great:* Knowing the Cassandra gossip-based healing pattern and explaining the two-level Union-Find (local shard Union-Find + coordinator-level Union-Find on component representatives).

**[SENIOR] Q7 - [SYSTEM] Design an "online judge" system that checks if two users share the same "hacker group" (connected through shared submissions).**

Requirements: 10M users. A "connection" is formed when two users submit identical code. Dynamic - new connections form in real time. Query: "are user A and user B in the same hacker group?"

Data model: submissions stream; for each pair of users submitting identical code (detected via code hashing), union the two users.

Union-Find for 10M users: parent[10M] + rank[10M] = 80MB. Fits in RAM.

Identical submission detection: hash each submission (SHA-256 of normalized code). Store HashMap<hash, List<userId>>. When a new submission arrives, look up its hash - union with all previous submitters with the same hash.

Scaling: 10M users with 1M submissions/day = ~12 submissions/second. Each submission: O(1) hash lookup + O(alpha(10M)) union per matching pair. Easily single-threaded.

Persistence: persist parent[] and rank[] arrays to disk after each batch for recovery. Union operations are idempotent - replay from log to reconstruct.

Query API: connected(userA, userB) = find(userA) == find(userB). O(alpha(n)) per query.

*What separates good from great:* The exact architecture: submission -> normalize -> hash -> HashMap lookup -> Union-Find union, and knowing that this is the real-world pattern used by online judges.

**[STAFF] Q8 - [ARCHITECTURE] How does Union-Find enable parallel graph processing at scale?**

For graphs with billions of edges distributed across machines, Union-Find-based connected components is parallelizable.

Parallel algorithm (Soman et al. 2010):
1. Partition edges across P processors
2. Each processor runs local Union-Find on its edge partition
3. Merge: compare component roots across processors; for cross-processor edges (one endpoint in each processor's set), union the corresponding roots
4. Iterate until no more merges are needed

Convergence: O(log D) iterations where D is graph diameter. Each iteration reduces the number of distinct components.

MapReduce formulation: Map phase assigns edges to shards by hash(min(u,v)). Reduce phase runs local Union-Find per shard. Cross-shard merges handled in a subsequent round. Multiple rounds converge to correct global components.

Used in: Apache Spark GraphX ConnectedComponents, Pregel's vertex-centric connected components, Facebook TAO for social graph partition analysis.

Key insight: Union-Find is a "embarrassingly parallelizable" algorithm because local merges are independent; only cross-boundary merges require coordination.

*What separates good from great:* Knowing the Soman parallel algorithm and the MapReduce formulation, and explaining why Union-Find parallelizes better than DFS (which has sequential path dependencies).

**[STAFF] Q9 - [THEORY] Prove that alpha(n) = O(1) for practical purposes and explain the inverse Ackermann function.**

The Ackermann function A(m, n) grows extremely fast:
- A(0, n) = n + 1
- A(1, n) = n + 2
- A(2, n) = 2n + 3
- A(3, n) = 2^(n+3) - 3
- A(4, n) = tower of 2s of height n+3

The inverse Ackermann alpha(n) = min{k : A(k,k) >= n}. For any n that could ever be represented in the physical universe:
- n <= 10^(10^23): alpha(n) <= 4

In practice: alpha(n) <= 4 for all n a computer could encounter. This is why we say "nearly O(1)."

The formal complexity of Union-Find with path compression and union by rank: Tarjan and van Leeuwen (1984) proved the amortized cost per operation is O(alpha(n)). This is TIGHT - Fredman and Saks (1989) proved O(alpha(n)) is the optimal amortized bound for this problem (cannot do better with a comparison-based approach).

Why it matters in practice: at n=10^9 operations, the constant factor of alpha(n)=4 means the algorithm takes 4 * 10^9 "comparison steps" - practically identical to O(1) amortized.

*What separates good from great:* Stating the Tarjan/van Leeuwen result is optimal (proved by Fredman and Saks) - Union-Find with both optimizations is known optimal; no further improvement is possible with comparison-based approaches.

---

### ⚖️ Comparison Table

| Operation | Union-Find | DFS/BFS | Sorted Sets | Adjacency Matrix |
|-----------|------------|---------|-------------|------------------|
| Check connected | O(alpha(n)) | O(V+E) precomp | O(1) precomp | O(1) |
| Union two sets | O(alpha(n)) | O(V+E) rebuild | O(n) | O(n) relabel |
| Find set members | O(n) scan | O(component) | O(component) | O(V) |
| Dynamic add edge | O(alpha(n)) | O(V+E) rebuild | O(n) rebuild | O(1) |
| Space | O(n) | O(V+E) | O(n) | O(V^2) |
| Supports splits | No | Yes | Yes | Yes |
| Best for | Incremental merges | Path queries | Static groups | Dense+static |

---

### 🏛️ System Design

*(Omit: not applicable as standalone system design - Union-Find is a component. See Senior Q7 for the online judge hacker group detection system design and Staff Q8 for the parallel graph processing architecture.)*

---

### 📊 Diagram

```
Union-Find with path compression example:

Initial: parent=[0,1,2,3,4,5]

union(0,1): parent=[1,1,2,3,4,5]
union(2,3): parent=[1,1,3,3,4,5]
union(4,5): parent=[1,1,3,3,5,5]
union(1,3): parent=[1,3,3,3,4,5]

     3
    /|\
   1  2  (3 is root of {0,1,2,3})
  /
 0

find(0) with path compression:
0 -> 1 -> 3 (root found)
path compression: parent[0]=3, parent[1]=3

After: parent=[3,3,3,3,4,5]
     3
   / | \
  0  1  2

Next find(0): 0 -> 3 (direct, O(1))
```

> **Diagram walkthrough:** Union-Find construction and path compression effect. After four unions, the tree has root 3 with 0->1->3 path for element 0. When find(0) is called: traversal goes 0->1->3, finds root 3. On the return path, parent[0] and parent[1] are both updated to 3. Future finds on 0 or 1 go directly to root in one step. The key relationship: path compression makes every node a direct child of the root after its first find - the tree becomes flat. Edge case: path compression doesn't update rank - rank[1] still reflects the pre-compression height, which is fine because rank is only an upper bound. Insight: after enough find operations, virtually all nodes point directly to their root; the tree is maximally flat and all operations are effectively O(1).
