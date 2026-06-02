---
layout: default
title: "Data Structures - L4 Bloom Filters"
parent: "Data Structures"
nav_order: 11
permalink: /data-structures/l4-bloom-filters/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---------|--------|
| 1 | [Bloom Filters and Probabilistic Data Structures](#bloom-filters-and-probabilistic-data-structures) | high |

---

# Bloom Filters and Probabilistic Data Structures

**Difficulty:** ★★★

**Interview Weight:** High

---

### 🎯 Model Answer

**30 seconds:**
A Bloom filter is a space-efficient probabilistic set membership structure. It can tell you "definitely NOT in set" or "possibly in set." False positives are possible; false negatives are not. It uses a bit array of size m and k hash functions. Each insert sets k bits; each query checks k bits (all set = "possibly present"; any clear = "definitely absent"). Used in databases (HBase, Cassandra, RocksDB) to avoid disk reads for non-existent keys, in CDNs to check cached content, and in Chrome's malware URL detection.

**3 minutes:**
The fundamental trade-off: exact set membership (HashSet) uses O(n * element_size) memory. A Bloom filter uses O(m) bits total regardless of element size, where m is tuned by the desired false positive rate. For 1 million elements with 1% false positive rate: ~9.6 bits per element = 1.2MB. A HashSet of 1 million strings (average 20 bytes) = 20MB+. 16x space reduction.

Implementation: bit array B[0..m-1], initially all zeros. k independent hash functions h_1, ..., h_k each mapping any element to a position in [0, m-1].

Insert(x): for each i in [1,k]: set B[h_i(x)] = 1.
Query(x): for each i in [1,k]: if B[h_i(x)] == 0 return "definitely not present." If all k bits are 1: return "possibly present."

False positive rate: (1 - e^(-kn/m))^k. Optimal k = (m/n) * ln(2) ~= 0.7 * (m/n). For false positive rate epsilon: m = -n * ln(epsilon) / (ln 2)^2 ~= -1.44 * n * log_2(epsilon) bits.

Key limitation: Bloom filters do not support deletion (setting a bit to 0 would affect other elements that set the same bit). Counting Bloom filters extend each bit to a counter to support deletion at the cost of space.

**Blank Mind Recovery:**
**(1) Core idea:** "Bit array + k hash functions. Each insert sets k bits. False positives possible, false negatives impossible."
**(2) Formula:** "For n=1M, epsilon=1%: m ~= 9.6 * n bits = 1.2MB. Much smaller than HashSet."
**(3) Where used:** "HBase/Cassandra: skip disk reads for absent keys. Chrome: block malware URLs. CDN: cache existence check."
**(4) Limitation:** "No deletion (standard). No element retrieval. Only set membership."

---

### 📘 Concept Explanation

**What it is:**
A Bloom filter is a probabilistic set data structure using a bit array and multiple hash functions. It trades perfect accuracy for massive space savings: false positives are possible but false negatives are impossible.

**The problem it solves:**
Exact set membership using a hash set or BST requires O(n * key_size) space. For millions of elements, this may exceed available memory. Bloom filters provide approximate membership in O(m) bits where m depends on the desired false positive rate, not the element size.

**Structure and operations:**

```
Bloom Filter: m=16 bits, k=3 hash functions

Initial state:
B: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]

Insert "alice":
  h1("alice") = 3 -> B[3] = 1
  h2("alice") = 7 -> B[7] = 1
  h3("alice") = 12 -> B[12] = 1
B: [0,0,0,1,0,0,0,1,0,0,0,0,1,0,0,0]

Insert "bob":
  h1("bob") = 1 -> B[1] = 1
  h2("bob") = 7 -> B[7] = 1 (already set)
  h3("bob") = 14 -> B[14] = 1
B: [0,1,0,1,0,0,0,1,0,0,0,0,1,0,1,0]

Query "alice": check B[3]=1, B[7]=1, B[12]=1
  All 1 -> "possibly present" (CORRECT: true positive)

Query "carol": h1=3, h2=7, h3=10
  B[3]=1, B[7]=1, B[10]=0
  Any 0 -> "definitely NOT present" (CORRECT)

Query "dave": h1=1, h2=7, h3=14
  B[1]=1, B[7]=1, B[14]=1
  All 1 -> "possibly present" (WRONG: false positive!)
  "dave" was never inserted but hits existing bits
```

> **Diagram walkthrough:** Bloom filter state after inserting "alice" and "bob". The bit array shows which positions were set by the three hash functions for each element. Query for "carol" is correctly answered "absent" because bit 10 is still 0. Query for "dave" produces a false positive - "dave" was never inserted, but its three hash positions (1, 7, 14) all happen to have been set by "bob"'s insertions. The key relationship: a false positive occurs when all k bits for a query element are 1 due to collisions with bits set by OTHER inserted elements. False negatives are impossible because an element can only set its own bits - those bits are never cleared. Edge case: as more elements are inserted, more bits are set and the false positive rate increases. When all m bits are 1, every query returns "possibly present" - the filter is saturated and useless. Insight: the false positive rate is a function of the fill level (n/m ratio) - designing the Bloom filter requires estimating the final n and setting m accordingly.

**Mathematical analysis and optimal parameters:**

```
False positive rate formula:
  FPR = (1 - e^(-kn/m))^k

Optimal k (hash functions) for given m, n:
  k* = (m/n) * ln(2) ~= 0.693 * (m/n)

Optimal m (bits) for given n, target FPR epsilon:
  m* = -n * ln(epsilon) / (ln 2)^2
     ~= 1.44 * n * log2(1/epsilon) bits

Example: n=1M elements, epsilon=1% FPR:
  m = 1.44 * 1M * log2(100) ~= 9.56M bits ~= 1.2MB
  k = (9.56 / 1) * 0.693 ~= 7 hash functions

FPR at different settings (n=1M):
  m=4.8M bits (4.8 bits/elem), k=3: ~10% FPR
  m=9.6M bits (9.6 bits/elem), k=7: ~1% FPR
  m=14.4M bits (14.4 bits/elem), k=10: ~0.1% FPR
  m=19.2M bits (19.2 bits/elem), k=14: ~0.01% FPR

Rule of thumb: each extra bit/element reduces FPR by ~0.7x
```

> **Code walkthrough:** Bloom filter mathematical analysis. The KEY MECHANISM: the false positive rate formula (1 - e^(-kn/m))^k arises from the probability that ALL k bit positions for a non-inserted element are set by other insertions. The optimal k minimizes this formula and works out to k* = (m/n) * ln(2). WHY IT MATTERS: these formulas allow precise engineering of the Bloom filter for a given application: fix n (expected elements) and epsilon (acceptable FPR), then compute the required m and k. WHAT BREAKS: if n grows beyond the designed capacity (more elements inserted than expected), the actual FPR exceeds the design target. Fix: overestimate n by 2x in the initial design. TAKEAWAY: the ~9.6 bits per element rule for 1% FPR is the most useful benchmark - memorize this for interviews to quickly estimate Bloom filter size requirements.

**Implementation:**

```java
import java.util.BitSet;

class BloomFilter {
    private final BitSet bits;
    private final int m;  // bit array size
    private final int k;  // hash function count

    BloomFilter(int n, double fpr) {
        // Compute optimal m and k from n and fpr
        this.m = optimalM(n, fpr);
        this.k = optimalK(m, n);
        this.bits = new BitSet(m);
    }

    static int optimalM(int n, double fpr) {
        return (int) Math.ceil(
            -n * Math.log(fpr) / (Math.log(2) * Math.log(2))
        );
    }
    static int optimalK(int m, int n) {
        return Math.max(1,
            (int) Math.round((double)m / n * Math.log(2))
        );
    }

    // Use double hashing to generate k hash positions
    // from two base hashes (Kirsch-Mitzenmacher, 2006)
    private int hash(byte[] data, int seed) {
        // MurmurHash3 or FNV32 in practice
        return Math.abs(
            Arrays.hashCode(data) * seed
        ) % m;
    }

    void add(String element) {
        byte[] data = element.getBytes();
        for (int i = 0; i < k; i++)
            bits.set(hash(data, i + 1));
    }

    boolean mightContain(String element) {
        byte[] data = element.getBytes();
        for (int i = 0; i < k; i++)
            if (!bits.get(hash(data, i + 1)))
                return false; // definitely absent
        return true; // possibly present
    }
}
// Guava's BloomFilter is production-quality:
// BloomFilter.create(Funnels.stringFunnel(UTF_8), 1_000_000, 0.01)
```

> **Code walkthrough:** Complete Bloom filter implementation. The KEY MECHANISM: optimalM and optimalK compute the mathematically optimal bit array size and hash function count from the expected element count n and desired false positive rate fpr. double hashing (Kirsch-Mitzenmacher) generates k hash positions from 2 base hashes without needing k independent hash functions. mightContain short-circuits on the first unset bit (definitely absent). WHY IT MATTERS: using Guava's BloomFilter in production is strongly preferred over hand-rolling - Guava uses 128-bit MurmurHash3, handles serialization, provides thread-safe variants, and has been extensively tested. WHAT BREAKS: using Arrays.hashCode() directly (as shown) is not a good hash function - it has poor distribution for similar strings. MurmurHash3 or SipHash must be used. TAKEAWAY: the implementation detail that matters most is hash function quality - a bad hash function causes correlated bit-setting patterns that increase false positive rate above theoretical predictions.

---

### 💻 Code Example

**Production pattern: Bloom filter in front of database lookup**

```java
// Pattern: avoid disk reads for non-existent keys
// Used by: HBase, Cassandra, RocksDB, PostgreSQL pg_bloom

class CachedDataService {
    private final BloomFilter<String> bloomFilter;
    private final Database db;
    private int savedDiskReads = 0;
    private int totalQueries = 0;

    // Initialize with expected key count and 1% FPR
    CachedDataService(Database db) {
        this.db = db;
        this.bloomFilter = BloomFilter.create(
            Funnels.stringFunnel(StandardCharsets.UTF_8),
            10_000_000, // 10M expected keys
            0.01        // 1% false positive rate
        );
        // Pre-populate with existing keys
        db.getAllKeys().forEach(bloomFilter::put);
    }

    Optional<Row> getRow(String key) {
        totalQueries++;
        // Bloom filter check: O(k) bit operations
        if (!bloomFilter.mightContain(key)) {
            // Definitely absent: skip disk read
            savedDiskReads++;
            return Optional.empty();
        }
        // Possibly present: go to disk
        // 1% will be false positives (wasted disk read)
        return db.lookup(key); // O(disk read)
    }

    // Expected benefit: 99% of absent-key lookups
    // skip disk read. Assumes ~50% queries for absent keys:
    // 0.5 * 0.99 = 49.5% of all queries save a disk read
}
```

> **Code walkthrough:** Bloom filter as a database read amplification reducer. The KEY MECHANISM: Bloom filter acts as a fast pre-filter - only queries for elements that MIGHT exist reach the database. For a workload where 50% of queries target non-existent keys, the Bloom filter eliminates 99% of those non-existent-key disk reads (1% FPR means 1% are false positives that still reach the database). WHY IT MATTERS: this is the exact pattern used in Cassandra, HBase, and RocksDB - each SSTable (sorted string file on disk) has a Bloom filter in memory. Before reading an SSTable for a key, the Bloom filter is checked. In a 10-level LSM Tree with many SSTables, this reduces disk reads per point query from O(levels) to O(1) in the common case. WHAT BREAKS: the Bloom filter only helps for ABSENT keys. For keys that exist (true positives), the Bloom filter always says "possibly present" and the disk read always happens. TAKEAWAY: Bloom filter effectiveness depends on the ratio of absent-key queries to total queries - if 99% of queries target existing keys, the Bloom filter reduces only 1% of queries, making it less beneficial.

**Counting Bloom filter for deletion support:**

```java
// Standard Bloom filter: no deletion
// Counting Bloom filter: each "bit" is a counter

class CountingBloomFilter {
    private final int[] counters; // 4-bit each
    private final int m, k;

    void add(String element) {
        for (int pos : hashPositions(element))
            counters[pos]++;  // increment counter
    }

    void remove(String element) {
        // Only safe if element was definitely inserted
        for (int pos : hashPositions(element))
            if (counters[pos] > 0) counters[pos]--;
    }

    boolean mightContain(String element) {
        for (int pos : hashPositions(element))
            if (counters[pos] == 0) return false;
        return true;
    }
}
// Space: 4x standard Bloom filter (4 bits vs 1 bit)
// Deletion caveat: removing an element that was
// never inserted corrupts the filter permanently.
// Must guarantee: only remove what was inserted.
```

> **Code walkthrough:** Counting Bloom filter extending standard Bloom filter with deletion support. The KEY MECHANISM: replace each bit with a small counter (typically 4 bits). Insert increments counters; remove decrements them; mightContain checks for zero counters. WHY IT MATTERS: standard Bloom filters are permanent accretion - you can add but never remove. Counting Bloom filters support deletion at 4x the space cost. WHAT BREAKS: removing an element that was never inserted causes a counter to underflow below its true value, making subsequent queries for other elements that hash to that position incorrectly return false negatives. TAKEAWAY: only remove from a counting Bloom filter elements you are certain were inserted; maintain a separate record of what was added if necessary.

---

### 🎓 Answers by Seniority

**Junior / Mid-level:**
Bloom filter: bit array + k hash functions. Insert sets k bits. Query returns "definitely absent" (any bit 0) or "possibly present" (all bits 1). False positives possible, false negatives impossible. Space: ~9.6 bits/element for 1% FPR. Used in databases to skip disk reads for absent keys. Cannot do deletion (standard), cannot retrieve elements, can only check membership.

**Senior / Staff-level:**
Bloom filters are the simplest member of a family of space-efficient probabilistic structures. At production scale: use Guava's BloomFilter (serializable, thread-safe-ish with copy-on-write). For streaming cardinality: HyperLogLog (~12KB to count 1B unique elements at 2% error). For approximate frequency: Count-Min Sketch (~400KB for top-k frequency counting). For set intersection: MinHash/LSH (locality-sensitive hashing). Each trades accuracy for space. Bloom filter false positive rate degradation over time is a major production concern: Cassandra allows configuring the Bloom filter target FPR per table (cassandra.yaml: bloom_filter_fp_chance = 0.01). When the filter saturates (too many elements inserted beyond design capacity), Cassandra rebuilds it via compaction.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Bloom filters can return false negatives"**
Reality: false negatives are IMPOSSIBLE. An element's k bit positions are set at insertion and never cleared. Any subsequent query for that element will find all k bits set. Only elements NOT in the filter can appear as false positives.

**Misconception 2: "Adding more hash functions always decreases false positive rate"**
Reality: too many hash functions (k > optimal k*) fills the bit array faster, increasing the fill ratio and actually increasing the false positive rate. The optimal k is exactly k* = 0.693 * (m/n). Both too few and too many hash functions degrade accuracy.

**Misconception 3: "Bloom filters support deletion"**
Reality: standard Bloom filters do NOT support deletion. Setting a bit to 0 would affect all other elements that had set the same bit, potentially causing false negatives (which are supposed to be impossible). Counting Bloom filters support deletion at 4x the space cost.

**Misconception 4: "False positive rate stays constant over time"**
Reality: the theoretical FPR assumes exactly n elements are inserted. If more elements are inserted (n grows beyond design capacity), the actual FPR increases. The Bloom filter must be rebuilt with a larger bit array as n grows.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Bloom filter FPR degrades silently as data grows**
- Symptom: increasing rate of "possibly present" results for absent keys; database disk reads increase over time
- Cause: more elements inserted than the initial design capacity n; bit array is too full
- Diagnosis: compute current fill ratio (bits_set / m); should be ~50% at optimal; >80% = FPR significantly above target
- Fix: rebuild Bloom filter with larger m for the new n; in Cassandra, compaction triggers automatic Bloom filter rebuild

**Failure 2: Bad hash function increases FPR above theoretical prediction**
- Symptom: measured FPR is 10% when theory predicts 1% with the same parameters
- Cause: hash functions have poor independence or poor distribution (e.g., using Java's hashCode() which has weak distribution for similar strings)
- Diagnosis: measure actual FPR by querying for known-absent keys; compare to theoretical prediction
- Fix: use cryptographic-quality or purpose-built hash functions (MurmurHash3, xxHash, SipHash); use Guava's BloomFilter which uses MurmurHash3 internally

**Failure 3: Thread safety violation with shared Bloom filter**
- Symptom: concurrent add() and mightContain() cause stale reads or lost updates; bit array corrupted under concurrent access
- Cause: BitSet is not thread-safe; concurrent modifications to the underlying long[] array create data races
- Diagnosis: run with Thread Sanitizer; look for intermittent false negatives (theoretically impossible, so any false negative = concurrent corruption)
- Fix: use Guava's BloomFilter which uses AtomicLongArray internally; or add external synchronization; or use copy-on-write (immutable Bloom filter + replace when full)

---

### 🎯 Interview Deep-Dive

| Timing | Questions |
|--------|-----------|
| Opening (0-3 min) | Basic properties, FPR |
| Mid (3-10 min) | Math, production use |
| Deep-dive (10-20 min) | Variants, system design |

**[JUNIOR] Q1 - [CONCEPT] What is a false positive in a Bloom filter and why can't there be false negatives?**

False positive: query returns "possibly present" for an element that was NEVER inserted. This happens when all k bit positions for the queried element were set by OTHER elements' insertions.

False negative: query returns "definitely absent" for an element that WAS inserted. This is IMPOSSIBLE because: insert(x) sets B[h_1(x)], ..., B[h_k(x)]. These bits are never cleared. query(x) checks the same positions. All bits set by insert(x) will still be set when query(x) runs. Therefore query(x) ALWAYS returns "possibly present" for any element that was inserted.

The asymmetry: bits can only be SET (0->1) and never cleared. This is the source of the false negative impossibility guarantee.

*What separates good from great:* Proving false negative impossibility from first principles (bit positions set on insert, never cleared, query checks same positions) rather than just asserting it.

**[JUNIOR] Q2 - [CONCEPT] How do you size a Bloom filter for 1 million elements with 1% false positive rate?**

Formula: m = -n * ln(epsilon) / (ln 2)^2

m = -(1,000,000) * ln(0.01) / (0.693)^2
m = -(1,000,000) * (-4.605) / 0.480
m = 1,000,000 * 4.605 / 0.480
m ~= 9,590,000 bits ~= 1.2MB

Rule of thumb: ~9.6 bits per element for 1% FPR.

Optimal number of hash functions: k = (m/n) * ln(2) = 9.6 * 0.693 ~= 6.7, round to 7.

So: 1.2MB bit array with 7 hash functions handles 1M elements at 1% FPR.

For comparison: a Java HashSet of 1M strings (average 20 bytes per string) = ~20MB + HashMap overhead (~50MB total). Bloom filter: 1.2MB = 40x smaller.

*What separates good from great:* Knowing the 9.6 bits/element rule of thumb and being able to derive it from the formula - demonstrating mathematical understanding, not just memorization.

**[MID] Q3 - [PRODUCTION] How do HBase and Cassandra use Bloom filters?**

HBase and Cassandra use LSM Trees (Log-Structured Merge trees). Data is stored in multiple files (SSTables in Cassandra, HFiles in HBase) on disk. A single row might exist in the MemTable, the most recent flushed SSTable, or a compacted SSTable.

Problem: for a point lookup (get row by key), the database may need to check multiple files on disk. For a key that doesn't exist, every file would need to be searched (expensive).

Solution: each SSTable has an in-memory Bloom filter containing all keys in that file. Before reading the SSTable from disk, the Bloom filter is consulted:

- Bloom filter says "definitely absent" (0): skip this SSTable. No disk read.
- Bloom filter says "possibly present" (1%): read the SSTable. 1% are false positives.

In a 10-level LSM Tree with 100 SSTables: without Bloom filters, each absent-key lookup reads 100 files = 100 disk I/Os. With 1% FPR Bloom filters: 1 * 100 * 1% = 1 false positive disk read expected = O(1) disk reads.

Cassandra: bloom_filter_fp_chance per table (default 0.01 = 1%). Bloom filter size per SSTable proportional to the number of rows.

*What separates good from great:* Quantifying the benefit: LSM Tree without Bloom filters = O(levels) disk reads per absent-key query. With 1% FPR Bloom filters = O(1) expected disk reads. This is the exact calculation that motivated Bloom filter adoption in every major LSM-based storage system.

**[MID] Q4 - [CODING] Implement Bloom filter add and mightContain using double hashing.**

Double hashing technique (Kirsch-Mitzenmacher, 2006): generate k hash positions from just TWO base hash values (h1, h2) using: h_i(x) = (h1(x) + i * h2(x)) mod m. This avoids computing k independent hash functions.

```java
class SimpleBloomFilter {
    private final BitSet bits;
    private final int m, k;

    void add(String s) {
        long h1 = murmur3_h1(s);
        long h2 = murmur3_h2(s);
        for (int i = 0; i < k; i++) {
            int pos = (int)(
                (h1 + (long)i * h2) % m
            );
            bits.set(Math.abs(pos));
        }
    }

    boolean mightContain(String s) {
        long h1 = murmur3_h1(s);
        long h2 = murmur3_h2(s);
        for (int i = 0; i < k; i++) {
            int pos = (int)(
                (h1 + (long)i * h2) % m
            );
            if (!bits.get(Math.abs(pos)))
                return false;
        }
        return true;
    }
}
```

> **Code walkthrough:** Double hashing Bloom filter implementation. The KEY MECHANISM: derive k hash positions from h1 + i*h2 for i = 0 to k-1. Kirsch-Mitzenmacher proved this achieves the same asymptotic false positive rate as k independent hash functions. WHY IT MATTERS: computing k independent hash functions (e.g., k calls to different hash algorithms) is O(k * element_size); double hashing requires only 2 hash computations regardless of k. WHAT BREAKS: h2(x) must be coprime to m (or m must be prime) to ensure all k positions are distinct. If h2(x) = 0, all k positions equal h1(x) - the Bloom filter degrades to a single hash function with k=1 effective bits. TAKEAWAY: Math.abs() is needed because Java's modulo operator can return negative values for negative inputs; BitSet.set() with a negative index throws ArrayIndexOutOfBoundsException.\n\n*What separates good from great:* Knowing the Kirsch-Mitzenmacher result that double hashing achieves the same FPR as k independent hash functions - this is the standard production optimization used in Guava's BloomFilter implementation.

**[MID] Q5 - [TRADE-OFF] When should you NOT use a Bloom filter?**

Bloom filters are inappropriate when:

1. You need exact answers with no false positives. Use a HashSet. Bloom filters are unsuitable for security-critical membership tests (e.g., checking if a username is taken - false positive means blocking a legitimate username).

2. You need to retrieve the element, not just test membership. Bloom filters store no element data.

3. You need deletion (frequently). Standard Bloom filters don't support deletion. Counting Bloom filters support deletion at 4x space cost - at that point, a HashSet may be competitive.

4. The dataset is small. For n < 10K elements, a HashSet uses trivial memory. A Bloom filter's space advantage only becomes significant at large n.

5. You need to enumerate all elements in the set. Bloom filters have no iteration capability.

6. The false positive rate would cause more harm than the disk/memory savings justify. If a 1% FPR causes 1% of users to see incorrect "item not found" errors, the UX cost may outweigh the infrastructure savings.

*What separates good from great:* The security use case - a Bloom filter should NEVER be used in authentication or authorization (checking valid session tokens, valid API keys) because false positives could grant unauthorized access.

**[SENIOR] Q6 - [PRODUCTION] Design a Bloom filter strategy for a Cassandra table with 100 billion rows.**

100 billion rows at 1% FPR: m = 9.6 * 100B = 960GB of bits = 120GB. Cannot hold in RAM for a single Bloom filter.

But Cassandra doesn't use a single Bloom filter per table. Cassandra uses one Bloom filter PER SSTABLE. With compaction, a well-tuned table has 10-20 SSTables total. Each SSTable holds ~5-10 billion rows (after compaction).

Per-SSTable Bloom filter (10B rows, 1% FPR): m = 9.6 * 10B = 96GB bits = 12GB. Still too large.

Solutions:

1. Increase FPR tolerance: at 10% FPR, m = 4.8 bits/element = 6GB per SSTable. Trade more disk reads for less memory.

2. Use off-heap memory: Cassandra stores Bloom filters in off-heap direct memory (bypasses GC). Total memory usage ~= (SSTables * rows_per_sstable * bits_per_element / 8).

3. Partitioned Bloom filters: partition the table into key ranges; each partition has its own smaller Bloom filter. Queries route to the correct partition Bloom filter. Trade computation for memory.

4. Accept higher FPR for cold SSTables: hot (recently written) SSTables have strict FPR; cold SSTables that are rarely accessed have relaxed FPR. Tiered FPR management.

Real Cassandra: bloom_filter_fp_chance controls target FPR. For a 1TB table with 100B rows, teams often accept 10% FPR to reduce Bloom filter memory from 12GB to 6GB per SSTable.

*What separates good from great:* Understanding that Cassandra uses per-SSTable Bloom filters (not per-table), that off-heap memory is used to avoid GC pressure, and that FPR is a configurable trade-off between memory and I/O.

**[SENIOR] Q7 - [SYSTEM] How does Google's Bigtable use Bloom filters?**

Bigtable (and its open-source equivalent HBase) uses Bloom filters at the SSTable level - same pattern as Cassandra.

Each SSTable file on GFS (Google File System) has an in-memory Bloom filter (per column family). Before reading an SSTable for a row key, the Bloom filter is checked:
- Not present: skip SSTable (no I/O)
- Possibly present: read SSTable index, then data block (2 I/Os)

Bigtable's two-level index: SSTable index (in memory) + data blocks (on disk). Bloom filter is checked before the SSTable index, making it a three-tier structure: Bloom filter -> SSTable index -> data block.

Bloom filter location: in the SSTable footer (on disk) but loaded into memory when the SSTable is opened. Memory budget for Bloom filters is configurable.

Google's paper (2006) reports that Bloom filters eliminate ~75% of unnecessary disk reads for lookups of non-existent rows - the common case in many applications (e.g., checking if a user has performed an action they haven't).

*What separates good from great:* Knowing the Bigtable 2006 paper's result (~75% disk read reduction from Bloom filters) and understanding the three-tier lookup structure (Bloom filter -> SSTable index -> data block).

**[SENIOR] Q8 - [DEBUGGING] Your system's false positive rate is 5x higher than the theoretical prediction. Diagnose.**

Step 1: verify actual element count vs design capacity. If 5M elements were inserted into a Bloom filter designed for 1M (5x capacity), the actual FPR would be approximately (1-e^(-k*5n/m))^k which is much higher than design FPR.

Step 2: verify hash function quality. Run a chi-square test on hash output distribution: for 1M random inputs, the bit positions set should be uniformly distributed across [0, m). Significant deviation = poor hash function.

Step 3: verify k (hash function count). Double-check that the actual k used matches the theoretical optimal. Using k=3 when optimal is k=7 gives significantly higher FPR.

Step 4: check for correlated inputs. The FPR formula assumes random inputs. If inputs are highly correlated (e.g., sequential integers 1, 2, 3...) and the hash function has poor distribution for sequential inputs, effective k is reduced.

Step 5: measure empirically. Take a sample of 10K known-absent keys. Query each. Count "possibly present" returns. This gives the true FPR independent of theoretical assumptions.

Most likely cause: n exceeded design capacity. Check insertion count vs design n.

*What separates good from great:* The empirical measurement step (sample 10K absent keys, measure actual FPR) as the definitive diagnosis - theoretical prediction can be wrong due to hash function quality or capacity issues, but empirical measurement always tells the truth.

**[STAFF] Q9 - [THEORY] Prove that the optimal number of hash functions k is (m/n) * ln(2).**

The false positive rate formula: FPR = (1 - e^(-kn/m))^k

Let x = kn/m (the expected fraction of bits set per hash function, times k). Then:

FPR(k) = (1 - e^(-k*n/m))^k

To minimize, take d(FPR)/dk and set to 0. It's easier to minimize log(FPR):

log(FPR) = k * log(1 - e^(-kn/m))

Let t = e^(-kn/m). Then log(FPR) = k * log(1 - t) where t = e^(-kn/m).

Taking the derivative with respect to k and setting to 0:

d/dk [k * log(1-t)] = log(1-t) + k * d/dk[log(1-t)] = 0

Working through (omitting algebra):
The minimum occurs when t = 1/2, i.e., e^(-kn/m) = 1/2.

Solving: -kn/m = ln(1/2) = -ln(2), so k = (m/n) * ln(2) ~= 0.693 * (m/n).

At the optimal k: each bit is set with probability 1/2. The Bloom filter is exactly half full (half the bits are 1).

*What separates good from great:* Deriving that at optimal k, the Bloom filter is exactly half full (each bit independently set with probability 1/2) - this gives an elegant rule of thumb: check if your Bloom filter is ~50% full after inserting n elements. If significantly more, k may be non-optimal.

**[STAFF] Q10 - [ARCHITECTURE] Describe three probabilistic data structures beyond Bloom filters and when to use each.**

1. HyperLogLog (cardinality estimation):
   Problem: count unique elements in a stream of billions.
   How: hash each element, take the longest leading zero run. The maximum leading zeros observed is a probabilistic estimator of log_2(n). Multiple registers and harmonic mean reduce variance.
   Space: ~12KB for 2% error rate, regardless of n (even billions of unique elements).
   Use when: counting unique visitors, unique queries, unique IPs at web scale. Redis HyperLogLog (PFADD/PFCOUNT).

2. Count-Min Sketch (frequency estimation):
   Problem: estimate frequency of each element in a stream (top-K queries).
   How: 2D array of counters with d hash functions (rows) * w counters (columns). Increment counter at (h_i(x), x) for each insert. Query returns min of d counters.
   Space: O(d * w) = O(1/epsilon * log(1/delta)) for epsilon error, delta failure probability.
   Use when: finding frequent items (heavy hitters), word frequency in log streams, network traffic analysis. Can't do deletion (standard) - use conservative updates or CMS with additions only.

3. MinHash / Locality-Sensitive Hashing (similarity):
   Problem: find documents/users/products that are similar to a query.
   How: MinHash computes signatures that have high collision probability for similar items (Jaccard similarity). LSH groups items with similar signatures into the same bucket with high probability.
   Space: O(k * n) for k hash functions on n items.
   Use when: near-duplicate detection, recommendation systems (find similar users), plagiarism detection, genome sequence similarity.

*What separates good from great:* Mapping each structure to its production use case with a concrete example (Redis HyperLogLog, log stream heavy hitters, recommendation systems) and knowing the approximate parameters (12KB for HyperLogLog, epsilon/delta for CMS).

**[STAFF] Q11 - [ARCHITECTURE] How would you build a distributed Bloom filter for 1 trillion elements?**

1 trillion elements at 1% FPR: m = 9.6T bits = 1.2TB. Too large for RAM.

Approach 1 - Partition by key hash: divide the key space into 1000 partitions. Partition i handles keys where hash(key) % 1000 == i. Each partition: 1B elements, 1.2GB Bloom filter. Distribute partitions across 10 machines (100 partitions each). Each machine holds 120GB of Bloom filter data in RAM (feasible with 256GB+ RAM servers).

Lookup: hash key to determine partition, route to appropriate machine, check local Bloom filter. Single-hop lookup: O(1) network round trip.

Problem: machine failure loses 10% of partitions. Fix: replicate each partition to 2 machines (2x RAM cost).

Approach 2 - Hierarchical Bloom filters: coarse global Bloom filter (high FPR, small) + fine per-shard Bloom filter (low FPR, accessed only for "possibly present" responses). Global filter: 1T elements at 10% FPR = 144GB total = ~144MB per machine across 1000 machines. Fine filter per shard: accessed for 10% of queries, still O(1) lookups.

Approach 3 - Accept the trade-off: for truly massive datasets, a Bloom filter occupying terabytes of RAM is impractical. Use a probabilistic data structure designed for disk: fingerprint-based filters (Cuckoo filter has delete support and is more space-efficient for large n).

*What separates good from great:* Proposing the partitioned approach with concrete numbers (1000 partitions, 1.2GB each, 10 machines) and knowing Cuckoo filters as an alternative with deletion support and better cache performance than Bloom filters.

**[STAFF] Q12 - [THEORY] What is a Cuckoo filter and how does it improve on Bloom filters?**

A Cuckoo filter (Fan et al., SIGCOMM 2014) uses cuckoo hashing to store fingerprints (partial hashes) of inserted elements.

Structure: array of buckets, each holding 4 fingerprints. Insert: compute fingerprint fp = hash(x); try to insert fp in bucket h1(x) OR h2(x). If full, evict an existing fingerprint and re-insert it at its alternate bucket (cuckoo displacement). Delete: compute fp, find bucket h1(x) or h2(x), remove fp.

Advantages over Bloom filter:
1. Deletion supported: remove the fingerprint directly.
2. Better cache performance: bucket access is cache-friendly (buckets aligned to cache lines).
3. Slightly better space efficiency at <3% FPR: Cuckoo filter uses ~8 bits/element for 3% FPR vs. 10 bits/element for Bloom filter.

Disadvantages:
1. Lookup occasionally visits up to 2 buckets (vs Bloom filter's k bit accesses).
2. Insert is O(1) amortized but O(log n) worst case (cuckoo displacement chain).
3. Slightly higher false positive rate for very low FPR targets.

Usage: Cuckoo filters are preferred when deletion is needed AND space efficiency is important. Redis modules, FoundationDB, some databases use Cuckoo filters alongside or instead of Bloom filters.

*What separates good from great:* Knowing Cuckoo filters as the practical production alternative to Bloom filters when deletion is needed, and being able to compare space efficiency (8 bits/element for Cuckoo at 3% FPR vs 10 bits/element for Bloom).

---

### ⚖️ Comparison Table

| Property | Bloom Filter | Counting BF | Cuckoo Filter | HyperLogLog | HashSet |
|----------|-------------|-------------|---------------|-------------|---------|
| Membership | Yes (FP possible) | Yes (FP possible) | Yes (FP possible) | No | Yes (exact) |
| Deletion | No | Yes | Yes | No | Yes |
| False positives | Yes (~1% if tuned) | Yes | Yes (~1% if tuned) | N/A | No |
| False negatives | Never | Never | Never | N/A | No |
| Space | ~9.6 bits/elem at 1% | ~38 bits/elem at 1% | ~8 bits/elem at 3% | 12KB total | O(n * elem_size) |
| Cardinality | No | Yes (size()) | Yes (size()) | Yes (~2% error) | Yes (exact) |
| Concurrent | Needs sync | Needs sync | Needs sync | External sync | ConcurrentHashSet |
| Scalable | Re-create to expand | Re-create | Re-create | Merge-able | Resize |

---

### 🏛️ System Design

**Design the URL blacklist check for a web browser (Chrome's Safe Browsing).**

**Requirements:** 1 billion malicious URLs. Check each visited URL in < 1ms. Updates every 30 minutes. Works offline (local check, not server round-trip). Memory budget: < 100MB.

**Architecture:**

```
URL Safety Check Architecture:

Browser -> Local Bloom Filter Check
             |
        Definitely Safe? -> Allow (no network)
             |
        Possibly Unsafe?
             |
          Server API -> Definitive answer
          (only for ~1% of safe URLs = false positives
           + all actually unsafe URLs)

Bloom Filter parameters:
  n = 1B URLs, epsilon = 0.1% FPR
  m = 1.44 * 1B * log2(1000) = ~14.4B bits = 1.8GB
  Too large for 100MB budget!

Revised: accept 1% FPR (100x more server calls for safe URLs)
  m = 9.6 * 1B = 9.6GB = 1.2GB -> still too large

Solution: Google's approach - partial hashes + server confirmation
  Store 32-bit prefix of full URL hash in sorted array
  1B * 4 bytes = 4GB -> still too large

Final solution: local Bloom filter for 10M known-bad URLs
  + server lookup for anything in "recently reported" list
  + 30-min sync of top-10M list -> 9.6MB local storage
```

> **Diagram walkthrough:** Chrome Safe Browsing architecture showing how Bloom filter trade-offs drive system design. The key insight: 1 billion URLs with low FPR exceed reasonable local storage. Chrome's actual solution uses a two-tier approach: a local Bloom filter (or hash prefix list) for the most commonly blocked URLs, with a server API for comprehensive checking. The Bloom filter eliminates server round-trips for the vast majority of safe URLs (if a URL is definitely not in the local blacklist, no network call needed). Only "possibly unsafe" responses trigger a server call. A 1% FPR means 1% of safe URLs trigger an unnecessary server call - acceptable if the call is fast. Edge case: the bloom filter must be updated regularly as new malicious URLs are discovered; Chrome downloads delta updates every 30 minutes. Insight: the system design is driven by the memory budget constraint - trading FPR for memory is the central engineering decision, demonstrating that Bloom filter parameters are dictated by system constraints, not just theory.

---

### 📊 Diagram

```
Bloom filter FPR vs bits-per-element:

bits/elem | FPR      | Use case
----------|----------|----------------------------------
4.8       | ~10%     | Coarse pre-filter, multi-level
6.2       | ~3%      | Cache existence check
9.6       | ~1%      | Database read amplification (std)
14.4      | ~0.1%    | User-facing membership check
19.2      | ~0.01%   | High-precision, near-exact check

Space for 1M elements at various FPRs:
  1%  FPR: 9.6M bits = 1.2MB
  0.1% FPR: 14.4M bits = 1.8MB
  10%  FPR: 4.8M bits = 0.6MB

Cost of false positive: extra disk read in DB
Benefit of lower FPR: fewer wasted disk reads
Trade: more RAM for lower FPR

Bloom filter operations (k=7, m=9.6M):
  add:          7 bit positions set
  mightContain: 7 bit reads, short-circuit on 0
  Time:         O(k) = O(7) = O(1)
  Space:        1.2MB for 1M elements @ 1% FPR
```

> **Diagram walkthrough:** Bloom filter design parameter table mapping FPR to bits/element with practical use cases. The key relationship: each halving of FPR (from 1% to 0.5%) requires ~1.5 more bits/element. The cost-benefit row shows the production trade-off explicitly: lower FPR requires more RAM but reduces wasted disk reads. For database use (Cassandra, HBase), 1% FPR at 9.6 bits/element is the industry standard because it eliminates 99% of absent-key disk reads with minimal RAM overhead. Edge case: for very small n (< 10K), the fixed overhead of the Bloom filter structure (hash function setup, BitSet initialization) makes HashSet more practical. Insight: the "operations" section shows why Bloom filter queries are effectively O(1) regardless of n - k bit reads with early termination is constant-time independent of the bit array size. The Bloom filter's query time is determined by k (hash count), not by n or m.
