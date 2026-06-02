---
layout: default
title: "Data Structures - L2 Trees"
parent: "Data Structures"
nav_order: 4
permalink: /data-structures/l2-trees/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 1 | [Binary Search Trees](#binary-search-trees) | critical |
| 2 | [AVL Trees and Tree Balancing](#avl-trees-and-tree-balancing) | high |

---

# Binary Search Trees

**Difficulty:** ★★☆

**Interview Weight:** Critical

---

### 🎯 Model Answer

**30 seconds:**
A Binary Search Tree is a binary tree where every node satisfies the BST invariant: all values in the left subtree are less than the node, and all values in the right subtree are greater. This enables O(log n) average-case search, insert, and delete by eliminating half the tree at each step. The critical weakness: a BST degrades to O(n) on sorted input because all nodes chain right - balance is required for production use.

**3 minutes:**
A BST is the tree equivalent of binary search. Binary search on a sorted array is O(log n) because you halve the search space each step. A BST achieves the same on a dynamic, modifiable dataset. The BST invariant encodes sorted order structurally - in-order traversal always yields sorted output.

BST performance is entirely driven by tree height. A perfectly balanced BST on n nodes has height log(n) - all operations run O(log n). Insert sorted input [1,2,3,4,5] and the tree degenerates to a right-skewed linked list with height n - every operation becomes O(n). This is why Java's TreeMap uses a Red-Black Tree and not a plain BST.

For interview purposes: know the BST invariant and how to verify it recursively; implement search, insert, delete (delete has three cases: leaf, one child, two children); in-order traversal produces sorted order; validate BST requires passing min/max range down recursively - not just parent comparison.

**Blank Mind Recovery:**
**(1) Restate:** "BST: left subtree values less than node value, right subtree values greater."
**(2) Core insight:** "Halve the search space at each level - O(log n) average."
**(3) Critical failure:** "Sorted insertion gives O(n) height - that is why balanced BSTs exist."
**(4) One code pattern:** "Validate BST: pass a min/max range down recursively - not just parent comparison."

---

### 📘 Concept Explanation

**What it is:**
A Binary Search Tree is a rooted binary tree satisfying the BST invariant: for every node N, all values in N's left subtree are strictly less than N's value, and all values in N's right subtree are strictly greater.

**The problem it solves:**
Arrays offer O(1) access by index but O(n) search by value. Sorted arrays enable O(log n) search but O(n) insert/delete. A BST offers O(log n) for search, insert, and delete simultaneously - right when you need all three operations on a dynamic ordered dataset.

**How it works:**

```
        8
       / \
      3   10
     / \    \
    1   6    14
       / \   /
      4   7 13
```

> **Diagram walkthrough:** A valid BST with root 8. Left subtree {1,3,4,6,7} are all less than 8; right subtree {10,13,14} are all greater. To find 6: start at 8, go left (6 less than 8), reach 3, go right (6 greater than 3), reach 6 - found in 3 comparisons. The key relationship: at each node, the BST invariant eliminates an entire subtree from consideration. Edge case: the BST invariant must hold for ALL descendants, not just immediate children - a common bug is checking only parent-child comparison. Insight: in-order traversal yields 1,3,4,6,7,8,10,13,14 - perfectly sorted, proving the BST encodes sort order structurally.

**Core operations:**

```java
public class BST<T extends Comparable<T>> {
    private Node<T> root;

    static class Node<T> {
        T value;
        Node<T> left, right;
        Node(T v) { this.value = v; }
    }

    // Search - O(h) where h = tree height
    public boolean contains(T value) {
        Node<T> curr = root;
        while (curr != null) {
            int cmp = value.compareTo(curr.value);
            if (cmp == 0) return true;
            curr = cmp < 0 ? curr.left : curr.right;
        }
        return false;
    }

    // Insert - O(h)
    public void insert(T value) {
        root = insertRec(root, value);
    }
    private Node<T> insertRec(Node<T> n, T val) {
        if (n == null) return new Node<>(val);
        int cmp = val.compareTo(n.value);
        if (cmp < 0)
            n.left = insertRec(n.left, val);
        else if (cmp > 0)
            n.right = insertRec(n.right, val);
        return n; // duplicate: ignore
    }

    // Delete - O(h), three cases
    public void delete(T value) {
        root = deleteRec(root, value);
    }
    private Node<T> deleteRec(Node<T> n, T val) {
        if (n == null) return null;
        int cmp = val.compareTo(n.value);
        if (cmp < 0)
            n.left = deleteRec(n.left, val);
        else if (cmp > 0)
            n.right = deleteRec(n.right, val);
        else {
            // Case 1 & 2: zero or one child
            if (n.left == null) return n.right;
            if (n.right == null) return n.left;
            // Case 3: two children
            // Replace with in-order successor
            Node<T> succ = findMin(n.right);
            n.value = succ.value;
            n.right = deleteRec(n.right, succ.value);
        }
        return n;
    }
    private Node<T> findMin(Node<T> n) {
        while (n.left != null) n = n.left;
        return n;
    }
}
```

> **Code walkthrough:** Complete generic BST with all three operations. The KEY MECHANISM in delete: the two-children case replaces the deleted node's value with its in-order successor (minimum of right subtree), then deletes the successor from the right subtree recursively. The successor has at most one child (it is the leftmost node) so the recursive delete hits the zero/one-child case. WHY IT MATTERS: the in-order successor is the only valid replacement - it is greater than all left subtree values and less than all other right subtree values by definition, preserving the BST invariant. WHAT BREAKS: using max of left subtree works too but requires consistent choice - mixing strategies or forgetting the recursive delete of the replaced node leaves a duplicate in the tree. TAKEAWAY: the two-children delete is the most complex operation in the BST; a candidate who explains it fluently with the invariant reasoning stands out.

**BST Validate - the classic interview trap:**

```java
// BAD: checks only immediate parent-child pairs
boolean validateBad(Node<Integer> node) {
    if (node == null) return true;
    if (node.left != null
        && node.left.value > node.value)
        return false;
    if (node.right != null
        && node.right.value < node.value)
        return false;
    return validateBad(node.left)
        && validateBad(node.right);
}
// Fails on: [5,1,4,null,null,3,6]
//     5
//    / \
//   1   4   <- 4 < 5 OK locally
//      / \
//     3   6  <- 3 < 5 VIOLATED globally

// GOOD: pass valid range down recursion
boolean validate(
    Node<Integer> node,
    Integer min,
    Integer max
) {
    if (node == null) return true;
    if (min != null && node.value <= min)
        return false;
    if (max != null && node.value >= max)
        return false;
    return validate(node.left, min, node.value)
        && validate(
            node.right, node.value, max
        );
}
// Initial call: validate(root, null, null)
```

> **Code walkthrough:** The BST validation trap - one of the most commonly failed interview coding problems. The KEY MECHANISM: the BAD version approves node 4 in the right subtree of 5 because 4 < 5 passes locally; it fails to check that 3 (in 4's left subtree) violates 3 < 5. The GOOD version threads min/max bounds: right child inherits min=parent.value, left child inherits max=parent.value - creating a "valid value corridor" that narrows at each level. WHY IT MATTERS: this exact bug has appeared in production BST validation code at major companies. WHAT BREAKS: using int primitives forces sentinel values (Integer.MIN/MAX_VALUE) which are fragile for keys that might actually equal sentinel values - Integer allows null for "unbounded". TAKEAWAY: any tree invariant involving ancestors (not just parent) requires threading that constraint down the recursion as an explicit parameter.

**When to use:**
- Dynamic ordered set/map with mixed insert/delete/search
- Need in-order traversal of data in sorted order
- As a teaching tool; NOT for production plain BST

**When NOT to use:**
- Sequential or sorted insertions - use balanced BST variants
- Read-only sorted data - sorted array has better cache behavior
- Concurrent access - use ConcurrentSkipListMap

---

### 💻 Code Example

**Production Example: range search for ordered index**

```java
// Find all values in [lo, hi] - O(log n + k)
// k = number of results
// Core operation for autocomplete, window queries
<T extends Comparable<T>> void rangeSearch(
    Node<T> node, T lo, T hi,
    List<T> result
) {
    if (node == null) return;
    int cmpLo = lo.compareTo(node.value);
    int cmpHi = hi.compareTo(node.value);
    // Recurse left only if lo <= node.value
    if (cmpLo < 0)
        rangeSearch(node.left, lo, hi, result);
    // Include this node if in range
    if (cmpLo <= 0 && cmpHi >= 0)
        result.add(node.value);
    // Recurse right only if hi >= node.value
    if (cmpHi > 0)
        rangeSearch(node.right, lo, hi, result);
}
// prefix search: lo="app", hi="apq" (exclusive)
// Returns: ["app","apple","application","apply"]
```

> **Code walkthrough:** BST range search - the defining advantage over hash tables. The KEY MECHANISM: only recurse into subtrees that can contain results - if lo is greater than node.value, the entire left subtree is less than lo and can be skipped. WHY IT MATTERS: O(log n + k) complexity where k is the number of matches - only the matched elements plus the navigation path. A HashMap cannot answer range queries without scanning all keys (O(n)). WHAT BREAKS: an off-by-one in the comparisons (using less-than instead of less-than-or-equal for range endpoints) misses boundary values in the result. TAKEAWAY: range queries are the killer feature that justifies BSTs over hash tables; any ordering-based query is naturally O(log n + k) in a BST.

**Failure Example: sequential insert degrades to O(n)**

```java
// BAD: plain BST with sequential IDs
BST<Integer> idx = new BST<>();
// Auto-increment IDs: 1, 2, 3, ..., 1_000_000
for (int id = 1; id <= 1_000_000; id++) {
    idx.insert(id); // right-skewed chain!
}
// Every search for id=999_999 requires
// ~999_999 comparisons. 100ms per search.

// GOOD: TreeMap uses Red-Black Tree
TreeMap<Integer, Record> idx = new TreeMap<>();
for (int id = 1; id <= 1_000_000; id++) {
    idx.put(id, records.get(id));
}
// Search for id=999_999: 20 comparisons. < 1ms.
```

> **Code walkthrough:** The silent production disaster of plain BSTs with sorted input. The KEY MECHANISM: integer auto-increment IDs are sorted - each new ID becomes the rightmost leaf, building a right-skewed chain of height n. WHY IT MATTERS: this is the NORMAL case in production, not an edge case - most databases use auto-increment primary keys, and most imports are sorted by ID. WHAT BREAKS: 1 million sequential inserts take O(1M) time each for searches near the end of the list. TAKEAWAY: never use a plain BST for production data; always use TreeMap (Red-Black) or similar self-balancing structure.

---

### 🎓 Answers by Seniority

**Junior / Mid-level:**
BST invariant: left subtree values less than node, right subtree values greater, recursively. Enables O(log n) average search by halving search space at each level. Operations are O(h) where h is tree height. Balanced: h = O(log n). Sorted input: h = O(n). Delete has three cases - leaf (remove), one child (replace), two children (replace value with in-order successor then delete successor from right subtree).

**Senior / Staff-level:**
Production decision: plain BST never. TreeMap (Red-Black) for in-memory ordered data with dynamic modifications. B-Tree for disk-based storage - branching factor 1000 means only 3 disk I/Os for 1 billion records vs. 30 for an AVL tree. Decision framework: in-memory + ordered + dynamic = TreeMap; disk-based + ordered + range queries = B-Tree; unordered + fast exact lookup = HashMap; write-heavy append + range queries = LSM-Tree (RocksDB/Cassandra).

---

### ⚠️ Common Misconceptions

**Misconception 1: "BST guarantees O(log n) operations"**
Reality: BST guarantees O(log n) ONLY when balanced. Sorted insertion creates O(n) height. The guarantee requires a self-balancing tree (AVL, Red-Black).

**Misconception 2: "Validate BST by checking each node against its parent"**
Reality: BST validation requires global min/max constraints propagated down the recursion. Parent-only comparison approves invalid trees like [5,1,4,null,null,3,6].

**Misconception 3: "Delete is easy once you know insert"**
Reality: Delete has three cases; the two-children case (replace with in-order successor and recursively delete it) is subtle and the most common bug source in BST implementations.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Height explosion on sorted input**
- Symptom: operations that were O(ms) become O(seconds) after data load
- Cause: auto-increment IDs or alphabetically sorted imports create a right-skewed chain
- Diagnosis: measure tree height vs. log(n); height near n confirms degeneration
- Fix: switch to TreeMap (Red-Black Tree)

**Failure 2: BST invariant violation from mutable keys**
- Symptom: TreeMap lookups return null for keys that were successfully inserted
- Cause: key object's compareTo() changed after insertion (mutable state)
- Diagnosis: add logging to compareTo(); check for value changes after insertion
- Fix: use only immutable objects as BST/TreeMap keys

**Failure 3: Wrong BST validation algorithm fails in production**
- Symptom: validation passes for known-valid trees but also passes for [5,1,4,null,null,3,6]
- Cause: parent-only comparison check instead of global min/max range check
- Fix: pass explicit min/max bounds through the validation recursion

**Failure 4: Concurrent modification breaks BST invariant**
- Symptom: ConcurrentModificationException or lost updates under concurrent access
- Cause: plain BST is not thread-safe
- Fix: use ConcurrentSkipListMap for concurrent sorted map access

---

### 🎯 Interview Deep-Dive

| Timing | Questions |
|--------|-----------|
| Opening (0-2 min) | BST invariant, search |
| Mid (2-8 min) | Operations, validate trap |
| Deep-dive (8-15 min) | Production trade-offs, scale |

**[JUNIOR] Q1 - [CONCEPT] What is the BST invariant and why does it enable efficient search?**

The BST invariant: for every node N, all values in N's left subtree are strictly less than N's value, and all values in N's right subtree are strictly greater. This must hold recursively for every node - not just the parent-child relationship.

This invariant enables O(log n) search by eliminating half the search space at each step. If the target is less than the current node, the entire right subtree is irrelevant - it contains only values greater than the current node by the invariant. This halving produces O(log n) on a balanced tree.

In-order traversal (left, root, right) always produces ascending sorted output - the tree structure encodes sorted order.

*What separates good from great:* Immediately adding the caveat "this is O(log n) average, O(n) worst case on sorted input - which is why production systems use balanced BSTs like TreeMap."

**[JUNIOR] Q2 - [CODING] Walk me through the three cases of BST delete.**

Case 1 - Leaf node (no children): remove by setting the parent's pointer to null. The parent's link to this node becomes null.

Case 2 - One child: replace the node with its single child. The grandparent now points to the child directly.

Case 3 - Two children: find the in-order successor - the leftmost node in the right subtree (smallest value greater than the deleted node). Copy the successor's value into the deleted node. Then recursively delete the successor from the right subtree. The successor has at most one child (it is the leftmost, so no left child) - so the recursive delete hits case 1 or 2.

Why the in-order successor? It is greater than all left subtree values (it came from the right subtree) and less than all other right subtree values (it was the minimum of the right subtree). Both halves of the BST invariant at the deleted position are satisfied.

*What separates good from great:* Explaining WHY the in-order successor maintains BST invariants and noting that the in-order predecessor (maximum of left subtree) works equally well.

**[MID] Q3 - [DEBUGGING] Your TreeMap intermittently returns null for keys that are definitely in the map. What are the causes?**

The primary cause is mutable keys. TreeMap uses compareTo() to navigate the internal Red-Black BST at insert time. If a key's compareTo() value changes after insertion, the key is stored at the "wrong" position based on its value at insert time. Future lookups navigate using the current compareTo() value, arrive at a different position in the tree, find nothing, and return null.

Diagnostic steps:
1. Add logging to the key's compareTo() method - log both the caller and return value
2. Check whether the same logical object returns different compareTo() values at different times
3. Look for mutable fields in the key class (dates, counters, mutable strings)

Common culprits: Date objects mutated after insertion; domain objects with fields that change (balance, status, name); objects with @EqualsAndHashCode on mutable fields.

Fix: use only immutable objects as TreeMap keys. For mutable domain objects, use an immutable identifier (Long ID or UUID) as the key.

*What separates good from great:* Describing the exact mechanism - the key was placed at position X based on compareTo() at insert time; the key's compareTo() value changed; future lookups navigate to position Y where the key does not exist.

**[MID] Q4 - [TRADE-OFF] When does a plain BST beat alternatives?**

Plain BST wins in two narrow scenarios:

Bulk-loaded read-only workload: load from randomly shuffled data, then search only. Expected height on random input is O(log n) with a small constant, comparable to balanced BST but without rotation overhead. The random input eliminates the adversarial degeneration case.

Competitive programming with time constraints: plain BST is 30 lines vs. 150 for AVL. In timed contests with guaranteed non-adversarial input, simplicity wins.

In production: never. The O(n) worst case is unacceptable for user-facing systems. Even "probably random" input is not worth the risk - one sorted batch import triggers the O(n) case.

A practical middle ground: treap (BST + random heap priorities). Expected O(log n) with simpler implementation than AVL because randomization prevents adversarial cases without the complexity of full rotation bookkeeping.

*What separates good from great:* Knowing about treaps as the practical middle ground and explaining that the adversarial case (sorted input) is the NORMAL case in production with auto-increment IDs.

**[MID] Q5 - [SYSTEM] How would you implement an in-memory leaderboard using a BST?**

Use TreeMap<Integer, Set<String>> mapping score to the set of players with that score. TreeMap provides O(log n) insert/update, O(log n) floor/ceiling for nearest scores, and O(k + log n) for top-K by iterating from the maximum backwards using descendingKeySet().

Rank computation requires augmentation: store subtree size at each node. With augmentation, rank(player) = count of nodes with score greater than player.score. Java's TreeMap does not support augmentation directly - you would need a custom Red-Black tree or an order-statistics tree.

Alternative - Redis Sorted Set: uses a skip list internally. O(log n) for all operations including rank queries (ZRANK command), with native range query support (ZRANGEBYSCORE). For most leaderboard systems, Redis Sorted Set is the production choice - it handles the augmentation requirement natively.

*What separates good from great:* Knowing that augmentation (subtree size at each node) is required for O(log n) rank queries, and knowing Redis Sorted Sets use a skip list under the hood with native ZRANK support.

**[SENIOR] Q6 - [PRODUCTION] You need an in-memory ordered index for a microservice. How do you choose the data structure?**

Start with the access pattern - what queries does this index serve?

Exact-match only: HashMap. O(1) amortized, simpler, lower overhead than BST. The default choice.

Range, floor/ceiling, sorted iteration: TreeMap. O(log n) for all operations. 3 to 5 times slower than HashMap on random access but negligible unless doing millions of lookups per second.

Rank queries (kth smallest, percentile calculations): augmented BST or order-statistics tree. TreeMap does not support rank natively - need custom implementation or Guava's RangeMap.

Dataset exceeding RAM: move to B-Tree or LSM-Tree at the storage layer.

Concurrent access: ConcurrentSkipListMap over synchronized TreeMap. Skip list's lock-free concurrent implementation scales far better than a global lock.

*What separates good from great:* Asking "what queries does this index serve?" before choosing - framing the decision as driven by access patterns, not just "which is faster."

**[SENIOR] Q7 - [DEBUGGING] BST in-order traversal produces incorrect sorted output. How do you diagnose?**

Two possible root causes: wrong traversal order, or BST invariant violation.

Traversal check: in-order = left subtree first, then node, then right subtree. A common bug is implementing pre-order (node before left) or mixing the order. Print "visiting node X" in the traversal method and trace the call sequence.

BST invariant check: run the min/max validation algorithm. If it reports a violation, find the first node where the invariant breaks - this is where the BST was corrupted.

Trace test: insert known values [5,3,7,1,4,6,8], run in-order traversal, verify output is [1,3,4,5,6,7,8]. Any out-of-order pair points to a specific structural violation.

Most common production cause: mutable keys. A domain object used as a TreeMap key gets modified after insertion (name change, score update) - this changes its compareTo() position and silently breaks the BST invariant. In-order traversal then visits nodes in the "stored" order which no longer matches the "current" compareTo() order.

*What separates good from great:* Immediately identifying mutable keys as the primary production cause rather than just concluding "the traversal algorithm is wrong."

**[STAFF] Q8 - [ARCHITECTURE] How do major databases use BST variants at the storage layer?**

Production databases do not use in-memory BSTs for primary storage - they use disk-optimized variants.

B-Trees (PostgreSQL, MySQL, MongoDB indexes): each node contains hundreds of keys filling one disk page (4KB or 16KB). With branching factor 1000, height for 1 trillion records is 4. Maximum 4 disk I/Os per search. Each I/O reads one full node worth of keys, maximizing work per I/O.

LSM-Trees (RocksDB, Cassandra, LevelDB): buffer writes in an in-memory balanced BST (MemTable - typically a Red-Black Tree), then flush to sorted immutable SSTable files on disk. Reads merge multiple sorted files. Writes are fast because MemTable writes are O(log n) in-memory and flushed sequentially to disk. Periodic compaction merges SSTables to maintain read performance.

Decision: B-Tree for read-heavy with small updates (OLTP); LSM-Tree for write-heavy (time series, logging, event sourcing).

*What separates good from great:* Explaining why B-Trees are disk-optimized (node size equals disk page size, maximizing keys searchable per I/O) and why LSM-Trees were invented (B-Tree random write amplification is too slow for write-heavy workloads at scale).

**[STAFF] Q9 - [SCALE] Design a distributed ordered index for 10 billion records.**

A single in-memory BST is impossible at this scale (10 billion integers alone is 80GB+). A single B-Tree has lock contention and storage limits.

Architecture: shard by key range. Divide the key space into N shards; each shard owns a contiguous range and maintains its own B-Tree. Route queries to the correct shard based on key value.

Shard boundary meta-index: store (shard_id, min_key, max_key) for all shards in a small in-memory BST or sorted array. This is HBase's .META. table pattern - a meta-index pointing to the actual data shards.

Distributed range queries: fan out to all relevant shards based on the meta-index, collect sorted results from each, merge with a priority queue. O(k * log n) total where k is shards touched.

Operational challenges: shard rebalancing when keys cluster (hot shards on sequential IDs); cross-shard range queries requiring coordination; consistent ordering under network partitions; leader election per shard for availability.

Real-world: Google Bigtable (tablet servers with B-Trees per tablet), HBase (region servers), CockroachDB (ranges with Raft replication per range).

*What separates good from great:* Recognizing the recursive meta-index challenge - you need an ordered index just to locate which shard holds a given key range, and that meta-index itself may need sharding at extreme scale.

---

### ⚖️ Comparison Table

| Property | Plain BST | AVL Tree | Red-Black Tree | B-Tree |
|----------|-----------|----------|----------------|--------|
| Search worst case | O(n) | O(log n) | O(log n) | O(log n) |
| Insert worst case | O(n) | O(log n) | O(log n) | O(log n) |
| Balance guarantee | None | height diff <= 1 | Color rules | Branching factor |
| Rotation overhead | None | O(log n) inserts | Max 2 rotations | None |
| Max height | O(n) | 1.44 log n | 2 log n | log_B(n) |
| Best for | Controlled input | Read-heavy | General in-memory | Disk storage |
| Java equivalent | Manual | Manual | TreeMap/TreeSet | Not in JDK |

---

### 🏛️ System Design

**Ordered In-Memory Cache with Range Query:**

```
HTTP Requests
     |
     v
+--------------------+
| Cache Layer        |
| TreeMap<CacheKey,  |
|   CacheEntry>      |
|                    |
| get(k): O(log n)   |
| put(k,v): O(log n) |
| subMap(lo,hi):     |
|   O(log n + k)     |
+--------------------+
     |
     v (cache miss only)
+--------------------+
| Database           |
+--------------------+
```

> **Diagram walkthrough:** A read-through cache backed by TreeMap for ordered key access. TreeMap sits between clients and the database, serving exact-match and range lookups from memory. On a cache hit, requests return O(log n) from TreeMap without touching the database. The key relationship: TreeMap preserves key ordering, enabling range queries like "all cache entries for user X between timestamps T1 and T2." Edge case: eviction policy must account for range access patterns - a pure LRU heap does not support range queries efficiently alongside eviction ordering. Insight: for caches that need both fast exact lookup AND range queries, TreeMap is the natural choice; for pure LRU with no range queries, LinkedHashMap (insertion-order HashMap) is simpler.

---

### 📊 Diagram

BST search path vs. degeneration on sorted input:

```
Balanced BST (h ~ log n):

        8
       / \
      3   10
     / \    \
    1   6    14
       / \
      4   7
Search for 6: 8->3->6 (3 steps)

Degenerate BST (sorted input 1,2,3,4,5):

1
 \
  2
   \
    3
     \
      4
       \
        5
Search for 5: 1->2->3->4->5 (5 steps)
```

> **Diagram walkthrough:** Two BSTs with the same elements but different insertion orders. Left: balanced structure with height 3, search takes 3 comparisons. Right: sorted insertion creates a right-skewed chain with height n, search requires n comparisons. The key relationship: same BST algorithm, radically different performance based purely on insertion order. Edge case: the degenerate case is exactly what happens with auto-increment primary keys in production - sequential insertion is normal, not adversarial. Insight: a senior engineer sees the right diagram and immediately asks "what is the insertion order in production?" because the answer determines whether any BST-based solution is safe.

---

---

# AVL Trees and Tree Balancing

**Difficulty:** ★★☆

**Interview Weight:** High

---

### 🎯 Model Answer

**30 seconds:**
An AVL tree is a self-balancing BST where the height difference between the left and right subtrees of any node (the balance factor) is at most 1. After every insert or delete, the tree performs rotations to restore this invariant, guaranteeing O(log n) height always. The cost: constant rotation overhead per operation. The guarantee: O(log n) for all operations regardless of insertion order.

**3 minutes:**
The motivation for AVL trees is the catastrophic O(n) worst case of plain BSTs. The AVL invariant - balance factor in {-1, 0, 1} at every node - limits tree height to at most 1.44 log n, guaranteeing O(log n) for all operations.

The key mechanism is rotations. When an insert or delete creates an imbalance (balance factor becomes plus or minus 2), the tree performs one of four rotation patterns: single right rotation for the LL case (unbalanced node and its heavy child both lean left), single left rotation for the RR case, left-right double rotation for the LR case (bent left-right imbalance), right-left double rotation for the RL case (bent right-left imbalance). Rotations are O(1) pointer operations that restructure the tree locally without violating BST order.

AVL trees are stricter than Red-Black Trees (balance factor at most 1 vs. at most 2 log n for Red-Black). This makes AVL lookups slightly faster but AVL inserts slightly slower. In practice, Red-Black Trees are used for general-purpose sorted maps (Java's TreeMap) while AVL Trees excel in read-heavy workloads.

**Blank Mind Recovery:**
**(1) Restate:** "AVL: BST where |left height minus right height| is at most 1 at every node."
**(2) Core insight:** "This guarantees height at most 1.44 log n, preventing the O(n) degeneration of plain BST."
**(3) Key operation:** "After insert/delete, walk up updating balance factors and rotate where factor becomes plus or minus 2."
**(4) Four cases:** "LL (right rotate), RR (left rotate), LR (left-rotate child then right-rotate root), RL (right-rotate child then left-rotate root)."

---

### 📘 Concept Explanation

**What it is:**
An AVL tree (Adelson-Velsky and Landis, 1962) is a BST augmented with a balance factor at each node: height(left_subtree) - height(right_subtree). The AVL invariant: this factor must be -1, 0, or +1 at every node. After any modification, rotations restore this invariant.

**The problem it solves:**
Plain BSTs have O(n) worst-case on sorted input. AVL trees trade constant rotation overhead per modification for a strict O(log n) height guarantee - the first self-balancing BST in computer science history.

**The four rotation cases:**

```
LL case: z left-heavy (+2), y left-heavy (+1)
   z[+2]           y
   /     rotateR  / \
  y[+1]  ====>  x   z
 /
x

RR case: z right-heavy (-2), y right-heavy (-1)
z[-2]              y
  \     rotateL   / \
  y[-1] ====>   z   x
    \
     x

LR case: z left-heavy (+2), y right-heavy (-1)
  z[+2]     z[+2]         x
  /    rotL   /    rotR   / \
y[-1] ===> x[+1] ===>  y   z
  \        /
   x      y

RL case: z right-heavy (-2), y left-heavy (+1)
z[-2]        z[-2]            x
  \    rotR    \     rotL     / \
  y[+1] ===>  x[-1] ===>   z   y
 /               \
x                 y
```

> **Diagram walkthrough:** All four AVL imbalance cases following an insert. Each z is the first unbalanced ancestor (balance factor reaching plus or minus 2). The numbers in brackets are balance factors. LL and RR are "straight" imbalances - the heavy path goes consistently in one direction, fixed by a single rotation. LR and RL are "bent" imbalances - the path zigzags, requiring two rotations: the first rotation straightens the bend into an LL or RR case, then the second rotation fixes the LL or RR. The key relationship: both the unbalanced node's balance factor AND its heavy child's balance factor signs determine which case applies - same signs (LL/RR) = one rotation; opposite signs (LR/RL) = two rotations. Edge case: after a double rotation the new subtree root's balance factor is 0, meaning the height of this subtree decreased by 1, which can trigger further rebalancing higher up during delete. Insight: all four rotations preserve BST in-order sequence - the structural rewiring never changes the relative ordering of any two nodes.

**AVL insert implementation:**

```java
class AVLTree {
    static class Node {
        int val, height;
        Node left, right;
        Node(int v) { val = v; height = 1; }
    }
    Node root;

    int height(Node n) {
        return n == null ? 0 : n.height;
    }
    int balanceFactor(Node n) {
        return n == null
            ? 0 : height(n.left) - height(n.right);
    }
    void updateHeight(Node n) {
        n.height = 1
            + Math.max(height(n.left),
                       height(n.right));
    }

    // LL case: right rotate at z
    Node rotateRight(Node z) {
        Node y = z.left;
        Node T = y.right;
        y.right = z;
        z.left = T;
        updateHeight(z); // z is now lower
        updateHeight(y); // y is the new root
        return y;
    }

    // RR case: left rotate at z
    Node rotateLeft(Node z) {
        Node y = z.right;
        Node T = y.left;
        y.left = z;
        z.right = T;
        updateHeight(z);
        updateHeight(y);
        return y;
    }

    Node insert(Node n, int val) {
        // 1. Standard BST insert
        if (n == null) return new Node(val);
        if (val < n.val)
            n.left = insert(n.left, val);
        else if (val > n.val)
            n.right = insert(n.right, val);
        else return n; // duplicate

        // 2. Update height bottom-up
        updateHeight(n);

        // 3. Get balance factor
        int bf = balanceFactor(n);

        // 4. Rebalance if needed (4 cases)
        // LL: left-heavy + left child left-heavy
        if (bf > 1 && val < n.left.val)
            return rotateRight(n);
        // RR: right-heavy + right child right-heavy
        if (bf < -1 && val > n.right.val)
            return rotateLeft(n);
        // LR: left-heavy + left child right-heavy
        if (bf > 1 && val > n.left.val) {
            n.left = rotateLeft(n.left);
            return rotateRight(n);
        }
        // RL: right-heavy + right child left-heavy
        if (bf < -1 && val < n.right.val) {
            n.right = rotateRight(n.right);
            return rotateLeft(n);
        }
        return n;
    }

    public void insert(int val) {
        root = insert(root, val);
    }
}
```

> **Code walkthrough:** Complete AVL insert with automatic rebalancing. The KEY MECHANISM: after standard recursive BST insert, updateHeight() is called bottom-up on the return path - each node recalculates its height from its children's heights. If balanceFactor reaches plus or minus 2, the correct rotation case is selected by checking BOTH the current node's factor AND the value's relationship to the heavy child. WHY IT MATTERS: the cached height field avoids O(n) height recomputation on every balance check - each rotation only needs to update the two nodes involved. WHAT BREAKS: forgetting to call updateHeight on the demoted node (z) BEFORE the new root (y) in rotateRight/rotateLeft leaves y's height based on stale z data, corrupting all ancestor balance factors. TAKEAWAY: in any AVL rotation, update heights strictly bottom-up - the demoted node first, then the new root - because the new root's height depends on the demoted node's updated height.

**AVL vs Red-Black comparison:**

| Property | AVL | Red-Black |
|----------|-----|-----------|
| Max height | 1.44 log n | 2 log n |
| Rotations per insert | At most 1 | At most 2 |
| Rotations per delete | O(log n) | At most 3 |
| Lookup speed | Faster (lower height) | Slower |
| Write overhead | Higher | Lower |
| Java JDK | Not included | TreeMap/TreeSet |
| Use case | Read-heavy | Mixed read/write |

---

### 💻 Code Example

**Debugging: AVL tree integrity validator**

```java
boolean validateAVL(Node node) {
    if (node == null) return true;

    // 1. BST property
    if (node.left != null
        && node.left.val >= node.val) {
        System.err.printf(
            "BST violation: left %d >= %d%n",
            node.left.val, node.val);
        return false;
    }
    if (node.right != null
        && node.right.val <= node.val) {
        System.err.printf(
            "BST violation: right %d <= %d%n",
            node.right.val, node.val);
        return false;
    }

    // 2. Height accuracy
    int expected = 1 + Math.max(
        height(node.left), height(node.right));
    if (node.height != expected) {
        System.err.printf(
            "Height mismatch at %d: "
            + "stored=%d expected=%d%n",
            node.val, node.height, expected);
        return false;
    }

    // 3. AVL balance invariant
    int bf = balanceFactor(node);
    if (Math.abs(bf) > 1) {
        System.err.printf(
            "Balance violation at %d: bf=%d%n",
            node.val, bf);
        return false;
    }

    return validateAVL(node.left)
        && validateAVL(node.right);
}
// Usage: assert validateAVL(root) after every op
```

> **Code walkthrough:** A complete AVL integrity validator for debugging. The KEY MECHANISM: three checks in order - BST property (left < node < right), height accuracy (stored height equals recomputed height), and AVL balance (|bf| at most 1). The height check is the most diagnostic - a stale height at any node corrupts all ancestor balance factors, causing incorrect rotation decisions that compound over time. WHY IT MATTERS: AVL bugs are notoriously subtle because a wrong rotation on input sequence [1,2,3,4] may not manifest until input [1,2,3,4,5,6,7] - the validator catches the corruption at the exact operation that caused it. WHAT BREAKS: any code path that modifies tree structure without calling updateHeight() will be caught immediately. TAKEAWAY: implement a tree invariant validator BEFORE writing optimizations; run it after every operation during testing; it finds in minutes what manual trace would take hours.

---

### 🎓 Answers by Seniority

**Junior / Mid-level:**
Balance factor = height(left_subtree) - height(right_subtree). AVL invariant: this must be -1, 0, or +1 at every node. When it becomes plus or minus 2 after insert/delete, perform the appropriate rotation to restore balance. LL and RR cases use a single rotation; LR and RL cases need two rotations. This guarantees height at most 1.44 log n and O(log n) for all operations.

**Senior / Staff-level:**
Java's TreeMap uses Red-Black Tree not AVL because Red-Black requires at most 2 rotations per insert and 3 per delete - lower write overhead for a general-purpose mixed read/write map. Choose AVL only when the workload is read-dominated and the tighter height bound (1.44 log n vs. 2 log n) meaningfully reduces comparison count in the critical path. Neither is appropriate for disk storage - B-Trees minimize disk I/Os by maximizing branching factor, which is the bottleneck at scale, not comparison count.

---

### ⚠️ Common Misconceptions

**Misconception 1: "AVL rotations change BST ordering"**
Reality: Rotations are structure-preserving. They change tree shape but never change the in-order traversal sequence. After any rotation, the BST invariant still holds for all nodes.

**Misconception 2: "AVL delete needs at most one rotation like insert"**
Reality: AVL insert requires at most one rotation. AVL delete can require O(log n) rotations - after rebalancing one node its height decreases by 1, which can unbalance the grandparent, cascading to the root.

**Misconception 3: "Determine LR vs. LL by checking only the unbalanced node"**
Reality: LR/RL detection requires checking BOTH the unbalanced node's balance factor AND its heavy child's balance factor. Same sign = single rotation (LL/RR). Opposite signs = double rotation (LR/RL).

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Stale heights after rotation**
- Symptom: AVL tree gradually becomes unbalanced; occasional O(n) operations
- Cause: rotateRight/rotateLeft updates height of the new root but not the demoted node first
- Diagnosis: validateAVL() reports "Height mismatch" at the node that was demoted in the last rotation
- Fix: in every rotation, call updateHeight() on the demoted node first, then on the new root

**Failure 2: Wrong rotation case selected**
- Symptom: after insert the tree stays unbalanced (balance factor remains 2); operation becomes O(n) gradually
- Cause: LR case detected as LL; single rotation applied instead of double; imbalance moves to opposite side instead of being fixed
- Diagnosis: after the failing insert, print balance factors from inserted node up to root; two consecutive nodes with opposite-sign factors confirms LR/RL misidentification
- Fix: check BOTH the unbalanced node's factor AND its heavy child's factor sign before selecting rotation type

**Failure 3: Delete rebalancing stops early**
- Symptom: validateAVL() fails at an ancestor of the deleted node after some deletes
- Cause: delete method returns after the first rebalancing rotation instead of propagating up
- Fix: after delete, continue walking from the deletion point to root checking and rebalancing at each ancestor; any height change can cascade

---

### 🎯 Interview Deep-Dive

| Timing | Questions |
|--------|-----------|
| Opening (0-2 min) | AVL invariant, balance factor |
| Mid (2-8 min) | Rotations, AVL vs Red-Black |
| Deep-dive (8-15 min) | Production use, theory |

**[JUNIOR] Q1 - [CONCEPT] What guarantees does AVL give that plain BSTs do not?**

AVL trees guarantee O(log n) height for all inputs regardless of insertion order. Plain BSTs have O(log n) expected height on random input but O(n) worst case on sorted input.

The AVL balance invariant (|balance_factor| at most 1 at every node) limits height to approximately 1.44 log n. Inserting 1 million sorted integers into an AVL tree still gives at most 29 comparisons per search. The same insertion into a plain BST gives 1 million comparisons.

The cost: constant rotation overhead per insert/delete. Since rotations are O(1) pointer operations, total modification cost is O(log n) with a small constant.

*What separates good from great:* Stating the exact height bound (1.44 log n) and explaining it comes from the Fibonacci tree structure - the most unbalanced valid AVL tree has exactly Fibonacci(h) nodes.

**[JUNIOR] Q2 - [CODING] When do you use a single rotation vs. a double rotation in AVL?**

Single rotation: the imbalance is "straight" - both the unbalanced node and its heavy child lean in the same direction.
- LL case: node is left-heavy (bf = +2) AND left child is also left-heavy (bf = +1). Apply right rotation at the node.
- RR case: node is right-heavy (bf = -2) AND right child is also right-heavy (bf = -1). Apply left rotation at the node.

Double rotation: the imbalance is "bent" - the unbalanced node and its heavy child lean in opposite directions.
- LR case: node is left-heavy (bf = +2) AND left child is right-heavy (bf = -1). Apply left rotation on the child first (straightens the bend to LL), then right rotation on the node.
- RL case: node is right-heavy (bf = -2) AND right child is left-heavy (bf = +1). Apply right rotation on the child first (straightens to RR), then left rotation on the node.

The detection rule: check the sign of BOTH the unbalanced node's factor AND its heavy child's factor. Same sign = single rotation. Opposite signs = double rotation.

*What separates good from great:* Explaining WHY a single rotation fails for the LR case - it just moves the imbalance to the opposite side without reducing tree height, requiring a second rotation to complete the fix.

**[MID] Q3 - [COMPARISON] Compare AVL and Red-Black trees. When would you choose each?**

Both guarantee O(log n) operations. They differ in balance strictness and write overhead.

AVL: height at most 1.44 log n (strict). Fewer comparisons per search. Insert requires at most 1 rotation. Delete can require O(log n) rotations.

Red-Black: height at most 2 log n (loose). More comparisons per search. Insert requires at most 2 rotations. Delete requires at most 3 rotations.

Choose AVL when: search operations dominate the workload - autocomplete backend, read-heavy in-memory dictionary, static dataset built once and queried continuously. The stricter balance means 30% fewer comparisons per lookup vs. Red-Black on average.

Choose Red-Black when: mixed read/write or write-heavy workload. Java's TreeMap, C++ std::map, Linux kernel's CFS scheduler and memory management - all use Red-Black for its lower write overhead.

In practice: use TreeMap (Red-Black) for general Java work. Implement AVL only when profiling shows read latency is bottlenecked by comparison count.

*What separates good from great:* The precise asymmetry - AVL insert at most 1 rotation (actually very cheap in practice) but delete O(log n) rotations; Red-Black always at most 2 and 3 respectively. AVL's high delete cost makes it worse than often assumed for write-heavy workloads.

**[MID] Q4 - [DEBUGGING] After implementing AVL delete, some subtrees are not rebalancing. How do you debug?**

Step 1: Write validateAVL() checking BST property, height accuracy, and balance factor at every node. Add assertions to run it after every delete during testing.

Step 2: Create a minimal failing test. Start with 7 nodes and find the deletion sequence that triggers the bug. Common failure case: deleting a node when the sibling's subtree is 2 levels deeper.

Step 3: Trace the rebalancing path manually. After deletion, walk from the deleted node's parent to the root. At each ancestor, compute the expected balance factor manually. Find the first ancestor where computed does not match stored.

Step 4: Common bugs: (a) rotation case not triggered - check that you test BOTH the node's balance factor AND the child's factor sign; (b) rebalancing stops after first rotation - the loop must continue to root after any height change; (c) heights not updated in the correct order - demoted node must be updated before new root.

Step 5: Test all deletion variants specifically: leaf deletion, one-child deletion, two-children deletion, deletion at root, deletion that triggers cascading rebalancing.

*What separates good from great:* Noting that AVL delete can require O(log n) rotations (unlike insert which needs at most 1) - this is the most commonly forgotten AVL detail and the primary cause of "stops too early" bugs.

**[MID] Q5 - [TRADE-OFF] What is the performance overhead of AVL maintenance and when does it matter?**

Memory overhead: each node stores an extra height integer (4 bytes). O(n) total additional memory. For small-value nodes (integer keys), this is 20% extra per node.

Rotation overhead per insert: at most 1 rotation. Each rotation is O(1) - 2 pointer reassignments plus 2 height updates. On modern hardware: ~5-10 nanoseconds per rotation. Negligible.

Rotation overhead per delete: O(log n) rotations in the worst case - each potentially cascading to root. Worst case: ~30 * 10ns = 300ns for 1 billion nodes. Still negligible for most workloads.

When it matters: bulk inserts/deletes at rates above 10 million per second (rotation overhead accumulates); systems where predictable sub-microsecond latency is required (real-time control systems); memory-constrained embedded systems where 4 bytes per node is significant.

When it does not matter: typical business applications with fewer than 1 million operations per second; read-heavy workloads where insert is rare; trees that fit in L2/L3 cache (rotations are cache-local operations).

*What separates good from great:* The asymmetry between insert (at most 1 rotation - very cheap) and delete (O(log n) rotations - can accumulate). AVL insert overhead is actually smaller than Red-Black in practice; AVL delete is where the overhead difference becomes meaningful.

**[SENIOR] Q6 - [PRODUCTION] Why do production databases not use AVL trees for disk-based indexes?**

AVL trees optimize for comparison count, not disk I/Os. Each node access on a disk-based tree is a disk I/O. An AVL tree on 1 billion records has height approximately 1.44 * log2(1B) ~= 43 levels. Up to 43 disk I/Os per search. At 5-10 milliseconds per I/O, one search takes up to 430 milliseconds.

B-Trees solve this by using large nodes sized to fill one disk page (4KB or 16KB), containing hundreds of keys and child pointers. With branching factor 1000 per node, height for 1 billion records is log_1000(1B) = 3. Only 3 disk I/Os per search, regardless of tree size.

The fundamental mismatch: AVL minimizes comparison count (cheap when data is in CPU cache); B-Tree minimizes disk I/Os (expensive - 1000 times slower than RAM access). When data does not fit in RAM, disk I/O dominates and comparison count is irrelevant.

This is why PostgreSQL, MySQL, Oracle, and SQLite all use B-Tree variants for table indexes.

*What separates good from great:* Explaining B-Tree node size selection - node size should match the OS disk page size (4KB-16KB), maximizing keys per I/O and making full use of the data already transferred in one read.

**[SENIOR] Q7 - [SYSTEM] How is AVL balance maintained under concurrent modifications?**

Concurrent AVL modification is extremely difficult. The naive approach of a global lock eliminates all concurrency benefit.

The core challenge: AVL rotations touch multiple non-adjacent nodes at different tree levels. A single insert may trigger rotations at the grandparent, great-grandparent, or further up. To lock correctly, you need to know which nodes will be modified before traversing - but you discover this only during traversal, requiring locks on nodes you haven't visited yet.

Lock coupling (hand-over-hand locking): hold lock on parent while acquiring lock on child, then release parent. Allows concurrent operations on disjoint paths. But AVL rotations break the "disjoint path" assumption by touching ancestor nodes outside the current path.

The production solution: use ConcurrentSkipListMap instead of any tree. Skip list insertions only modify the insertion point and its forward pointers at each skip level - no cascading changes to distant ancestor nodes. This locality makes lock-free concurrent skip lists practical and performant.

Alternative for low-write-concurrency: a reader-writer lock (ReadWriteLock) - concurrent reads, exclusive writes. Acceptable when writes are rare (less than 1% of operations).

*What separates good from great:* Explaining precisely WHY skip lists are more concurrency-friendly than AVL trees - skip list structural changes are localized; AVL rotations can cascade to ancestors, requiring locks on arbitrary non-local nodes.

**[STAFF] Q8 - [ARCHITECTURE] Design an in-memory time-series index using AVL trees for 100K inserts per second.**

Time-series requirements: fast insert of timestamped data points, fast range queries over time windows, fast aggregation (sum, count, average) over ranges.

Critical insight: time-series data arrives in ascending timestamp order. This is exactly the sorted insertion case where plain BSTs fail catastrophically. AVL rebalancing handles sorted insertion correctly, maintaining O(log n) height.

AVL design with augmentation:
- Key: (metric_name, timestamp_ms) - composite, immutable
- Value: measurement value (double)
- Augmentation: store subtree count and sum at each node for O(log n) range aggregation without full traversal

At 100K inserts per second: AVL insert is O(log n) with at most 1 rotation. For 100M stored points (height ~= 40), each insert takes ~40 comparisons plus 1 rotation. At 100ns per operation this is 4-5 microseconds per insert, easily achieving 200K+ inserts per second on a single core.

Sharding for scale: partition by time window (1-hour shards). Active shard accepts inserts; queries fan out to relevant shards. Each shard is an independent AVL tree.

Persistence: periodically serialize shards to disk as sorted files (SSTable pattern). The in-memory AVL IS the MemTable in an LSM-Tree architecture.

*What separates good from great:* Mentioning subtree augmentation for O(log n) range aggregation and recognizing that sorted-timestamp insertion specifically motivates using a balanced BST over plain BST.

**[STAFF] Q9 - [THEORY] What is the minimum node count for an AVL tree of height h, and why does this matter?**

Minimum nodes N(h) satisfies the Fibonacci recurrence: N(0)=1, N(1)=2, N(h) = N(h-1) + N(h-2) + 1.

The minimum-node AVL tree of height h - a Fibonacci tree - has its left subtree as the minimum-node AVL tree of height h-1, and its right subtree as the minimum-node AVL tree of height h-2. This is the most unbalanced AVL tree that still satisfies the invariant (balance factor exactly 1 at the root).

Since Fibonacci numbers grow as phi^h / sqrt(5) where phi = 1.618033, solving for h:
N(h) >= phi^h so h <= log_phi(N) = log_2(N) / log_2(phi) ~= 1.44 * log_2(N)

This proves: AVL height is at most 1.44 * log_2(n) - the tight height bound.

Why it matters in practice:
(1) Proves the O(log n) guarantee is tight and quantified - 44% overhead vs. perfect balance, bounded and predictable
(2) For 1 million nodes: perfect tree height = 20; AVL worst case = 29; plain BST worst case = 1 million
(3) The Fibonacci structure explains cascading delete rebalancing - deleting from a Fibonacci tree at any level reduces a subtree height by 1, triggering a cascade of rebalancing all the way to the root in the worst case

*What separates good from great:* Deriving the 1.44 constant from the Fibonacci recurrence and connecting it to the practical consequence - AVL delete can require O(log n) rotations precisely because the Fibonacci tree structure means height reductions at one level propagate upward.

---

### ⚖️ Comparison Table

| Property | AVL Tree | Red-Black Tree | Plain BST | Skip List |
|----------|----------|----------------|-----------|-----------|
| Height guarantee | 1.44 log n | 2 log n | O(n) worst | O(log n) expected |
| Insert rebalance | O(log n) rotations | O(1) rotations | O(1) | O(log n) |
| Delete rebalance | O(log n) rotations | O(1-2) rotations | O(1) | O(log n) |
| Lookup | O(log n) | O(log n) | O(n) worst | O(log n) |
| Memory | Node + balance | Node + color bit | Node only | Node + tower |
| Cache performance | Good | Good | Varies | Poor |
| Concurrent | Hard | Hard | Hard | Practical |
| Java impl | - | TreeMap | - | ConcurrentSkipListMap |

---

### 🏛️ System Design

*(Omit: not applicable as standalone system design - AVL Trees are a component. See Staff Q8 for in-memory time-series index using AVL trees at 100K inserts/second.)*

---

### 📊 Diagram

```
AVL rotations - LL case (right rotation):

Before:        After:
   z              y
  /              / \
 y       ->     x   z
/
x

LL case: z is unbalanced (-2), y is left-heavy
Fix: single right rotation at z

LR case (left-right double rotation):

Before:    Step 1:     Step 2:
   z          z            y
  /          /            / \
 x    ->   y    ->       x   z
  \        /
   y      x

Step 1: left rotation at x
Step 2: right rotation at z
```

> **Diagram walkthrough:** The two fundamental AVL rotation cases. LL case (single right rotation): node z has balance factor -2 (left-heavy), left child y has balance factor -1 (left-heavy). One right rotation at z restores balance - y becomes the new root, x stays y's left child, z becomes y's right child. LR case (double rotation): node z is left-heavy but left child x is right-heavy - the "bent" case. Two rotations required: first left-rotate at x (straightening the bend), then right-rotate at z (balancing). The key relationship: LL and RR are single rotations; LR and RL (the bent cases) require two rotations. Edge case: the RR case is the mirror of LL (left rotation); RL is the mirror of LR. Insight: all four cases can be detected by checking the balance factor of the imbalanced node AND its heavy child - same-sign = single rotation, opposite-sign = double rotation.
