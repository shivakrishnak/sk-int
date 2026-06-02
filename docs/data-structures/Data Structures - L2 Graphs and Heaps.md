---
layout: default
title: "Data Structures - L2 Graphs and Heaps"
parent: "Data Structures"
nav_order: 5
permalink: /data-structures/l2-graphs-and-heaps/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 1 | [Graph Representations: Adjacency List vs Matrix](#graph-representations-adjacency-list-vs-matrix) | critical |
| 2 | [Heap and Priority Queue](#heap-and-priority-queue) | critical |

---

# Graph Representations: Adjacency List vs Matrix

**Difficulty:** ★★☆

**Interview Weight:** Critical

---

### 🎯 Model Answer

**30 seconds:**
A graph can be stored as an adjacency matrix (V x V 2D array where matrix[u][v]=1 means edge u->v) or an adjacency list (array of lists where list[u] contains all neighbors of u). Matrix gives O(1) edge existence check but uses O(V^2) space. Adjacency list gives O(degree) edge check but uses O(V + E) space. For sparse graphs (E much less than V^2, which is almost every real-world graph), adjacency list wins on space and traversal speed. For dense graphs (E close to V^2), matrix is competitive.

**3 minutes:**
The core trade-off is between operation speed and space efficiency. An adjacency matrix answers "is there an edge from A to B?" in O(1) by indexing matrix[A][B]. It uses O(V^2) space regardless of edge count - for a social network with 1 billion users and average 500 friends each, the matrix would require 1 billion * 1 billion bytes = 10^18 bytes, which is physically impossible. The adjacency list for the same graph uses 1 billion * 500 * 8 bytes = 4 terabytes - large but feasible.

An adjacency list answers "is there an edge from A to B?" in O(degree(A)) by scanning A's neighbor list. BFS and DFS visit each edge exactly once, running O(V + E) on an adjacency list vs. O(V^2) on a matrix regardless of actual edge count.

The decision rule: start with adjacency list for every real-world graph problem. Switch to matrix only when V is small (under a few thousand), the graph is dense (E ~= V^2), and you need frequent O(1) edge checks.

**Blank Mind Recovery:**
**(1) Two representations:** "Matrix: V x V array, O(1) edge check, O(V^2) space. List: array of lists, O(degree) edge check, O(V+E) space."
**(2) Key question:** "How dense is the graph? Sparse = adjacency list. Dense = matrix maybe."
**(3) Traversal:** "BFS/DFS is O(V+E) on list, O(V^2) on matrix."
**(4) Real world:** "Social graphs, road networks, dependency graphs = all sparse = adjacency list."

---

### 📘 Concept Explanation

**What it is:**
Two fundamental ways to represent a graph G = (V, E) in memory. The choice affects space usage, edge query time, traversal efficiency, and algorithm complexity.

**The problem it solves:**
Algorithm efficiency on graphs depends critically on how edges are stored. The right representation can reduce BFS from O(V^2) to O(V + E).

**Adjacency Matrix:**

```
Graph: 4 nodes, edges: 0-1, 0-2, 1-3, 2-3

Adjacency Matrix:
     0  1  2  3
  0 [0, 1, 1, 0]
  1 [0, 0, 0, 1]
  2 [0, 0, 0, 1]
  3 [0, 0, 0, 0]

Space: O(V^2) = 16 cells
Edge 0->1 check: matrix[0][1] -> O(1)
Neighbors of 0: scan row 0 -> O(V)
```

> **Diagram walkthrough:** A 4-node directed graph stored as a 4x4 adjacency matrix. Each cell matrix[u][v] is 1 if there is a directed edge from u to v, 0 otherwise. Finding edge 0->1 is O(1) - just index matrix[0][1]. Finding all neighbors of node 0 requires scanning the entire row 0 (4 cells). The key relationship: matrix size is always V^2 regardless of actual edge count. Edge case: for an undirected graph the matrix is symmetric - matrix[u][v] = matrix[v][u] - wasting half the space. Insight: the matrix is fast for random edge queries but wastes enormous space for sparse graphs; for a 1000-node sparse graph with 5000 edges, the matrix has 1 million cells of which 995,000 are zero.

**Adjacency List:**

```
Graph: same 4 nodes, edges: 0-1, 0-2, 1-3, 2-3

Adjacency List:
0 -> [1, 2]
1 -> [3]
2 -> [3]
3 -> []

Space: O(V + E) = 4 + 4 = 8 entries
Edge 0->1 check: scan list[0] -> O(degree(0))
Neighbors of 0: list[0] -> O(1) to access
```

> **Diagram walkthrough:** Same graph stored as an array of neighbor lists. Each node has a list of its outgoing neighbors. Finding all neighbors of node 0 is O(1) to access the list - then O(degree(0)) to iterate. Finding a specific edge 0->1 requires scanning list[0] for 1. The key relationship: total storage is O(V + E) - proportional to actual graph size, not worst-case size. Edge case: for a high-degree node (a "hub" like a celebrity on a social network with millions of followers), scanning the neighbor list for a specific edge is O(million) - this is where matrix wins. Insight: adjacency lists store ONLY the edges that exist; matrices store presence or absence for every possible edge.

**Java implementations:**

```java
// Adjacency Matrix (directed, unweighted)
int V = 5;
int[][] matrix = new int[V][V];
// Add edge u->v:
matrix[u][v] = 1;
// Check edge u->v:
boolean exists = matrix[u][v] == 1;
// All neighbors of u:
for (int v = 0; v < V; v++) {
    if (matrix[u][v] == 1) { /* process */ }
}

// Adjacency List (directed, unweighted)
List<List<Integer>> adj = new ArrayList<>();
for (int i = 0; i < V; i++)
    adj.add(new ArrayList<>());
// Add edge u->v:
adj.get(u).add(v);
// Check edge u->v:
boolean exists = adj.get(u).contains(v);
// All neighbors of u:
for (int neighbor : adj.get(u)) { /* O(deg) */ }

// Weighted adjacency list
List<List<int[]>> adjW = new ArrayList<>();
for (int i = 0; i < V; i++)
    adjW.add(new ArrayList<>());
// Add weighted edge u->v with weight w:
adjW.get(u).add(new int[]{v, w});
```

> **Code walkthrough:** Both representations in Java. The KEY MECHANISM: matrix uses a 2D array for O(1) random access; adjacency list uses List<List> where index u directly accesses u's neighbor list in O(1) but checking a specific neighbor requires O(degree) list scan. WHY IT MATTERS: the BFS inner loop processes all edges once - on matrix this is O(V) per node regardless of actual degree; on adjacency list this is O(actual_degree) per node. WHAT BREAKS: using HashMap<Integer, Set<Integer>> instead of List<List<Integer>> for adjacency list improves edge checks to O(1) average but adds 5-10x memory overhead per edge. TAKEAWAY: for competitive programming use int[][] matrix for small dense graphs or List<List<Integer>> for sparse graphs; for production use Map<Node, Set<Edge>> which handles non-integer node IDs and weighted edges cleanly.

**BFS comparison:**

```java
// BFS on adjacency list: O(V + E)
void bfsAdj(
    List<List<Integer>> adj, int start, int V
) {
    boolean[] visited = new boolean[V];
    Queue<Integer> q = new LinkedList<>();
    visited[start] = true;
    q.add(start);
    while (!q.isEmpty()) {
        int u = q.poll();
        for (int v : adj.get(u)) { // O(deg(u))
            if (!visited[v]) {
                visited[v] = true;
                q.add(v);
            }
        }
    }
}
// Total: sum of degrees = O(E)

// BFS on adjacency matrix: O(V^2)
void bfsMatrix(int[][] mat, int start, int V) {
    boolean[] visited = new boolean[V];
    Queue<Integer> q = new LinkedList<>();
    visited[start] = true;
    q.add(start);
    while (!q.isEmpty()) {
        int u = q.poll();
        for (int v = 0; v < V; v++) { // O(V)
            if (mat[u][v] == 1 && !visited[v]) {
                visited[v] = true;
                q.add(v);
            }
        }
    }
}
// Total: V * V = O(V^2)
```

> **Code walkthrough:** BFS complexity difference between the two representations. The KEY MECHANISM: adjacency list BFS inner loop runs exactly sum(degrees) times = 2E for undirected, E for directed. Matrix BFS inner loop runs V times per node regardless of actual degree. WHY IT MATTERS: on a social network with V=1M nodes and E=500M edges (each user has 500 friends), adjacency list BFS is O(500M); matrix BFS would be O(10^12) - 2 million times slower. WHAT BREAKS: if you accidentally store a graph with V=1000 nodes but E=500000 edges using adjacency list and run BFS, the O(V+E) = O(501000) is still faster than matrix O(V^2) = O(10^6) but the margin is small. TAKEAWAY: for any graph algorithm, ask first "what is the traversal cost on this representation?" - if it matters, use adjacency list for sparse graphs.

**When to use which:**

| Scenario | Winner | Reason |
|----------|--------|--------|
| Social network, road network | Adjacency list | Sparse (E << V^2) |
| Dense tournament matrix | Adjacency matrix | E ~= V^2, O(1) edge check |
| Dijkstra / BFS / DFS | Adjacency list | O(V+E) traversal |
| Floyd-Warshall (all pairs) | Adjacency matrix | Already O(V^3), matrix fits |
| Dynamic edge add/remove | Adjacency list | No resizing of matrix |
| Exact edge existence check | Adjacency matrix | O(1) vs O(degree) |

---

### 💻 Code Example

**Production Example: BFS shortest path on road network**

```java
// Bidirectional adjacency list for road network
// V = intersections, E = road segments
int[] bfsShortestPath(
    List<List<int[]>> adj, // [neighbor, distance]
    int start, int end, int V
) {
    int[] dist = new int[V];
    Arrays.fill(dist, Integer.MAX_VALUE);
    int[] prev = new int[V];
    Arrays.fill(prev, -1);
    Queue<Integer> q = new LinkedList<>();
    dist[start] = 0;
    q.add(start);
    while (!q.isEmpty()) {
        int u = q.poll();
        if (u == end) break;
        for (int[] edge : adj.get(u)) {
            int v = edge[0];
            if (dist[v] == Integer.MAX_VALUE) {
                dist[v] = dist[u] + 1;
                prev[v] = u;
                q.add(v);
            }
        }
    }
    // Reconstruct path
    List<Integer> path = new ArrayList<>();
    for (int v = end; v != -1; v = prev[v])
        path.add(0, v);
    return path.stream()
        .mapToInt(Integer::intValue).toArray();
}
```

> **Code walkthrough:** BFS shortest path (unweighted) on an adjacency list. The KEY MECHANISM: BFS visits nodes in non-decreasing distance order from the start; the first time we reach each node is via the shortest path. The prev[] array records the path back. WHY IT MATTERS: for unweighted graphs, BFS is optimal - no need for Dijkstra's heap overhead. On a city road network (V=100K intersections, E=300K roads), BFS runs in O(400K) operations. WHAT BREAKS: this only works for UNWEIGHTED graphs - for weighted roads (different distances per segment), BFS gives wrong results; use Dijkstra with a priority queue instead. TAKEAWAY: always ask "is the graph weighted?" before choosing BFS vs. Dijkstra - BFS is faster for unweighted, Dijkstra is necessary for weighted.

---

### 🎓 Answers by Seniority

**Junior / Mid-level:**
Adjacency matrix: V x V array, O(1) edge check, O(V^2) space. Adjacency list: array of neighbor lists, O(degree) edge check, O(V+E) space. BFS/DFS is O(V+E) on list, O(V^2) on matrix. Real-world graphs are sparse (social networks, roads, dependencies) - always adjacency list by default.

**Senior / Staff-level:**
Production graph representations depend on query patterns. For distributed graphs (Facebook's social graph, Google's web graph), neither in-memory representation works - shard edges by source node, store on-disk as edge lists, build partitioned adjacency lists. For graph databases (Neo4j, Amazon Neptune), edges are first-class objects with properties, stored as linked lists per node. For analytical workloads (PageRank, community detection), use Compressed Sparse Row (CSR) format - arrays of offsets and neighbor lists for cache-friendly traversal with O(1) degree lookup by subtraction.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Adjacency matrix is always faster"**
Reality: Matrix is faster ONLY for edge existence checks (O(1) vs O(degree)). For traversal, BFS/DFS, and most algorithms, adjacency list is faster on sparse graphs.

**Misconception 2: "Adjacency list can not check edge existence efficiently"**
Reality: Use adjacency set (Map<Integer, Set<Integer>>) instead of list for O(1) average edge checks while maintaining O(V+E) space.

**Misconception 3: "The choice doesn't matter for small graphs"**
Reality: Even at V=1000, matrix BFS is O(1M) vs. list BFS O(V+E). If E is small (sparse), list is 100-1000x faster.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Matrix used for large sparse graph**
- Symptom: OutOfMemoryError during graph construction; or graph traversal takes minutes instead of seconds
- Cause: V=100K nodes creates 100K * 100K * 4 bytes = 40GB matrix
- Fix: switch to adjacency list; O(V+E) space instead of O(V^2)

**Failure 2: Adjacency list with linear edge check creates O(V*E) algorithm**
- Symptom: algorithm that should be O(E log V) is running in O(E^2) time
- Cause: using adj.get(u).contains(v) in a hot loop (O(degree) per call, called E times)
- Fix: switch to adjacency set (HashSet per node) for O(1) average edge check

**Failure 3: Non-integer node IDs in array-indexed adjacency list**
- Symptom: ArrayIndexOutOfBoundsException or wrong neighbors after node ID gaps
- Cause: node IDs are not consecutive integers (UUIDs, sparse integers, strings)
- Fix: use Map<NodeId, List<NodeId>> instead of indexed array

---

### 🎯 Interview Deep-Dive

| Timing | Questions |
|--------|-----------|
| Opening (0-2 min) | Definitions, space complexity |
| Mid (2-8 min) | Trade-offs, algorithm complexity |
| Deep-dive (8-15 min) | Production systems, scale |

**[JUNIOR] Q1 - [CONCEPT] Compare adjacency matrix and adjacency list on space and time.**

Adjacency matrix: V x V 2D array. Space O(V^2) always. Edge check O(1). Finding all neighbors of u: O(V) (scan entire row). Best for dense graphs (E ~= V^2).

Adjacency list: array where index u contains list of u's neighbors. Space O(V + E). Edge check O(degree(u)). Finding all neighbors of u: O(1) to access list, O(degree) to iterate. Best for sparse graphs (E much less than V^2).

In most real-world problems: social networks, road maps, dependency graphs, web crawls - graphs are sparse. Adjacency list wins on space and traversal speed.

*What separates good from great:* Immediately asking "how dense is the graph?" and giving the V^2 vs V+E comparison with a real example (Facebook: 3 billion users, average 500 friends, matrix would need 9 * 10^18 bytes - infeasible).

**[JUNIOR] Q2 - [CODING] How does BFS complexity change between the two representations?**

On adjacency list: BFS visits each node once and processes each edge once. Total work = sum of all degrees = O(E) for directed, O(2E) for undirected. Total BFS: O(V + E).

On adjacency matrix: BFS visits each node once. For each node u, it scans the entire row of V cells to find neighbors, regardless of actual degree. Total work: V nodes * V cells = O(V^2).

For a sparse graph with V = 1000 and E = 2000: adjacency list BFS is O(3000); matrix BFS is O(1,000,000). 333x difference.

For a dense graph with V = 1000 and E = 400,000 (40% of all possible edges): adjacency list BFS is O(401,000); matrix BFS is O(1,000,000). The matrix is only 2.5x slower.

*What separates good from great:* Deriving the BFS complexity from first principles (sum of degrees = 2E) rather than just stating O(V+E) as a fact.

**[MID] Q3 - [TRADE-OFF] When would you choose adjacency matrix over adjacency list?**

Choose adjacency matrix when:
1. Dense graph - E is close to V^2. At E = V^2/2, matrix and list have comparable space; traversal difference shrinks.
2. Frequent random edge existence checks - O(1) matrix[u][v] vs O(degree) list scan.
3. Floyd-Warshall all-pairs shortest paths - the algorithm is already O(V^3) and works naturally on the matrix.
4. Small V - V at most a few thousand, so V^2 space is affordable (1000 * 1000 * 4 bytes = 4MB).
5. Parallel matrix operations - graph algorithms expressed as matrix multiplication (e.g., reachability via matrix power) run efficiently on GPUs.

In all other cases: adjacency list.

*What separates good from great:* Mentioning matrix multiplication = graph reachability. A^k[u][v] > 0 means there is a path of length k from u to v - this is why graph algorithms are sometimes expressed as linear algebra operations for GPU acceleration.

**[MID] Q4 - [DEBUGGING] Your BFS on a graph with 10K nodes is running in O(V^2) time instead of O(V+E). What is the cause?**

The classic cause: using an adjacency matrix for a sparse graph. BFS scans every row completely, paying O(V) per node regardless of actual edges.

Second cause: using adjacency list with linear edge existence checks in the wrong place. If BFS is checking `adj.get(u).contains(v)` (O(degree) linear scan) for every edge during traversal, the total cost becomes O(E * max_degree).

Third cause: using a sorted list as the adjacency structure and binary searching for neighbors - this works but adds O(log degree) per edge check.

Diagnostic: time a single BFS on a 10-node subgraph and compare to a 100-node subgraph. If time scales as V^2 not V+E, the representation is the issue. Profile which inner loop dominates.

Fix: confirm the adjacency list is a List<List<Integer>> (or Map<Integer, List<Integer>>) and BFS is iterating neighbors directly via `for (int v : adj.get(u))` - not checking membership.

*What separates good from great:* Distinguishing between the wrong representation (matrix) and the right representation used wrong (list with contains() checks in inner loop).

**[MID] Q5 - [SYSTEM] Design an in-memory graph for a dependency resolution system (package manager).**

Requirements: detect cycles (circular dependencies), topological sort (installation order), find all transitive dependencies.

Representation: adjacency list Map<String, Set<String>> - package name to set of direct dependencies. String keys handle non-integer node IDs; Set enables O(1) edge check.

Cycle detection: DFS with coloring (white=unvisited, gray=in-current-path, black=done). Finding a gray neighbor means a cycle. Return the cycle path.

Topological sort: DFS-based (Kahn's algorithm or DFS post-order reversal). Result is the valid installation order.

Transitive closure: memoized DFS - for each package, cache all transitive dependencies once computed.

Scale: npm registry has 2 million packages. Adjacency list: O(V + E) where E is total dependency edges (estimated 10-20 million). Fits in ~200MB. Matrix would be 2M * 2M * 1 bit = 500GB - impossible.

*What separates good from great:* Using Map<String, Set<String>> for non-integer node IDs and immediately quantifying why matrix is impossible at 2M nodes scale.

**[SENIOR] Q6 - [PRODUCTION] How are large-scale graphs stored in production systems?**

At Facebook/LinkedIn/Twitter scale, neither in-memory adjacency list nor matrix works for the full graph.

Distributed adjacency list: partition nodes across servers, each server stores the adjacency list for its assigned nodes. For the social graph (shard by user ID), server 1 holds users 1-10M and their friend lists, server 2 holds 10M-20M. Cross-shard edge lookups require network hops.

Compressed Sparse Row (CSR): flat arrays for cache-friendly traversal. Two arrays: offsets[V+1] where offsets[u] is the start index of u's neighbors in the neighbors[] array; neighbors[E] contains all neighbor IDs. Degree of u = offsets[u+1] - offsets[u]. Used in Apache Spark GraphX, NetworkX for large static graphs. 2-3x better cache performance vs linked adjacency lists.

Graph databases (Neo4j): nodes and relationships are first-class storage records. Each node stores a pointer to its first relationship; each relationship stores pointers to previous/next for both source and target. Enables O(1) neighbor access without index scan. B-Tree indexes on node properties. Designed for highly connected data with rich edge properties.

*What separates good from great:* Knowing about CSR format and why it improves cache performance (sequential memory access) over linked adjacency lists (pointer chasing causing cache misses).

**[SENIOR] Q7 - [DEBUGGING] After adding edges to a graph, BFS finds paths that shouldn't exist. Diagnose.**

Primary cause: undirected graph stored as directed - adding edge u->v without adding edge v->u. BFS from v can reach u via the reverse path u->v which exists, but v->u does not. This creates one-way reachability.

Second cause: self-loops accidentally added (adj.get(u).add(u)) causing BFS to never finish or mark nodes visited incorrectly.

Third cause: node ID collision - two different nodes mapped to the same integer ID in the adjacency list.

Diagnostic approach:
1. Print the adjacency list for the suspect nodes and verify the edges match the intended graph
2. Check for self-loops: for each u, verify u is not in adj.get(u)
3. For undirected graphs: verify edge symmetry: for every v in adj.get(u), check u is in adj.get(v)
4. Check node ID assignment: log ID at insertion time, verify uniqueness

*What separates good from great:* Immediately thinking of directed vs. undirected symmetry as the most common graph bug - most graph problems involving "connection" are undirected, but implementations often only add one direction.

**[STAFF] Q8 - [ARCHITECTURE] Design the graph storage layer for a recommendation system (users x items x interactions).**

Bipartite graph: two node types (users, items), edges are interactions (view, purchase, like) with weights and timestamps. V = ~100M users + 10M items; E = ~10B interactions.

Storage: edge list on disk, partitioned by time window (daily shards). Each edge record: (user_id, item_id, interaction_type, weight, timestamp). Sorted within shard by user_id for efficient user-based queries.

In-memory representation for serving: per-user adjacency list of (item_id, weight) pairs sorted by weight descending. Top-K retrieval is O(K) - read first K entries. Fits ~2TB in RAM for 100M users with 20 interactions each.

Real-time updates: append-only log for new interactions; batch job rebuilds sorted adjacency lists nightly. Near-real-time: use Redis sorted sets (ZADD item_id weight to user:N:interactions) for O(log E) insert with O(K) top-K retrieval.

Recommendation generation: matrix factorization (SVD) treats the adjacency matrix as a sparse user-item rating matrix; collaborative filtering treats it as a bipartite graph and finds nodes with similar neighbor sets.

*What separates good from great:* Recognizing this is a bipartite graph with heterogeneous node types and weighted timestamped edges - the representation must support both graph traversal and matrix factorization access patterns.

**[STAFF] Q9 - [SCALE] How would you handle a graph with 1 trillion edges distributed across 1000 servers?**

1 trillion edges at 16 bytes each (src, dst, weight, timestamp) = 16TB. Distribute across 1000 servers = 16GB per server, feasible.

Partitioning strategy: hash-based (edge goes to server hash(src) % 1000) - simple but causes all outgoing edges of a node to be co-located, while all incoming edges are spread across servers. Good for out-neighbor queries, bad for in-neighbor queries.

Better: vertex-cut partitioning. Assign each vertex to multiple servers based on which servers hold its edges. Each vertex has a "mirror" on servers holding its edges; mirrors coordinate via a master copy. Used in GraphX (Apache Spark) and PowerGraph.

Edge-cut partitioning: assign each vertex to exactly one server; edges may span servers. Good for vertex-centric processing (each update touches only one server); bad for edge-heavy algorithms where cross-server edges require network communication.

Distributed BFS: start with a queue on the source server. Processing a node means retrieving its adjacency list (possibly remote RPC), filtering unvisited neighbors, and placing them in queues on their respective servers. Level-synchronous BFS (used in Pregel/Giraph) processes all nodes at distance k before advancing to k+1.

*What separates good from great:* Knowing the difference between edge-cut and vertex-cut partitioning and when each is appropriate - vertex-cut reduces cross-server edge communication for high-degree vertices (the common case in power-law graphs like social networks).

---

### ⚖️ Comparison Table

| Property | Adjacency Matrix | Adjacency List | Adjacency Set |
|----------|-----------------|----------------|---------------|
| Space | O(V^2) | O(V + E) | O(V + E) |
| Edge check | O(1) | O(degree) | O(1) avg |
| Add edge | O(1) | O(1) amortized | O(1) avg |
| Remove edge | O(1) | O(degree) | O(1) avg |
| All neighbors of u | O(V) | O(degree) | O(degree) |
| BFS/DFS | O(V^2) | O(V + E) | O(V + E) |
| Best for | Dense, small V | Sparse, traversal | Sparse, edge checks |
| Java | int[][] | List<List<Integer>> | Map<Integer, Set<Integer>> |

---

### 🏛️ System Design

*(Omit: not applicable as primary system design here - adjacency list and matrix are components within larger systems such as the recommendation system design above (Staff Q8) and the BFS shortest path production example above. See Staff-level Q8 for the full system design context.)*

---

### 📊 Diagram

```
Sparse graph (V=4, E=4):

 0 --> 1
 |     |
 v     v
 2 --> 3

Adjacency Matrix:       Adjacency List:
   0  1  2  3           0: [1, 2]
0 [0, 1, 1, 0]          1: [3]
1 [0, 0, 0, 1]          2: [3]
2 [0, 0, 0, 1]          3: []
3 [0, 0, 0, 0]
16 cells, 4 edges        8 entries total

Space ratio: matrix/list = 16/8 = 2x
At V=1000, E=2000:       ratio = 1M / 3000 = 333x
At V=1M, E=10M:          ratio = 10^12 / 11M = 90000x
```

> **Diagram walkthrough:** The same 4-node graph in both representations, with concrete space comparison. The matrix always uses V^2 cells; the list uses V + E entries. The key relationship: the space ratio grows proportionally to V^2/(V+E) - as graphs get larger and sparser, the matrix becomes increasingly wasteful. Edge case: for a complete graph where E = V*(V-1)/2, the space ratio approaches 2 (matrix is only twice as large as list) - this is the breakeven point where matrix becomes competitive. Insight: real-world graphs are power-law distributed (a few nodes with millions of edges, most nodes with few) - average sparsity makes adjacency lists universally preferred in production.

---

---

# Heap and Priority Queue

**Difficulty:** ★★☆

**Interview Weight:** Critical

---

### 🎯 Model Answer

**30 seconds:**
A heap is a complete binary tree satisfying the heap property: in a max-heap, every parent is greater than or equal to both children; in a min-heap, every parent is less than or equal to both children. The root is always the maximum (or minimum). Operations: insert and extract-min/max in O(log n), peek at min/max in O(1). Heaps are implemented efficiently as arrays - no pointers needed. The primary use case is a priority queue: processing elements by priority rather than arrival order.

**3 minutes:**
A heap is the go-to data structure when you need fast access to the minimum or maximum of a dynamic set. The key insight is that a heap ONLY guarantees the root is the min/max - it does not sort the entire structure. This partial order is sufficient for priority queue operations and enables O(log n) insert and extract vs. O(n) for a sorted array insert.

Implementation trick: a complete binary tree can be stored as an array without pointers. For a node at index i, left child is at 2i+1, right child is 2i+2, and parent is at (i-1)/2. This array layout gives excellent cache performance compared to pointer-based trees.

Critical algorithm applications: Dijkstra's shortest path (min-heap on distances), Prim's MST (min-heap on edge weights), A* search, Huffman coding, k-way merge, finding top-K elements. Java's PriorityQueue is a min-heap by default.

**Blank Mind Recovery:**
**(1) Restate:** "Heap: complete binary tree where parent is always min (or max) of its subtree. Root = global min/max."
**(2) Array indexing:** "Node at i: left = 2i+1, right = 2i+2, parent = (i-1)/2."
**(3) Operations:** "Insert: add at end, sift up. Extract: swap root with last, remove last, sift down."
**(4) Use case:** "Any time you say 'give me the next highest/lowest priority item' - that is a heap."

---

### 📘 Concept Explanation

**What it is:**
A heap is a complete binary tree (all levels completely filled except possibly the last, which fills left to right) satisfying the heap property. Min-heap: every parent less than or equal to its children. Max-heap: every parent greater than or equal to its children.

**The problem it solves:**
Process elements in priority order: O(1) access to the highest-priority element, O(log n) insert of new elements. A sorted array gives O(1) access but O(n) insert. A linked list gives O(1) insert at an end but O(n) priority access.

**Array representation:**

```
Min-Heap tree:           Array representation:
        1                Index: 0  1  2  3  4  5  6
       / \               Value: 1  3  2  6  5  7  4
      3   2
     / \ / \
    6  5 7  4

Node at i:
  left child  = 2*i + 1
  right child = 2*i + 2
  parent      = (i-1) / 2

Example:
  Node 2 (index 2, value=2):
    left  = 2*2+1 = 5  (value=7)
    right = 2*2+2 = 6  (value=4)
    parent = (2-1)/2 = 0 (value=1)
```

> **Diagram walkthrough:** A min-heap with 7 nodes stored as an array. The tree structure is implicit - no pointers needed. The root (minimum) is at index 0. The key relationship: parent at index i always has a smaller value than children at 2i+1 and 2i+2. This is the only ordering guarantee - left is not necessarily smaller than right. Edge case: the last level is filled left-to-right; the "last node" used in sift-up/sift-down operations is always the rightmost node on the last level, which is the last element of the array. Insight: the array layout means all elements of the heap are contiguous in memory - excellent cache performance compared to a pointer-based binary tree where nodes scatter across the heap.

**Core operations:**

```java
public class MinHeap {
    private int[] data;
    private int size;

    public MinHeap(int capacity) {
        data = new int[capacity];
        size = 0;
    }

    // O(1): minimum is always at root
    public int peek() {
        if (size == 0)
            throw new NoSuchElementException();
        return data[0];
    }

    // O(log n): insert + restore heap property
    public void insert(int val) {
        if (size >= data.length)
            throw new IllegalStateException("Full");
        data[size] = val;      // add at end
        siftUp(size);          // restore heap
        size++;
    }
    private void siftUp(int i) {
        while (i > 0) {
            int parent = (i - 1) / 2;
            if (data[parent] <= data[i]) break;
            swap(i, parent);
            i = parent;
        }
    }

    // O(log n): remove min + restore heap
    public int extractMin() {
        if (size == 0)
            throw new NoSuchElementException();
        int min = data[0];
        data[0] = data[--size]; // move last to root
        siftDown(0);
        return min;
    }
    private void siftDown(int i) {
        while (true) {
            int smallest = i;
            int l = 2 * i + 1, r = 2 * i + 2;
            if (l < size && data[l] < data[smallest])
                smallest = l;
            if (r < size && data[r] < data[smallest])
                smallest = r;
            if (smallest == i) break;
            swap(i, smallest);
            i = smallest;
        }
    }

    private void swap(int i, int j) {
        int t = data[i]; data[i] = data[j];
        data[j] = t;
    }
}
```

> **Code walkthrough:** A complete min-heap implementation. The KEY MECHANISM: siftUp after insert moves the new element up by comparing with its parent, swapping when smaller - stops when parent is smaller or root is reached. siftDown after extractMin moves the promoted last element down by comparing with both children, swapping with the smaller child - stops when both children are larger or a leaf is reached. WHY IT MATTERS: both operations take O(log n) - the height of the heap - because a complete binary tree of n nodes has height exactly floor(log2 n). WHAT BREAKS: using siftDown after insert (instead of siftUp) breaks the heap property - inserting at the end and sifting down would move the new element to the wrong position since siftDown assumes the heap is already correct above. TAKEAWAY: insert uses siftUp (new element may be smaller than parent), extract uses siftDown (promoted last element may be larger than its new children).

**heapify - O(n) build from array:**

```java
// BAD: n * O(log n) = O(n log n)
int[] arr = {5, 3, 8, 1, 2, 7, 4};
MinHeap h = new MinHeap(arr.length);
for (int x : arr) h.insert(x); // O(n log n)

// GOOD: heapify in-place O(n)
void heapify(int[] arr) {
    int n = arr.length;
    // Start from last internal node
    // (last leaf's parent) and sift down
    for (int i = n/2 - 1; i >= 0; i--)
        siftDown(arr, n, i);
}
// Called by: Arrays.sort uses heapify internally
// Java's PriorityQueue(Collection) uses heapify
```

> **Code walkthrough:** Building a heap from an existing array in O(n) vs. O(n log n). The KEY MECHANISM: heapify starts at the last internal node (the parent of the last leaf = index n/2 - 1) and calls siftDown on each node going up to the root. This works because leaf nodes (the bottom half of the array) trivially satisfy the heap property. WHY IT MATTERS: O(n) build is used in heapsort and when constructing a PriorityQueue from a collection - the difference from O(n log n) matters at scale. WHAT BREAKS: the analysis that heapify is O(n) is non-obvious and counterintuitive - nodes near the bottom have small subtrees (most nodes have few descendants), so the total work is bounded by a geometric series summing to O(n). TAKEAWAY: use PriorityQueue(Collection) constructor for bulk initialization - it calls heapify internally; do NOT add elements one by one.

**Java PriorityQueue:**

```java
// Min-heap (default)
PriorityQueue<Integer> minH = new PriorityQueue<>();
minH.offer(5); minH.offer(2); minH.offer(8);
minH.peek();    // 2, O(1)
minH.poll();    // removes and returns 2, O(log n)

// Max-heap using reverseOrder()
PriorityQueue<Integer> maxH =
    new PriorityQueue<>(Comparator.reverseOrder());

// Custom comparator (e.g., tasks by priority)
PriorityQueue<Task> pq = new PriorityQueue<>(
    Comparator.comparingInt(t -> t.priority)
);

// Top-K largest elements (min-heap of size K)
PriorityQueue<Integer> topK =
    new PriorityQueue<>(); // min-heap
for (int x : data) {
    topK.offer(x);
    if (topK.size() > K) topK.poll(); // remove min
}
// topK now contains K largest elements
```

> **Code walkthrough:** Java's PriorityQueue for the four most common interview patterns. The KEY MECHANISM: Java's PriorityQueue is a min-heap by default (smallest element at top); reverseOrder() creates a max-heap by inverting comparisons. The top-K largest pattern uses a min-heap of size K - when the heap exceeds K elements, the smallest is evicted; after processing all n elements, the K remaining are the K largest. WHY IT MATTERS: the top-K pattern is O(n log K) time and O(K) space - much better than sorting all n elements (O(n log n)) when K is small. WHAT BREAKS: using contains() or remove(element) on PriorityQueue is O(n) linear scan - the heap has no index for arbitrary elements. TAKEAWAY: PriorityQueue excels at "next highest priority" access; it is poor for arbitrary element access or updates (decreaseKey) - for Dijkstra with decreaseKey, a more complex indexed heap is needed.

---

### 💻 Code Example

**Production Example: Dijkstra's shortest path with min-heap**

```java
// Dijkstra on adjacency list - O((V+E) log V)
int[] dijkstra(
    List<List<int[]>> adj, // [neighbor, weight]
    int src, int V
) {
    int[] dist = new int[V];
    Arrays.fill(dist, Integer.MAX_VALUE);
    dist[src] = 0;
    // PriorityQueue: [distance, node]
    PriorityQueue<int[]> pq = new PriorityQueue<>(
        Comparator.comparingInt(a -> a[0])
    );
    pq.offer(new int[]{0, src});

    while (!pq.isEmpty()) {
        int[] curr = pq.poll();
        int d = curr[0], u = curr[1];
        // Skip stale entries
        if (d > dist[u]) continue;
        for (int[] edge : adj.get(u)) {
            int v = edge[0], w = edge[1];
            if (dist[u] + w < dist[v]) {
                dist[v] = dist[u] + w;
                pq.offer(new int[]{dist[v], v});
            }
        }
    }
    return dist;
}
```

> **Code walkthrough:** Dijkstra's algorithm using Java's PriorityQueue as a min-heap. The KEY MECHANISM: the min-heap always pops the unvisited node with the smallest known distance; processing this node is equivalent to finalizing its shortest path. "Skip stale entries" handles the fact that Java's PriorityQueue lacks decreaseKey - instead, duplicate entries are added and outdated ones skipped by checking d > dist[u]. WHY IT MATTERS: O((V+E) log V) is the standard complexity for sparse graphs; without the heap, naive Dijkstra is O(V^2). WHAT BREAKS: not checking d > dist[u] processes stale heap entries that were invalidated when a shorter path was found - this gives wrong distances and O(E log E) instead of O(E log V). TAKEAWAY: the "stale entry skip" pattern is the standard Java idiom for Dijkstra since PriorityQueue lacks decreaseKey - always add this check.

**Failure Example: using PriorityQueue.contains() in a loop**

```java
// BAD: O(n) contains makes total O(n^2)
PriorityQueue<Integer> pq = new PriorityQueue<>();
// ... populate with n elements
for (int val : candidates) {
    if (!pq.contains(val)) { // O(n) linear scan!
        pq.offer(val);
    }
}

// GOOD: use HashSet for O(1) membership check
Set<Integer> inQueue = new HashSet<>();
PriorityQueue<Integer> pq = new PriorityQueue<>();
for (int val : candidates) {
    if (!inQueue.contains(val)) { // O(1)
        pq.offer(val);
        inQueue.add(val);
    }
}
```

> **Code walkthrough:** A common performance trap with PriorityQueue. The KEY MECHANISM: PriorityQueue.contains() performs a linear scan of the underlying array (O(n)) because the heap structure only guarantees the root is minimum - there is no index for arbitrary elements. WHY IT MATTERS: calling contains() in a loop over n candidates turns O(n log n) into O(n^2). WHAT BREAKS: the code looks correct and produces right results; the O(n^2) issue is invisible until input size reaches 10K+ where the slowdown becomes measurable. TAKEAWAY: PriorityQueue does not support efficient membership queries - if you need both priority-ordered access AND membership check, pair it with a HashSet tracking which elements are currently in the queue.

---

### 🎓 Answers by Seniority

**Junior / Mid-level:**
Heap: complete binary tree, parent always min (or max) of subtree. Stored as array: node i has left child 2i+1, right child 2i+2, parent (i-1)/2. Insert: add at end, siftUp O(log n). Extract-min: swap root with last, remove last, siftDown O(log n). Peek: O(1). Java: PriorityQueue is a min-heap by default. Top-K pattern: min-heap of size K, evict minimum when exceeded.

**Senior / Staff-level:**
Priority queue is a contract (peek/offer/poll by priority); heap is one implementation. Alternative implementations: Fibonacci heap (amortized O(1) decrease-key for Dijkstra), pairing heap, binomial heap. Fibonacci heap gives Dijkstra O(E + V log V) vs. O((V+E) log V) for binary heap - significant for dense graphs. Java lacks Fibonacci heap; for dense graphs in production, either implement or use Apache Commons Fibonacci heap. For stream top-K with approximate results, use Count-Min Sketch or reservoir sampling.

---

### ⚠️ Common Misconceptions

**Misconception 1: "A heap is a sorted data structure"**
Reality: A heap is PARTIALLY ordered - only the root is guaranteed to be min/max. Left child is not necessarily smaller than right child. In-order traversal of a heap does not produce sorted output.

**Misconception 2: "PriorityQueue.contains() is O(log n)"**
Reality: PriorityQueue.contains() is O(n) - it performs a linear scan of the underlying array. Use a separate HashSet for O(1) membership tracking.

**Misconception 3: "Building a heap from n elements requires O(n log n)"**
Reality: heapify (building from an existing array by calling siftDown from the last internal node up to the root) is O(n). Java's PriorityQueue(Collection) constructor uses heapify internally.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Stale entries in Dijkstra cause wrong distances**
- Symptom: Dijkstra returns incorrect shortest paths; shorter paths are missed
- Cause: missing `if (d > dist[u]) continue` check for stale heap entries
- Diagnosis: print distance at each pop; if a node is popped with d > dist[u], stale entries exist
- Fix: add the stale entry check immediately after polling from the priority queue

**Failure 2: Max-heap needed but min-heap used**
- Symptom: algorithm produces results in ascending order instead of descending; top-K finds K smallest instead of K largest
- Cause: PriorityQueue default is min-heap; max requires Comparator.reverseOrder()
- Fix: PriorityQueue<Integer> maxH = new PriorityQueue<>(Comparator.reverseOrder())

**Failure 3: decreaseKey not available in Java PriorityQueue**
- Symptom: Dijkstra adds duplicate entries but does not update the priority of existing entries; heap grows to O(E) size
- Cause: Java PriorityQueue lacks decreaseKey; each priority update adds a new entry
- Fix: this is expected behavior when using the "stale entry skip" pattern; total heap size is O(E) not O(V) - acceptable for sparse graphs

---

### 🎯 Interview Deep-Dive

| Timing | Questions |
|--------|-----------|
| Opening (0-2 min) | Heap property, array indexing |
| Mid (2-8 min) | Operations, applications |
| Deep-dive (8-15 min) | Heapsort, Dijkstra, scale |

**[JUNIOR] Q1 - [CONCEPT] What is the heap property and why is it stored as an array?**

The heap property for a min-heap: every parent node is less than or equal to both of its children. This must hold for every node in the tree. The consequence: the root contains the global minimum.

A complete binary tree can be represented as an array without pointers because the shape is predictable. For a node at index i: left child at 2i+1, right child at 2i+2, parent at (i-1)/2. No gaps in the tree means no wasted array slots.

Benefits of array representation: no pointer overhead (saves 16 bytes per node for two child pointers and a parent pointer), sequential memory layout means better cache performance, trivial to compute parent and child indices with integer arithmetic.

*What separates good from great:* Explaining that the array layout ONLY works because the tree is "complete" - any shape other than complete binary tree would leave gaps in the array.

**[JUNIOR] Q2 - [CODING] Walk me through insert and extract-min operations step by step.**

Insert:
1. Place the new element at the end of the array (index = current size).
2. siftUp: compare with parent at (i-1)/2. If smaller, swap. Repeat until parent is smaller or root reached.
3. Height is O(log n) so siftUp takes O(log n) steps.

Extract-min:
1. Save root (the minimum) to return.
2. Move the last element in the array to index 0 (the root position).
3. Reduce size by 1.
4. siftDown: compare root with both children. Swap with the smaller child if it is smaller than root. Repeat until both children are larger or a leaf is reached.
5. Height is O(log n) so siftDown takes O(log n) steps.

Why move last to root? We need to remove the root while keeping the complete binary tree shape. Moving the last element maintains the shape; siftDown restores the heap property.

*What separates good from great:* Explaining WHY the last element is moved to root (to maintain the complete binary tree shape) rather than just stating the algorithm.

**[MID] Q3 - [CODING] Find the top-K largest elements in a stream of integers using O(K) space.**

Use a min-heap of size at most K.

Algorithm: iterate through the stream. For each element, add it to the heap. If the heap size exceeds K, remove the minimum (poll()). After processing all elements, the heap contains exactly the K largest elements seen.

Correctness: the min-heap always contains the K largest elements seen so far. When a new element arrives: if it is larger than the current minimum of the K-largest set (heap root), it should replace the minimum. Adding to heap then polling the minimum accomplishes exactly this.

Time complexity: O(n log K) - n elements, each heap operation O(log K).
Space complexity: O(K) - the heap never exceeds K+1 elements.

Alternative: if K is large (K close to n), sort in O(n log n) or use QuickSelect for O(n) average time.

*What separates good from great:* Knowing when to switch from heap-based O(n log K) to QuickSelect O(n) based on K size, and implementing the return step correctly (return heap.toArray() - not sorted, just the K elements).

**[MID] Q4 - [TRADE-OFF] Compare using a heap versus a sorted array for a priority queue.**

| Operation | Min-Heap | Sorted Array |
|-----------|----------|--------------|
| Insert | O(log n) | O(n) shift |
| Peek-min | O(1) | O(1) |
| Extract-min | O(log n) | O(1) |
| Find arbitrary | O(n) | O(log n) binary |

Heap wins when: frequent inserts mixed with extract-min operations. The O(log n) insert vs. O(n) sorted insert is decisive.

Sorted array wins when: rare inserts, many extract-min operations with occasional random access. Or when data is read-only and you want O(log n) search by value.

Real-world: task scheduler (heap wins - frequent task additions with priority changes); read-only lookup table (sorted array wins - O(log n) search by value).

*What separates good from great:* Identifying the asymmetry: heap insert is O(log n) but find/delete is O(n); sorted array insert is O(n) but find is O(log n). The right choice depends on the ratio of inserts to finds.

**[MID] Q5 - [CODING] How does heapsort work and what is its complexity?**

Heapsort:
1. Build max-heap from array: O(n) using heapify (start from last internal node, siftDown each).
2. Repeatedly extract max: swap root (maximum) with last element, shrink heap size by 1, siftDown root. Repeat n times.

After step 2, the array is sorted in ascending order: each extracted max goes to the back of the array.

Time: O(n) for heapify + O(n log n) for n extractions = O(n log n). Guaranteed O(n log n) worst case - unlike quicksort which has O(n^2) worst case.

Space: O(1) - heapsort is in-place.

Why is heapsort not used in practice despite good complexity? Cache performance: during siftDown, access pattern jumps between array positions that are far apart (child at 2i+1, 2i+2 while parent at i). This causes frequent cache misses. Introsort (used in Java Arrays.sort) uses quicksort for average case (cache-friendly sequential access) and heapsort only as a fallback when quicksort depth exceeds a threshold.

*What separates good from great:* Explaining why heapsort has poor cache performance despite O(n log n) guarantee - the siftDown access pattern jumps non-sequentially through memory, causing cache misses on large arrays.

**[SENIOR] Q6 - [PRODUCTION] How does Dijkstra's shortest path use a priority queue and what are the performance implications?**

Dijkstra processes nodes in non-decreasing distance order from the source. The priority queue maintains all "candidate" nodes ordered by their current known distance.

Algorithm: initialize all distances to infinity except source (distance=0). Insert source with priority 0. Each iteration: extract the node with minimum distance from the heap, process its edges, update neighbor distances if improved, insert updated neighbors.

With binary heap: O((V + E) log V). Each node is inserted once, extracted once: O(V log V). Each edge may update a neighbor: O(E log V) insertions. Total: O((V + E) log V).

Java limitation: PriorityQueue lacks decreaseKey. The standard workaround is to insert a new entry with the updated priority and use the "stale entry skip" pattern. This increases heap size to O(E) but maintains O(E log V) total complexity.

With Fibonacci heap: O(E + V log V). decreaseKey is O(1) amortized. Significant win for dense graphs. Not in Java standard library.

At scale: for V=10M road network, E=30M edges, binary heap Dijkstra is O(40M * log 10M) ~= 40M * 23 = 920M operations. With modern CPUs at 10^9 simple operations/second: ~1 second. For navigation systems requiring 100ms response, approximate algorithms (A*, bidirectional Dijkstra, Contraction Hierarchies) reduce this by 100x.

*What separates good from great:* Knowing the Fibonacci heap advantage for dense graphs and why modern navigation uses Contraction Hierarchies (precomputed "shortcuts" reducing Dijkstra query time from seconds to milliseconds).

**[SENIOR] Q7 - [DEBUGGING] A priority queue is processing tasks in the wrong order. Diagnose.**

Step 1: verify the heap property after every insertion. Add a validateHeap() method that checks all parent-child relationships. Run it after each insert and extract during testing.

Step 2: check the comparator direction. PriorityQueue default is min-heap (smaller = higher priority). If you want higher numerical value = higher priority, you need Comparator.reverseOrder() or a custom comparator.

Step 3: verify the Comparable/Comparator implementation. A common bug: compareTo() returns wrong sign (negative when should be positive) or returns 0 for non-equal elements. Add logging to compareTo.

Step 4: check for mutable priority fields. If the comparator accesses a field that changes after insertion, the heap order is silently corrupted. Once a task is in the queue, its priority field must not change. If priority can change, remove the task, update priority, re-insert.

Step 5: verify the heap is not shared across threads without synchronization. Concurrent modifications break the heap invariant silently.

*What separates good from great:* Immediately identifying mutable priority fields as the most insidious production cause - tasks are added with one priority, the priority field changes (task escalation, timeout) but the heap does not know, producing stale ordering.

**[STAFF] Q8 - [ARCHITECTURE] Design a real-time task scheduler handling 1M tasks per second with priority aging.**

Requirements: 1M task inserts per second, tasks have integer priorities 1-100, older tasks should age (priority increases over time to prevent starvation), extract highest priority next.

Single binary heap limitation: 1M inserts/second requires O(log n) per insert. At n=10M tasks, log n ~= 24. 1M * 24 = 24M operations/second - achievable but tight, no room for aging overhead.

Priority aging approach: "virtual priority" = base_priority + age_weight * elapsed_seconds. Requires recomputing priority for all tasks periodically - O(n) scan.

Better: bucket queue (discrete priority levels). Array of 100 queues (one per priority level); insert O(1), extract O(100) = O(1) amortized. Aging: background thread periodically promotes tasks by moving them from queue[p] to queue[p+1]. Promotion is O(n_promoted) per aging cycle, not O(n_total).

At 1M inserts/second: bucket queue insert is O(1) array index + O(1) queue append = ~50ns. Easily achieves 1M/s.

Extract: linear scan of 100 buckets for first non-empty, then O(1) dequeue. With 100 priority levels: ~100 * 1ns = 100ns per extract.

Real-world: Linux O(1) scheduler (Linux 2.6.0-2.6.22) used exactly this design - two arrays of 140 queues (one active, one expired), achieving O(1) scheduling.

*What separates good from great:* Knowing the Linux O(1) scheduler design and recognizing that bucket queues (discrete priorities) enable O(1) scheduling by trading the generality of a binary heap for a finite priority range.

**[STAFF] Q9 - [SCALE] How do you implement a distributed priority queue for 1 billion tasks?**

A single heap cannot hold 1 billion tasks in memory efficiently. 1B tasks * 64 bytes per task = 64GB - exceeds typical single server RAM.

Distributed design: partition tasks by priority range. Servers 1-10 handle priorities 1-10, servers 11-20 handle priorities 11-20. Each server maintains a local binary heap.

Global extraction: to get the global maximum priority task, contact one representative server per priority range (the one holding the max for that range), find the global max among responses, extract from that server. This is O(number_of_priority_levels) = O(P) network round trips per extraction.

Better: hierarchical approach. Tier-1 servers hold top 0.1% of priority tasks (fits in RAM). Tier-2 holds the rest. Promote from Tier-2 to Tier-1 when Tier-1 drops below threshold. Extraction from Tier-1 is always local.

Challenges: network latency for cross-server coordination; consistent ordering under concurrent inserts from multiple producers; fault tolerance (server failure loses the tasks assigned to it - need replication).

Real-world: Kafka topic partitions with consumer group offset tracking; AWS SQS with message priority attributes; Celery task queues with Redis sorted sets as the backend.

*What separates good from great:* The tiered approach (hot priority tasks in-memory, cold in distributed storage) and recognizing that true distributed priority queue with strong consistency is extremely expensive - most production systems relax consistency to "best-effort" priority ordering.

---

### ⚖️ Comparison Table

| Property | Binary Heap | Fibonacci Heap | Sorted Array | BST (TreeMap) |
|----------|-------------|----------------|--------------|---------------|
| Insert | O(log n) | O(1) amortized | O(n) | O(log n) |
| Extract-min | O(log n) | O(log n) amortized | O(1) | O(log n) |
| Peek-min | O(1) | O(1) | O(1) | O(log n) |
| Decrease-key | O(log n) | O(1) amortized | O(n) | O(log n) |
| Build from array | O(n) heapify | O(n) | O(n log n) | O(n log n) |
| Find arbitrary | O(n) | O(n) | O(log n) | O(log n) |
| Space | O(n) | O(n) | O(n) | O(n) |
| Best for | General priority queue | Dense graph Dijkstra | Read-heavy sorted | Sorted iteration + priority |

---

### 🏛️ System Design

*(Omit: not applicable as standalone system design - heap and priority queue are components within larger systems. See Staff Q8 for the full real-time task scheduler system design and Senior Q6 for Dijkstra architecture at scale.)*

---

### 📊 Diagram

```
Min-Heap insert(2) - before and after:

Before:          Array: [1, 3, 4, 6, 5, 7, 8]
     1
    / \
   3   4
  /\ /\
 6 5 7  8

Insert 2 at end:  Array: [1, 3, 4, 6, 5, 7, 8, 2]
     1
    / \
   3   4
  /\ /\
 6 5 7  8
/
2

SiftUp: 2 < parent(3), swap:
     1
    / \
   2   4    Array: [1, 2, 4, 6, 5, 7, 8, 3]
  /\ /\
 6 3 7  8
/
5 (was 5, now shifted)

Wait, recheck: 2 < parent(1)? No. Stop.
Final: [1, 2, 4, 6, 5, 7, 8, 3]
```

> **Diagram walkthrough:** A min-heap showing the siftUp operation after inserting value 2. The new element is placed at the end of the array (last position in the tree). SiftUp compares with parent: 2 vs. parent 3 at index 1 - 2 is smaller, so swap. Then 2 vs. parent 1 at index 0 - 2 is NOT smaller, so stop. The key relationship: siftUp only swaps when the new element is smaller than its parent - it "bubbles up" to its correct level. Edge case: in the worst case, the inserted element is the new minimum and bubbles all the way to the root, taking O(log n) swaps. Insight: after siftUp completes, the heap property holds at every node because only the path from the new element to the root was touched - all other parent-child relationships were already valid.
