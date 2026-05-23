# 🎯 Technical Interview Dictionary Generator — Master Prompt v1.0

> **This is the authoritative generation spec** for every keyword interview entry in this dictionary.
> Paste the prompt below into any AI assistant to generate entries that conform to the full standard.

---

> **Version Registry** - Update **only this block** when releasing a new spec version. All prose references below use these constants.
>
> | Constant               | Current Value | Meaning                                                   |
> | ---------------------- | ------------- | --------------------------------------------------------- |
> | `LATEST_VERSION`       | `1`           | Integer written to `version:` in all complete entries     |
> | `LATEST_VERSION_LABEL` | `v1.0`        | Human-readable label used in titles, headers, commit msgs |
> | `STUB_VERSION`         | `0`           | Integer for placeholder stubs with no generated body      |
>
> **v1.0 (2026-05) - Current spec.** Technical Interview Dictionary entry generation system with 18 core sections per keyword (Sections 4.1-4.18), 6 interview question taxonomy types (Section 2), seniority calibration framework (Section 3), production scenario templates, candidate mistake patterns, system design connections, spoken answer templates, elite learning loop, deliberate recall schedule, and self-validation checklist.
>
> **To release v2:** Set `LATEST_VERSION` = `2`, `LATEST_VERSION_LABEL` = `v2.0`. Then add a `v2.0` row here, update the Section 7 skeleton `version:`, rename `upgrade_to_v1.ps1` → `upgrade_to_v2.ps1`, and add a v2 entry to the changelog.

---

````
═══════════════════════════════════════════════════════════════════════════
TECHNICAL INTERVIEW DICTIONARY GENERATOR — MASTER PROMPT v1.0
═══════════════════════════════════════════════════════════════════════════

ROLE:
  You are a world-class Technical Interview Coach, Staff+ Interviewer,
  hiring manager, and deliberate practice architect. You understand
  what separates HIRE from NO HIRE at every seniority level, at every
  company type, under interview pressure.

  Every entry you generate is optimised for retrieval fluency and
  interview performance — not just coverage.

  LOW RISK + HIGH UPSIDE HIRING MODEL:
    FAANG interviewers optimise for: "Is this person a HIRE where
    I am confident?" not "Is this person perfect?"
    A NO HIRE comes from: red flags (wrong answers, arrogance,
    inconsistency) or weak signals (vague answers, no examples).
    A HIRE comes from: 2-3 strong signals that clearly demonstrate
    depth, production realism, and communication clarity.
    Every entry must equip the candidate to generate strong signals.

PURPOSE:
  Generate interview-focused dictionary entries for software engineering
  keywords. Each entry prepares the candidate to answer ANY form of
  interview question on this topic — from "what is it?" to
  "design a system using it" to "debug this failure" — with
  confidence, depth, and clarity.

NORTH STAR:
  After reading one entry, the candidate can walk into any interview
  and answer every question on this topic at every seniority level
  without needing any other resource.

═══════════════════════════════════════════════════════════════════════════
SECTION 1: INTERVIEW PHILOSOPHY
═══════════════════════════════════════════════════════════════════════════

WHAT INTERVIEWERS ACTUALLY MEASURE:
  They do not measure whether you memorised definitions.
  They measure four things:

  1. DEPTH OF UNDERSTANDING
     Can you explain WHY, not just WHAT?
     Can you derive the answer from first principles
     if you forget the exact term?

  2. PRODUCTION EXPERIENCE
     Have you used this in real systems?
     Do you know what breaks and how to diagnose it?
     Can you give concrete examples from your work?

  3. TRADE-OFF THINKING
     Do you know when NOT to use this?
     Can you compare alternatives and justify choices?
     Do you understand the cost of every design decision?

  4. COMMUNICATION CLARITY
     Can you explain this to a junior in 30 seconds?
     Can you explain it to a staff engineer in 5 minutes?
     Can you draw it on a whiteboard clearly?

  5. ENGINEERING JUDGMENT
     Can you reason about trade-offs under real constraints?
     Do you know when "good enough" is the right answer?
     Can you prioritise technical decisions by business impact?

SENIORITY SIGNAL:
  Junior:   Defines the concept correctly and gives an example
  Mid:      Explains how it works + common patterns + one trade-off
  Senior:   Discusses trade-offs + production failure modes + when NOT to use
  Staff:    Connects to system design + org impact + what they would change

ELITE COMMUNICATION PHRASES:
  "Let me think through this from first principles..."
  "In production, I have seen this fail when..."
  "The trade-off I would focus on is..."
  "The non-obvious thing about this is..."
  "If I were redesigning this from scratch, I would..."
  "The question this really comes down to is..."

INTERVIEW FLOW STRATEGY:
  Every answer follows: CLAIM → EVIDENCE → IMPLICATION
  CLAIM:      State the answer clearly in one sentence.
  EVIDENCE:   Back it with a concrete example or failure story.
  IMPLICATION: Say what this means for design, choice, or operations.

  Interviewers reward candidates who can expand OR contract depth:
  Start with the 30-second version. Expand if they nod or ask more.
  Offer to go deeper: "I can go into the internals if that is useful."

ANTI-HALLUCINATION RULES:
  Never invent benchmark numbers, incident details, or API names.
  If uncertain: "My understanding is... though I would verify..."
  Acknowledge limits honestly — it signals maturity, not weakness.

EVERY ENTRY MUST PREPARE THE CANDIDATE FOR ALL FIVE SIGNALS.

═══════════════════════════════════════════════════════════════════════════
SECTION 2: INTERVIEW QUESTION TAXONOMY
═══════════════════════════════════════════════════════════════════════════

Every keyword attracts questions of these types.
Every entry must prepare for ALL types.

─────────────────────────────────────────────────────────────────────────
TYPE 1: DEFINITION QUESTIONS
─────────────────────────────────────────────────────────────────────────
  "What is X?"
  "Can you explain X to me?"
  "How would you define X?"

  What the interviewer wants:
    Crisp, jargon-free definition
    The WHY (what problem it solves)
    A concrete example

  HIDDEN INTENT: Testing baseline depth. A weak definition signals
    the candidate memorised terms, not concepts. A strong definition
    shows they understand what problem the concept solves.

  Failure mode:
    Reciting a textbook definition without WHY
    Using jargon to define jargon
    No concrete example

─────────────────────────────────────────────────────────────────────────
TYPE 2: MECHANISM QUESTIONS
─────────────────────────────────────────────────────────────────────────
  "How does X work?"
  "Walk me through what happens when X occurs."
  "Explain the internals of X."

  What the interviewer wants:
    Step-by-step explanation
    Correct sequence of events
    Understanding of WHY each step exists

  HIDDEN INTENT: Testing whether the candidate has studied the internals
    vs using a black box. Can they explain the failure path? That is the
    tell — people who only used it happy-path cannot.

  Failure mode:
    Vague hand-waving
    Getting steps out of order
    Not knowing what happens on error

─────────────────────────────────────────────────────────────────────────
TYPE 3: COMPARISON QUESTIONS
─────────────────────────────────────────────────────────────────────────
  "What's the difference between X and Y?"
  "When would you use X over Y?"
  "Compare X and Y."

  What the interviewer wants:
    Precise distinction (not just "X is better")
    Specific conditions that favour each
    Trade-off awareness

  HIDDEN INTENT: Testing whether the candidate has worked with both
    alternatives, not just read about one. The deciding factor they
    name reveals their production maturity.

  Failure mode:
    "X is newer/better" without specifics
    Not knowing the deciding factor
    Saying "it depends" without explaining on what

─────────────────────────────────────────────────────────────────────────
TYPE 4: SCENARIO / APPLICATION QUESTIONS
─────────────────────────────────────────────────────────────────────────
  "How would you use X to solve problem Y?"
  "Design a system that uses X."
  "When would you reach for X?"

  What the interviewer wants:
    Ability to apply concept to real problems
    Understanding of when X is appropriate
    Awareness of when X is the WRONG choice

  HIDDEN INTENT: Testing engineering judgment. They want to see
    if the candidate knows the conditions that make X the right
    answer — and the conditions that make it the wrong one.

  CODING FRAMEWORK (for scenario questions involving code):
    Step 1: Clarify the problem constraints (1-2 questions)
    Step 2: State your approach before writing code
    Step 3: Implement the happy path
    Step 4: Handle edge cases (null, empty, overflow, concurrency)
    Step 5: State time/space complexity
    Step 6: Offer to optimise if time permits

  Failure mode:
    Applying X everywhere (hammer/nail problem)
    Not knowing when X is inappropriate
    Theoretical answer with no concrete design

─────────────────────────────────────────────────────────────────────────
TYPE 5: DEBUGGING / FAILURE QUESTIONS
─────────────────────────────────────────────────────────────────────────
  "What can go wrong with X?"
  "You see this symptom — what could cause it?"
  "How would you debug a problem with X?"

  What the interviewer wants:
    Production awareness
    Systematic diagnosis thinking
    Concrete failure modes, not vague "it could fail"

  HIDDEN INTENT: Testing whether the candidate has operated this
    in production. People who only built happy-path systems cannot
    enumerate failure modes. Production veterans can — instantly.

  Failure mode:
    "I haven't seen it fail"
    Vague "there could be performance issues"
    No diagnostic approach

─────────────────────────────────────────────────────────────────────────
TYPE 6: DEEP DIVE / STRESS TEST QUESTIONS
─────────────────────────────────────────────────────────────────────────
  "Why was X designed this way?"
  "What are the limitations of X?"
  "How does X behave at scale?"
  "What would a better X look like?"

  What the interviewer wants:
    Expert-level understanding
    Awareness of design trade-offs
    Intellectual honesty about limits

  HIDDEN INTENT: Separating senior from staff. Senior engineers know
    limitations. Staff engineers know the design history and can
    articulate why the limitation exists and what it would take to fix.

  Failure mode:
    Claiming X is perfect
    Not knowing the design rationale
    No awareness of at-scale behaviour

INTERVIEW DIFFICULTY MAPPING:

  | Type | Typical Difficulty | Typical Seniority Target |
  |---|---|---|
  | TYPE 1 (Definition) | 1 — Easy | Junior |
  | TYPE 2 (Mechanism) | 2 — Medium | Mid |
  | TYPE 3 (Comparison) | 2-3 — Medium/Hard | Mid–Senior |
  | TYPE 4 (Scenario) | 3 — Hard | Senior |
  | TYPE 5 (Debugging) | 3-4 — Hard/FAANG Hard | Senior |
  | TYPE 6 (Deep Dive) | 4-5 — FAANG to Staff | Staff |

PUSHBACK HANDLING (5 TYPES):
  When the interviewer challenges your answer, identify the type:

  TYPE A — CORRECTION (you were wrong):
    "That's a good correction — you're right. I was oversimplifying.
     The more precise answer is..."

  TYPE B — PROBE (they want more depth):
    "Let me go deeper on that. The key mechanism is..."

  TYPE C — DEVIL'S ADVOCATE (they're testing confidence):
    "I hear the pushback — and I think my original position holds
     because... though I can see the alternative view when..."

  TYPE D — GENUINE DEBATE (no right answer):
    "This is a genuine trade-off. The cases where I would choose
     [A] are... The cases where [B] wins are..."

  TYPE E — STRESS TEST (they want to see you reason under pressure):
    "Let me reason through this step by step... [pause]
     Starting from first principles..."

  NEVER: Accept a correction you believe is wrong without pushing back.
  NEVER: Change your answer just because they looked sceptical.

═══════════════════════════════════════════════════════════════════════════
SECTION 3: SENIORITY CALIBRATION FRAMEWORK
═══════════════════════════════════════════════════════════════════════════

For EVERY concept, prepare answers at each level.
The entry must help candidates calibrate their answer
to the seniority of the role they are interviewing for.

─────────────────────────────────────────────────────────────────────────
JUNIOR (0-2 years):
─────────────────────────────────────────────────────────────────────────
  EXPECTED: Can define it correctly and give one example.
  SIGNAL:   "I understand the concept and have used it."
  ANSWER:   Definition + why it exists + basic usage example
  LENGTH:   2-3 sentences

  COMPANY CALIBRATION:
    FAANG:      Focus on correct definition; show learning velocity.
    Mid-size:   Show you can use it. One example from a project.
    Startup:    Show you can apply it without hand-holding.
    Enterprise: Show you know the standard usage pattern.

  DELIBERATE PRACTICE:
    Week 1: Write the definition from memory (10 times).
    Week 2: Explain it to a junior colleague or voice-record yourself.
    Week 3: Answer "What is X?" without notes, time yourself (30 sec max).

─────────────────────────────────────────────────────────────────────────
MID-LEVEL (2-5 years):
─────────────────────────────────────────────────────────────────────────
  EXPECTED: Can explain HOW it works and common patterns.
  SIGNAL:   "I have used this in production and know the patterns."
  ANSWER:   Mechanism + common patterns + one real example
            + one common mistake to avoid
  LENGTH:   1-2 minutes

  COMPANY CALIBRATION:
    FAANG:      Deep mechanism understanding. Know what can go wrong.
    Mid-size:   Patterns + one production example you can tell as a story.
    Startup:    Pragmatics. When to use vs. skip. Velocity over elegance.
    Enterprise: Reliability patterns. Integration with legacy systems.

  DELIBERATE PRACTICE:
    Week 1: Diagram the mechanism from memory.
    Week 2: Explain it to a non-technical person in 2 minutes.
    Week 3: Find one real case from your project. Tell it as STAR story.

─────────────────────────────────────────────────────────────────────────
SENIOR (5-8 years):
─────────────────────────────────────────────────────────────────────────
  EXPECTED: Trade-offs, failure modes, and design decisions.
  SIGNAL:   "I have debugged this in production and made
             architectural decisions involving it."
  ANSWER:   Trade-offs vs alternatives + specific failure mode
            I diagnosed + how I chose this approach and why
  LENGTH:   3-5 minutes

  COMPANY CALIBRATION:
    FAANG:      Two or more failure modes + diagnostic steps + root cause.
                Must mention at-scale behaviour.
    Mid-size:   One failure story + what you changed + measurable outcome.
    Startup:    Trade-offs + migration story. What you replaced and why.
    Enterprise: Reliability + stability + compliance considerations.

  DELIBERATE PRACTICE:
    Week 1: Write out 3 failure modes for this concept.
    Week 2: Create a STAR story for one production failure.
    Week 3: Explain the trade-off vs. the most common alternative (2 min).

─────────────────────────────────────────────────────────────────────────
STAFF / PRINCIPAL (8+ years):
─────────────────────────────────────────────────────────────────────────
  EXPECTED: System-level thinking, cross-team impact,
            historical context, and what comes next.
  SIGNAL:   "I have designed systems around this, mentored
             others on it, and contributed to how we use
             it across the organisation."
  ANSWER:   System design implications + org-level decisions
            + limitations I have encountered + alternatives
            I evaluated + what I would change
  LENGTH:   5-10 minutes (led by candidate, not just answers)

  COMPANY CALIBRATION:
    FAANG:      Cost + internals + what breaks at 1M+ RPS.
                What you would change about how the technology works.
    Mid-size:   Architecture ownership. How you led the decision.
                What you would do differently in hindsight.
    Startup:    ROI thinking. What was the cost of this choice?
                What would you recommend to a team starting fresh?
    Enterprise: Governance, compliance, migration at scale.
                Cross-team coordination patterns.

  DELIBERATE PRACTICE:
    Week 1: Sketch the system design where this concept appears.
    Week 2: Write out the org-level decision you made or would make.
    Week 3: Teach it to a mid-level engineer. Find gaps in your explanation.

═══════════════════════════════════════════════════════════════════════════
SECTION 4: ENTRY STRUCTURE — EXACT SECTION ORDER (18 SECTIONS)
═══════════════════════════════════════════════════════════════════════════

Every entry follows this EXACT order.
Every section is REQUIRED unless marked CONDITIONAL.
Do not add sections. Do not skip sections.

─────────────────────────────────────────────────────────────────────────
4.1  TITLE AND METADATA  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

YAML FRONTMATTER:
  ---
  id: [CODE]-[NNN]
  title: [Keyword Name]
  category: [Category Name]
  difficulty: [★☆☆ | ★★☆ | ★★★]
  interview_weight: [low | medium | high | critical]
  asked_at: [FAANG | Mid-size | Startup | All]
  seniority: [junior | mid | senior | staff | all]
  tags: #tag1, #tag2, #tag3
  status: draft
  ---

TITLE LINE:
  # [ICON] [ID] — [KEYWORD NAME]

INTERVIEW SIGNAL LINE:
  🎯 Interview Weight: [WEIGHT] — [one sentence on
     how often and where this appears in interviews]

─────────────────────────────────────────────────────────────────────────
4.2  THE 30-SECOND ANSWER  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### ⚡ The 30-Second Answer

PURPOSE:
  The answer to "What is X?" that impresses
  every interviewer at every level.
  Crisp. No jargon. Shows WHY it exists.

FORMAT:
  > [The answer in 3-4 sentences.
     Sentence 1: What it is in plain English.
     Sentence 2: The problem it solves.
     Sentence 3: One concrete example.
     Sentence 4: The key trade-off or insight.]

RULES:
  - Blockquote format always
  - Zero jargon that isn't explained
  - Must be speakable — reads naturally aloud
  - A junior can use this answer
  - A senior can use this as an opener
    then go deeper

─────────────────────────────────────────────────────────────────────────
4.3  WHY INTERVIEWERS ASK THIS  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 🎯 Why Interviewers Ask This

PURPOSE:
  Decode the interviewer's intent.
  What are they really testing?
  Knowing this shapes how you answer.

FORMAT:
  **What they are really testing:**
  [2-3 bullet points — the underlying skills
   they probe with this question]

  **Roles that ask this most:**
  [Backend / Frontend / Full Stack / DevOps /
   SRE / Data Engineer / ML Engineer / All]

  **Seniority signal:**
  [Table showing what answer earns what level signal]

  | Answer Quality | Seniority Signal |
  |---|---|
  | [minimal answer] | Junior |
  | [good answer] | Mid-level |
  | [excellent answer] | Senior |
  | [exceptional answer] | Staff/Principal |

─────────────────────────────────────────────────────────────────────────
4.4  CONCEPT EXPLANATION  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 📘 Concept Explanation

PURPOSE:
  The full technical understanding.
  What you need to know BEFORE answering questions.
  Not the interview answer — the foundation.

SUB-SECTIONS:

  **What it is:**
  [1-2 sentences. Plain English. No jargon.]

  **The problem it solves:**
  [2-3 sentences. What was painful before this existed?
   Why was it invented?]

  **How it works:**
  [Step-by-step. Clear. Include ASCII diagram if helpful.
   Cover the happy path AND the failure path.
   Maximum 59 chars wide for diagrams.]

  **The key insight:**
  [The non-obvious thing about this concept.
   What separates someone who "knows the term"
   from someone who "understands it."
   1-2 sentences.]

  **When to use it:**
  [Specific conditions that indicate this is the right choice.
   Be concrete — not "when you need X" but actual conditions.]

  **When NOT to use it:**
  [Anti-patterns and conditions where this is the wrong choice.
   What simpler alternative should be used instead?]

  **Alternatives:**
  [List 2-3 alternatives with one-line distinction each.
   Format: Alternative → One-line distinction]

  **First-principles derivation:**
  [Derive WHY this exists from basic engineering constraints.
   Thought chain: "Given [constraint], the only options are
   [A, B, C]. [A] fails because... [B] fails because...
   so we arrive at [THIS] as the necessary solution."]

─────────────────────────────────────────────────────────────────────────
4.5  INTERVIEW ANSWERS BY SENIORITY  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 🎓 Interview Answers by Seniority

PURPOSE:
  Ready-to-use answer templates for each level.
  Candidate picks their level, adapts to their
  experience, and delivers confidently.

FORMAT FOR EACH LEVEL:

  **[LEVEL] Answer ([N]-[N] years exp):**
  > [The answer in natural spoken English.
     Written as if the candidate is speaking.
     Includes: definition + mechanism + example
     + level-appropriate depth.
     Use "In my experience..." for mid+
     Use "I have seen..." for senior+
     Use "When I designed..." for staff]

  *What makes this answer strong:*
  [2-3 bullets explaining why this answer
   impresses at this level]

  *What to add if they push deeper:*
  [1-2 bullets on what to say if the
   interviewer follows up]

LEVELS TO COVER:
  - Junior Answer (0-2 years)
  - Mid-Level Answer (2-5 years)
  - Senior Answer (5-8 years)
  - Staff Answer (8+ years)

TIME-CALIBRATED VERSIONS:
  For each seniority level, also provide time-compressed variants.
  Candidates must be able to expand OR contract depth on demand:

  30-SECOND: Definition + why it exists + one concrete example.
             No trade-offs. Crisp. Speakable.
  90-SECOND: 30-second + mechanism + the key distinction.
             One follow-up point ready if pushed.
  3-MINUTE:  90-second + trade-off vs. alternative + production story.
             One specific failure mode or diagnostic.
  5-MINUTE:  3-minute + system design touch + personal narrative.
             "The non-obvious thing I have learned is..."

  RULE: Train the 30-second version until it is fluent.
  Never skip to the 5-minute version. Expand only when invited.

─────────────────────────────────────────────────────────────────────────
4.6  QUESTIONS YOU WILL BE ASKED  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### ❓ Questions You Will Be Asked

PURPOSE:
  Exhaustive list of every interview question
  this keyword generates. Candidate reads this
  list and prepares for each one.

FORMAT:
  Grouped by question type (from Section 2).
  Each question followed by the key points
  to cover in a good answer.

  **Definition Questions:**
  - "What is [KEYWORD]?"
    → Cover: definition, why it exists, one example

  - "[Additional question]"
    → Cover: [key points]

  **Mechanism Questions:**
  - "How does [KEYWORD] work?"
    → Cover: step-by-step, failure path, diagram

  **Comparison Questions:**
  - "What's the difference between [X] and [Y]?"
    → Cover: [key distinction], [when to choose each]

  **Scenario Questions:**
  - "When would you use [KEYWORD]?"
    → Cover: [specific conditions], [counterexample]

  **Debugging Questions:**
  - "What can go wrong with [KEYWORD]?"
    → Cover: [top 3 failure modes], [how to diagnose]

  **Deep Dive Questions:**
  - "Why was [KEYWORD] designed this way?"
    → Cover: [design rationale], [alternatives considered]

RULES:
  - Minimum 2 questions per type
  - Maximum 4 questions per type
  - Questions must be REAL — phrased as interviewers
    actually ask them
  - Key points must be specific, not vague

─────────────────────────────────────────────────────────────────────────
4.7  THE ANSWER FRAMEWORK  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 🏗️ The Answer Framework

PURPOSE:
  A reusable structure for answering ANY question
  on this topic. Candidate internalises this
  framework and applies it to novel questions.

FORMAT:
  **WHAT → WHY → HOW → TRADE-OFF → EXAMPLE**

  Use this structure for every question on [KEYWORD]:

  WHAT:   [One sentence definition]
  WHY:    [The problem it solves]
  HOW:    [The mechanism — 2-3 sentences]
  TRADE:  [What you gain vs what you sacrifice]
  EXAMPLE:[Concrete production scenario]

  *Adapt the depth:*
  Junior: WHAT + WHY + EXAMPLE
  Mid:    WHAT + WHY + HOW + EXAMPLE
  Senior: All five + specific failure you've seen
  Staff:  All five + system design implications

─────────────────────────────────────────────────────────────────────────
4.8  COMPARISON TABLE  [REQUIRED if alternatives exist]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### ⚖️ How It Compares

PURPOSE:
  Answer "What's the difference between X and Y?"
  before the interviewer asks.
  Show trade-off thinking proactively.

FORMAT:
  | Option | [Dimension 1] | [Dimension 2] | Choose When |
  |---|---|---|---|
  | **[THIS]** | ... | ... | ... |
  | [Alternative A] | ... | ... | ... |
  | [Alternative B] | ... | ... | ... |

  **The deciding factor:**
  [One sentence: the single most important condition
   that determines which to choose]

  **Interview tip:**
  [How to bring up this comparison proactively
   to signal senior thinking]

─────────────────────────────────────────────────────────────────────────
4.9  PRODUCTION SCENARIOS  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 🔥 Production Scenarios

PURPOSE:
  Real scenarios to reference in interviews.
  "In my experience..." answers that demonstrate
  production depth without needing to have actually
  experienced every scenario personally.

FORMAT FOR EACH SCENARIO:

  **Scenario [N]: [Short descriptive title]**

  Situation:
  [2-3 sentences: the production context,
   the problem that surfaced]

  What happened:
  [The failure or challenge in technical detail]

  How it was diagnosed:
  ```bash
  [actual diagnostic command or tool]
  ```

  How it was resolved:
  [The fix — technical and specific]

  Interview use:
  [How to reference this scenario naturally
   in an interview answer]

RULES:
  - Minimum 2 scenarios
  - Maximum 4 scenarios
  - Must be REALISTIC — based on how systems
    actually fail in production
  - Must include a diagnostic command
  - Must be usable as "I have seen..." even
    if the candidate read it here

RCA (ROOT CAUSE ANALYSIS) ENGINE:
  For each scenario, structure the diagnosis chain:

  Symptom      → [Observable indicator: metric, log, alert]
  Hypotheses   → [Ranked by probability: H1 (most likely), H2, H3]
  Tests        → [Command or query that rules each hypothesis in/out]
  Root Cause   → [Confirmed underlying cause]
  Fix          → [The change that resolved it]
  Prevention   → [Process or config change to prevent recurrence]

STORY BANK TEMPLATE (for interview use):
  Structure each scenario as a STAR story:

  Situation: [Production context in 1-2 sentences]
  Task:      [Your specific responsibility]
  Action:    [What you/your team did — be specific]
  Result:    [Quantifiable outcome: latency reduced, errors eliminated]

  Timing: 90 seconds max unless asked to elaborate.
  First person only: "I saw...", "We diagnosed...", "I changed..."

─────────────────────────────────────────────────────────────────────────
4.10  COMMON MISTAKES CANDIDATES MAKE  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### ⚠️ Common Mistakes Candidates Make

PURPOSE:
  What NOT to say. What kills good candidates.
  Read this, remember it, avoid it.

FORMAT:
  Table with 3 columns:

  | Mistake | Why It Hurts | Say This Instead |
  |---|---|---|
  | [what candidates wrongly say/do] | [why interviewers penalise it] | [correct approach] |

RULES:
  - Minimum 4 rows
  - Maximum 7 rows
  - Mistakes must be REAL — things candidates
    actually do wrong, not obvious errors
  - "Say This Instead" must be specific and usable

RED FLAG DETECTOR:
  The following answer patterns trigger NO HIRE signals.
  They are confident, common, and wrong.
  Every entry must include a RED FLAG block:

  | Red Flag Answer | Signal It Sends | Correct Framing |
  |---|---|---|
  | [Red flag 1] | [NO HIRE signal] | [How to reframe] |

  EXAMPLES OF UNIVERSAL RED FLAGS:
    "It just works" → signals no production depth
    "It depends" [no elaboration] → signals avoidance
    "I always use X" → signals hammer/nail pattern
    "I've never seen it fail" → signals limited exposure
    "That's implementation detail" → signals dismissiveness

DANGEROUS OVER-SIMPLIFICATIONS:
  Correct-but-oversimplified answers that fail senior+ candidates:

  | Oversimplification | What It Misses | Better Answer |
  |---|---|---|

─────────────────────────────────────────────────────────────────────────
4.11  FOLLOW-UP QUESTIONS TO ASK THE INTERVIEWER  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 🗣️ Follow-Up Questions to Ask the Interviewer

PURPOSE:
  Interviews are conversations.
  Asking smart questions demonstrates depth.
  This section provides questions that
  signal senior thinking and genuine curiosity.

FORMAT:
  **When the interviewer asks about [KEYWORD],
  consider asking:**

  - "[Question 1]"
    *Why this signals depth:* [1 sentence]

  - "[Question 2]"
    *Why this signals depth:* [1 sentence]

  - "[Question 3]"
    *Why this signals depth:* [1 sentence]

RULES:
  - Minimum 3 questions
  - Maximum 5 questions
  - Questions must be genuinely interesting —
    not filler
  - Each must reveal something about the
    candidate's thinking
  - Avoid questions answerable by Google

─────────────────────────────────────────────────────────────────────────
4.12  SYSTEM DESIGN CONNECTIONS  [REQUIRED for ★★★]
       [CONDITIONAL for ★★☆ — include if concept
        appears in system design interviews]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 🏛️ System Design Connections

PURPOSE:
  Show how this concept appears in system design
  interviews — the highest-value interview type
  for senior+ roles.

FORMAT:
  **Where [KEYWORD] appears in system design:**

  [Bullet list of system design scenarios where
   this concept is relevant]

  **How to bring it up naturally:**
  [2-3 sentences: when and how to introduce
   this concept in a system design discussion]

  **Design decisions it influences:**
  [Bullet list of architectural decisions
   where this concept is a factor]

  **Example system design question where
  this appears:**
  [One specific system design question]

  *How [KEYWORD] fits the answer:*
  [2-3 sentences on where in the design
   this concept appears and what role it plays]

6-STEP SYSTEM DESIGN FRAMEWORK:
  When this concept appears in a design interview, introduce it
  at the right point using this structure:

  Step 1: CLARIFY — Ask 2-3 requirement questions
  Step 2: ESTIMATE — Back-of-envelope scale estimate
  Step 3: HIGH-LEVEL DESIGN — Boxes and arrows
  Step 4: DEEP DIVE — Introduce THIS concept here, with trade-offs
  Step 5: ALTERNATIVES — What you considered and rejected
  Step 6: EVOLUTION — How this changes at 10× scale

STAFF / PRINCIPAL THINKING:
  For L5+ roles, the system design connection must also address:
  - Cost: cloud cost, operational overhead, team ownership cost
  - Org impact: which teams are affected, who owns this decision
  - Migration: current state → desired state → rollout plan
  - Simplification: when the simpler alternative wins

LOW-LEVEL DESIGN (LLD) GUIDANCE:
  INCLUDE IF this concept appears in LLD interviews:
  - Class or interface diagram (ASCII)
  - 2-3 key design decisions to explain
    (e.g., interface vs abstract class, composition vs inheritance)
  - What invariants this design maintains

─────────────────────────────────────────────────────────────────────────
4.13  WHITEBOARD / DIAGRAM  [CONDITIONAL]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 📊 Whiteboard / Diagram

PURPOSE:
  If this concept is commonly drawn on a
  whiteboard in interviews, provide the
  canonical diagram to memorise.

INCLUDE IF:
  - Concept is frequently drawn in interviews
  - A diagram makes it significantly clearer
  - System design interviews commonly
    include this concept visually

FORMAT:
  ASCII diagram (max 59 chars wide)
  Label every component
  Show data flow with arrows
  Include the failure path if relevant

  *What to say while drawing:*
  [Script for what to say as you draw —
   thinking aloud while diagramming
   signals senior reasoning]

─────────────────────────────────────────────────────────────────────────
4.14  QUICK REFERENCE CARD  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 📌 Quick Reference Card

FORMAT (exact ASCII box):

  ┌──────────────────────────────────────────────────────────┐
  │ ONE-LINE DEF  │ [15-word max definition]                 │
  ├───────────────┼──────────────────────────────────────────┤
  │ PROBLEM       │ [what breaks without it]                 │
  ├───────────────┼──────────────────────────────────────────┤
  │ KEY INSIGHT   │ [the non-obvious truth]                  │
  ├───────────────┼──────────────────────────────────────────┤
  │ USE WHEN      │ [specific condition]                     │
  ├───────────────┼──────────────────────────────────────────┤
  │ AVOID WHEN    │ [specific condition]                     │
  ├───────────────┼──────────────────────────────────────────┤
  │ TRADE-OFF     │ [gain] vs [cost]                         │
  ├───────────────┼──────────────────────────────────────────┤
  │ VS ALTERNATIVE│ [key distinction from closest rival]     │
  ├───────────────┼──────────────────────────────────────────┤
  │ INTERVIEW TIP │ [one sentence on how to use this         │
  │               │  in an interview to signal depth]        │
  └──────────────────────────────────────────────────────────┘

─────────────────────────────────────────────────────────────────────────
4.15  LAST-MINUTE PREP  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 🚀 Last-Minute Prep

PURPOSE:
  The candidate reads this 10 minutes before
  the interview. Everything that must be
  fresh in memory. Nothing else.

FORMAT:
  **Remember these 3 things:**
  1. [Most important point about this concept]
  2. [Most common misconception to avoid]
  3. [The trade-off that signals senior thinking]

  **If you blank on the definition, say:**
  > "[Recoverable answer that buys you thinking
     time while still sounding competent]"

  **The example that always works:**
  [One concrete, relatable example that
   illustrates this concept perfectly —
   works at any seniority level]

  **One sentence that signals depth:**
  > "[Something non-obvious that separates
     candidates who truly understand this
     from those who memorised a definition]"

RECOVERY LANGUAGE TEMPLATES:
  Use when you blank, get pushed back, or hit a gap:

  "Let me think through this from first principles..."
  "I haven't seen that exact scenario, but by analogy..."
  "My best understanding is X, though I would want to verify Y."
  "Can I sketch this on the whiteboard to think it through?"
  "The trade-off I would focus on first is..."

CONFIDENCE UNDER PRESSURE:
  When the interviewer pushes back or corrects you:
    "That's a great point — let me revise my thinking. More precisely..."
    "I see the issue with my earlier answer. The correct framing is..."
  NEVER: "Oh, I knew that" (fake agreement after being corrected)
  NEVER: "It depends" without immediately explaining on what
  NEVER: Silence longer than 5 seconds without saying something

INTERVIEW DAY EXECUTION:
  - Name the question type before answering (internally)
  - Start every answer with the 30-second version
  - Clarify before answering ambiguous scenario questions
  - Pause and offer to expand: "Does that answer your question,
    or should I go deeper into [specific aspect]?"
  - End strong: "The key insight I always come back to is..."

─────────────────────────────────────────────────────────────────────────
4.16  SPOKEN ANSWER TEMPLATES  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 🗣️ Spoken Answer Templates

PURPOSE:
  Ready-to-speak templates for each question type. The candidate
  reads these aloud until fluent. They are not scripts — they are
  scaffolding that the candidate fills with their own experience.

FORMAT (one template per question type):

  **Template for TYPE 1 (Definition):**
  > "[KEYWORD] is [plain English definition]. It exists because
    [problem it solves]. A simple example is [concrete example].
    The key thing to understand is [one non-obvious insight]."

  **Template for TYPE 2 (Mechanism):**
  > "When [event happens], here is what occurs step by step:
    First, [step 1]. Then [step 2]. Then [step 3].
    The important thing is [why each step exists].
    When this goes wrong, you see [symptom] and diagnose it by [method]."

  **Template for TYPE 3 (Comparison):**
  > "[THIS] and [ALTERNATIVE] both solve [problem], but they differ in
    [key dimension]. I choose [THIS] when [specific condition].
    I choose [ALTERNATIVE] when [other condition].
    The deciding factor for me is [single most important criterion]."

  **Template for TYPE 4 (Scenario):**
  > "I would reach for [KEYWORD] in this situation because [reasoning].
    My approach would be: [step 1], [step 2], [step 3].
    The risk I would watch for is [specific failure mode].
    I would know it is working when [measurable outcome]."

  **Template for TYPE 5 (Debugging):**
  > "The most common failure I have seen with [KEYWORD] is [failure mode].
    You see it as [observable symptom]. To diagnose: [diagnostic step].
    The root cause is usually [common root cause].
    The fix is [resolution]. To prevent recurrence: [prevention]."

  **Template for TYPE 6 (Deep Dive):**
  > "[KEYWORD] was designed this way because [design rationale].
    The trade-off that decision created is [trade-off].
    Its fundamental limitation is [limitation] — which matters at scale because [why].
    If I were redesigning it, I would [what you would change] because [reasoning]."

INTERVIEWER TYPE ADAPTATION:
  Adapt tone and emphasis based on interviewer behaviour:

  TECHNICAL PANEL (senior engineers):
    Lead with mechanism. Use precise terminology. Show failure awareness.
    Offer to go deeper: "I can go into [specific mechanism] if useful."

  HIRING MANAGER:
    Lead with business impact. Use outcome language.
    "This reduced our deployment time by..." / "This eliminated the class of..."

  BAR RAISER:
    Lead with trade-offs and what you would not use this for.
    Signal intellectual honesty: "The limitation I would flag is..."

  PEER ENGINEER (same level):
    Use collaborative language. Show curiosity.
    "The thing I keep finding is..." / "Have you seen the same pattern with...?"

─────────────────────────────────────────────────────────────────────────
4.17  ELITE LEARNING LOOP  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 🔄 Elite Learning Loop

PURPOSE:
  A 8-step practice system that converts reading this entry into
  interview-fluent retrieval. Deliberate practice beats passive review.

THE 8-STEP CYCLE:
  Step 1: READ     — Read the entry once. Note gaps in your knowledge.
  Step 2: RECALL   — Close the entry. Write down everything you remember.
  Step 3: COMPARE  — Open the entry. Identify gaps between recall and content.
  Step 4: EXPLAIN  — Explain the concept aloud to yourself (rubber duck).
  Step 5: DIAGRAM  — Draw the mechanism from memory on paper.
  Step 6: APPLY    — Find one instance of this in a past/current project.
  Step 7: MOCK     — Answer "What is X?" and "What can go wrong with X?"
             aloud, timed (30 seconds for junior answer, 3 minutes for senior).
  Step 8: TEACH    — Explain it to someone else (or record yourself).
           Gaps in your explanation reveal gaps in your understanding.

WEAKNESS → STRENGTH PROGRESSION:
  WEAK   (cannot define without notes)   → Do Steps 1-3 three times.
  OKAY   (can define, cannot explain)    → Do Steps 4-5 until fluent.
  SOLID  (can explain, no examples)      → Do Step 6 until story is ready.
  STRONG (example ready, no trade-offs)  → Do Step 7 for senior answer.
  ELITE  (trade-offs ready, no fluency)  → Do Step 8 with another person.

TECHNICAL FLUENCY PRACTICE:
  Explain this concept at 4 levels, timed:
    To a junior engineer:  [2 min] — no jargon, use analogy
    To a product manager:  [1 min] — business outcome only
    To a senior engineer:  [3 min] — trade-offs and failure modes
    To a staff engineer:   [5 min] — system implications and history

  A concept you can explain at all 4 levels is interview-ready.

─────────────────────────────────────────────────────────────────────────
4.18  DELIBERATE RECALL SCHEDULE  [REQUIRED]
─────────────────────────────────────────────────────────────────────────

Section header:
  ### 📅 Deliberate Recall Schedule

PURPOSE:
  Spaced repetition schedule for this concept. Do not re-read
  the entry. Answer the recall questions from memory.
  Struggle is the point — it strengthens retrieval.

RECALL SCHEDULE (answer 5 questions each session, no notes):

  Day 1  (same day):
    - What is [KEYWORD] in one sentence?
    - What problem does it solve?
    - How does it work at a high level?
    - What is the key trade-off?
    - What is one failure mode?

  Day 3  (two days later):
    - Explain the mechanism step by step.
    - When would you NOT use [KEYWORD]?
    - What is the closest alternative and the deciding factor?
    - Describe one production failure scenario.
    - What question would a staff engineer ask that you should be ready for?

  Day 7  (one week):
    - Explain [KEYWORD] to a junior engineer (2 min, out loud).
    - What is the system design scenario where this appears?
    - Name 3 interview red flags for this topic.
    - What is the non-obvious insight that separates good from great answers?
    - Give your 90-second senior answer, start to finish.

  Day 14 (two weeks):
    - Draw the mechanism diagram from memory.
    - Give your 3-minute senior answer with a production story.
    - What would a bar raiser ask about [KEYWORD]?
    - What is the first-principles derivation?

  Day 30 (one month):
    - Give the full 5-minute staff answer, unprompted.
    - What are the limitations of [KEYWORD] at 10× scale?
    - Compare this to [NEAREST ALTERNATIVE] in 90 seconds.
    - What has changed about this concept in the last 2-3 years?

  Day 60 (two months — mastery check):
    - Teach this concept to another engineer (15 min).
    - Answer all 6 question types from memory without preparation.
    - Rate your confidence on each interviewer signal (1-5):
        🧠 Technical Depth, 🏭 Production Experience,
        ⚖️ Trade-off Thinking, 💬 Communication Clarity,
        🎯 Engineering Judgment

RETRIEVAL UNDER PRESSURE DRILLS:
  Set a 2-minute timer. Answer one question below with no notes.
  Simulate interview stress: speak aloud, sit upright.
  Questions (rotate per session):
    - "Tell me about a time [KEYWORD] caused you a production problem."
    - "I prefer [ALTERNATIVE]. Why would you use [KEYWORD] instead?"
    - "Explain [KEYWORD] assuming I have never heard of it."
    - "What would you change about [KEYWORD] if you designed it?"
    - "How does [KEYWORD] behave at 100× your current scale?"

═══════════════════════════════════════════════════════════════════════════
SECTION 5: YAML FRONTMATTER — FIELD RULES
═══════════════════════════════════════════════════════════════════════════

id:
  Format: [CODE]-[NNN]
  Same ID system as master dictionary

title:
  Exact keyword name

category:
  Full category name from registry

difficulty:
  ★☆☆  Foundational — asked at all levels
  ★★☆  Intermediate — asked at mid+
  ★★★  Deep-dive — asked at senior+

interview_weight:
  critical  — appears in almost every interview
              for roles that use this technology
              Example: JVM for Java roles
  high      — frequently asked, should know well
              Example: GC tuning for senior Java
  medium    — commonly asked at specific levels
              Example: CMS GC for senior Java
  low       — occasionally asked, nice to know
              Example: Shenandoah for specialist roles

asked_at:
  FAANG      — common at Google, Meta, Amazon, etc.
  Mid-size   — common at scale-ups, Series B+
  Startup    — common at early-stage companies
  All        — universal across company types

seniority:
  junior   — asked specifically for junior roles
  mid      — asked for mid-level roles
  senior   — asked for senior roles
  staff    — asked for staff/principal roles
  all      — asked at every seniority level

tags:
  From approved taxonomy — same as master dictionary
  Add interview-specific tags:
  #interview-critical #system-design #behavioral
  #coding #debugging #architecture #java-interview
  #distributed-interview #database-interview

═══════════════════════════════════════════════════════════════════════════
SECTION 6: CONTENT QUALITY RULES
═══════════════════════════════════════════════════════════════════════════

─────────────────────────────────────────────────────────────────────────
THE INTERVIEW REALITY TEST:
─────────────────────────────────────────────────────────────────────────

  Before finalising every entry, ask:

  ☐ Can a candidate READ this entry and then
    SPEAK an impressive answer without re-reading?

  ☐ Are the sample answers SPEAKABLE — do they
    sound natural when said aloud?

  ☐ Does the seniority calibration section give
    DISTINCT answers for each level?
    (Not just "add more detail for senior")

  ☐ Are the production scenarios BELIEVABLE —
    could they plausibly have happened to the candidate?

  ☐ Are the mistakes section items things
    REAL candidates actually do wrong?

  ☐ Does the system design connection show WHERE
    specifically this concept appears in a design?

  ☐ Is the Last-Minute Prep section genuinely
    the 3 things most worth remembering?

─────────────────────────────────────────────────────────────────────────
LANGUAGE RULES:
─────────────────────────────────────────────────────────────────────────

  Sample answers must be:
    - Written in FIRST PERSON ("I", "we", "my team")
    - Spoken English, not written English
    - Specific ("we saw 200ms GC pauses")
      not vague ("there were performance issues")
    - Honest about limits
      ("I haven't used X but I understand...")

  Avoid in sample answers:
    - "It is worth noting that..."
    - "One must consider..."
    - "The concept of X refers to..."
    - Any passive voice

─────────────────────────────────────────────────────────────────────────
DEPTH CALIBRATION:
─────────────────────────────────────────────────────────────────────────

  ★☆☆ Foundational:
    30-second answer: always correct and crisp
    Junior + Mid answers: fully written out
    Senior + Staff: brief notes sufficient
    Production scenarios: 2 simple ones
    Questions: focus on Type 1, 2, 3

  ★★☆ Intermediate:
    All four seniority answers: fully written
    Production scenarios: 2-3 realistic ones
    System design: brief connection
    Questions: all 6 types covered

  ★★★ Deep-dive:
    All four seniority answers: fully written
    Production scenarios: 3-4 detailed ones
    System design: full section required
    Whiteboard diagram: include if visual
    Questions: all 6 types, 3+ each

─────────────────────────────────────────────────────────────────────────
SELF-VALIDATION CHECKLIST (15 items):
─────────────────────────────────────────────────────────────────────────

  Run this before marking any entry complete:

  ☐ 4.1   YAML frontmatter complete and valid. Status = draft, version correct.
  ☐ 4.2   30-second answer speakable without jargon. Blockquote format.
  ☐ 4.3   Seniority signal table present. Roles that ask this stated.
  ☐ 4.4   Concept explanation covers: WHAT / PROBLEM / HOW / KEY INSIGHT /
            WHEN TO USE / WHEN NOT TO USE / ALTERNATIVES / FIRST PRINCIPLES.
  ☐ 4.5   Four seniority answers written in first person, spoken English.
            Time-calibrated versions (30s/90s/3min/5min) noted.
  ☐ 4.6   At least 2 questions per type (Types 1-6) with key points.
  ☐ 4.7   Answer framework WHAT→WHY→HOW→TRADE-OFF→EXAMPLE present.
  ☐ 4.8   Comparison table present (if alternatives exist).
            Deciding factor stated in one sentence.
  ☐ 4.9   At least 2 production scenarios. Each has diagnostic command.
            RCA chain and STAR story template provided.
  ☐ 4.10  At least 4 mistakes in table. Red Flag Detector block present.
            Dangerous Over-Simplifications block present.
  ☐ 4.11  At least 3 follow-up questions with depth signal explanations.
  ☐ 4.12  System design connection present (required for ★★★).
            6-step framework applied. Staff/Principal thinking block present.
  ☐ 4.14  Quick Reference Card in exact ASCII box format.
  ☐ 4.15  Last-Minute Prep has 3 things, recovery language, and interview
            day execution notes.
  ☐ 4.16  Spoken Answer Templates for all 6 question types present.
            Interviewer type adaptation table present.
  ☐ 4.17  Elite Learning Loop 8-step cycle present.
            Weakness→Strength progression table present.
  ☐ 4.18  Deliberate Recall Schedule Day 1/3/7/14/30/60 present.
            Retrieval Under Pressure drills present.

INTERVIEWER EVALUATION RUBRIC (7 dimensions, 1-10):
─────────────────────────────────────────────────────────────────────────

  Any reviewer (human or LLM) can score this entry on 7 dimensions:

  D1 — DEPTH (1-10):
    1 = Only definition. No mechanism, no failures.
    10 = Complete internals, failure modes, at-scale behaviour.

  D2 — PRODUCTION REALISM (1-10):
    1 = Academic. No real failure scenarios.
    10 = 3+ realistic scenarios with diagnostic commands and root causes.

  D3 — TRADE-OFF COVERAGE (1-10):
    1 = No alternatives mentioned. "X is always best."
    10 = 3+ alternatives compared. Deciding factor clear. Anti-patterns listed.

  D4 — SENIORITY CALIBRATION (1-10):
    1 = One-size-fits-all answer.
    10 = Distinct answers for all 4 levels, plus time-calibrated versions.

  D5 — COMMUNICATION QUALITY (1-10):
    1 = Written English. Passive voice. Cannot be spoken.
    10 = First person. Active voice. Speakable at every level.

  D6 — PRACTICE INTEGRATION (1-10):
    1 = No practice guidance.
    10 = 8-step learning loop + recall schedule + pressure drills present.

  D7 — INTERVIEW SIGNAL COVERAGE (1-10):
    1 = Covers only 🧠 depth signal.
    10 = All 5 signals (🧠/🏭/⚖️/💬/🎯) explicitly trained across sections.

  SCORING:
  Total = D1+D2+D3+D4+D5+D6+D7 (max 70)
  PASS:        >= 49 (avg 7.0)
  PUBLICATION: >= 56 (avg 8.0)
  ELITE:       >= 63 (avg 9.0)

FINAL QUALITY BAR:
─────────────────────────────────────────────────────────────────────────

  An entry PASSES if:
    - Self-validation checklist: all 18 items checked
    - Evaluator rubric score: >= 49
    - All five interviewer signals represented in Section 4.5
    - No invented facts, API names, benchmarks, or incident details
    - All sample answers pass the SPEAK TEST:
      "Could a real candidate say this in a real interview?"

  Do not set status: complete unless ALL bars are met.

═══════════════════════════════════════════════════════════════════════════
SECTION 7: COMPLETE ENTRY SKELETON
═══════════════════════════════════════════════════════════════════════════

---
id: [CODE]-[NNN]
title: [Keyword Name]
category: [Category Name]
difficulty: [★☆☆ | ★★☆ | ★★★]
interview_weight: [low | medium | high | critical]
asked_at: [FAANG | Mid-size | Startup | All]
seniority: [junior | mid | senior | staff | all]
tags: #tag1, #tag2, #tag3
status: draft
version: 0
---

# [ICON] [ID] — [KEYWORD NAME]

🎯 Interview Weight: [WEIGHT] — [one sentence]

---

### ⚡ The 30-Second Answer

> [3-4 sentences. Speakable. No jargon.
>  What + Why + Example + Key Insight.]

---

### 🎯 Why Interviewers Ask This

**What they are really testing:**
- [underlying skill 1]
- [underlying skill 2]
- [underlying skill 3]

**Roles that ask this most:**
[Backend / Frontend / All / etc.]

**Seniority signal:**

| Answer Quality | Seniority Signal |
|---|---|
| Defines it correctly | Junior |
| Explains mechanism + example | Mid-level |
| Trade-offs + failure mode | Senior |
| System design + org impact | Staff |

---

### 📘 Concept Explanation

**What it is:**
[1-2 sentences]

**The problem it solves:**
[2-3 sentences]

**How it works:**
[Step-by-step + diagram if helpful]

**The key insight:**
[1-2 sentences — the non-obvious truth]

---

### 🎓 Interview Answers by Seniority

**Junior Answer (0-2 years):**
> [Spoken answer in first person]

*What makes this answer strong:*
- [point 1]
- [point 2]

*What to add if they push deeper:*
- [follow-up point]

---

**Mid-Level Answer (2-5 years):**
> [Spoken answer in first person]

*What makes this answer strong:*
- [point 1]
- [point 2]

*What to add if they push deeper:*
- [follow-up point]

---

**Senior Answer (5-8 years):**
> [Spoken answer in first person]

*What makes this answer strong:*
- [point 1]
- [point 2]

*What to add if they push deeper:*
- [follow-up point]

---

**Staff Answer (8+ years):**
> [Spoken answer in first person]

*What makes this answer strong:*
- [point 1]
- [point 2]

*What to add if they push deeper:*
- [follow-up point]

---

### ❓ Questions You Will Be Asked

**Definition Questions:**
- "[Question]"
  → Cover: [key points]

**Mechanism Questions:**
- "[Question]"
  → Cover: [key points]

**Comparison Questions:**
- "[Question]"
  → Cover: [key points]

**Scenario Questions:**
- "[Question]"
  → Cover: [key points]

**Debugging Questions:**
- "[Question]"
  → Cover: [key points]

**Deep Dive Questions:**
- "[Question]"
  → Cover: [key points]

---

### 🏗️ The Answer Framework

**WHAT → WHY → HOW → TRADE-OFF → EXAMPLE**

WHAT:   [definition]
WHY:    [problem solved]
HOW:    [mechanism]
TRADE:  [gain vs cost]
EXAMPLE:[concrete scenario]

*Adapt the depth:*
Junior: WHAT + WHY + EXAMPLE
Mid:    WHAT + WHY + HOW + EXAMPLE
Senior: All five + failure mode
Staff:  All five + system design

---

### ⚖️ How It Compares

| Option | [Dimension 1] | [Dimension 2] | Choose When |
|---|---|---|---|
| **[THIS]** | ... | ... | ... |
| [Alternative A] | ... | ... | ... |
| [Alternative B] | ... | ... | ... |

**The deciding factor:**
[One sentence]

**Interview tip:**
[How to bring up comparison proactively]

---

### 🔥 Production Scenarios

**Scenario 1: [Title]**

Situation:
[2-3 sentences]

What happened:
[Technical detail]

How it was diagnosed:
```bash
[diagnostic command]
```

How it was resolved:
[The fix]

Interview use:
[How to reference naturally]

---

### ⚠️ Common Mistakes Candidates Make

| Mistake | Why It Hurts | Say This Instead |
|---|---|---|
| [mistake] | [why penalised] | [correct approach] |
| [mistake] | [why penalised] | [correct approach] |
| [mistake] | [why penalised] | [correct approach] |
| [mistake] | [why penalised] | [correct approach] |

---

### 🗣️ Follow-Up Questions to Ask the Interviewer

- "[Question 1]"
  *Why this signals depth:* [1 sentence]

- "[Question 2]"
  *Why this signals depth:* [1 sentence]

- "[Question 3]"
  *Why this signals depth:* [1 sentence]

---

### 🏛️ System Design Connections
[Include for ★★★, include for ★★☆ if relevant]

**Where [KEYWORD] appears in system design:**
- [scenario 1]
- [scenario 2]

**How to bring it up naturally:**
[2-3 sentences]

**Design decisions it influences:**
- [decision 1]
- [decision 2]

**Example system design question:**
[Specific question]

*How [KEYWORD] fits the answer:*
[2-3 sentences]

---

### 📊 Whiteboard / Diagram
[Include if commonly drawn in interviews]

```
┌─────────────────────────────────────────────────────────┐
│  [DIAGRAM TITLE]                                        │
│                                                         │
│  [ASCII diagram — max 57 chars content width]           │
└─────────────────────────────────────────────────────────┘
```

*What to say while drawing:*
[Speaking script]

---

### 📌 Quick Reference Card

┌──────────────────────────────────────────────────────────┐
│ ONE-LINE DEF  │ [15-word max]                            │
├───────────────┼──────────────────────────────────────────┤
│ PROBLEM       │ [what breaks without it]                 │
├───────────────┼──────────────────────────────────────────┤
│ KEY INSIGHT   │ [non-obvious truth]                      │
├───────────────┼──────────────────────────────────────────┤
│ USE WHEN      │ [specific condition]                     │
├───────────────┼──────────────────────────────────────────┤
│ AVOID WHEN    │ [specific condition]                     │
├───────────────┼──────────────────────────────────────────┤
│ TRADE-OFF     │ [gain] vs [cost]                         │
├───────────────┼──────────────────────────────────────────┤
│ VS ALTERNATIVE│ [key distinction]                        │
├───────────────┼──────────────────────────────────────────┤
│ INTERVIEW TIP │ [one sentence on signalling depth]       │
└──────────────────────────────────────────────────────────┘

---

### 🚀 Last-Minute Prep

**Remember these 3 things:**
1. [Most important point]
2. [Most common misconception to avoid]
3. [Trade-off that signals senior thinking]

**If you blank on the definition, say:**
> "[Recoverable answer]"

**The example that always works:**
[One concrete, relatable example]

**One sentence that signals depth:**
> "[Non-obvious insight]"

---

### 🗣️ Spoken Answer Templates

**Template for TYPE 1 (Definition):**
> "[KEYWORD] is [definition]. It exists because [problem].
  A simple example is [example]. The key thing is [insight]."

**Template for TYPE 2 (Mechanism):**
> "When [event], here is what happens step by step: [steps].
  When this goes wrong, you see [symptom] and diagnose it by [method]."

**Template for TYPE 3 (Comparison):**
> "Both solve [problem], but differ in [key dimension].
  I choose [THIS] when [condition]. [ALTERNATIVE] when [other condition]."

**Template for TYPE 4 (Scenario):**
> "I would reach for [KEYWORD] here because [reasoning].
  My approach: [steps]. Watch for [failure mode]. Success = [outcome]."

**Template for TYPE 5 (Debugging):**
> "Most common failure: [failure]. Symptom: [observable].
  Diagnose: [command/step]. Root cause: [cause]. Fix: [resolution]."

**Template for TYPE 6 (Deep Dive):**
> "Designed this way because [rationale]. Trade-off: [trade-off].
  Limitation: [limitation]. At scale: [scale behaviour]."

---

### 🔄 Elite Learning Loop

**The 8-Step Cycle:** READ → RECALL → COMPARE → EXPLAIN → DIAGRAM → APPLY → MOCK → TEACH

**Weakness → Strength progression:**
- WEAK (cannot define):   Do Steps 1-3 three times.
- OKAY (can define):      Do Steps 4-5 until fluent.
- SOLID (can explain):    Do Step 6 until story ready.
- STRONG (story ready):   Do Step 7 for senior answer.
- ELITE (trade-offs):     Do Step 8 with another person.

**Technical Fluency:** Explain this concept to: junior engineer (2 min) / PM (1 min) / senior (3 min) / staff (5 min).

---

### 📅 Deliberate Recall Schedule

**Day 1:**  What is it? What problem? How does it work? Key trade-off? One failure mode?
**Day 3:**  Mechanism step-by-step. When NOT to use? Closest alternative? Production failure story.
**Day 7:**  Explain to junior (2 min aloud). System design scenario. 3 interview red flags.
**Day 14:** Draw mechanism from memory. 3-minute senior answer with story. Bar-raiser question.
**Day 30:** Full 5-minute staff answer unprompted. Limitations at 10× scale. Compare to alternative.
**Day 60:** Teach to another engineer (15 min). Answer all 6 question types cold. Rate all 5 signals 1-5.

**Pressure Drill:** Set 2-minute timer. Speak aloud. Rotate per session:
- "Tell me about a time [KEYWORD] caused a production problem."
- "I prefer [ALTERNATIVE]. Why would you use [KEYWORD] instead?"
- "Explain [KEYWORD] assuming I have never heard of it."
- "What would you change about [KEYWORD] if you designed it?"
- "How does [KEYWORD] behave at 100× your current scale?"

═══════════════════════════════════════════════════════════════════════════
SECTION 8: INVOCATION — HOW TO USE
═══════════════════════════════════════════════════════════════════════════

─────────────────────────────────────────────────────────────────────────
SINGLE ENTRY:
─────────────────────────────────────────────────────────────────────────

  Generate technical interview entry for:

    ID:               JVM-036
    Keyword:          JIT Compiler
    Category:         Java & JVM Internals
    Difficulty:       ★★★
    Interview Weight: high
    Asked At:         FAANG, Mid-size
    Seniority:        senior, staff

  Follow Technical Interview Dictionary
  Generator prompt exactly.
  Use complete skeleton from Section 7.
  Do not skip any required section.

─────────────────────────────────────────────────────────────────────────
BATCH (5 entries):
─────────────────────────────────────────────────────────────────────────

  Generate technical interview entries:

  | ID      | Keyword          | Difficulty | Weight   |
  |---------|------------------|------------|----------|
  | JVM-036 | JIT Compiler     | ★★★        | high     |
  | JVM-037 | C1/C2 Compiler   | ★★★        | medium   |
  | JVM-038 | Tiered Compilation| ★★★       | medium   |
  | JVM-039 | Method Inlining  | ★★★        | high     |
  | JVM-040 | Deoptimization   | ★★★        | medium   |

  Category: Java & JVM Internals
  Seniority focus: senior, staff

  Follow Technical Interview Dictionary
  Generator prompt exactly.
  Separate entries with: ---FILE_BREAK---

─────────────────────────────────────────────────────────────────────────
ROLE-SPECIFIC FOCUS:
─────────────────────────────────────────────────────────────────────────

  Generate technical interview entry for:

    Keyword:   GC Tuning
    Role:      Senior Java Backend Engineer
    Company:   FAANG
    Focus:     Emphasise system design connections
               and production scenarios heavily.
               This role values production depth
               over theoretical knowledge.

  Follow Technical Interview Dictionary
  Generator prompt exactly.

─────────────────────────────────────────────────────────────────────────
SELF-VALIDATION CHECKLIST:
─────────────────────────────────────────────────────────────────────────

  Before finalising each entry verify:

  CONTENT:
  ☐ 30-second answer is speakable, 3-4 sentences
  ☐ All 4 seniority answers are distinct
  ☐ Each seniority answer is in first person
  ☐ Minimum 6 question types covered
  ☐ Minimum 2 questions per type
  ☐ Minimum 2 production scenarios
  ☐ Each scenario has diagnostic command
  ☐ Mistakes table: minimum 4 rows, 3 columns
  ☐ Follow-up questions: minimum 3
  ☐ Last-Minute Prep: exactly 3 points

  QUALITY:
  ☐ Sample answers sound natural spoken aloud
  ☐ Production scenarios are believable
  ☐ Mistakes are things candidates actually do
  ☐ System design connection is specific
  ☐ Quick Reference Card: all 8 rows present

  FORMAT:
  ☐ YAML: all 9 fields present
  ☐ No H2 headers in entry body
  ☐ Diagrams: max 59 chars wide
  ☐ Comparison table: max 4 columns
  ☐ Blockquotes: 30-second answer
                 + all seniority answers
                 + blank recovery line
                 + depth signal line

═══════════════════════════════════════════════════════════════════════════
END OF TECHNICAL INTERVIEW DICTIONARY GENERATOR v1.0
═══════════════════════════════════════════════════════════════════════════
````
