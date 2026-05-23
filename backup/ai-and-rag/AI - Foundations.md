---
layout: default
title: "AI - Foundations"
parent: "AI Foundations, LLMs, RAG and Agents"
grand_parent: "Interview Mastery"
nav_order: 1
permalink: /interview/ai-and-rag/foundations/
topic: AI Foundations, LLMs, RAG and Agents
subtopic: Foundations
keywords:
  - Neural Networks
  - Transformers
  - Embeddings
  - Tokenization
  - Training vs Inference
  - Model Types
difficulty_range: medium
status: in-progress
version: 3
---

**Keywords covered in this file:**

- [Neural Networks](#neural-networks)
- [Transformers](#transformers)
- [Embeddings](#embeddings)
- [Tokenization](#tokenization)
- [Training vs Inference](#training-vs-inference)
- [Model Types](#model-types)

# Neural Networks

**TL;DR** - Neural networks are mathematical functions composed of layers of interconnected nodes (neurons) that learn patterns from data by adjusting weights through backpropagation - the foundation for all modern AI including LLMs, image recognition, and recommendation systems.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Traditional programming requires explicit rules: "if pixel pattern X, then cat." Writing rules for every possible cat image is impossible. You need a system that learns the rules from examples rather than being told them explicitly.
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
Neural network structure:
  Input Layer -> Hidden Layers -> Output Layer
  [features]    [learned repr]    [prediction]

  Each connection has a weight (learnable parameter)
  Each neuron applies: output = activation(sum(inputs * weights) + bias)

Training (learning):
  1. Forward pass: Input -> prediction
  2. Loss calculation: How wrong is the prediction?
  3. Backpropagation: Calculate gradient of loss
     w.r.t. each weight (chain rule of calculus)
  4. Update weights: w = w - learning_rate * gradient
  5. Repeat millions of times on training data

Key architectures:
  Feedforward (MLP): Basic. Input -> hidden -> output.
  CNN (Convolutional): Images. Local patterns, spatial.
  RNN/LSTM: Sequences. Memory of previous inputs.
  Transformer: Attention-based. Parallel. Modern LLMs.

Why deep (many layers) matters:
  Layer 1: Learns edges, basic patterns
  Layer 2: Learns shapes, combinations of edges
  Layer 3: Learns objects, combinations of shapes
  ...
  Layer N: Learns abstract concepts
  (Each layer builds on previous - hierarchical repr)
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

1. Neural networks learn patterns from data by adjusting weights through backpropagation (gradient descent). More data + more parameters = better pattern recognition.
2. Architecture matters: CNNs for images (spatial), RNNs for sequences (temporal), Transformers for everything modern (attention mechanism enables parallelism).
3. Deep = hierarchical feature learning. Early layers learn simple patterns, deeper layers learn complex abstractions. This is why "deep learning" works.

**Interview one-liner:**
"Neural networks are differentiable function approximators that learn hierarchical representations through backpropagation - with Transformers (attention-based, parallelizable) replacing RNNs as the dominant architecture for sequence modeling due to their ability to capture long-range dependencies."
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

[TODO: Include if 2+ named alternatives exist for Neural Networks. Otherwise remove this section.]
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

# Transformers

**TL;DR** - Transformers are the architecture behind all modern LLMs (GPT, Claude, Llama) - using self-attention to process entire sequences in parallel (unlike sequential RNNs), enabling models to capture long-range dependencies and scale to billions of parameters.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
RNNs process sequences one token at a time (sequential bottleneck). Long sequences lose early context (vanishing gradient). Training is slow because each step depends on the previous. You can't parallelize the computation.
---

### 📘 Textbook Definition

The Transformer architecture (Vaswani et al., 2017 - "Attention Is All You Need") replaces recurrence with self-attention, allowing every position in a sequence to attend to every other position in parallel. It consists of encoder (understanding) and decoder (generation) stacks, with multi-head attention, positional encoding, and feed-forward layers.
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
Transformer architecture:
  Input: "The cat sat on the mat"
  +--------------------------------------------+
  | Tokenization: [The][cat][sat][on][the][mat] |
  | + Positional Encoding (position info)       |
  +--------------------------------------------+
        |
  +--------------------------------------------+
  | Multi-Head Self-Attention:                 |
  | Each token attends to ALL other tokens     |
  | "sat" attends strongly to "cat" (subject)  |
  | Learns WHAT to pay attention to            |
  | Q (query) * K (key) -> attention weights   |
  | Attention weights * V (value) -> output    |
  +--------------------------------------------+
        |
  +--------------------------------------------+
  | Feed-Forward Network (per position)        |
  | Dense layers add non-linearity             |
  +--------------------------------------------+
        |
  Repeat N layers (GPT-4 has ~120 layers)

Self-attention formula:
  Attention(Q,K,V) = softmax(QK^T / sqrt(d_k)) * V
  - Q: What am I looking for?
  - K: What do I contain?
  - V: What do I output if matched?

Why it works:
  - Parallel: All positions computed simultaneously
  - Global context: Every token sees every other token
  - Scalable: More layers/heads = more capacity
  - Versatile: Same architecture for text, code, images

Model variants:
  Encoder-only: BERT (understanding, classification)
  Decoder-only: GPT, Claude, Llama (generation)
  Encoder-Decoder: T5, BART (translation, summarization)
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

1. Self-attention lets every token attend to every other token in parallel (O(n^2) computation vs O(n) sequential in RNNs). This is both its power and scaling challenge.
2. Q/K/V mechanism: Query (what I'm looking for) x Key (what I contain) = attention weight. Weight x Value = contextualized output. Multi-head = multiple attention patterns simultaneously.
3. Modern LLMs are decoder-only Transformers (GPT, Claude, Llama): autoregressive, generate one token at a time during inference, but trained in parallel on all positions.

**Interview one-liner:**
"Transformers replaced RNNs via self-attention (parallel, global context, scalable) - modern LLMs are decoder-only Transformers generating tokens autoregressively, with the attention mechanism (QKV) enabling each position to attend to relevant context across the entire sequence."
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

[TODO: Include if 2+ named alternatives exist for Transformers. Otherwise remove this section.]
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

# Embeddings

**TL;DR** - Embeddings are dense vector representations of text/data in high-dimensional space where semantic similarity is captured by geometric distance - enabling similarity search, RAG retrieval, clustering, and recommendation without keyword matching.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
"Dog" and "puppy" are completely different strings. Keyword search for "dog" won't find documents about "puppies." You need a way to represent meaning numerically so similar concepts are near each other in vector space.
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
Embedding concept:
  Text -> Embedding Model -> Vector [0.12, -0.34, ..., 0.89]
                              (768 or 1536 dimensions)

  "King" - "Man" + "Woman" ~= "Queen" (vector arithmetic!)

  Similar meanings -> vectors close together (cosine sim):
    cosine_sim("dog", "puppy") = 0.92 (very similar)
    cosine_sim("dog", "cat") = 0.75 (related)
    cosine_sim("dog", "blockchain") = 0.12 (unrelated)

Embedding models:
  | Model          | Dims | Use Case          |
  |---------------|------|-------------------|
  | text-embedding-3-small (OpenAI) | 1536 | General purpose   |
  | text-embedding-3-large (OpenAI) | 3072 | Higher quality     |
  | all-MiniLM-L6 (open source) | 384  | Fast, lightweight  |
  | BGE-large (open source) | 1024 | High quality, free |
  | Cohere embed-v3 | 1024 | Multilingual      |

Applications:
  1. Semantic search: Query -> embed -> find nearest vectors
  2. RAG retrieval: Chunk docs -> embed -> store in vector DB
  3. Clustering: Group similar documents automatically
  4. Anomaly detection: Find outliers in embedding space
  5. Recommendations: Find items similar to user preferences

Key considerations:
  - Same model for indexing and querying (must match!)
  - Chunk size affects quality (too big = diluted meaning)
  - Cosine similarity vs Euclidean distance (cosine preferred)
  - Dimensionality: higher = more expressive, more compute
  - Fine-tuning embeddings for domain-specific retrieval
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

1. Embeddings map semantic meaning to geometric space: similar text = nearby vectors. Enables similarity search without keyword matching.
2. Same embedding model MUST be used for indexing and querying. Mixing models = garbage results (different vector spaces).
3. RAG depends on embedding quality: chunk size, model choice, and domain relevance all affect retrieval accuracy. Test with your actual data.

**Interview one-liner:**
"Embeddings encode semantic meaning as dense vectors enabling similarity search via cosine distance - I choose embedding models based on domain fit and benchmark performance (MTEB), ensure consistent models between indexing and query time, and optimize chunk sizes for retrieval quality in RAG pipelines."
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

[TODO: Include if 2+ named alternatives exist for Embeddings. Otherwise remove this section.]
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

# Tokenization

**TL;DR** - Tokenization converts text into numerical tokens (subword units) that models process - affecting context window utilization, cost (billed per token), multilingual performance, and model behavior. Understanding tokens is essential for prompt engineering and cost management.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Models can't process raw text. They need numbers. Character-level is too granular (sequences become very long). Word-level can't handle new words or morphology. You need a middle ground that balances vocabulary size, sequence length, and coverage.
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
Tokenization approaches:
  Character: "hello" -> [h, e, l, l, o] (very long sequences)
  Word: "unhappiness" -> [unhappiness] (huge vocabulary)
  Subword (BPE): "unhappiness" -> [un, happiness] (balanced!)

BPE (Byte Pair Encoding) - used by GPT/Claude:
  Start with characters, iteratively merge frequent pairs
  "low" "lower" "newest" "widest" ->
    Characters: l,o,w,e,r,n,w,s,t
    Merge 'e'+'s' -> 'es': low, lower, newest, widest
    Merge 'es'+'t' -> 'est': low, lower, newest, widest
    ...until vocabulary size reached (50K-100K tokens)

Token counts (GPT-4 / cl100k_base):
  "Hello, world!" -> 4 tokens
  "Supercalifragilistic" -> 5 tokens
  "   " (3 spaces) -> 1 token
  Code: ~2-3 tokens per line on average
  English: ~1 token per 4 characters / 0.75 words

Why tokenization matters:
  1. Cost: Billed per token (input + output)
     GPT-4: $30/M input tokens, $60/M output tokens
  2. Context window: 128K tokens = ~96K words
     Inefficient tokenization wastes context window
  3. Multilingual: Non-English often uses MORE tokens
     Chinese/Japanese: 1 char might be 2-3 tokens
  4. Code: Whitespace and formatting consume tokens
  5. Prompt engineering: Token boundaries affect behavior
     "un" + "happy" vs "unhappy" = different tokens

Practical implications:
  - Shorter prompts = cheaper + faster (fewer tokens)
  - Remove unnecessary whitespace in code prompts
  - Non-English text is more expensive (more tokens)
  - Use tiktoken (OpenAI) to count before sending
  - JSON is token-expensive (quotes, braces, colons)
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

1. Tokens are subword units (BPE). ~4 chars per token in English, ~0.75 words per token. Non-English and code can be less efficient.
2. Tokens determine cost (billed per token), context window usage (limited tokens), and speed (more tokens = slower generation).
3. Use tokenizer tools (tiktoken, Anthropic's token counter) to estimate costs and context usage before sending large prompts.

**Interview one-liner:**
"Tokenization via BPE converts text to subword units that determine cost, context window utilization, and generation speed - I optimize by understanding token economics (~4 chars/token English), using structured formats efficiently, and pre-counting tokens to stay within context limits."
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

[TODO: Include if 2+ named alternatives exist for Tokenization. Otherwise remove this section.]
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

# Training vs Inference

**TL;DR** - Training learns model parameters from data (expensive, GPU-intensive, done once), while inference uses the trained model to generate predictions (cheaper per request, latency-sensitive, done millions of times) - understanding this distinction is key to AI system architecture.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
Without separating training from inference, teams either try to train on every request (impossibly expensive and slow) or don't understand why inference has different hardware/scaling requirements than training. The distinction drives all AI infrastructure decisions.
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
Training vs Inference:
  | Aspect      | Training            | Inference           |
  |-------------|---------------------|---------------------|
  | Purpose     | Learn weights       | Use weights         |
  | Frequency   | Once (or periodic)  | Every request       |
  | Duration    | Days-weeks          | Milliseconds-seconds|
  | Hardware    | GPU clusters (A100) | GPUs or optimized   |
  | Cost        | $1M-$100M (LLMs)   | $0.001-$0.06/request|
  | Optimization| Throughput (batch)  | Latency (real-time) |
  | Data        | Trillions of tokens | Single prompt       |
  | Memory      | Model + gradients   | Model only          |

Training pipeline:
  Data collection -> Preprocessing -> Tokenization
    -> Pre-training (self-supervised, massive compute)
      -> Fine-tuning (task-specific, less compute)
        -> RLHF (alignment, moderate compute)
          -> Evaluation -> Deployment

Inference optimization:
  - Quantization: FP32 -> INT8/INT4 (smaller, faster)
  - KV caching: Store computed attention (avoid recompute)
  - Batching: Process multiple requests together
  - Speculative decoding: Draft model proposes, big verifies
  - Distillation: Train small model to mimic large model
  - Hardware: Inference-specific chips (AWS Inferentia)

Cost comparison (GPT-4 scale):
  Training: ~$100M (one-time, A100 clusters, months)
  Inference: ~$0.03/request but x1B requests = $30M/month
  Insight: At scale, inference cost > training cost

For engineers building AI products:
  - You DON'T train foundation models (use existing ones)
  - You MAY fine-tune (your data + base model)
  - You ALWAYS do inference (API calls or self-hosted)
  - Inference latency = user experience (P99 matters)
  - Inference cost = unit economics (cost per request)
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

1. Training = learning weights (expensive, slow, done rarely). Inference = using weights (cheap per request, fast, done constantly). Different hardware and optimization needs.
2. Most engineers never train - you use existing models via API (OpenAI, Anthropic) or fine-tune. Your concern is inference: latency, cost, and reliability.
3. Inference optimization matters at scale: quantization (smaller model), batching (throughput), KV caching (avoid recomputation), and model selection (smaller model sufficient?).

**Interview one-liner:**
"Training learns parameters (one-time, massive compute) while inference applies them (per-request, latency-sensitive) - I focus on inference optimization (model selection for cost/quality trade-off, quantization, caching, batching) since at scale inference cost dominates, and on fine-tuning decisions (when RAG isn't sufficient)."
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

[TODO: Include if 2+ named alternatives exist for Training vs Inference. Otherwise remove this section.]
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

# Model Types

**TL;DR** - AI models span different architectures and purposes: foundation models (general, pre-trained on massive data), fine-tuned models (specialized), open-source vs proprietary, and different modalities (text, image, audio, multimodal) - choosing correctly drives cost, quality, and flexibility.
---

### 🔥 The Problem This Solves

**WORLD WITHOUT IT:**
"Just use GPT-4 for everything" wastes money on simple tasks. "Just use the cheapest model" fails on complex reasoning. Without understanding model types and capabilities, you either overspend or get poor results.
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
Model landscape (2024-2025):
  Foundation Models (general purpose):
    GPT-4o, Claude 3.5 Sonnet, Gemini Pro, Llama 3
    Pre-trained on internet-scale data
    Good at: reasoning, generation, following instructions

  Smaller / Faster Models:
    GPT-4o-mini, Claude Haiku, Gemini Flash, Phi-3
    Less capable but 10-50x cheaper
    Good at: classification, extraction, simple tasks

  Open Source:
    Llama 3 (Meta), Mistral, Qwen, DeepSeek
    Self-hostable, customizable, no vendor lock-in
    Good at: privacy-sensitive, fine-tuning, edge deployment

  Specialized:
    Code: Codex, StarCoder, DeepSeek-Coder
    Embedding: text-embedding-3, BGE, Cohere embed
    Image: DALL-E 3, Stable Diffusion, Midjourney
    Speech: Whisper (transcription), TTS models

Model selection framework:
  1. Task complexity:
     Simple (classify, extract) -> small/fast model
     Complex (reason, create) -> large model
  2. Latency requirements:
     Real-time (<1s) -> smaller or cached
     Background -> can use larger, slower models
  3. Cost sensitivity:
     High volume -> optimize for $/request
     Low volume -> optimize for quality
  4. Privacy/compliance:
     Sensitive data -> self-hosted or on-premises
     Public data -> API-based (simpler)
  5. Customization needs:
     Domain-specific -> fine-tune or RAG
     General -> use off-the-shelf

Proprietary vs Open Source:
  | Factor      | Proprietary (OpenAI, Anthropic) | Open Source (Llama, Mistral) |
  |-------------|-------------------------------|------------------------------|
  | Quality     | Highest (usually)             | Close, rapidly improving     |
  | Cost        | Per-token pricing             | Infrastructure only          |
  | Control     | API-dependent                 | Full control                 |
  | Privacy     | Data sent to provider         | Data stays local             |
  | Customization| Limited fine-tuning          | Full fine-tuning, merge      |
  | Ops burden  | Zero (managed)                | Significant (self-host)      |
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

1. Use the smallest model that achieves acceptable quality. GPT-4o-mini/Haiku for simple tasks (classification, extraction) at 1/10th the cost. Large models for complex reasoning only.
2. Open source (Llama 3, Mistral) for: data privacy, fine-tuning, cost at scale, no vendor lock-in. Proprietary (GPT-4, Claude) for: best quality, zero ops, rapid iteration.
3. Model routing: Use a classifier or heuristic to route simple requests to cheap models and complex ones to expensive models. Reduces cost 50-80% with minimal quality loss.

**Interview one-liner:**
"I select models based on task complexity, latency, and cost - routing simple extraction to small models (Haiku/mini), complex reasoning to frontier models (Sonnet/GPT-4o), and using open-source (Llama) for privacy-sensitive workloads or high-volume inference where self-hosting economics make sense."
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

[TODO: Include if 2+ named alternatives exist for Model Types. Otherwise remove this section.]
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
