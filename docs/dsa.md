# Data Structures & Algorithms Interview Guide

## 1. Overview
At the Staff+ level, DSA interviews test your ability to **think from first principles under pressure**. Not whether you can recite a memorized solution, but how you break down a novel problem, connect it to foundational patterns, and articulate trade-offs. This guide is designed to **take you from zero to hero**—building intuition, confidence, and a pattern-based thinking framework that works for any problem, at any tech company.

Key areas:
- Core data structures and their operations
- Algorithmic paradigms
- A proven problem-solving framework
- How to cultivate intuition (no rote memorization)
- Comprehensive pattern library with identification clues
- Java code examples for each pattern
- Tips to increase speed and accuracy
- Building unshakable confidence

Real interviews: Google, Meta, Amazon, Netflix, Stripe, and other top-tier companies.

## 2. Core Data Structures (Understand Internally)

### Arrays & Strings
- **Properties**: contiguous memory, constant-time indexed access, cache-friendly, size immutable (Java). Strings immutable in Java; use `StringBuilder` for manipulation.
- **Important algorithms**: two-pointer (partition, merge sorted arrays, palindrome), sliding window, prefix sum, Kadane’s algorithm for max subarray.

### Linked Lists
- **Singly/Doubly**: traversal, insertion, deletion.
- **Tricks**: Dummy head node, slow/fast pointer (cycle detection, middle), reverse in-place (three-pointer method).

### Hash Tables
- **HashMap/HashSet** operations (average O(1)).
- Collision resolution: chaining (Java 8+ treeify), open addressing.
- Use for: existence checks, frequency counting, caching.

### Stacks & Queues
- **Stack**: LIFO; use for DFS, expression evaluation, monotonic stack problems.
- **Queue**: FIFO; BFS, sliding window.
- **Deque**: both ends; monotonic deque for sliding window maximum.

### Trees & Binary Trees
- Traversals: DFS (pre, in, post order) recursive and iterative (stack), BFS (level order) using queue.
- Binary Search Trees (BST): search, insertion, deletion; successor/predecessor.
- Balanced BSTs (AVL, Red-Black) guarantee O(log n) operations.
- Heaps (PriorityQueue): min-heap, max-heap; top-k elements; median from stream using two heaps.
- Tries (prefix trees): auto-complete, dictionary search.

### Graphs
- Representations: adjacency list (list of lists) vs adjacency matrix.
- Traversals: BFS (shortest path in unweighted), DFS (cycle detection, topological sort).
- Shortest paths: Dijkstra (non-negative weights), Bellman-Ford (negative edges), Floyd-Warshall (all pairs).
- Minimum spanning tree: Prim's and Kruskal's (Union-Find).
- Union-Find (Disjoint Set Union) with path compression and union by rank.

### Advanced Data Structures (Know concepts, not full implementation)
- Segment Tree / Binary Indexed Tree (Fenwick) for range sum queries.
- LRU Cache: `LinkedHashMap` or `HashMap` + doubly-linked list.
- Bloom filter: probabilistic data structure for set membership.
- Skip list: alternative to balanced trees.

## 3. Algorithmic Paradigms (When to Use)

### Recursion & Backtracking
- **When**: exhaustive search: permutations, subsets, combinations, N-Queens, Sudoku.
- **Pattern**: base case, reduce input size, undo side-effect (backtrack).
- **Complexity**: exponential, pruning helps.

### Divide and Conquer
- **When**: merge sort, quick sort, binary search, closest pair of points.
- **Pattern**: divide into subproblems, conquer recursively, combine results.

### Dynamic Programming (DP)
- **When**: overlapping subproblems and optimal substructure (maximum, minimum, number of ways). Look for “subproblem recurrence”.
- **States**: define DP array (1D, 2D), what does `dp[i]` represent?
- **Approach**: top-down (memoization) or bottom-up (tabulation). Usually bottom-up after pattern recognition.
- **Common problems**: Fibonacci, knapsack (0/1, unbounded), LCS, LIS, edit distance, coin change, matrix chain.

### Greedy
- **When**: local optimal leads to global optimal. Usually sorting + selection.
- **Problems**: activity selection, Huffman coding, Dijkstra (partly greedy), fractional knapsack.

### Sliding Window
- **Fixed size**: max sum subarray, average.
- **Variable size**: smallest subarray with sum ≥ target, longest substring without repeating characters.

### Two Pointers
- **Sorted arrays**: pair sum, remove duplicates, three sum.
- **In-place array partition**: move zeros, Dutch national flag.

### Fast & Slow Pointers (Tortoise & Hare)
- **Linked list**: cycle detection, middle of list, palindrome linked list.

### Bit Manipulation
- **Operations**: AND, OR, XOR, NOT, shifts.
- **Tricks**: XOR to find missing number, count set bits, power of two check.

### Topological Sort
- **Course schedule**, build dependency order using Kahn's algorithm (BFS) or DFS.

### Union-Find (Disjoint Set)
- **Dynamic connectivity**: number of islands II, redundant connection.

## 4. How to Approach Any Problem (Framework)
This framework will keep you calm and structured in interviews.

1. **Clarify**: Ask questions about input format, size constraints, edge cases, output exactly, duplicates, sorted? Define problem precisely.
2. **Example**: Work through a simple example and a tricky one. Draw/sketch.
3. **Brute Force**: State the naive solution. Analyze its complexity. This shows you can at least solve it.
4. **Optimize (Pattern Recognition)**:
   - What data structure can improve lookup? (hash table)
   - Do we need ordering? (sorting / tree)
   - Is there overlapping subproblems? (DP)
   - Does a sliding window apply? (contiguous subarray)
   - Does two-pointer work? (sorted array, palindrome)
   - Graph? BFS/DFS.
5. **Pseudo-code & Dry Run**: On the example.
6. **Code**: Clean, with meaningful variable names.
7. **Test**: Edge cases: empty, single element, huge input (complexity must hold), duplicates, negative numbers.
8. **Complexity**: Time & space.

## 5. How to Gain Intuition (Don’t Memorize)

### Understand the Core Concept Behind Each Pattern
Don't memorize code; understand **why** the pattern works.
- **Sliding Window**: Avoid recomputation by moving the window and adjusting partial results.
- **DP**: Identify state that can be built from smaller subproblems; think about a decision at each step.
- **Two Pointers**: Eliminate irrelevant elements by moving pointers based on a condition.

### Build a Mental Map of Patterns
When you read a problem, ask: “What is the structure of the input/output?” and “What am I optimizing?”
- Contiguous subarray → sliding window, prefix sum.
- Pair/combination → two pointers after sorting, hash map.
- Subsets/permutations → backtracking.
- Shortest path/minimum steps → BFS.
- Maximize/minimize something with decision → DP or greedy.

### Practice with “Signposts”
For each problem you solve, write down what clue led to the pattern. Example: “Target sum in array → Hash map for complement.” Over time, you internalize these associations.

### Solve by Variation, Not Volume
Don’t rush 100 problems. Pick 20 problems of a pattern, solve some, then attempt others without seeing the solution. Apply the pattern from scratch. That builds intuition.

### Derive, Don’t Copy
When seeing a solution, cover it, try to derive it using the pattern’s philosophy. If you fail, study why, then derive again next day.

## 6. Comprehensive Pattern Catalog (Identification & Examples)

### Pattern 1: Two Pointers (Sorted Array)
- **Clues**: Sorted array, need pairs/triplets with a sum, comparing elements from ends.
- **Approach**: Two pointers from start and end; move based on condition.
- **Example**: Two Sum II (sorted array).
```java
int[] twoSum(int[] numbers, int target) {
    int l = 0, r = numbers.length - 1;
    while (l < r) {
        int sum = numbers[l] + numbers[r];
        if (sum == target) return new int[]{l + 1, r + 1};
        else if (sum < target) l++;
        else r--;
    }
    return null;
}
```

### Pattern 2: Fast & Slow Pointers
- **Clues**: Linked list cycle detection, middle, palindrome.
- **Example**: Find middle of LinkedList.
```java
ListNode findMiddle(ListNode head) {
    ListNode slow = head, fast = head;
    while (fast != null && fast.next != null) {
        slow = slow.next;
        fast = fast.next.next;
    }
    return slow;
}
```

### Pattern 3: Sliding Window (Variable Size)
- **Clues**: Longest/shortest substring/subarray with a constraint; positive numbers.
- **Approach**: Expand window, contract when condition met, track best.
- **Example**: Longest substring without repeating characters.
```java
int lengthOfLongestSubstring(String s) {
    Set<Character> set = new HashSet<>();
    int l = 0, max = 0;
    for (int r = 0; r < s.length(); r++) {
        while (set.contains(s.charAt(r))) {
            set.remove(s.charAt(l++));
        }
        set.add(s.charAt(r));
        max = Math.max(max, r - l + 1);
    }
    return max;
}
```

### Pattern 4: Sliding Window (Fixed Size)
- **Clues**: Subarray of length k, moving average.
- **Example**: Maximum average subarray.

### Pattern 5: Prefix Sum
- **Clues**: Sum of subarray, range queries.
- **Example**: Subarray sum equals k.
```java
int subarraySum(int[] nums, int k) {
    Map<Integer, Integer> preSumFreq = new HashMap<>();
    preSumFreq.put(0, 1);
    int sum = 0, count = 0;
    for (int num : nums) {
        sum += num;
        count += preSumFreq.getOrDefault(sum - k, 0);
        preSumFreq.put(sum, preSumFreq.getOrDefault(sum, 0) + 1);
    }
    return count;
}
```

### Pattern 6: Binary Search (Search Space)
- **Clues**: Sorted input, min/max of some value, monotonic condition.
- **Example**: Find minimum in rotated sorted array, split array largest sum (binary search on answer).

### Pattern 7: Tree BFS
- **Clues**: Level-order traversal, closest leaf, shortest path in unweighted graph, min depth.
- **Example**: Level order traversal.

### Pattern 8: Tree DFS
- **Clues**: Path sum, depth calculation, diameter.
- **Example**: Maximum depth of binary tree.
```java
int maxDepth(TreeNode root) {
    if (root == null) return 0;
    return 1 + Math.max(maxDepth(root.left), maxDepth(root.right));
}
```

### Pattern 9: In-place Linked List Reversal
- **Clues**: Reverse sublist, reverse entire list, reorder list.
- **Example**: Reverse a linked list.
```java
ListNode reverseList(ListNode head) {
    ListNode prev = null, curr = head;
    while (curr != null) {
        ListNode next = curr.next;
        curr.next = prev;
        prev = curr;
        curr = next;
    }
    return prev;
}
```

### Pattern 10: Cyclic Sort
- **Clues**: Array containing numbers from 1 to n, find missing/duplicate.
- **Example**: Find all missing numbers.
```java
List<Integer> findDisappearedNumbers(int[] nums) {
    for (int i = 0; i < nums.length; i++) {
        while (nums[i] != i + 1 && nums[nums[i] - 1] != nums[i]) {
            swap(nums, i, nums[i] - 1);
        }
    }
    List<Integer> res = new ArrayList<>();
    for (int i = 0; i < nums.length; i++) {
        if (nums[i] != i + 1) res.add(i + 1);
    }
    return res;
}
```

### Pattern 11: Merge Intervals
- **Clues**: Overlapping intervals, schedule, meeting rooms.
- **Example**: Merge intervals.
```java
int[][] merge(int[][] intervals) {
    Arrays.sort(intervals, (a, b) -> Integer.compare(a[0], b[0]));
    List<int[]> merged = new ArrayList<>();
    for (int[] interval : intervals) {
        if (merged.isEmpty() || merged.get(merged.size()-1)[1] < interval[0])
            merged.add(interval);
        else
            merged.get(merged.size()-1)[1] = Math.max(merged.get(merged.size()-1)[1], interval[1]);
    }
    return merged.toArray(new int[0][]);
}
```

### Pattern 12: Top ‘K’ Elements
- **Clues**: K largest/smallest, K most frequent.
- **Example**: Top K frequent elements using min-heap of size K.

### Pattern 13: Subsets (Backtracking)
- **Clues**: All subsets, permutations, combinations.
- **Example**: Subsets.
```java
List<List<Integer>> subsets(int[] nums) {
    List<List<Integer>> res = new ArrayList<>();
    backtrack(res, new ArrayList<>(), nums, 0);
    return res;
}
void backtrack(List<List<Integer>> res, List<Integer> temp, int[] nums, int start) {
    res.add(new ArrayList<>(temp));
    for (int i = start; i < nums.length; i++) {
        temp.add(nums[i]);
        backtrack(res, temp, nums, i + 1);
        temp.remove(temp.size() - 1);
    }
}
```

### Pattern 14: Modified Binary Search
- **Clues**: Search in rotated array, ceiling of a number, bitonic array.

### Pattern 15: Bitwise XOR
- **Clues**: Find missing number in array of pairs, single number.
- **Example**: Single Number (every element appears twice except one).
```java
int singleNumber(int[] nums) {
    int res = 0;
    for (int num : nums) res ^= num;
    return res;
}
```

### Pattern 16: Two Heaps (Median in Stream)
- **Clues**: Need to maintain median of streaming data.

### Pattern 17: Graph BFS / DFS
- **Clues**: Paths, connectivity, island count.
- **Example**: Number of islands.
```java
int numIslands(char[][] grid) {
    int count = 0;
    for (int i = 0; i < grid.length; i++)
        for (int j = 0; j < grid[0].length; j++)
            if (grid[i][j] == '1') {
                dfs(grid, i, j);
                count++;
            }
    return count;
}
void dfs(char[][] grid, int i, int j) {
    if (i < 0 || j < 0 || i >= grid.length || j >= grid[0].length || grid[i][j] == '0') return;
    grid[i][j] = '0';
    dfs(grid, i+1, j); dfs(grid, i-1, j);
    dfs(grid, i, j+1); dfs(grid, i, j-1);
}
```

### Pattern 18: Topological Sort
- **Clues**: Ordering of tasks with prerequisites, dependency resolution.
- **Example**: Course Schedule (detect cycle).

### Pattern 19: Union Find
- **Clues**: Disjoint set merging, connected components, dynamic connectivity.

### Pattern 20: Dynamic Programming
- **Clues**: Optimal value, number of ways, min/max, overlapping subproblems.
- **Example**: Coin Change (minimum coins).
```java
int coinChange(int[] coins, int amount) {
    int[] dp = new int[amount + 1];
    Arrays.fill(dp, amount + 1);
    dp[0] = 0;
    for (int i = 1; i <= amount; i++) {
        for (int coin : coins) {
            if (coin <= i) dp[i] = Math.min(dp[i], dp[i - coin] + 1);
        }
    }
    return dp[amount] > amount ? -1 : dp[amount];
}
```

### Pattern 21: Knapsack DP
- **0/1 Knapsack**, unbounded, partition equal subset sum.
- **Example**: Partition subset sum.

### Pattern 22: Longest Common Subsequence / Substring
- **Clues**: Compare two strings, find longest matching sequence.
- **Example**: LCS DP.

### Pattern 23: Greedy Algorithms
- **Clues**: Activity selection, minimum arrows to burst balloons, jump game.
- **Example**: Jump Game II (minimum jumps) using greedy.

### Pattern 24: Monotonic Stack
- **Clues**: Next greater element, largest rectangle in histogram.
- **Example**: Next greater element.
```java
int[] nextGreaterElement(int[] nums) {
    int[] res = new int[nums.length];
    Arrays.fill(res, -1);
    Deque<Integer> stack = new ArrayDeque<>();
    for (int i = 0; i < nums.length; i++) {
        while (!stack.isEmpty() && nums[stack.peek()] < nums[i])
            res[stack.pop()] = nums[i];
        stack.push(i);
    }
    return res;
}
```

### Pattern 25: K-way Merge
- **Clues**: Merge multiple sorted arrays/lists.

## 7. Tips & Tricks for Speed and Accuracy
- **Use `int` not `Integer`** unless null needed, to avoid boxing overhead.
- **Precompute hash of lengths** if doing substring matching (Rabin-Karp).
- **For DP**, define state first, then recurrence.
- **Invert the problem** sometimes helps (max distance → min of something else).
- **Use sentinel nodes** in linked lists (dummy head) to avoid null checks.
- **Modulo** arithmetic handling for huge numbers.
- **Binary search** over answer space when verifying a guess is cheap.
- **Avoid deep recursion** on large input; prefer iterative or use tail recursion (but Java doesn't optimize).
- **Practice writing code on a whiteboard/plain editor** without IDE autocomplete.

## 8. How to Build Confidence
- **Start with “Easy” problems** but solve them without hints. Many “Easy” problems contain fundamental patterns.
- **Mock interviews** with peers or platforms like Pramp, interviewing.io. The pressure simulation is invaluable.
- **Explain your approach aloud**, even when practicing alone—this reinforces clarity.
- **Learn from failures**: For each problem you couldn't solve, analyze the exact gap (pattern recognition, edge case handling, complexity analysis), then drill that specific area.
- **Track your progress**: Keep a log of problems and the pattern you applied. Over time you'll see you hit most patterns.

## 9. High ROI Questions for Practice (Most Common Interview Patterns)
1. Two Sum (and all variants)
2. Longest Substring Without Repeating Characters
3. Valid Parentheses
4. Merge Intervals
5. Top K Frequent Elements
6. Kth Largest Element in an Array
7. Number of Islands (BFS/DFS)
8. Clone Graph
9. Course Schedule (Topological Sort)
10. LRU Cache
11. Minimum Window Substring
12. Median of Two Sorted Arrays (binary search)
13. Longest Increasing Subsequence
14. Coin Change
15. Word Break
16. Binary Tree Maximum Path Sum
17. Serialize and Deserialize Binary Tree
18. Trapping Rain Water
19. Implement Trie (Prefix Tree)
20. Sliding Window Maximum (Deque)
21. Alien Dictionary (Topological Sort of unknown order)
22. Sudoku Solver
23. Design Hit Counter / Rate Limiter
24. Design a Search Autocomplete System
25. Find Median from Data Stream

## 10. Cheat Sheet (Last Day Revision)
- **Complexities**: QuickSort O(n log n) average O(n^2) worst, MergeSort O(n log n) always, in-place. Heapify O(n). BST search/insert O(log n) avg.
- **Formula**: Sum of 1..n = n(n+1)/2, missing number XOR.
- **Tricks**: HashMap for O(1) lookup; Stack for matching brackets; Queue for BFS; PriorityQueue for K-th.
- **Pattern shortcuts**: “Contiguous subarray” -> sliding window/prefix sum; “sorted” -> two pointers/binary search; “all subsets” -> backtracking; “min/max value” -> DP or greedy; “shortest path” -> BFS.
- **Edge cases**: empty input, null, single element# Data Structures & Algorithms Interview Guide

## 1. Overview
At the Staff+ level, DSA interviews test your ability to **think from first principles under pressure**. Not whether you can recite a memorized solution, but how you break down a novel problem, connect it to foundational patterns, and articulate trade-offs. This guide is designed to **take you from zero to hero**—building intuition, confidence, and a pattern-based thinking framework that works for any problem, at any tech company.

Key areas:
- Core data structures and their operations
- Algorithmic paradigms
- A proven problem-solving framework
- How to cultivate intuition (no rote memorization)
- Comprehensive pattern library with identification clues
- Java code examples for each pattern
- Tips to increase speed and accuracy
- Building unshakable confidence

Real interviews: Google, Meta, Amazon, Netflix, Stripe, and other top-tier companies.

## 2. Core Data Structures (Understand Internally)

### Arrays & Strings
- **Properties**: contiguous memory, constant-time indexed access, cache-friendly, size immutable (Java). Strings immutable in Java; use `StringBuilder` for manipulation.
- **Important algorithms**: two-pointer (partition, merge sorted arrays, palindrome), sliding window, prefix sum, Kadane’s algorithm for max subarray.

### Linked Lists
- **Singly/Doubly**: traversal, insertion, deletion.
- **Tricks**: Dummy head node, slow/fast pointer (cycle detection, middle), reverse in-place (three-pointer method).

### Hash Tables
- **HashMap/HashSet** operations (average O(1)).
- Collision resolution: chaining (Java 8+ treeify), open addressing.
- Use for: existence checks, frequency counting, caching.

### Stacks & Queues
- **Stack**: LIFO; use for DFS, expression evaluation, monotonic stack problems.
- **Queue**: FIFO; BFS, sliding window.
- **Deque**: both ends; monotonic deque for sliding window maximum.

### Trees & Binary Trees
- Traversals: DFS (pre, in, post order) recursive and iterative (stack), BFS (level order) using queue.
- Binary Search Trees (BST): search, insertion, deletion; successor/predecessor.
- Balanced BSTs (AVL, Red-Black) guarantee O(log n) operations.
- Heaps (PriorityQueue): min-heap, max-heap; top-k elements; median from stream using two heaps.
- Tries (prefix trees): auto-complete, dictionary search.

### Graphs
- Representations: adjacency list (list of lists) vs adjacency matrix.
- Traversals: BFS (shortest path in unweighted), DFS (cycle detection, topological sort).
- Shortest paths: Dijkstra (non-negative weights), Bellman-Ford (negative edges), Floyd-Warshall (all pairs).
- Minimum spanning tree: Prim's and Kruskal's (Union-Find).
- Union-Find (Disjoint Set Union) with path compression and union by rank.

### Advanced Data Structures (Know concepts, not full implementation)
- Segment Tree / Binary Indexed Tree (Fenwick) for range sum queries.
- LRU Cache: `LinkedHashMap` or `HashMap` + doubly-linked list.
- Bloom filter: probabilistic data structure for set membership.
- Skip list: alternative to balanced trees.

## 3. Algorithmic Paradigms (When to Use)

### Recursion & Backtracking
- **When**: exhaustive search: permutations, subsets, combinations, N-Queens, Sudoku.
- **Pattern**: base case, reduce input size, undo side-effect (backtrack).
- **Complexity**: exponential, pruning helps.

### Divide and Conquer
- **When**: merge sort, quick sort, binary search, closest pair of points.
- **Pattern**: divide into subproblems, conquer recursively, combine results.

### Dynamic Programming (DP)
- **When**: overlapping subproblems and optimal substructure (maximum, minimum, number of ways). Look for “subproblem recurrence”.
- **States**: define DP array (1D, 2D), what does `dp[i]` represent?
- **Approach**: top-down (memoization) or bottom-up (tabulation). Usually bottom-up after pattern recognition.
- **Common problems**: Fibonacci, knapsack (0/1, unbounded), LCS, LIS, edit distance, coin change, matrix chain.

### Greedy
- **When**: local optimal leads to global optimal. Usually sorting + selection.
- **Problems**: activity selection, Huffman coding, Dijkstra (partly greedy), fractional knapsack.

### Sliding Window
- **Fixed size**: max sum subarray, average.
- **Variable size**: smallest subarray with sum ≥ target, longest substring without repeating characters.

### Two Pointers
- **Sorted arrays**: pair sum, remove duplicates, three sum.
- **In-place array partition**: move zeros, Dutch national flag.

### Fast & Slow Pointers (Tortoise & Hare)
- **Linked list**: cycle detection, middle of list, palindrome linked list.

### Bit Manipulation
- **Operations**: AND, OR, XOR, NOT, shifts.
- **Tricks**: XOR to find missing number, count set bits, power of two check.

### Topological Sort
- **Course schedule**, build dependency order using Kahn's algorithm (BFS) or DFS.

### Union-Find (Disjoint Set)
- **Dynamic connectivity**: number of islands II, redundant connection.

## 4. How to Approach Any Problem (Framework)
This framework will keep you calm and structured in interviews.

1. **Clarify**: Ask questions about input format, size constraints, edge cases, output exactly, duplicates, sorted? Define problem precisely.
2. **Example**: Work through a simple example and a tricky one. Draw/sketch.
3. **Brute Force**: State the naive solution. Analyze its complexity. This shows you can at least solve it.
4. **Optimize (Pattern Recognition)**:
   - What data structure can improve lookup? (hash table)
   - Do we need ordering? (sorting / tree)
   - Is there overlapping subproblems? (DP)
   - Does a sliding window apply? (contiguous subarray)
   - Does two-pointer work? (sorted array, palindrome)
   - Graph? BFS/DFS.
5. **Pseudo-code & Dry Run**: On the example.
6. **Code**: Clean, with meaningful variable names.
7. **Test**: Edge cases: empty, single element, huge input (complexity must hold), duplicates, negative numbers.
8. **Complexity**: Time & space.

## 5. How to Gain Intuition (Don’t Memorize)

### Understand the Core Concept Behind Each Pattern
Don't memorize code; understand **why** the pattern works.
- **Sliding Window**: Avoid recomputation by moving the window and adjusting partial results.
- **DP**: Identify state that can be built from smaller subproblems; think about a decision at each step.
- **Two Pointers**: Eliminate irrelevant elements by moving pointers based on a condition.

### Build a Mental Map of Patterns
When you read a problem, ask: “What is the structure of the input/output?” and “What am I optimizing?”
- Contiguous subarray → sliding window, prefix sum.
- Pair/combination → two pointers after sorting, hash map.
- Subsets/permutations → backtracking.
- Shortest path/minimum steps → BFS.
- Maximize/minimize something with decision → DP or greedy.

### Practice with “Signposts”
For each problem you solve, write down what clue led to the pattern. Example: “Target sum in array → Hash map for complement.” Over time, you internalize these associations.

### Solve by Variation, Not Volume
Don’t rush 100 problems. Pick 20 problems of a pattern, solve some, then attempt others without seeing the solution. Apply the pattern from scratch. That builds intuition.

### Derive, Don’t Copy
When seeing a solution, cover it, try to derive it using the pattern’s philosophy. If you fail, study why, then derive again next day.

## 6. Comprehensive Pattern Catalog (Identification & Examples)

### Pattern 1: Two Pointers (Sorted Array)
- **Clues**: Sorted array, need pairs/triplets with a sum, comparing elements from ends.
- **Approach**: Two pointers from start and end; move based on condition.
- **Example**: Two Sum II (sorted array).
```java
int[] twoSum(int[] numbers, int target) {
    int l = 0, r = numbers.length - 1;
    while (l < r) {
        int sum = numbers[l] + numbers[r];
        if (sum == target) return new int[]{l + 1, r + 1};
        else if (sum < target) l++;
        else r--;
    }
    return null;
}
```

### Pattern 2: Fast & Slow Pointers
- **Clues**: Linked list cycle detection, middle, palindrome.
- **Example**: Find middle of LinkedList.
```java
ListNode findMiddle(ListNode head) {
    ListNode slow = head, fast = head;
    while (fast != null && fast.next != null) {
        slow = slow.next;
        fast = fast.next.next;
    }
    return slow;
}
```

### Pattern 3: Sliding Window (Variable Size)
- **Clues**: Longest/shortest substring/subarray with a constraint; positive numbers.
- **Approach**: Expand window, contract when condition met, track best.
- **Example**: Longest substring without repeating characters.
```java
int lengthOfLongestSubstring(String s) {
    Set<Character> set = new HashSet<>();
    int l = 0, max = 0;
    for (int r = 0; r < s.length(); r++) {
        while (set.contains(s.charAt(r))) {
            set.remove(s.charAt(l++));
        }
        set.add(s.charAt(r));
        max = Math.max(max, r - l + 1);
    }
    return max;
}
```

### Pattern 4: Sliding Window (Fixed Size)
- **Clues**: Subarray of length k, moving average.
- **Example**: Maximum average subarray.

### Pattern 5: Prefix Sum
- **Clues**: Sum of subarray, range queries.
- **Example**: Subarray sum equals k.
```java
int subarraySum(int[] nums, int k) {
    Map<Integer, Integer> preSumFreq = new HashMap<>();
    preSumFreq.put(0, 1);
    int sum = 0, count = 0;
    for (int num : nums) {
        sum += num;
        count += preSumFreq.getOrDefault(sum - k, 0);
        preSumFreq.put(sum, preSumFreq.getOrDefault(sum, 0) + 1);
    }
    return count;
}
```

### Pattern 6: Binary Search (Search Space)
- **Clues**: Sorted input, min/max of some value, monotonic condition.
- **Example**: Find minimum in rotated sorted array, split array largest sum (binary search on answer).

### Pattern 7: Tree BFS
- **Clues**: Level-order traversal, closest leaf, shortest path in unweighted graph, min depth.
- **Example**: Level order traversal.

### Pattern 8: Tree DFS
- **Clues**: Path sum, depth calculation, diameter.
- **Example**: Maximum depth of binary tree.
```java
int maxDepth(TreeNode root) {
    if (root == null) return 0;
    return 1 + Math.max(maxDepth(root.left), maxDepth(root.right));
}
```

### Pattern 9: In-place Linked List Reversal
- **Clues**: Reverse sublist, reverse entire list, reorder list.
- **Example**: Reverse a linked list.
```java
ListNode reverseList(ListNode head) {
    ListNode prev = null, curr = head;
    while (curr != null) {
        ListNode next = curr.next;
        curr.next = prev;
        prev = curr;
        curr = next;
    }
    return prev;
}
```

### Pattern 10: Cyclic Sort
- **Clues**: Array containing numbers from 1 to n, find missing/duplicate.
- **Example**: Find all missing numbers.
```java
List<Integer> findDisappearedNumbers(int[] nums) {
    for (int i = 0; i < nums.length; i++) {
        while (nums[i] != i + 1 && nums[nums[i] - 1] != nums[i]) {
            swap(nums, i, nums[i] - 1);
        }
    }
    List<Integer> res = new ArrayList<>();
    for (int i = 0; i < nums.length; i++) {
        if (nums[i] != i + 1) res.add(i + 1);
    }
    return res;
}
```

### Pattern 11: Merge Intervals
- **Clues**: Overlapping intervals, schedule, meeting rooms.
- **Example**: Merge intervals.
```java
int[][] merge(int[][] intervals) {
    Arrays.sort(intervals, (a, b) -> Integer.compare(a[0], b[0]));
    List<int[]> merged = new ArrayList<>();
    for (int[] interval : intervals) {
        if (merged.isEmpty() || merged.get(merged.size()-1)[1] < interval[0])
            merged.add(interval);
        else
            merged.get(merged.size()-1)[1] = Math.max(merged.get(merged.size()-1)[1], interval[1]);
    }
    return merged.toArray(new int[0][]);
}
```

### Pattern 12: Top ‘K’ Elements
- **Clues**: K largest/smallest, K most frequent.
- **Example**: Top K frequent elements using min-heap of size K.

### Pattern 13: Subsets (Backtracking)
- **Clues**: All subsets, permutations, combinations.
- **Example**: Subsets.
```java
List<List<Integer>> subsets(int[] nums) {
    List<List<Integer>> res = new ArrayList<>();
    backtrack(res, new ArrayList<>(), nums, 0);
    return res;
}
void backtrack(List<List<Integer>> res, List<Integer> temp, int[] nums, int start) {
    res.add(new ArrayList<>(temp));
    for (int i = start; i < nums.length; i++) {
        temp.add(nums[i]);
        backtrack(res, temp, nums, i + 1);
        temp.remove(temp.size() - 1);
    }
}
```

### Pattern 14: Modified Binary Search
- **Clues**: Search in rotated array, ceiling of a number, bitonic array.

### Pattern 15: Bitwise XOR
- **Clues**: Find missing number in array of pairs, single number.
- **Example**: Single Number (every element appears twice except one).
```java
int singleNumber(int[] nums) {
    int res = 0;
    for (int num : nums) res ^= num;
    return res;
}
```

### Pattern 16: Two Heaps (Median in Stream)
- **Clues**: Need to maintain median of streaming data.

### Pattern 17: Graph BFS / DFS
- **Clues**: Paths, connectivity, island count.
- **Example**: Number of islands.
```java
int numIslands(char[][] grid) {
    int count = 0;
    for (int i = 0; i < grid.length; i++)
        for (int j = 0; j < grid[0].length; j++)
            if (grid[i][j] == '1') {
                dfs(grid, i, j);
                count++;
            }
    return count;
}
void dfs(char[][] grid, int i, int j) {
    if (i < 0 || j < 0 || i >= grid.length || j >= grid[0].length || grid[i][j] == '0') return;
    grid[i][j] = '0';
    dfs(grid, i+1, j); dfs(grid, i-1, j);
    dfs(grid, i, j+1); dfs(grid, i, j-1);
}
```

### Pattern 18: Topological Sort
- **Clues**: Ordering of tasks with prerequisites, dependency resolution.
- **Example**: Course Schedule (detect cycle).

### Pattern 19: Union Find
- **Clues**: Disjoint set merging, connected components, dynamic connectivity.

### Pattern 20: Dynamic Programming
- **Clues**: Optimal value, number of ways, min/max, overlapping subproblems.
- **Example**: Coin Change (minimum coins).
```java
int coinChange(int[] coins, int amount) {
    int[] dp = new int[amount + 1];
    Arrays.fill(dp, amount + 1);
    dp[0] = 0;
    for (int i = 1; i <= amount; i++) {
        for (int coin : coins) {
            if (coin <= i) dp[i] = Math.min(dp[i], dp[i - coin] + 1);
        }
    }
    return dp[amount] > amount ? -1 : dp[amount];
}
```

### Pattern 21: Knapsack DP
- **0/1 Knapsack**, unbounded, partition equal subset sum.
- **Example**: Partition subset sum.

### Pattern 22: Longest Common Subsequence / Substring
- **Clues**: Compare two strings, find longest matching sequence.
- **Example**: LCS DP.

### Pattern 23: Greedy Algorithms
- **Clues**: Activity selection, minimum arrows to burst balloons, jump game.
- **Example**: Jump Game II (minimum jumps) using greedy.

### Pattern 24: Monotonic Stack
- **Clues**: Next greater element, largest rectangle in histogram.
- **Example**: Next greater element.
```java
int[] nextGreaterElement(int[] nums) {
    int[] res = new int[nums.length];
    Arrays.fill(res, -1);
    Deque<Integer> stack = new ArrayDeque<>();
    for (int i = 0; i < nums.length; i++) {
        while (!stack.isEmpty() && nums[stack.peek()] < nums[i])
            res[stack.pop()] = nums[i];
        stack.push(i);
    }
    return res;
}
```

### Pattern 25: K-way Merge
- **Clues**: Merge multiple sorted arrays/lists.

## 7. Tips & Tricks for Speed and Accuracy
- **Use `int` not `Integer`** unless null needed, to avoid boxing overhead.
- **Precompute hash of lengths** if doing substring matching (Rabin-Karp).
- **For DP**, define state first, then recurrence.
- **Invert the problem** sometimes helps (max distance → min of something else).
- **Use sentinel nodes** in linked lists (dummy head) to avoid null checks.
- **Modulo** arithmetic handling for huge numbers.
- **Binary search** over answer space when verifying a guess is cheap.
- **Avoid deep recursion** on large input; prefer iterative or use tail recursion (but Java doesn't optimize).
- **Practice writing code on a whiteboard/plain editor** without IDE autocomplete.

## 8. How to Build Confidence
- **Start with “Easy” problems** but solve them without hints. Many “Easy” problems contain fundamental patterns.
- **Mock interviews** with peers or platforms like Pramp, interviewing.io. The pressure simulation is invaluable.
- **Explain your approach aloud**, even when practicing alone—this reinforces clarity.
- **Learn from failures**: For each problem you couldn't solve, analyze the exact gap (pattern recognition, edge case handling, complexity analysis), then drill that specific area.
- **Track your progress**: Keep a log of problems and the pattern you applied. Over time you'll see you hit most patterns.

## 9. High ROI Questions for Practice (Most Common Interview Patterns)
1. Two Sum (and all variants)
2. Longest Substring Without Repeating Characters
3. Valid Parentheses
4. Merge Intervals
5. Top K Frequent Elements
6. Kth Largest Element in an Array
7. Number of Islands (BFS/DFS)
8. Clone Graph
9. Course Schedule (Topological Sort)
10. LRU Cache
11. Minimum Window Substring
12. Median of Two Sorted Arrays (binary search)
13. Longest Increasing Subsequence
14. Coin Change
15. Word Break
16. Binary Tree Maximum Path Sum
17. Serialize and Deserialize Binary Tree
18. Trapping Rain Water
19. Implement Trie (Prefix Tree)
20. Sliding Window Maximum (Deque)
21. Alien Dictionary (Topological Sort of unknown order)
22. Sudoku Solver
23. Design Hit Counter / Rate Limiter
24. Design a Search Autocomplete System
25. Find Median from Data Stream

## 10. Cheat Sheet (Last Day Revision)
- **Complexities**: QuickSort O(n log n) average O(n^2) worst, MergeSort O(n log n) always, in-place. Heapify O(n). BST search/insert O(log n) avg.
- **Formula**: Sum of 1..n = n(n+1)/2, missing number XOR.
- **Tricks**: HashMap for O(1) lookup; Stack for matching brackets; Queue for BFS; PriorityQueue for K-th.
- **Pattern shortcuts**: “Contiguous subarray” -> sliding window/prefix sum; “sorted” -> two pointers/binary search; “all subsets” -> backtracking; “min/max value” -> DP or greedy; “shortest path” -> BFS.
- **Edge cases**: empty input, null, single element, negative numbers, overflow (use long).

---

### 🎤 Communication Training
- **Think out loud**: “I’m considering a brute-force approach that would be O(n^2), but I see we can use a hash map to get O(n).”
- **Explain trade-offs**: “We can use an array for faster access, but it’s fixed size. An ArrayList gives flexibility with amortized O(1) append.”
- **Admit when stuck**: “I’m trying to figure out the recurrence; I see that if I include the current item, the remaining capacity decreases...”

### 📈 Personalised Self-Assessment (12 YOE)
- **Strong areas**: You likely have years of practical coding; you can implement standard algorithms easily but might be rusty on advanced DP or graph problems.
- **Hidden gaps**: Intuition for bit manipulation, complex state DP, advanced graph algorithms (Tarjan's), segment trees (may be rare but can appear).
- **Overconfidence risks**: Assuming you don’t need to practice because you’re senior; interviewing without refreshing pattern recognition leads to suboptimal solutions. You must practice consistently for at least a few weeks.

Now you have the foundational guide. Go deeply into each pattern, solve 5-10 problems per pattern, and use the framework to approach new problems. You are on the path from zero to hero., negative numbers, overflow (use long).

---

### 🎤 Communication Training
- **Think out loud**: “I’m considering a brute-force approach that would be O(n^2), but I see we can use a hash map to get O(n).”
- **Explain trade-offs**: “We can use an array for faster access, but it’s fixed size. An ArrayList gives flexibility with amortized O(1) append.”
- **Admit when stuck**: “I’m trying to figure out the recurrence; I see that if I include the current item, the remaining capacity decreases...”

### 📈 Personalised Self-Assessment (12 YOE)
- **Strong areas**: You likely have years of practical coding; you can implement standard algorithms easily but might be rusty on advanced DP or graph problems.
- **Hidden gaps**: Intuition for bit manipulation, complex state DP, advanced graph algorithms (Tarjan's), segment trees (may be rare but can appear).
- **Overconfidence risks**: Assuming you don’t need to practice because you’re senior; interviewing without refreshing pattern recognition leads to suboptimal solutions. You must practice consistently for at least a few weeks.

Now you have the foundational guide. Go deeply into each pattern, solve 5-10 problems per pattern, and use the framework to approach new problems. You are on the path from zero to hero.