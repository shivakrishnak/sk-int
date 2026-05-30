---
layout: default
title: "JavaScript - L2 DOM and Events"
parent: "JavaScript"
nav_order: 7
permalink: /javascript/l2-dom-and-events/
---

# DOM Manipulation and Query API

🎯 **Interview Weight:** high (★★☆) - Core frontend skill; tests
whether the candidate understands live vs static collections,
layout thrashing, and XSS via innerHTML

---

### 🎯 Model Answer

**30 seconds:**

> The DOM is the browser's live, tree-structured representation of
> an HTML document. The Query API - `querySelector`, `getElementById`,
> `querySelectorAll` - selects nodes. Manipulation methods like
> `appendChild`, `textContent`, and `classList` modify the tree.
> The key performance insight is to batch DOM reads before writes;
> interleaving them forces repeated layout recalculations, called
> layout thrashing. For security, always use `textContent` for user
> data, never `innerHTML`.

**3 minutes (Senior):**

> I think about DOM manipulation in two cost dimensions: query cost
> and mutation cost. `getElementById` is O(1) via a browser hash map;
> `querySelector` runs the CSS selector engine and is O(n) for complex
> selectors. For elements accessed frequently in event handlers, I
> cache the reference at init rather than re-querying on every event.
>
> For mutations: any write that changes layout - width, height,
> position - invalidates the browser's layout tree. Reads that return
> layout values like `offsetHeight` or `getBoundingClientRect` force
> the browser to flush that invalidation synchronously to return an
> accurate value. Interleaving reads and writes in a loop causes
> repeated layout flushes - layout thrashing. The fix is batching:
> read all values first, then write all values.
>
> For security: `innerHTML` parses assigned strings as HTML. If any
> user-controlled data is in the string, embedded scripts or event
> handlers execute - DOM-based XSS. `textContent` treats the value
> as literal text and is always safe for user data.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

*Adapting up:* Staff discuss virtual DOM reconciliation trade-offs,
MutationObserver for reactive UI, and why frameworks exist to solve
these manual DOM problems.

*Adapting down:* Junior: `querySelector`, `textContent`, `classList` -
the three tools for 90% of cases.

**Blank Mind Recovery:**

**(1) Restate:** "DOM manipulation - let me think through what
the DOM is and what makes working with it tricky."

**(2) First principles:** "The browser parses HTML into a tree of
objects. JavaScript needs to find nodes and change them. The
challenge is doing that without performance or security problems..."

**(3) Bridge:** "This reminds me of a live database - reads and
writes both have cost, and batching is the key optimization."

---

### 📘 Concept Explanation

**What it is:**

The DOM is the browser's in-memory object representation of a parsed
HTML document. The Query API selects nodes; manipulation methods
modify the tree, triggering rendering pipeline updates.

**The problem it solves:**

Without the DOM API, JavaScript cannot read or modify the page after
initial render. The DOM gives JavaScript a structured, live interface
to the document for building interactive applications.

**How it works:**

```
HTML → [Parser] → DOM Tree
  document
    └─ html
         └─ body
              └─ ul#list
                   └─ li (x1000)

Query:
  getElementById('list')  → O(1) hash map
  querySelector('.item')  → O(n) selector engine
  querySelectorAll('li')  → static NodeList (snapshot)

Mutation:
  el.textContent = 'x'  → text node update
  el.classList.add('y') → attribute update
  el.style.display='none'→ style update
       |
  Browser invalidates layout (deferred)
       |
  Read offsetHeight → forces synchronous flush
  (= layout thrashing if in a loop)
```

**The key insight:**

`querySelectorAll` returns a **static** NodeList - a snapshot.
`getElementsByClassName` returns a **live** HTMLCollection that
updates automatically. This distinction causes subtle bugs when
iterating a collection while modifying the DOM.

**When to use it:**

- Progressive enhancement on server-rendered pages
- Web Components and custom element implementations
- Direct DOM manipulation outside of frameworks

**When NOT to use it:**

- Inside React, Vue, or Angular - use framework state; direct DOM
  manipulation bypasses reconciliation and causes sync issues
- For large list renders - use DocumentFragment or virtual scrolling

**Alternatives:**

- Framework virtual DOM → Abstracts DOM, batches updates automatically
- `insertAdjacentHTML` → Faster than full `innerHTML` replacement
- Canvas/WebGL → Pixel-level rendering not tied to the DOM tree

**First-principles derivation:**

Given HTML parses into a tree, and JavaScript needs to interact with
rendered content, the design must provide: tree traversal (query),
node modification (mutation), and event observation. Layout
performance costs arise from the browser's rendering pipeline -
invalidation is inherent in the layout tree design.

---

### 💻 Code Example

**Example 1: textContent vs innerHTML (security)**

```javascript
// BAD: innerHTML with user content - XSS vector
// name = '<img src=x onerror=alert(document.cookie)>'
document.getElementById('greeting').innerHTML =
  'Hello, ' + name; // executes attacker JS

// GOOD: textContent treats value as literal text
document.getElementById('greeting').textContent =
  'Hello, ' + name; // safe - no HTML parsing
```

> **Code walkthrough:** `innerHTML` parses the string as HTML,
> executing any embedded handlers in user-controlled data. `textContent`
> escapes everything as plain text and never parses HTML. Default to
> `textContent` for any runtime data; use `innerHTML` only for
> developer-controlled static templates.

**Example 2: Avoiding layout thrashing**

```javascript
// BAD: read/write interleaved - forces layout recalc each iteration
elements.forEach(el => {
  const h = el.offsetHeight; // READ: forces sync layout flush
  el.style.height = (h * 1.5) + 'px'; // WRITE: invalidates layout
}); // Next READ forces flush again - O(n) layouts

// GOOD: batch reads then writes - O(1) layouts
const heights = elements.map(el => el.offsetHeight); // all reads
elements.forEach((el, i) => {
  el.style.height = (heights[i] * 1.5) + 'px'; // all writes
});
```

> **Code walkthrough:** Each layout-read property forces the browser
> to synchronously recalculate layout because the preceding write may
> have invalidated cached values. Batching reads first causes one
> layout calculation; batching writes causes one invalidation. This
> pattern is the most impactful DOM performance optimization.

**Example 3: DocumentFragment for bulk insertion**

```javascript
// BAD: 1000 appends = 1000 potential reflows
items.forEach(item => {
  const li = document.createElement('li');
  li.textContent = item.name;
  ul.appendChild(li); // each triggers layout check
});

// GOOD: DocumentFragment is off-DOM - no reflows during build
const fragment = document.createDocumentFragment();
items.forEach(item => {
  const li = document.createElement('li');
  li.textContent = item.name; // safe - no user input in innerHTML
  fragment.appendChild(li); // off-DOM, no reflow
});
ul.appendChild(fragment); // single DOM insertion, one reflow
```

> **Code walkthrough:** A DocumentFragment is an off-screen container
> not attached to the live document tree. Node insertions into it
> cause no layout recalculations. The single `appendChild` of the
> fragment moves all children into the DOM in one operation, one
> reflow regardless of list size. Critical for rendering large lists
> without visible jank.

---

### ⚖️ Comparison Table

| Method | Returns | Live? | Complexity | Best For |
|---|---|---|---|---|
| `getElementById` | Element or null | Yes | O(1) | Single element by id (hot paths) |
| `querySelector` | First match or null | No | O(n) | Any CSS selector, single result |
| `querySelectorAll` | Static NodeList | No | O(n) | Multiple elements, CSS selector |
| `getElementsByClassName` | Live HTMLCollection | Yes | Fast | Class-based, needs live updates |
| `getElementsByTagName` | Live HTMLCollection | Yes | Fast | Tag-based iteration |

**The deciding factor:**
Use `querySelector`/`querySelectorAll` for clarity; `getElementById`
for performance-critical paths where O(1) lookup matters.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> I use `querySelector` for CSS selector-based selection and
> `getElementById` for id-based. I use `textContent` over `innerHTML`
> for user data to avoid XSS. For class manipulation I use
> `classList.add/remove/toggle`. To add elements, `createElement`
> then `appendChild` or `insertAdjacentElement`.

*Push deeper:* Explain layout thrashing and the batch-reads-first pattern.
Describe why `querySelectorAll` returns a static snapshot.

---

**Senior / Staff (5+ years):**

> I treat DOM manipulation through a performance and security lens.
> Performance: batch layout reads before writes to avoid thrashing;
> use DocumentFragment for bulk insertions; cache element references
> rather than re-querying in hot paths. Security: `textContent` for
> any user data, `DOMPurify.sanitize()` if I must use `innerHTML`
> for user-provided HTML. I use `requestAnimationFrame` to align
> visual updates with the browser's render loop, not setTimeout.

*Push deeper:* Staff discuss MutationObserver for reactive patterns,
ResizeObserver for layout-responsive components, and how modern
frameworks solve these concerns through virtual DOM or signals.

---

### ⚠️ Common Misconceptions

**Misconception 1: `querySelectorAll` returns a live collection.**

It returns a static NodeList snapshot at query time. Adding elements
to the DOM afterward does not update it. `getElementsByClassName`
returns a live HTMLCollection. Iterating a live collection while
removing elements causes elements to be skipped (index shifts).

**Misconception 2: Layout thrashing only affects loops.**

A single read/write pair outside a loop still causes one forced layout.
The problem compounds in loops, but any `offsetHeight` read after a
style write without RAF triggers a synchronous layout flush.

**Misconception 3: `innerHTML = ''` is the fastest way to empty an element.**

`replaceChildren()` (modern browsers) or
`while (el.firstChild) el.removeChild(el.firstChild)` can be faster
for elements with many children, and the latter preserves detached
node references for debugging.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Layout thrashing causing frame drops.**

Symptom: DevTools Performance shows repeated alternating "Recalculate
Style" and "Layout" blocks within single frames; FPS drops below 60.

Diagnosis: Record in Performance tab; look for "Forced reflow" warning
in the "Summary" for layout events. Each forced reflow is a read
after a write.

Fix: Audit all layout-read properties (`offsetWidth`, `scrollTop`,
`getBoundingClientRect`, etc.) in loops and move them before the
write loop.

**Failure 2: XSS via innerHTML in a template string.**

Symptom: Unexpected JavaScript execution when displaying user content;
reported by security scanner.

Diagnosis: Search for `innerHTML` assignments where the assigned
value contains runtime data (function parameters, API responses,
URL parameters).

Fix: Replace with `textContent` for text values; for structured HTML
from user data, use `DOMPurify.sanitize(input)` before `innerHTML`.

**Failure 3: Stale reference after framework re-render.**

Symptom: `el.style.display = 'block'` has no visible effect;
`el.parentNode` is null.

Diagnosis: The element was replaced by a framework re-render.
The cached reference points to a detached node no longer in the DOM.

Fix: Re-query after re-renders; use data attributes + delegation
instead of caching leaf node references; let the framework own DOM
state rather than mixing direct manipulation with framework renders.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is the DOM? | Definition | ★☆☆ | 1 min |
| What is layout thrashing? How do you prevent it? | Mechanism | ★★☆ | 3 min |
| `textContent` vs `innerHTML` - when do you use each? | Comparison | ★★☆ | 2 min |
| Render a list of 10,000 items without jank | Scenario | ★★★ | 5 min |
| React app is directly manipulating DOM - what breaks? | Debugging | ★★☆ | 3 min |
| How does the browser's rendering pipeline relate to DOM mutations? | Deep Dive | ★★★ | 5 min |
| `querySelectorAll` returns a live NodeList you can watch for changes? | Misconception | ★★☆ | 2 min |
| How does DOM mutation cost scale at 60fps with 500 animated elements? | Performance | ★★★ | 4 min |
| You see alternating Layout/Recalculate in Performance trace. Explain. | Debugging | ★★☆ | 3 min |

**Q: What is layout thrashing and how do you fix it?**

A: Layout thrashing is when JavaScript forces the browser to
recalculate layout repeatedly within a single frame by interleaving
layout-reading properties (offsetHeight, getBoundingClientRect) with
style writes. Each read after a write forces a synchronous layout
flush, because the browser must recalculate to return accurate
dimensions given the pending writes.

The fix is always batching: collect all reads first, store them in
variables, then execute all writes. For cases where the pattern is
hard to batch manually, `requestAnimationFrame` aligns writes to
the next rendering frame boundary, and the FastDOM library provides
a read/write queue abstraction.

*What separates good from great:* The ability to name all the
layout-read properties that trigger flushes, not just `offsetHeight`.
The full list includes: `scrollTop/Left/Width/Height`, `offsetTop/Left/Width/Height`,
`clientTop/Left/Width/Height`, `getComputedStyle`, `getBoundingClientRect`,
`offsetParent`, `focus`, and more. Great engineers know this from
having debugged real layout thrashing in production.

**Q: How would you render 10,000 items efficiently?**

A: Three approaches by trade-off. DocumentFragment: buffer all
node creation off-DOM, single append. Fast insertion, but 10,000 DOM
nodes exist and must be maintained by the browser. Appropriate for
static displays up to ~5,000 items. Virtual scrolling: only render
the ~20 visible items. As the user scrolls, recycle DOM nodes by
updating content and position. Constant DOM node count regardless
of list size - the correct approach for very large or unlimited lists.
Libraries: `@tanstack/virtual`, `react-virtual`. Pagination: render
50-100 at a time, load more on demand. Simpler, appropriate for
bounded lists with natural page breaks.

*What separates good from great:* Knowing that DocumentFragment solves
insertion cost but not DOM maintenance cost. 10,000 DOM nodes exist
in the layout tree, accessibility tree, and event system regardless
of how they were inserted. The frame render cost for scrolling 10,000
items is non-trivial even after batch insertion.

---

# Event Bubbling, Capturing, and Delegation

🎯 **Interview Weight:** critical (★★☆) - Event delegation is the
most-tested DOM pattern in interviews; expected at all levels above
junior; passive listeners often tested at senior+

---

### 🎯 Model Answer

**30 seconds:**

> DOM events propagate in three phases: capture (root to target),
> target (the element itself), and bubble (target back to root).
> `addEventListener` defaults to the bubble phase. Event delegation
> leverages bubbling: attach one listener to a parent, identify the
> clicked child via `event.target.closest(selector)`. This is more
> memory-efficient than per-element listeners and works for
> dynamically added elements. `stopPropagation` stops bubbling;
> `preventDefault` stops the browser's default action - they are
> different and independent.

**3 minutes (Senior):**

> Event propagation has three sequential phases. Capture: event
> travels from `document` down the tree to the target. `{ capture: true }`
> listeners fire here - useful for intercepting events before they
> reach the target. Target: handlers on the element itself fire.
> Bubble: event travels back up; most listeners use this default phase.
>
> Event delegation exploits bubbling. One listener on a `<ul>` handles
> clicks on any `<li>`. The key implementation detail is
> `event.target.closest('li')` - not just `event.target === li`,
> because clicking an inner `<span>` makes `event.target` the `<span>`.
> `closest()` walks up the DOM from the click target to find the
> intended ancestor.
>
> I always use `{ passive: true }` on scroll and touch listeners.
> A non-passive touchstart listener forces the browser to wait for
> the JavaScript handler to complete before scrolling - even if
> `preventDefault` is never called. This is the primary cause of
> scroll jank on mobile. Marking passive tells the browser it can
> scroll immediately without waiting.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

*Adapting up:* Staff discuss React synthetic events (delegated to
root), shadow DOM event retargeting, and AbortController for listener
lifecycle management.

*Adapting down:* Junior: events bubble by default, `addEventListener`,
`event.target`, `stopPropagation` vs `preventDefault`.

**Blank Mind Recovery:**

**(1) Restate:** "Event bubbling - let me think through what
problem event propagation solves."

**(2) First principles:** "When a user clicks a nested element, the
click applies to every containing element. The browser needs a model
for handler order. Bubbling fires innermost-to-outermost..."

**(3) Bridge:** "This reminds me of CSS specificity - both systems
decide which rule applies when multiple elements respond to the same
action."

---

### 📘 Concept Explanation

**What it is:**

DOM events propagate through the document in three phases. Event
delegation is a pattern exploiting bubbling to handle multiple
elements with a single parent listener.

**The problem it solves:**

Attaching listeners to every element in a large list is expensive
in memory and does not work for dynamically added elements. Delegation
uses one listener for all current and future children.

**How it works:**

```
User clicks <span> inside <li> inside <ul>

CAPTURE (root → target):
  document → html → body → ul → li → span

TARGET (element itself):
  span - handlers with capture:true or default fire

BUBBLE (target → root):
  span → li → ul → body → html → document

Delegated handler on ul fires (bubble phase):
  event.target        = span (origin)
  event.currentTarget = ul (listener location)
  event.target.closest('li') → walks up → returns li
```

**The key insight:**

`event.target` is where the click actually originated. `event.currentTarget`
is where the listener is attached. In delegation these differ. Using
`closest(selector)` correctly handles inner-element clicks regardless
of DOM depth.

**When to use it:**

- Dynamic lists where items are added/removed at runtime
- Large lists (100+ items) where per-element listeners waste memory
- Any repeated interactive element pattern

**When NOT to use it:**

- When events must be contained within a component boundary - use
  `stopPropagation` to prevent unwanted delegation to ancestors
- Events that do not bubble: focus, blur, mouseenter, mouseleave

**Alternatives:**

- Direct per-element listeners → Simpler, O(n) memory, no dynamic support
- Pointer Events API → Unifies mouse/touch; still uses bubbling
- IntersectionObserver/ResizeObserver → Observe DOM changes without events

**First-principles derivation:**

When a user interacts with a nested element, the action logically
applies to every container. The bubble model (innermost-to-outermost)
matches user expectation - the closest handler to the action fires
first. Capture is available for cases requiring intercepting before
the target fires.

---

### 💻 Code Example

**Example 1: Event delegation with closest()**

```javascript
// BAD: O(n) listeners, breaks for dynamically added items
items.forEach(item => {
  const li = createLi(item);
  li.addEventListener('click', () => handleClick(item.id));
  ul.appendChild(li);
});

// GOOD: O(1) listener handles all items including future ones
ul.addEventListener('click', (event) => {
  // closest() walks up from click origin to find <li>
  // Handles clicks on inner <span>, <strong>, <img>
  const li = event.target.closest('li');
  if (!li || !ul.contains(li)) return; // guard against outside clicks
  handleClick(li.dataset.id); // id stored in data attribute
});

items.forEach(item => {
  const li = createLi(item);
  li.dataset.id = item.id; // data attribute for delegation
  ul.appendChild(li);
});
```

> **Code walkthrough:** One listener on `<ul>` handles all current
> and future list items. `closest('li')` walks up the DOM from the
> actual click target (which may be a child element) to find the
> nearest `<li>` ancestor. `ul.contains(li)` prevents false matches
> if `closest` walks up beyond the `<ul>`. Data attributes pass item
> identity without closure capture per-item.

**Example 2: stopPropagation vs preventDefault**

```javascript
// Modal: click inside should NOT close; click outside should
modal.addEventListener('click', (event) => {
  event.stopPropagation(); // prevent bubble to overlay
  // Does NOT prevent form submission, link nav, etc.
});

overlay.addEventListener('click', () => {
  closeModal(); // fires only when clicking outside modal
});

// Link: prevent default nav but allow event to bubble
link.addEventListener('click', (event) => {
  event.preventDefault(); // stops navigation
  // Event STILL bubbles - analytics listener on body fires
  trackClick(link.href);
});
```

> **Code walkthrough:** `stopPropagation` contains events within a
> component - clicking inside the modal does not trigger the overlay
> close handler. `preventDefault` cancels the browser's built-in
> reaction (navigation, form submit, checkbox toggle) while the event
> continues propagating. The two are independent and serve different
> purposes, though they are often confused.

**Example 3: Passive listeners for scroll performance**

```javascript
// BAD: browser must wait for handler before scrolling
window.addEventListener('touchstart', handleTouch);
window.addEventListener('scroll', updateNav);

// GOOD: passive:true allows immediate scroll without JS wait
window.addEventListener('touchstart', handleTouch, {
  passive: true // cannot call preventDefault - but that is fine
});
window.addEventListener('scroll', updateNav, {
  passive: true // scroll update UI does not need preventDefault
});

// once:true for initialization - auto-removed after first call
document.addEventListener('DOMContentLoaded', init, { once: true });

// AbortController for component lifecycle cleanup
const controller = new AbortController();
el.addEventListener('click', handleClick,
  { signal: controller.signal });
el.addEventListener('keydown', handleKey,
  { signal: controller.signal });
// Cleanup: removes ALL listeners registered with this signal
controller.abort();
```

> **Code walkthrough:** `{ passive: true }` tells the browser the
> handler will never call `preventDefault`, allowing immediate scroll
> on the compositor thread without waiting for JavaScript. This is
> the fix for scroll jank on mobile touchstart/touchmove listeners.
> `AbortController` provides component-level listener lifecycle
> management - one `abort()` removes all listeners registered with
> that signal, eliminating individual `removeEventListener` bookkeeping.

---

### ⚖️ Comparison Table

| Approach | Memory | Dynamic elements | Use When |
|---|---|---|---|
| **Event delegation** | O(1) | Yes | Large/dynamic lists, repeated elements |
| Direct per-element | O(n) | No (manual re-attach) | Small, static, unique elements |
| Capture phase listener | O(1) | Yes | Must intercept before target fires |
| AbortController cleanup | O(1)+lifecycle | Yes | Components with mount/unmount lifecycle |

**The deciding factor:**
Delegation for repeated or dynamic elements; direct listeners for
unique, stable elements like a single nav close button.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Events bubble from the clicked element up to the document by default.
> I use event delegation by attaching one listener to a parent and
> checking `event.target` to know which child was clicked. I use
> `event.target.closest(selector)` when the clickable element has
> inner elements. `stopPropagation` stops bubbling up; `preventDefault`
> stops browser defaults like navigation or form submission.

*Push deeper:* Describe all three propagation phases. Explain what
`event.currentTarget` is versus `event.target` in delegation.

---

**Senior / Staff (5+ years):**

> My default for repeated or dynamic elements is event delegation
> with `closest()`. For all scroll and touch listeners I use
> `{ passive: true }` - this is the primary mobile scroll jank fix.
> I use `AbortController` for component cleanup instead of tracking
> individual `removeEventListener` calls. The subtle failure mode
> in delegation is shadow DOM: events re-target at shadow boundaries,
> so `event.target` inside a shadow root is the shadow host from
> outside, breaking delegation assumptions.

*Push deeper:* Staff discuss React synthetic event delegation, custom
events with `{ bubbles: true, composed: true }` for shadow DOM
crossing, `stopImmediatePropagation`, and pointer events unification.

---

### ⚠️ Common Misconceptions

**Misconception 1: `stopPropagation` and `preventDefault` are the same.**

`stopPropagation` stops the event traveling through the DOM tree.
`preventDefault` cancels the browser's default action. They are
completely independent. `stopImmediatePropagation` additionally
prevents other listeners on the same element from firing.

**Misconception 2: All events bubble.**

Focus, blur, mouseenter, and mouseleave do NOT bubble. Use `focusin`,
`focusout`, `mouseover`, `mouseout` for delegation on those events.
This is a common source of "why doesn't my delegation work?" bugs.

**Misconception 3: Capture phase is rarely needed.**

Capture is essential for: intercepting events before a third-party
widget handles them; implementing accessibility keyboard navigation
that must fire before input handlers; global keyboard shortcut
systems that need priority over component-level handlers.

---

### 🚨 Failure Modes and Diagnosis

**Failure 1: Delegation broken by inner elements.**

Symptom: Clicking inside a list item does nothing; delegation handler
returns early.

Diagnosis: `event.target` is an inner `<span>` or `<img>`;
`event.target.tagName === 'LI'` check fails.

Fix: Replace `event.target.tagName === 'LI'` with
`event.target.closest('li')`.

**Failure 2: Scroll jank on mobile.**

Symptom: Choppy scroll on iOS/Android; DevTools shows "Added
non-passive event listener to a scroll-blocking event."

Diagnosis: `touchstart` or `touchmove` listener registered without
`{ passive: true }`.

Fix: Add `{ passive: true }` to all scroll-related listeners. If
`preventDefault` is needed for drag logic, keep non-passive but
minimize handler execution time.

**Failure 3: Memory leak from unremoved listeners.**

Symptom: Growing heap; detached DOM nodes in heap snapshot.

Diagnosis: Elements removed from DOM still have active listeners
holding closure references, preventing GC.

Fix: Use `AbortController` signal with all listeners in a component;
call `abort()` on component destruction.

---

### 🎯 Interview Deep-Dive

| Question | Type | Difficulty | Time |
|---|---|---|---|
| What is event bubbling? | Definition | ★☆☆ | 1 min |
| Explain all three phases of DOM event propagation | Mechanism | ★★☆ | 2 min |
| Event delegation vs direct listeners - when does each win? | Comparison | ★★☆ | 2 min |
| Implement delegation for a dynamic table with delete buttons | Scenario | ★★☆ | 5 min |
| Mobile users report scroll jank. You see touchstart listeners. Fix it. | Debugging | ★★☆ | 3 min |
| How does React synthetic events relate to native DOM propagation? | Deep Dive | ★★★ | 4 min |
| "stopPropagation and preventDefault are the same thing." | Misconception | ★★☆ | 2 min |
| Delegation with 100,000 items - does bubbling add latency? | Performance | ★★☆ | 2 min |
| How does shadow DOM affect event.target in a delegated handler? | Deep Dive | ★★★ | 4 min |

**Q: Explain the three phases of DOM event propagation.**

A: Phase 1 is capture: the event travels from `document` down to
the target element. Handlers registered with `{ capture: true }` fire
here. This is used to intercept events before the target's own
handlers fire - useful for global keyboard shortcuts or accessibility
systems. Phase 2 is target: handlers registered on the element itself
fire here, regardless of capture/bubble registration. Phase 3 is
bubble: the event travels back up from the target to `document`.
Default `addEventListener` handlers fire during this phase.

The most important implication: events on an inner element bubble
through all its ancestors. A click on a `<span>` fires handlers on
the `<span>`, then `<div>`, then `<section>`, then `<body>`, then
`<html>`, then `document`. Event delegation exploits this to handle
all descendant events from a single ancestor listener.

*What separates good from great:* Knowing which events do not bubble
(focus, blur, mouseenter) and why - they were designed for element-
level notification without informing ancestors, as opposed to actions
like click that naturally propagate up the containment hierarchy.

**Q: How does React's synthetic event system relate to DOM propagation?**

A: React delegates all event listening to a single listener on the
React root container (changed from `document` in React 17). When a
click fires and bubbles to the root, React's single listener processes
it and dispatches `SyntheticEvent` objects to the appropriate
component handlers, simulating the propagation order of the React
component tree.

The implication: if you call `event.stopPropagation()` in a native
listener registered via `addEventListener` below the root, the event
never reaches React's root listener, and React component handlers
never fire. This causes confusing bugs when mixing native DOM listeners
with React event props. The fix: use React event props exclusively
for React components; avoid `addEventListener` on elements managed
by React.

*What separates good from great:* Knowing the React 17 change was
specifically to support multiple React roots on one page (micro-
frontends) without event listener collision between roots.

**Q: Memory leak from event listeners - how do you diagnose and fix it?**

A: Diagnosis: Chrome DevTools heap snapshot. Take one at baseline,
interact to mount/unmount components, take another. Filter by
"Objects allocated between snapshots" - look for EventListener
and HTMLElement objects with unexpected counts. The retained size
shows what else the listener is keeping alive through closures.

Fix with AbortController: `const c = new AbortController(); el.addEventListener('click', handler, { signal: c.signal }); return () => c.abort();`
One `abort()` removes all listeners registered with that signal.
In React: `useEffect(() => { const c = new AbortController(); ... return () => c.abort(); }, []);`

*What separates good from great:* Understanding that the listener
itself is not what leaks memory - it is the closure over component
state variables that keeps the entire component's variable scope
alive in memory. The EventListener is the root; the retained size
includes everything the closure references.
