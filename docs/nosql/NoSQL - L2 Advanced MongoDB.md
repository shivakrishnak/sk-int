---
layout: default
title: "NoSQL - L2 Advanced MongoDB"
parent: "NoSQL"
nav_order: 4
permalink: /nosql/l2-advanced-mongodb/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [MongoDB Aggregation Pipeline](#mongodb-aggregation-pipeline) | ★★☆ |
| 2 | [MongoDB Replication and Replica Sets](#mongodb-replication-and-replica-sets) | ★★☆ |

---

# MongoDB Aggregation Pipeline

---

### 🎯 Model Answer

**30 seconds:**
> MongoDB's Aggregation Pipeline transforms documents through a sequence of stages:
> `$match` (filter), `$group` (aggregate), `$project` (reshape), `$sort`, `$limit`,
> `$lookup` (JOIN), `$unwind` (flatten array), `$addFields`. Each stage's output
> is the next stage's input. Unlike `find()`, the pipeline can compute, join, and
> reshape data. Use `$match` early to filter before expensive stages like `$group`.

**3 minutes (Senior):**
> The Aggregation Pipeline is MongoDB's data transformation engine. It processes
> documents through an ordered list of stages, each producing a stream of documents
> for the next stage. Key stages: `$match` is equivalent to SQL WHERE (apply early for
> index use); `$group` is equivalent to SQL GROUP BY with accumulator operators (`$sum`,
> `$avg`, `$max`, `$min`, `$push`, `$addToSet`); `$project` shapes the output (include,
> exclude, and compute fields); `$lookup` performs a LEFT OUTER JOIN to another
> collection; `$unwind` deconstructs an array into individual documents (one doc per
> element); `$facet` runs multiple pipelines on the same data for multi-faceted
> aggregations. Pipeline optimization: indexes are used by `$match` and `$sort` when
> placed before `$group`; `$match` should be the first stage to reduce document count
> early. The `explain()` method works on aggregation pipelines for performance analysis.

**Framework:** Match (filter) -> Group (aggregate) -> Project (reshape) -> Sort/Limit

**Blank Mind Recovery:**

**(1) Restate:** "Aggregation Pipeline: sequence of stages. `$match` filters,
`$group` aggregates (sum/avg), `$project` reshapes, `$lookup` joins, `$unwind`
flattens arrays. Apply `$match` early for index use."

**(2) First principles:** "Each stage transforms the document stream. The output of
stage N is the input to stage N+1. MongoDB optimizes the pipeline: merges adjacent
`$match` stages, uses indexes for early `$match` and `$sort`."

**(3) Bridge:** "The Aggregation Pipeline is like an assembly line. Raw documents
(raw materials) enter one end. Each station (stage) performs one transformation.
The finished output leaves the other end. Early quality control (`$match`) reduces
the work for all downstream stations."

---

### 📘 Concept Explanation

**Core Aggregation Stages:**

```text
AGGREGATION PIPELINE STAGES:

  $match    Filter documents (uses indexes if first)
            {$match: {status: "active", age: {$gt: 18}}}

  $group    Aggregate by key, accumulate values
            {$group: {
              _id: "$department",
              total_salary: {$sum: "$salary"},
              avg_salary: {$avg: "$salary"},
              employees: {$push: "$name"}
            }}

  $project  Reshape output (include/exclude/compute)
            {$project: {
              name: 1,
              total: {$multiply: ["$qty","$price"]},
              _id: 0
            }}

  $sort     Sort documents by field(s)
  $limit    Cap number of output documents
  $skip     Skip N documents

  $lookup   LEFT OUTER JOIN to another collection
            {$lookup: {
              from: "products",
              localField: "product_id",
              foreignField: "_id",
              as: "product_info"
            }}

  $unwind   Deconstruct array to one doc per element
            {$unwind: "$tags"}

  $addFields  Add new computed fields
  $facet      Multiple sub-pipelines on same input
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the core aggregation stages with their
> syntax and purpose. (2) KEY MECHANISM: stages form a pipeline; each stage is an
> independent transformation; MongoDB optimizes the pipeline execution order in some
> cases (e.g., `$sort + $limit` before `$group` is pushed to after `$group` if possible);
> the `$match` stage uses indexes when it is the first stage in the pipeline. (3) WHY
> IT MATTERS: the aggregation pipeline replaces complex application-side data processing
> with server-side computation; a `$group` that computes totals across 10 million documents
> is far more efficient than fetching 10 million documents and summing in the application.
> (4) WHAT BREAKS: using `$unwind` on a large array field before `$match` creates one
> document per array element (multiplicative cardinality explosion); always `$match` before
> `$unwind` to reduce the document count first. (5) TAKEAWAY: the golden rule of pipeline
> optimization: `$match` and `$project` as early as possible to reduce document count
> and size for all downstream stages.

---

### 💻 Code Example

```python
from pymongo import MongoClient

client = MongoClient("mongodb://localhost:27017")
db = client.company
employees = db.employees

# Basic pipeline: sales by department
pipeline = [
    # Stage 1: filter (uses index on department)
    {"$match": {"status": "active"}},

    # Stage 2: group and aggregate
    {"$group": {
        "_id": "$department",
        "total_salary": {"$sum": "$salary"},
        "avg_salary": {"$avg": "$salary"},
        "headcount": {"$sum": 1},
        "names": {"$push": "$name"}
    }},

    # Stage 3: sort by total salary
    {"$sort": {"total_salary": -1}},

    # Stage 4: top 5 departments only
    {"$limit": 5},

    # Stage 5: rename _id to department
    {"$project": {
        "department": "$_id",
        "total_salary": 1,
        "avg_salary": {"$round": ["$avg_salary", 2]},
        "headcount": 1,
        "_id": 0
    }}
]

results = list(employees.aggregate(pipeline))
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a five-stage aggregation pipeline that filters
> active employees, groups by department to compute salary stats, sorts by total salary,
> limits to top 5, and projects clean output. (2) KEY MECHANISM: `$match` as the first
> stage uses any index on `status`; the filtered documents (a fraction of the total)
> flow into `$group`; `$group` computes `$sum: "$salary"` (sum of salary field) and
> `$sum: 1` (count); `$push` accumulates all names into an array; `$round` in `$project`
> rounds the average to 2 decimal places. (3) WHY IT MATTERS: this pipeline returns 5
> documents regardless of how many employees exist; without the pipeline, the application
> would fetch all active employees, group them in application code, sort, and limit; at
> 100,000 employees, the pipeline is 100x less data transferred. (4) WHAT BREAKS: `$push`
> in `$group` accumulates all values into an array; for large groups, this array can grow
> very large and exceed the 16 MB document limit; use `$addToSet` for unique values or
> avoid `$push` for large groups. (5) TAKEAWAY: always `$match` first to minimize the
> documents flowing through the pipeline; `$sort` after `$group` (not before) unless
> you need sorted input for `$first`/`$last` accumulators.

```python
# $lookup: JOIN orders with customer details
pipeline_join = [
    # Only look at recent orders
    {"$match": {"status": "shipped",
                "created_at": {"$gte": last_week}}},

    # JOIN to customers collection
    {"$lookup": {
        "from": "customers",
        "localField": "customer_id",
        "foreignField": "_id",
        "as": "customer"  # result is array
    }},

    # Unwind customer (1-element array -> doc)
    {"$unwind": "$customer"},

    # Compute order value and project
    {"$project": {
        "order_id": "$_id",
        "customer_name": "$customer.name",
        "customer_email": "$customer.email",
        "total": 1,
        "created_at": 1,
        "_id": 0
    }},
    {"$sort": {"created_at": -1}},
    {"$limit": 100}
]

# BAD: no index on customers._id -> COLLSCAN per order
# GOOD: _id is always indexed in MongoDB; $lookup is safe
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a `$lookup` pipeline that joins recent shipped
> orders to the customers collection, followed by `$unwind` to flatten the single-element
> result array, then projects the combined fields. (2) KEY MECHANISM: `$lookup` performs
> a LEFT OUTER JOIN; for each document in the pipeline (orders), MongoDB searches the
> `from` collection (customers) for documents where `foreignField` matches `localField`;
> the matching documents are added as an array in the `as` field; `$unwind` flattens
> this array; since there is exactly one customer per order, `$unwind` produces one
> output document per input document. (3) WHY IT MATTERS: the `_id` field in the
> customers collection is always indexed; the `$lookup` uses this index for each order;
> without the index on the foreign field, `$lookup` performs a COLLSCAN of the customers
> collection for each order, which is O(N * M) complexity. (4) WHAT BREAKS: if
> `$lookup` is on a custom field (not `_id`), that field MUST be indexed in the `from`
> collection; unindexed `$lookup` is prohibitively slow on large collections. (5)
> TAKEAWAY: always index the `foreignField` in the `from` collection before using
> `$lookup`; verify with explain() on the aggregation pipeline.

```python
# $facet: multiple aggregations in one pipeline pass
pipeline_facet = [
    {"$match": {"category": "electronics"}},
    {"$facet": {
        # Sub-pipeline 1: price ranges
        "price_ranges": [
            {"$bucket": {
                "groupBy": "$price",
                "boundaries": [0, 100, 500, 1000, 5000],
                "default": "5000+",
                "output": {"count": {"$sum": 1}}
            }}
        ],
        # Sub-pipeline 2: top brands
        "top_brands": [
            {"$group": {"_id": "$brand",
                         "count": {"$sum": 1}}},
            {"$sort": {"count": -1}},
            {"$limit": 5}
        ],
        # Sub-pipeline 3: total and average price
        "stats": [
            {"$group": {
                "_id": None,
                "total": {"$sum": 1},
                "avg_price": {"$avg": "$price"}
            }}
        ]
    }}
]
# Returns one document with three facets
# Equivalent to three separate aggregation queries
# but processes the $match filter only once
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the `$facet` stage running three sub-pipelines
> on the same filtered document set in a single aggregation pass. (2) KEY MECHANISM:
> `$facet` receives all documents passing the preceding stages and fans them out to each
> named sub-pipeline simultaneously; each sub-pipeline processes the same input documents
> independently; the results are combined into a single output document with one field
> per sub-pipeline. (3) WHY IT MATTERS: a search results page often needs counts by price
> range, counts by brand, and total count simultaneously; without `$facet`, three separate
> aggregation queries are needed; with `$facet`, MongoDB applies the `$match` filter once
> and runs all three aggregations in one pass. (4) WHAT BREAKS: `$facet` sub-pipelines
> cannot include `$out`, `$merge`, `$indexStats`, or `$facet` themselves; sub-pipeline
> results accumulate in memory; very large `$push` or `$group` operations within `$facet`
> can hit the 100 MB memory limit per stage. (5) TAKEAWAY: use `$facet` for search
> results pages that need multiple aggregations on the same filtered dataset; it reduces
> the number of database round-trips from N to 1.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> The Aggregation Pipeline is MongoDB's way to do SQL-style GROUP BY, JOIN, and
> computed fields. Use `$match` to filter early (it uses indexes), `$group` to aggregate
> (like GROUP BY), `$project` to pick fields, `$lookup` for JOINs, `$unwind` to flatten
> arrays, `$sort` and `$limit` for ordering and pagination. Think of it as an assembly
> line: each stage transforms the documents flowing through it.

---

**Senior / Staff (5+ years):**
> Pipeline optimization is the key skill. The three rules: (1) `$match` early (reduces
> document count, uses indexes); (2) `$project` early (reduces document size, less data
> per stage); (3) `$sort + $limit` together (MongoDB can use a "top-K sort" internally,
> avoiding a full sort). The hidden cost: `$unwind` before `$match` explodes cardinality;
> `$lookup` without a `foreignField` index is a COLLSCAN per document. The 100 MB limit:
> by default, aggregation stages are bounded at 100 MB of RAM; for large operations, use
> `allowDiskUse: true`. Monitor `explain("executionStats")` on all production aggregation
> pipelines.

---

### ⚠️ Common Misconceptions

**Misconception 1: "`$match` always uses an index."**

`$match` only uses an index if it is one of the first stages in the pipeline before
`$group`, `$unwind`, or `$lookup`. If `$match` comes after `$unwind`, the documents
have already been multiplied; there is no index to use on the unwind output. Place
`$match` as the first stage before any stage that multiplies or transforms the
document count.

**Misconception 2: "`$lookup` is equivalent to SQL JOIN in performance."**

`$lookup` performs a nested loop join (for each document, search the `from` collection).
SQL JOIN implementations use hash join and merge join algorithms that are significantly
more efficient for large datasets. `$lookup` is adequate for small-to-medium lookups
with an indexed `foreignField`; for large cross-collection joins, consider denormalizing
or pre-joining data using the snapshot pattern at write time.

---

### ⚠️ Common Misconceptions

**Misconception 3: "Aggregation pipeline results are always sorted."**

`$group` output is not sorted. The order of documents from `$group` is undefined.
Always add an explicit `$sort` after `$group` if the output order matters. The same
applies to `$facet` sub-pipeline results: sub-pipeline outputs are in arbitrary order
unless explicitly sorted.

**Misconception 4: "allowDiskUse is always safe to enable."**

`allowDiskUse: true` allows the pipeline to spill to disk when a stage exceeds 100 MB
of RAM. This prevents OOM errors but significantly degrades performance (disk I/O is
orders of magnitude slower than RAM). If a production pipeline requires `allowDiskUse`,
it is a signal that the pipeline is doing too much work; optimize with indexes, earlier
`$match` stages, or data pre-processing at write time.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Pipeline produces no output unexpectedly.**

Symptom: `list(collection.aggregate(pipeline))` returns an empty list.
Root cause: `$match` filter matches no documents; or a `$lookup` with no matches
followed by `$unwind` drops all documents (by default `$unwind` removes documents
with no array match).
Diagnosis: run each stage individually by progressively adding stages and checking
the count at each step.
Fix: add `{preserveNullAndEmptyArrays: true}` to `$unwind` to preserve documents
where the `$lookup` found no matches; use `$match` with lenient filters to debug.

**Failure Mode 2: Pipeline exceeds 100 MB memory limit.**

Symptom: `MongoOperationFailure: Exceeded memory limit for $group stage`.
Root cause: a `$group` or `$sort` stage exceeds 100 MB of RAM; often caused by
a `$push` accumulator collecting large arrays.
Fix: add `allowDiskUse=True` to `aggregate()` as a temporary fix; then optimize
the pipeline by adding `$match` earlier to reduce cardinality, replacing `$push`
with `$addToSet` for deduplication, or batching the aggregation.

---

### ⚖️ Comparison Table

| Stage | SQL Equivalent | Notes |
|---|---|---|
| `$match` | `WHERE` | Uses index if first; filter early |
| `$group` | `GROUP BY` + aggregates | Output is unordered |
| `$project` | `SELECT` | Include/exclude/compute fields |
| `$sort` | `ORDER BY` | Uses index before `$group` |
| `$limit` | `LIMIT` | Must pair with `$sort` for consistent results |
| `$lookup` | `LEFT OUTER JOIN` | Requires index on foreignField |
| `$unwind` | Not applicable | Flattens array; increases cardinality |
| `$facet` | Multiple queries | Single pass, multiple aggregations |

---

### 🏛️ System Design

*(Omit: L2 keyword; aggregation at production scale covered in L4 entries.)*

---

### 📊 Diagram

```text
AGGREGATION PIPELINE FLOW:

  [employees collection: 100,000 docs]
        |
  $match {status:"active"}          -- uses index
        |
  [50,000 active employees]
        |
  $group {_id:"$dept", total:$sum}  -- aggregates
        |
  [20 department results]
        |
  $sort {total: -1}
        |
  $limit 5
        |
  [5 top departments]
        |
  $project {dept:$_id, total:1}
        |
  OUTPUT: 5 documents

  Key: $match EARLY reduces pipeline cardinality
  100,000 -> 50,000 -> 20 -> 5
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: a five-stage aggregation pipeline showing
> document count at each stage, illustrating how early `$match` reduces processing for
> all downstream stages. (2) HOW TO READ IT: each box is a stage; the number in brackets
> is the approximate document count flowing into the next stage; the count reduces at each
> stage. (3) KEY RELATIONSHIP: `$match` as the first stage reduces 100,000 to 50,000;
> every subsequent stage processes half as many documents as it would without the early
> filter; this is the cascading benefit of early filtering. (4) EDGE CASE: if `$group`
> is placed before `$match`, MongoDB cannot use an index on `status` because the document
> stream has already been transformed; the `$match` after `$group` operates on the 20
> group results, not the 100,000 employee documents, but by then the expensive `$group`
> has already processed all 100,000. (5) INSIGHT: a senior engineer observes that the
> total work done by the pipeline is proportional to the cardinality at each stage; any
> stage that reduces cardinality (match, limit, group) should be placed as early as
> logically possible to minimize work for all downstream stages.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Pipeline stages, `$group` accumulators |
| Mechanism | 2 | Index use, `$lookup` internals |
| Application | 2 | Real pipeline design, optimization |
| Trade-off | 1 | Pipeline vs application-side processing |
| Debugging | 1 | Pipeline diagnosis |
| Behavioral | 1 | Pipeline design decision story |

---

**[MID] Q1 (Definition): What are the most important MongoDB aggregation pipeline stages?**

The six most commonly used stages:

`$match`: filters documents using the same query syntax as `find()`. Placed first, it
uses collection indexes to reduce the document count before any other processing.

`$group`: groups documents by a key field and computes aggregate values. The `_id` field
specifies the grouping key (can be null for total aggregate). Accumulators: `$sum` (total),
`$avg` (average), `$max`, `$min`, `$first`, `$last`, `$push` (array of values), `$addToSet`
(unique values array), `$count`.

`$project`: shapes the output document. Include fields with `1`, exclude with `0`,
compute new fields using aggregation expressions (`$multiply`, `$concat`, `$dateToString`).

`$sort`: sorts documents by one or more fields. Placed before `$group`, MongoDB can use
an index. Placed after `$group`, it sorts the aggregated results.

`$lookup`: performs a LEFT OUTER JOIN. For each input document, searches the `from`
collection for documents where `foreignField` matches `localField`. Returns matching
documents as an array in the `as` field.

`$unwind`: deconstructs an array field into individual documents. One document is
created per array element. Used after `$lookup` to flatten the result array.

*What separates good from great:* The `$bucket` and `$bucketAuto` stages for histograms.
`$bucket` groups documents into user-defined ranges (price < 100, 100-500, 500+).
`$bucketAuto` automatically determines bucket boundaries to distribute documents evenly.
These are useful for analytics: "how many products are in each price range?" is a single
`$bucket` stage. Without it, the application must define range logic in code.

---

**[MID] Q2 (Application): Design an aggregation pipeline to compute monthly revenue by product category for the last year.**

```python
from datetime import datetime, timedelta

# Orders have: {_id, created_at, category,
#               total, status}
one_year_ago = datetime.utcnow() - timedelta(days=365)

pipeline = [
    # Stage 1: filter for the time period and
    # only completed orders
    {"$match": {
        "status": "completed",
        "created_at": {"$gte": one_year_ago}
    }},

    # Stage 2: group by year-month and category
    {"$group": {
        "_id": {
            "year": {"$year": "$created_at"},
            "month": {"$month": "$created_at"},
            "category": "$category"
        },
        "revenue": {"$sum": "$total"},
        "order_count": {"$sum": 1},
        "avg_order": {"$avg": "$total"}
    }},

    # Stage 3: sort by period and category
    {"$sort": {
        "_id.year": 1,
        "_id.month": 1,
        "_id.category": 1
    }},

    # Stage 4: project clean output
    {"$project": {
        "_id": 0,
        "year": "$_id.year",
        "month": "$_id.month",
        "category": "$_id.category",
        "revenue": {"$round": ["$revenue", 2]},
        "order_count": 1,
        "avg_order": {"$round": ["$avg_order", 2]}
    }}
]

results = list(
    db.orders.aggregate(pipeline,
                        allowDiskUse=True)
)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a complete revenue analytics pipeline using
> `$year` and `$month` date operators for temporal grouping, combined category grouping,
> and multiple accumulator fields. (2) KEY MECHANISM: `$group` with a compound `_id` (year,
> month, category) creates one group per unique combination; `$year` and `$month` are date
> aggregation operators that extract components from a Date field; `$sum: "$total"` sums
> the total field across all documents in each group. (3) WHY IT MATTERS: this single
> pipeline computes 12 months * N categories of aggregated data in one server-side pass;
> without the pipeline, the application would fetch all completed orders from the last
> year (potentially millions), group and sum in application code, which would transfer
> gigabytes of data. (4) WHAT BREAKS: if `created_at` is not indexed, the `$match` stage
> performs a COLLSCAN on all orders; add a compound index on `{status: 1, created_at: 1}`
> for this pipeline; `allowDiskUse: True` is needed if the group result exceeds 100 MB.
> (5) TAKEAWAY: use date operators (`$year`, `$month`, `$week`, `$dayOfMonth`) in `$group`
> `_id` for temporal aggregations; they are more efficient than client-side date parsing.

*What separates good from great:* The index design for this pipeline. The `$match` filter
on `{status: "completed", created_at: {$gte: one_year_ago}}` benefits from a compound
index `{status: 1, created_at: 1}` (ESR: equality on status, range on created_at). Without
this index, every aggregation execution scans the full orders collection. In a production
analytics system, this pipeline runs hourly or daily; the index pays for itself after the
first few executions.

---

**[SENIOR] Q3 (Mechanism): How does `$lookup` work internally and what are its performance characteristics?**

`$lookup` performs a LEFT OUTER JOIN using a nested loop strategy:
1. For each document flowing through the pipeline (the left side), MongoDB queries the
   `from` collection (the right side) for documents where `foreignField = localField`.
2. The matching documents are added as an array field to the current document.
3. If no documents match, the `as` field is an empty array (LEFT OUTER behavior).

Time complexity: O(N * log M) where N is the number of input documents and M is the
size of the `from` collection (assuming an index on `foreignField`). Without an index,
complexity is O(N * M) - a COLLSCAN per document.

Performance characteristics:
- With index on `foreignField`: each lookup is O(log M); 1,000 input documents and
  1 million in `from` collection = 1,000 * O(log 1,000,000) = 1,000 * 20 = 20,000 ops.
- Without index on `foreignField`: 1,000 * 1,000,000 = 1 billion comparisons.

`$lookup` limitations:
- Cannot `$lookup` across shards for the `from` collection (in older MongoDB versions;
  improved in 5.1+).
- `$lookup` results can be very large arrays if there are many matches; be aware of the
  16 MB document limit.

*What separates good from great:* The "uncorrelated sub-query" `$lookup` syntax. MongoDB
5.0+ supports `$lookup` with a pipeline sub-query (instead of simple field matching).
This allows filtering the joined documents, projecting only needed fields, and sorting
the join result before it becomes the array. For example: join orders to the last 5
order items only (not all items). The pipeline `$lookup` avoids loading unnecessary
data from the `from` collection.

---

**[SENIOR] Q4 (Application): How do you debug a slow aggregation pipeline?**

Step 1 - Add explain():

```python
result = db.collection.aggregate(
    pipeline,
    explain=True
).next()
# or:
result = db.command(
    "aggregate", "collection",
    pipeline=pipeline,
    explain=True
)
```

> **Code walkthrough:** (1) WHAT IT SHOWS: running explain on an aggregation pipeline
> using the explain=True parameter. (2) KEY MECHANISM: explain returns the full execution
> plan including which stages use indexes (IXSCAN vs COLLSCAN) and the estimated document
> count at each stage. (3) WHY IT MATTERS: explain reveals where in the pipeline the
> document count explodes or where a stage is doing a COLLSCAN. (4) WHAT BREAKS: in
> some MongoDB versions, the explain parameter must be passed via `db.command()` instead
> of `collection.aggregate()`; check driver documentation for the correct syntax. (5)
> TAKEAWAY: always run explain on production-bound aggregation pipelines before deployment.

Step 2 - Progressive pipeline testing:
Test each stage individually by running the pipeline with stages removed from the end
and checking document count at each step.

Step 3 - Check common bottlenecks:
- Is `$match` first? Does it use an index (check for IXSCAN in explain)?
- Does `$lookup` have an index on `foreignField`?
- Does `$sort` have an index, or does it create an in-memory sort?
- Are `$unwind` and `$group` operating on many documents?
- Is `allowDiskUse` needed (indicating the pipeline exceeds 100 MB RAM)?

Step 4 - Optimization strategies:
- Move `$match` and `$project` earlier.
- Add missing indexes.
- Use `$addFields` instead of `$project` when keeping all existing fields.
- Batch the aggregation if operating on the full collection.

*What separates good from great:* The pipeline cursor profiling. For pipelines that run
in production, enable MongoDB's query profiler (`db.setProfilingLevel(1, 100)`) and
analyze the `system.profile` entries for aggregation operations. The profiler records
the full aggregation pipeline, execution time, documents examined, and whether
`allowDiskUse` was triggered; this provides the data needed to optimize recurring
slow pipelines without running manual explain() calls.

---

**[SENIOR] Q5 (Trade-off): When should you use aggregation pipeline vs MapReduce vs application-side processing?**

Aggregation Pipeline:
- Best choice for most analytics and data transformation tasks in MongoDB 4.0+.
- Supports indexes; runs server-side; handles billions of documents with proper indexing.
- Limitations: 100 MB per stage (use `allowDiskUse` for larger operations); complex
  multi-pass algorithms are difficult to express.

MapReduce (deprecated in MongoDB 5.0):
- JavaScript-based; more flexible than the pipeline for complex logic.
- Significantly slower than the aggregation pipeline for the same operation.
- Not recommended for new code; use the aggregation pipeline or `$function`/`$accumulator`
  for custom logic.

Application-side processing:
- Appropriate when: the transformation logic is too complex for the pipeline; you need
  programming language features (machine learning, complex business rules); or the data
  is already loaded into the application for other purposes.
- Avoid for: large-scale aggregations (transferring millions of documents to the
  application is slow and expensive); operations that could use indexes (the application
  cannot use MongoDB indexes).

*What separates good from great:* The `$function` and `$accumulator` stages. MongoDB 4.4+
supports JavaScript functions within the aggregation pipeline using `$function` (for
field transformations) and `$accumulator` (for custom accumulator logic in `$group`).
These allow complex business logic (custom scoring, non-standard transformations) while
keeping the computation server-side. Performance is slower than native pipeline operators
(JavaScript evaluation overhead), but much better than application-side processing for
large datasets.

---

**[SENIOR] Q6 (Debugging): An aggregation pipeline is returning incorrect results. How do you diagnose it?**

Systematic diagnosis:

Step 1 - Verify input data: check that the documents you think exist, actually exist
with the exact field names and types you expect; use `find_one()` to examine a sample
document.

Step 2 - Test stages in isolation: progressively build the pipeline one stage at a time
and inspect results after each stage.

```python
# Test only the first stage
debug_pipeline = [pipeline[0]]
sample = list(
    db.collection.aggregate(debug_pipeline).limit(5)
)
print(sample)
# Add stages one at a time and check results
```

> **Code walkthrough:** (1) WHAT IT SHOWS: building the pipeline incrementally to isolate
> the stage producing incorrect results. (2) KEY MECHANISM: each stage is tested
> independently; incorrect output is localized to the stage where it first appears. (3)
> WHY IT MATTERS: complex pipelines with 10+ stages can produce subtle errors from one
> bad stage; isolating the error stage saves hours of debugging. (4) WHAT BREAKS: some
> stages depend on the output of previous stages; testing in complete isolation requires
> constructing test data matching the expected intermediate output. (5) TAKEAWAY: build
> pipelines incrementally during development; test each stage before adding the next.

Common causes of incorrect results:
- `$group` with wrong `_id` (grouping by the wrong field).
- `$unwind` dropping documents with empty arrays (use `preserveNullAndEmptyArrays`).
- `$lookup` joining on the wrong field names.
- `$project` with wrong field name references (case sensitivity).
- Type mismatch in `$match` filter (string "123" vs integer 123 for an ID field).

*What separates good from great:* The `$replaceRoot` and `$mergeObjects` combination
for complex document reshaping. When `$lookup` returns an array and you want to merge
the joined fields into the top-level document (not keep them in the `as` array),
combine `$unwind` + `$replaceRoot` with `$mergeObjects`: `{$replaceRoot: {newRoot:
{$mergeObjects: ["$$ROOT", "$joined_field"]}}}`. This flattens the joined document
fields to the top level, simplifying downstream stages.

---

**[SENIOR] Q7 (Behavioral): Describe a time you used the aggregation pipeline to solve a performance problem.**

Structure this using STAR (Situation, Task, Action, Result):

Situation: an e-commerce reporting API was taking 30+ seconds to generate a daily
summary dashboard showing revenue by category, top products, and return rates. The
API was fetching all orders for the day (50,000-100,000 documents), loading them into
the application, and computing summaries in Python.

Task: reduce the dashboard API response time to under 2 seconds while maintaining
data accuracy.

Action:
1. Profiled the API: 90% of time was spent fetching and transferring 100,000 order
   documents to the application server.
2. Rewrote the data fetch as a `$facet` aggregation pipeline with three sub-pipelines:
   revenue by category (`$group`), top 10 products (`$group + $sort + $limit`), return
   rate (`$match {status: "returned"} + $group`).
3. Added a compound index on `{status: 1, created_at: 1}` to enable the `$match` filter
   to use an index.
4. Added `allowDiskUse=True` as a safety net.

Result: API response time reduced from 30+ seconds to under 500 ms. Data transferred
reduced from 100,000 documents to 1 document with three computed facets.

*What separates good from great:* The ongoing optimization after the initial fix.
After the aggregation pipeline fix, we identified that the same dashboard was refreshed
every 5 minutes by 200+ users. We added a Redis cache in front of the aggregation
with a 5-minute TTL; the database now runs the aggregation once per 5 minutes instead
of once per user request per 5 minutes; further reduced database load by 200x. The
lesson: server-side aggregation is step one; caching is step two for frequently-repeated
identical computations.

---

**[SENIOR] Q8 (Application): How do you handle aggregation across multiple collections with complex joining logic?**

For complex multi-collection joins in MongoDB, use a combination of `$lookup` with
pipeline, `$unwind`, and `$replaceRoot`:

```python
# Orders -> join products -> join customers
# -> compute enriched order with full details
pipeline = [
    # Filter recent orders
    {"$match": {"status": "pending",
                "created_at": {"$gte": cutoff}}},

    # Join customer details
    {"$lookup": {
        "from": "customers",
        "let": {"cid": "$customer_id"},
        "pipeline": [
            {"$match": {"$expr": {
                "$eq": ["$_id", "$$cid"]
            }}},
            {"$project": {
                "name": 1, "tier": 1,
                "email": 1, "_id": 0
            }}  # Only fetch needed fields
        ],
        "as": "customer"
    }},
    {"$unwind": "$customer"},

    # Compute priority score
    {"$addFields": {
        "priority_score": {
            "$multiply": [
                "$total",
                {"$cond": {
                    "if": {"$eq": [
                        "$customer.tier", "gold"
                    ]},
                    "then": 2,
                    "else": 1
                }}
            ]
        }
    }},
    {"$sort": {"priority_score": -1}}
]
```

> **Code walkthrough:** (1) WHAT IT SHOWS: a pipeline `$lookup` (using `let` and
> `pipeline` syntax) that projects only needed customer fields in the join, followed by
> a computed field using `$cond` for conditional scoring. (2) KEY MECHANISM: the
> pipeline `$lookup` (MongoDB 3.6+) allows filtering and projecting the joined documents
> before they become the `as` array; projecting only `name`, `tier`, and `email` from
> customers avoids loading the full customer document for each order; `$$cid` references
> the local field variable from `let`. (3) WHY IT MATTERS: for large customer documents
> with many fields, projecting in the `$lookup` pipeline reduces the size of the `as`
> array by 90%+ compared to loading the full document; this reduces both memory use and
> serialization overhead. (4) WHAT BREAKS: `$expr` within `$match` inside a `$lookup`
> pipeline does not use a standard index in all MongoDB versions; verify with explain()
> that the join is using the customers `_id` index. (5) TAKEAWAY: use pipeline `$lookup`
> with projection to minimize data loaded from the joined collection; never `$lookup`
> the full document when only a few fields are needed.

*What separates good from great:* The write-time denormalization vs read-time `$lookup`
trade-off for this pattern. If this pipeline runs millions of times per day, the
repeated `$lookup` cost adds up; consider whether denormalizing customer tier into the
order document at write time (snapshot pattern) eliminates the `$lookup` entirely.
The break-even point depends on: how often orders are queried (read frequency) vs how
often customer tier changes (write frequency). If customer tier changes rarely (monthly)
and orders are queried millions of times, denormalization is the better long-term
architecture.

---

**[SENIOR] Q9 (Mechanism): What is the `$merge` stage and how does it differ from `$out`?**

Both `$merge` and `$out` write aggregation results to a collection (useful for
materialized views or pre-computed analytics).

`$out` (MongoDB 2.6+): replaces the entire output collection with the pipeline result.
If the collection exists, it is completely replaced. If the pipeline produces an error,
the target collection is not modified (atomic swap using a temp collection).

`$merge` (MongoDB 4.2+): merges the pipeline result into an existing collection using
configurable behavior:
- `whenMatched`: what to do when a document with the same `_id` already exists:
  `replace` (replace the entire document), `merge` (merge fields), `keepExisting`
  (ignore), `fail` (raise error), or a pipeline (custom merge logic).
- `whenNotMatched`: what to do when no existing document matches:
  `insert` (insert new document), `discard` (ignore), `fail` (raise error).

Use `$out` for: scheduled batch jobs that completely rebuild a summary collection.
Use `$merge` for: incremental updates where new aggregation results are merged into
existing summary data (e.g., hourly revenue summaries merged into a monthly total).

*What separates good from great:* The materialized view pattern using `$merge`. By
scheduling an aggregation with `$merge` to run every hour, you create a materialized
view of pre-computed summary data. Dashboard queries read from the summary collection
(fast, small) instead of the raw orders collection (slow, large). The `$merge` with
`whenMatched: "merge"` incrementally updates existing summaries without full rebuilds.
This is the correct architecture for analytics dashboards that must be fast and always
current but do not require real-time data.

---

---

# MongoDB Replication and Replica Sets

---

### 🎯 Model Answer

**30 seconds:**
> A MongoDB Replica Set is a group of MongoDB instances (typically 3) that maintain the
> same data. One is the primary (accepts all writes); the others are secondaries
> (replicate from the primary's oplog). If the primary fails, secondaries elect a new
> primary automatically (typically in 10-30 seconds). Applications use a connection string
> pointing to all replica set members; the driver handles failover transparently.

**3 minutes (Senior):**
> Replica sets provide high availability and data durability. The primary receives all
> writes; writes are logged to the oplog (capped collection); secondaries tail the oplog
> and replay operations asynchronously. An arbiter (no data, no election votes except
> in ties) can be added to make a 2-node replica set have a tiebreaking voter for
> elections. Elections are triggered by primary unavailability (heartbeat timeout) and
> completed in a Raft-like consensus vote; the secondary with the most up-to-date oplog
> and highest priority wins. Read preferences control whether reads go to the primary
> (default, consistent) or secondaries (reduced primary load but potentially stale reads).
> Write concern (`w: majority`) ensures a write is on a majority of nodes before
> returning. Oplog size determines how long secondaries can lag before they fall behind
> and require a full resync.

**Framework:** Primary (writes) -> Oplog -> Secondary (async replay) -> Heartbeat/Election -> Failover

**Blank Mind Recovery:**

**(1) Restate:** "Replica set: 3 nodes (1 primary + 2 secondaries). Primary writes to
oplog; secondaries replay. Primary fails -> election -> new primary in 10-30 seconds.
Write concern `w:majority` ensures durability."

**(2) First principles:** "Replication is copying data to multiple machines so that no
single machine failure loses data. The oplog is a log of all changes; secondaries replay
the log to stay synchronized."

**(3) Bridge:** "A replica set is like having three copies of a notebook. One person
(primary) actively writes in their notebook; they call out each change. The other two
people (secondaries) copy each change into their own notebooks. If the active writer
is unavailable, one of the copiers takes over as the new active writer."

---

### 📘 Concept Explanation

**Replica Set Architecture:**

```text
REPLICA SET TOPOLOGY:

  CLIENT (App)
     |
     | (writes to primary)
     v
  [PRIMARY]  <-- all writes, oplog
     |  |
     |  | (async replication)
     v  v
  [SEC-1]  [SEC-2]  <-- replay oplog

  Election (primary fails):
    SEC-1, SEC-2 detect timeout (~10s)
    SEC-1 votes for itself, requests votes
    SEC-2 votes for SEC-1 if its oplog is
    up-to-date or SEC-1 has higher priority
    SEC-1 becomes new primary (~10-30s total)

  ARBITER (optional, no data):
    Used for 2-node set to prevent ties
    Participates in election votes only
```

> **Code walkthrough:** (1) WHAT IT SHOWS: the replica set topology with primary, two
> secondaries, and an optional arbiter, with the election flow on primary failure. (2)
> KEY MECHANISM: heartbeats are sent every 2 seconds between members; if a primary does
> not respond to heartbeats for 10 seconds (the default `electionTimeoutMillis`), the
> remaining secondaries start an election; the election uses a Raft-inspired protocol
> where candidates need votes from a majority of voting members to win. (3) WHY IT
> MATTERS: the 10-30 second election time means applications experience a brief write
> unavailability period during failover; connection pools will return errors during this
> window; applications must handle transient write failures with retries. (4) WHAT BREAKS:
> a 2-node replica set (primary + 1 secondary, no arbiter) cannot elect a new primary if
> the primary fails because neither remaining node can get a majority of votes (2 out of
> 2 required); always use an odd number of voting members (3, 5, 7). (5) TAKEAWAY: always
> use a minimum of 3 voting members in a replica set; this provides majority-based election
> (2 out of 3 votes) and tolerates one node failure without write unavailability.

---

### 💻 Code Example

```python
from pymongo import MongoClient, ReadPreference

# Connection string lists all replica set members
# The driver handles routing and failover automatically
client = MongoClient(
    "mongodb://host1:27017,host2:27017,host3:27017"
    "/?replicaSet=myReplicaSet"
    "&readPreference=primaryPreferred"
    "&w=majority"
    "&retryWrites=true"
)

db = client.myapp
users = db.users

# Write: always goes to the primary
# w=majority: wait for majority acknowledgment
users.insert_one(
    {"name": "Alice"},
    # Override per-operation write concern
    # if needed:
    # write_concern=WriteConcern(w="majority", j=True)
)

# Read from secondaries to reduce primary load
# readPreference=secondary:
# read from any secondary; may be slightly stale
secondary_client = MongoClient(
    "mongodb://host1,host2,host3"
    "/?replicaSet=myReplicaSet",
    read_preference=ReadPreference.SECONDARY
)
# Use for analytics, reports, non-critical reads

# Read from primary (default, always consistent)
primary_read = users.find_one(
    {"name": "Alice"}
)  # Uses primary by default
```

> **Code walkthrough:** (1) WHAT IT SHOWS: connecting to a replica set with all members
> listed in the connection string, configuring read preference and write concern at the
> connection level, and creating a secondary-preferring client for analytics reads. (2)
> KEY MECHANISM: the MongoDB driver automatically monitors all replica set members via
> the Server Discovery and Monitoring (SDAM) protocol; when a failover occurs, the driver
> detects the new primary within seconds and routes subsequent writes to it; `retryWrites:
> true` automatically retries idempotent write operations that fail due to transient
> network errors or primary elections. (3) WHY IT MATTERS: always list all replica set
> members in the connection string; if only one member is listed and that member is the
> current primary which fails, the driver cannot discover the new primary; listing all
> members allows the driver to discover the new primary even if the listed primary fails.
> (4) WHAT BREAKS: `read_preference=SECONDARY` can return stale data; if a secondary is
> lagging (replication lag), reads from it may return data that has been updated on the
> primary but not yet replicated; for user-facing reads where staleness is unacceptable,
> use `PRIMARY` or `PRIMARY_PREFERRED`. (5) TAKEAWAY: set `retryWrites=true` in all
> production connection strings; this handles the brief write failure window during
> elections transparently without application-layer retry logic.

```python
# Monitor replica set status
import pprint

# rs.status() equivalent in Python
status = client.admin.command("replSetGetStatus")

# Key fields to monitor:
# - members[].health (1 = healthy, 0 = down)
# - members[].state (1=PRIMARY, 2=SECONDARY, 7=ARBITER)
# - members[].optimeDate (last oplog entry applied)
# - members[].lagSeconds (replication lag)

for member in status["members"]:
    print(f"Host: {member['name']}")
    print(f"State: {member['stateStr']}")
    if member["stateStr"] == "SECONDARY":
        lag = (
            status["members"][0]["optimeDate"]
            - member["optimeDate"]
        ).total_seconds()
        print(f"Lag: {lag:.1f}s")
```

> **Code walkthrough:** (1) WHAT IT SHOWS: monitoring replica set status programmatically
> including member state and replication lag calculation. (2) KEY MECHANISM: `replSetGetStatus`
> returns the current state of all replica set members including their last applied oplog
> entry timestamp; replication lag is the difference between the primary's last oplog
> timestamp and the secondary's last applied oplog timestamp. (3) WHY IT MATTERS:
> replication lag determines how stale secondary reads are; a secondary lagging by 60
> seconds means reads from that secondary may return data up to 60 seconds old; alert
> when lag exceeds the application's staleness tolerance. (4) WHAT BREAKS: if replication
> lag grows unchecked, the secondary may fall off the primary's oplog window (if the
> oplog is written faster than the secondary can replay it and the oplog wraps around);
> the secondary must then perform a full initial sync. (5) TAKEAWAY: monitor replication
> lag continuously; alert at 10 seconds for production systems; a growing lag indicates
> a slow secondary (network, disk I/O, or CPU bottleneck).

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> A MongoDB Replica Set has one primary (receives all writes) and one or more secondaries
> (replicate from the primary). If the primary fails, a secondary is automatically elected
> as the new primary in 10-30 seconds. Use at least 3 members. Applications connect with
> a connection string listing all members; the driver handles failover automatically. Write
> concern `w: majority` ensures the write is on a majority of nodes before acknowledging.

---

**Senior / Staff (5+ years):**
> Replica set design decisions that matter in production: (1) Write concern - `w: majority`
> prevents data loss on primary failure but adds latency; understand the trade-off and
> use majority for critical data; (2) Oplog sizing - size the oplog to handle at least
> 24 hours of write volume; a small oplog with high write volume causes secondaries to
> fall off the oplog and require full resync; (3) Priority settings - set priority=0 on
> secondaries in the secondary datacenter to prevent them from becoming primary during
> normal operation; (4) Read preferences - use secondary reads for analytics to reduce
> primary load, but understand the staleness implications; (5) Hidden members - add
> hidden=true, priority=0 members for full-collection backups that do not serve traffic.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Reading from secondaries is always safe for load distribution."**

Reading from secondaries introduces staleness. The replication is asynchronous; a
secondary can lag seconds to minutes behind the primary. For data that must be current
(user balance, inventory, session state), reading from a secondary can return stale data
that leads to incorrect application behavior. Use secondary reads only for workloads
where staleness is acceptable (analytics, reporting, batch processing).

**Misconception 2: "w: majority guarantees zero data loss."**

`w: majority` guarantees the write is on a majority of voting members before returning.
If the primary and one secondary simultaneously fail (minority of nodes), the remaining
majority has the data. However, if a catastrophic event (datacenter failure) affects
the majority of nodes simultaneously, data can still be lost. `w: majority` protects
against single-node failures, not datacenter-level events. Geo-distributed replica sets
(members in different datacenters) provide protection against datacenter failures.

---

### 🚨 Failure Modes and Diagnosis

**Failure Mode 1: Replica set stuck without a primary (no primary elected).**

Symptom: writes fail with "not master" or "no primary available"; `rs.status()` shows
all members as SECONDARY.
Root cause: a majority of voting members are unavailable; the remaining members cannot
elect a primary (they do not have a majority of votes).
Diagnosis: `rs.status()` to check which members are unreachable; check network
connectivity between nodes; verify the member count and voting configuration.
Fix: restore enough nodes to form a majority; if in an emergency, use `rs.reconfig()`
to reduce the required quorum (understand the data loss risk).

**Failure Mode 2: Replication lag growing on secondary.**

Symptom: secondary falls progressively further behind the primary; eventually falls off
the oplog window and requires full initial sync; secondary `stateStr` shows "RECOVERING".
Root cause: the secondary cannot apply oplog entries as fast as the primary generates
them; caused by: slow disk on secondary, high primary write rate, or long-running
operations blocking replication.
Diagnosis: check secondary disk I/O, CPU; check `replSetGetStatus` for `optimeDate`
diff; check `db.adminCommand({currentOp: true, localOps: true})` for blocking operations.
Fix: increase disk throughput on secondary; add more secondaries to distribute read load;
increase oplog size with `replSetResizeOplog`.

---

### ⚖️ Comparison Table

| Configuration | Fault Tolerance | Write Latency | Read Scalability |
|---|---|---|---|
| **Standalone (no RS)** | None | Lowest | None |
| **2-node RS** | 0 failures (no majority) | Low | Limited |
| **3-node RS** | 1 failure | Low | 2 secondaries |
| **5-node RS** | 2 failures | Slightly higher | 4 secondaries |
| **PSA (Primary+Secondary+Arbiter)** | 1 data failure | Low | 1 secondary |

---

### 🏛️ System Design

**Production Replica Set Design for Multi-Region Availability:**

Requirements: survive regional failure; minimize cross-region write latency; enable
local reads in each region.

```text
  MULTI-REGION REPLICA SET:

  US-EAST (primary region):
    Primary    (priority: 2)  <-- writes here
    Secondary  (priority: 1)  <-- US-EAST reads

  US-WEST (secondary region):
    Secondary  (priority: 0)  <-- never primary
    Secondary  (priority: 0)  <-- US-WEST reads
    (hidden=false, readable via secondary
     read preference)

  EUROPE (disaster recovery):
    Secondary  (priority: 0, hidden=true)
    (full backup; not in normal read pool)

  Write concern: w:2 (primary + US-EAST secondary)
  = writes acknowledged locally in US-EAST
  = US-WEST has eventual consistency
  = Europe is a lagging backup
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: a 5-member replica set distributed across
> three regions for high availability with controlled failover behavior. (2) HOW TO READ
> IT: priority values control election outcomes; the US-EAST primary (priority 2) always
> wins elections over the US-EAST secondary (priority 1) which wins over US-WEST
> secondaries (priority 0); priority 0 members never become primary. (3) KEY RELATIONSHIP:
> write concern `w: 2` acknowledges when the primary and the US-EAST secondary have the
> write; this keeps write latency at intra-datacenter speed (< 1 ms) while ensuring one
> replica before acknowledgment. (4) EDGE CASE: if US-EAST fails entirely (both primary
> and secondary gone), US-WEST secondaries (priority 0) cannot form a majority alone
> (2 of 5 nodes); the Europe hidden secondary must be reconfigured to allow an election;
> this requires manual intervention. (5) INSIGHT: a senior engineer notes that the
> priority and hidden settings are the knobs for controlling election behavior; hidden
> members provide backup without affecting the application's read replica pool.

---

### 📊 Diagram

```text
REPLICA SET REPLICATION AND ELECTION:

  NORMAL OPERATION:
    [PRIMARY]
      |-- oplog write
      |
      +-> [SEC-1] (async replay)
      +-> [SEC-2] (async replay)
    heartbeat every 2s

  PRIMARY FAILURE:
    t=0s:  PRIMARY stops responding
    t=10s: SEC-1 and SEC-2 detect timeout
    t=10s: SEC-1 starts election,
           requests vote from SEC-2
    t=12s: SEC-2 votes for SEC-1
           (SEC-1 has majority: 2 of 3)
    t=12s: SEC-1 becomes new PRIMARY
    t=30s: app driver detects new primary,
           retryWrites reconnects

  KEY: 3+ voting members = election succeeds
  2 members (no arbiter) = no majority possible
```

> **Diagram walkthrough:** (1) WHAT IT DEPICTS: normal replica set replication flow and
> the step-by-step election process when the primary fails. (2) HOW TO READ IT: the top
> block shows normal operation with oplog writes flowing from primary to secondaries via
> async replication and heartbeats; the bottom block shows the timeline from primary
> failure to election completion. (3) KEY RELATIONSHIP: the 10-second heartbeat timeout
> initiates the election; the election requires a majority of voting members; with 3
> nodes, 2 votes form a majority; the entire process takes 10-30 seconds. (4) EDGE CASE:
> with only 2 data nodes and no arbiter, if the primary fails, the single remaining
> secondary cannot achieve a majority of votes (1 of 2 is not a majority); the replica
> set has no writable primary until the failed node recovers or the configuration is
> manually changed. (5) INSIGHT: a senior engineer notes that `retryWrites=true` in the
> connection string is the application-layer complement to the automatic election; without
> it, writes that fail during the election window are lost; with it, they are automatically
> retried after the new primary is elected.

---

### 🎯 Interview Deep-Dive

| Category | Count | Coverage |
|---|---|---|
| Definition | 2 | Replica set, oplog |
| Mechanism | 2 | Election, replication lag |
| Application | 2 | Connection configuration, read preferences |
| Scenario | 2 | Failover, lag diagnosis |
| Trade-off | 1 | Write concern vs latency |
| Behavioral | 1 | Production incident |

---

**[MID] Q1 (Definition): What is a MongoDB Replica Set and how does it provide high availability?**

A Replica Set is a group of MongoDB instances (nodes) that maintain the same dataset.
It provides high availability through automatic failover.

Components:
- Primary: the single node that accepts all writes. Writes are recorded in the oplog.
- Secondary: one or more nodes that replicate from the primary's oplog asynchronously.
  Can optionally serve reads (secondary read preference).
- Arbiter (optional): participates in elections but holds no data. Used to provide a
  majority voter when an even number of data nodes is needed.

High availability mechanism:
1. Each member sends heartbeats to all others every 2 seconds.
2. If a secondary does not receive a heartbeat from the primary for `electionTimeoutMillis`
   (default: 10 seconds), it starts an election.
3. The candidate with the most up-to-date oplog and highest priority gets votes.
4. When a majority of voting members vote for a candidate, it becomes the new primary.
5. The entire election typically completes in 10-30 seconds.

During the election window, writes are unavailable. `retryWrites: true` in the
connection string causes the driver to automatically retry safe-to-retry write
operations after the new primary is elected.

*What separates good from great:* The minimum 3-node recommendation. With 2 nodes (no
arbiter), losing the primary leaves only 1 of 2 nodes; 1 node is not a majority of 2,
so no election can succeed. With 3 nodes, losing the primary leaves 2 of 3 nodes; 2
is a majority of 3, so an election succeeds. Always use an odd number of voting
members (3, 5, 7) or add an arbiter to even-numbered data-node sets.

---

**[MID] Q2 (Application): How do you configure read preferences in MongoDB and when do you use each?**

Read preference specifies which replica set members the driver routes reads to:

`PRIMARY` (default): all reads go to the primary. Guarantees the most current data.
Use for: any read that must see the latest writes (user balance, session state, shopping
cart, inventory check before purchase).

`PRIMARY_PREFERRED`: read from primary if available; fallback to secondary if primary
is unavailable. Use for: non-critical reads that benefit from primary freshness but can
tolerate a secondary during primary maintenance.

`SECONDARY`: read from any available secondary. May return stale data.
Use for: analytics, reporting, monitoring dashboards, batch processing. Never use for
user-facing reads that require up-to-date data.

`SECONDARY_PREFERRED`: read from secondary if available; fallback to primary. Same
staleness concern as SECONDARY.

`NEAREST`: read from the member with the lowest network latency (primary or secondary).
Use for: globally distributed applications where latency is more important than
consistency.

Tag sets: MongoDB supports tagging replica set members and routing reads to members with
specific tags. Example: tag two secondaries as "analytics" and route reporting queries
to them, leaving the primary and the remaining secondary for application traffic.

*What separates good from great:* The Causal Consistency option. MongoDB 3.6+ supports
causal consistency sessions: writes in a session are visible to reads in the same session
even when reading from a secondary. This is implemented using operation timestamps:
the read includes the timestamp of the last write in the session, and MongoDB ensures
the secondary has applied operations up to that timestamp before serving the read. This
allows secondary reads with "read your own writes" consistency.

---

**[SENIOR] Q3 (Mechanism): How does MongoDB's oplog work and why does its size matter?**

The oplog (operations log) is a capped collection in the `local` database on each
replica set member (`local.oplog.rs`). It records every write operation applied to
the primary as an "idempotent operation" (an operation that can be re-applied multiple
times safely).

Why idempotent: the original write may be a range update (`updateMany`); the oplog
records it as individual document updates (one oplog entry per document). This ensures
that replaying the oplog multiple times does not corrupt data.

Replication mechanism: secondaries maintain a pointer to the last oplog entry they
have applied. They continuously tail the oplog cursor, reading new entries and applying
them to their local data. If a secondary falls behind, it continues from its last
applied position.

Oplog size importance: the oplog is a capped collection with a maximum size. When the
oplog is full, the oldest entries are overwritten. If a secondary is offline for longer
than it takes for the primary to fill the oplog, the secondary's last applied position
is now overwritten; the secondary cannot recover via oplog replay and must perform a
full initial sync (copying all data from scratch).

Oplog window calculation: oplog_window_hours = oplog_size_GB / (write_rate_GB_per_hour).
If write rate is 2 GB/hour and oplog is 10 GB, the window is 5 hours. Any secondary
offline for more than 5 hours requires a full resync.

*What separates good from great:* The `replSetResizeOplog` command (MongoDB 4.4+)
allows resizing the oplog without restarting the MongoDB server. Before 4.4, changing
oplog size required removing the member from the replica set, wiping the data directory,
and re-syncing. This operational improvement makes it practical to increase oplog size
in response to observed secondary lag.

---

**[SENIOR] Q4 (Scenario): Your MongoDB primary fails at 2 AM. Walk through what happens and what you do.**

Automated recovery (happens without intervention):

Seconds 0-10: primary stops responding to heartbeats from secondaries.

Second 10: election timeout expires; secondaries start an election.

Seconds 10-30: election completes; the secondary with the highest priority and most
up-to-date oplog wins; it becomes the new primary.

Second 30: the driver detects the new primary (SDAM monitoring); all subsequent writes
are routed to the new primary. Applications using `retryWrites: true` automatically
retry any writes that failed during the election window.

Manual investigation (what you do):

1. Check `rs.status()` to confirm the new primary is operating normally.
2. Check replication lag on remaining secondaries: all should be near 0 after failover.
3. Investigate the failed primary: check system logs for OOM kills, disk failures,
   network partition, kernel panics.
4. Once root cause is identified and fixed, add the former primary back as a secondary:
   it automatically syncs from the current primary's oplog and re-joins the replica set.
5. If needed, step down the current primary to restore the original topology (use
   `rs.stepDown()` during a low-traffic window).

*What separates good from great:* The write rollback scenario. If `w: 1` writes were
acknowledged to the primary just before it failed, and those writes had not yet
replicated to a secondary, those writes are "rolled back" when the former primary
re-joins the replica set as a secondary (because it has writes the new primary does
not). MongoDB writes rolled-back writes to a `rollback/` directory as BSON files.
These can be replayed if the writes are critical. This is why `w: majority` is
important for critical data: it prevents write rollback by ensuring the write is on
a majority before acknowledging.

---

**[SENIOR] Q5 (Trade-off): Compare `w: 1` vs `w: majority` write concern in terms of durability, latency, and when to use each.**

`w: 1` (acknowledge from primary only):
- Durability: write is on the primary; if the primary fails before the write replicates,
  the write is lost (rolled back when the former primary re-joins as secondary).
- Latency: minimal; the primary writes to its journal and acknowledges.
- Use for: high-throughput writes where some loss is acceptable (analytics events,
  metrics, log entries); writes that are easily re-generated from other sources.

`w: majority` (acknowledge from majority of voting members):
- Durability: write is on a majority of nodes; survives a single node failure without
  data loss; the write is "committed" in the consensus sense.
- Latency: slightly higher; the primary must wait for at least one secondary to
  acknowledge (in a 3-node set, one secondary must confirm); adds the secondary
  acknowledgment round-trip (~1-5 ms for same-DC secondaries).
- Use for: any write that must not be lost (user registrations, financial transactions,
  order placements, permission changes).

The latency difference: in a same-datacenter 3-node replica set, the primary-to-secondary
replication round-trip is typically 1-5 ms. The total `w: majority` latency is primary
write time + 1-5 ms. For most applications, this is negligible. In cross-datacenter
configurations, the secondary may be 50-200 ms away; `w: majority` with a cross-DC
secondary adds 50-200 ms to every write.

*What separates good from great:* The hybrid write concern strategy. Use `w: majority`
for critical writes (orders, payments) and `w: 1` for non-critical writes (events,
logs, metrics) in the same application. This provides durability where it matters
without paying the latency cost for all writes. Implement this as a service-level
policy: the payment service uses `w: majority`; the analytics service uses `w: 1`.

---

**[SENIOR] Q6 (Scenario): Replication lag on a secondary is growing. How do you diagnose and fix it?**

Diagnosis:

Step 1 - Quantify the lag:

```python
status = client.admin.command("replSetGetStatus")
for member in status["members"]:
    if member["stateStr"] == "SECONDARY":
        lag = (
            status["members"][0]["optimeDate"]
            - member["optimeDate"]
        ).total_seconds()
        print(f"{member['name']}: {lag:.0f}s lag")
```

> **Code walkthrough:** (1) WHAT IT SHOWS: measuring replication lag by comparing the
> primary's oplog timestamp to each secondary's last applied oplog timestamp. (2) KEY
> MECHANISM: optimeDate is the timestamp of the last oplog entry applied by each member;
> the difference between primary and secondary timestamps is the lag. (3) WHY IT MATTERS:
> growing lag indicates the secondary cannot keep up with the write rate; left unchecked,
> the secondary falls off the oplog window. (4) WHAT BREAKS: if lag exceeds the oplog
> window, the secondary enters RECOVERING state and requires full initial sync. (5)
> TAKEAWAY: alert when lag exceeds 30 seconds for production systems; investigate
> immediately at 60 seconds.

Step 2 - Identify the bottleneck:
- Check secondary disk I/O: `iostat -x 5` - if disk utilization is near 100%,
  the secondary disk is too slow for the write rate.
- Check secondary CPU: if high, the secondary is CPU-bound on replication replay.
- Check for long-running operations blocking replication: `db.currentOp()` on the
  secondary; blocking reads with `$readPreference: secondary` can block replication.

Step 3 - Fix options:
- Slow secondary disk: upgrade to faster storage (NVMe vs SATA SSD).
- High CPU on secondary: reduce read load on the secondary (route read queries
  elsewhere); reduce the number of indexes (more indexes = more index maintenance
  on replication).
- Blocking operations: use read timeout configuration to kill long-running secondary
  reads that block replication.
- Increase oplog size immediately: `db.adminCommand({replSetResizeOplog: 1, size: 51200})`
  (50 GB) to buy time while fixing the root cause.

*What separates good from great:* The proactive monitoring approach. Set alerts before
lag becomes a problem: alert at 30s lag (investigate), alert at 120s lag (escalate),
alert at 80% of oplog window consumed (emergency). Track the oplog window size:
`rs.printReplicationInfo()` shows the oplog's oldest and newest timestamps; the window
shrinks as write volume increases. Resize the oplog proactively when the window drops
below 48 hours.

---

**[SENIOR] Q7 (Behavioral): How have you used replica set read preferences to scale read traffic?**

Structure: STAR method.

Situation: a social media analytics dashboard was causing read spikes on the MongoDB
primary, causing write latency increases during peak hours. The dashboard was queried
by internal analysts 200+ times per day, each query taking 2-5 seconds on a collection
with 50 million documents.

Task: reduce primary load from analytics queries without affecting write performance
or user-facing reads.

Action:
1. Identified that analytics queries were reading from the primary despite the
   `SECONDARY_PREFERRED` configuration; investigation revealed the queries were
   run with a separate client that used the default `PRIMARY` read preference.
2. Created a dedicated analytics MongoDB client with `ReadPreference.SECONDARY` and
   a tag set (`{"role": "analytics"}`) pointing to two dedicated secondary members.
3. Tagged the two analytics secondaries: `rs.conf()` + member `tags: {role: "analytics"}`.
4. Optionally hid one secondary (`hidden: true`) as a pure backup; kept the other
   as the analytics replica.
5. Monitored replication lag on the analytics secondaries; confirmed they could handle
   the analytics read load without falling behind.

Result: primary CPU reduced by 40% during peak hours; write latency normalized; analytics
queries ran against secondaries with acceptable 5-30 second staleness (analysts accepted
near-real-time data rather than real-time).

*What separates good from great:* The isolation concern. Read traffic on a secondary
competes with replication replay for disk I/O and CPU. Heavy analytics reads on a
secondary can increase replication lag on that secondary. Isolate analytics by using
a dedicated secondary tagged for analytics; monitor its lag separately; if lag grows,
reduce analytics query frequency or scale out by adding another tagged secondary.

---

**[SENIOR] Q8 (Mechanism): What is the difference between a replica set and MongoDB Atlas Global Clusters?**

Replica Set: a group of MongoDB instances maintaining the same data with automatic
failover within one logical dataset. All writes go to one primary; data is geographically
concentrated even in multi-region replica sets. Read scaling via secondary reads. The
primary is a single point of write bottleneck.

MongoDB Sharding (Cluster): horizontal partitioning of data across multiple replica
sets (shards). Each shard is a replica set. Data is distributed by a shard key; a
`mongos` router directs queries to the correct shard(s). Write scaling is achieved
by distributing writes across multiple shards; each shard handles writes for a subset
of the data.

MongoDB Atlas Global Clusters: a MongoDB Atlas-managed configuration combining sharding
and geographic distribution. Data is zoned by geography (shard key includes a geographic
zone field); writes are routed to the nearest zone (low latency); reads are served
from the local zone replica set. Provides: global write distribution (not just global
read), geographic data locality for compliance, and automatic zone failover.

Key differences:
- Replica Set: single geographic write point; read scaling; data durability.
- Sharded Cluster: write scaling; horizontal data distribution.
- Atlas Global Cluster: write scaling + geographic distribution + compliance zoning.

*What separates good from great:* The decision framework. A replica set is the correct
choice for most production MongoDB applications; it provides durability and read scaling
without operational complexity. Move to sharding when: a single replica set's write
throughput is saturated (typically > 100,000 writes/second for a well-tuned primary);
or when dataset size exceeds a single server's storage capacity. Move to Atlas Global
Clusters when: regulatory requirements mandate data residency; write latency from a
geographically distant primary is unacceptable; the application serves a global user
base with approximately equal write traffic in each region.

---

**[SENIOR] Q9 (Application): How do you set up and safely step down a primary in a replica set?**

Step down is needed for: primary node maintenance (disk replacement, OS patching),
restoring original topology after automatic failover, or moving the primary to a
higher-priority server.

Safe step-down procedure:

Step 1 - Check current state:

```python
status = client.admin.command("replSetGetStatus")
primary = next(m for m in status["members"]
               if m["stateStr"] == "PRIMARY")
print(f"Current primary: {primary['name']}")
# Verify secondaries have low lag before stepping down
```

> **Code walkthrough:** (1) WHAT IT SHOWS: finding the current primary and verifying
> replica set health before initiating a step-down. (2) KEY MECHANISM: stepping down
> while secondaries have high lag means the new primary starts with a less up-to-date
> oplog; any `w: 1` writes between lag and step-down could be at risk. (3) WHY IT
> MATTERS: verify all secondaries have < 5 seconds lag before stepping down to minimize
> write unavailability. (4) WHAT BREAKS: stepping down with a lagging secondary forces
> an election where the new primary may be less up-to-date than expected. (5) TAKEAWAY:
> always check secondaries' replication lag before a planned step-down.

Step 2 - Step down the primary:

```python
# stepDown(60): primary steps down for at least 60 seconds
# Allows time for secondary to catch up and be elected
client.admin.command(
    "replSetStepDown", 60,
    secondaryCatchUpPeriodSecs=10
)
# This raises a NotPrimaryError - expected
```

> **Code walkthrough:** (1) WHAT IT SHOWS: using `replSetStepDown` to trigger a planned
> failover. (2) KEY MECHANISM: `replSetStepDown` tells the primary to step down and not
> attempt to become primary again for 60 seconds; it waits up to `secondaryCatchUpPeriodSecs`
> seconds for a secondary to catch up before stepping down; an election starts immediately
> after. (3) WHY IT MATTERS: the step-down is graceful: the primary waits for a secondary
> to be current before stepping down, minimizing the write unavailability window. (4) WHAT
> BREAKS: the command raises `NotPrimaryError` (because the connection's primary just stepped
> down); this is expected; catch this specific error in the calling code. (5) TAKEAWAY:
> use `replSetStepDown` for all planned primary changes; never kill the primary process
> directly for planned maintenance (this triggers an uncontrolled election).

*What separates good from great:* The maintenance window coordination. Before stepping
down: (1) verify application connections use retry logic; (2) reduce traffic by moving
to a maintenance window; (3) confirm secondary lag < 5 seconds; (4) step down; (5) monitor
the election and confirm the intended secondary becomes primary (check priority values
in `rs.conf()`); (6) perform maintenance on the former primary; (7) add it back as a
secondary and verify it catches up via oplog.
