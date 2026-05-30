---
layout: default
title: "HTML - L1 Forms and Media"
parent: "HTML"
nav_order: 3
permalink: /html/l1-forms-and-media/
render_with_liquid: false
---

# HTML Forms

🎯 **Interview Weight:** high (★☆☆) - Forms are the primary
user input mechanism on the web; every production app uses them

---

### 🎯 Model Answer

**30 seconds:**

> HTML forms collect user input and submit it to a server.
> A `<form>` element wraps input controls (`<input>`, `<select>`,
> `<textarea>`) and defines the `action` (where to send data)
> and `method` (GET or POST). Form controls are associated with
> labels via `<label for="id">` matching the input's `id`.
> The browser handles submission, encoding, and basic validation
> (required, type, pattern) natively.

**3 minutes (Senior):**

> HTML forms provide the browser-native mechanism for collecting
> and submitting structured user data. The form element is a
> container that groups controls and defines submission behavior:
> `action` (URL to submit to), `method` (GET or POST), `enctype`
> (for file uploads: `multipart/form-data`).
>
> The critical accessibility pattern: every form control needs
> an associated `<label>`. The association uses `for="id"` matching
> the control's `id`, or wrapping the control inside `<label>`.
> Without labels: screen readers cannot announce what each field is
> for; form controls have no visible name for assistive technology.
>
> HTML5 form validation is often underutilized. `type="email"`,
> `type="url"`, `required`, `pattern`, `min`/`max`, `minlength`/`maxlength`
> give the browser native validation without JavaScript. The
> Constraint Validation API adds programmatic control.
>
> Form grouping: `<fieldset>` groups related controls; `<legend>`
> provides the group name. Essential for radio button groups
> (screen readers announce "legend: choice" for each option).

*Adapting up:* Discuss the Constraint Validation API, custom
validity messages, and how React controlled inputs differ from
native form behavior.

*Adapting down:* Forms collect user input. Each input field
needs a label so users know what to type.

**Blank Mind Recovery:**

**(1) Restate:** "HTML forms - the mechanism for collecting and
submitting user data. Let me walk through the key pieces."

**(2) First principles:** "A form has: where to go (action),
how to send (method), and what controls to collect (inputs)."

**(3) Bridge:** "Think of a paper form with labeled fields:
the form element is the paper, inputs are blank lines, labels
are the field names."

---

### 📘 Concept Explanation

**What it is:**

HTML forms are the web's native mechanism for collecting user
input and submitting it to a server. The `<form>` element groups
controls; `<input>`, `<select>`, `<textarea>`, and `<button>`
provide the interactive controls.

**The problem it solves:**

Web applications need user input: login credentials, search
queries, data entry, file uploads. Forms provide browser-native
input collection with built-in keyboard handling, validation,
and submission - without requiring JavaScript for basic cases.

**How it works:**

```
FORM STRUCTURE:
<form action="/submit" method="POST"
      enctype="application/x-www-form-urlencoded">

  <!-- Label + input pair (accessibility-required) -->
  <label for="email">Email address</label>
  <input type="email"
         id="email"
         name="email"
         placeholder="you@example.com"
         required
         autocomplete="email">

  <!-- Fieldset groups related inputs -->
  <fieldset>
    <legend>Notification preference</legend>
    <label>
      <input type="radio" name="notify" value="email">
      Email
    </label>
    <label>
      <input type="radio" name="notify" value="sms">
      SMS
    </label>
  </fieldset>

  <!-- Select dropdown -->
  <label for="country">Country</label>
  <select id="country" name="country">
    <option value="">Select country</option>
    <option value="us">United States</option>
    <option value="uk">United Kingdom</option>
  </select>

  <!-- Textarea -->
  <label for="message">Message</label>
  <textarea id="message" name="message"
            rows="5" maxlength="500"></textarea>

  <!-- Submit button -->
  <button type="submit">Submit</button>
  <button type="reset">Clear form</button>
</form>

SUBMISSION ENCODING:
  GET:  /submit?email=user%40ex.com&notify=email
  POST: body = email=user%40ex.com&notify=email

  File upload (multipart/form-data required):
  <form enctype="multipart/form-data" method="POST">
    <input type="file" name="attachment" accept=".pdf,.doc">
  </form>

INPUT TYPES (HTML5):
  text | email | password | number | tel | url
  date | time | datetime-local | month | week
  color | range | checkbox | radio | file
  hidden | submit | reset | button | image | search
```

**The key insight:**

The `name` attribute on form controls is what gets submitted -
it becomes the key in the form data. The `id` attribute is for
CSS and JavaScript targeting, including label association. They
can be the same value but serve different purposes.

**When to use it:**

Always use `<form>` for data submission (login, registration,
search, settings). Even with JavaScript-powered submission, wrap
inputs in a `<form>` to get browser benefits: Enter key submission,
native validation, accessibility.

**When NOT to use it:**

Don't use forms for navigation (use `<a>`). Don't omit `<label>`
elements (use `aria-label` as last resort only). Don't use
`type="text"` when a more specific type applies (misses native
validation and mobile keyboard optimization).

**Alternatives:**

- React controlled inputs → manage form state in JavaScript
- Form libraries (React Hook Form, Formik) → complex validation
- `fetch` + JSON → submit without form encoding
- Service workers → offline form submission queuing

**First-principles derivation:**

Given users need to submit structured data to servers, the
minimum required structure: a container (form) that defines
destination and encoding, labelled fields with names that become
data keys, and a submission trigger. HTML's form model was
designed to work without JavaScript - the browser handles
encoding, validation, and submission natively.

---

### 💻 Code Example

**Accessible form: BAD vs GOOD**

```html
<!-- BAD: placeholder as label, no label element -->
<form>
  <!-- Placeholder disappears on input - user forgets field purpose -->
  <!-- Screen reader: announces "edit blank" - no field name -->
  <input type="text" placeholder="Enter your name">
  <input type="email" placeholder="Enter your email">
  <input type="submit" value="Submit">
</form>
```

```html
<!-- GOOD: proper labels, input types, validation -->
<form action="/register" method="POST" novalidate>
  <!-- novalidate: disable browser UI but keep Constraint API -->
  
  <div class="field">
    <label for="name">
      Full name
      <span aria-hidden="true">*</span>
      <span class="sr-only">(required)</span>
    </label>
    <!-- autocomplete hints keyboard/password managers -->
    <input type="text"
           id="name"
           name="fullName"
           required
           autocomplete="name"
           aria-describedby="name-hint"
           aria-required="true">
    <p id="name-hint" class="hint">
      Enter your first and last name.
    </p>
  </div>

  <div class="field">
    <label for="email">Email address</label>
    <input type="email"
           id="email"
           name="email"
           required
           autocomplete="email"
           inputmode="email">
  </div>

  <fieldset>
    <legend>Preferred contact method</legend>
    <label>
      <input type="radio" name="contact" value="email">
      Email
    </label>
    <label>
      <input type="radio" name="contact" value="phone">
      Phone
    </label>
  </fieldset>

  <button type="submit">Create account</button>
</form>
```

> **Code walkthrough:** The GOOD form has explicit `<label>` elements
> linked by `for`/`id` pairs - clicking the label focuses the input.
> `aria-describedby` links the hint text to the input, which screen
> readers announce after the field name. `autocomplete` hints the
> browser (and password managers) about field purpose, improving
> form fill rate. The `<fieldset>` + `<legend>` pattern for radio
> groups means screen readers announce "Preferred contact method:
> Email" for each option - users know the group context.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> HTML forms collect user input with `<input>`, `<select>`, and
> `<textarea>` elements. Each input needs a `<label>` linked by
> `for`/`id`. The form submits via `action` and `method`. HTML5
> input types (email, number, date) provide native validation and
> mobile keyboard optimization without JavaScript.

---

**Senior / Staff:**

> Forms are a contract between the browser, user, and server.
> The `name` attribute defines the submission key; `autocomplete`
> values (from the WHATWG spec) enable browser autofill and
> password manager integration - critical for conversion rates.
> `<fieldset>`+`<legend>` is non-negotiable for radio groups: without
> it, screen readers cannot provide group context for each option.
>
> For SPAs: even with JavaScript form handling, keep the `<form>`
> element. It enables Enter key submission, browser password
> manager detection, and native validation APIs. Submit via
> `event.preventDefault()` + `new FormData(form)` rather than
> reading each input individually.

---

### ⚠️ Common Misconceptions

**"Placeholder can replace the label"**

Placeholder text disappears when the user starts typing. When
the field is filled, the user has no reminder of what the field
is for. Screen readers may not announce placeholder text at all
for some users. Labels are mandatory; placeholders are supplementary.

**"Using `type="text"` is safe for all inputs"**

Using `type="email"` gives free email format validation, email-
optimized keyboard on mobile, and semantic meaning. `type="password"`
enables password manager detection. `type="tel"` shows the numeric
keyboard on mobile. Using `type="text"` everywhere wastes these
browser features.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: form submission sends empty or wrong data**

```
Diagnosis:
1. DevTools → Network → submit form → look at request payload
2. Check: do all inputs have name="" attribute?
   (inputs without name are NOT submitted)
3. Check: is the button type="submit"? Or a div?
4. Check: radio group - do all options share the same name?
5. For file uploads: is enctype="multipart/form-data" set?

Common causes:
  - Input missing name attribute (data not included)
  - Button is div/span (doesn't trigger form submission)
  - File input without multipart/form-data (file not uploaded)
  - Disabled inputs are NOT submitted (by design)

Fix: verify name attributes first - most common cause
```

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| Form elements overview | 2-3 min | name vs id distinction |
| Label association | 2 min | Accessibility requirement |
| fieldset/legend purpose | 2 min | Radio group context |
| Input types benefit | 2 min | Mobile + validation |
| FormData API | 2-3 min | JavaScript form handling |
| Form validation approach | 2-3 min | Native vs JS |
| File upload requirements | 2 min | enctype change |

---

**Q1: Why is associating labels with form controls important?**
`[JUNIOR]` MECHANISM

*Why they ask:* Accessibility fundamentals.

*Likely follow-up:* "What are the two ways to associate a label?"

> **Answer:**
>
> Labels provide an accessible name for form controls. Without
> labels, screen readers announce only the input type ("edit
> text") with no indication of what data to enter.
>
> Two association methods:
>
> ```html
> <!-- Method 1: for/id matching (explicit association) -->
> <label for="username">Username</label>
> <input type="text" id="username" name="username">
>
> <!-- Method 2: wrapping (implicit association) -->
> <label>
>   Username
>   <input type="text" name="username">
> </label>
> ```
>
> Benefits of labels:
> 1. Screen readers announce: "Username, edit text"
> 2. Clicking the label focuses/activates the control
>    (increases click target - important for checkboxes)
> 3. Required for WCAG 2.1 Success Criterion 1.3.1
>
> Bad alternatives:
> - `placeholder` only: disappears when typing
> - `aria-label` attribute: works for AT but no visible label
>   and no click-to-focus
> - No label: completely inaccessible to screen readers
>
> *What separates good from great:* Click target size. Checkboxes
> are small targets. A `<label>` wrapping a checkbox makes the
> ENTIRE label text (and the checkbox) the click target. This is
> a UX improvement for all users, not just accessibility.

---

**Q2: What is the difference between `name` and `id` on a form
input?** `[JUNIOR]` DEFINITION

*Why they ask:* Core HTML forms vocabulary.

*Likely follow-up:* "Can they have the same value?"

> **Answer:**
>
> `id` is for HTML: must be unique within the document.
> Used for: CSS targeting (`#email`), JavaScript
> (`getElementById`), and label association (`for="id"`).
>
> `name` is for HTTP: the key in the submitted form data.
> Used for: form submission data encoding. Without `name`,
> the control is NOT submitted.
>
> They can have the same value (common practice):
> ```html
> <label for="email">Email</label>
> <input type="email" id="email" name="email">
> <!-- id="email" links label; name="email" submits data -->
> ```
>
> Radio buttons MUST share a `name` (same name = same group):
> ```html
> <!-- id unique, name shared (same radio group) -->
> <input type="radio" id="yes" name="preference" value="yes">
> <input type="radio" id="no"  name="preference" value="no">
> ```
>
> `name` with same value creates arrays on some backends:
> ```html
> <input name="tags" value="html">
> <input name="tags" value="css">
> <!-- PHP: $_POST['tags'] = ['html', 'css'] -->
> ```
>
> *What separates good from great:* Disabled inputs are excluded
> from submission. If you need to submit a value but disable
> user editing, use `readonly` (control is submitted) instead
> of `disabled` (control is excluded from submission).

---

**Q3: How does HTML5 native form validation work?** `[SENIOR]`
MECHANISM

*Why they ask:* Front-end validation strategy question.

*Likely follow-up:* "When would you disable it with novalidate?"

> **Answer:**
>
> HTML5 form validation uses validation attributes on controls.
> The browser validates before submission and shows UI for errors.
>
> Validation attributes:
> - `required` - field must have a value
> - `type="email"` - must match email format
> - `type="url"` - must match URL format
> - `pattern="[0-9]{5}"` - must match regex
> - `min="0" max="100"` - number range
> - `minlength="8" maxlength="20"` - string length
>
> The browser's validation UI:
> - Blocks form submission until valid
> - Shows platform-specific error tooltips (Chrome, Firefox, Safari
>   each render differently)
> - On invalid submit: focuses first invalid field
>
> `novalidate` on the form disables browser validation UI while
> keeping the Constraint Validation API available:
>
> ```javascript
> form.addEventListener('submit', (e) => {
>   e.preventDefault();
>   // Use API: report validity on all fields
>   if (!form.checkValidity()) {
>     form.reportValidity(); // shows browser UI
>     return;
>   }
>   // Use API: check specific field
>   const email = form.querySelector('#email');
>   if (!email.validity.typeMismatch) { /* valid */ }
> });
> ```
>
> When to use `novalidate`: when you want custom error UI (styled
> error messages in your design system) while still using
> native validation logic.
>
> *What separates good from great:* The `validity` object exposes
> 8 flags: `valueMissing`, `typeMismatch`, `patternMismatch`,
> `tooLong`, `tooShort`, `rangeUnderflow`, `rangeOverflow`,
> `customError`, `valid`. Knowing these flags allows precise
> error message selection: "Please enter a valid email" vs "Email
> is required" vs "Email must be under 100 characters."

---

**Q4: What is the `autocomplete` attribute and why does it matter?**
`[SENIOR]` SCENARIO

*Why they ask:* Production conversion rate impact.

*Likely follow-up:* "What are the valid autocomplete values?"

> **Answer:**
>
> `autocomplete` hints the browser and password managers about
> what type of data a field contains. This enables:
> 1. Browser autofill (pre-fill from saved data)
> 2. Password manager integration
> 3. Mobile keyboard prediction
>
> Key `autocomplete` values from the WHATWG spec:
> ```html
> <!-- Personal information -->
> <input autocomplete="name">
> <input autocomplete="given-name">
> <input autocomplete="email">
> <input autocomplete="tel">
>
> <!-- Address -->
> <input autocomplete="street-address">
> <input autocomplete="postal-code">
> <input autocomplete="country">
>
> <!-- Payment (triggers credit card UI in mobile) -->
> <input autocomplete="cc-number">
> <input autocomplete="cc-exp">
> <input autocomplete="cc-csc">
>
> <!-- Credentials -->
> <input type="email" autocomplete="username">
> <input type="password" autocomplete="current-password">
> <input type="password" autocomplete="new-password">
>
> <!-- OTP - triggers SMS code suggestion on iOS -->
> <input type="text" autocomplete="one-time-code">
> ```
>
> `autocomplete="one-time-code"` causes iOS to suggest the
> SMS code from messages - a massive UX improvement for 2FA.
>
> Production impact: reducing form friction directly improves
> conversion. Google data shows proper `autocomplete` can reduce
> checkout completion time by 40%.
>
> *What separates good from great:* `autocomplete="new-password"`
> vs `autocomplete="current-password"` - password managers use
> this to decide whether to fill an existing password or generate
> a new one. Getting this wrong causes password managers to fill
> the wrong field, corrupting password storage.

---

**Q5: How do you handle file uploads in HTML forms?** `[JUNIOR]`
SCENARIO

*Why they ask:* Common requirement with specific HTML requirements.

*Likely follow-up:* "How do you limit file types?"

> **Answer:**
>
> File uploads require two specific attributes:
>
> ```html
> <!-- Both changes are required for file upload: -->
> <form action="/upload" method="POST"
>       enctype="multipart/form-data">
>   <!-- 1. enctype MUST be multipart/form-data -->
>   
>   <label for="file">Upload document</label>
>   <input type="file"
>          id="file"
>          name="document"
>          accept=".pdf,.doc,.docx"
>          multiple>
>   <!-- accept: hint browser file picker filter -->
>   <!-- multiple: allow selecting multiple files -->
>   
>   <button type="submit">Upload</button>
> </form>
> ```
>
> Without `enctype="multipart/form-data"`:
> - Default encoding (`application/x-www-form-urlencoded`)
> - Only sends filename, NOT file contents
> - Server receives empty/wrong data
>
> `accept` attribute: hints the file picker which file types
> to show (user can override). Not a security control.
> Use MIME types or extensions: `accept="image/*"`,
> `accept=".pdf,application/pdf"`.
>
> Multiple files: `multiple` attribute on the input.
>
> Server security: ALWAYS validate file type, size, and content
> on the server. `accept` is a UX hint, not a security control.
>
> *What separates good from great:* `accept` is a browser-side
> filter only. A malicious user can change it in DevTools or
> bypass it entirely. Server-side: check file extension AND
> MIME type AND magic bytes (first bytes of file). Even a
> renamed `.php` as `.jpg` can be detected by magic bytes.

---

**Q6: What is the purpose of `<fieldset>` and `<legend>`?**
`[JUNIOR]` MECHANISM

*Why they ask:* Grouping controls for accessibility.

*Likely follow-up:* "When is fieldset mandatory?"

> **Answer:**
>
> `<fieldset>` groups related form controls. `<legend>` provides
> the group's name (must be first child of fieldset).
>
> For accessibility:
> - Screen readers announce: "[legend]: [input name]" for each
>   control in the group
> - Without fieldset/legend for radio groups: screen reader
>   announces only "Option 1, radio" with no group context
>   - User doesn't know what they're choosing
>
> ```html
> <!-- With fieldset/legend: -->
> <fieldset>
>   <legend>Delivery speed</legend>
>   <label>
>     <input type="radio" name="speed" value="standard">
>     Standard (5 days)
>   </label>
>   <label>
>     <input type="radio" name="speed" value="express">
>     Express (2 days)
>   </label>
> </fieldset>
> <!-- Screen reader: "Delivery speed: Standard (5 days), radio" -->
>
> <!-- Without fieldset/legend: -->
> <div>
>   <p>Delivery speed</p>
>   <label>...</label> <!-- Looks right, but... -->
>   <!-- Screen reader: "Standard (5 days), radio" -->
>   <!-- User doesn't know what they're choosing -->
> </div>
> ```
>
> When fieldset is mandatory:
> - Radio button groups (WCAG 1.3.1 requires group label)
> - Checkbox groups with shared purpose
> - Related form fields (address block, date components)
>
> Styling note: `<fieldset>` has browser-default border.
> `fieldset { border: none; }` to remove; still keeps semantics.
>
> *What separates good from great:* The WCAG 1.3.1 requirement
> ("Info and Relationships") specifically covers radio groups
> needing group labels. This is a Level A (must-pass) success
> criterion. Failing to use fieldset/legend on radio groups is
> a legal accessibility compliance failure in many jurisdictions.

---

**Q7: How does the FormData API work?** `[SENIOR]` MECHANISM

*Why they ask:* JavaScript form handling.

*Likely follow-up:* "How do you append files to FormData?"

> **Answer:**
>
> `FormData` is the JavaScript API for reading and constructing
> multipart form data, typically used for AJAX form submissions.
>
> ```javascript
> const form = document.querySelector('#my-form');
>
> form.addEventListener('submit', async (e) => {
>   e.preventDefault();
>
>   // Read entire form automatically:
>   const data = new FormData(form);
>
>   // Read values:
>   console.log(data.get('email'));   // "user@ex.com"
>   console.log(data.getAll('tags')); // ["html", "css"]
>
>   // Append values manually:
>   data.append('timestamp', Date.now());
>   data.set('status', 'active');     // set replaces existing
>   data.delete('sensitiveField');    // remove before send
>
>   // Append file from input:
>   const fileInput = form.querySelector('[type="file"]');
>   data.append('attachment', fileInput.files[0]);
>
>   // Submit via fetch:
>   // DO NOT set Content-Type header - browser sets it
>   // with the correct boundary for multipart
>   const response = await fetch('/submit', {
>     method: 'POST',
>     body: data  // no Content-Type header!
>   });
> });
>
> // Build FormData manually (no form element needed):
> const data = new FormData();
> data.append('name', 'Alice');
> data.append('file', blob, 'filename.pdf');
> ```
>
> Critical: when using `FormData` with `fetch`, do NOT set
> `Content-Type: multipart/form-data` manually. The browser
> sets it automatically with the correct multipart boundary.
> Setting it manually omits the boundary and breaks parsing.
>
> *What separates good from great:* The Content-Type boundary
> gotcha is a real production failure mode. Developers see
> "multipart/form-data" in the spec and manually add the header,
> breaking uploads. The boundary parameter is auto-generated
> uniquely by the browser. Manual setting: `Content-Type:
> multipart/form-data` (no boundary = server parse error).
> Correct approach: omit the header entirely.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | Constraint Validation API |
| Hiring Manager | Conversion impact of good forms |
| Bar Raiser | WCAG compliance + FormData API |
| Peer Engineer | Practical label/fieldset patterns |

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ keyword.)*

---

### 📊 Diagram

*(Omit: form anatomy is well-expressed in code examples.)*

---

---

# HTML Images and Media

🎯 **Interview Weight:** high (★☆☆) - Images are the largest
contributor to page weight and LCP; every page uses them

---

### 🎯 Model Answer

**30 seconds:**

> HTML images use `<img>` with `src` (source URL), `alt` (text
> alternative), and `width`/`height` (prevent layout shift). For
> responsive images: `srcset` provides multiple resolutions and
> `sizes` tells the browser which size to use at each viewport
> width. For art direction: `<picture>` with `<source media="...">`.
> Audio and video use `<audio>` and `<video>` with `<source>`
> for multiple format fallbacks.

**3 minutes (Senior):**

> Images are often the biggest bottleneck for page performance
> and the largest contributor to CLS and LCP in Core Web Vitals.
>
> The critical mistake: omitting `width` and `height` attributes.
> Without dimensions, the browser allocates no space for the image.
> When the image loads, it pushes content down - this is CLS.
> Setting `width` and `height` allows the browser to reserve the
> correct space, maintaining `aspect-ratio` even with CSS `width: 100%`.
>
> `alt` text is a required attribute (not optional). It serves
> three purposes: screen reader text for users who can't see
> the image; fallback text when images fail to load; search
> engine signal for image search. For PURELY decorative images
> (visual dividers, background textures that happen to be `<img>`),
> use `alt=""` (empty string) to tell screen readers to skip it.
>
> Modern responsive images: `srcset` + `sizes` for resolution
> switching (same image, different sizes). `<picture>` + `<source>`
> for art direction (different crops at different viewports) or
> format switching (WebP with JPEG fallback).

*Adapting up:* Discuss CLS prevention, LCP optimization with
`fetchpriority="high"` and `<link rel="preload" as="image">`,
and the Intersection Observer API for custom lazy loading.

*Adapting down:* `<img src="image.jpg" alt="Description">` is
the basic pattern. Alt text describes the image for users who
can't see it.

**Blank Mind Recovery:**

**(1) Restate:** "HTML images - let me cover the key attributes
and responsive image techniques."

**(2) First principles:** "Images need: what it is (src), what
it shows (alt), how big it is (width/height). Then optimization
layered on top."

**(3) Bridge:** "Think of an image tag like a shipping label:
address (src), description (alt), package size (width/height)."

---

### 📘 Concept Explanation

**What it is:**

`<img>` is a void (replaced) element that embeds an image
in the document. `<picture>` is a container for art-direction
and format negotiation. `<video>` and `<audio>` embed media
with player controls.

**The problem it solves:**

Documents need to display visual content. Images provide visual
information that cannot be conveyed by text alone. The HTML
image model provides: embedded image display, accessibility via
alt text, responsive delivery via srcset/picture, and performance
hints via loading/fetchpriority.

**How it works:**

```
BASIC IMAGE:
<img src="photo.jpg"
     alt="Product photo: red running shoes"
     width="800"
     height="600"
     loading="lazy">

RESPONSIVE (RESOLUTION SWITCHING):
<img src="photo-400.jpg"
     srcset="photo-400.jpg 400w,
             photo-800.jpg 800w,
             photo-1200.jpg 1200w"
     sizes="(max-width: 600px) 100vw,
            (max-width: 1200px) 50vw,
            800px"
     alt="Product photo"
     width="800"
     height="600">

SIZES EXPLANATION:
  "(max-width: 600px) 100vw" = on screens <= 600px wide,
    this image is 100% of viewport width
  "(max-width: 1200px) 50vw" = on screens <= 1200px,
    image is 50% of viewport width
  "800px" = default: image is 800px wide
  Browser picks srcset candidate matching calculated size.

ART DIRECTION (different crops):
<picture>
  <!-- Mobile: tall crop -->
  <source media="(max-width: 600px)"
          srcset="hero-mobile.jpg">
  <!-- Tablet: medium crop -->
  <source media="(max-width: 1024px)"
          srcset="hero-tablet.jpg">
  <!-- Desktop: wide crop / WebP -->
  <source type="image/webp" srcset="hero.webp">
  <!-- Fallback (always include): -->
  <img src="hero.jpg" alt="Hero image">
</picture>

LAZY LOADING:
  loading="lazy"  → defer until near viewport
  loading="eager" → load immediately (default)
  fetchpriority="high" → LCP images: hint high priority

VIDEO:
<video controls autoplay muted loop playsinline
       width="800" height="450"
       poster="thumbnail.jpg">
  <source src="video.webm" type="video/webm">
  <source src="video.mp4" type="video/mp4">
  Your browser does not support video.
</video>

AUDIO:
<audio controls>
  <source src="audio.ogg" type="audio/ogg">
  <source src="audio.mp3" type="audio/mpeg">
  Your browser does not support audio.
</audio>
```

**The key insight:**

`loading="lazy"` should NOT be used on above-the-fold images.
Lazy loading delays the fetch - on the LCP image this directly
harms LCP scores. Use `loading="eager"` (or omit) for the
first image; `loading="lazy"` only for images below the fold.

**When to use it:**

`<img>` for all content images. `<picture>` when you need
art direction (different image) or format negotiation (WebP +
JPEG fallback). `<video>` for video content. Background images
that are purely decorative: CSS `background-image`.

**When NOT to use it:**

Don't use `<img>` for decorative background images (use CSS).
Don't omit `alt` (browsers may announce filename). Don't set
`loading="lazy"` on the first/hero image. Don't use `<img>`
for SVG icons that need to be styled with CSS (use inline `<svg>`).

**Alternatives:**

- CSS `background-image` → decorative images, background patterns
- Inline `<svg>` → icons that need CSS/JS interaction
- CSS `content: url()` → decorative pseudo-element images
- Canvas API → programmatically drawn images

**First-principles derivation:**

Given images are external resources that have: a location (src),
a description (alt), dimensions (width/height), and may exist
in multiple sizes, the `<img>` element needs attributes for all
four. Responsive delivery added srcset/sizes when it became clear
that serving 1200px images to 400px screens wasted 9x bandwidth.

---

### 💻 Code Example

**CLS prevention via width/height**

```html
<!-- BAD: no dimensions - causes Cumulative Layout Shift -->
<div class="product-grid">
  <img src="product-1.jpg" alt="Red shoes">
  <!-- When image loads: everything below shifts down -->
  <!-- This is CLS (Cumulative Layout Shift) -->
  <!-- Google ranks this as "poor" user experience -->
  <p>Product description</p>
</div>

<!-- GOOD: dimensions prevent CLS -->
<div class="product-grid">
  <img src="product-1.jpg"
       alt="Red running shoes, size 10"
       width="400"
       height="300">
  <!-- Browser reserves 4:3 aspect ratio space -->
  <!-- Content does NOT shift when image loads -->
  <!-- Works even with CSS width: 100%; height: auto -->
  <p>Product description</p>
</div>
```

```css
/* CSS width doesn't override the aspect-ratio reservation */
.product-grid img {
  width: 100%;   /* responsive */
  height: auto;  /* maintain aspect ratio */
  /* Browser uses width/height HTML attributes to calculate
     aspect-ratio BEFORE the image loads */
}
```

> **Code walkthrough:** The `width` and `height` attributes in
> HTML create an intrinsic aspect ratio. Even though CSS sets
> `width: 100%; height: auto`, the browser reserves the correct
> proportional space before the image loads. Without these
> attributes, the browser allocates 0 height for the image
> container, and everything below shifts when the image loads -
> this is CLS. CLS is a Core Web Vitals metric that directly
> affects Google search ranking.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Images use `<img src alt width height>`. Alt text describes the
> image; `alt=""` for decorative images. Width/height prevent layout
> shift. `loading="lazy"` defers off-screen images. For responsive
> images: `srcset` + `sizes` for the same image at different
> resolutions; `<picture>` for different images at different
> viewports.

---

**Senior / Staff:**

> Images are the primary contributor to LCP and CLS in Core Web
> Vitals. Production checklist: `width`/`height` always (CLS
> prevention), `loading="lazy"` only below the fold, `fetchpriority="high"`
> + `<link rel="preload" as="image">` for the LCP image, `srcset`/`sizes`
> for responsive delivery, WebP/AVIF via `<picture>` for modern
> format delivery with JPEG fallback.
>
> For video: `autoplay muted playsinline` is the trio required for
> background autoplay on mobile Safari. Missing `muted` or `playsinline`
> breaks mobile autoplay.

---

### ⚠️ Common Misconceptions

**"`loading='lazy'` should be on all images"**

Using `loading="lazy"` on the LCP image (typically the first large
image on the page) delays its fetch, directly increasing LCP time.
Use `loading="eager"` or omit the attribute for above-the-fold
images. Lazy load only below-the-fold images.

**"Alt text describes the image visually"**

Alt text provides the FUNCTION or INFORMATION conveyed by the image,
not a visual description. A chart with `alt="Line chart"` is bad;
`alt="Revenue grew 40% YoY from $1M to $1.4M"` is good. A
decorative divider image should have `alt=""` (not `alt="divider"`).

---

### 🚨 Failure Modes and Diagnosis

**Symptom: Large CLS score (>0.1 = "needs improvement")**

```
Diagnosis:
1. Chrome DevTools → Lighthouse → run audit
2. Look for: CLS breakdown by element
3. Common culprits:
   - Images without width/height
   - Ads loading and pushing content
   - Web fonts causing text shift (FOUT)
   - Lazy-loaded content above the fold

Fix for images:
  <img width="400" height="300" ...>
  + CSS: img { height: auto; }

Measure: DevTools → Performance → scroll → look for layout shift
  (red triangles indicate layout shift events)
Target: CLS < 0.1 (good), 0.1-0.25 (needs improvement), >0.25 (poor)
```

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| img src alt width height | 2 min | CLS prevention |
| alt text rules | 2-3 min | Decorative vs informative |
| loading lazy vs eager | 2 min | LCP vs off-screen |
| srcset and sizes | 3-4 min | Responsive image logic |
| picture element | 2-3 min | Art direction |
| video autoplay rules | 2 min | Mobile policy |
| fetchpriority high | 2 min | LCP optimization |

---

**Q1: What is the `alt` attribute and how should you write it?**
`[JUNIOR]` MECHANISM

*Why they ask:* Accessibility fundamental.

*Likely follow-up:* "When should alt be empty?"

> **Answer:**
>
> `alt` provides a text alternative for an image. It serves:
> 1. Screen readers: announced when focus reaches the image
> 2. Fallback: displayed if image fails to load
> 3. SEO: search engine signal for image search
>
> Rules for good alt text:
>
> - **Informative images**: describe the INFORMATION conveyed,
>   not the visual appearance. For a chart: describe the finding.
>   For a product photo: identify the product.
>
> - **Functional images** (links, buttons): describe the ACTION.
>   `<a href="/"><img src="logo.png" alt="Company homepage"></a>`
>   Not "Company logo" (visual) but "Company homepage" (function).
>
> - **Decorative images**: `alt=""` (empty string).
>   Screen reader skips the image entirely. Do NOT omit the
>   attribute (browser may announce filename). Do NOT use
>   `alt="image"` or `alt="decorative"`.
>
> - **Complex images** (charts, infographics): use short alt +
>   long description in `<figcaption>` or `aria-describedby`.
>
> ```html
> <!-- Informative: convey the information -->
> <img src="revenue-chart.png"
>      alt="Revenue increased 40% in Q4 2025">
>
> <!-- Functional: describe the action -->
> <a href="/"><img src="logo.svg" alt="Return to homepage"></a>
>
> <!-- Decorative: empty alt, not omitted -->
> <img src="divider.png" alt="">
> ```
>
> *What separates good from great:* "alt text" is not description-of-
> image, it's PURPOSE-of-image. A logo alt of "Company name logo"
> is worse than just "Company name" (the word "logo" adds no value).
> A chart alt should give the takeaway finding, not "bar chart of
> revenue" (which describes the FORMAT, not the INFORMATION).

---

**Q2: How do `srcset` and `sizes` work together?** `[SENIOR]`
MECHANISM

*Why they ask:* Responsive images is a common real-world requirement.

*Likely follow-up:* "What is the 'w descriptor' vs 'x descriptor'?"

> **Answer:**
>
> `srcset` lists the available image candidates with their
> actual pixel widths (w descriptor). `sizes` tells the browser
> what layout width the image will have at each viewport condition.
> The browser combines these to pick the optimal file to download.
>
> ```html
> <img src="fallback.jpg"
>      srcset="img-400.jpg 400w,
>              img-800.jpg 800w,
>              img-1600.jpg 1600w"
>      sizes="(max-width: 600px) 100vw,
>             (max-width: 1200px) 50vw,
>             800px"
>      alt="Product image">
> ```
>
> Browser algorithm on a 900px viewport at 2x DPR:
> 1. Evaluate `sizes`: viewport 900px matches `(max-width: 1200px) 50vw`
>    → image will be 450px wide in layout
> 2. Account for DPR: 450px × 2 = 900 pixels needed
> 3. Choose closest srcset candidate: 800w is closest to 900
>    → download `img-800.jpg`
>
> `x descriptor` (alternative): for fixed-size images at different
> DPRs. `srcset="img.jpg 1x, img@2x.jpg 2x"`. Simpler but less
> flexible than `w descriptor`.
>
> *What separates good from great:* The `sizes` attribute is a
> HINT - the browser can override it for network conditions,
> saved-data mode, or viewport changes. It's not a command.
> Also: `sizes` must accurately reflect the CSS layout width
> or the browser will pick the wrong candidate. Tools like RespImageLint
> detect incorrect `sizes` values.

---

**Q3: When should you use `<picture>` vs `srcset` on `<img>`?**
`[SENIOR]` COMPARISON

*Why they ask:* Common confusion point in responsive images.

*Likely follow-up:* "How does picture with type work for WebP?"

> **Answer:**
>
> Use `srcset` on `<img>` for: the SAME image at different resolutions
> (resolution switching). The browser chooses the best size. No control
> over WHICH image is displayed - just which SIZE.
>
> Use `<picture>` for:
> 1. **Art direction**: DIFFERENT images at different viewports
>    (different crop, different orientation, different composition)
> 2. **Format switching**: WebP for modern browsers, JPEG fallback
>
> ```html
> <!-- Art direction: different image, not just different size -->
> <picture>
>   <source media="(max-width: 600px)"
>           srcset="hero-portrait.jpg">
>   <img src="hero-landscape.jpg" alt="Hero image">
> </picture>
>
> <!-- Format switching: WebP with JPEG fallback -->
> <picture>
>   <!-- Browser takes FIRST matching source -->
>   <source type="image/avif" srcset="photo.avif">
>   <source type="image/webp" srcset="photo.webp">
>   <img src="photo.jpg" alt="Photo">
>   <!-- img is ALWAYS the fallback - required element -->
> </picture>
> ```
>
> `<img>` inside `<picture>` is the fallback AND the element that
> carries `alt`, `width`, `height`, `loading`, `fetchpriority`.
> The `<source>` elements have no `alt` attribute.
>
> *What separates good from great:* WebP support is now universal
> (100% browser support). AVIF offers 20-50% better compression
> than WebP. The `<picture>` format-switching pattern with AVIF
> → WebP → JPEG is the production standard for maximum compression
> with universal compatibility, requiring no JavaScript.

---

**Q4: How do you optimize images for LCP?** `[SENIOR]` SCENARIO

*Why they ask:* Core Web Vitals is a ranking factor.

*Likely follow-up:* "What is fetchpriority?"

> **Answer:**
>
> LCP (Largest Contentful Paint) measures when the largest
> visible image or text block renders. Optimizing the LCP image:
>
> 1. **Identify the LCP element**: Chrome DevTools → Lighthouse
>    → see which element is LCP (usually hero image)
>
> 2. **Do NOT lazy load it**:
>    ```html
>    <!-- WRONG: delays LCP image -->
>    <img src="hero.jpg" loading="lazy" alt="Hero">
>    <!-- CORRECT: eager (or omit) -->
>    <img src="hero.jpg" loading="eager" alt="Hero">
>    ```
>
> 3. **Raise its fetch priority**:
>    ```html
>    <img src="hero.jpg" fetchpriority="high" alt="Hero">
>    ```
>
> 4. **Preload it** (starts fetch before parser reaches img):
>    ```html
>    <link rel="preload" as="image" href="hero.jpg">
>    <!-- For responsive images: -->
>    <link rel="preload" as="image"
>          imagesrcset="hero-400.jpg 400w, hero-800.jpg 800w"
>          imagesizes="(max-width: 600px) 100vw, 800px">
>    ```
>
> 5. **Set width/height**: prevents CLS during load
>
> 6. **Optimize format and size**: serve WebP/AVIF, correct
>    dimensions (not 2000px image for 400px layout slot)
>
> Combined effect: reducing LCP by 500ms+ is achievable with
> these changes alone on image-heavy pages.
>
> *What separates good from great:* `fetchpriority="high"` was
> added in 2022 specifically because the browser's default priority
> heuristics (based on position in HTML) weren't always right.
> Explicitly marking the LCP image as high priority is the
> most reliable signal. Combined with `<link rel="preload">`,
> the browser starts fetching the image before rendering HTML.

---

**Q5: What attributes are required for background video autoplay?**
`[JUNIOR]` MECHANISM

*Why they ask:* Common mobile issue with video elements.

*Likely follow-up:* "Why does muted matter?"

> **Answer:**
>
> For autoplay video (especially background videos):
>
> ```html
> <video autoplay muted loop playsinline
>        width="1920" height="1080"
>        poster="thumbnail.jpg"
>        aria-hidden="true">
>   <source src="background.webm" type="video/webm">
>   <source src="background.mp4" type="video/mp4">
> </video>
> ```
>
> Required attributes for mobile autoplay:
> - `muted`: browsers block autoplay for sound. `muted` allows it.
>   Without `muted`, video will not autoplay on iOS or Chrome Android.
> - `playsinline`: iOS Safari plays `<video>` fullscreen by default.
>   `playsinline` keeps it inline. Without it, mobile users see
>   fullscreen video hijacking the page.
>
> Other attributes:
> - `autoplay`: starts playing immediately
> - `loop`: repeats indefinitely
> - `poster`: thumbnail shown before video loads
> - `aria-hidden="true"`: decorative video is hidden from AT
>
> Format support: WebP is the modern format but lacks broad
> support. For video: WebM (VP9) for all modern browsers,
> MP4 (H.264) as universal fallback.
>
> *What separates good from great:* The Chrome autoplay policy
> (2017) and iOS Safari policy: audio is blocked by default.
> Even `muted` videos had restrictions until browsers relaxed
> rules for muted autoplay. The minimum required combination
> (`muted` + `playsinline`) exists because of browser security
> policies preventing websites from playing audio without user
> interaction, protecting users from autoplaying ads with sound.

---

**Q6: When should alt be empty (`alt=""`) vs descriptive?**
`[JUNIOR]` MECHANISM

*Why they ask:* Nuanced accessibility question.

*Likely follow-up:* "What happens if you omit alt entirely?"

> **Answer:**
>
> **Descriptive `alt`**: image conveys information needed to
> understand the page. Examples:
> - Product photos: `alt="Blue leather wallet, slim profile"`
> - Charts: `alt="Q4 sales exceeded target by 23%"`
> - Instructional images: `alt="Step 3: click the blue button"`
> - Linked images: `alt="View shopping cart (3 items)"`
>
> **Empty `alt=""` (decorative)**: image is visual decoration
> only; removing it wouldn't lose any information. Examples:
> - Background textures or gradients as `<img>`
> - Decorative borders, dividers
> - Icons that duplicate adjacent text label
> - Stock photos used purely for visual mood
>
> For icons with adjacent text:
> ```html
> <!-- icon duplicates text label - empty alt -->
> <button>
>   <img src="save-icon.png" alt="">
>   Save document
> </button>
> <!-- Screen reader: "Save document, button" -->
> <!-- NOT: "save icon Save document, button" (redundant) -->
> ```
>
> **Omitting `alt` entirely** is different from `alt=""`:
> - Some screen readers announce the filename: "product_photo_001.jpg"
> - The image is treated as if it needs attention
> - Should never be omitted (always provide alt="", even if empty)
>
> *What separates good from great:* The rule for linked images:
> the alt text should describe the DESTINATION or ACTION, not
> the visual. `<a href="/logout"><img src="door.png" alt="Log out"></a>`
> Not "door" (visual) but "Log out" (action). The visual metaphor
> is a UX aid for sighted users; the alt serves the accessible
> name for the link.

---

**Q7: How does `<figure>` and `<figcaption>` work with images?**
`[JUNIOR]` SCENARIO

*Why they ask:* Semantic grouping of images.

*Likely follow-up:* "When would you use both alt and figcaption?"

> **Answer:**
>
> `<figure>` groups self-contained content (image + its caption).
> `<figcaption>` provides a visible caption for the figure.
>
> ```html
> <figure>
>   <img src="chart.png"
>        alt="Bar chart: 2026 regional revenue">
>   <figcaption>
>     Fig. 3: Regional revenue breakdown Q1 2026.
>     APAC shows strongest growth at +32% YoY.
>   </figcaption>
> </figure>
> ```
>
> When to use both `alt` and `<figcaption>`:
> - `alt`: short description for screen readers + image-off fallback
> - `figcaption`: visible caption that ADDS information (context,
>   source citation, analysis) beyond what alt provides
>
> Pattern for charts/infographics:
> ```html
> <figure>
>   <img src="infographic.png"
>        alt="Summary: Node.js is used by 50% of devs"
>        aria-describedby="fig1-desc">
>   <figcaption id="fig1-desc">
>     Node.js usage statistics from 2026 Stack Overflow
>     survey. 50% of professional developers use Node.js,
>     up from 47% in 2025. Backend use dominates at 72%.
>   </figcaption>
> </figure>
> ```
>
> `aria-describedby` on the `<img>` points to the figcaption -
> screen readers announce: alt text THEN full figcaption text.
>
> *What separates good from great:* The `aria-describedby` +
> `<figcaption>` pattern for complex images is the production
> accessible pattern. Simple images: just good `alt`. Complex
> images (charts, diagrams): short `alt` + full text description
> in `<figcaption>` (visible for everyone) + `aria-describedby`
> linking them. This serves visual users (caption), screen readers
> (both), and SEO (text content from description).

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | srcset + sizes algorithm |
| Hiring Manager | CLS and LCP business impact |
| Bar Raiser | fetchpriority + preload patterns |
| Peer Engineer | alt text rules + responsive patterns |

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ keyword.)*

---

### 📊 Diagram

*(Omit: responsive image selection logic covered in code/text.)*

---

---

# HTML Links and Navigation

🎯 **Interview Weight:** high (★☆☆) - Links are the foundation
of hypertext; anchor elements have more behavior than most
developers use

---

### 🎯 Model Answer

**30 seconds:**

> HTML links use `<a href="URL">` to navigate to other pages
> or resources. `href` is the destination; without `href`, `<a>`
> has no role and no keyboard behavior. Links have four CSS
> pseudo-states: `:link`, `:visited`, `:hover`, `:focus`, `:active`.
> For external links: `target="_blank"` opens in a new tab with
> `rel="noopener noreferrer"` required for security. Link text
> must describe the destination - not "click here."

**3 minutes (Senior):**

> The `<a>` element is the foundation of hypertext - literally
> why HTML was invented. The `href` attribute determines both
> behavior and semantics. Without `href`: the element has no role
> (not a link), is not keyboard-focusable, and cannot be activated.
> With `href`: it has `role="link"`, is keyboard-focusable (Tab),
> activatable (Enter), and navigates on click.
>
> `rel` attribute is underutilized. `rel="noopener noreferrer"` on
> `target="_blank"` is security-critical: without `noopener`, the
> new tab can access the opener's `window.opener` object and
> redirect the parent page (reverse tabnapping attack).
>
> `rel="nofollow"` tells search engines not to pass PageRank to
> the linked URL - used for sponsored/paid links and user-generated
> content links (GDPR of SEO).
>
> For navigation: `<nav>` + `<ul>` + `<li>` + `<a>` is the
> correct semantic structure for navigation menus. The list
> structure tells screen readers the count ("list, 5 items")
> allowing users to know how many navigation items to expect.

*Adapting up:* Discuss client-side routing intercept patterns,
History API, and how Next.js `<Link>` works.

*Adapting down:* `<a href="url">text</a>` creates a clickable
link. The text should describe where clicking goes.

**Blank Mind Recovery:**

**(1) Restate:** "HTML links - `<a href>` - let me cover the
key attributes and behaviors."

**(2) First principles:** "A link is a reference to another
resource. It needs: where to go (href), what it does (text
content), how it opens (target), and what metadata about the
relationship (rel)."

**(3) Bridge:** "A link is like a road sign - the text is the
sign, href is the address, rel is the road type classification."

---

### 📘 Concept Explanation

**What it is:**

The `<a>` (anchor) element creates hyperlinks to web pages,
files, emails, phone numbers, or other locations within the
same page. The `href` attribute specifies the link destination.

**The problem it solves:**

Hypertext requires a mechanism to reference other documents.
HTML's `<a>` element provides: the destination (href), the
visible text (content), relationship metadata (rel), and
opening behavior (target). Without hyperlinks, HTML would be
isolated documents, not a web.

**How it works:**

```
LINK TYPES:
  <!-- Absolute URL (external) -->
  <a href="https://example.com">Example</a>

  <!-- Relative URL (same domain) -->
  <a href="/about">About</a>
  <a href="../images/photo.jpg">Photo</a>
  <a href="page.html">Page</a>

  <!-- Fragment (same page) -->
  <a href="#section-3">Jump to section 3</a>
  <section id="section-3">...</section>

  <!-- Protocol links -->
  <a href="mailto:user@example.com?subject=Hello">Email me</a>
  <a href="tel:+15551234567">Call us</a>
  <a href="sms:+15551234567">Text us</a>

  <!-- Download -->
  <a href="/report.pdf" download="Q1-Report.pdf">
    Download report
  </a>

SECURITY ATTRIBUTES (required on external links):
  <a href="https://external.com"
     target="_blank"
     rel="noopener noreferrer">
    External site (opens in new tab)
  </a>
  <!-- noopener: prevents new tab accessing window.opener -->
  <!-- noreferrer: doesn't send Referer header + noopener -->

REL ATTRIBUTE VALUES:
  noopener    → security: block window.opener access
  noreferrer  → security: no Referer + noopener
  nofollow    → SEO: don't pass PageRank
  sponsored   → SEO: paid/sponsored link
  ugc         → SEO: user-generated content
  prefetch    → hint: prefetch this URL
  preload     → hint: preload this resource
  alternate   → alternate version (lang, format)
  canonical   → preferred URL for this content
  author      → author of current document
  license     → license for current page

LINK STATES (CSS pseudo-classes):
  :link    → unvisited link
  :visited → visited link
  :hover   → pointer over
  :focus   → keyboard/programmatic focus
  :active  → being activated (mousedown)

NAVIGATION PATTERN:
  <nav aria-label="Main navigation">
    <ul>
      <li><a href="/" aria-current="page">Home</a></li>
      <li><a href="/products">Products</a></li>
      <li><a href="/about">About</a></li>
    </ul>
  </nav>
  <!-- aria-current="page" on active link: screen readers
       announce "current page" after link text -->
```

**The key insight:**

`<a>` without `href` is NOT a link. It's just a named anchor
(old HTML4 pattern for internal targets). Without `href`:
no `role="link"`, not keyboard-focusable, not activated by
Enter. This is why JavaScript frameworks must be careful:
`<a>` used as a button (with onclick but no href) must add
`href="#"` or better: use `<button>` instead.

**When to use it:**

`<a>` for: navigation to another URL, downloads, email/phone
links, same-page jumps. Any link to a resource.

`<button>` for: actions (submit, toggle, modal open). No navigation.

**When NOT to use it:**

Don't use `<a>` without `href` as a button (use `<button>`).
Don't use `<a href="#">` to do nothing. Don't use JavaScript
`href="javascript:..."`. Don't use non-descriptive link text
("click here", "read more").

**Alternatives:**

- `<button>` → for actions (not navigation)
- `<form action="...">` → for form submission navigation
- `history.pushState()` → SPA navigation without page reload
- Router `<Link>` components → framework-managed client routing

**First-principles derivation:**

Hypertext requires: a source document, a destination reference,
and a mechanism to traverse. The anchor element `<a>` is the
traversal mechanism. `href` is the destination reference. The
element model separates the link (semantic) from the text
(presentation), enabling programmatic link handling.

---

### 💻 Code Example

**External links: security requirement**

```html
<!-- BAD: reverse tabnapping vulnerability -->
<a href="https://social.example.com"
   target="_blank">
  Follow us on Social
</a>
<!-- New tab can execute:                     -->
<!-- window.opener.location = 'phishing.com' -->
<!-- Redirects the ORIGINAL tab to attacker  -->

<!-- GOOD: noopener blocks window.opener access -->
<a href="https://social.example.com"
   target="_blank"
   rel="noopener noreferrer">
  Follow us on Social
  <!-- Optional: indicate new tab opens -->
  <span class="sr-only"> (opens in new tab)</span>
  <svg aria-hidden="true" focusable="false">
    <!-- external link icon -->
  </svg>
</a>
```

> **Code walkthrough:** `target="_blank"` opens the link in a new
> tab. Without `rel="noopener"`, the new tab has access to the
> opener's `window.opener` property and can redirect the original
> tab to a phishing page. This is the "reverse tabnapping" attack.
> `noopener` breaks the `window.opener` reference. `noreferrer`
> additionally prevents sending the Referer header AND implies
> `noopener`. Modern browsers set `noopener` by default for
> `target="_blank"` (as of Chrome 88, Firefox 79), but older
> browsers require explicit `rel="noopener noreferrer"`.

---

### 🎓 Answers by Seniority

**Junior / Mid:**

> Links use `<a href="url">`. For external links with `target="_blank"`,
> I always add `rel="noopener noreferrer"` to prevent the reverse
> tabnapping attack. `rel="nofollow"` tells search engines not to
> follow the link for PageRank. In navigation, I use `aria-current="page"`
> on the active link. Link text must describe the destination.

---

**Senior / Staff:**

> The `<a>` element is the foundation of hypertext and has three
> distinct modes: navigation (href=URL), action trigger (used as
> button - antipattern), and named anchor (href=#id). Each has
> different keyboard/accessibility behavior. The correct architecture:
> navigation = `<a>`, actions = `<button>`. Mixing them creates
> accessibility and semantic debt.
>
> For SPAs: `history.pushState()` enables URL changes without
> navigation, but the history stack must be managed carefully for
> back-button behavior. Framework `<Link>` components (Next.js,
> React Router) abstract this with prefetching and scroll management.

---

### ⚠️ Common Misconceptions

**"link text doesn't matter for SEO"**

Link text (anchor text) is a ranking signal. Text like "click here"
provides no topical signal; text like "React performance guide"
tells search engines the linked page's topic. Descriptive link
text improves SEO for BOTH the current page and the linked target.

**"`<a>` without `href` is fine as a button"**

`<a>` without `href` is not a link - no role, not keyboard
focusable, not activatable by Enter. Using it as a button is an
accessibility failure. Use `<button>` for actions. Use `<a>` with
a real `href` for navigation.

---

### 🚨 Failure Modes and Diagnosis

**Symptom: Clicking link opens in same tab when target="_blank" is set**

```
Diagnosis:
  This is expected behavior if user Ctrl+clicks
  OR if browser settings override target="_blank"
  Check: is there a JavaScript handler calling e.preventDefault()?

Symptom: Reverse tabnapping is possible
Diagnosis:
  Check all <a target="_blank"> elements:
  grep for 'target="_blank"' without 'noopener'

Quick audit:
  DevTools console:
  document.querySelectorAll('a[target="_blank"]')
    .forEach(a => {
      if(!a.rel.includes('noopener')) {
        console.warn('Missing noopener:', a.href);
      }
    });

Fix: add rel="noopener noreferrer" to all external _blank links
```

---

### 🎯 Interview Deep-Dive

| Scenario | Recommended Time | Key Signal |
|---|---|---|
| href attribute types | 2 min | URL types, protocol links |
| noopener noreferrer why | 2-3 min | Security awareness |
| link vs button | 2 min | Semantic clarity |
| aria-current on nav | 2 min | Active state accessibility |
| nofollow sponsored ugc | 2 min | SEO rel values |
| download attribute | 1-2 min | File download behavior |
| Link text best practices | 2 min | SEO + accessibility |

---

**Q1: What is the security risk of `target="_blank"` without `rel="noopener"`?**
`[SENIOR]` FAILURE

*Why they ask:* Security awareness - real vulnerability.

*Likely follow-up:* "Do modern browsers fix this automatically?"

> **Answer:**
>
> The vulnerability is "reverse tabnapping" (also called opener
> tabnapping):
>
> 1. User is on yoursite.com
> 2. User clicks a `target="_blank"` link to evil.com
> 3. evil.com's JavaScript executes:
>    `window.opener.location = 'https://phishing.com/yoursite'`
> 4. The ORIGINAL yoursite.com tab redirects to a phishing page
>    without the user noticing (they're looking at the new tab)
> 5. User returns to the "yoursite.com" tab (now phishing) and
>    enters credentials
>
> `rel="noopener"` sets `window.opener` to null in the new tab.
> The new tab cannot access the original tab's location.
>
> `rel="noreferrer"` implies `noopener` AND additionally prevents
> sending the `Referer` request header (the URL of the page that
> had the link).
>
> Modern browsers: Chrome 88+ and Firefox 79+ set `noopener`
> automatically for `target="_blank"`. But:
> - Older browsers don't have this protection
> - Explicit `rel="noopener noreferrer"` ensures protection
>   across all browser versions
> - It's defense-in-depth and documents intent
>
> *What separates good from great:* The attack only works if
> the linked third-party site is compromised OR if you're
> intentionally linking to an untrusted site (user-generated
> content). Internal trusted pages are not at risk. The
> practice is still correct as defense-in-depth and for
> cross-origin links where you can't trust the destination.

---

**Q2: When should you use `<a>` vs `<button>`?** `[JUNIOR]`
COMPARISON

*Why they ask:* Semantic HTML fundamentals.

*Likely follow-up:* "Can you style a button to look like a link?"

> **Answer:**
>
> Use `<a href>` for: NAVIGATION - going to another URL, downloading
> a file, scrolling to a page section. Right-click should give
> "open in new tab", Ctrl+click should open in new tab.
>
> Use `<button type="button">` for: ACTIONS - doing something
> without navigating. Toggle, submit, modal open, delete, play.
> No URL, no navigation. Right-click has no link options.
>
> ```html
> <!-- LINK: navigates to a page -->
> <a href="/products/123">View product</a>
>
> <!-- BUTTON: performs an action -->
> <button type="button" onclick="addToCart(123)">
>   Add to cart
> </button>
>
> <!-- BOTH: linked button in a form context -->
> <a href="/checkout" class="btn">Proceed to checkout</a>
> <!-- This IS navigation - correct to use <a> even though
>      it looks like a button -->
> ```
>
> Accessibility difference:
> - `<a>` announced as "link" by screen readers
> - `<button>` announced as "button"
> - Users have different expectations: links navigate (can
>   open in new tab, bookmark), buttons perform actions
>
> Can you style button as link? YES:
> ```css
> button.link-style {
>   background: none; border: none; padding: 0;
>   color: blue; text-decoration: underline; cursor: pointer;
> }
> ```
>
> *What separates good from great:* The keyboard behavior difference.
> `<a>` is activated by Enter. `<button>` is activated by both
> Enter AND Spacebar. If your "link-styled action" needs spacebar
> activation (like a toggle), use `<button>`. If it needs to
> be bookmarkable, right-clickable, or navigatable, use `<a>`.

---

**Q3: What is `aria-current` and how does it work with navigation?**
`[JUNIOR]` MECHANISM

*Why they ask:* Active state accessibility.

*Likely follow-up:* "What other values does aria-current accept?"

> **Answer:**
>
> `aria-current` communicates to screen readers which item in a
> set represents the current context. For navigation, `aria-current="page"`
> marks the active page link.
>
> ```html
> <nav aria-label="Main navigation">
>   <ul>
>     <!-- aria-current="page" on the link for the current page -->
>     <li><a href="/" aria-current="page">Home</a></li>
>     <li><a href="/products">Products</a></li>
>     <li><a href="/about">About</a></li>
>   </ul>
> </nav>
> <!-- Screen reader: "link, Home, current page" -->
> <!-- Without aria-current: "link, Home" - no indication -->
> ```
>
> Other `aria-current` values:
> - `step` - current step in a multi-step wizard
> - `location` - current item in breadcrumb navigation
> - `date` - current date in a calendar
> - `time` - current time in a time selector
> - `true` - general "current item" (when none above apply)
>
> Visual indicator: `aria-current` is also styleable with CSS:
> ```css
> [aria-current="page"] {
>   font-weight: bold;
>   color: var(--color-active);
>   text-decoration: none;
>   border-bottom: 2px solid currentColor;
> }
> ```
>
> This is better than using a class like `.active` because it's
> the semantic source of truth - if aria-current is set, the link
> IS active.
>
> *What separates good from great:* Using `aria-current` as the
> CSS selector instead of (or in addition to) a class. This makes
> accessibility and styling in sync by definition. If you mark
> a link as current for ARIA, it will automatically receive the
> active visual style - no risk of ARIA and CSS getting out of sync.

---

**Q4: What is the `download` attribute on links?** `[JUNIOR]`
MECHANISM

*Why they ask:* Common requirement, underused attribute.

*Likely follow-up:* "What are its limitations?"

> **Answer:**
>
> The `download` attribute tells the browser to download the
> linked file rather than navigate to it. The value provides
> the suggested filename.
>
> ```html
> <!-- Download with default filename from URL -->
> <a href="/reports/q1-2026.pdf" download>
>   Download Q1 Report
> </a>
>
> <!-- Download with custom filename -->
> <a href="/api/export?format=csv"
>    download="sales-data-2026.csv">
>   Export to CSV
> </a>
>
> <!-- Download object URL (client-side generated file) -->
> <script>
>   const data = 'Name,Email\nAlice,a@ex.com';
>   const blob = new Blob([data], { type: 'text/csv' });
>   const url = URL.createObjectURL(blob);
>
>   const a = document.createElement('a');
>   a.href = url;
>   a.download = 'export.csv';
>   a.click();
>   URL.revokeObjectURL(url); // clean up
> </script>
> ```
>
> Limitations:
> - Only works for SAME-ORIGIN URLs (or URLs with CORS headers)
> - Cross-origin links without CORS: `download` is ignored,
>   browser navigates instead
> - Server must not send `Content-Disposition: inline`
>   (overrides download behavior)
>
> *What separates good from great:* The Object URL pattern for
> client-side file generation. Creating a CSV, JSON, or image
> in JavaScript and offering it as a download requires the
> `URL.createObjectURL(blob)` + `a.download` pattern. Calling
> `URL.revokeObjectURL()` after clicking prevents memory leaks
> (object URLs hold a reference to the blob in memory until revoked).

---

**Q5: How should navigation menus be structured in HTML?**
`[SENIOR]` SCENARIO

*Why they ask:* Semantic navigation structure question.

*Likely follow-up:* "When would you use multiple nav elements?"

> **Answer:**
>
> Semantic navigation structure uses `<nav>` + `<ul>` + `<li>` + `<a>`:
>
> ```html
> <!-- Primary navigation -->
> <nav aria-label="Main navigation">
>   <ul role="list">  <!-- explicit role for CSS resets -->
>     <li>
>       <a href="/" aria-current="page">Home</a>
>     </li>
>     <li>
>       <a href="/products">Products</a>
>     </li>
>     <!-- Dropdown submenu: -->
>     <li>
>       <button aria-expanded="false"
>               aria-controls="about-menu">
>         About
>       </button>
>       <ul id="about-menu" hidden role="list">
>         <li><a href="/team">Team</a></li>
>         <li><a href="/history">History</a></li>
>       </ul>
>     </li>
>   </ul>
> </nav>
> ```
>
> Why `<ul>` for navigation items:
> - Screen readers announce "list, 3 items" giving users a count
>   before navigating through
> - Semantic list communicates "these are related navigation items"
>
> Multiple `<nav>` elements: valid, but each needs `aria-label`
> to distinguish them (main navigation, breadcrumbs, footer nav,
> table of contents). Without labels, screen readers just announce
> "navigation" for each.
>
> Skip link (required for accessibility):
> ```html
> <!-- First element in body, visually hidden until focused -->
> <a href="#main-content" class="skip-link">
>   Skip to main content
> </a>
> ```
>
> *What separates good from great:* The skip link is WCAG 2.1 Level A
> requirement. Users navigating by keyboard must Tab through every
> navigation link on every page before reaching content. A skip
> link lets them bypass navigation directly. It can be visually
> hidden by default and shown on `:focus` - serving keyboard
> users without affecting visual design.

---

**Q6: What are the different `rel` values for links and when
do you use them?** `[SENIOR]` DEFINITION

*Why they ask:* SEO + security knowledge via rel attribute.

*Likely follow-up:* "When should you use nofollow vs sponsored?"

> **Answer:**
>
> The `rel` attribute defines the RELATIONSHIP between the current
> document and the linked URL.
>
> Security:
> - `noopener` - block `window.opener` (use with target="_blank")
> - `noreferrer` - no Referer header + noopener
>
> SEO:
> - `nofollow` - don't pass PageRank; search engines may ignore
>   the link for ranking. When: untrusted user-generated content,
>   links you don't want to endorse.
> - `sponsored` - paid/sponsored link. REQUIRED by Google for
>   compensated placements since 2019. Failure = manual penalty.
> - `ugc` - user-generated content. For forum links, comments.
>
> Content relationships:
> - `alternate` - alternate version (different language, format,
>   mobile version). Used with `hreflang` for international SEO.
> - `canonical` - preferred URL for this content (in `<link>`,
>   not `<a>`)
> - `author` - author information page
> - `license` - license for page content
>
> Preloading:
> - `prefetch` - pre-fetch for likely next navigation
> - `preconnect` - establish connection to origin (on `<link>`)
> - `preload` - preload resource (on `<link>`)
>
> Multiple values (space-separated):
> ```html
> <a href="https://partner.com"
>    rel="noopener noreferrer nofollow sponsored"
>    target="_blank">
>   Partner site (sponsored)
> </a>
> ```
>
> *What separates good from great:* Google's 2019 update changed
> `nofollow` from a hard directive to a hint (Google may choose
> to follow it anyway). `sponsored` and `ugc` provide more precise
> signals about WHY the link is nofollowed. Paid links without
> `sponsored` can trigger manual Google penalties - this is a
> real revenue-impacting issue for commerce sites.

---

**Q7: What is the skip navigation pattern and why is it required?**
`[SENIOR]` MECHANISM

*Why they ask:* Keyboard accessibility requirement.

*Likely follow-up:* "How do you visually hide it until focus?"

> **Answer:**
>
> Skip navigation is a link at the top of the page that allows
> keyboard users to bypass the navigation and jump directly
> to the main content.
>
> Why required: keyboard users navigate sequentially by pressing
> Tab. On a page with 30 navigation links, they must Tab 30 times
> to get from the top of the page to the main content - on EVERY
> page. Skip nav eliminates this.
>
> WCAG 2.1 Success Criterion 2.4.1 (Level A - must pass):
> "A mechanism is available to bypass blocks of content that are
> repeated on multiple web pages."
>
> Implementation:
> ```html
> <!-- First element in <body> -->
> <a href="#main-content" class="skip-link">
>   Skip to main content
> </a>
>
> <!-- Target: the <main> element -->
> <main id="main-content" tabindex="-1">
>   <!-- Content here -->
> </main>
> ```
>
> ```css
> .skip-link {
>   /* Visually hidden by default: */
>   position: absolute;
>   top: -40px;
>   left: 0;
>   background: #000;
>   color: white;
>   padding: 8px;
>   z-index: 9999;
> }
> .skip-link:focus {
>   /* Visible when keyboard-focused: */
>   top: 0;
> }
> ```
>
> `tabindex="-1"` on `<main>`: allows the skip link to MOVE FOCUS
> to `<main>` via `href="#main-content"`. Without `tabindex="-1"`,
> the viewport scrolls to `<main>` but focus stays on the skip
> link, defeating the purpose.
>
> *What separates good from great:* The `tabindex="-1"` on the
> target element is a subtle but critical detail. Without it,
> clicking the skip link scrolls the page but doesn't move
> keyboard focus to the content area. The user still Tabs from
> the skip link back through all navigation. `-1` makes the
> element programmatically focusable (via `href` fragment + JS
> `focus()`) without adding it to the natural tab order.

---

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel | rel attribute values + security |
| Hiring Manager | Accessibility compliance |
| Bar Raiser | Skip nav + reverse tabnapping |
| Peer Engineer | link vs button + navigation structure |

---

### ⚖️ Comparison Table

*(Omit: ★☆☆ keyword.)*

---

### 🏛️ System Design

*(Omit: ★☆☆ keyword.)*

---

### 📊 Diagram

*(Omit: navigation structure best expressed in code examples.)*
