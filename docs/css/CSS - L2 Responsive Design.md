---
layout: default
title: "CSS - L2 Responsive Design"
parent: "CSS"
nav_order: 6
permalink: /css/l2-responsive-design/
render_with_liquid: false
---

# CSS Media Queries

🎯 **Interview Weight:** critical - Media queries are the
foundation of responsive design; every frontend role tests
this; understanding the cascade of breakpoints distinguishes
seniors from juniors

---

### 🎯 Model Answer

**30 seconds:**

> CSS media queries apply styles conditionally based on
> device characteristics. The syntax: `@media (condition) {
> rules }`. Common conditions: `max-width` (desktop-first),
> `min-width` (mobile-first), `prefers-color-scheme`,
> `prefers-reduced-motion`. The cascade applies, so specificity
> and source order determine which rule wins when multiple
> queries match.

**3 minutes (Senior):**

> Media queries are at-rules that evaluate a media feature
> expression and apply the enclosed CSS only when the condition
> is true. The media type (`screen`, `print`, `all`) is
> optional; the media feature is in parentheses.
>
> Breakpoint strategy matters more than the specific pixel
> values. Mobile-first: start with base styles for small
> screens, use `min-width` queries to progressively enhance
> for larger screens. Desktop-first (legacy): start with
> desktop styles, use `max-width` to override down. Mobile-
> first is now the standard - it forces progressive
> enhancement, smaller default payload, and aligns with
> how browsers parse CSS.
>
> Modern media features: `prefers-color-scheme: dark`
> (user OS dark mode), `prefers-reduced-motion: reduce`
> (accessibility), `prefers-contrast: high`, `hover: none`
> (touch devices), `pointer: coarse` (touch screens).
> These enable CSS-only adaptations without JavaScript.
>
> Range syntax (Level 4): `@media (width >= 768px)` is
> equivalent to `@media (min-width: 768px)` but more
> readable. Already supported in all major browsers.
>
> Media queries can be combined: `and`, `not`, `,` (or),
> `only` (legacy). `@media screen and (min-width: 768px)
> and (max-width: 1024px)` applies only for tablet widths.
>
> Performance: the browser parses all media query CSS even
> if the query doesn't match. `<link media="print">` avoids
> print CSS in the render-blocking critical path but still
> downloads it.

*Adapting up:* CSS Container Queries as the next evolution
(style based on container size, not viewport size).

*Adapting down:* @media lets you change styles based on
screen size using min-width/max-width conditions.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about CSS media queries -
let me explain the syntax, the mobile-first strategy, and
modern feature queries."

**(2) First principles:** "From first principles, responsive
design needs conditional styles. A media query says 'apply
these rules only when this condition is true about the
rendering environment'."

**(3) Bridge:** "Think of media queries as if-statements
in CSS. The browser evaluates the condition before applying
the styles."

---

### 📘 Concept Explanation

**What it is:**

CSS at-rules (`@media`) that evaluate a boolean expression
about the rendering environment and apply enclosed rules
only when the expression is true.

**The problem it solves:**

A single CSS stylesheet that renders correctly across phones
(375px), tablets (768px), laptops (1440px), and TVs (4K).
Without media queries, every device gets the same layout
regardless of available space.

**How it works:**

```
SYNTAX:
  @media [type] [(feature)]  [operator] [(feature)] {
    /* rules applied when condition is true */
  }

MEDIA TYPES:
  screen - for screens
  print  - for print/PDF
  all    - all output devices (default)

MEDIA FEATURES:
  Width:
    min-width: 768px      - viewport >= 768px
    max-width: 1024px     - viewport <= 1024px
    width: 768px          - exactly 768px (rare)

  Display quality:
    resolution: 2dppx     - retina / HiDPI
    color-gamut: p3       - wide gamut display

  User preferences:
    prefers-color-scheme: dark | light
    prefers-reduced-motion: reduce | no-preference
    prefers-contrast: high | low | no-preference
    forced-colors: active | none

  Input:
    hover: none | hover  - primary input has hover
    pointer: coarse | fine | none

LOGICAL OPERATORS:
  and  - both conditions must be true
  not  - negates the entire query
  ,    - OR (either query can match)
  only - compatibility (legacy, now ignored)

LEVEL 4 RANGE SYNTAX:
  (width >= 768px)         same as min-width: 768px
  (768px <= width <= 1024px) - range (tablet)

CSS CUSTOM MEDIA (Level 5 - proposal):
  @custom-media --tablet (min-width: 768px);
  @media (--tablet) { ... }
```

**The key insight:**

Media queries don't add specificity. Two rules from
different media queries have the same specificity - source
order determines which wins when both match. This is why
breakpoint ordering matters: mobile-first uses `min-width`
queries in ascending order; the larger breakpoint must come
last in source order to override the smaller one.

**When to use it:**

- Any responsive layout requirement
- Dark/light mode styling (`prefers-color-scheme`)
- Accessibility adaptations (`prefers-reduced-motion`)
- Print stylesheets
- Touch vs pointer input differentiation

**When NOT to use it:**

When the component should respond to its CONTAINER size,
not the viewport. Use CSS Container Queries instead.
Media queries create tight coupling between components
and viewport breakpoints.

**Alternatives:**

- CSS Container Queries: respond to container width
- CSS clamp/min/max: fluid typography and spacing without
  breakpoints
- CSS Grid auto-fill: responsive columns without breakpoints

**First-principles derivation:**

A webpage must display correctly in environments with
different capabilities. CSS needs a mechanism to provide
conditional rules. Media queries are the CSS specification's
answer: a boolean predicate evaluated against the browsing
environment.

---

### 💻 Code Example

**BAD: desktop-first with overlapping overrides**

```css
/* BAD: desktop-first creates override spaghetti */
.nav {
  display: flex;
  flex-direction: row;
  gap: 2rem;
  /* Desktop styles first */
}
@media (max-width: 1024px) {
  .nav { gap: 1rem; }
}
@media (max-width: 768px) {
  .nav {
    flex-direction: column;
    gap: 0;
  }
}
@media (max-width: 480px) {
  .nav { display: none; }
}
/* Each breakpoint overrides the one above */
/* Mobile loads ALL desktop CSS first */
```

> **Code walkthrough:** Desktop-first requires increasingly
> specific overrides down the breakpoint chain. Mobile
> loads all the expensive desktop CSS and overrides it.
> The override cascade is fragile - adding a property at
> any breakpoint requires checking all smaller breakpoints.

**GOOD: mobile-first progressive enhancement**

```css
/* GOOD: mobile-first - start minimal, enhance up */
.nav {
  display: none; /* hidden on mobile (hamburger menu) */
}

@media (min-width: 768px) {
  .nav {
    display: flex;
    gap: 1rem;
  }
}

@media (min-width: 1024px) {
  .nav { gap: 2rem; }
}
/* Ascending breakpoints, progressive enhancement */
/* Each breakpoint adds, rarely overrides */
```

> **Code walkthrough:** Mobile-first starts with the
> simplest state. Each `min-width` query adds complexity
> progressively. No override cascade - if a property isn't
> in the base styles, it doesn't need overriding. The CSS
> needed for mobile is minimal and loads immediately.

**PRODUCTION: accessibility media queries**

```css
/* Respect user preferences - always implement these */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
    scroll-behavior: auto !important;
  }
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-bg: #0f172a;
    --color-text: #f1f5f9;
    --color-surface: #1e293b;
    --color-border: #334155;
  }
}

/* HIGH contrast mode support */
@media (forced-colors: active) {
  .custom-checkbox {
    border: 2px solid ButtonText;
    /* Don't rely on background colors in forced-colors */
  }
}
```

> **Code walkthrough:** The reduced-motion query uses
> `!important` as a deliberate override of all animations
> and transitions site-wide. This is the rare legitimate
> use of `!important` - a user accessibility preference
> must override design decisions. Dark mode uses CSS
> custom property overrides so the entire design system
> switches without touching component CSS. Forced-colors
> handles Windows High Contrast Mode.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> CSS media queries apply different styles based on screen
> size. The main usage: `@media (min-width: 768px) { styles }`.
> For mobile-first development, start with base styles for
> mobile, then use `min-width` breakpoints to enhance for
> larger screens. Common breakpoints: 480px (small mobile),
> 768px (tablet), 1024px (laptop), 1440px (desktop). Modern
> media queries also support user preferences like
> `prefers-color-scheme: dark` for automatic dark mode.

---

**Senior / Staff (5+ years):**

> Media queries are about more than just width. The
> `prefers-reduced-motion` and `prefers-color-scheme` queries
> are accessibility requirements now. `hover: none` and
> `pointer: coarse` enable proper touch vs mouse adaptations.
>
> Breakpoint strategy: I prefer content-based breakpoints -
> set breakpoints where the layout breaks, not at device
> widths. Using CSS Grid's `auto-fill + minmax` eliminates
> breakpoints for column counts entirely.
>
> CSS Container Queries are the real future - media queries
> bind components to viewport, making them reusable context
> impossible. Container queries fix the "component at
> different sizes in different contexts" problem.

---

### ⚠️ Common Misconceptions

**"Mobile-first means making a mobile app first"**

Mobile-first means writing CSS base styles for mobile and
using `min-width` media queries to enhance. It's a code
authoring strategy, not a product strategy. The same codebase
serves all screen sizes.

**"Media query breakpoints should match device widths"**

Device widths change every year. Content-based breakpoints
(where the layout breaks) are more stable and maintainable.
Designing to `375/768/1440` creates false precision.

**"Media queries block rendering"**

All `<link>` CSS blocks rendering regardless of media
attribute. `<link media="print">` still blocks rendering
but is deprioritized. The only performance gain is avoiding
a separate request for print styles - not blocking prevention.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: styles don't apply at expected width**

Diagnosis:
```
# Check viewport meta tag (REQUIRED for responsive):
<meta name="viewport"
  content="width=device-width, initial-scale=1">
# Without this, mobile browsers zoom out desktop layout
# Media query min-width sees the document width, not viewport
```

---

**Symptom: prefers-color-scheme not working**

Check DevTools: in Chrome, go to Rendering panel,
toggle "Emulate CSS media feature prefers-color-scheme".
If styles still don't apply, check specificity - the
`:root` override must be more specific than component
overrides.

---

**Symptom: breakpoints appear at wrong widths**

```
# Chrome DevTools > Device toolbar shows actual viewport
# Check if scrollbar width affects layout:
# On Windows, scrollbar (~17px) reduces viewport width
# Use overflow-y: scroll on body to keep consistent
```

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| "Explain media queries" | 3 min | Syntax + mobile-first |
| Why mobile-first is better | 3 min | Progressive enhancement |
| prefers-reduced-motion | 3-4 min | Accessibility |
| viewport meta tag role | 2-3 min | Without it: broken |
| Container queries vs media | 4 min | Component portability |
| Content-based breakpoints | 3 min | Design argument |
| Dark mode implementation | 3-4 min | Custom properties |
| media query specificity | 3 min | Cascade behavior |
| Range syntax | 2 min | Level 4 modern syntax |

---

**Q1: What is the difference between min-width and
max-width media queries?** `[JUNIOR]` MECHANISM

*Why they ask:* Core concept for every frontend role.

*Likely follow-up:* "Why is min-width preferred for
mobile-first development?"

> **Answer:**
>
> `min-width` applies styles when the viewport is AT LEAST
> the specified width. `max-width` applies when it's AT MOST
> the specified width.
>
> Mobile-first uses `min-width`: base styles apply to
> all screen sizes, then `min-width` queries ENHANCE for
> larger screens.
>
> ```css
> /* mobile-first */
> .container { width: 100%; } /* base: mobile */
> @media (min-width: 768px) {
>   .container { max-width: 1200px; margin: 0 auto; }
> }
> ```
>
> Desktop-first uses `max-width`: base styles for desktop,
> then `max-width` queries REDUCE for smaller screens.
>
> ```css
> /* desktop-first */
> .sidebar { display: block; width: 250px; }
> @media (max-width: 768px) {
>   .sidebar { display: none; }
> }
> ```
>
> Mobile-first is preferred because:
> 1. Progressive enhancement: start simple, add complexity
> 2. Performance: mobile devices load minimal CSS first
> 3. Maintainability: adding properties is easier than
>    overriding them
> 4. Forces designers to prioritize content hierarchy
>    on small screens (content-first thinking)
>
> *What separates good from great:* The viewport meta tag
> `<meta name="viewport" content="width=device-width,
> initial-scale=1">` is REQUIRED for media queries to work
> on mobile. Without it, mobile browsers render at 980px
> (virtual viewport) and scale down, so `min-width: 768px`
> always fires - making the "mobile" styles never apply
> on actual mobile devices.

---

**Q2: How do you implement dark mode with CSS?**
`[MID]` PRODUCTION

*Why they ask:* Practical dark mode implementation is
a real production skill.

*Likely follow-up:* "How do you also support a user
toggle?"

> **Answer:**
>
> The clean approach: CSS custom properties as a design
> token layer, `prefers-color-scheme` to override the tokens.
>
> ```css
> /* Design tokens - light mode defaults */
> :root {
>   --color-bg: #ffffff;
>   --color-text: #0f172a;
>   --color-primary: #2563eb;
>   --color-surface: #f8fafc;
>   --color-border: #e2e8f0;
> }
>
> /* Dark mode - override tokens only */
> @media (prefers-color-scheme: dark) {
>   :root {
>     --color-bg: #0f172a;
>     --color-text: #f1f5f9;
>     --color-primary: #60a5fa;
>     --color-surface: #1e293b;
>     --color-border: #334155;
>   }
> }
>
> /* Components reference tokens, never raw colors */
> .card {
>   background: var(--color-surface);
>   color: var(--color-text);
>   border: 1px solid var(--color-border);
> }
> ```
>
> Components never reference specific colors - only tokens.
> So the entire site switches to dark mode by overriding
> the tokens.
>
> For a user-controlled toggle:
> ```css
> /* User preference overrides OS preference */
> [data-theme="dark"] {
>   --color-bg: #0f172a;
>   /* ... dark tokens ... */
> }
> [data-theme="light"] {
>   --color-bg: #ffffff;
>   /* ... light tokens ... */
> }
> ```
>
> JavaScript toggles `data-theme` on `<html>`. The explicit
> `data-theme` attribute has higher specificity than the
> media query when it's on the same `:root` element... Actually
> source order determines this, so the `[data-theme]` rule
> must come AFTER the media query in source order.
>
> *What separates good from great:* Store the user's
> preference in `localStorage`. On page load, read it
> and set `data-theme` before the first render (inline
> script in `<head>`) to prevent flash of wrong theme.
> CSS alone can't persist the preference across page loads.

---

**Q3: Why is the viewport meta tag required for responsive
design?** `[MID]` MECHANISM

*Why they ask:* A non-obvious but critical fact that
separates candidates who've actually done responsive work.

*Likely follow-up:* "What happens if you omit it?"

> **Answer:**
>
> Mobile browsers have two viewports: the visual viewport
> (actual screen pixels) and the layout viewport (the width
> CSS is computed against).
>
> Without `<meta name="viewport"...>`:
> The browser uses a default layout viewport of 980px (iOS)
> or similar. It renders the page as if it were 980px wide,
> then scales it down to fit the screen. The result is a
> tiny, zoomed-out desktop layout on mobile.
>
> CSS media queries compare against the LAYOUT viewport.
> On a 375px iPhone without the meta tag, the layout viewport
> is 980px. `@media (max-width: 480px)` NEVER fires.
> Mobile-first `@media (min-width: 768px)` ALWAYS fires.
> The entire responsive system is broken.
>
> With `content="width=device-width, initial-scale=1"`:
> - `width=device-width`: layout viewport = physical screen
>   CSS pixels (e.g., 375px on iPhone 13)
> - `initial-scale=1`: no zoom applied
>
> The layout viewport now equals the visual viewport.
> Media queries work as expected.
>
> `initial-scale=1` is critical: even with device-width,
> some older browsers apply a zoom. Setting initial-scale
> to 1 ensures 1 CSS pixel = 1 device-independent pixel.
>
> *What separates good from great:* You can also set
> `minimum-scale=1, maximum-scale=1` to prevent user
> zoom, but this is an ACCESSIBILITY violation (WCAG 1.4.4
> Resize Text). Never prevent user zoom.

---

**Q4: How does media query specificity work?** `[SENIOR]`
MECHANISM

*Why they ask:* A subtle cascade question that trips up
experienced developers.

*Likely follow-up:* "Does wrapping a rule in a media query
increase its specificity?"

> **Answer:**
>
> Media queries do NOT add specificity. A rule inside
> `@media (min-width: 768px) {}` has the same specificity
> as the same rule outside any query.
>
> ```css
> /* Specificity: 0,0,1,0 - one class */
> .nav { display: none; }
>
> /* Specificity: also 0,0,1,0 - same class */
> @media (min-width: 768px) {
>   .nav { display: flex; }
> }
> ```
>
> When both rules are active (screen >= 768px), the SECOND
> rule wins due to SOURCE ORDER, not because of higher
> specificity.
>
> This is why breakpoint ordering matters for mobile-first:
> ```css
> /* CORRECT order: ascending min-width */
> .nav { display: none; }  /* mobile base */
> @media (min-width: 768px) { .nav { display: flex; } }
> @media (min-width: 1024px) { .nav { gap: 2rem; } }
>
> /* WRONG: if 1024px query comes before 768px query,
>    at 1024px+ BOTH apply, 768px wins by source order */
> ```
>
> The last matching rule in source order wins (for equal
> specificity). So for mobile-first, breakpoints must be
> in ASCENDING order (smaller breakpoints before larger).
> For desktop-first, breakpoints must be in DESCENDING order.
>
> *What separates good from great:* The `not` keyword
> negates the entire media feature query but doesn't change
> specificity. `@media not (min-width: 768px)` = `@media
> (max-width: 767.98px)` - same specificity as any other
> query.

---

**Q5: What is `prefers-reduced-motion` and how do you
use it?** `[SENIOR]` PRODUCTION

*Why they ask:* Required accessibility knowledge for
modern frontend roles.

*Likely follow-up:* "What user conditions trigger this?"

> **Answer:**
>
> `prefers-reduced-motion: reduce` is a CSS media feature
> that detects when the user has enabled "Reduce Motion"
> in their OS accessibility settings. On macOS: System
> Settings > Accessibility > Display > Reduce Motion.
> On Windows: Settings > Ease of Access > Display >
> Show animations.
>
> Users who set Reduce Motion often have vestibular disorders,
> epilepsy, or motion sensitivity. Large animations can
> trigger nausea, dizziness, or seizures.
>
> Implementation options:
>
> Option 1: Global override (safe default)
> ```css
> @media (prefers-reduced-motion: reduce) {
>   *, *::before, *::after {
>     animation-duration: 0.01ms !important;
>     transition-duration: 0.01ms !important;
>   }
> }
> ```
>
> Option 2: Per-animation preference (better UX)
> ```css
> .hero-animation {
>   animation: fade-in 1s ease;
> }
> @media (prefers-reduced-motion: reduce) {
>   .hero-animation {
>     animation: none; /* no motion at all */
>     opacity: 1; /* ensure final state is visible */
>   }
> }
> ```
>
> Option 3: CSS variable approach
> ```css
> :root {
>   --transition: 0.3s ease;
>   --animation-duration: 1s;
> }
> @media (prefers-reduced-motion: reduce) {
>   :root {
>     --transition: 0;
>     --animation-duration: 0.01ms;
>   }
> }
> ```
>
> Important: `0.01ms` instead of `0` preserves the
> animation's end state. `animation-duration: 0` may
> snap to initial state; `0.01ms` triggers completion
> so the final keyframe applies.
>
> *What separates good from great:* WCAG 2.3.3 (AAA)
> requires providing a way to disable non-essential
> animation. WCAG 2.3.1 (AA, required) requires that
> flashing content doesn't occur more than 3 times per
> second. Implementing `prefers-reduced-motion` fulfills
> 2.3.3. Flashing is a seizure risk regardless of user
> settings.

---

**Q6: How does `hover: none` differ from touch detection
in JavaScript?** `[SENIOR]` TRADE-OFF

*Why they ask:* CSS-only touch detection pattern.

*Likely follow-up:* "Is CSS-only touch detection reliable?"

> **Answer:**
>
> `@media (hover: none)` detects when the primary input
> device CANNOT hover - indicating a touch-first device.
> `@media (pointer: coarse)` detects if the primary pointer
> is low-precision (finger vs mouse).
>
> ```css
> /* Touch-friendly tap targets */
> @media (hover: none) and (pointer: coarse) {
>   .button {
>     min-height: 44px; /* WCAG 2.5.5 touch target size */
>     min-width: 44px;
>   }
> }
>
> /* Show hover effect only on devices with hover */
> .nav-link::after {
>   /* underline animation - off by default */
>   transform: scaleX(0);
>   transition: transform 0.3s;
>   content: "";
>   display: block;
>   background: currentColor;
>   height: 2px;
> }
> @media (hover: hover) {
>   .nav-link:hover::after { transform: scaleX(1); }
> }
> ```
>
> CSS hover queries vs JavaScript `touchstart` detection:
>
> CSS advantage: no JavaScript, no flash of wrong styles,
> no event listener overhead. The media query fires at
> parse time.
>
> CSS limitation: some devices are both touch AND mouse
> (Surface Pro, iPad with keyboard). `hover: hover` can
> be true even on touch devices. The reliability has
> improved but isn't perfect.
>
> JavaScript limitation: `touchstart` fires on touch
> devices but many laptops with touchscreens fire it too.
> JavaScript detection via `navigator.maxTouchPoints > 0`
> is more reliable but still not perfect.
>
> *What separates good from great:* The safest approach:
> design touch-friendly by default (44px targets, no
> hover-dependent interactions), then use `@media (hover:
> hover)` to ADD hover enhancements. This follows
> progressive enhancement - works for everyone, enhanced
> for mouse users.

---

**Q7: What are CSS Container Queries and why are they
better than media queries for components?** `[SENIOR]`
COMPARISON

*Why they ask:* Container Queries are now production-ready
and change the responsive design mental model.

*Likely follow-up:* "What's the syntax for container queries?"

> **Answer:**
>
> Media queries are viewport-based: they fire based on
> the viewport size. A component using media queries can't
> be used at different sizes in different parts of the page
> without custom media query values per context.
>
> Container queries fire based on the component's containing
> block size:
>
> ```css
> /* Define a containment context */
> .card-wrapper {
>   container-type: inline-size; /* or size */
>   container-name: card;
> }
>
> /* Query the container, not the viewport */
> @container card (min-width: 400px) {
>   .card { flex-direction: row; }
>   .card-image { width: 40%; }
> }
> ```
>
> Problem this solves: a card component in a 300px sidebar
> should use vertical layout. The same component in a 800px
> main content area should use horizontal layout. With media
> queries, you'd need different classes or complex breakpoint
> math. With container queries, the card itself detects its
> available space.
>
> Container queries are in all major browsers (Chrome 105+,
> Firefox 110+, Safari 16+). Browser support is now
> sufficient for production use.
>
> Media queries are still needed for:
> - Viewport-level layout (page shell)
> - User preference queries (prefers-color-scheme, etc.)
> - Print styles
>
> Container queries are better for:
> - Component-level layout
> - Design system components used in different contexts
> - Anything you want to be truly reusable
>
> *What separates good from great:* Container queries
> require `container-type` to be set on an ancestor.
> An element cannot query itself - only its container.
> This prevents circular dependencies (an element's
> own size influencing its own layout which changes
> its size).

---

**Q8: Debug: your responsive layout breaks only in Chrome,
not Firefox.** `[SENIOR]` DEBUGGING

*Why they ask:* Real cross-browser debugging skill.

*Likely follow-up:* "What is the scrollbar width problem?"

> **Answer:**
>
> Step 1: Enable the DevTools Device toolbar in both
> browsers and compare the viewport width at the same
> zoom level. Chrome and Firefox may report different
> viewport widths for the same window size due to scrollbar
> rendering.
>
> On Windows, Chrome renders a standard OS scrollbar (~17px)
> that reduces the viewport width. Firefox may use a
> different scrollbar width or overlay scrollbars.
>
> ```css
> /* Scrollbar-aware viewport calculation */
> body {
>   overflow-y: scroll; /* Always show scrollbar */
>   /* Prevents layout shift when content overflows */
>   /* Keeps viewport width consistent */
> }
>
> /* Modern: scrollbar-gutter prevents layout shift */
> html { scrollbar-gutter: stable; }
> ```
>
> Step 2: Check media query boundary precision.
> `max-width: 768px` and `min-width: 768px` both include
> exactly 768px. Use `max-width: 767.99px` or better,
> switch to range syntax: `(width < 768px)` and
> `(width >= 768px)` to avoid 1px overlap.
>
> Step 3: Check for browser-specific CSS support.
> Container queries, `dvh`/`svh`/`lvh` units, `:has()`,
> CSS grid subgrid - support varies. Use Can I Use and
> DevTools compatibility indicators.
>
> *What separates good from great:* On a Windows machine
> with always-visible scrollbars, the viewport width is
> window-width - 17px. A 1024px window has a 1007px
> viewport. If your breakpoint is exactly 1007px, it
> fires at 1024px window width on Windows but 1024px
> viewport on Mac (where scrollbars are overlaid). This
> is the "scrollbar breakpoint problem" - mitigate with
> `scrollbar-gutter: stable` on `html`.

---

**Q9: How would you build a print stylesheet?** `[SENIOR]`
PRODUCTION

*Why they ask:* Print is often overlooked but important
for financial, legal, and content-heavy sites.

*Likely follow-up:* "How do you avoid breaking elements
across pages?"

> **Answer:**
>
> Print stylesheets use `@media print {}` or a separate
> `<link media="print">` file.
>
> ```css
> @media print {
>   /* Hide interactive and navigation elements */
>   nav, .sidebar, .header, footer,
>   .cookie-banner, .ads, .social-share {
>     display: none !important;
>   }
>
>   /* Ensure full-width single column */
>   .container { max-width: 100%; }
>   .main-content { width: 100%; float: none; }
>
>   /* Show link URLs */
>   a[href]::after {
>     content: " (" attr(href) ")";
>     font-size: 0.8em;
>     color: #666;
>   }
>   a[href^="#"]::after,
>   a[href^="javascript"]::after {
>     content: ""; /* skip internal and js links */
>   }
>
>   /* Page break control */
>   h1, h2, h3 { page-break-after: avoid; }
>   img { page-break-inside: avoid; }
>   blockquote { page-break-inside: avoid; }
>
>   /* Ensure dark text on white */
>   body { color: #000; background: #fff; }
>   * { color-adjust: exact !important; }
>
>   /* Set paper margins */
>   @page {
>     margin: 2cm;
>     @top-center { content: "Document Title"; }
>   }
> }
> ```
>
> `page-break-after: avoid` on headings prevents a heading
> from appearing at the bottom of a page without its content
> below. `page-break-inside: avoid` keeps elements together.
> Modern property: `break-after`, `break-inside`.
>
> `color-adjust: exact` (non-standard: `-webkit-print-color-
> adjust: exact`) forces the browser to print background
> colors (browsers suppress backgrounds by default to save ink).
>
> *What separates good from great:* Test print output
> with Chrome's DevTools (Ctrl+P shows print preview).
> Use `@page` with named pages to create different margins
> for first page vs rest. For multipage documents, use
> `counter(page)` in `@page` for automatic page numbering.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Cascade + specificity in queries |
| Hiring Manager | Mobile-first strategy and trade-offs |
| Bar Raiser | Container queries evolution discussion |
| Peer Engineer | prefers-reduced-motion accessibility |

---

### ⚖️ Comparison Table

| Approach | Responds to | Use Case | Reusable |
|---|---|---|---|
| Media queries (`min-width`) | Viewport width | Page layouts | Context-dependent |
| Container queries | Container width | Components | Yes |
| `clamp()` | Viewport (fluid) | Typography, spacing | Yes |
| Grid `auto-fill` | Container + item min | Card grids | Yes |
| `prefers-*` queries | User preference | A11y, dark mode | Yes |

---

### 🏛️ System Design

*(Omit: ★★☆ working-level - responsive design architecture
is covered in L5 Design Systems)*

---

### 📊 Diagram

*(Omit: media query syntax is better conveyed through code
examples than diagrams)*

---
---

# Responsive Design Patterns and Mobile-First

🎯 **Interview Weight:** high - Mobile-first is the standard
for modern web development; understanding the philosophy
and pattern differences distinguishes candidates

---

### 🎯 Model Answer

**30 seconds:**

> Mobile-first responsive design means writing base CSS for
> the smallest viewport and progressively enhancing for
> larger screens using `min-width` media queries. The key
> patterns: fluid typography with `clamp()`, fluid grids
> with CSS Grid's `auto-fill + minmax`, logical containers
> with `max-width`, and content-based breakpoints rather
> than device-based breakpoints.

**3 minutes (Senior):**

> Mobile-first is both a code strategy and a design
> philosophy. In code: base styles handle mobile, `min-width`
> queries layer in enhancements. This forces progressive
> enhancement - each breakpoint adds capability rather
> than overriding it.
>
> The philosophy: prioritize content hierarchy on the
> smallest viewport. If information architecture is clear
> on a 375px screen, it will scale gracefully. Desktop-first
> creates "add everything to desktop, hide on mobile" which
> still ships all that CSS and markup to mobile devices.
>
> Key patterns in modern responsive design:
>
> Fluid typography: `font-size: clamp(1rem, 2.5vw, 1.5rem)`.
> No breakpoints needed for font scaling. The size interpolates
> between the minimum (1rem) and maximum (1.5rem) based on
> viewport width.
>
> Fluid spacing: `padding: clamp(1rem, 5%, 3rem)`. Spacing
> scales with viewport without breakpoints.
>
> Intrinsic layout: CSS Grid's `auto-fill + minmax` creates
> columns without media queries. Items arrange themselves
> based on available space.
>
> The goal: reduce media queries as much as possible.
> Every breakpoint is a maintenance point. Fluid values
> (clamp, minmax) reduce the breakpoint count by making
> values continuously adaptive rather than discretely
> stepped.

*Adapting up:* Discuss the "Intrinsic Web Design" approach,
CSS Grid + Flexbox no-media-query patterns, container queries.

*Adapting down:* Mobile-first means writing CSS for mobile
first, then adding styles for bigger screens with min-width
queries.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about mobile-first responsive
design - the strategy, the patterns, and the technical
implementation."

**(2) First principles:** "From first principles, a responsive
website has continuous content that must render in containers
of highly variable width. The solution: fluid units, flexible
layouts, and conditional overrides at breakpoints."

**(3) Bridge:** "Think of mobile-first like dressing for
the weather: start with a base layer (mobile), add layers
as conditions warrant (larger screens). You don't start
dressed for a blizzard and strip layers for summer."

---

### 📘 Concept Explanation

**What it is:**

A CSS authoring strategy where base styles target the
smallest viewport and media queries progressively add
complexity for larger screens, combined with fluid layout
techniques that minimize the need for discrete breakpoints.

**The problem it solves:**

A website must look correct and be usable on screens from
320px to 4K, on touch and mouse devices, in portrait and
landscape orientation. Discrete breakpoints alone create
layout that "pops" between states rather than flowing
smoothly.

**How it works:**

```
RESPONSIVE DESIGN TOOLKIT:

1. MOBILE-FIRST MEDIA QUERIES:
   base:              /* mobile styles */
   @media (>=768px):  /* tablet enhancements */
   @media (>=1024px): /* desktop enhancements */

2. FLUID TYPOGRAPHY:
   font-size: clamp(min, preferred, max);
   clamp(1rem, 0.875rem + 0.5vw, 1.25rem)
   /* min=1rem, grows with viewport, max=1.25rem */

3. FLUID SPACING:
   padding: clamp(1rem, 3%, 3rem);
   /* Scales proportionally, bounded */

4. INTRINSIC GRID:
   grid-template-columns:
     repeat(auto-fill, minmax(280px, 1fr));
   /* No breakpoints - columns self-organize */

5. FLUID CONTAINERS:
   .container {
     width: 100%;
     max-width: 1200px;
     margin-inline: auto;
     padding-inline: clamp(1rem, 4%, 2rem);
   }

6. LOGICAL PROPERTIES:
   margin-inline vs margin-left/right
   padding-block vs padding-top/bottom
   /* Direction-independent - works in RTL */

7. INTRINSIC SIZING:
   width: min(100%, 65ch);
   /* Whichever is smaller */
   /* Content never overflows at small sizes */
```

**The key insight:**

The best responsive design has as FEW media queries as
possible. Every media query is a discrete jump; fluid
values create smooth continuous adaptation. `clamp()`,
`minmax()`, `min()`, `max()` are the tools for removing
breakpoints from typography, spacing, and layout.

**When to use it:**

- Every website (mobile-first is the standard, not optional)
- Design systems where components need fluid sizing
- When building reusable components (container queries)

**When NOT to use it:**

There's no "not." Mobile-first responsive design is the
current standard for web development. The question is
what level of fluidity - discrete breakpoints only, or
fluid + breakpoints.

**Alternatives:**

- Desktop-first: still used for internal enterprise apps
  where users are assumed to be on desktop
- Separate mobile/desktop domains (m.example.com): legacy
  approach, now abandoned

**First-principles derivation:**

Content must be accessible on any device. A smartphone
display is fundamentally different from a 27" monitor.
The responsive design pattern provides a single codebase
that adapts to the rendering environment through fluid
values and conditional overrides.

---

### 💻 Code Example

**BAD: hard-coded widths, absolute breakpoints**

```css
/* BAD: works only at specific widths */
.hero-title {
  font-size: 64px; /* too large on 375px mobile */
}
@media (max-width: 480px) {
  .hero-title { font-size: 32px; }
}
@media (max-width: 768px) {
  .hero-title { font-size: 48px; }
}
/* Still jumps: 320px → 32px, 481px → 64px (too big) */
```

> **Code walkthrough:** Three discrete sizes create visible
> jumps. A 481px screen gets the full 64px size which may
> overflow. The gap between breakpoints is not handled.
> This pattern requires maintaining many breakpoints.

**GOOD: fluid typography with clamp()**

```css
/* GOOD: fluid, no media queries */
.hero-title {
  /* min: 1.875rem (30px)
     preferred: 2rem + 3vw (scales with viewport)
     max: 4rem (64px) */
  font-size: clamp(1.875rem, 2rem + 3vw, 4rem);
}

/* Fluid body copy */
body {
  font-size: clamp(1rem, 0.95rem + 0.26vw, 1.125rem);
  line-height: 1.5;
}

/* Fluid spacing */
.section {
  padding-block: clamp(3rem, 8vw, 8rem);
}
```

> **Code walkthrough:** `clamp(min, preferred, max)` creates
> a continuously scaling value. At 320px viewport: 2rem +
> 3*0.32rem = 2.96rem (below max, above min). At 1440px:
> 2rem + 3*14.4px = ~5.5rem → clamped to 4rem. No breakpoints
> needed. The font grows smoothly with the viewport.

**PRODUCTION: full responsive component**

```css
/* Fluid article layout with content + sidebar */
.page-layout {
  display: grid;
  grid-template-columns:
    /* sidebar auto-hides when not enough space */
    1fr
    min(240px, 30%);
  grid-template-areas: "main aside";
  gap: clamp(1rem, 3%, 3rem);
}

/* Stack at small sizes */
@media (max-width: 680px) {
  .page-layout {
    grid-template-columns: 1fr;
    grid-template-areas: "main" "aside";
  }
}

/* Article body - readable line length */
.article-body {
  /* max ~65 characters */
  max-width: 65ch;
  margin-inline: auto;
}

/* Images scale within container */
img { max-width: 100%; height: auto; }
```

> **Code walkthrough:** This layout uses one media query
> for the column stack but fluid values for spacing and
> sizing. `65ch` for article width is a typographic
> constraint - it limits to 65 characters per line
> regardless of font size, which scales correctly at
> all sizes. `min(240px, 30%)` for sidebar is "whichever
> is smaller" - prevents a 240px sidebar on a 375px screen.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> Mobile-first means writing base CSS for mobile and using
> `min-width` media queries to add styles for larger screens.
> Start with a single-column layout for mobile. At 768px,
> add a sidebar. At 1024px, make the sidebar wider. This is
> progressive enhancement. Key tools: `max-width: 100%` for
> images, `width: 100%` for containers, and common breakpoints
> at 480px, 768px, 1024px, and 1440px. Modern approach: use
> `clamp()` for font sizes and `repeat(auto-fill, minmax(...))` for grids to reduce the number of breakpoints needed.

---

**Senior / Staff (5+ years):**

> Modern responsive design should minimize media queries,
> not just write mobile-first. Every breakpoint is a
> maintenance point. `clamp()` for typography, `minmax`
> for grids, `min()` for containers - these create fluid
> layouts that adapt continuously without discrete jumps.
>
> Container queries are the next evolution. A component
> shouldn't know about the viewport - it should respond to
> its own container. This makes components truly reusable
> across different layout contexts.
>
> The "Intrinsic Web Design" approach (Jen Simmons): let
> content define the layout, not fixed breakpoints. CSS Grid
> and Flexbox with flexible units can create layouts that
> look right at every size naturally.

---

### ⚠️ Common Misconceptions

**"More breakpoints = more responsive"**

More breakpoints = more maintenance burden and more discrete
layout jumps. Fluid values eliminate the need for breakpoints.
Aim for 2-3 major structural breakpoints maximum.

**"Mobile-first means a separate mobile site"**

One codebase, one HTML, one URL - CSS adapts the presentation.
Separate mobile sites (m.example.com) are a legacy pattern
abandoned for performance, SEO, and maintenance reasons.

**"Responsive design is just setting max-width: 100% on images"**

That's one component. Responsive design requires: fluid
layout, appropriate typography scaling, touch-friendly
interaction targets (min 44px), and consideration of
bandwidth (image formats, lazy loading).

---

### 🚨 Failure Modes and Diagnosis

**Symptom: layout looks wrong on specific real device**

```
# Chrome DevTools Device toolbar is a simulation only
# For real device testing:
# - Android: USB debugging + chrome://inspect
# - iOS: Safari Web Inspector + iPhone/iPad
# Or: BrowserStack / Sauce Labs for remote testing
```

---

**Symptom: text too small on mobile**

Cause: `font-size` below 16px base on mobile triggers
iOS auto-zoom on input focus. Set `font-size: 16px` minimum
on inputs, or use `touch-action: manipulation` to prevent
double-tap zoom that triggers the size adjustment.

---

**Symptom: horizontal scroll on mobile**

```
# Find the overflowing element:
# Add to CSS temporarily:
* {
  outline: 1px solid red;
}
/* Or DevTools: Layers panel shows overflow */
# Common causes: fixed-width elements, negative margins,
# pre/code blocks without overflow-x: auto
```

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| "Define mobile-first" | 2 min | Strategy vs device |
| Why mobile-first wins | 3 min | Progressive enhancement |
| Fluid typography | 3-4 min | clamp() use |
| Reducing breakpoints | 3 min | CSS Grid auto-fill |
| Intrinsic Web Design | 4 min | Content-first philosophy |
| Image responsiveness | 3-4 min | srcset, picture, aspect-ratio |
| Container queries role | 3-4 min | Component portability |
| Performance and responsive | 4 min | Bandwidth, lazy loading |
| Touch target requirements | 2-3 min | WCAG 44px |

---

**Q1: What is the difference between mobile-first and
responsive design?** `[JUNIOR]` CONCEPTUAL

*Why they ask:* Clarifies vocabulary that many candidates
conflate.

*Likely follow-up:* "Can you be responsive without being
mobile-first?"

> **Answer:**
>
> Responsive design: a single website that adapts its
> layout and presentation to different screen sizes using
> fluid grids, flexible images, and media queries. Coined
> by Ethan Marcotte in 2010.
>
> Mobile-first: a specific implementation strategy for
> responsive design. Write base CSS styles for the smallest
> viewport, then progressively add complexity for larger
> screens using `min-width` media queries.
>
> You can be responsive without mobile-first (desktop-first
> responsive design uses `max-width` queries). But mobile-
> first is considered best practice because:
>
> 1. Performance: mobile devices load minimal base CSS without
>    needing to download and override large desktop styles
> 2. Progressive enhancement: add features as space allows
>    vs graceful degradation (removing features for small screens)
> 3. Forces priority: if the most important content works
>    on 375px, the hierarchy is clear
> 4. Content-first: you must decide what's essential on mobile
>    before adding extras on desktop
>
> Both are responsive. Mobile-first is the recommended
> implementation strategy.
>
> *What separates good from great:* The original responsive
> design article used `max-width` media queries (desktop-first).
> Mobile-first came later as a philosophy from Luke Wroblewski
> in his 2011 book. The shift was driven by mobile traffic
> surpassing desktop (happened ~2016 globally). Designing
> for the majority case first.

---

**Q2: What is `clamp()` and how do you use it for
responsive typography?** `[MID]` MECHANISM

*Why they ask:* `clamp()` is the modern fluid typography
tool that reduces breakpoints.

*Likely follow-up:* "How do you calculate the preferred
value in clamp()?"

> **Answer:**
>
> `clamp(minimum, preferred, maximum)` returns the preferred
> value, but never below minimum and never above maximum.
> It's equivalent to `max(min, min(preferred, max))`.
>
> For typography: `font-size: clamp(1rem, 2.5vw, 2rem)`.
> At small viewports: 2.5vw might equal 0.5rem - clamped
> to 1rem. At large viewports: 2.5vw might equal 3rem -
> clamped to 2rem. In between: scales linearly with vw.
>
> The problem with pure `vw`: `font-size: 2.5vw` on a
> 320px screen = 8px (too small). On a 2560px screen = 64px
> (too large). `clamp()` bounds the extremes.
>
> Computing the preferred value: use the "ideal at target
> viewport" formula:
>
> ```
> # Desired: 1rem at 400px, 1.5rem at 1200px
> # Slope = (1.5 - 1) / (1200 - 400) = 0.5 / 800
> # = 0.000625 rem/px = 0.0625vw/1%
> # Intercept = 1 - 0.625 * (400/100)
> # = 1 - 0.25 = 0.75rem
> # Preferred: 0.75rem + 0.0625 * 100vw
> #          = 0.75rem + 6.25vw (but that's too steep)
>
> # Simplified: clamp(1rem, 1rem + 1vw, 1.5rem)
> # At 400px: 1 + 4 = 5... hmm too big
> # Try: clamp(1rem, 0.75rem + 0.625vw, 1.5rem)
> # At 400px: 0.75 + 2.5 = 3.25rem... nope
>
> # Use CSS Clamp Calculator tool (utilities like
> # fluid.style or utopia.fyi) for precise values
> ```
>
> Practical formula: `font-size: clamp(1rem,
> calc(1rem + 1.5 * ((100vw - 400px) / 1000)), 1.5rem)`
> Grows from 1rem at 400px to 1.5rem at 1400px.
>
> *What separates good from great:* utopia.fyi is the
> canonical tool for generating fluid type scales and
> spacing scales using clamp(). It generates a complete
> CSS custom property scale with clamp values for the
> entire typography system.

---

**Q3: What are "intrinsic web design" patterns?** `[SENIOR]`
ARCHITECTURE

*Why they ask:* Shows awareness of the evolution beyond
breakpoint-heavy responsive design.

*Likely follow-up:* "Name three CSS features that enable
intrinsic design."

> **Answer:**
>
> Intrinsic Web Design (Jen Simmons, 2018) describes a
> CSS-first approach where content and CSS capabilities
> determine layout without predetermined breakpoints.
>
> Core idea: instead of saying "at 768px do X," you describe
> the layout constraints and let CSS calculate the best
> layout for any size.
>
> Enabling features:
>
> 1. CSS Grid with `auto-fill/auto-fit + minmax`:
>    ```css
>    grid-template-columns:
>      repeat(auto-fill, minmax(250px, 1fr));
>    /* Columns reorganize automatically at any width */
>    ```
>
> 2. Flexbox with `flex-wrap: wrap`:
>    ```css
>    .toolbar {
>      display: flex;
>      flex-wrap: wrap;
>      gap: 0.5rem;
>    }
>    /* Items wrap when space runs out - no breakpoints */
>    ```
>
> 3. `clamp()`, `min()`, `max()`:
>    ```css
>    width: min(65ch, 100%); /* never wider than 65ch */
>    padding: clamp(1rem, 3%, 3rem); /* fluid spacing */
>    ```
>
> 4. Container Queries:
>    Components respond to their own container, not viewport.
>
> 5. CSS `aspect-ratio`:
>    ```css
>    .video { aspect-ratio: 16/9; }
>    /* Maintains ratio at any width - no padding-top hack */
>    ```
>
> The result: layouts that work at any viewport size with
> fewer breakpoints. Breakpoints still exist but only for
> major structural changes, not minor adjustments.
>
> *What separates good from great:* The padding-top hack
> for aspect ratio (`padding-top: 56.25%` for 16:9) is
> completely replaced by `aspect-ratio: 16/9`. This is
> a canonical example of how CSS features replace hacks
> designed to work around missing capabilities.

---

**Q4: How do you make images responsive?** `[JUNIOR]`
HANDS-ON

*Why they ask:* Images are one of the most common responsive
challenges and performance concerns.

*Likely follow-up:* "What is the srcset attribute?"

> **Answer:**
>
> Three levels of responsive images:
>
> Level 1: CSS fluid images (required always):
> ```css
> img { max-width: 100%; height: auto; }
> /* Image scales down when container is smaller */
> /* height: auto maintains aspect ratio */
> ```
>
> Level 2: Different resolution images with `srcset`:
> ```html
> <img
>   src="hero.jpg"
>   srcset="
>     hero-400.jpg 400w,
>     hero-800.jpg 800w,
>     hero-1600.jpg 1600w
>   "
>   sizes="
>     (max-width: 768px) 100vw,
>     50vw
>   "
>   alt="Hero image"
> >
> ```
>
> `srcset` provides options with widths. `sizes` tells the
> browser how wide the image will be rendered (before layout
> is computed). Browser picks the best `srcset` option for
> the viewport/screen density.
>
> Level 3: Art direction (different crops) with `<picture>`:
> ```html
> <picture>
>   <source
>     media="(max-width: 600px)"
>     srcset="hero-portrait.jpg"
>   >
>   <source
>     media="(min-width: 601px)"
>     srcset="hero-landscape.jpg"
>   >
>   <img src="hero-landscape.jpg" alt="Hero image">
> </picture>
> ```
>
> `<picture>` selects the SOURCE based on media query,
> enabling different image crops (portrait on mobile,
> landscape on desktop).
>
> *What separates good from great:* Add `loading="lazy"`
> to below-the-fold images and `decoding="async"` to all
> non-critical images. Combine with `aspect-ratio` to
> reserve space before the image loads, preventing
> Cumulative Layout Shift (CLS).

---

**Q5: What is the "hamburger menu" anti-pattern?** `[SENIOR]`
TRADE-OFF

*Why they ask:* Shows UX judgment beyond pure CSS knowledge.

*Likely follow-up:* "What alternatives exist?"

> **Answer:**
>
> The hamburger menu (three horizontal lines = navigation
> hidden behind a button) became the dominant mobile
> navigation pattern post-2012. It hides navigation to
> save space but introduces multiple problems:
>
> Problems:
> 1. Discoverability: users must know to tap the icon.
>    Studies show hamburger menus reduce engagement with
>    navigation items (users tap them less than visible nav).
> 2. Extra tap: every navigation action requires two taps
>    (open menu, then navigate). Friction.
> 3. Obscures content: full-screen nav overlays hide
>    underlying content.
> 4. Accessibility: a button that toggles nav requires
>    careful ARIA management (`aria-expanded`, focus trap,
>    Escape key handling).
>
> Alternatives:
>
> 1. Bottom navigation bar (tabs): visible on mobile,
>    instant navigation. Best for primary routes (4-5 items).
>    Used by Instagram, Twitter, iOS apps.
>
> 2. Priority+ pattern: show items that fit, collapse
>    overflow to "More" menu.
>
> 3. Progressive disclosure: on mobile, show only top-level
>    nav. Deep nav accessible from within sections.
>
> 4. Sidebar with nav: always-visible left or bottom panel
>    on larger mobile (tablet).
>
> When hamburger IS appropriate: secondary navigation,
> admin interfaces, when primary navigation is very long.
>
> *What separates good from great:* Nielsen Norman Group
> research shows that tab bars (bottom navigation) are
> more discoverable and have higher usage rates than
> hamburger menus. Most apps have moved from hamburger to
> tab bars for primary navigation. Mobile-first responsive
> design should consider which navigation model fits the
> information architecture, not default to hamburger.

---

**Q6: What are WCAG touch target size requirements?**
`[SENIOR]` PRODUCTION

*Why they ask:* Accessibility knowledge for interactive
responsive elements.

*Likely follow-up:* "What does iOS require for touch targets?"

> **Answer:**
>
> WCAG 2.5.5 (Level AA, WCAG 2.2) requires interactive
> targets to be at least 44x44 CSS pixels OR have sufficient
> spacing around smaller targets (the spacing counts as
> part of the target).
>
> Implementation:
> ```css
> /* Ensure minimum 44x44px touch target */
> .btn {
>   min-height: 44px;
>   min-width: 44px;
>   padding: 0.5rem 1rem; /* visual padding */
> }
>
> /* For small icons, use padding to extend tap area */
> .icon-btn {
>   padding: 0.75rem; /* extends click area around 24px icon */
>   /* total: 24 + 24 = 48px clickable area */
> }
>
> /* Media query: increase on coarse pointer devices */
> @media (pointer: coarse) {
>   .btn { min-height: 48px; }
> }
> ```
>
> Platform guidelines:
> - Apple HIG: 44x44pt minimum (matches WCAG)
> - Google Material Design 3: 48x48dp minimum
> - Android accessibility: 48x48dp minimum
>
> Common mistake: visually small buttons that have too-small
> tap targets. The hit area (touchable region including padding)
> must be 44x44px minimum, not the visual button size.
>
> WCAG 2.5.8 (Level AA, WCAG 2.2): target size minimum is
> 24x24 CSS pixels if sufficient spacing exists. But best
> practice remains 44x44 minimum.
>
> *What separates good from great:* iOS has a system feature
> called "Reachability" and "Larger Accessibility Text." When
> Dynamic Type is enabled, buttons must scale their height.
> Use `em` or `rem` for button sizes so they scale with
> text size settings. Fixed `px` heights break when the
> user has set a large system font size.

---

**Q7: How does `aspect-ratio` replace the padding-top
hack?** `[SENIOR]` MECHANISM

*Why they ask:* A classic responsive technique replaced
by modern CSS.

*Likely follow-up:* "What was wrong with the padding-top hack?"

> **Answer:**
>
> The padding-top hack: to maintain a 16:9 aspect ratio
> for a video container before CSS `aspect-ratio` existed.
>
> Old approach (hack):
> ```css
> /* padding-top trick */
> .video-wrapper {
>   position: relative;
>   padding-top: 56.25%; /* 9/16 = 0.5625 */
>   height: 0;
>   overflow: hidden;
> }
> .video-wrapper iframe {
>   position: absolute;
>   top: 0; left: 0;
>   width: 100%; height: 100%;
> }
> ```
>
> Why `padding-top: 56.25%` works: percentage-based padding
> is computed relative to the element's WIDTH, not height.
> For a 1000px-wide container, `padding-top: 56.25%` = 562.5px
> height. This maintains 16:9 ratio.
>
> Problems: requires wrapper element, `height: 0`, absolute
> positioning of child. Complex, non-obvious, hard to
> understand from reading the code.
>
> Modern approach:
> ```css
> .video-wrapper {
>   aspect-ratio: 16 / 9;
>   width: 100%;
> }
> .video-wrapper iframe {
>   width: 100%; height: 100%;
> }
> ```
>
> Direct, readable, no positional tricks. Browser handles
> the ratio calculation.
>
> Other uses: `aspect-ratio: 1` for square avatars, `3 / 2`
> for photo thumbnails, `4 / 3` for classic video content.
>
> `aspect-ratio` is supported in all major browsers since
> 2021 (Chrome 88, Safari 15, Firefox 89).
>
> *What separates good from great:* Combine with
> `object-fit: cover` for images and videos:
> `img { aspect-ratio: 16/9; object-fit: cover; width: 100%; }`
> This fills the ratio box while cropping to the aspect ratio,
> regardless of the image's natural dimensions.

---

**Q8: How do you handle responsive design in a design
system?** `[STAFF]` ARCHITECTURE

*Why they ask:* Design system architecture at scale.

*Likely follow-up:* "How do you version breakpoints?"

> **Answer:**
>
> In a design system, responsive design is systematized
> through design tokens, component-level container queries,
> and a breakpoint token system.
>
> Token approach:
> ```css
> :root {
>   /* Breakpoint tokens as custom media (proposed) */
>   --breakpoint-sm: 480px;
>   --breakpoint-md: 768px;
>   --breakpoint-lg: 1024px;
>   --breakpoint-xl: 1440px;
>
>   /* Spacing scale - fluid */
>   --space-sm:  clamp(0.5rem, 1.5vw, 1rem);
>   --space-md:  clamp(1rem, 3vw, 2rem);
>   --space-lg:  clamp(2rem, 5vw, 4rem);
>
>   /* Type scale - fluid */
>   --text-sm:   clamp(0.875rem, 1vw, 1rem);
>   --text-base: clamp(1rem, 1.5vw, 1.125rem);
>   --text-lg:   clamp(1.125rem, 2vw, 1.5rem);
>   --text-xl:   clamp(1.5rem, 3vw, 2.25rem);
> }
> ```
>
> Components use container queries:
> ```css
> .card-container {
>   container-type: inline-size;
>   container-name: card;
> }
> @container card (min-width: 400px) {
>   .card { flex-direction: row; }
> }
> ```
>
> This makes the design system components independent of
> viewport. A card works correctly whether placed in a
> 300px sidebar or a 900px main content area.
>
> Breakpoint changes: tokens are updated in ONE place,
> all components inherit the new values without code changes.
>
> *What separates good from great:* Use Sass or CSS PostCSS
> to generate breakpoint mixins from the token values.
> This creates a consistent authoring experience:
> `@include breakpoint(md) { ... }` rather than raw pixel
> values. In design tool integration (Figma Tokens plugin),
> breakpoint tokens can be exported and kept in sync with
> the CSS tokens.

---

**Q9: A card grid is fine on desktop and mobile but
broken at exactly 768px. How do you diagnose?** `[MID]`
DEBUGGING

*Why they ask:* Real debugging scenario for responsive layouts.

*Likely follow-up:* "How do you prevent this class of problem?"

> **Answer:**
>
> The "exactly at breakpoint" failure is a classic edge case.
>
> Step 1: Open DevTools Device toolbar. Manually drag the
> width to exactly 768px. Observe the layout. Then try 767px
> and 769px to find exactly which pixels cause the issue.
>
> Step 2: Check for overlapping queries. If you have both
> `max-width: 768px` and `min-width: 768px`, BOTH fire
> at exactly 768px. The cascade determines which wins
> based on source order and specificity.
>
> Fix 1: Use non-overlapping breakpoints:
> ```css
> @media (max-width: 767.99px) { /* mobile only */ }
> @media (min-width: 768px) { /* tablet+ */ }
> /* .99 prevents the 1px overlap */
> ```
>
> Fix 2: Range syntax (Level 4 - cleaner):
> ```css
> @media (width < 768px) { /* mobile: strictly less */ }
> @media (width >= 768px) { /* tablet+: at least 768 */ }
> ```
>
> Step 3: Check if the issue is the scrollbar. On Windows,
> at exactly 768px viewport, the scrollbar (17px) means
> the content area is 751px wide. If your grid has a
> `min-width: 768px` breakpoint, it fires, but the content
> area is only 751px - too narrow for the desktop layout.
>
> `scrollbar-gutter: stable` on `html` reserves scrollbar
> space always, preventing this inconsistency.
>
> *What separates good from great:* Using CSS Grid's
> `auto-fill + minmax` eliminates this problem entirely
> because there's no discrete breakpoint. The columns
> self-organize continuously.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | clamp() mechanics and fluid typography |
| Hiring Manager | Mobile-first philosophy and business rationale |
| Bar Raiser | Intrinsic design and container queries |
| Peer Engineer | Debugging responsive edge cases |

---

### ⚖️ Comparison Table

| Pattern | Breakpoints | Best For | Complexity |
|---|---|---|---|
| Mobile-first + min-width | Discrete | Structural layout | Low |
| `clamp()` fluid | None | Typography, spacing | Medium |
| Grid `auto-fill` | None | Card grids | Low |
| Container queries | None (container-based) | Reusable components | Medium |
| Desktop-first + max-width | Discrete | Legacy codebases | Low (legacy) |

---

### 🏛️ System Design

*(Omit: ★★☆ working-level - responsive design systems
architecture is covered in L5 Design Systems)*

---

### 📊 Diagram

*(Omit: responsive design is best illustrated with code
examples, which are provided above)*
