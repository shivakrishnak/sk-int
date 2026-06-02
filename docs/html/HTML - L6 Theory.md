---
layout: default
title: "HTML - L6 Theory"
parent: "HTML"
nav_order: 13
permalink: /html/l6-theory/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [HTML Living Standard and WHATWG Parsing Algorithm](#html-living-standard-and-whatwg-parsing-algorithm) | specialist |
| 2 | [HTML Specification History and Browser Divergence](#html-specification-history-and-browser-divergence) | specialist |

---

# HTML Living Standard and WHATWG Parsing Algorithm

🎯 **Interview Weight:** specialist (★★☆) - theory-level knowledge
for senior/staff engineers who need to understand why browsers
behave the way they do at the specification level

---

### 🎯 Model Answer

**30 seconds:**

> The WHATWG HTML Living Standard defines the tokenization and
> tree-construction algorithm browsers use to parse HTML. The parser
> is deliberately error-tolerant: it defines exactly what to do with
> malformed HTML (unclosed tags, wrong nesting, omitted elements).
> This means `<p><b>text</p>` parses identically in all browsers.
> The parser has multiple states (data state, tag open state, etc.)
> and transitions between them based on input characters.

**3 minutes (Senior):**

> The HTML parsing algorithm has two phases:
>
> 1. **Tokenization**: reads the byte stream character-by-character
>    and emits tokens (DOCTYPE token, start tag token, end tag token,
>    comment token, character token, end-of-file token). The tokenizer
>    is a state machine with 80 states.
>
> 2. **Tree construction**: receives tokens and builds the DOM tree.
>    Maintains a "stack of open elements" (similar to a parse stack)
>    and uses "insertion modes" (initial, before html, in head, in body,
>    in table, etc.) to handle nesting rules.
>
> Error handling is defined: the spec specifies exactly what to do
> with every error condition. This is why all browsers produce the
> same DOM from the same malformed HTML. Before the spec defined
> error handling, each browser had different behavior (the IE/Firefox/Opera
> divergence era).
>
> The script execution pause: when the tree construction encounters
> a non-deferred script, it gives the script to the scripting engine,
> pauses tokenization, runs the script, then resumes. This is the
> specification basis for "parser-blocking JavaScript."

**Blank Mind Recovery:**

**(1) Restate:** "HTML parser = tokenizer (byte stream → tokens)
+ tree builder (tokens → DOM). Error handling is defined in spec,
producing consistent behavior across browsers."

**(2) First principles:** "The browser receives bytes over the network.
It must turn those bytes into a tree of objects. The spec defines
every step of this process, including what to do when the HTML is wrong."

---

### 📘 Concept Explanation

**What it is:**

The WHATWG HTML parsing algorithm is the specification that all
browser HTML parsers implement. It defines a tokenization state
machine and a tree construction algorithm that deterministically
produces a DOM tree from any sequence of bytes.

**The problem it solves:**

Before the HTML parsing spec was formalized, each browser implemented
its own error recovery behavior. The same broken HTML produced
different DOMs in IE, Firefox, and Opera. This was catastrophic for
web development: a page that worked in one browser broke in another
not because of CSS or JavaScript differences, but because the browsers
built different DOM trees from the same HTML. The spec defines
error handling explicitly, creating identical parse results.

**How it works:**

```
HTML PARSING PIPELINE:

  Network bytes
    |
    v
  [PREPROCESSING]
  Byte order mark detection → character encoding determination
  BOM: UTF-8 (0xEF 0xBB 0xBF), UTF-16 LE/BE
  <meta charset="UTF-8"> → updates encoding mid-parse
  Content-Type: text/html; charset=utf-8 → initial encoding

    |
    v
  [TOKENIZER - State Machine]

  80 states define what to do for each input character.
  Key states:

  Data state:
    '<' → switch to Tag open state
    '&' → switch to Character reference state
    EOF → emit end-of-file token
    else → emit current character as character token

  Tag open state (after '<'):
    '/' → switch to End tag open state
    letter → start new tag, switch to Tag name state
    '!' → switch to Markup declaration open state
    '?' → parse error, switch to Bogus comment state
    else → parse error, emit '<', reconsume in Data state

  Tag name state (inside a tag name):
    space/newline/tab → switch to Before attribute name state
    '/' → switch to Self-closing start tag state
    '>' → emit current tag token, switch to Data state
    letter → append to tag name
    else → append to tag name (error recovery)

  String attribute state:
    (reading attribute value in quotes):
    '"' → end of value, switch to After attribute value state
    '&' → character reference
    else → append to attribute value

  Emitted token types:
    DOCTYPE: <!DOCTYPE html>
    Start tag: <div class="foo">
    End tag: </div>
    Comment: <!-- text -->
    Character: any text content
    End-of-file

  [TREE CONSTRUCTION - Insertion Modes]

  Maintains:
    - Stack of open elements
    - List of active formatting elements
    - Current insertion mode

  Insertion modes (simplified):
    "initial"      → expect DOCTYPE
    "before html"  → expect <html>
    "before head"  → expect <head>
    "in head"      → process head elements
    "after head"   → expect <body>
    "in body"      → process body content (most complex)
    "in table"     → inside a <table> element
    "text"         → processing script or style content
    ...more for frameset, foreign content (SVG/MathML)

  Key "in body" rules:
    Start tag <p>:
      if current open <p> exists: close it first
      then open new <p>
      (implicit closing: <p><p> → first </p> auto-generated)

    Start tag <li>:
      if current open <li> exists: close it first
      (list nesting handled by spec, not by author)

    End tag </b> when not currently in <b>:
      parse error: no-op (silently ignored)

  Error recovery example - unclosed tags:
    Input: <p>Hello <b>world
    Tokens: [p], [b], "Hello ", "world", EOF

    Tree construction:
      Open <p>
        Open <b>
          Insert "Hello "
          Insert "world"
        EOF encountered:
          Stack: [html, body, p, b]
          Spec: close elements in order: </b>, </p>
          → <b>Hello world</b> (text content in b)
      Result DOM:
        <html><body>
          <p><b>Hello world</b></p>
        </body></html>

    EVERY browser produces this identical DOM.

  The Adoption Agency Algorithm (complex formatting):
    Handles nested formatting like:
    <b>text1 <i>text2</b> text3</i>
    (b and i are not properly nested)

    Algorithm produces:
    <b>text1 <i>text2</i></b><i> text3</i>
    (browsers reconstruct proper nesting)

SCRIPT EXECUTION INTERACTION WITH PARSER:
  When tokenizer encounters <script> (no defer/async):
    1. Tokenizer pauses
    2. Tree construction runs (to get the DOM ready)
    3. Script is fetched (if external)
    4. Scripting engine runs the script
    5. Script may call document.write():
       document.write("<p>Dynamic content</p>")
       → This inserts tokens back into the tokenizer
       → Tokenizer continues from the inserted text
    6. Tokenizer resumes with original HTML

  Why document.write works (and why it's evil):
    Spec allows inserting tokens during script execution.
    This is the "dynamic markup insertion" feature.
    Calling document.write after the page is loaded
    (in a DOMContentLoaded handler) CLEARS THE ENTIRE PAGE
    and writes from scratch. This is a spec-defined behavior
    that breaks pages when CDN-injected scripts call it.

FOREIGN CONTENT (SVG and MathML):
  The HTML parser understands when to switch to
  SVG or MathML parsing modes:
    <svg> → switches to SVG insertion mode
      (SVG is case-sensitive: <rect> not <RECT>)
    </svg> → switches back to HTML insertion mode
    <math> → switches to MathML insertion mode

  Integration is specified in the HTML spec itself,
  not in SVG or MathML specs - showing the Living Standard
  approach of defining interoperability explicitly.
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice using SQL. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**

The parsing algorithm is not a "try to parse valid HTML" algorithm.
It is an "accept any bytes and produce a predictable DOM" algorithm.
Every error has a defined recovery. This makes the web robust:
billions of pages with minor markup errors still work because
the spec tells browsers exactly how to recover.

**When to use it:**

Understanding the parsing algorithm helps diagnose:
- Why your HTML renders differently than you expected
- Why `document.write` is dangerous in async contexts
- Why `<p><div></div></p>` produces `<p></p><div></div><p></p>`
- Why self-closing tags like `<p />` don't work in HTML

---

### 💻 Code Example

**Observing parser error recovery**

```html
<!-- BAD HTML: div inside p (block inside inline) -->
<!-- Authors should never write this: -->
<p>Start <div>Block element</div> end</p>

<!-- RESULT (what browsers actually create in the DOM): -->
<!--
  <p>Start </p>
  <div>Block element</div>
  <p> end</p>

  Reason: spec says <div> CANNOT be inside <p>
  When tokenizer encounters <div> while in <p>:
  → implicit close of <p> (</p> synthesized)
  → open <div>
  → when </div> is encountered: close div
  → spec: if there was an open <p> before the block,
    reopen <p> after the block
  → the " end" text goes into the new <p>
-->

<!-- VERIFY: paste this into browser console: -->
<!--
const div = document.createElement('div');
div.innerHTML = '<p>Start <div>Block element</div> end</p>';
console.log(div.innerHTML);
// Logs: <p>Start </p><div>Block element</div><p> end</p>
-->
```

> **Code walkthrough:** BAD pattern: This Unknown example demonstrates a key concept in practice using authentication. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **WHAT BREAKS: understand the execution model before using this pattern in production code.**

```javascript
// Observing tokenizer states via the HTML spec's test suite
// (For educational purposes - spec test vectors)

// Test: unclosed formatting element
const html1 = '<b><i>text';
const div1 = document.createElement('div');
div1.innerHTML = html1;
console.log(div1.innerHTML);
// Output: <b><i>text</i></b>
// Reason: EOF closes all open elements in reverse stack order

// Test: misnested formatting
const html2 = '<b>bold<i>both</b>italic</i>';
const div2 = document.createElement('div');
div2.innerHTML = html2;
console.log(div2.innerHTML);
// Output: <b>bold<i>both</i></b><i>italic</i>
// Reason: Adoption Agency Algorithm reconstructs nesting
```

> **Code walkthrough:** The first example shows the spec's ruleice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> about block elements inside paragraph elements. The `<p>` element
> has an optional end tag - the spec defines it as "implicitly
> closeable" when certain block-level elements are opened. Crucially,
> this behavior is not browser-specific: the spec mandates it,
> so every browser produces the same three-paragraph DOM. The second
> example shows the Adoption Agency Algorithm for misnested formatting
> elements - a rule that's complex enough to have its own name in
> the spec, revealing the lengths HTML goes to for error recovery.

---

### ⚖️ Comparison Table

| Parsing Phase | Input | Output | Key Algorithm |
|---|---|---|---|
| Tokenization | Byte stream | Token stream | State machine (80 states) |
| Tree Construction | Token stream | DOM tree | Insertion modes + stack |
| Error Recovery | Invalid tokens | Best-guess DOM | Defined in spec per error |

| Spec Concept | What it Does | Why It Matters |
|---|---|---|
| Optional end tags | Some elements auto-close | Explains implicit </p> behavior |
| Adoption Agency Alg | Fixes misnested formatting | Consistent cross-browser DOM |
| Script pause | Stops tokenizer for scripts | Parser-blocking JavaScript |
| Scripting enabled flag | Controls if scripts run | Bots: scripting may be disabled |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> HTML is parsed by a state machine that handles errors by design.
> All browsers produce the same DOM from the same HTML (even malformed HTML)
> because the error recovery is specified. The parser pauses for
> `<script>` tags (parser-blocking) and creates the DOM incrementally
> (streaming parse). `document.write()` works by inserting text
> into the parser mid-execution.

---

**Senior / Staff:**

> The parsing algorithm's error recovery rules explain many "why
> does my HTML render differently than expected" issues. `<div>`
> inside `<p>` produces 3 paragraphs (not 1). `<p />` is not
> self-closing in HTML (only in XML/SVG). The Adoption Agency
> Algorithm handles misnested formatting by producing a correct
> nesting from incorrect input. Understanding the tree construction
> modes explains why `document.write` called after load clears the
> page (the parser has been closed; calling it reopens a blank page).

---

### ⚠️ Common Misconceptions

**"`<p />` is a self-closing paragraph tag"**

HTML is NOT XML. Self-closing syntax (`/>`) is only meaningful for
void elements (`<br>`, `<hr>`, `<input>`, `<img>`, etc.) and for
SVG/MathML foreign content. In the HTML parser, `<p />` is treated
as `<p>` (the `/` is ignored). The `<p>` element has an optional
end tag - it's closed implicitly when the next block element or
another `<p>` is encountered. Writing `<p />` does nothing special.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: DOM structure doesn't match written HTML**

```
Common cause: block elements inside paragraph elements.

Diagnosis:
  Browser DevTools → Elements panel
  Inspect actual DOM tree vs written HTML
  If they differ: browser error recovery applied

  Common cases:
  1. <p><div> → browser closes <p> before <div>
  2. <table><tr><td> → content outside table cells
     is moved before the table (the "foster parenting" spec rule)
  3. <ul><p>text</p></ul> → <p> is not a valid <ul> child
     browser closes <ul>, inserts <p>, reopens <ul>

  Fix: validate HTML
    W3C Markup Validator: validator.w3.org
    Shows parse errors that browsers silently recover from
    Fixes prevent unexpected DOM structure
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Scenario| Recommended Time| Key Signal|
|------|-------------------------------------------|---------------------------|
| Two phases of HTML parsing| 3 min| Tokenizer + tree builder|
| Why browsers produce same DOM from invalid HTML| 3 min| Spec-defined error rec
| What tokens does the HTML parser emit| 2 min| Token types|
| Parser pausing for scripts| 2-3 min| Parser-blocking explanation|
| Why `<p><div></div></p>` produces 3 elements| 3 min| Optional end tags|
| Adoption Agency Algorithm| 3-4 min| Formatting nesting|
| Why `<p />` isn't self-closing| 2 min| HTML vs XML parsing|
| document.write and the parser| 3 min| Dynamic markup insertion|
| Stack of open elements| 3 min| Tree construction internals|
| Tokenizer state machine states| 2-3 min| 80 states overview|
| HTML parser vs XML parser differences| 3 min| Error tolerance|

---

**[JUNIOR] Q1 - [MECHANISM] What are the two phases of HTML parsing?** `[JUNIOR]` DEFINITION**

> **Answer:**
>
> HTML parsing has two distinct phases:
>
> **Phase 1: Tokenization**
> The tokenizer reads bytes from the network as a character stream.
> It is implemented as a finite state machine with 80 states. Each
> state defines what to do when a specific character is encountered:
> emit a token, switch states, or record an error.
>
> Emitted token types:
> - DOCTYPE token (`<!DOCTYPE html>`)
> - Start tag token (`<div class="foo">`)
> - End tag token (`</div>`)
> - Comment token (`<!-- comment -->`)
> - Character token (any text content)
> - End-of-file token
>
> **Phase 2: Tree Construction**
> The tree builder receives tokens from the tokenizer and builds
> the DOM tree. It maintains:
> - A stack of open elements (current nesting path)
> - A current insertion mode (one of ~20 modes)
>
> The insertion mode changes based on context:
> "in head" → processing `<head>` content
> "in body" → processing `<body>` content
> "in table" → inside `<table>`
>
> Each mode defines what to do with each token type. When a `<p>`
> start tag is encountered while already in a `<p>`, the mode rule
> says: implicitly close the current `<p>` first.
>
> The two phases run concurrently in browsers (tokenizer feeds
> tokens to tree builder as they're produced - incremental parsing).
>
> *What separates good from great:* The two-phase design is why the
> spec is separate from browser implementation. The tokenizer spec
> is exact: for every state, for every character, the action is defined.
> This exactness is what enabled different browser teams (Blink, Gecko,
> WebKit) to independently implement the same tokenizer and get
> identical results from the same HTML. The html5lib test suite has
> thousands of tokenizer test cases that every parser implementation
> must pass.

---

**[JUNIOR] Q2 - [MECHANISM] How does the HTML parser handle `<script>` elements?** `[SENIOR]`**

> **Answer:**
>
> When the tree builder encounters a `<script>` start tag token:
>
> 1. An `HTMLScriptElement` is created and inserted into the DOM
> 2. If the script is external (has `src`): start fetching
> 3. If NOT `defer` or `async`: PAUSE the tokenizer
>    - Spec: "the script is a classic script that will be immediately executed"
> 4. Wait for the script's external resource to load (if external)
> 5. Execute the script (JavaScript engine)
> 6. Resume the tokenizer
>
> Special case: `document.write` during execution:
> ```
> Script calls: document.write("<p>Injected</p>")
> Spec: the text is inserted into the HTML input stream
>       at the current tokenizer position
> Tokenizer resumes with: original HTML + injected text interleaved
> ```
>
> After document is fully loaded:
> Calling `document.write` on a closed document calls
> `document.open()` first (implicit) which DESTROYS the current
> document and starts a new empty one. This is why calling
> `document.write` in a `setTimeout` or `DOMContentLoaded` handler
> clears the entire page.
>
> For `async` scripts:
> - Fetching happens in parallel (tokenizer continues)
> - Execution happens when fetch completes (can interrupt tokenizer
>   at ANY point - hence "non-blocking" but can still interrupt)
>
> For `defer` scripts:
> - Fetching happens in parallel
> - Execution deferred until AFTER parsing is complete
> - Executed in document order before DOMContentLoaded fires
>
> *What separates good from great:* The spec defines two document
> states: "the insertion point" (active during script execution)
> and the normal tokenizer position. `document.write` pushes to the
> insertion point. When the script stack is empty, the insertion point
> is undefined - this is when calling `document.write` triggers
> the implicit `document.open()` that destroys the page.


---

**[SENIOR] Q3 - [MECHANISM] What is the "insertion mode" concept in the HTML5 parsing algorithm and why does it exist?**

*Why they ask:* Tests deep parsing algorithm knowledge.

The HTML parser has 18 defined insertion modes (Initial,
BeforeHTML, BeforeHead, InHead, InBody, InTable,
InSelect, AfterBody, etc.). Each mode defines which
tokens are valid and what tree construction operations
to perform. The parser transitions between modes based
on context - the same token has different semantics
depending on current mode. For example, `<td>` in
"InBody" mode triggers foster parenting (the TD
is placed outside the table, which is invalid HTML,
but the parser recovers). In "InTable" mode, `<td>`
is valid. Insertion modes exist because HTML is
context-sensitive - the meaning of a tag depends on
where it appears in the document structure. A pure
tokenizer (context-free) cannot handle this;
the tree constructor needs contextual state.

*What separates good from great:* Foster parenting -
the specific recovery mechanism for misplaced table
content is a signal that the candidate has read
the actual spec, not just a summary.

---

**[SENIOR] Q4 - [TRADE-OFF] Why does the HTML spec mandate specific error recovery behavior rather than rejecting malformed HTML?**

*Why they ask:* Tests understanding of web compatibility philosophy.

In the early web (1990s), browser vendors implemented
error recovery inconsistently - one browser ignored
an unclosed tag while another inferred a closing tag
at different points. This caused the same document to
render differently across browsers. The HTML5 spec
(2008+) decision: define exact error recovery behavior
so all browsers produce identical DOMs from identical
malformed input. This sacrificed the "fail loud, fail
early" principle (which XML enforces - one syntax error
stops parsing) in favor of backward compatibility.
Breaking the web by rejecting billions of existing
HTML pages was not an option. The trade-off: malformed
HTML silently "works" but with potentially unintended
structure. Developers who rely on error recovery build
fragile pages that may fail on future parser spec updates.

*What separates good from great:* XHTML's failure as a
counter-example - XHTML 1.0 enforced strict parsing
(any error = blank page), was widely deployed 2000-2008,
then abandoned because the error-strict policy broke
too many production sites.

---

**[MID] Q5 - [MECHANISM] How does the speculative preload scanner differ from the main HTML parser?**

*Why they ask:* Tests HTML performance optimization knowledge.

The main HTML parser is single-threaded and can block
on `<script>` tags (executes synchronously, blocking
further parsing). The speculative preload scanner runs
concurrently with the main parser on a separate thread.
It scans ahead in the raw HTML (not a full parse) looking
for resource references (`<script src>`, `<link href>`,
`<img src>`) and dispatches network fetches early.
This means images and scripts start downloading while
earlier scripts are still executing. The scanner is
"speculative" because it does not fully parse the
document - if JavaScript manipulates the DOM in a way
that removes a resource, the speculative fetch was
wasted. Scripts injected with `document.write()` bypass
the speculative scanner (injected dynamically, invisible
to the pre-scan). This is one reason `document.write`
is deprecated.

*What separates good from great:* `document.write`
defeating the speculative scanner - this explains why
Google PageSpeed specifically flags `document.write`
as a performance issue even for small resource loads.

---

**[SENIOR] Q6 - [DEBUGGING] An HTML page takes 4 seconds to render despite a fast server. The HTML file is 15KB. What do you investigate?**

*Why they ask:* Tests render-blocking resource diagnosis.

Parser blocking causes: (1) A synchronous `<script>`
in `<head>` without `defer` or `async` - the browser
fetches and executes it before continuing. Check the
Network waterfall for a script that delays HTML parsing.
(2) A CSS file in `<head>` - CSS is render-blocking
(not parser-blocking, but blocks paint). Large CSS
files delay First Contentful Paint. (3) A slow DNS
resolution for a cross-origin resource referenced
early in `<head>`. Fix priority: add `defer` or `async`
to all `<head>` scripts, inline critical CSS (above-fold
styles), add `<link rel="preconnect">` for critical
third-party origins. Use Chrome DevTools "Coverage"
to find unused CSS that can be deferred.

*What separates good from great:* CSS render-blocking
vs parser-blocking distinction - CSS does not block
parsing but blocks rendering; a 500KB CSS file will
show up as a long render-blocking period in the DevTools
Performance trace even if parsing completes quickly.

---

**[SENIOR] Q7 - [MECHANISM] What is the difference between the tokenizer and tree builder in the HTML parsing algorithm?**

*Why they ask:* Tests parsing architecture understanding.

The HTML parser has two stages: (1) Tokenizer: reads
raw bytes and produces a stream of tokens (DOCTYPE,
start tag, end tag, character, comment). The tokenizer
is a state machine with 80+ states that handles character
encoding, entity references, and raw text elements
(script/style which suppress normal tokenization).
(2) Tree builder: consumes tokens and builds the DOM
tree. It maintains insertion modes and implements all
error recovery logic. The separation matters: the
tokenizer handles lexical analysis (what are the tokens),
the tree builder handles syntactic analysis (how do
tokens form a tree). The script execution pause affects
the tree builder (it pauses waiting for script to execute),
not the tokenizer.

*What separates good from great:* "The tokenizer is
suspended during scripted parsing" - when `document.write`
is called during a parser-blocking script, a new tokenizer
is started for the injected markup, nested within the
paused tokenizer. This two-level nesting is why
`document.write` is pathological for parsing performance.

---

**[STAFF] Q8 - [DESIGN] How would you design an HTML sanitizer that preserves safe markup while blocking XSS?**

*Why they ask:* Tests security-aware HTML processing knowledge.

A safe HTML sanitizer must parse using the browser's
actual HTML parsing algorithm (not a regex) to handle
all the edge cases the spec defines. Implementation:
(1) Parse the input HTML into a DOM using a sandboxed
parser (DOMParser API or a server-side HTML5 parser like
`html5lib`). (2) Walk the resulting DOM tree. (3) For
each element: check against an allowlist of permitted
tags (not a blocklist - new dangerous tags keep being
added). (4) For each attribute: check against a per-tag
allowlist of safe attributes. (5) URL attributes
(`href`, `src`, `action`) must be validated against
a URL allowlist (permit only `http:`, `https:`, `mailto:`
- never `javascript:`, `data:`, `vbscript:`).
(6) Event handler attributes (`on*`) are never permitted.
Key insight: blocklist approaches always miss edge cases
(e.g., SVG's `<animate onbegin="alert(1)">`).

*What separates good from great:* Parser-based vs
regex-based sanitization - regex can be bypassed with
malformed HTML that browsers correct during parsing.
Only parsing with an HTML5-compliant parser and then
filtering the resulting DOM is provably safe.

---

**[STAFF] Q9 - [MECHANISM] How do HTML modules and import maps change HTML architecture for future applications?**

*Why they ask:* Tests forward-looking standards awareness.

HTML Modules (proposed, partial implementation):
allows importing HTML files as modules via
`import template from './component.html' assert {type: 'html'}`.
The imported module provides a DocumentFragment that
can be cloned into the DOM. This eliminates the current
workaround of fetching HTML strings with `fetch()` and
setting `innerHTML` (XSS risk) or hardcoding templates
as JS template literals. Import Maps (Chrome 89+, 2021):
allows remapping bare module specifiers in the browser
without a bundler: `{"imports": {"lodash": "/node_modules/lodash/index.js"}}`.
This enables `import _ from 'lodash'` in browser code
without build step. Architecture implication: native
module loading for HTML components becomes possible,
reducing build tool dependency for development and
simple deployments.

*What separates good from great:* Import maps enabling
"no build step" development - this is a real architectural
shift for simple apps and internal tools, reducing the
webpack/vite requirement that has been necessary since
2015.


---

| Interviewer Type| Emphasis|
|----------------------------------|-------------------------------------------|
| Theory Interview| 80-state machine + insertion modes|
| Senior Technical| Script execution pause + document.write|
| Curiosity Probe| Why browsers produce same DOM from bad HTML|

---

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compar


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanation


# HTML Specification History and Browser Divergence

🎯 **Interview Weight:** specialist (★★☆) - historical context
explains current HTML behaviors and motivates modern practices

---

### 🎯 Model Answer

**30 seconds:**

> HTML started with Tim Berners-Lee's informal 1991 proposal. HTML 2.0
> was the first formal spec (1995). HTML 4.01 (1999) was the stable
> web baseline. The browser wars (IE vs Netscape, 1995-2001) drove
> proprietary extensions and divergence. WHATWG formed in 2004 to
> modernize HTML while W3C was pursuing XHTML2 (dead end). HTML5
> was developed by WHATWG/W3C jointly from 2007-2014. In 2019:
> W3C and WHATWG agreed on the single Living Standard. Browser
> divergence today is minimal vs the 1990s-2000s era.

**3 minutes:**

> HTML history in eras:
>
> **Era 1 (1991-1995)**: Tim Berners-Lee's original HTML at CERN.
> Hyperlinks + simple structure for scientific documents.
>
> **Era 2 (1995-2000) - Browser Wars**: Netscape Navigator vs IE.
> Each browser added proprietary HTML elements (`<blink>`, `<marquee>`,
> `<layer>`). Pages were written for specific browsers. "Best viewed
> in IE" banners were common. DOM manipulation was different in each
> browser. CSS support was inconsistent.
>
> **Era 3 (2000-2007) - Standards movement**: W3C pushed XHTML
> (strict HTML as XML). Firefox/Mozilla gained market share.
> Web standards advocates (Jeffrey Zeldman, etc.) pushed for
> cross-browser coding. IE stagnation (no updates from IE6, 2001
> to IE7, 2006).
>
> **Era 4 (2007-2014) - HTML5**: WHATWG and W3C collaborated.
> Chrome launched (2008). IE dominance eroded. HTML5 delivered:
> `<canvas>`, `<video>`, `<audio>`, form input types, localStorage,
> semantic elements, Web Workers, WebSocket.
>
> **Era 5 (2014-present) - Living Standard**: HTML5 finalized (2014).
> 2019: unified Living Standard. Modern web: near-identical rendering
> in all major browsers. Devtools, service workers, PWA, Web Components.

**Blank Mind Recovery:**

**(1) Restate:** "HTML evolved from a CERN document format to a
Living Standard. Browser wars caused divergence. HTML5 and WHATWG
fixed it. One spec, consistent behavior today."

**(2) Bridge:** "The history explains WHY we have features like
`doctype` (to trigger standards mode), `vendor prefixes` (experimental
CSS), and `caniuse.com` (because support used to matter a lot more)."

---

### 📘 Concept Explanation

**What it is:**

HTML specification history documents how the language evolved from
an informal academic document format to the most widely deployed
document format in history, and how browser divergence (and its
resolution) shaped modern web development practices.

**The problem it solves:**

Understanding the history explains many current HTML behaviors that
seem arbitrary: why `<!DOCTYPE html>` exists, why `<table>` has
quirky rendering, why there are vendor-prefixed CSS properties,
why IE's box model was different, and why progressive enhancement
was essential for years.

**How it works:**

```
HTML TIMELINE:

1991: Tim Berners-Lee proposes HTML
  18 elements, all structural
  Purpose: share documents over the internet at CERN
  No styling, no interactivity, no media
  <a>, <h1>-<h6>, <p>, <ul>, <li>, <dl>, <dt>, <dd>

1994: W3C formed (World Wide Web Consortium)
  Tim Berners-Lee leaves CERN, founds W3C at MIT
  Purpose: standardize web technologies

1995: HTML 2.0 (RFC 1866)
  First formal specification
  Formalizes what was already implemented in browsers
  (Spec followed implementations, not the other way around)

1996: HTML 3.2 (W3C recommendation)
  Adds: tables, applets, client-side image maps
  Netscape proprietary: <center>, <blink>, <font>
  IE proprietary: CSS support (but different from W3C CSS)

1997: HTML 4.0, then HTML 4.01 (1999)
  Major spec - remained the baseline for 15 years
  Strict vs Transitional vs Frameset doctypes
  Recommendations: move presentation to CSS
  Still: most sites used Transitional mode

THE BROWSER WARS (1995-2001):
  Netscape Navigator: dominant browser until 1997
  Internet Explorer: Microsoft bundled with Windows
  Market share shift: Netscape 80% → IE 80% (1997-1998)

  Netscape proprietary HTML elements:
    <blink>: text blinks on/off
    <layer>: CSS-like positioning (never standardized)
    <frameset>: multiple HTML files in one window

  IE proprietary HTML elements:
    <marquee>: scrolling text
    <bgsound>: background audio (IE only)
    Behavior: CSS filter, HTC behaviors
    DOM: document.all instead of document.getElementById

  Result: pages written "best viewed in IE" or "best viewed in Netscape"
  Developers maintained two codebases.

THE DOCTYPE HACK:
  Problem: HTML 4.01 changed table/box model behavior.
  Old pages relied on old behavior.
  Browsers needed to support BOTH old and new behavior.

  Solution: DOCTYPE triggers standards mode vs quirks mode.

  Quirks mode: <html> with no DOCTYPE or old DOCTYPE
    → browser renders like IE4/Netscape 4 (table box model)
  Standards mode: <!DOCTYPE html> or strict HTML 4.01 doctype
    → browser renders per specs

  This is why <!DOCTYPE html> exists.
  The 15-character string at the top of every HTML file
  exists to opt into "standards mode".

  HTML5 simplified: <!DOCTYPE html>
  (Was: <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Strict//EN"
        "http://www.w3.org/TR/html4/strict.dtd">)

THE XHTML DEAD END (1999-2007):
  W3C direction: move web to XML
  XHTML 1.0 (2000): HTML as XML
    → case-sensitive, all tags closed, attribute values quoted
    → served as application/xhtml+xml broke in IE
  XHTML 2.0 (draft, 2006): completely incompatible with HTML4
    → no backward compatibility
    → rejected by browser vendors: "web can't break backward compat"
    → XHTML 2 never shipped, deprecated 2009

  WHATWG formed (2004) specifically to oppose XHTML direction:
    Apple, Mozilla, Opera engineers
    "HTML is the web. We must evolve HTML, not replace it."

HTML5 DEVELOPMENT (2007-2014):
  WHATWG developed HTML5 specification
  W3C adopted the WHATWG spec as basis for "HTML 5"
  Both organizations worked on the same spec (mostly)

  Key HTML5 additions:
  Semantic elements:
    <article>, <section>, <aside>, <nav>,
    <header>, <footer>, <main>, <figure>, <figcaption>

  Media:
    <video>, <audio>, <source>, <track>
    (eliminated need for Flash for video)

  Forms:
    type="email", type="url", type="date",
    type="number", type="range", type="color",
    type="tel", type="search"
    required, pattern, min, max, placeholder

  Canvas + graphics:
    <canvas>: 2D drawing API
    <svg>: inline SVG (SVG integrated into HTML parser)

  APIs (HTML spec, not JS spec):
    localStorage, sessionStorage (Web Storage)
    Drag and drop API
    History API (pushState)
    Web Workers
    WebSocket protocol (spec in HTML)
    Geolocation API (via HTML spec reference)
    Microdata (alternative to JSON-LD, mostly unused)

  November 2014: W3C published "HTML 5" as a Recommendation
  "HTML5" was complete.

2016-2019: FORK RESOLVED:
  W3C and WHATWG had diverged slightly (e.g., two different
  HTML specs existed). This confused developers.

  May 2019: W3C and WHATWG Memorandum of Understanding:
  - WHATWG HTML Living Standard = THE HTML spec
  - W3C publishes snapshots of the WHATWG standard
  - W3C stopped developing its own HTML specification
  - One spec, maintained on GitHub by WHATWG

BROWSER RENDERING ENGINES (history):
  1995: Trident (IE), Gecko (Netscape/Firefox), KHTML (Konqueror)
  1998: WebKit (Apple forked from KHTML, 2002)
  2008: V8 (Google), Blink (Google forked from WebKit, 2013)
  2019: Edge switches from EdgeHTML to Blink (Chromium)

  Today: Blink (Chrome, Edge, Opera, Brave)
         Gecko (Firefox)
         WebKit (Safari, iOS all browsers)
  3 rendering engines (was 5+ in the browser war era)

REMAINING BROWSER DIVERGENCE (2025):
  Safari (WebKit) lags on some features:
    Push API: partial support
    Web NFC: not supported
    Service Worker background sync: limited

  Firefox: different from Blink in edge cases:
    Some CSS Grid subgrid behaviors
    Some Web Bluetooth API behaviors

  Practical impact: much less than the 1990s-2000s era.
  "Baseline Newly Available" covers 90%+ of users for most features.
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

**The key insight:**

The browser divergence era (1995-2007) created a generation of
"defensive web development" practices: check if a feature exists
before using it, use multiple CSS prefixes, test in multiple browsers.
Many of these practices are now unnecessary for modern browsers but
persist as habits. Understanding the history helps engineers
distinguish "this is still necessary" from "this is a 2005 practice
that modern browsers don't need."

---

### 💻 Code Example

**Evolution of feature detection patterns**

```javascript
// BAD: browser detection (2000s era - unreliable):
if (navigator.userAgent.indexOf('MSIE') !== -1) {
  // IE-specific code
  document.attachEvent('onclick', handler);
} else {
  // Modern browser code
  document.addEventListener('click', handler);
}
// Problem: user agent strings are spoofed, unreliable,
// and don't tell you what the browser CAN do

// BETTER: feature detection (2000s-era best practice):
if (document.addEventListener) {
  document.addEventListener('click', handler);
} else if (document.attachEvent) {
  document.attachEvent('onclick', handler);  // IE8 and below
}
// Problem: verbose, must maintain for every API split

// MODERN (2015+): assume modern browsers,
// use Baseline as the threshold:
// Check caniuse.com/mdn compatibility tables first.
// If feature is Baseline Widely Available: use directly.
// If feature is Baseline Newly Available: use with check.

// Modern feature detection (used sparingly):
if ('loading' in HTMLImageElement.prototype) {
  // Native lazy loading: use it
} else {
  // Old browser: use IntersectionObserver polyfill
}

// CSS vendor prefixes (2005-2015 era, now mostly gone):
.box {
  -webkit-transform: rotate(45deg);  /* Chrome/Safari */
  -moz-transform: rotate(45deg);     /* Firefox */
  -ms-transform: rotate(45deg);      /* IE 9 */
  transform: rotate(45deg);          /* Standard */
}
// Modern (2024): just use transform: rotate(45deg);
// All browsers support unprefixed transform

// DOCTYPE evolution:
<!-- 2005: full DOCTYPE (HTML 4.01 Strict) -->
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Strict//EN"
  "http://www.w3.org/TR/html4/strict.dtd">

<!-- 2010+: HTML5 DOCTYPE (always use this) -->
<!DOCTYPE html>
```

> **Code walkthrough:** The progression from user-agent detectionice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**
> to feature detection to Baseline-based assumptions reflects the
> evolution of browser compatibility. User-agent detection failed
> because browsers lied about their identity for compatibility.
> Feature detection was more reliable but required testing for
> every API. Today's approach is to check the Baseline status of
> a feature once (at development time), then either use it directly
> or add a polyfill - no runtime feature detection needed for
> features that have been Baseline for years. The CSS vendor prefix
> example shows how a practice that was essential in 2010 became
> obsolete by 2020 as browsers converged on standard implementations.

---

### ⚖️ Comparison Table

| Era | Dominant Browser | HTML Spec | Divergence Level |
|---|---|---|---|
| 1995-2000 | Netscape | HTML 3.2 | High (proprietary elements) |
| 2000-2008 | IE 6 | HTML 4.01 | Very High (IE-only behaviors) |
| 2008-2014 | IE/Chrome | HTML5 draft | Medium (new API race) |
| 2014-2019 | Chrome | HTML5/Living | Low |
| 2019-present | Chrome | Living Standard | Very Low |

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> HTML evolved from a document format to an application platform.
> The browser wars caused proprietary divergence. HTML5 standardized
> major features (video, canvas, semantic elements). The Living
> Standard ensures continuous improvement. `<!DOCTYPE html>` triggers
> standards mode (vs quirks mode that emulated old browser behavior).

---

**Senior / Staff:**

> The historical divergence era (IE dominance, 2001-2008) explains
> many current practices: vendor prefixes, feature detection, the
> concept of progressive enhancement. Modern cross-browser compatibility
> is dramatically better - the three surviving rendering engines
> (Blink, Gecko, WebKit) implement the same Living Standard.
> Quirks mode still exists (any page without `<!DOCTYPE html>` gets it),
> so always include the doctype. The browser wars also explain why
> `document.all` exists (IE proprietary API, still alive in 2025 for
> compatibility) and why `attachEvent` code still appears in legacy codebases.

---

### ⚠️ Common Misconceptions

**"HTML5 is a technology, not a specification"**

"HTML5" is specifically the 2014 W3C recommendation that succeeded
HTML 4.01. The term became marketing for a bundle of features
(Canvas, Web Storage, geolocation, offline). The current specification
is the "HTML Living Standard" - not HTML5. Features like service
workers, web components, and custom elements arrived AFTER HTML5
was published. Engineers using "HTML5" to mean "modern web features"
are technically imprecise, though the usage is widely understood.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: page renders in quirks mode**

```
Diagnosis:
  Browser DevTools → Console:
  document.compatMode
  "BackCompat" = quirks mode
  "CSS1Compat" = standards mode

Root cause: missing DOCTYPE or obsolete DOCTYPE
  BAD (triggers quirks mode):
    (no DOCTYPE)
    <html>...</html>

  BAD (old DOCTYPE, triggers quirks mode):
    <!DOCTYPE html PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">

  GOOD:
    <!DOCTYPE html>
    <html>...</html>

Quirks mode differences (what breaks):
  Box model: IE4 quirks box model (width includes padding/border)
  Table layout: different from standards
  Various CSS property interpretations
  Vertical alignment in table cells

Fix: add <!DOCTYPE html> as first line of every HTML document
```

> **Code walkthrough:** This Unknown example demonstrates a key concept in practice. **KEY MECHANISM:** the runtime executes these instructions in sequence with specific memory and execution semantics. **WHY IT MATTERS:** misapplying this pattern causes subtle bugs that only manifest under production load. **TAKEAWAY: understand the execution model before using this pattern in production code.**

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| HTML versions and evolution | 3 min | 1991 → Living Standard |
| Browser wars impact | 2-3 min | Divergence era |
| Why DOCTYPE exists | 2 min | Quirks vs standards mode |
| WHATWG formation | 2-3 min | XHTML dead end |
| HTML5 key additions | 3 min | Video, canvas, semantic elements |
| Browser rendering engines today | 2 min | Blink, Gecko, WebKit |
| Vendor prefixes history | 2-3 min | CSS prefix evolution |
| Feature detection vs UA detection | 2-3 min | Best practice evolution |
| 2019 WHATWG/W3C agreement | 2 min | One Living Standard |
| Quirks mode diagnosis | 2 min | document.compatMode |

---

**[JUNIOR] Q1 - [MECHANISM] Why does `<!DOCTYPE html>` exist and what happens without it?**

> **Answer:**
>
> The DOCTYPE declaration exists to trigger "standards mode" in
> browsers, as opposed to "quirks mode."
>
> Historical context: When HTML 4.01 standardized the box model and
> other rendering behaviors, it changed how things rendered vs older
> browsers (IE3/IE4, Netscape 4). To avoid breaking millions of
> existing pages, browsers kept the old rendering behavior available.
>
> The trigger mechanism:
> - Page with `<!DOCTYPE html>`: standards mode (correct rendering)
> - Page without DOCTYPE: quirks mode (old rendering)
>
> What quirks mode changes:
> - Box model: `width` includes `padding` and `border` (IE4 behavior)
>   vs standards: `width` is content-only
> - `height: 100%` on elements that lack a height-specified parent:
>   different behavior
> - Various CSS interpretation differences
>
> HTML5 simplified the DOCTYPE because browsers don't need to
> download and validate a DTD. The minimum string that triggers
> standards mode in all browsers is `<!DOCTYPE html>`.
>
> Checking current mode:
> ```javascript
> document.compatMode
> // "CSS1Compat" → standards mode
> // "BackCompat" → quirks mode (DOCTYPE missing)
> ```
>
> *What separates good from great:* There is also an "almost standards mode"
> (also called "limited quirks mode") triggered by certain transitional
> doctypes. The only reliable way to get full standards mode is
> `<!DOCTYPE html>`. Any other DOCTYPE risks either quirks mode or
> almost-standards mode. This is why every HTML file should start
> with the 15-character `<!DOCTYPE html>` declaration, always.

---

**[JUNIOR] Q2 - [MECHANISM] What is the browser wars era and why does it matter for web development today?**

> **Answer:**
>
> The browser wars (1995-2001) were a period of fierce competition
> between Netscape Navigator and Microsoft Internet Explorer.
>
> What happened:
> - Both browsers added proprietary HTML elements and APIs to win market share
> - Netscape: `<blink>`, `<layer>`, proprietary JavaScript APIs
> - IE: `<marquee>`, `document.all`, `ActiveX`, CSS filters
> - Pages were designed for one browser or the other
> - "Best viewed in IE" or "Best viewed in Netscape" banners were common
>
> Long-term impact (still visible in codebases today):
>
> 1. `document.all`: IE-only API from 1996, still present in browsers
>    for backward compatibility:
>    ```javascript
>    document.all['myId'] // IE way
>    document.getElementById('myId') // standards way
>    ```
>
> 2. `event.srcElement` vs `event.target`:
>    IE used `event.srcElement`; standards spec `event.target`.
>    Modern browsers support both.
>
> 3. `addEventListener` vs `attachEvent`:
>    IE8 and below used `attachEvent`.
>    You may still see this in legacy code.
>
> 4. CSS vendor prefixes: even post-wars, experimental CSS features
>    shipped with prefixes (`-webkit-`, `-moz-`, `-ms-`).
>
> Why it matters now:
> - Legacy codebases contain IE-specific workarounds
> - Understanding this history helps you recognize and remove them
> - It explains why web standards advocacy exists
> - It motivates the "progressive enhancement" principle
>   (build on what all browsers support, layer on extras)
>
> *What separates good from great:* Microsoft ending IE support
> in June 2022 effectively ended the browser wars legacy. Before
> that date, many enterprise applications required IE11 support
> (often for internal corporate tools). The shift from IE11 support
> to modern browser support was a significant compatibility threshold:
> arrow functions, `const`/`let`, CSS Grid, `Promise`, `fetch` all
> required polyfills for IE11 but are now universally supported.
> Removing IE11 support from a codebase typically removes 10-30%
> of the JavaScript bundle (polyfills).


---

**[SENIOR] Q3 - [MECHANISM] Why did XHTML fail to replace HTML despite technical advantages?**

*Why they ask:* Tests understanding of web standards evolution.

XHTML 1.0 (2000) required well-formed XML: every tag
closed, lowercase elements, quoted attributes, no
`<br>` without `<br/>`. The advantages: clear, parseable
documents; XML tooling compatibility; path to semantic
web. The failure: (1) Served as `text/html` MIME type,
browsers parsed it with the lenient HTML parser - the
strict rules had no enforcement. (2) Content served
as `application/xhtml+xml` (the correct MIME type)
caused any single syntax error to display a blank page
("Yellow Screen of Death"). (3) Legacy content (blogs,
CMSs, user-generated content) could not realistically
enforce XHTML rules. (4) Server and tool support was
inconsistent. By 2008, the WHATWG/HTML5 trajectory was
clear: spec-defined error recovery over strict syntax.
XHTML 2.0 (fundamentally incompatible with HTML) was
abandoned in 2009.

*What separates good from great:* The MIME type trap -
knowing that `text/html` XHTML is a lie (browsers parse
it as HTML4 with the error-tolerant parser) vs
`application/xhtml+xml` XHTML which is strict. Most
"XHTML" sites were using the former, getting none of
the actual XHTML benefits.

---

**[MID] Q4 - [MECHANISM] What is quirks mode and what triggers it?**

*Why they ask:* Tests DOCTYPE and browser history knowledge.

Quirks mode is a browser rendering mode that emulates
old (pre-CSS-standard) behavior of Netscape 4 and IE5
to maintain backward compatibility with pre-standard
web pages. Trigger: missing, malformed, or old DOCTYPE.
`<!DOCTYPE html>` triggers standards mode. `<!DOCTYPE
HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">`
without a URL triggers almost-standards mode (standards
except for image cell behavior). No DOCTYPE triggers
quirks mode. The three modes differ in: box model
(quirks uses IE5 box model: padding included in width),
table cell height calculation, line height in table cells.
Modern browsers all implement standards mode consistently.
Quirks mode exists only for compatibility with pre-2000
web pages.

*What separates good from great:* The "almost standards"
mode - a third mode between quirks and standards, triggered
by specific old DOCTYPEs, that matches standards mode
except for one image placement behavior. Most candidates
only know two modes.

---

**[SENIOR] Q5 - [TRADE-OFF] Why does the HTML Living Standard model (continuous updates) create risks for production applications?**

*Why they ask:* Tests standards stability awareness.

Living Standard risks: (1) Feature behavior can change
between browser versions as the spec evolves. An API
that shipped in Chrome 90 may have behavioral clarifications
in Chrome 95 that break assumptions. (2) No versioned
"stable" snapshot to pin to - a production app cannot
say "we target HTML 5.3." (3) Feature detection is the
only stable strategy - detecting capability rather than
relying on version numbers. (4) Experimental features
behind flags may ship broadly before spec stabilization,
locking in behavior that the spec later changes.
Mitigation: use BrowserStack/Playwright for cross-browser
testing, subscribe to browser changelogs (Chrome Platform
Status, MDN), run integration tests on browser canary
builds in CI to detect spec changes early.

*What separates good from great:* Canary testing in CI -
running end-to-end tests against browser canary/beta
detects spec behavior changes 6-8 weeks before stable
release, giving teams time to adapt.

---

**[SENIOR] Q6 - [DEBUGGING] An HTML page renders correctly in Chrome but shows blank content in Safari. The page uses valid HTML5. What do you investigate?**

*Why they ask:* Tests cross-browser compatibility debugging.

Safari lags Chrome in implementing newer HTML features.
Investigation: (1) Open Safari Technology Preview or
BrowserStack. (2) Check Safari's error console for
unrecognized elements (custom elements without polyfill,
`<dialog>` before 15.4, `<details>`/`<summary>` before
2012). (3) Check caniuse.com for each HTML5 API or
element used - filter to Safari version in use.
(4) Declarative Shadow DOM - not supported in Safari
until 16.4 (2023). Web components, `popover` API,
`<dialog>` are common Safari-lag candidates.
Fix: feature detection (`'showModal' in document.createElement('dialog')`),
polyfills for critical elements, progressive enhancement
fallback for non-critical features.

*What separates good from great:* Knowing specific
Safari lag dates - `<dialog>` shipping in Safari 15.4
(March 2022) is a real production issue affecting
enterprise users on older Safari versions.

---

**[STAFF] Q7 - [DESIGN] How would you design an HTML5 migration strategy for a large legacy website still using HTML4 patterns?**

*Why they ask:* Tests migration architecture thinking.

Migration strategy: (1) Audit - crawl the site, identify
HTML4 patterns: `<center>`, `<font>`, `<b>`/`<i>` for
semantics, table-based layout, missing DOCTYPE,
non-semantic wrapper `<div>` structures. (2) DOCTYPE
first - add `<!DOCTYPE html>` to all pages. Low risk,
enables HTML5 rendering mode. (3) Semantic layer -
add landmark elements (`<header>`, `<nav>`, `<main>`,
`<footer>`) as wrappers around existing divs. These
are additive; they do not break existing CSS.
(4) Form upgrade - add `type="email"`, `type="tel"`,
`required`, `pattern` attributes. Progressive enhancement:
old browsers render as `type="text"`. (5) Remove
presentational HTML - replace `<b>` with `<strong>`,
`<i>` with `<em>` or `<cite>`, `<center>` with CSS.
(6) Validate after each phase with W3C Validator.
Never do all phases at once - each phase can be
deployed and tested independently.

*What separates good from great:* The additive landmark
approach - wrapping existing divs in semantic elements
rather than restructuring the entire DOM reduces risk
by making the semantic migration independent of styling.

---

**[STAFF] Q8 - [MECHANISM] How does the HTML Content Security Policy interact with inline HTML and script execution?**

*Why they ask:* Tests security headers and HTML integration.

CSP `script-src` controls which scripts can execute.
`'unsafe-inline'` allows all inline scripts -
functionally disabling XSS protection. Modern CSP uses
nonces: the server generates a per-request nonce
(random token), adds it to the `Content-Security-Policy`
header (`script-src 'nonce-<token>'`) and to each
trusted inline script tag (`<script nonce="<token">`).
The browser only executes inline scripts with matching
nonces. An injected script from XSS does not know the
nonce. HTML implications: dynamically generated scripts
(from `innerHTML`) do not execute even if the static
page has a nonce - the nonce applies to the script
element in the HTML response, not to DOM-injected scripts.
This makes nonce-based CSP compatible with server-side
rendering but incompatible with client-side `innerHTML`
script injection.

*What separates good from great:* The `innerHTML` script
suppression rule - browsers do not execute scripts
inserted via `innerHTML` regardless of CSP, as a
separate security measure. This is distinct from CSP
and confuses developers who expect `innerHTML` to
execute scripts.

---

**[STAFF] Q9 - [TRADE-OFF] What are the trade-offs of using `<template shadowrootmode>` (Declarative Shadow DOM) versus JavaScript-based shadow root attachment?**

*Why they ask:* Tests emerging web standards trade-off knowledge.

Declarative Shadow DOM (DSD): server-rendered shadow root
in HTML, works before JavaScript loads, enables SSR for
web components. Trade-offs: (1) Verbose - the shadow DOM
markup is repeated for each instance in the HTML (server
must serialize full shadow template per component instance).
For 100 instances of the same component: 100× the shadow
DOM HTML in the response. JavaScript `attachShadow` +
shared `<template>` avoids this by cloning one template.
(2) Browser support: Chrome 90+, Firefox 123+, Safari 16.4+.
Requires polyfill for older browsers. (3) Streaming HTML
advantage - DSD enables streaming: the shadow root is
available immediately when that element's HTML is streamed,
before the rest of the page loads. JavaScript `attachShadow`
requires waiting for DOMContentLoaded (or earlier with
careful placement). Use DSD for SSR-critical components,
JavaScript attachment for client-side-only components.

*What separates good from great:* The per-instance
verbosity trade-off - for components rendered many times,
DSD's serialization cost may outweigh the SSR benefit.
Hybrid: DSD for the first critical above-fold instance,
JS cloning for subsequent instances.


---

| Interviewer Type | Emphasis |
|---|---|
| Theory Interview | WHATWG history + parsing algorithm |
| Senior Technical | DOCTYPE quirks mode + browser engine history |
| Architectural | Living Standard evolution + standards process |

---

### 💻 Code Example

*(Omit: this concept does not have a programmatic interface that can be demonstrated in code. The conceptual explanation above is sufficient.)*


---

### 🏛️ System Design

*(Omit: system design diagram not applicable for this concept - see ★★★ keywords for full system design coverage.)*


---

### ⚖️ Comparison Table

*(Omit: this is a ★☆☆ foundational concept with no direct alternatives to compare - see higher-difficulty keywords for trade-off analysis.)*


---

### 📊 Diagram

*(Omit: no standalone visual diagram required for this concept - the explanations and code examples above provide sufficient clarity.)*



