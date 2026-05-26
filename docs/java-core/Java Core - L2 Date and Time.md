---
layout: default
title: "Java Core - L2 Date and Time"
parent: "Java Core"
nav_order: 5
permalink: /java-core/l2-date-and-time/
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Java Date Time API Overview](#java-date-time-api-overview) | high |
| 2 | [LocalDate LocalTime and LocalDateTime](#localdate-localtime-and-localdatetime) | high |
| 3 | [ZonedDateTime and Time Zones](#zoneddatetime-and-time-zones) | high |
| 4 | [Duration Period and Temporal Arithmetic](#duration-period-and-temporal-arithmetic) | medium |

---

# Java Date Time API Overview

**Interview Weight:** high - Asked at every level for Java roles.
Interviewers expect you to know why `java.util.Date` is deprecated,
what replaced it, and the design principles of the new API.

---

### 🎯 Model Answer

**30 seconds:**

> The `java.time` API (Java 8, JSR-310) replaced `java.util.Date`
> and `Calendar`. It separates concerns: `LocalDate` for date-only,
> `LocalTime` for time-only, `LocalDateTime` for date+time without
> timezone, `ZonedDateTime` for timezone-aware, `Instant` for a
> point on the global timeline. All classes are immutable and
> thread-safe. The old `Date`/`Calendar` API was mutable, thread-
> unsafe, and had confusing month indexing (0-based months).

**3 minutes (Senior):**

> The old API had three fundamental problems. First, mutability:
> `Date` and `Calendar` objects could be mutated after creation,
> making defensive copying mandatory for correctness. Second, design
> inconsistency: `Calendar.JANUARY` is 0, not 1 - a source of
> off-by-one bugs for 20 years. Third, no concept separation: a
> `Date` was actually a timestamp (milliseconds since epoch), not
> a "date" - making the name misleading.
>
> The `java.time` API separates the abstraction correctly. An
> `Instant` is a point on the global timeline (nanosecond precision).
> A `LocalDate` is a date without any timezone - "2024-03-15" as a
> concept, not tied to a specific millisecond. A `ZonedDateTime`
> is a LocalDateTime plus a timezone rule, which correctly handles
> DST transitions. A `ZoneOffset` is a fixed offset (+05:30) without
> DST rules.
>
> For database interop: `Instant` maps to a UTC timestamp column.
> `LocalDate` maps to a DATE column. `LocalDateTime` maps to a
> DATETIME column without timezone. For most microservices, store
> timestamps as `Instant` (UTC) and convert to `ZonedDateTime` for
> display only.

**Framework:** OLD API (mutable, 0-based months, confusing) →
NEW API (java.time, immutable, type-safe) → KEY TYPES (Instant,
Local*, Zoned*) → DATABASE MAPPING (Instant=UTC, LocalDate=DATE)

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about the java.time API and how
it compares to the old Date/Calendar."

**(2) First principles:** "Any date/time API needs to separate:
a point in time (timestamp), a calendar date, a time of day, and
a timezone. The old API merged all of these badly."

**(3) Bridge:** "This is similar to Python's datetime module:
datetime vs date vs time, timezone-naive vs timezone-aware."

---

### 📘 Concept Explanation

**What it is:**

`java.time` (JSR-310, Java 8) is the modern date and time API.
Core types: `Instant` (nanoseconds since epoch), `LocalDate`
(calendar date), `LocalTime` (time of day), `LocalDateTime`
(date + time, no timezone), `ZonedDateTime` (date + time +
timezone), `OffsetDateTime` (date + time + fixed offset).

**The problem it solves:**

`java.util.Date`: mutable, represents milliseconds since epoch
despite the name "Date," months are 0-indexed. `Calendar`: mutable,
complex API, no type safety between date components. Both are
not thread-safe, requiring synchronization in shared contexts.

**How it works:**

```
  Global Timeline
  ──────────────────────────────────────────────────────
              Instant                     Instant
        (nanoseconds since epoch)       (UTC always)

  Zone Aware
  ──────────────────────────────────────────────────────
       ZonedDateTime                ZonedDateTime
   (Instant + ZoneId rules)     (handles DST correctly)

  Zone Naive
  ──────────────────────────────────────────────────────
       LocalDateTime = LocalDate + LocalTime
   (no timezone - "2024-03-15T14:30" is an abstract concept)
```

**The key insight:**

`LocalDateTime` is NOT timezone-aware. Two `LocalDateTime` objects
with the same values in New York and London represent two completely
different moments in real time. The name is misleading - it does
not mean "local to the current timezone." It means "no timezone
information." When you need a real-world timestamp, use `Instant`.

**When to use it:**

- `Instant`: storing timestamps in databases, event times, audit logs
- `LocalDate`: birthdays, holidays, dates without time component
- `LocalTime`: business hours, opening times without a specific date
- `LocalDateTime`: appointment times shown to users in a single timezone
- `ZonedDateTime`: user-visible times across different timezones, calendaring

**When NOT to use it:**

- Never store `LocalDateTime` as "the time something happened" without
  also storing the timezone - you lose the ability to compare events
  across timezones
- Avoid `Date`/`Calendar` in new code - they are effectively deprecated
- Do not use `java.sql.Date` in new code; use `LocalDate` and configure
  the JDBC driver to handle java.time types

**Alternatives:**

- `Joda-Time` - the predecessor that inspired java.time; no longer
  needed in Java 8+
- `Instant` + `ZoneId` instead of `ZonedDateTime` for explicit control

**First-principles derivation:**

Date and time require four orthogonal concepts: (1) a point on the
timeline (Instant), (2) a human-readable calendar date (LocalDate),
(3) a human-readable time of day (LocalTime), (4) the mapping rule
between human time and UTC (ZoneId/ZoneOffset). Any date/time API
that conflates these concepts creates bugs. JSR-310 separates them
cleanly, making invalid operations (adding a timezone to a timeline
point) type errors.

---

### 💻 Code Example

**Example 1: Old API vs new API comparison**

```java
// BAD: java.util.Date / Calendar (mutable, confusing)
Calendar cal = Calendar.getInstance();
cal.set(2024, Calendar.MARCH, 15);  // MARCH = 2, not 3!
Date d = cal.getTime();             // mutable - anyone can setTime()
// cal.getTime() returns a Date which is actually a timestamp
// "date" but contains hours/minutes/seconds (usually midnight or now)

// BAD: Date arithmetic is painful
Calendar tomorrow = Calendar.getInstance();
tomorrow.setTime(d);
tomorrow.add(Calendar.DAY_OF_MONTH, 1);
Date nextDay = tomorrow.getTime();

// GOOD: java.time is immutable and expressive
LocalDate date = LocalDate.of(2024, Month.MARCH, 15); // Month enum, not 0-indexed
LocalDate nextDay = date.plusDays(1);   // immutable - returns new object
LocalDate prevMonth = date.minusMonths(1);

// GOOD: Timestamp for events
Instant now = Instant.now();        // UTC timestamp, nanosecond precision
Instant oneHourLater = now.plus(Duration.ofHours(1));
```

> **Code walkthrough:** The BAD pattern shows the classic Calendar
> pitfalls: `MARCH` is 2 (0-indexed), the calendar is mutable (any
> code holding a reference can change it), and arithmetic requires
> multi-step mutation. The GOOD pattern shows java.time: month names
> are type-safe enums, every operation returns a new immutable
> instance, and `Instant` represents real timestamps correctly.

**Example 2: Timezone-aware operations**

```java
// BAD: Storing LocalDateTime as a timestamp loses timezone info
LocalDateTime meetingTime = LocalDateTime.of(2024, 3, 15, 14, 0);
// Stored in DB as "2024-03-15 14:00:00"
// When retrieved in a different timezone, it means a different Instant!

// GOOD: Store as Instant (UTC) in the database
ZoneId nyZone = ZoneId.of("America/New_York");
ZonedDateTime meeting = ZonedDateTime.of(meetingTime, nyZone);
Instant storedInDb = meeting.toInstant();  // UTC timestamp, timezone-safe

// Retrieve and display in any timezone
Instant fromDb = storedInDb;
ZonedDateTime inNewYork = fromDb.atZone(ZoneId.of("America/New_York"));
ZonedDateTime inLondon  = fromDb.atZone(ZoneId.of("Europe/London"));
// Both represent the same moment, displayed in local time

// DST-aware: ZonedDateTime handles the DST gap correctly
// March 10, 2024 2:30 AM does not exist in America/New_York (clocks spring forward)
ZonedDateTime dstGap = ZonedDateTime.of(
    LocalDateTime.of(2024, 3, 10, 2, 30), ZoneId.of("America/New_York")
);
// Java adjusts to 3:30 AM automatically - no exception, no silent wrong value
```

> **Code walkthrough:** Storing `LocalDateTime` in a database as
> an event timestamp is a common bug - the timezone is lost, making
> cross-timezone comparisons incorrect. The GOOD pattern stores
> `Instant` (UTC) in the database and converts to `ZonedDateTime`
> for display only. The DST example shows that `ZonedDateTime`
> handles the "spring forward" gap correctly - it adjusts the time
> rather than producing an invalid or incorrect value.

---

### ⚖️ Comparison

| Type | Has Date | Has Time | Has Timezone | Use Case |
|------|----------|----------|--------------|----------|
| `Instant` | no (timeline point) | no | UTC always | Event timestamps, audit logs |
| `LocalDate` | yes | no | no | Birthdays, holidays |
| `LocalTime` | no | yes | no | Opening hours, recurring times |
| `LocalDateTime` | yes | yes | no | Single-timezone display |
| `ZonedDateTime` | yes | yes | yes + DST rules | Cross-timezone calendaring |
| `OffsetDateTime` | yes | yes | fixed offset | Exchange with other systems |

**The deciding factor:** If you need to store "when did this happen"
(event time), use `Instant`. If you need to store "what the user sees
on their calendar" independent of timezone, use `LocalDateTime`.
If the timezone matters for display or DST, use `ZonedDateTime`.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> The new java.time API (Java 8+) replaces the old Date/Calendar.
> Main types: `LocalDate` for dates, `LocalTime` for times,
> `LocalDateTime` for date+time without timezone, `ZonedDateTime`
> for timezone-aware, `Instant` for UTC timestamps. All are
> immutable. Old Calendar had 0-indexed months and was mutable -
> avoid it in new code.

*Push deeper:* Why is `LocalDateTime` not timezone-aware, and when
does that matter?

---

**Senior / Staff (5+ years):**

> In production I follow one rule: store all event timestamps as
> `Instant` (UTC) in the database. Convert to `ZonedDateTime` for
> display only. This eliminates timezone bugs completely for event
> times. I use `LocalDate` for dates that are intentionally timezone-
> agnostic (birthdays, expiration dates). The common production bug:
> storing `LocalDateTime` as an event timestamp and then discovering
> that the application behaves differently in different deployment
> regions.

*Push deeper:* `OffsetDateTime` vs `ZonedDateTime` (fixed offset
vs named timezone with DST rules), and the JDBC driver configuration
needed for java.time types with various databases.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is the difference between `Date` and `Instant`?"
- "What replaced `java.util.Date`?"

🗣️ "`java.util.Date` was actually a timestamp (milliseconds since
Unix epoch) despite being named 'Date'. It was mutable and not
thread-safe. `java.time.Instant` is the modern replacement - an
immutable point on the global timeline with nanosecond precision.
`java.time` (Java 8, JSR-310) replaces the entire old API with
type-safe, immutable classes: `LocalDate`, `LocalDateTime`,
`ZonedDateTime`, and `Instant`."

#### Mechanism

- "What is wrong with `java.util.Date`?"

🗣️ "Three problems. First, mutability: `Date.setTime()` lets anyone
change the timestamp, breaking any class that holds a reference
to it without defensive copying. Second, naming: despite being
called 'Date', it stores a timestamp (milliseconds since epoch)
with time components - printing a Date gives you time too. Third,
Calendar is worse: months are zero-indexed (JANUARY=0), the API
is stateful, and time zone handling is error-prone. The java.time
API solves all three."

#### Comparison

- "`LocalDateTime` vs `ZonedDateTime` - when to use each?"

🗣️ "`LocalDateTime` has no timezone - it is an abstract date and
time concept. Two `LocalDateTime` values with the same content
in New York and Tokyo represent different moments in global time.
`ZonedDateTime` includes a timezone rule (`ZoneId`) and handles
DST transitions. I use `LocalDateTime` for user-visible appointment
times shown in a single timezone context (a meeting shown on a
local calendar). I use `ZonedDateTime` when I need to know the
actual real-world moment, compare across timezones, or handle
DST correctly."

#### Debugging

- "A timestamp stored in the database is always 5 hours off.
  What is the cause?"

🗣️ "This is a classic timezone misconfiguration. Most likely
causes: (1) The application is storing `LocalDateTime` converted
from `ZonedDateTime` without specifying UTC - the server timezone
offsets the value. (2) The JDBC driver is interpreting a TIMESTAMP
column using the JVM's default timezone when the database stores
UTC. The fix: store `Instant` and configure your JDBC driver and
JPA provider to use UTC for all timestamp handling (in Spring:
`spring.jpa.properties.hibernate.jdbc.time_zone=UTC`)."

#### Misconception / Trap

- "Can I use `==` to compare two `LocalDate` objects?"
- "Is `LocalDateTime.now()` the current time in UTC?"

🗣️ "No to both. `LocalDate` is an object - use `.equals()` or
`.isEqual()` for comparison. And `LocalDateTime.now()` returns
the current date-time in the JVM's default timezone, NOT UTC.
If you want UTC, use `LocalDateTime.now(ZoneOffset.UTC)` or better,
`Instant.now()` which is always UTC."

#### Performance and Scalability

- "What are the performance considerations for date/time operations
  at scale?"

🗣️ "`java.time` objects are immutable, so every arithmetic
operation creates a new object. In high-throughput paths processing
millions of timestamps, this can contribute to GC pressure. The
mitigation: batch process, use `DateTimeFormatter` instances as
static fields (they are thread-safe and expensive to create), and
prefer `Instant` arithmetic (which operates on longs) over
`ZonedDateTime` arithmetic (which resolves timezone rules) when
the timezone is not needed for the operation."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Type hierarchy, DST handling, immutability. |
| Hiring Manager   | Timezone bug in production - impact and prevention. |
| Bar Raiser       | JDBC driver config, thread-safety of DateTimeFormatter. |
| Peer Engineer    | "The LocalDateTime-as-timestamp bug bit us in production when..." |

---

---

# LocalDate LocalTime and LocalDateTime

**Interview Weight:** high - The daily-use API for most Java
date operations. Interviewers test both correct usage and the
key gotcha: these types are timezone-naive.

---

### 🎯 Model Answer

**30 seconds:**

> `LocalDate` is a date without time (year-month-day). `LocalTime`
> is a time without date (hour-minute-second-nano). `LocalDateTime`
> is both combined but without any timezone. All three are immutable
> and comparable. Key methods: `plus/minus` for arithmetic, `of`
> for construction, `now()` for current value, and `with` for
> adjustment. For timezone-aware timestamps, use `ZonedDateTime`
> or `Instant` instead.

**3 minutes (Senior):**

> These three types implement the `Temporal` interface and support
> a consistent arithmetic API: `plus(amount, unit)`, `minus`, and
> `with(field, value)` for adjustment. `TemporalAdjusters` provides
> common adjustments: `firstDayOfMonth()`, `lastDayOfNextMonth()`,
> `nextOrSame(DayOfWeek.MONDAY)`.
>
> `LocalDate.now()` uses the JVM default timezone to determine
> "today." This means two servers in different timezones can return
> different `LocalDate.now()` values at the same `Instant`. For
> globally consistent "today," pass an explicit `ZoneId`:
> `LocalDate.now(ZoneId.of("UTC"))`.
>
> Parsing and formatting use `DateTimeFormatter`, which is thread-
> safe and should be stored as a static final field. The old
> `SimpleDateFormat` was not thread-safe - a common production bug
> was sharing a `SimpleDateFormat` between threads.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about LocalDate, LocalTime, and
LocalDateTime - the timezone-naive date/time types."

**(2) First principles:** "A date, a time, and a combined date-
time are three distinct concepts. These three classes each model
one concept cleanly."

**(3) Bridge:** "In Python, these map to `date`, `time`, and
`datetime` from the `datetime` module - same separation, same
principle."

---

### 📘 Concept Explanation

**What it is:**

Three immutable, timezone-naive types:
- `LocalDate`: year + month + day (e.g., 2024-03-15)
- `LocalTime`: hour + minute + second + nanosecond (e.g., 14:30:00)
- `LocalDateTime`: both combined (e.g., 2024-03-15T14:30:00)

**How it works:**

```java
// Construction
LocalDate date  = LocalDate.of(2024, Month.MARCH, 15);
LocalDate today = LocalDate.now();                   // JVM timezone
LocalDate today2= LocalDate.now(ZoneId.of("UTC"));  // explicit timezone

// Arithmetic - all return NEW immutable objects
LocalDate nextWeek   = date.plusWeeks(1);
LocalDate lastYear   = date.minusYears(1);
LocalDate adjusted   = date.with(TemporalAdjusters.lastDayOfMonth());

// Comparison
boolean before = date.isBefore(LocalDate.of(2025, 1, 1));
long daysBetween = ChronoUnit.DAYS.between(date, nextWeek);  // 7

// Combining
LocalDateTime datetime = LocalDateTime.of(date, LocalTime.of(14, 30));
LocalDate    extracted = datetime.toLocalDate();

// Formatting - DateTimeFormatter is thread-safe, reuse it
DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd/MM/yyyy");
String formatted = date.format(fmt);       // "15/03/2024"
LocalDate parsed = LocalDate.parse("15/03/2024", fmt);
```

**The key insight:**

`LocalDate`, `LocalTime`, and `LocalDateTime` do not have a timezone
concept at all. `LocalDate.now()` determines "today" by applying
the JVM's default timezone to the current instant. If you change
the JVM timezone (or deploy to a server with a different timezone),
you may get a different "today." For globally consistent results,
always pass an explicit `ZoneId` to `now()`.

**When to use it:**

- `LocalDate`: user's birthday, product expiration dates, holidays,
  financial dates (business days)
- `LocalTime`: store opening hours, recurring time-of-day schedule
- `LocalDateTime`: meeting times in a scheduling app where all users
  are in the same timezone; database DATETIME columns without TZ

**When NOT to use it:**

- Event timestamps (when something happened globally) - use Instant
- User-visible times across multiple timezones - use ZonedDateTime
- Never rely on `LocalDate.now()` in production without specifying
  a timezone - servers may be in different timezones

---

### 💻 Code Example

**Example 1: Business day calculation using TemporalAdjusters**

```java
// Calculate the next business day (skip weekends)
LocalDate today = LocalDate.now(ZoneId.of("Europe/London"));

// BAD: Manual loop - verbose and easy to get wrong
LocalDate nextBizDay = today.plusDays(1);
while (nextBizDay.getDayOfWeek() == DayOfWeek.SATURDAY
    || nextBizDay.getDayOfWeek() == DayOfWeek.SUNDAY) {
    nextBizDay = nextBizDay.plusDays(1);
}

// GOOD: Custom TemporalAdjuster - reusable, testable
TemporalAdjuster nextBusinessDay = temporal -> {
    LocalDate d = LocalDate.from(temporal);
    return switch (d.getDayOfWeek()) {
        case FRIDAY   -> d.plusDays(3);  // Friday -> Monday
        case SATURDAY -> d.plusDays(2);  // Saturday -> Monday
        default       -> d.plusDays(1);  // Mon-Thu -> next day
    };
};
LocalDate next = today.with(nextBusinessDay);

// Common adjusters from TemporalAdjusters
LocalDate firstDay  = today.with(TemporalAdjusters.firstDayOfMonth());
LocalDate lastDay   = today.with(TemporalAdjusters.lastDayOfMonth());
LocalDate nextMonday= today.with(TemporalAdjusters.nextOrSame(DayOfWeek.MONDAY));
```

> **Code walkthrough:** The BAD pattern manually loops to skip
> weekends - verbose and duplicates logic that should be centralized.
> The GOOD pattern uses a custom `TemporalAdjuster` - a `@FunctionalInterface`
> that can be applied via `with()`. This is the java.time extension
> point for custom calendar logic. Built-in `TemporalAdjusters` handle
> the most common adjustments.

**Example 2: Safe parsing with error handling**

```java
// BAD: SimpleDateFormat is NOT thread-safe (classic production bug)
private static final SimpleDateFormat SDF = new SimpleDateFormat("yyyy-MM-dd");
// Multiple threads calling SDF.parse() or SDF.format() concurrently
// causes corrupt results or ParseException

// GOOD: DateTimeFormatter is thread-safe - safe as static final
private static final DateTimeFormatter ISO_DATE =
    DateTimeFormatter.ofPattern("yyyy-MM-dd");

// Safe parsing with error handling
Optional<LocalDate> safeParse(String input) {
    try {
        return Optional.of(LocalDate.parse(input, ISO_DATE));
    } catch (DateTimeParseException e) {
        return Optional.empty();
    }
}

// ISO_8601 format is built-in - no need to define pattern
LocalDate d = LocalDate.parse("2024-03-15");  // ISO-8601 default
```

> **Code walkthrough:** `SimpleDateFormat` is a production anti-
> pattern in concurrent code - it maintains internal state and breaks
> under concurrent access. `DateTimeFormatter` is immutable and
> thread-safe - store it as a static final and reuse freely. The
> `safeParse` helper wraps the checked `DateTimeParseException` in
> an `Optional` for callers that want to handle invalid input
> gracefully.

---

### ⚖️ Comparison

| Type | Date | Time | Timezone | Precision | Best For |
|------|------|------|----------|-----------|----------|
| `LocalDate` | yes | no | no | day | Birthdays, dates |
| `LocalTime` | no | yes | no | nanosecond | Time-of-day |
| `LocalDateTime` | yes | yes | no | nanosecond | Single-TZ display |
| `ZonedDateTime` | yes | yes | yes+DST | nanosecond | Cross-TZ events |
| `Instant` | no (epoch) | no | UTC | nanosecond | Event timestamps |

**The deciding factor:** If the timezone matters for any comparison
or display, use `ZonedDateTime`. If you only need date or time as
a calendar concept, use `Local*`.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `LocalDate` is date-only (year/month/day). `LocalTime` is time-
> only. `LocalDateTime` is both but no timezone. All are immutable.
> Methods follow a consistent pattern: `plusDays()`, `minusMonths()`,
> `withYear()`. For timezone-aware work, use `ZonedDateTime`.

*Push deeper:* Why `LocalDate.now()` depends on the JVM timezone.

---

**Senior / Staff (5+ years):**

> In production, I specify timezone explicitly for all `now()` calls
> and never depend on the JVM default timezone. `DateTimeFormatter`
> as a static final is mandatory - `SimpleDateFormat` sharing across
> threads was one of the most common threading bugs in pre-Java 8
> code. I also validate dates after parsing: a user-input date of
> `2024-02-30` should produce a `DateTimeParseException`, not a
> silently rolled-over March 1st.

*Push deeper:* `TemporalAdjusters` for custom calendar logic,
`DateTimeFormatterBuilder` for locale-aware formatting, and
`ResolverStyle.STRICT` vs `SMART` vs `LENIENT` for parsing control.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is the difference between `LocalDate` and `LocalDateTime`?"

🗣️ "`LocalDate` represents a date without a time component -
year, month, and day only. `LocalDateTime` represents a date
combined with a time of day. Neither has a timezone. If you need
timezone information, use `ZonedDateTime`. For event timestamps
(when something happened globally), use `Instant`."

#### Debugging

- "Your code works in London but shows the wrong date in Singapore.
  What happened?"

🗣️ "This is a `LocalDate.now()` timezone issue. `LocalDate.now()`
uses the JVM's default timezone to determine 'today.' A server
in London and a server in Singapore will return different dates
near midnight. The fix: always pass an explicit ZoneId: `LocalDate.now(ZoneId.of(\"UTC\"))` or the user's timezone. Alternatively,
use `Instant.now()` for event timestamps and convert to local
date in the display layer."

#### Misconception / Trap

- "Is `LocalDateTime.now()` the same as the current UTC time?"

🗣️ "No - `LocalDateTime.now()` returns the current date-time
in the JVM's default timezone, not UTC. On a JVM set to UTC,
they happen to be equal. On a JVM set to `America/New_York`,
it returns the Eastern Time value. For UTC timestamp, use
`Instant.now()` or `LocalDateTime.now(ZoneOffset.UTC)`."

#### Performance and Scalability

- "What performance consideration applies to `DateTimeFormatter`?"

🗣️ "`DateTimeFormatter` instances are expensive to create (they
parse the format pattern). They are immutable and thread-safe,
so the correct pattern is to create them once as static final
fields and reuse. The wrong pattern is creating a new formatter
per call in a high-throughput method. Also, for ISO-8601 format,
use the built-in `DateTimeFormatter.ISO_LOCAL_DATE` constant
rather than defining your own - it avoids the creation cost
entirely."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | Immutability, TemporalAdjusters, DateTimeFormatter thread-safety. |
| Hiring Manager   | Timezone bugs in production - business impact. |
| Bar Raiser       | ResolverStyle, locale-aware formatting, custom adjusters. |
| Peer Engineer    | "The SimpleDateFormat threading bug was in our logs for months..." |

---

---

# ZonedDateTime and Time Zones

**Interview Weight:** high - Frequently asked at senior level.
Timezone handling is a known pain point - interviewers probe for
production experience with DST bugs and UTC storage patterns.

---

### 🎯 Model Answer

**30 seconds:**

> `ZonedDateTime` is a `LocalDateTime` combined with a `ZoneId`
> (timezone rules, including DST transitions). `ZoneId` uses
> geographic names like `"America/New_York"` which correctly apply
> Daylight Saving Time rules. `ZoneOffset` is a fixed numeric
> offset like `"+05:30"` without DST rules. The golden rule for
> microservices: store timestamps as `Instant` (UTC), convert to
> `ZonedDateTime` for display only.

**3 minutes (Senior):**

> Timezone arithmetic is hard because of DST. When clocks spring
> forward (March in North America), the hour 2:00-3:00 AM does not
> exist. When clocks fall back, that hour exists twice (the first
> time on DST, the second time on standard time). `ZonedDateTime`
> handles both correctly: if you try to create a ZonedDateTime in
> a non-existent gap, Java adjusts it; if you create one in an
> overlap, Java uses the earlier offset.
>
> `ZoneId.of("America/New_York")` uses the IANA timezone database,
> which is updated when governments change DST rules. The JVM ships
> with a bundled copy of the IANA database - you may need to update
> the JVM or use the `tzdata` Maven artifact when countries change
> their DST rules unexpectedly.
>
> `Instant` to `ZonedDateTime` conversion: `instant.atZone(zoneId)`.
> `ZonedDateTime` to `Instant`: `zdt.toInstant()`. For database
> storage, always normalize to UTC (`Instant` or `OffsetDateTime`
> with UTC offset) and convert to the user's `ZoneId` in the
> presentation layer.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about ZonedDateTime and how
timezone-aware date/time handling works in Java."

**(2) First principles:** "The earth has different time offsets.
Some regions adjust clocks seasonally. Any timezone-aware type
needs: a point in time (Instant), a timezone rule (ZoneId), and
the ability to handle DST transitions."

**(3) Bridge:** "Python's timezone handling is analogous:
`datetime` + `tzinfo`. The same DST gap/overlap problems exist;
`pytz` (and now `zoneinfo`) handle them the same way."

---

### 📘 Concept Explanation

**What it is:**

`ZonedDateTime` = `LocalDateTime` + `ZoneId` (timezone rules).
`ZoneId` uses the IANA timezone database (e.g., `"America/New_York"`,
`"Europe/London"`, `"Asia/Kolkata"`). `ZoneOffset` is a simpler
fixed-offset timezone (e.g., `"+05:30"`, `"-05:00"`) without DST.

**How it works:**

```
  Instant (UTC)
    2024-03-10T07:30:00Z
           |
    atZone("America/New_York") → ZonedDateTime
    2024-03-10T03:30-05:00[America/New_York]
           |
    atZone("Europe/London") → ZonedDateTime
    2024-03-10T07:30Z[Europe/London]
           |
    atZone("Asia/Kolkata") → ZonedDateTime
    2024-03-10T13:00+05:30[Asia/Kolkata]
```

**The key insight:**

The same `Instant` (UTC timestamp) displayed in different zones
gives different `ZonedDateTime` values - but they are all the same
moment. DST is applied by the `ZoneId` rule: `"America/New_York"`
knows when to switch from -5:00 to -4:00 each year. `ZoneOffset`
like `"+05:30"` is static - it never changes regardless of DST.

**When to use it:**

- `ZonedDateTime`: any time you display a date-time to a user in
  their local timezone, or schedule events across timezones
- `OffsetDateTime`: exchanging timestamps with external systems
  (APIs, databases) where a fixed offset is required
- `ZoneOffset.UTC` / `Instant`: internal storage, always UTC

**When NOT to use it:**

- Do not store `ZonedDateTime` with a named zone in databases
  (database may not understand IANA zone names) - normalize to
  UTC `Instant` or `OffsetDateTime(UTC)` for storage
- Do not use `ZoneOffset.of("+05:30")` for Indian Standard Time
  in calculations - it does not handle historical rule changes.
  Use `ZoneId.of("Asia/Kolkata")` instead

---

### 💻 Code Example

**Example 1: DST-aware scheduling**

```java
// Schedule a meeting "every Monday at 10 AM New York time"
// Using Instant arithmetic FAILS across DST boundaries

ZoneId nyZone = ZoneId.of("America/New_York");
ZonedDateTime meetingNow = ZonedDateTime.of(
    LocalDate.of(2024, 3, 4),   // Monday in EST (-5)
    LocalTime.of(10, 0),
    nyZone
);
// 2024-03-04T10:00-05:00[America/New_York]
// = 2024-03-04T15:00Z in UTC

// BAD: Add 7 days via Instant arithmetic - wrong in DST weeks
Instant wrongNextWeek = meetingNow.toInstant().plus(Duration.ofDays(7));
// = 2024-03-11T15:00Z
// Which is 2024-03-11T11:00 AM New York time (DST sprang forward!)
// Meeting shifted to 11 AM!

// GOOD: Add 7 days via ZonedDateTime - handles DST correctly
ZonedDateTime correctNextWeek = meetingNow.plusWeeks(1);
// = 2024-03-11T10:00-04:00[America/New_York]
// = 2024-03-11T14:00Z in UTC
// Meeting stays at 10 AM New York time, DST handled automatically
```

> **Code walkthrough:** The BAD pattern adds 7 * 24 hours in UTC
> which crosses the DST boundary, shifting the New York display time.
> The GOOD pattern uses `ZonedDateTime.plusWeeks()` which adds a
> calendar week while respecting DST rules - the clock time stays
> at 10 AM New York time regardless of DST transitions. This is
> the critical difference between wall-clock arithmetic and absolute
> duration arithmetic.

**Example 2: UTC storage pattern**

```java
// Production pattern: UTC in, timezone out
@Entity
class Event {
    // GOOD: Store as Instant (UTC) in database
    private Instant scheduledAt;

    // GOOD: Accept user-facing ZonedDateTime, store as Instant
    public void setScheduledAt(ZonedDateTime userTime) {
        this.scheduledAt = userTime.toInstant();
    }

    // GOOD: Return ZonedDateTime for display in user's timezone
    public ZonedDateTime getScheduledAt(ZoneId userZone) {
        return scheduledAt.atZone(userZone);
    }
}

// Usage: user in London creates an event for 10 AM New York
ZoneId nyZone = ZoneId.of("America/New_York");
ZonedDateTime nyTime = ZonedDateTime.of(
    LocalDateTime.of(2024, 6, 15, 10, 0), nyZone
);
event.setScheduledAt(nyTime);  // stored as 2024-06-15T14:00:00Z

// Display to a Tokyo user
ZoneId tokyoZone = ZoneId.of("Asia/Tokyo");
System.out.println(event.getScheduledAt(tokyoZone));
// 2024-06-15T23:00+09:00[Asia/Tokyo]
```

> **Code walkthrough:** This is the canonical production pattern:
> accept user input as `ZonedDateTime` (user specifies their
> timezone), convert to `Instant` for storage, and reconvert to
> `ZonedDateTime` in the user's timezone for display. The database
> always stores UTC. This pattern is timezone-bug-free by design.

---

### ⚖️ Comparison

| Type | DST Rules | Mutability | Best Use |
|------|-----------|------------|----------|
| `ZoneId` (named) | yes | immutable | User display, scheduling |
| `ZoneOffset` (fixed) | no | immutable | External API exchange |
| `ZonedDateTime` | applies ZoneId | immutable | Full timezone-aware datetime |
| `OffsetDateTime` | applies ZoneOffset | immutable | DB/API without DST |
| `Instant` | UTC always | immutable | Storage, comparison |

**The deciding factor:** Use `ZonedDateTime` when DST matters for
the operation (scheduling, display). Use `Instant` for storage
and comparison. Use `OffsetDateTime` for exchange with systems
that require a fixed offset.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `ZonedDateTime` combines a `LocalDateTime` with a `ZoneId`
> timezone. `ZoneId` uses geographic names like `"America/New_York"`
> and includes DST rules. The main rule: store timestamps as `Instant`
> (UTC) and use `ZonedDateTime` only for display.

*Push deeper:* What happens to a `ZonedDateTime` during a DST
transition - the gap (spring forward) and overlap (fall back).

---

**Senior / Staff (5+ years):**

> DST is the main timezone pitfall. Adding 24 hours to a
> `ZonedDateTime` near a DST transition gives the wrong wall-clock
> time. You must use `plusDays()` on `ZonedDateTime`, not
> `plus(Duration.ofDays(1))` on the underlying `Instant`. I enforce
> UTC storage in all systems: database columns are `TIMESTAMP WITH
> TIME ZONE` or plain UTC; the presentation layer converts. When
> governments change DST rules (which happens), we update the JVM
> timezone data with the `tzdata` Maven artifact.

*Push deeper:* `ZonedDateTime` in a fold (DST overlap), choosing
the earlier vs later offset, and how `toInstant()` resolves
ambiguity.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is the difference between `ZoneId` and `ZoneOffset`?"

🗣️ "`ZoneId` is a named timezone like `'America/New_York'` that
uses the IANA timezone database and applies Daylight Saving Time
rules based on the date. `ZoneOffset` is a static UTC offset like
`'+05:30'` that never changes. Use `ZoneId` for user-facing times
where DST matters. Use `ZoneOffset` for external system exchange
where a fixed offset is expected."

#### Debugging

- "A scheduled job runs at the wrong time after a DST transition.
  What is the cause?"

🗣️ "The job is likely using duration arithmetic on `Instant` (adding
seconds/hours) instead of calendar arithmetic on `ZonedDateTime`
(adding days/weeks). When you add `Duration.ofDays(1)` to an
`Instant`, you always add exactly 86,400 seconds. But across a
DST transition, a wall-clock day might be 23 or 25 hours. Fix: use
`ZonedDateTime.plusDays(1)` which adds a calendar day and adjusts
for DST, keeping the wall-clock time constant."

#### Misconception / Trap

- "Is `ZoneOffset.UTC` the same as `ZoneId.of('UTC')`?"

🗣️ "They represent the same zone (UTC+0), but they are different
types. `ZoneOffset.UTC` is a `ZoneOffset` (fixed offset). `ZoneId.of('UTC')`
returns a `ZoneId`. For `ZonedDateTime.of(ldt, ZoneOffset.UTC)`,
the result has offset `+00:00`. For `ZonedDateTime.of(ldt, ZoneId.of('UTC'))`,
the result has the zone ID `'UTC'`. They compare as equal with
`.isEqual()` (same instant) but not `.equals()` (different types).
In practice, use `ZoneOffset.UTC` for UTC normalization."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | DST gap/overlap, arithmetic on ZonedDateTime vs Instant. |
| Hiring Manager   | UTC storage rule, production DST bugs. |
| Bar Raiser       | IANA database updates, ZonedDateTime fold resolution. |
| Peer Engineer    | "The scheduling DST bug cost us a missed batch run on clock-change Sunday..." |

---

---

# Duration Period and Temporal Arithmetic

**Interview Weight:** medium - Often tested as a follow-up when
the interviewer wants to confirm you understand the difference
between time-based and calendar-based durations.

---

### 🎯 Model Answer

**30 seconds:**

> `Duration` measures time-based amounts: hours, minutes, seconds,
> nanoseconds. `Period` measures calendar-based amounts: years,
> months, days. The distinction matters because a month is not a
> fixed duration (February has 28-29 days). Use `Duration` for
> machine time (timeouts, delays, elapsed time). Use `Period` for
> calendar arithmetic (age, billing cycles, date differences).

**3 minutes (Senior):**

> The `Duration`/`Period` split maps exactly to the gap/overlap
> problem in timezones. Adding `Duration.ofDays(1)` (86,400 seconds)
> to a `ZonedDateTime` near a DST boundary moves the wall-clock
> time by 23 or 25 hours. Adding `Period.ofDays(1)` uses calendar
> semantics - "tomorrow at the same time" - and handles DST. This
> is why `ZonedDateTime.plus(Duration.ofDays(1))` and
> `ZonedDateTime.plus(Period.ofDays(1))` produce different results
> across DST.
>
> `ChronoUnit` provides constants for both: `SECONDS`, `HOURS`
> are duration-based; `DAYS`, `MONTHS`, `YEARS` are calendar-based.
> `ChronoUnit.between(date1, date2)` measures the amount of the
> given unit between two temporals. Use `DAYS.between()` for
> business day counts; use `SECONDS.between()` for elapsed time.
>
> For measuring elapsed wall-clock time in code, avoid `Duration`
> between two `Instant.now()` calls in tight benchmarks - use
> `System.nanoTime()` (which is monotonic and immune to clock
> adjustments). `Instant.now()` uses the wall clock which can
> jump backward due to NTP.

**Blank Mind Recovery:**

**(1) Restate:** "You are asking about Duration vs Period
and how to do temporal arithmetic in Java."

**(2) First principles:** "Time has two semantics: absolute
duration (machine time) and calendar time (human-meaningful
units). These need different types because a month is not a
fixed number of seconds."

**(3) Bridge:** "Python's `timedelta` combines both, which is
simpler but loses the DST-awareness that Period provides."

---

### 📘 Concept Explanation

**What it is:**

- `Duration`: machine-based amount of time (hours, minutes,
  seconds, nanoseconds). Backed by seconds + nanosecond adjustment.
  Can be negative.
- `Period`: calendar-based date amount (years, months, days).
  Months and years have variable lengths.

**How it works:**

```java
// Duration - time-based
Duration threeHours   = Duration.ofHours(3);
Duration tenMinutes   = Duration.ofMinutes(10);
Duration fiveSeconds  = Duration.ofSeconds(5, 500_000_000); // 5.5s
Duration fromTo       = Duration.between(
                            LocalTime.of(9, 0),
                            LocalTime.of(17, 30)
                        );  // 8h30m

// Period - calendar-based
Period oneMonth    = Period.ofMonths(1);
Period twoYears    = Period.ofYears(2);
Period complex     = Period.of(1, 6, 15);  // 1yr 6mo 15d
Period between     = Period.between(
                         LocalDate.of(1990, 3, 15),
                         LocalDate.now()
                     );  // age in years/months/days

// ChronoUnit.between for measurement
long daysBetween = ChronoUnit.DAYS.between(
    LocalDate.of(2024, 1, 1),
    LocalDate.of(2024, 12, 31)
);  // 365

// Elapsed time measurement (use nanoTime for benchmarks!)
long start = System.nanoTime();
doWork();
long elapsed = System.nanoTime() - start;
Duration d = Duration.ofNanos(elapsed);
System.out.printf("Elapsed: %d ms%n", d.toMillis());
```

**The key insight:**

`Duration.ofDays(1)` is exactly 86,400 seconds. `Period.ofDays(1)`
is "one calendar day" which may be 23 or 25 hours across a DST
transition. When you want "the same time tomorrow," use `Period`.
When you want "exactly 24 hours from now," use `Duration`.

**When to use it:**

- `Duration`: HTTP request timeouts, connection pool timeouts,
  cache TTL, retry delays, elapsed time measurement
- `Period`: age calculation, subscription billing cycles, date
  filtering (records from the last 30 calendar days), payment
  due dates

**When NOT to use it:**

- Do not use `Instant.now()` for micro-benchmark timing - it can
  jump backward. Use `System.nanoTime()` (monotonic)
- Do not add `Duration.ofDays(30)` to get "next month" - use
  `Period.ofMonths(1)` or `plusMonths(1)` for calendar semantics

---

### 💻 Code Example

**Example 1: Duration for timeout configuration**

```java
// GOOD: Duration for machine-time quantities (timeouts, TTLs)
class HttpClientConfig {
    // Expressive: shows what 5000 means
    private final Duration connectTimeout = Duration.ofSeconds(5);
    private final Duration readTimeout    = Duration.ofSeconds(30);
    private final Duration cacheTtl       = Duration.ofMinutes(10);

    // BAD: Magic number - what does 5000 mean? Millis? Seconds?
    // private final long connectTimeout = 5000;

    HttpClient buildClient() {
        return HttpClient.newBuilder()
            .connectTimeout(connectTimeout)
            .build();
    }
}

// Measuring latency
Instant start = Instant.now();
String result = fetchFromRemote();
Duration latency = Duration.between(start, Instant.now());
if (latency.compareTo(Duration.ofMillis(200)) > 0) {
    metrics.recordSlowCall(latency.toMillis());
}
```

> **Code walkthrough:** Using `Duration` for timeout values makes
> the unit explicit and self-documenting. `Duration.ofSeconds(5)`
> is unambiguous; the magic number `5000` requires a comment to
> clarify it is milliseconds. Duration arithmetic and comparison
> (`compareTo`, `isNegative`, `toMillis`) is type-safe and readable.

**Example 2: Period for billing cycles**

```java
// GOOD: Period for calendar-based billing
class Subscription {
    private final LocalDate startDate;
    private final Period billingCycle;

    Subscription(LocalDate start, Period cycle) {
        this.startDate = start;
        this.billingCycle = cycle;
    }

    // When is the next billing date?
    LocalDate nextBillingDate(LocalDate from) {
        return from.plus(billingCycle);
    }

    // How many billing cycles have elapsed?
    int cyclesElapsed(LocalDate asOf) {
        Period elapsed = Period.between(startDate, asOf);
        // Approximate: normalize to same unit
        long months = elapsed.toTotalMonths();
        long cycleMonths = billingCycle.toTotalMonths();
        return (int) (months / cycleMonths);
    }
}

// Monthly subscription
Subscription monthly = new Subscription(
    LocalDate.of(2024, 1, 15),
    Period.ofMonths(1)
);
LocalDate nextBill = monthly.nextBillingDate(LocalDate.now());
// Jan 15 + 1 month = Feb 15 (not Feb 15 + 31 days = Mar 17!)
```

> **Code walkthrough:** `Period.ofMonths(1)` correctly handles
> variable-length months. Adding 1 month to January 15 gives
> February 15, not 31 days later (which would be March 17).
> `Duration.ofDays(31)` would give the wrong result for billing
> cycles. This is the key reason to use `Period` for calendar
> billing arithmetic.

---

### ⚖️ Comparison

| Type | Unit | DST-Aware | Negative | Use Case |
|------|------|-----------|---------|----------|
| `Duration` | nanos + secs | no (fixed seconds) | yes | Timeouts, elapsed time |
| `Period` | years + months + days | yes (via ZonedDateTime) | yes | Age, billing, calendar math |
| `ChronoUnit.between()` | single unit | depends on type | yes | Count of a specific unit |

**The deciding factor:** If the unit has variable length (months,
years), use `Period`. If you need exact machine time (seconds,
nanoseconds), use `Duration`.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**

> `Duration` is for time amounts: hours, minutes, seconds. `Period`
> is for calendar amounts: years, months, days. They differ because
> a month is not a fixed number of seconds. Use `Duration` for
> timeouts and delays; use `Period` for date arithmetic like
> calculating an age or a billing cycle.

*Push deeper:* Why `Duration.ofDays(1)` and `Period.ofDays(1)`
behave differently across DST transitions.

---

**Senior / Staff (5+ years):**

> The Duration vs Period distinction catches developers when they
> first encounter DST bugs in scheduled jobs. I enforce two rules:
> (1) all timeout/TTL values are `Duration` (never raw `long`
> milliseconds), and (2) all calendar arithmetic uses `Period` or
> the `plus/minus Months/Years` methods on `LocalDate`/`ZonedDateTime`.
> For benchmarking, I always use `System.nanoTime()` because
> `Instant.now()` uses the wall clock and can jump backward during
> NTP adjustments.

*Push deeper:* `TemporalAmount` interface that both `Duration`
and `Period` implement, custom `TemporalAmount` for business
calendar arithmetic, and `ChronoUnit.between()` for unit
measurement.

---

### ❓ Questions You Will Be Asked

#### Definition

- "What is the difference between `Duration` and `Period`?"

🗣️ "`Duration` measures time-based amounts - exact seconds and
nanoseconds. `Period` measures calendar-based amounts - years,
months, and days. The key difference is that months and years
have variable lengths: February can be 28 or 29 days. `Duration.ofDays(1)`
is exactly 86,400 seconds. `Period.ofDays(1)` means 'one calendar
day,' which could be 23 or 25 hours across a DST transition."

#### Mechanism

- "How do you measure elapsed time in Java?"

🗣️ "For code benchmarking and elapsed time measurement, I use
`System.nanoTime()` - it returns a monotonic counter that only
goes forward and is not affected by wall clock adjustments or
NTP synchronization. `Instant.now()` measures wall clock time,
which can theoretically go backward if NTP adjusts the system
clock. The pattern is: `long start = System.nanoTime(); doWork();
long elapsed = System.nanoTime() - start; Duration d = Duration.ofNanos(elapsed);`"

#### Comparison

- "`Duration.ofDays(30)` vs `Period.ofMonths(1)` - when does the
  difference matter?"

🗣️ "For billing cycles, subscription renewals, or any calendar
date math, `Period.ofMonths(1)` is correct. Adding 1 month to
January 31 gives February 28/29 (the last day of February).
Adding `Duration.ofDays(30)` gives March 2 - which is wrong for
a monthly subscription that started on January 31. The difference
matters whenever the months in the range have different lengths
or when DST transitions could change the number of hours in a day."

| Interviewer Type | Emphasis |
|---|---|
| Technical Panel  | DST and Duration vs Period, ChronoUnit measurement. |
| Hiring Manager   | Billing cycle correctness - business accuracy. |
| Bar Raiser       | System.nanoTime for monotonic timing, TemporalAmount interface. |
| Peer Engineer    | "The billing-cycle-off-by-a-day bug every February 28th..." |
