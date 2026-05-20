---
layout: default
title: "AI - RAG"
parent: "AI Foundations, LLMs, RAG and Agents"
grand_parent: "Interview Mastery"
nav_order: 3
permalink: /interview/ai-and-rag/rag/
topic: AI Foundations, LLMs, RAG and Agents
subtopic: RAG
keywords:
  - RAG Architecture
  - Vector Databases
  - Chunking Strategies
  - Retrieval Methods
  - Reranking
  - RAG Evaluation
difficulty_range: hard
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [RAG Architecture](#rag-architecture)
- [Vector Databases](#vector-databases)
- [Chunking Strategies](#chunking-strategies)
- [Retrieval Methods](#retrieval-methods)
- [Reranking](#reranking)
- [RAG Evaluation](#rag-evaluation)

# RAG Architecture

**TL;DR** - Retrieval-Augmented Generation (RAG) grounds LLM responses in your actual data by retrieving relevant documents before generation - reducing hallucination, enabling knowledge updates without retraining, and providing source attribution for trustworthy AI applications.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
LLMs have training data cutoff dates and no access to your private data. They hallucinate confidently. Fine-tuning is expensive and can't keep up with data changes. You need models to answer from YOUR current documents accurately.
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

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
RAG pipeline:
  Indexing (offline, one-time):
    Documents -> Chunk -> Embed -> Store in Vector DB

  Query (online, per-request):
    User query -> Embed query -> Search vector DB
      -> Retrieve top-K chunks -> Rerank
        -> Construct prompt (query + context)
          -> LLM generates answer with citations
            -> Return answer + sources

RAG architecture components:
  +-------------------------------------------+
  | 1. DATA INGESTION                         |
  | Documents (PDF, web, DB) -> Parse -> Clean |
  +-------------------------------------------+
         |
  +-------------------------------------------+
  | 2. CHUNKING                               |
  | Split into semantic units (500-1000 tokens)|
  +-------------------------------------------+
         |
  +-------------------------------------------+
  | 3. EMBEDDING                              |
  | text-embedding-3-small -> [0.12, -0.34...]|
  +-------------------------------------------+
         |
  +-------------------------------------------+
  | 4. VECTOR STORE                           |
  | Pinecone / Weaviate / pgvector / Chroma   |
  +-------------------------------------------+
         |  (query time)
  +-------------------------------------------+
  | 5. RETRIEVAL                              |
  | Semantic search + optional keyword hybrid  |
  +-------------------------------------------+
         |
  +-------------------------------------------+
  | 6. RERANKING (optional)                   |
  | Cross-encoder reorders by relevance        |
  +-------------------------------------------+
         |
  +-------------------------------------------+
  | 7. GENERATION                             |
  | LLM synthesizes answer from context        |
  +-------------------------------------------+

RAG vs Fine-tuning:
  | Factor        | RAG              | Fine-tuning       |
  |---------------|------------------|-------------------|
  | Knowledge update | Instant (add docs) | Retrain needed |
  | Cost          | Retrieval infra  | Training compute  |
  | Hallucination | Reduced (grounded)| Can still hallucinate|
  | Attribution   | Yes (cite sources)| No                |
  | Best for      | Dynamic knowledge | Style/behavior    |
  | Latency       | +retrieval time  | Same as base model|
```
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

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. RAG = retrieve relevant context, then generate with that context. Reduces hallucination, enables knowledge updates without retraining, provides source attribution.
2. Quality depends on every component: chunking (semantic units), embedding model (domain fit), retrieval (precision/recall), and generation prompt (grounding instructions).
3. RAG vs fine-tuning: RAG for knowledge (facts, documents, dynamic data), fine-tuning for behavior (style, format, domain-specific reasoning patterns). Often combined.

**Interview one-liner:**
"RAG grounds LLM responses in retrieved context - I architect pipelines with semantic chunking, hybrid retrieval (vector + keyword), cross-encoder reranking for precision, and generation prompts with strict grounding instructions and source citation, evaluating end-to-end with faithfulness and relevance metrics."
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

[TODO: Include if 2+ named alternatives exist for RAG Architecture. Otherwise remove this section.]
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

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
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

# Vector Databases

**TL;DR** - Vector databases store and efficiently search high-dimensional embeddings using approximate nearest neighbor (ANN) algorithms - enabling millisecond similarity search across millions of vectors for RAG, recommendation, and semantic search applications.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
You have 1 million document embeddings (1536 dimensions each). Finding the most similar vectors by brute-force comparison = 1M \* 1536 multiplications per query. Takes seconds, not milliseconds. Doesn't scale.
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

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
Vector database concepts:
  Store: Vectors + metadata + original text reference
  Index: ANN structure for fast approximate search
  Query: Input vector -> K nearest neighbors (ms latency)

ANN algorithms (how they make search fast):
  HNSW (Hierarchical Navigable Small World):
    Graph-based. Navigate layers to find neighbors.
    Best recall/speed trade-off. Most popular.
  IVF (Inverted File Index):
    Cluster vectors, search only relevant clusters.
    Good for large datasets, memory-efficient.
  PQ (Product Quantization):
    Compress vectors (reduce memory 4-8x).
    Lower recall but much less memory.

Vector database comparison:
  | Database   | Type      | Best For            |
  |-----------|-----------|---------------------|
  | Pinecone  | Managed   | Production, simple API|
  | Weaviate  | Managed/Self| Hybrid search, GraphQL|
  | Qdrant    | Self-host | Performance, Rust-based|
  | Milvus    | Self-host | Large scale, distributed|
  | pgvector  | Extension | Already using PostgreSQL|
  | Chroma    | Embedded  | Prototyping, local dev |

Key considerations:
  - Recall vs speed trade-off (tune index params)
  - Metadata filtering: filter BEFORE or AFTER vector search
  - Hybrid search: combine vector + keyword (BM25)
  - Scalability: millions vs billions of vectors
  - Update frequency: real-time vs batch indexing
  - Cost: managed ($$$) vs self-hosted (ops burden)

pgvector (start here for most teams):
  Already have PostgreSQL? Add pgvector extension.
  - Stores vectors alongside relational data
  - Supports HNSW and IVF indexes
  - SQL interface (familiar, transactional)
  - Good up to ~5M vectors
  - Scale beyond? Move to dedicated vector DB
```
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

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Vector databases enable millisecond similarity search using ANN algorithms (HNSW most popular). Trade-off: speed vs recall accuracy (tunable via index parameters).
2. Start with pgvector if you already use PostgreSQL (simpler, transactional, good to ~5M vectors). Move to Pinecone/Qdrant/Weaviate for scale or advanced features.
3. Metadata filtering + hybrid search (vector + keyword) significantly improves retrieval quality. Pure vector search misses exact matches; pure keyword misses semantic similarity.

**Interview one-liner:**
"Vector databases enable fast ANN search for RAG retrieval - I choose based on scale (pgvector for <5M vectors, dedicated DBs beyond), implement hybrid search (vector + BM25) for better recall, tune HNSW parameters for recall/latency trade-off, and use metadata pre-filtering to narrow search scope."
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

[TODO: Include if 2+ named alternatives exist for Vector Databases. Otherwise remove this section.]
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

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
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

# Chunking Strategies

**TL;DR** - Chunking determines how documents are split into units for embedding and retrieval - chunk size, overlap, and method (fixed, semantic, recursive) directly impact RAG quality because poorly chunked text produces poor embeddings and irrelevant retrieval results.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Embed an entire 50-page document as one vector? The embedding becomes too diluted (averages all topics). Embed each sentence individually? Lose context between sentences. Chunking strategy determines the granularity and quality of retrieval.
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

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
Chunking methods:
  1. Fixed-size (simplest):
     Split every N tokens (500, 1000)
     + Simple, predictable
     - Cuts mid-sentence, loses context

  2. Recursive character splitting:
     Split by: paragraphs > sentences > words
     Tries natural boundaries first
     + Respects structure somewhat
     - Still arbitrary at times

  3. Semantic chunking:
     Group sentences by semantic similarity
     Break when topic shifts (embedding distance)
     + Best semantic coherence
     - Slower, more complex, variable chunk sizes

  4. Document-structure aware:
     Split by: headers, sections, pages
     Respect document hierarchy
     + Perfect for structured documents
     - Requires format-specific parsers

  5. Parent-child (hierarchical):
     Store: Large parent chunk (context)
           + Small child chunks (retrieval)
     Search on children, return parent for context
     Best of both worlds (precise search, rich context)

Chunk size trade-offs:
  | Size     | Embedding quality | Retrieval | Context |
  |----------|-------------------|-----------|---------|
  | Small (100-200 tokens) | Precise  | High precision | Little context |
  | Medium (500-800 tokens)| Balanced | Balanced       | Good context   |
  | Large (1000-2000 tokens)| Diluted | Lower precision | Rich context  |

Best practices:
  - Start with 500-800 tokens, 100-200 token overlap
  - Add overlap (10-20%) to maintain context across boundaries
  - Include metadata: source, page, section header
  - Test with YOUR data and YOUR queries (no universal best)
  - Use section headers as context prefix in each chunk
    ("Chapter 3: Security > Authentication:\n" + chunk text)
```
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

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Start with 500-800 tokens with 10-20% overlap. Then tune based on retrieval evaluation (precision/recall on your actual queries).
2. Semantic/structure-aware chunking > fixed-size for most documents. Respect natural boundaries (paragraphs, sections, headers).
3. Parent-child chunking: search on small precise chunks, return larger parent for generation context. Balances retrieval precision with generation quality.

**Interview one-liner:**
"Chunking strategy directly determines RAG quality - I use recursive splitting with document-structure awareness (headers, sections), 500-800 token chunks with overlap, parent-child retrieval for precise search with rich context, and always evaluate chunking choices against actual query relevance."
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

[TODO: Include if 2+ named alternatives exist for Chunking Strategies. Otherwise remove this section.]
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

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
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

# Retrieval Methods

**TL;DR** - Effective RAG retrieval combines multiple methods: semantic search (vector similarity), keyword search (BM25/TF-IDF), hybrid approaches (combining both), and query transformation (rewriting queries for better matches) - because no single method handles all query types.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Pure vector search misses exact keyword matches ("error code ABC-123" won't find the document with that exact code). Pure keyword search misses semantic similarity ("how to fix memory issues" won't find "heap overflow troubleshooting"). You need both.
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

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
Retrieval methods:
  1. Semantic (Dense) Retrieval:
     Query -> embed -> cosine similarity search
     Finds: conceptually similar content
     Misses: exact terms, codes, names, acronyms

  2. Keyword (Sparse) Retrieval (BM25):
     Query -> tokenize -> term frequency matching
     Finds: exact matches, specific terms
     Misses: paraphrases, synonyms, concepts

  3. Hybrid (Dense + Sparse):
     Combine vector scores + BM25 scores
     Best overall recall - catches both types
     Methods: Reciprocal Rank Fusion (RRF), weighted sum

  4. Query transformation:
     Original: "Why is my app slow?"
     Rewritten: "application performance degradation
                 latency timeout slow response"
     HyDE: Generate hypothetical answer, embed THAT
     Multi-query: Generate 3-5 query variations, merge results

Hybrid search implementation:
  score = alpha * vector_score + (1-alpha) * bm25_score
  Typically alpha = 0.7 (favor semantic, boost keyword)

  Or Reciprocal Rank Fusion (RRF):
  RRF_score = sum(1 / (k + rank_i)) for each retriever
  (Combines rankings without needing score normalization)

Advanced retrieval patterns:
  Multi-step retrieval:
    1. Broad retrieval (top-50 from vector search)
    2. Rerank with cross-encoder (select top-5)
    3. Generate answer from top-5

  Contextual retrieval:
    Add document context to each chunk before embedding
    "This chunk is from [doc title], section [header]..."
    Improves embedding quality significantly

  Self-RAG:
    LLM decides: Do I need retrieval for this query?
    If yes: retrieve, then generate with context
    If no: generate directly (saves retrieval cost)
```
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

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Hybrid search (semantic + keyword) outperforms either alone. Use RRF or weighted combination. Most vector DBs support hybrid natively now.
2. Query transformation improves retrieval: multi-query (variations), HyDE (hypothetical answer embedding), and query decomposition (break complex queries into sub-queries).
3. Retrieval pipeline: broad recall (top-50) -> reranking (cross-encoder selects top-5) -> generation. Each stage narrows with increasing precision.

**Interview one-liner:**
"I implement hybrid retrieval (vector + BM25 with RRF fusion) for comprehensive recall, multi-query expansion for complex questions, and cross-encoder reranking to maximize precision in the final context window - evaluating retrieval independently from generation to isolate quality issues."
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

[TODO: Include if 2+ named alternatives exist for Retrieval Methods. Otherwise remove this section.]
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

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
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

# Reranking

**TL;DR** - Reranking uses a cross-encoder model to re-score retrieved documents by jointly encoding the query and each document together - dramatically improving precision over initial retrieval by catching subtle relevance signals that embedding similarity misses.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Initial retrieval (vector search) returns top-20 results. Some are relevant, some aren't. The order isn't optimal - result #15 might be more relevant than result #2. Bi-encoder embeddings can't capture fine-grained query-document interactions.
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

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
Bi-encoder vs Cross-encoder:
  Bi-encoder (embedding search - fast, less accurate):
    Query -> embed -> vector
    Doc -> embed -> vector
    Score = cosine_similarity(query_vec, doc_vec)
    Encodes query and doc INDEPENDENTLY
    Can't see interactions between them

  Cross-encoder (reranker - slow, more accurate):
    [query + doc] -> model -> relevance_score (0-1)
    Encodes query and doc TOGETHER
    Sees fine-grained word interactions
    Much more accurate but can't search millions

  Combined pipeline (best practice):
    Step 1: Bi-encoder retrieves top-50 (fast, broad)
    Step 2: Cross-encoder reranks top-50 -> top-5 (accurate)
    Step 3: Top-5 sent to LLM for generation

Reranking models:
  | Model              | Quality | Speed | Cost     |
  |-------------------|---------|-------|----------|
  | Cohere Rerank     | High    | Fast  | API cost |
  | BGE-reranker-v2   | High    | Medium| Free (OSS)|
  | cross-encoder/ms-marco | Good | Medium | Free    |
  | Jina Reranker     | High    | Fast  | API cost |
  | ColBERT (late interaction) | Good | Fast | Free  |

Impact of reranking:
  Without reranking: Retrieval precision ~60-70%
  With reranking: Retrieval precision ~85-95%
  (Precision = % of returned results that are relevant)

  Real improvement: The correct answer goes from
  position #7 to position #1 in the results

When to use reranking:
  - Always in production RAG (cheap precision boost)
  - When initial retrieval has >10 results to re-sort
  - When you observe relevant docs ranked low
  - Skip only for: real-time (<50ms) requirements,
    or when top-1 retrieval is already sufficient
```
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

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Reranking = cross-encoder re-scores retrieved results by jointly encoding query+document. Much more accurate than embedding similarity alone. Always use in production RAG.
2. Pipeline: bi-encoder retrieves top-50 (fast, broad recall) -> cross-encoder reranks to top-5 (slow, precise) -> LLM generates from top-5. Each stage trades speed for precision.
3. Reranking typically improves end-to-end RAG accuracy by 10-20%+ with minimal latency cost (50-200ms for 50 documents). Highest ROI improvement in most RAG systems.

**Interview one-liner:**
"Reranking via cross-encoder is the highest-ROI RAG improvement - jointly encoding query+document captures relevance signals that bi-encoder similarity misses. I use a retrieve-then-rerank pipeline (top-50 initial, rerank to top-5) with Cohere Rerank or BGE-reranker, adding 10-20% accuracy for ~100ms latency."
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

[TODO: Include if 2+ named alternatives exist for Reranking. Otherwise remove this section.]
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

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
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

# RAG Evaluation

**TL;DR** - RAG evaluation measures quality across the entire pipeline: retrieval quality (did we find relevant documents?), generation quality (is the answer faithful and relevant?), and end-to-end metrics (does the system answer correctly?) - using frameworks like RAGAS and custom evaluations.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
"The RAG system seems to work" is not a metric. Without evaluation: you can't measure improvement, can't catch regressions, can't identify whether problems are in retrieval or generation, can't compare configurations objectively.
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

**Level 1 - What it is (anyone can understand):**
[TODO: Plain English. No jargon. 2-4 sentences.]

**Level 2 - How to use it (junior developer):**
[TODO: Basic usage. Common patterns. 3-5 sentences.]

**Level 3 - How it works (mid-level engineer):**
[TODO: Internals. Data structures. 4-6 sentences.]

**Level 4 - Production mastery (senior/staff engineer):**
[TODO: Design decisions. Cross-system reasoning. 5-8 sentences.]



**The Senior-to-Staff Leap:**
A Senior says: "[TODO: What a competent senior would say]"
A Staff says: "[TODO: What demonstrates next-level abstraction]"
The difference: [TODO: 1 sentence - the mental model shift]

**Level 5 - Distinguished (expert thinking):**
[TODO: Cross-domain pattern recognition. Expert heuristics. 3-5 sentences.]
---

### ⚙️ How It Works

```
RAG evaluation dimensions:
  1. RETRIEVAL QUALITY (did we find the right docs?):
     Context Precision: % retrieved docs that are relevant
     Context Recall: % relevant docs that were retrieved
     MRR (Mean Reciprocal Rank): Position of first relevant doc

  2. GENERATION QUALITY (is the answer good?):
     Faithfulness: Is the answer supported by retrieved context?
       (No hallucination beyond what context provides)
     Answer Relevance: Does the answer address the question?
     Completeness: Does it cover all aspects of the question?

  3. END-TO-END:
     Correctness: Does answer match ground truth?
     Latency: Total time (retrieval + rerank + generation)
     Cost: Total tokens consumed per query

RAGAS framework (most popular):
  Metrics computed using LLM-as-judge:
  - Faithfulness: LLM checks if answer claims are in context
  - Answer Relevancy: LLM rates relevance to question
  - Context Precision: LLM rates relevance of retrieved docs
  - Context Recall: LLM checks if ground truth is in context

Evaluation dataset:
  | Question | Ground Truth Answer | Source Documents |
  |----------|--------------------|--------------------|
  | "What is our refund policy?" | "30-day full refund for..." | policy.pdf page 3 |
  | "How to reset password?" | "Navigate to Settings > ..." | help-center.md |
  (50-200 QA pairs covering your domain)

Evaluation pipeline:
  For each test case:
    1. Run query through RAG pipeline
    2. Record: retrieved chunks, generated answer
    3. Score: faithfulness, relevance, correctness
    4. Aggregate: mean scores, failure analysis
    5. Compare: against baseline or previous version

Continuous evaluation:
  - Run eval suite on every pipeline change
  - Monitor production: thumbs up/down, escalation rate
  - Track metrics over time (detect regression)
  - A/B test: new chunking strategy vs current
```
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

**WHAT IT IS:** [TODO]
**PROBLEM IT SOLVES:** [TODO]
**KEY INSIGHT:** [TODO]
**USE WHEN:** [TODO]
**AVOID WHEN:** [TODO]
**ANTI-PATTERN:** [TODO]
**TRADE-OFF:** [TODO]
**ONE-LINER:** [TODO]
**KEY NUMBERS:** [TODO: 2-3 critical thresholds/defaults/limits]
**TRIGGER PHRASE:** [TODO: 5-7 words activating full mental model]
**OPENING SENTENCE:** [TODO: First sentence showing immediate depth]

**If you remember only 3 things:**

1. Evaluate retrieval AND generation separately. Low faithfulness = generation problem. Low context recall = retrieval problem. Diagnose before fixing.
2. Build an evaluation dataset (50-200 QA pairs with ground truth from your domain). Without it, you're guessing about quality. This is the most important investment.
3. LLM-as-judge (RAGAS) for automated evaluation at scale, human evaluation for calibrating the LLM judge, and production monitoring (user feedback, escalation rates) for real-world quality.

**Interview one-liner:**
"I evaluate RAG systems across retrieval (precision/recall/MRR) and generation (faithfulness/relevance) independently to isolate issues, using RAGAS for automated scoring on a curated eval dataset, with production monitoring via user feedback and continuous evaluation on pipeline changes to prevent regression."
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

[TODO: Include if 2+ named alternatives exist for RAG Evaluation. Otherwise remove this section.]
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

**Q1: [TODO: Conceptual question - foundational]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete structured answer. 200-500 words.]

---

**Q2: [TODO: Debugging/diagnosis scenario]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with diagnostic steps.]

---

**Q3: [TODO: Architecture/design question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with design rationale.]

---

**Q4: [TODO: Trade-off decision question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with decision framework.]

---

**Q5: [TODO: Production scenario question]**

*Why they ask:* [TODO]

**Answer:**
[TODO: Complete answer with metrics/remediation.]
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
