---
layout: default
title: "CSS - L1 Selectors and Properties"
parent: "CSS"
nav_order: 2
permalink: /css/l1-selectors-and-properties/
---

# CSS Selectors

🎯 **Interview Weight:** high - tested in every frontend
interview; selector knowledge reveals CSS depth and
specificity awareness

---

### 🎯 Model Answer

**30 seconds:**

> CSS selectors are patterns that match HTML elements so style
> rules can be applied to them. They range from simple element
> selectors (`h1`) to complex combinators and pseudo-classes
> (`.nav > li:first-child`). The selector choice directly
> controls specificity: ID selectors score highest, class
> selectors mid, element selectors lowest. Choosing the right
> selector is a CSS architecture decision, not just syntax.

**3 minutes (Senior):**

> Selectors are the CSS mechanism for targeting HTML elements.
> They fall into six categories: element/type selectors (`h1`,
> `div`), class selectors (`.card`), ID selectors (`#header`),
> attribute selectors (`[type="text"]`), pseudo-classes
> (`:hover`, `:nth-child()`), and pseudo-elements (`::before`,
> `::after`). Combinators connect selectors: descendant (space),
> child (`>`), adjacent sibling (`+`), general sibling (`~`).
>
> Selector choice affects specificity and performance. ID
> selectors score (1,0,0) - extremely hard to override.
> Class selectors score (0,1,0). Element selectors (0,0,1).
> In a maintainable codebase, class-only selectors are the
> standard because they're low and consistent specificity.
>
> Modern selectors have expanded significantly. `:is()` takes
> a selector list and applies the highest specificity of its
> arguments. `:where()` is the same but always zero specificity
> - ideal for default styles that should be easily overridden.
> `:has()` is the parent selector CSS never had - it matches
> an element based on its descendants: `form:has(:invalid)`
> targets a form containing an invalid field.
>
> Performance: CSS selector performance matters far less than
> JS performance, but complex descendant selectors (many
> levels deep) are slower because browsers match right-to-left.
> `div p span a` is evaluated as "all `a` elements, filter
> those inside `span`, filter those inside `p`, filter those
> inside `div`" - the broadest selector (`a`) runs first.

*Adapting up:* Discuss `:has()`, container queries using
@container, and selector performance at scale.

*Adapting down:* `.class` targets by class, `#id` by id,
`element` by tag name.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about CSS selectors - let
me walk through how we target elements for styling."

**(2) First principles:** "From first principles, CSS needs
a way to say 'apply this style to THIS element but not THAT
one.' Selectors are that targeting language."

**(3) Bridge:** "Think of selectors like SQL WHERE clauses.
`.card:hover` is like WHERE class='card' AND state='hovered'."

---

### 📘 Concept Explanation

**What it is:**

CSS selectors are patterns used in CSS rules to match HTML
elements. Every CSS rule starts with a selector (or selector
list) that determines which elements receive the declarations
in that rule's block.

**The problem it solves:**

You need to apply different styles to different elements.
A selector provides precise targeting without modifying HTML,
maintaining separation of concerns.

**How it works:**

```
SELECTOR TYPES:

Type:        h1 { }         (0,0,1)
Class:       .card { }      (0,1,0)
ID:          #nav { }       (1,0,0)
Attribute:   [type=text]{}  (0,1,0)
Pseudo-class:.hover { }     (0,1,0)
Pseudo-elem: ::before { }   (0,0,1)

COMBINATORS:
" " descendant: .nav a    (any a inside .nav)
">" child:      .nav > a  (direct a children)
"+" adjacent:   h1 + p    (p immediately after h1)
"~" sibling:    h1 ~ p    (all p after h1)

MODERN:
:is(.a, .b)  - matches either, highest arg specificity
:where(.a,.b)- same but zero specificity
:has(.child) - parent selector, matches by descendant
:not(.skip)  - negation
```

**The key insight:**

Browsers match CSS selectors right-to-left for performance.
The rightmost part of a selector is the "key selector" -
it's matched first, then ancestor conditions are checked.
A complex ancestor chain doesn't slow down elements that
don't match the key selector at all.

**When to use it:**

Use class selectors as the default for styling. Use attribute
selectors for form inputs and data attributes. Use pseudo-
classes for state and structural targeting.

**When NOT to use it:**

Avoid deep descendant chains (`div > ul > li > a > span`)
that create fragile CSS tightly coupled to HTML structure.
Avoid ID selectors for styling (too high specificity).

**Alternatives:**

- CSS Modules: generates unique class names, no need for
  complex selectors to avoid conflicts
- BEM methodology: flat single-class selectors by convention
- Tailwind: utility classes, almost no CSS selectors needed

**First-principles derivation:**

Given the constraint: one CSS file targeting many HTML
elements with different style requirements. You need a
query language for HTML elements. The minimum requirements:
target by element type, by identity, by relationship
to other elements, by state. CSS selectors satisfy all four.

---

### 💻 Code Example

**BAD: tightly coupled, high-specificity selectors**

```css
/* BAD: fragile - breaks if HTML structure changes */
/* BAD: high specificity - hard to override */
#sidebar div.nav ul li a {
  color: blue;
  /* specificity: (1,1,3) */
}

/* Must escalate to override */
#sidebar div.nav ul li a.active {
  color: red;   /* (1,2,3) - specificity war */
}
```

> **Code walkthrough:** This selector is fragile on two levels.
> It's tightly coupled to the HTML structure - add a wrapper
> `div` and it breaks. It uses an ID, making it nearly
> impossible to override from component stylesheets without
> !important or matching specificity.

**GOOD: class-based, low specificity**

```css
/* GOOD: class-based, resilient, overridable */
.nav-link {
  color: blue;  /* (0,1,0) */
}

.nav-link--active {
  color: red;   /* (0,1,0) - source order determines winner */
}

/* Need to win? Add one more class */
.nav-link.nav-link--active {
  color: red;   /* (0,2,0) - explicit override */
}
```

> **Code walkthrough:** Single-class selectors are low
> specificity (0,1,0) and resilient to HTML restructuring.
> BEM-style naming (block__element--modifier) documents
> intent. When you need to override, add one class to
> increase specificity precisely by one step.

**PRODUCTION: modern pseudo-class usage**

```css
/* :has() - style parent based on child state */
.form-group:has(input:invalid) {
  border-color: red;
  /* Applied to form-group when input is invalid */
}

/* :is() - group selectors without repeating */
:is(h1, h2, h3) > a {
  /* Links directly inside any heading */
  text-decoration: none;
}

/* :where() - zero specificity defaults */
:where(ul, ol) {
  margin: 0;  /* Overridable by ANY selector */
  padding: 0;
}
```

> **Code walkthrough:** `:has()` finally gives CSS a parent
> selector - something CSS lacked for decades. `:is()` reduces
> repetition when you need to apply the same rule to multiple
> selectors. `:where()` is ideal for CSS resets or design
> system defaults because its zero specificity means any
> consumer rule overrides it without specificity conflicts.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> CSS selectors are patterns that target HTML elements for
> styling. Basic types are element selectors like `h1`, class
> selectors like `.card`, and ID selectors like `#header`.
> You can combine them - `.nav > a` means direct `a` children
> of `.nav`. Pseudo-classes add state targeting: `a:hover`
> for mouse-over, `:first-child` for first siblings. The
> choice of selector affects specificity - IDs are highest,
> classes mid, elements lowest - which determines which rule
> wins when two rules conflict.

*Push deeper:* Discuss modern selectors like `:is()`,
`:where()`, and `:has()`.

---

**Senior / Staff (5+ years):**

> Selectors are the CSS targeting language. The architecture
> decision is specificity management: I use class selectors
> as the default (0,1,0) because they're consistently
> overridable. Deep descendant selectors are fragile and
> couple CSS to HTML structure unnecessarily.
>
> Modern selectors changed the calculus significantly.
> `:has()` - the parent selector - enables patterns like
> styling a form when any child input is invalid, or
> styling a card layout differently when it has an image.
> Before `:has()`, this required JavaScript to add modifier
> classes. `:where()` with zero specificity is the right
> tool for design system defaults that must never compete
> with component styles. For large teams, CSS Modules or
> CSS-in-JS eliminate selector scope problems entirely by
> generating unique class names per component.

---

### ⚠️ Common Misconceptions

**"More specific selectors are better - they're more targeted"**

More specific selectors are harder to override, causing
specificity wars. The goal is consistent, low specificity
that you can predict and override when needed.

**"Descendant combinators (spaces) are just style"**

Deep descendant chains couple your CSS to your HTML structure.
If the HTML wraps in an extra `div`, the selector breaks.
BEM-style flat classes decouple them.

**":first-child and :first-of-type are the same"**

`:first-child` matches an element only if it is the first
child of its parent. `:first-of-type` matches the first
element of its type among siblings. `p:first-child` only
matches a `p` that is literally the first child (even if
siblings aren't `p` elements). `p:first-of-type` matches
the first `p` among siblings regardless of position.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: selector matches wrong elements**

Diagnosis:
```
# DevTools Elements panel:
# Right-click element > Force State to test pseudo-classes
# Use ctrl+F in Elements panel to test your selector
# e.g. type ".nav > a" - DevTools highlights all matches
```

---

**Symptom: :has() not working**

Cause: Browser not supporting `:has()` (needs Chrome 105+,
Safari 15.4+, Firefox 121+).

Fix: Check caniuse.com; add JS fallback or feature query:
```css
@supports selector(:has(a)) {
  .container:has(.active) { /* ... */ }
}
```

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| "Types of CSS selectors" | 2-3 min | All 6 types + combinators |
| "What is specificity?" | 2-3 min | Three-column score |
| Debugging a non-matching rule | 3-4 min | DevTools selector test |
| ":has() use cases" | 3-4 min | Parent selector patterns |
| Performance discussion | 3 min | Right-to-left matching |

---

**Q1: What types of CSS selectors exist?** `[JUNIOR]`
CONCEPTUAL

*Why they ask:* Establishes CSS foundation; tests vocabulary
and whether they know beyond basics.

*Likely follow-up:* "What's the difference between class
and ID selectors?"

> **Answer:**
>
> CSS selectors fall into six categories.
>
> Type selectors target elements by tag name: `h1`, `p`,
> `div`. They have the lowest specificity (0,0,1) and should
> rarely be used for component styling.
>
> Class selectors target by class attribute: `.card`,
> `.btn-primary`. Specificity (0,1,0). The standard choice
> for component styling.
>
> ID selectors target a unique element: `#navbar`. Specificity
> (1,0,0). Avoid for styling - use for JavaScript hooks.
>
> Attribute selectors target by attribute: `[type="email"]`,
> `[data-theme="dark"]`. Specificity (0,1,0). Useful for
> form elements and data attributes.
>
> Pseudo-classes target state or structure: `:hover`,
> `:focus`, `:nth-child(2n+1)`, `:is()`, `:has()`.
> Specificity (0,1,0) for most.
>
> Pseudo-elements target sub-parts of elements: `::before`,
> `::after`, `::placeholder`, `::selection`. Specificity
> (0,0,1).
>
> Combinators connect selectors: space (descendant), `>`
> (direct child), `+` (adjacent sibling), `~` (general
> sibling).
>
> *What separates good from great:* Mentioning `:has()` -
> it's the "parent selector" CSS lacked for 25 years,
> matching an element based on what it contains. This is
> a significant CSS capability unlocked recently.

---

**Q2: My CSS selector isn't matching. How do I debug it?**
`[MID]` DEBUGGING

*Why they ask:* Selector debugging is a daily skill.

*Likely follow-up:* "What does strikethrough on a property
mean in DevTools?"

> **Answer:**
>
> DevTools has a built-in selector tester. In the Elements
> panel, press Ctrl+F (or Cmd+F on Mac). Type your selector.
> DevTools highlights all matching elements in the DOM and
> shows a count. This immediately tells you if your selector
> is syntactically valid and what it matches.
>
> Common reasons a selector doesn't match:
>
> 1. Typo in class name: `.crad` instead of `.card`.
>    Check: inspect the element and look for its actual
>    class attribute in the HTML panel.
>
> 2. Structural mismatch: `.nav > a` requires `a` to be
>    a direct child - if there's a wrapper `span` between
>    `.nav` and `a`, the `>` child combinator fails. Use
>    the descendant combinator (space) instead or fix the
>    selector.
>
> 3. Pseudo-class state: `:hover` styles won't show in
>    the Styles panel because the element isn't hovered
>    while you're inspecting. Use DevTools' "Force element
>    state" (`:hov` button) to simulate hover/focus/active.
>
> 4. Specificity lost: the selector matches but a higher-
>    specificity rule overrides it. The Styles panel shows
>    your rule with strikethrough and the winning rule above.
>
> *What separates good from great:* Knowing that CSS selector
> matching is right-to-left. `.nav a` first finds all `a`
> elements in the DOM, then checks which ones are inside
> `.nav`. If you have 1000 `a` elements but only 10 are
> inside `.nav`, the browser still starts with all 1000.
> This is why key selectors (the rightmost part) should be
> specific.

---

**Q3: What is :has() and why was it a big deal?** `[SENIOR]`
MECHANISM

*Why they ask:* Tests awareness of modern CSS evolution.

*Likely follow-up:* "Name three real-world use cases for :has()"

> **Answer:**
>
> `:has()` is a relational pseudo-class that matches an element
> based on what it contains. Before it, CSS could only style
> elements based on their own properties or their ancestors -
> never based on their descendants.
>
> It was significant because CSS previously lacked any parent
> selector. The `:has()` feature request was filed in 2012 and
> took over a decade to implement because of circular
> dependency concerns in the CSS engine - if styles could
> depend on descendants, could descendants affect ancestors
> which re-style descendants infinitely? The implementation
> required cycle-detection algorithms.
>
> Real-world use cases:
>
> 1. Form validation styling: `form:has(:invalid)` - apply
>    a red border to the entire form when any field is invalid,
>    without JavaScript adding a class.
>
> 2. Card layout adaptation: `.card:has(img)` - cards with
>    images get different padding/layout than text-only cards.
>
> 3. Navigation state: `.nav:has(.active)` - highlight the
>    entire nav when any child is active.
>
> 4. Structural patterns: `section:has(> h2)` - sections
>    directly containing an h2 (not nested h2s).
>
> *What separates good from great:* Knowing the performance
> implications. `:has()` is evaluated after layout in some
> cases, which can force reflow. Browsers have optimized
> most common uses but complex `:has()` chains in tight loops
> can cause performance issues.

---

**Q4: How do CSS combinators work?** `[JUNIOR]` MECHANISM

*Why they ask:* Fundamental CSS knowledge; tests whether
they understand structural relationships.

*Likely follow-up:* "What's the difference between + and ~?"

> **Answer:**
>
> CSS combinators express structural relationships between
> elements.
>
> Descendant combinator (space): `.nav a` matches any `a`
> element that is a descendant (child, grandchild, etc.) of
> `.nav`. This is the most permissive - any depth.
>
> Child combinator (`>`): `.nav > a` matches only `a` elements
> that are DIRECT children of `.nav`. `a` elements nested
> deeper are not matched.
>
> Adjacent sibling combinator (`+`): `h2 + p` matches a `p`
> element that is the IMMEDIATELY FOLLOWING sibling of an
> `h2`. Only one element is matched.
>
> General sibling combinator (`~`): `h2 ~ p` matches all `p`
> elements that follow an `h2` as siblings (not children).
> Multiple elements can match.
>
> Practical example:
> - `.card > .title` styles only direct title children (not
>   nested titles inside the card body).
> - `input + label` styles a label immediately after an input
>   (useful for checkbox/radio layouts).
> - `h2 ~ p` styles all paragraphs following a section heading.
>
> *What separates good from great:* The Column combinator
> (`||`) targets cells in a specific column of a CSS Grid -
> rarely used but shows advanced knowledge. Also knowing
> that the `:is()` pseudo-class can combine selector groups:
> `:is(h1,h2,h3) + p` is cleaner than repeating the full
> rule three times.

---

**Q5: When should you use attribute selectors?** `[MID]`
TRADE-OFF

*Why they ask:* Tests knowledge of less-common but important
selector type.

*Likely follow-up:* "What's the performance difference
between class and attribute selectors?"

> **Answer:**
>
> Attribute selectors are most useful for three scenarios.
>
> First, form elements: `input[type="email"]`, `input
> [type="checkbox"]`, `input[disabled]`. These avoid needing
> to add extra classes to form inputs.
>
> Second, data attributes for JS-driven state: when JS sets
> `data-state="loading"` on a button, CSS can respond with
> `[data-state="loading"] { opacity: 0.5; cursor: wait; }`
> without JavaScript having to manage classes.
>
> Third, external links and download detection:
> `a[href^="https"]` (href starts with https),
> `a[href$=".pdf"]` (href ends with .pdf),
> `a[download]` (has download attribute). These let you
> style links based on their destination without classes.
>
> Attribute selectors have the same specificity as class
> selectors (0,1,0). Performance is slightly lower than class
> selectors because the browser must read attribute values
> rather than just checking the class list, but the difference
> is negligible in practice.
>
> The case against over-using them: they couple CSS to HTML
> attribute structure. If the attribute name or value
> format changes, CSS breaks silently.
>
> *What separates good from great:* Knowing the substring
> matching variants: `[attr^=val]` starts with, `[attr$=val]`
> ends with, `[attr*=val]` contains, `[attr~=val]` contains
> word, `[attr|=val]` equals or starts with hyphen variant
> (for language codes like `lang|=en`).

---

**Q6: What are pseudo-elements and when do you use them?**
`[MID]` MECHANISM

*Why they ask:* Pseudo-elements like ::before/::after are
widely used but often misunderstood.

*Likely follow-up:* "What is the content property for?"

> **Answer:**
>
> Pseudo-elements create virtual elements that CSS can style
> without adding HTML. `::before` inserts a virtual element
> as the first child; `::after` inserts one as the last child.
> Both require a `content` property (even `content: ""` for
> visual-only elements).
>
> Common uses:
>
> 1. Decorative content: `h2::before { content: "> "; }` adds
>    a visual prefix without modifying HTML.
>
> 2. Custom list markers or icons: `li::before { content: "•";
>    color: blue; }` replaces the default bullet.
>
> 3. Clearfix: `.container::after { content: ""; display:
>    table; clear: both; }` - the classic float-clearing trick.
>
> 4. Overlay: `::before` with `position: absolute; inset: 0`
>    creates a full-cover overlay for hover effects or dimming.
>
> Other pseudo-elements: `::placeholder` styles input
> placeholder text; `::selection` styles highlighted text;
> `::first-line` and `::first-letter` for typographic effects.
>
> Accessibility note: `content` on `::before`/`::after` is
> read by some screen readers. If the content is decorative,
> use `content: "" / ""` (the second part is the
> alt text - empty means skip for screen readers).
>
> *What separates good from great:* The `content` property
> can also counter(`name`), url(), attr() - the last is
> powerful: `a::after { content: " (" attr(href) ")"; }`
> appends the URL after each link in print stylesheets.

---

**Q7: How do nth-child selectors work?** `[SENIOR]`
MECHANISM

*Why they ask:* nth-child patterns come up frequently for
table striping, grid layouts, and list styling.

*Likely follow-up:* "What's the difference between
nth-child and nth-of-type?"

> **Answer:**
>
> `:nth-child(n)` selects elements based on their position
> among siblings. The argument is an `An+B` formula.
>
> Common patterns:
> - `:nth-child(2)` - second child exactly
> - `:nth-child(odd)` or `:nth-child(2n+1)` - odd positions
> - `:nth-child(even)` or `:nth-child(2n)` - even positions
> - `:nth-child(3n)` - every third element (3, 6, 9...)
> - `:nth-child(3n+1)` - first of every group of three
> - `:nth-child(-n+3)` - first three (n=0,1,2 give 3,2,1)
>
> The formula `An+B`: A is the cycle size, B is the offset.
> For `3n+1`: when n=0 -> 1st, n=1 -> 4th, n=2 -> 7th.
>
> `:nth-child` vs `:nth-of-type`:
> `:nth-child(2)` selects the element if it IS the second
> child among ALL siblings regardless of type.
> `p:nth-child(2)` matches a `p` element ONLY if it is the
> second child (not the second paragraph).
>
> `p:nth-of-type(2)` matches the SECOND `p` element among
> siblings, regardless of what other element types are
> mixed in.
>
> Modern CSS 4 adds `:nth-child(2 of .active)` - the nth
> element matching `.active`, not just the nth child.
>
> *What separates good from great:* `:last-child` is often
> used for removing the last item's separator (bottom border,
> margin). CSS `:not(:last-child)` can style all-but-last:
> `li:not(:last-child) { border-bottom: 1px solid #eee; }`.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Walk through specificity scores for given selectors |
| Hiring Manager | Frame as "the mechanism that makes CSS maintainable" |
| Bar Raiser | Discuss :has() implementation challenges and use cases |
| Peer Engineer | Talk about your real methodology for organizing selectors |

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ foundational keyword - selector comparison is
covered within Concept Explanation and the Interview Deep-Dive)*

---

### 🏛️ System Design

*(Omit: ★☆☆ foundational keyword - not architecture-level)*

---

### 📊 Diagram

*(Omit: prose and code examples sufficiently explain CSS
selectors without requiring a diagram)*

---
---

# CSS Units and Values

🎯 **Interview Weight:** high - CSS unit choice is a daily
decision with major responsive design and accessibility
implications; tested at all seniority levels

---

### 🎯 Model Answer

**30 seconds:**

> CSS units fall into two categories: absolute (`px`, `pt`,
> `cm`) and relative (`em`, `rem`, `%`, `vw`, `vh`). The
> critical interview point: `rem` is relative to the root
> font size (scales with user accessibility preferences),
> `em` is relative to the element's own font size (compounds
> with nesting), and `px` ignores user font size preferences.
> Modern CSS uses `rem` for typography and `px` for borders,
> shadows, and small decorative values.

**3 minutes (Senior):**

> CSS units determine how a value is interpreted by the
> browser. Absolute units like `px` are fixed to physical
> pixels (at 1:1 on non-HiDPI screens). Relative units are
> computed relative to something else.
>
> `em` is relative to the element's current `font-size`.
> This means it compounds with nesting: if `.parent` has
> `font-size: 1.2em` and `.child` also has `font-size: 1.2em`,
> the child's font is 1.44x the root size. This compounding
> makes `em` useful for components that should scale
> proportionally (set padding in `em` - it scales with the
> font), but dangerous for general layout.
>
> `rem` (root em) is always relative to the `:root` element's
> font size (default 16px in all browsers). It doesn't
> compound. This makes it the right unit for typography and
> any sizing that should scale with user accessibility
> preferences. If a user sets their browser font to 20px,
> `1rem` becomes 20px everywhere consistently.
>
> `%` is relative to the parent element's corresponding
> dimension. `width: 50%` is half the parent's width.
> `font-size: 150%` is 1.5x the parent's font-size.
>
> Viewport units: `vw` (1% of viewport width), `vh` (1% of
> viewport height), `svh`/`dvh` (small/dynamic viewport
> height - accounts for mobile browser chrome), `vmin`/`vmax`.
>
> CSS custom properties and `calc()` enable computed values:
> `calc(100% - 2rem)` is a fluid value. Clamp is the modern
> responsive typography tool: `font-size: clamp(1rem, 2.5vw,
> 2rem)` scales with viewport but never below 1rem or above
> 2rem.

*Adapting up:* Discuss CSS `calc()`, `clamp()`, `min()`,
`max()`, logical properties, and container query units.

*Adapting down:* `px` is fixed, `rem` and `em` scale with
font size.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about CSS units - let me
walk through the key distinction between fixed and relative
values."

**(2) First principles:** "From first principles, layout
values can either be fixed (always the same pixel count)
or relative (scale with something else). Which to use
depends on what should scale."

**(3) Bridge:** "Think of rem like a newspaper's column
width in 'characters wide' - it scales with the font size.
px is like inches - always the same regardless of font size."

---

### 📘 Concept Explanation

**What it is:**

CSS units are the measurement systems attached to CSS
property values. They determine how a numerical value is
interpreted - as absolute pixels, as a proportion of
the parent, as a proportion of viewport, or as a multiple
of font size.

**The problem it solves:**

Web pages display on screens of wildly different sizes
(mobile to 4K desktop) and must respect user accessibility
preferences (font size settings). Fixed pixel values produce
rigid layouts that break at extremes. Relative units enable
responsive, accessible designs.

**How it works:**

```
ABSOLUTE UNITS:
  px  - CSS pixel (device-independent)
  pt  - 1/72 inch (print)
  cm, mm, in - physical (print only)

RELATIVE TO FONT:
  em  - relative to CURRENT element font-size
  rem - relative to :root font-size (16px default)
  ch  - width of "0" character in current font
  ex  - height of lowercase "x" in current font

RELATIVE TO VIEWPORT:
  vw  - 1% of viewport width
  vh  - 1% of viewport height
  svh - small viewport height (mobile URL bar hidden)
  dvh - dynamic viewport height (changes with UI)
  vmin/vmax - smaller/larger of vw and vh

RELATIVE TO PARENT:
  % - depends on property:
      width/height: % of parent's same dimension
      font-size: % of parent's font-size
      transform: % of element's own size

MODERN MATH:
  calc(100% - 64px)
  min(300px, 100%)
  max(1rem, 2vw)
  clamp(min, preferred, max)
```

**The key insight:**

`rem` is the accessibility-safe font size unit because it
respects user browser font size preferences. Using `px` for
font sizes overrides those preferences. WCAG 1.4.4 (AA)
requires text to be resizable to 200% - `rem`-based layouts
support this automatically; `px`-based layouts often break.

**When to use it:**

- Typography: `rem` (scales with user preferences)
- Component padding/margin relative to its font: `em`
- Responsive layout: `%` or `vw`/`vh`
- Borders, shadows, small decorative details: `px`
- Responsive typography: `clamp()` with `rem`/`vw`

**When NOT to use it:**

Avoid `px` for font sizes (accessibility). Avoid `em` for
general layout sizing (compounding causes surprises). Avoid
`vh` for mobile full-screen (mobile browser chrome makes it
unreliable - use `svh` or `dvh` instead).

**Alternatives:**

- CSS container query units (`cqw`, `cqh`) - relative to
  container, not viewport
- Logical properties (`inline-size`, `block-size`) - work
  in writing-mode-independent ways

**First-principles derivation:**

Given constraint: styles must work across screen sizes
and honor user accessibility settings. Fixed units (px)
can't adapt. You need a relative unit system. The two
most useful bases are: the viewport (for layout) and
the font size (for typography). `rem` and `vw`/`vh` are
the canonical expressions of these two bases.

---

### 💻 Code Example

**BAD: px everywhere (common in legacy CSS)**

```css
/* BAD: accessibility failure */
body { font-size: 14px; }  /* ignores user prefs */
h1   { font-size: 28px; }  /* doesn't scale */
p    { font-size: 16px; }
.container { width: 960px; } /* breaks on mobile */
```

> **Code walkthrough:** All `px` values are immune to user
> font size preferences. A user who sets their browser font
> to 24px (common for low vision) gets no benefit - all text
> stays at the declared pixel size. The fixed container width
> causes horizontal scroll on mobile.

**GOOD: rem-first, responsive units**

```css
/* GOOD: accessibility-respecting unit hierarchy */
:root {
  font-size: 100%;    /* inherits user browser preference */
}

h1 { font-size: 2rem; }   /* 2x root - scales with user */
p  { font-size: 1rem; }   /* 1x root */
small { font-size: 0.875rem; } /* 87.5% of root */

.container {
  width: min(960px, 100% - 2rem); /* fluid with max */
  margin-inline: auto;
}
```

> **Code walkthrough:** Setting `:root { font-size: 100% }`
> inherits the browser's user-configured font size (default
> 16px, but user may have changed it). All `rem` values then
> scale proportionally. `min(960px, 100% - 2rem)` is the
> modern idiom for "max-width with padding" - no media query
> needed.

**PRODUCTION: responsive typography with clamp**

```css
/* Modern fluid typography - no media query breakpoints */
:root {
  --fs-sm:   clamp(0.875rem, 0.8rem + 0.35vw, 1rem);
  --fs-base: clamp(1rem,     1rem  + 0.5vw,   1.25rem);
  --fs-lg:   clamp(1.25rem,  1.2rem + 0.7vw,  1.75rem);
  --fs-xl:   clamp(1.75rem,  1.5rem + 1.25vw, 2.5rem);
}

h1 { font-size: var(--fs-xl); }
p  { font-size: var(--fs-base); }
```

> **Code walkthrough:** `clamp(min, preferred, max)` creates
> fluid values that scale linearly between a minimum (at small
> viewports) and maximum (at large viewports). The middle
> value is the preferred scale expression - `1rem + 0.5vw`
> means "base rem plus half a percent of viewport width."
> This eliminates typography breakpoints entirely and provides
> smooth scaling across all viewport sizes.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> CSS units tell the browser what measurement system to use.
> `px` is fixed pixels. `rem` is relative to the root font
> size (16px by default) - use it for typography. `em` is
> relative to the current element's font size. `%` is
> relative to the parent's value. `vw` and `vh` are
> percentages of the viewport width/height. The main rule
> I follow: use `rem` for font sizes (it respects user
> accessibility preferences), `px` for borders and small
> details, and `%` or `vw`/`vh` for responsive layout.

*Push deeper:* Discuss the difference between `em` compounding
and `rem` not compounding, and `clamp()` for fluid typography.

---

**Senior / Staff (5+ years):**

> Unit choice is an accessibility and responsive design
> decision, not just syntax preference. `px` for font sizes
> overrides browser accessibility settings, violating WCAG
> 1.4.4. `rem` preserves user intent while still allowing
> designer control through the ratio.
>
> The nuance is `em` vs `rem`. `em` compounds with nesting -
> use it intentionally for components that should scale
> proportionally with their own font size (button padding
> in `em` scales with button text). `rem` doesn't compound -
> use it for global sizing and typography.
>
> For responsive design I use `clamp()` for typography
> (eliminates most font-size media queries) and `%` combined
> with `min()`/`max()` for layout. The new container query
> units (`cqw`, `cqh`) are increasingly important for
> component-level responsive design where viewport units
> are inappropriate.
>
> `vh` is broken on mobile (browser chrome changes make the
> viewport height unreliable). Use `svh` (small viewport
> height) or `dvh` (dynamic, updates as chrome shows/hides)
> for any full-height mobile layouts.

---

### ⚠️ Common Misconceptions

**"1rem = 16px"**

1rem = the root font size, which defaults to 16px in most
browsers. But users can change this. A user at 20px root
means 1rem = 20px. Your CSS should work at any root size.

**"em is the same as rem"**

`em` references the current element's computed font-size.
`rem` references the root element's font-size. `em` compounds
with nesting; `rem` does not.

**"vh is reliable for full-screen mobile"**

`100vh` on mobile includes the browser's URL bar, which shows
and hides as the user scrolls. Use `100svh` (small viewport
height - always excludes browser chrome) or `100dvh`
(dynamic - updates as chrome appears/disappears).

---

### 🚨 Failure Modes and Diagnosis

**Symptom: font sizes don't scale when user changes
browser zoom or font size**

Cause: font sizes set in `px`.

Diagnosis:
```
# Chrome > Settings > Appearance > Font size > set to Large
# If your text stays the same size, you're using px
# DevTools: Computed tab shows final px value of rem
```

Fix: Replace `font-size: 16px` with `font-size: 1rem`.
Ensure root is `font-size: 100%` not a fixed px value.

---

**Symptom: mobile layout has full-height section with
scroll artifacts - content hidden behind browser UI**

Cause: `height: 100vh` on mobile.

Fix:
```css
.hero {
  height: 100dvh; /* dynamic viewport height */
  /* falls back gracefully where dvh unsupported */
  height: 100vh;
}
@supports (height: 100dvh) {
  .hero { height: 100dvh; }
}
```

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| "Difference between rem/em/px" | 2-3 min | Compounding + accessibility |
| Accessibility implication | 2-3 min | WCAG + user font prefs |
| "Design fluid typography" | 4-5 min | clamp() usage |
| vh mobile problem | 3 min | svh/dvh knowledge |
| calc() usage | 2-3 min | Mixing units |

---

**Q1: What is the difference between em and rem?** `[JUNIOR]`
COMPARISON

*Why they ask:* The most common CSS units question; reveals
understanding of reference points.

*Likely follow-up:* "When would you use em over rem?"

> **Answer:**
>
> Both `em` and `rem` are relative font size units, but they
> reference different base values.
>
> `rem` stands for "root em" and is always relative to the
> `:root` (html) element's `font-size`. If the root is 16px,
> `1rem` = 16px everywhere in the document, regardless of
> where in the DOM the element lives. It does not compound.
>
> `em` is relative to the CURRENT element's `font-size`.
> If the parent has `font-size: 1.2em` and the child also
> has `font-size: 1.2em`, the child is 1.44x the root (1.2
> * 1.2). It compounds with nesting.
>
> When to use each: use `rem` for typography and any sizing
> that should scale globally but not compound. Use `em` for
> component-internal sizing that should scale with the
> component's text - for example, `padding: 0.5em` on a
> button means the padding scales proportionally as the
> button text size changes.
>
> The practical default: `rem` for font-size and layout
> dimensions; `em` for padding/margin inside components
> that should stay proportional to the component's font.
>
> *What separates good from great:* Using `em` for media
> query breakpoints instead of `px`. If a user sets their
> font to 20px, `em`-based breakpoints adapt accordingly,
> ensuring layout changes happen at the right moment
> relative to the user's text size, not just viewport pixels.

---

**Q2: Why should I avoid px for font sizes?** `[JUNIOR]`
TRADE-OFF

*Why they ask:* Tests accessibility awareness.

*Likely follow-up:* "What WCAG guideline does this relate to?"

> **Answer:**
>
> Browser default font sizes can be changed by users. This is
> a critical accessibility feature for people with low vision.
> `px` values are absolute and do not respond to this setting.
>
> When a user sets their browser font to 24px and your CSS
> says `font-size: 16px`, your text stays 16px. The user's
> preference is ignored. They'd need to use browser zoom
> instead - which scales everything, not just text.
>
> WCAG 2.1 Success Criterion 1.4.4 (Resize text, Level AA)
> requires that text can be resized up to 200% without loss
> of content or functionality. `px` font sizes prevent this
> unless the user uses browser zoom.
>
> The fix: `font-size: 1rem` inherits the user's preference.
> At default (16px) it's 16px. At user-set 20px it's 20px.
> The ratio you choose (1rem, 1.25rem, 2rem) controls the
> relative size while the user controls the absolute base.
>
> Never set `html { font-size: 62.5%; }` just to make rem
> calculations easier (1rem = 10px trick). This reduces the
> root font size, breaking user preferences at the source.
> Use `font-size: 100%` on `:root` to inherit user settings.
>
> *What separates good from great:* This also affects browser
> zoom behavior. When users zoom in browsers (Ctrl+Plus),
> both px and rem scales up because zoom is a viewport-level
> scale. The difference is specifically user font size
> settings in browser preferences, not browser zoom.

---

**Q3: How does CSS calc() work?** `[MID]` MECHANISM

*Why they ask:* calc() is a workhorse of responsive CSS.

*Likely follow-up:* "Can you mix units in calc()?"

> **Answer:**
>
> `calc()` performs mathematical calculations at render time,
> allowing you to mix different CSS units in a single value.
> This is the CSS equivalent of "I want this minus that."
>
> Syntax: `calc(expression)` where expression can use +, -,
> *, /. Key rule: + and - must have spaces around them.
> `calc(100% - 2rem)` is valid; `calc(100%-2rem)` is not.
>
> Common uses:
>
> `width: calc(100% - 64px)` - full width minus fixed sidebar
> (impossible without calc since you can't subtract px
> from %).
>
> `height: calc(100vh - 3rem)` - full viewport minus header.
>
> `transform: translateX(calc(-50% + 10px))` - center offset
> by a fixed amount.
>
> `font-size: calc(1rem + 0.5vw)` - fluid typography
> (though `clamp()` is preferred for this).
>
> calc() can also be used inside other functions:
> `clamp(1rem, calc(1rem + 2vw), 2rem)`.
>
> CSS custom properties integrate naturally:
> `--gap: 1rem; width: calc(50% - var(--gap))`.
>
> *What separates good from great:* The newer `min()`,
> `max()`, and `clamp()` functions are often better than
> `calc()` for responsive values. `min(500px, 100%)` is
> cleaner than `calc()` for "at most 500px." `clamp(1rem,
> 2.5vw, 2rem)` replaces calc() + media queries for fluid
> typography.

---

**Q4: What is clamp() and why is it useful?** `[SENIOR]`
MECHANISM

*Why they ask:* clamp() represents modern responsive CSS
mastery.

*Likely follow-up:* "How would you use clamp for responsive
typography without media queries?"

> **Answer:**
>
> `clamp(min, preferred, max)` constrains a value between a
> minimum and maximum while using a preferred "fluid" value
> between those bounds.
>
> `font-size: clamp(1rem, 2.5vw, 2rem)` means: never smaller
> than 1rem, never larger than 2rem, and in between scale
> with 2.5vw (2.5% of viewport width).
>
> At viewport width 640px: 2.5vw = 16px = 1rem -> clamped to
> 1rem minimum.
> At viewport width 1200px: 2.5vw = 30px > 2rem -> clamped
> to 2rem maximum.
> At viewport width 900px: 2.5vw = 22.5px = 1.4rem -> fluid.
>
> This eliminates typography media query breakpoints entirely.
> The font scales linearly between min and max across the
> responsive range. The math for the preferred value:
> `preferred = min + (max - min) * (100vw - min-vw) /
> (max-vw - min-vw)`. Tools like utopia.fyi compute these
> values interactively.
>
> clamp() also works for spacing, layout sizes, and any
> CSS property that accepts a length. A responsive gap:
> `gap: clamp(1rem, 3vw, 2.5rem)`.
>
> *What separates good from great:* Knowing the accessibility
> implication: the preferred value in clamp() should include
> a rem component to respect user font size preferences:
> `clamp(1rem, 0.5rem + 1.5vw, 2rem)`. The `0.5rem` part
> anchors the scaling to user preferences; pure `vw` units
> ignore them.

---

**Q5: Debugging: a layout is breaking on mobile. Units might
be the cause. How do you investigate?** `[MID]` DEBUGGING

*Why they ask:* Responsive unit debugging is a real-world skill.

*Likely follow-up:* "How do you test different viewport sizes?"

> **Answer:**
>
> Step 1: Open DevTools responsive mode (Ctrl+Shift+M in
> Chrome). Drag the viewport width to see where the layout
> breaks. Note the exact viewport width.
>
> Step 2: Select the broken element. In the Computed tab,
> find the relevant dimension property. Check the value -
> does it match your expectation for that viewport size?
>
> Step 3: If using vw/vh: verify the expected computation.
> `50vw` at 375px viewport should be 187.5px. If it's not,
> check for scrollbar width affecting viewport calculation
> (use `dvw` or add `scrollbar-gutter: stable`).
>
> Step 4: If using vh on mobile: this is almost always
> the culprit. Mobile browsers include/exclude the browser
> chrome from `100vh` inconsistently. Switch to `svh`
> (small viewport height - always excludes chrome) or
> `100%` on a full-height parent.
>
> Step 5: Check for `vw` causing horizontal scroll.
> `100vw` includes the scrollbar width on desktop,
> creating 16px overflow. Use `100%` on the body instead,
> or `overflow-x: hidden` on html (though this hides the
> symptom, not the cause).
>
> *What separates good from great:* Chrome DevTools has a
> "Device toolbar" that simulates specific devices with
> correct pixel density ratios. Testing at 375px width
> (iPhone SE) and 390px (iPhone 14) catches most mobile
> breakage.

---

**Q6: What are viewport units and their gotchas?** `[MID]`
MECHANISM

*Why they ask:* Viewport units are widely used and have
well-known pitfalls that trip up developers.

*Likely follow-up:* "What is dvh and how does it differ from vh?"

> **Answer:**
>
> Viewport units are percentages of the browser viewport:
> `1vw` = 1% of viewport width, `1vh` = 1% of viewport
> height, `1vmin` = 1% of the smaller dimension, `1vmax`
> = 1% of the larger dimension.
>
> The critical gotcha: on mobile devices, `100vh` is not
> the visible screen height. Mobile browsers have a dynamic
> chrome bar (URL bar, navigation) that shows and hides as
> users scroll. The viewport height spec ambiguity meant
> different browsers treated `100vh` differently - some
> included the chrome in the calculation, some didn't.
>
> The fix arrived in CSS 2022: three new viewport units:
> - `svh`/`svw`: small viewport - based on the viewport
>   when the browser chrome is FULLY VISIBLE (smaller)
> - `lvh`/`lvw`: large viewport - based on the viewport
>   when chrome is hidden (largest size)
> - `dvh`/`dvw`: dynamic viewport - updates in real time
>   as chrome shows/hides
>
> For a mobile hero section: `min-height: 100svh` ensures
> the section fills the screen even when chrome is visible.
>
> `100vw` on desktop often causes horizontal scroll because
> it doesn't account for scrollbar width. Use `overflow-x:
> hidden` on the html element or use percentage instead.
>
> *What separates good from great:* Knowing that `vmin`
> is useful for square elements that should fit in either
> portrait or landscape: `width: 80vmin; height: 80vmin`
> creates a square that fits the viewport regardless of
> orientation.

---

**Q7: How do you build accessible, responsive type
without a design system?** `[SENIOR]` HANDS-ON

*Why they ask:* Tests ability to apply unit knowledge to
a real-world implementation challenge.

*Likely follow-up:* "How do you generate the type scale values?"

> **Answer:**
>
> I start with a type scale - a modular ratio of font sizes.
> A common ratio is 1.25 (major third). Starting from a base
> of 1rem: sm = 0.8rem, base = 1rem, lg = 1.25rem, xl =
> 1.5625rem, 2xl = 1.953rem.
>
> To make it responsive, I use clamp() for each step:
>
> ```css
> :root {
>   font-size: 100%; /* inherit user preference */
>   --text-sm:   clamp(.8rem, .7rem + .5vw,   1rem);
>   --text-base: clamp(1rem,  .9rem + .5vw,  1.2rem);
>   --text-xl:   clamp(1.5rem, 1.2rem + 1vw, 2rem);
> }
> ```
>
> The `100%` root inherits user accessibility preferences.
> The `rem` component of each clamp preferred value anchors
> scaling to user settings. The `vw` component adds fluid
> scaling with viewport.
>
> For spacing I use a parallel scale with `rem` values and
> `gap`/padding using those variables. No `px` for text or
> most layout.
>
> Tools that generate these values: utopia.fyi for fluid
> type scales with the exact clamp() calculations, and
> Type Scale (typescale.com) for modular ratios.
>
> *What separates good from great:* Setting text spacing in
> `em` relative to the font size: `p { line-height: 1.5; }`
> (unitless value - computed as 1.5 * font-size, and
> inherited correctly). `margin-bottom: 1em` on paragraphs
> means the spacing scales with the paragraph's font size
> automatically.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Walk through rem vs em compounding with numbers |
| Hiring Manager | Frame as "accessibility-first responsive design" |
| Bar Raiser | Discuss clamp() and container query units |
| Peer Engineer | Share a mobile vh bug story |

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ foundational keyword - unit comparisons covered
in Concept Explanation and Q1 of Deep-Dive)*

---

### 🏛️ System Design

*(Omit: ★☆☆ foundational keyword - not architecture-level)*

---

### 📊 Diagram

*(Omit: the code examples and explanations are sufficient
for understanding CSS units)*

---
---

# CSS Colors and Typography

🎯 **Interview Weight:** medium - foundational knowledge;
tested in junior/mid interviews; deeper in design system
and accessibility discussions at senior level

---

### 🎯 Model Answer

**30 seconds:**

> CSS colors can be expressed as hex (`#ff0000`), RGB
> (`rgb(255, 0, 0)`), HSL (`hsl(0, 100%, 50%)`), or modern
> `oklch()` for perceptually uniform color spaces. Typography
> in CSS is controlled by the `font` shorthand and its
> constituent properties: `font-family`, `font-size`,
> `font-weight`, `line-height`, `letter-spacing`. The key
> interview point: use a font stack with system-ui or generic
> fallbacks, always set `line-height` unitlessly (for correct
> inheritance), and ensure color contrast meets WCAG AA (4.5:1
> for body text, 3:1 for large text).

**3 minutes (Senior):**

> Color and typography are the most visible parts of CSS and
> the most common sources of accessibility failures.
>
> For colors: the modern approach uses CSS custom properties
> as design tokens. Define your color palette as HSL variables:
> `--color-primary: hsl(220, 100%, 50%)` and adjust
> lightness/saturation with `oklch()` for perceptual
> uniformity (HSL is not perceptually uniform - the same
> numeric step in different hue ranges looks like different
> amounts of change).
>
> Color contrast is WCAG-required. AA requires 4.5:1 for
> normal text (under 18pt/24px) and 3:1 for large text or
> UI components. AAA is 7:1. Chrome DevTools' Accessibility
> panel checks this automatically. `color-contrast()` (CSS
> 4) can automatically pick the accessible color option.
>
> For typography: always provide a font stack with at least
> 3 fallbacks. `system-ui` or `-apple-system` gives
> native-looking text with no font download. `font-display:
> swap` on `@font-face` prevents invisible text during load
> (FOIT - Flash Of Invisible Text).
>
> `line-height` should be set unitlessly (e.g., `1.5` not
> `1.5em` or `24px`) because unitless values are inherited
> as a ratio while unit values are inherited as a computed
> pixel value - inherited `24px` line-height on a component
> with different font size produces wrong proportions.

*Adapting up:* Discuss CSS Color Level 4 (oklch, color-mix),
variable fonts, and design token color systems.

*Adapting down:* Colors as hex/rgb/hsl; font-family/size/
weight/line-height as the four core typography properties.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about CSS colors and
typography - let me walk through the core values and the
accessibility requirements."

**(2) First principles:** "From first principles, color
needs to be specifiable in multiple ways (hex for designers,
HSL for programmatic manipulation) and must meet contrast
requirements for accessibility."

**(3) Bridge:** "Think of typography as the reading experience
layer - not just what font, but the rhythm (line-height) and
breathing room (letter-spacing) between letters and lines."

---

### 📘 Concept Explanation

**What it is:**

CSS color values define element colors in multiple notations.
CSS typography properties control font appearance and text
layout: family, size, weight, style, line spacing, and
letter spacing.

**The problem it solves:**

Visual design requires precise color specification and
consistent typography. Text must be readable (contrast
compliance) and render predictably across fonts, sizes,
and devices.

**How it works:**

```
COLOR FORMATS:
  Hex:  #rgb, #rrggbb, #rrggbbaa
  RGB:  rgb(255 0 128 / 50%)  [modern space syntax]
  HSL:  hsl(220deg 100% 50%)
  HWB:  hwb(220 0% 0%)        [hue-whiteness-blackness]
  LCH:  lch(50% 60 220)       [perceptually uniform]
  oklch:oklch(0.6 0.2 260)    [modern, widest gamut]

  Named: red, blue, transparent, currentColor

TYPOGRAPHY PROPERTIES:
  font-family: "Inter", system-ui, sans-serif;
  font-size:   1rem;        [relative!]
  font-weight: 400;         [100-900 for variable fonts]
  font-style:  normal|italic|oblique;
  line-height: 1.5;         [unitless!]
  letter-spacing: 0.01em;
  text-transform: uppercase|lowercase|capitalize;
  text-decoration: underline|none;
  font-variant:    small-caps;
  font-display:    swap;    [on @font-face - FOIT prevention]
```

**The key insight:**

`line-height` must be unitless for correct inheritance.
When set as `1.5` (no unit), descendants inherit the
ratio and compute their own line height from their font
size. When set as `24px`, descendants inherit `24px` - wrong
for any element with a different font size.

**When to use it:**

CSS custom properties as color tokens; system font stacks
as primary; web fonts for brand typography only; unitless
`line-height` always.

**When NOT to use it:**

Don't hardcode color values throughout CSS - use CSS
custom properties so theme changes are one-line edits.
Don't rely on `font-size: 62.5%` hack for rem calculations.
Don't use `line-height` with units.

**Alternatives:**

- oklch and LCH for programmatic color manipulation
  (perceptually uniform vs HSL)
- CSS `color-scheme` property for automatic dark mode
- Variable fonts for single font file with multiple weights

**First-principles derivation:**

Multiple color models exist because different tasks need
different abstractions: hex for designer tools and codes,
RGB for programmatic blending, HSL for human-adjustable
hue/saturation/lightness, oklch for perceptual uniformity
in color scales.

---

### 💻 Code Example

**BAD: color hardcoded, line-height with units**

```css
/* BAD: hardcoded colors, unit line-height */
.header { color: #1a73e8; }
.text   { color: #1a73e8; } /* duplicate, hard to change */
.card   { background: #f8f9fa; }

p {
  font-size: 16px;
  line-height: 24px; /* WRONG: inherited as 24px always */
}
h2 {
  font-size: 24px;
  /* inherits line-height: 24px -> ratio=1.0, too tight */
}
```

> **Code walkthrough:** Hardcoded colors scattered throughout
> CSS mean a brand color change requires finding every
> occurrence. Pixel `line-height` breaks when inherited by
> elements with different font sizes - a 24px line-height on
> 24px text is ratio 1.0 (too tight), while it was designed
> for 16px text at ratio 1.5.

**GOOD: design tokens + unitless line-height**

```css
/* GOOD: token-based colors, unitless line-height */
:root {
  --color-primary:    hsl(214deg 90% 45%);
  --color-surface:    hsl(210deg 17% 98%);
  --color-text:       hsl(215deg 28% 17%);
  --color-text-muted: hsl(215deg 16% 47%);
}

.header { color: var(--color-primary); }
.card   { background: var(--color-surface); }

p {
  font-size: 1rem;
  line-height: 1.6;  /* unitless - correct inheritance */
  color: var(--color-text);
}
h2 {
  font-size: 1.5rem;
  line-height: 1.2;  /* headings can be tighter */
}
```

> **Code walkthrough:** Color tokens defined once in `:root`
> mean every color change is a single edit. HSL format makes
> colors human-readable and allows programmatic lightness
> adjustments. Unitless `line-height` inherits as a ratio -
> each element computes its own `px` value from its font-size.

**PRODUCTION: web font loading with FOIT prevention**

```css
/* Prevent FOIT (Flash Of Invisible Text) */
@font-face {
  font-family: "Inter";
  src: url("/fonts/inter-var.woff2") format("woff2");
  font-weight: 100 900; /* variable font range */
  font-display: swap;   /* show fallback until loaded */
}

/* Font stack with system fallback */
:root {
  font-family: "Inter", system-ui, -apple-system,
               BlinkMacSystemFont, sans-serif;
}
```

> **Code walkthrough:** `font-display: swap` tells the browser
> to show the fallback font immediately and swap to the web
> font when it loads. Without it, text may be invisible for
> seconds during slow connections (FOIT). Variable fonts
> (single file, all weights) with `font-weight: 100 900`
> replace separate font files per weight, reducing HTTP
> requests.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> CSS colors can be specified as hex codes (#ff0000), RGB
> values, or HSL (hue, saturation, lightness). HSL is more
> human-readable since you can intuit "a 50% lightness blue."
> For typography, the four main properties are font-family
> (the typeface), font-size, font-weight (how thick/thin),
> and line-height (space between lines - always use unitless
> values like 1.5, not pixels, so it inherits correctly).
> Colors should be stored as CSS custom properties so you
> can change your brand color in one place.

*Push deeper:* Mention WCAG color contrast requirements
and font-display: swap.

---

**Senior / Staff (5+ years):**

> Color is a design token problem. I represent colors as
> CSS custom properties in semantic layers: primitives (the
> full palette), semantics (--color-text, --color-surface),
> and component-specific (--button-color). This enables dark
> mode by remapping semantic tokens. I use oklch for
> programmatic color manipulation because HSL is perceptually
> non-uniform - equal numeric steps look different depending
> on hue.
>
> Typography at scale is a font loading performance problem.
> Variable fonts with a single woff2 file cover all weights,
> `font-display: swap` prevents FOIT, and `font-size-adjust`
> can make fallback fonts match the metric of the web font,
> reducing layout shift during font swap (FOUT).
>
> Contrast compliance is non-negotiable: WCAG AA (4.5:1)
> is the minimum for body text. I check with DevTools
> Accessibility panel or axe and build the palette with
> contrast in mind from the start.

---

### ⚠️ Common Misconceptions

**"Hex and RGB are different things"**

They're the same color model in different notation. `#ff0000`
and `rgb(255, 0, 0)` represent identical colors.

**"Higher font-weight means the font is larger"**

Font-weight controls thickness (100=thin, 400=normal,
700=bold, 900=black). Font-size controls height. They're
independent.

**"currentColor is a specific color"**

`currentColor` is a CSS keyword that resolves to the element's
current computed `color` value. `border-color: currentColor`
makes the border match the text color. Very useful for icon
colors and maintaining color consistency.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: web font not loading, using fallback font**

Diagnosis:
```
# Network tab: check font file HTTP status (200 vs 404)
# Check CORS headers if font is on CDN
# Check font-face src path is correct
# Check: is the @font-face before the rule using it?
```

---

**Symptom: text fails accessibility contrast check**

Diagnosis:
```
# Chrome DevTools > Lighthouse > Accessibility
# Or: Elements panel > select text > Accessibility tab
# Shows contrast ratio with pass/fail against AA/AAA
```

Fix: increase contrast by darkening foreground or lightening
background (or vice versa). Use oklch or a contrast checker
to find a value that passes.

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| "Color formats in CSS" | 2 min | hex/hsl/oklch + use cases |
| "WCAG contrast requirement" | 2 min | 4.5:1 + 3:1 numbers |
| line-height unitless | 2-3 min | Inheritance explanation |
| Font loading optimization | 3-4 min | FOIT + font-display |
| Dark mode implementation | 4-5 min | Token system + media query |

---

**Q1: What is the difference between HSL and hex for
colors?** `[JUNIOR]` COMPARISON

*Why they ask:* Color format fluency signals CSS depth.

*Likely follow-up:* "When would you choose HSL over hex?"

> **Answer:**
>
> Hex and HSL express the same sRGB color space in different
> notations. `#3498db` and `hsl(204deg 70% 53%)` are the
> same color.
>
> Hex is compact and universally recognized by designers and
> color pickers. It's what design tools export. The downside:
> it's opaque - you can't tell by looking at `#3498db` that
> it's a medium-lightness blue.
>
> HSL is human-readable: Hue (0-360 degrees on the color
> wheel), Saturation (0% = grey, 100% = vivid), Lightness
> (0% = black, 50% = normal, 100% = white). You can intuit
> `hsl(220deg 90% 45%)` as "a vivid, medium-dark blue."
>
> HSL is also programmatically manipulable. To create a
> hover state that's 10% lighter: change `L` from 45% to
> 55%. In CSS custom properties:
> ```css
> --btn-color: hsl(220deg 90% 45%);
> --btn-hover: hsl(220deg 90% 55%); /* +10% lightness */
> ```
>
> The limitation of HSL: it's not perceptually uniform.
> Equal `L` increments look like different amounts of
> change depending on the hue. `oklch` is the modern fix -
> it's designed to change in perceptually equal steps.
>
> *What separates good from great:* CSS Color 4's `color-mix()`
> function: `color-mix(in oklch, var(--color-primary) 80%,
> white)` creates an 80% tint of your primary color
> programmatically - replacing Sass `lighten()` natively.

---

**Q2: Why does WCAG specify color contrast ratios?**
`[JUNIOR]` CONCEPTUAL

*Why they ask:* Accessibility is a core engineering concern;
tests values not just technical knowledge.

*Likely follow-up:* "What are the actual WCAG AA numbers?"

> **Answer:**
>
> Color contrast is an accessibility requirement for people
> with low vision, color blindness, and those reading in
> bright sunlight. The contrast ratio is computed as
> (lighter luminance + 0.05) / (darker luminance + 0.05).
> A ratio of 1:1 is identical colors (no contrast); 21:1
> is white on black (maximum contrast).
>
> WCAG 2.1 requires:
> - 4.5:1 for normal text (under 18pt = 24px for regular
>   weight, or under 14pt = 19px for bold)
> - 3:1 for large text (18pt+ = 24px+ regular, or 14pt+
>   = 19px+ bold) and UI components (button outlines,
>   focus indicators)
>
> These are the AA level requirements. AAA is stricter:
> 7:1 for normal text, 4.5:1 for large text.
>
> In practice: light grey text on white background fails
> constantly. `#767676` on white is exactly 4.5:1. Anything
> lighter fails. Common failures in the wild: grey placeholder
> text, disabled state text, caption text, and light-colored
> icons on white.
>
> DevTools checks this: select an element, go to Accessibility
> tab, find the contrast ratio. Chrome's color picker also
> shows contrast lines on the gradient.
>
> *What separates good from great:* Contrast applies to UI
> components too, not just text. Focus indicators, form field
> borders, and button outlines need 3:1 against their
> adjacent background. This is a newer WCAG 2.1 addition
> (1.4.11) that many teams miss.

---

**Q3: Explain font stacks and why you need multiple
fonts in font-family.** `[JUNIOR]` MECHANISM

*Why they ask:* Font stacks are daily CSS; reveals knowledge
of web font loading failure modes.

*Likely follow-up:* "What is system-ui?"

> **Answer:**
>
> A font stack is the comma-separated list in `font-family`.
> The browser tries fonts left to right and uses the first
> one available. Providing multiple fonts is essential
> because web fonts can fail to load (network error, user
> has fonts disabled, CORS issue) and not all users have
> the same system fonts installed.
>
> A typical modern font stack:
> ```css
> font-family: "Inter", system-ui, -apple-system,
>              BlinkMacSystemFont, sans-serif;
> ```
>
> "Inter" is the web font - brand typography. `system-ui`
> is the browser's native system font (San Francisco on
> macOS/iOS, Segoe UI on Windows, Roboto on Android).
> `-apple-system` and `BlinkMacSystemFont` are older
> vendor-prefixed equivalents for Apple browsers that
> predate `system-ui`. `sans-serif` is the browser's
> generic fallback.
>
> Fonts with spaces must be quoted: `"Times New Roman"`.
> Single-word fonts don't need quotes but can have them:
> `Inter` and `"Inter"` are both valid.
>
> The benefit of `system-ui` as primary: zero font load
> time, native look for the platform, best performance.
> The trade-off: looks different on Mac vs Windows vs Android.
> For brand consistency, a web font is needed. For utility
> interfaces, system-ui is often preferred.
>
> *What separates good from great:* Understanding font
> metrics and layout shift. When a web font loads and
> replaces the fallback, if the fonts have different
> metrics (line height, x-height, spacing), the layout
> reflows (FOUT - Flash Of Unstyled Text). The CSS
> `size-adjust` and `ascent-override` descriptors on
> `@font-face` can adjust fallback metrics to match the
> web font, minimizing layout shift.

---

**Q4: How do you implement dark mode in CSS?** `[SENIOR]`
PRODUCTION

*Why they ask:* Dark mode is a modern frontend requirement;
tests knowledge of CSS custom properties and media queries.

*Likely follow-up:* "How do you handle user override
of dark mode preference?"

> **Answer:**
>
> The modern approach uses CSS custom properties as a
> semantic color token layer, with `prefers-color-scheme`
> media query to remap them.
>
> ```css
> :root {
>   --color-bg:   hsl(0 0% 100%);
>   --color-text: hsl(215 28% 17%);
>   --color-card: hsl(210 17% 98%);
> }
>
> @media (prefers-color-scheme: dark) {
>   :root {
>     --color-bg:   hsl(215 28% 9%);
>     --color-text: hsl(210 17% 95%);
>     --color-card: hsl(215 25% 14%);
>   }
> }
>
> body { background: var(--color-bg); color: var(--color-text); }
> .card { background: var(--color-card); }
> ```
>
> No component changes needed - only the `:root` tokens change.
>
> To support user override (a "toggle dark mode" button),
> add a `data-theme` attribute:
> ```css
> [data-theme="dark"] { /* same remapped tokens */ }
> [data-theme="light"] { /* explicit light tokens */ }
> ```
> Set `document.documentElement.setAttribute("data-theme",
> theme)` from JavaScript.
>
> Ordering matters: `[data-theme="dark"]` should come after
> the media query so the manual override wins.
>
> *What separates good from great:* Using `color-scheme:
> light dark` on `:root` tells the browser to render native
> form controls, scrollbars, and browser UI in the
> appropriate mode. Without it, you might have dark custom
> styles but light browser scrollbars.

---

**Q5: How do variable fonts change web typography?**
`[SENIOR]` MECHANISM

*Why they ask:* Variable fonts represent modern font
technology with performance implications.

*Likely follow-up:* "What axes do variable fonts expose?"

> **Answer:**
>
> Traditional web fonts required separate font files for
> each variation: Inter-Regular.woff2, Inter-Bold.woff2,
> Inter-Light.woff2. Each HTTP request added latency.
>
> Variable fonts encode all variations in a single file.
> A single Inter-var.woff2 covers the entire weight range
> 100-900. One file replaces 9 files.
>
> Variable fonts expose "axes" - continuous ranges of
> variation. The standard axes:
> - `wght` (weight): replaces font-weight discrete values
>   with a continuous range. `font-weight: 450` is valid
>   with a variable font that supports 100-900.
> - `wdth` (width): compressed to expanded, controlled via
>   `font-stretch`
> - `ital` (italic): 0 (normal) to 1 (italic), via
>   `font-style`
> - `slnt` (slant): oblique angles, via `font-style: oblique
>   15deg`
>
> Custom axes (prefixed with uppercase): a font might have
> `CASL` (casual), `MONO` (monospace proportion), etc.,
> accessed via `font-variation-settings: "CASL" 0.5`.
>
> Performance: one variable font file is typically smaller
> than two traditional files but larger than one. The break-
> even is around 2-3 weight variants.
>
> *What separates good from great:* Variable fonts enable
> CSS animations of font variation axes: animate `font-weight`
> from 400 to 800 on hover for a weight transition effect.
> This was impossible with traditional fonts.

---

**Q6: What is FOIT and FOUT and how do you prevent them?**
`[MID]` DEBUGGING

*Why they ask:* Font loading problems are visible performance
bugs that affect UX.

*Likely follow-up:* "What is font-display: optional?"

> **Answer:**
>
> FOIT (Flash Of Invisible Text): the browser hides text
> while the web font loads. The default browser behavior
> varies: Chrome/Firefox hide text for up to 3 seconds
> then fall back; Safari hides indefinitely.
>
> FOUT (Flash Of Unstyled Text): text shows immediately in
> the fallback font, then visibly swaps when the web font
> loads. This causes layout shift.
>
> `font-display` on `@font-face` controls this:
> - `auto`: browser default (usually FOIT)
> - `block`: 3-second FOIT, then fallback, then swap
> - `swap`: immediate fallback (FOUT), then swap when ready
>   - Best for critical text (headings, body)
> - `fallback`: very short FOIT (100ms), then fallback,
>   then swap only if font loads quickly (3s window)
> - `optional`: very short FOIT, then decide to swap
>   or not based on network conditions - no swap after
>   initial period. Best for non-essential decorative fonts.
>
> For most text: `font-display: swap` prevents invisible
> text at the cost of visible swap. Reduce FOUT impact by
> using `size-adjust`, `ascent-override`, `descent-override`
> on the `@font-face` to match fallback metrics to the
> web font, minimizing layout shift on swap.
>
> *What separates good from great:* Preloading the font file:
> `<link rel="preload" href="/fonts/inter.woff2" as="font"
> type="font/woff2" crossorigin>`. This starts the font
> download during HTML parsing before CSS is processed,
> reducing the time until swap and minimizing visible FOUT.

---

**Q7: Describe how you would set up a color system
using CSS custom properties.** `[SENIOR]` HANDS-ON

*Why they ask:* Color system design is a real senior
frontend skill.

*Likely follow-up:* "How does this support dark mode?"

> **Answer:**
>
> I use a two-layer token system: primitives and semantics.
>
> Primitive tokens are the full color palette - every shade:
> ```css
> :root {
>   --blue-50:  hsl(220 100% 97%);
>   --blue-500: hsl(220 90% 56%);
>   --blue-900: hsl(220 70% 20%);
>   /* ... all shades 50-950 */
> }
> ```
>
> Semantic tokens map meanings to primitives:
> ```css
> :root {
>   --color-bg:          var(--neutral-50);
>   --color-text:        var(--neutral-900);
>   --color-primary:     var(--blue-500);
>   --color-primary-fg:  var(--neutral-50);
>   --color-border:      var(--neutral-200);
>   --color-focus:       var(--blue-400);
> }
> ```
>
> Dark mode remaps semantics only:
> ```css
> @media (prefers-color-scheme: dark) {
>   :root {
>     --color-bg:    var(--neutral-900);
>     --color-text:  var(--neutral-50);
>     /* etc. - primitives unchanged */
>   }
> }
> ```
>
> Components use semantic tokens only - never primitives
> directly. This means components need zero changes for
> dark mode.
>
> *What separates good from great:* Adding a component token
> layer for complex components: `--button-bg: var(--color-
> primary)`. A component's variant (.btn-danger) only
> overrides its own component tokens: `--button-bg: var(
> --color-error)`. This keeps component overrides contained
> and prevents semantic token pollution.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Walk through oklch vs HSL perceptual uniformity |
| Hiring Manager | Frame as accessibility compliance and brand consistency |
| Bar Raiser | Discuss two-layer design token system for dark mode |
| Peer Engineer | Discuss font-display choices and real FOUT experiences |

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ foundational keyword - color format and typography
comparisons are covered inline in the Concept Explanation)*

---

### 🏛️ System Design

*(Omit: ★☆☆ foundational keyword - not architecture-level)*

---

### 📊 Diagram

*(Omit: prose and code examples are sufficient for understanding
CSS colors and typography)*
