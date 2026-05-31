---
layout: default
title: "Java Core - L3 DateTime and Records"
parent: "Java Core"
grand_parent: "SK Interview"
nav_order: 10
permalink: /java-core/l3-datetime-and-records/
render_with_liquid: false
---

## Keywords in This File
{: .no_toc }

| # | Keyword | Weight |
|---|---|---|
| 1 | [Java Core - L3 DateTime and Records](#java-core---l3-datetime-and-records) | medium |

---

# Java Core - L3 DateTime and Records

## Java Date and Time API

---

### 🎯 Model Answer

**30 seconds:**
> Java 8 introduced `java.time` - a comprehensive, immutable date/time API.
> Key types: `LocalDate` (date only), `LocalTime` (time only), `LocalDateTime`
> (both, no timezone), `ZonedDateTime` (with timezone), `Instant` (machine
> timestamp, UTC epoch seconds), `Duration` (time-based amount), `Period`
> (date-based amount). All are immutable. `DateTimeFormatter` for formatting/parsing.
> The old `java.util.Date` and `Calendar` are mutable, not thread-safe, and
> replaced by `java.time` in modern code.

**3 minutes (Senior):**
> Key design: `Instant` is a machine timestamp (epoch seconds + nanos since
> 1970-01-01T00:00:00Z). `ZonedDateTime` is a human timestamp with timezone
> rules (DST, offsets). Always use `Instant` for storing/comparing times,
> `ZonedDateTime` for user display. Timezone pitfalls: `ZoneId.of("Asia/Kolkata")`
> (name-based, observes DST rules) vs `ZoneOffset.of("+05:30")` (fixed offset,
> no DST). Storing `ZoneOffset` loses historical DST info.
>
> `DateTimeFormatter` is thread-safe (immutable) - create once as a static
> constant. `SimpleDateFormat` is NOT thread-safe - never share instances.
> `ChronoUnit` for field-based arithmetic: `ChronoUnit.DAYS.between(d1, d2)`.
> Business day calculations require `TemporalAdjusters` or a library like
> ThreeTenExtra. `Duration.between(t1, t2)` for time-based differences.
> `Period.between(d1, d2)` for date-based (days/months/years).

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Java date/time API - let me cover LocalDate/Time,
Instant, ZonedDateTime, formatting, arithmetic, and the key differences
from the old Date/Calendar API."

**(2) First principles:** "From first principles: time has two views -
machine time (a number: nanoseconds since epoch, timezone-agnostic) and
human time (2024-01-15 in Tokyo timezone). Java time provides both.
Immutability ensures thread safety and prevents the 'share and mutate'
bugs common with Date/Calendar."

**(3) Bridge:** "java.time is like a precision watch collection. Instant
is a stopwatch (pure elapsed time). LocalDateTime is a wall clock
(shows 3pm but doesn't say where). ZonedDateTime is a world clock
(3pm in New York, accounting for DST). Each tool for its purpose."

---

### 📘 Concept Explanation

**Type hierarchy:**
```
LocalDate       - 2024-01-15 (no time, no timezone)
LocalTime       - 14:30:00 (no date, no timezone)
LocalDateTime   - 2024-01-15T14:30:00 (no timezone)
OffsetDateTime  - 2024-01-15T14:30:00+05:30 (fixed offset)
ZonedDateTime   - 2024-01-15T14:30:00+05:30[Asia/Kolkata] (full timezone)
Instant         - 1705316400.000000000 (epoch seconds + nanos, UTC)
Year, YearMonth, MonthDay - partial dates
Duration        - "3 hours 30 minutes" (time-based amount)
Period          - "2 years 3 months 5 days" (date-based amount)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Creating and manipulating:**
```java
// Creation:
LocalDate today = LocalDate.now();
LocalDate date = LocalDate.of(2024, Month.JANUARY, 15);
LocalDate date = LocalDate.parse("2024-01-15"); // ISO-8601

LocalTime time = LocalTime.of(14, 30, 0);
LocalDateTime ldt = LocalDateTime.of(date, time);
ZonedDateTime zdt = ldt.atZone(ZoneId.of("Asia/Kolkata"));
Instant now = Instant.now(); // machine timestamp

// Arithmetic (returns new instance - immutable!):
LocalDate nextWeek = today.plusDays(7);
LocalDate lastYear = today.minusYears(1);
LocalDate endOfMonth = today.with(TemporalAdjusters.lastDayOfMonth());
LocalDate nextMonday = today.with(TemporalAdjusters.next(DayOfWeek.MONDAY));
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

> **Code walkthrough:** The timezone conversion example is the most
> common production use case: store as Instant (UTC), display in user's
> timezone. The wrong approach (storing LocalDateTime without timezone)
> creates ambiguity: does "2024-01-15 14:30" mean UTC, IST, or EST?
> The Duration vs Period distinction catches many newcomers - Duration
> for time gaps, Period for calendar date differences.

```java
// BAD: SimpleDateFormat is not thread-safe:
static final SimpleDateFormat SDF =
    new SimpleDateFormat("yyyy-MM-dd"); // SHARED static!
// Multiple threads formatting dates -> garbled output or exceptions!

// GOOD: DateTimeFormatter is thread-safe (immutable):
static final DateTimeFormatter FORMATTER =
    DateTimeFormatter.ofPattern("yyyy-MM-dd");
static final DateTimeFormatter ISO = DateTimeFormatter.ISO_DATE_TIME;

// Store as Instant (UTC), display in user timezone:
Instant eventTime = Instant.parse("2024-01-15T09:00:00Z"); // UTC

// Display for user in India:
ZonedDateTime istTime = eventTime.atZone(ZoneId.of("Asia/Kolkata"));
System.out.println(istTime.format(FORMATTER)); // "2024-01-15"

// Display for user in New York:
ZonedDateTime nyTime = eventTime.atZone(ZoneId.of("America/New_York"));
System.out.println(nyTime.format(DateTimeFormatter.RFC_1123_DATE_TIME));

// Duration vs Period:
Instant start = Instant.parse("2024-01-01T10:00:00Z");
Instant end = Instant.parse("2024-01-01T14:30:00Z");
Duration diff = Duration.between(start, end);
System.out.println(diff.toHours() + "h " + diff.toMinutesPart() + "m"); // 4h 30m

LocalDate d1 = LocalDate.of(2024, 1, 1);
LocalDate d2 = LocalDate.of(2024, 3, 15);
Period period = Period.between(d1, d2);
System.out.println(period.getMonths() + " months " +
                   period.getDays() + " days"); // 2 months 14 days
long daysDiff = ChronoUnit.DAYS.between(d1, d2); // 74 days total

// Finding business days (simplified):
LocalDate nextBusinessDay = LocalDate.now()
    .with(TemporalAdjusters.next(DayOfWeek.MONDAY)); // next Monday
// For proper business day calculation: use a library like ThreeTenExtra
```

> **Code walkthrough:** `Duration.toMinutesPart()` (Java 9) returns
> the minutes component (0-59), NOT total minutes. `Duration.toMinutes()`
> returns total minutes (270 for 4h 30m). Common mistake: using
> `toMinutes()` to display the "minutes part" of a 4h30m duration and
> showing "270 minutes" instead of "30 minutes". The `*Part()` methods
> (Java 9) were added precisely for this display use case.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Use `LocalDate` for dates without time, `LocalDateTime` for date+time
> without timezone, `ZonedDateTime` for timezone-aware datetime, `Instant`
> for machine timestamps. All are immutable - arithmetic returns new
> objects. `DateTimeFormatter` is thread-safe; `SimpleDateFormat` is not.
> For database storage: map to JDBC timestamp/date via
> `Timestamp.from(instant)` or `Date.valueOf(localDate)`.

---

**Senior / Staff (5+ years):**
> Production rule: store all times as UTC Instant or epoch millis/nanos.
> Display in user's local timezone only at the presentation layer.
> Never store `ZonedDateTime` directly in databases - the timezone name
> may change (political changes, DST rule updates). Store Instant + a
> separate timezone ID string if needed. JDBC 4.2+ supports `setObject`
> with `Instant` and `LocalDate` directly. Spring Data JPA automatically
> maps `Instant` to `TIMESTAMP` and `LocalDate` to `DATE`. Avoid
> `java.util.Date` entirely in new code - it's mutable and confusingly
> represents milliseconds since epoch (not a "date").

---

### ⚠️ Common Misconceptions

**Misconception 1: "`LocalDateTime` is sufficient for event scheduling."**
`LocalDateTime` has no timezone: "2024-01-15T14:30" could be 14:30 in
any timezone. Scheduling a meeting at "14:30 Monday" without timezone
context: is it 14:30 UTC? 14:30 EST? 14:30 IST? Use `ZonedDateTime` for
future events (DST rules matter for "next Monday 14:30 in New York").
Use `Instant` for past events stored in a database.

**Misconception 2: "`Duration.toMinutes()` gives the minutes component."**
`Duration.toMinutes()` converts the ENTIRE duration to minutes.
A 2h30m Duration: `toMinutes()` = 150 (not 30).
For display: use `toHoursPart()` and `toMinutesPart()` (Java 9) or
manually calculate: `duration.toMinutes() % 60`.

---

### 🚨 Failure Modes and Diagnosis

**Failure: DST gap causes appointment at wrong time.**
```java
// DST "spring forward" in New York: 2024-03-10 02:00 -> 03:00
// Scheduling "daily at 02:30 America/New_York":
LocalTime dailyTime = LocalTime.of(2, 30);
ZoneId nyZone = ZoneId.of("America/New_York");

LocalDate dstDay = LocalDate.of(2024, 3, 10);
LocalDateTime ldt = dstDay.atTime(dailyTime);
// 02:30 AM doesn't exist on DST day! Gap: 02:00-03:00 doesn't exist
ZonedDateTime zdt = ldt.atZone(nyZone);
// Result: 03:30 AM (adjusted forward by 1 hour) - surprise!
```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Diagnosis: appointments appearing 1 hour off on DST transition days.
Use `ZonedDateTime.ofStrict(ldt, offset, zone)` to get an exception
instead of silent adjustment.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Instant vs LocalDateTime | 2 minutes |
| Timezone best practices | 2 minutes |
| DateTimeFormatter thread safety | 2 minutes |
| Duration vs Period | 2 minutes |
| DST handling | 2-3 minutes |
| Database integration | 2 minutes |
| java.util.Date migration | 2 minutes |
| TemporalAdjusters | 90 seconds |
| Calendar vs java.time | 2 minutes |

---

**Q1 (Instant vs LocalDateTime): When do you use Instant vs LocalDateTime?**

A: **Instant:** a point on the timeline, independent of timezone.
Expressed as seconds + nanoseconds since 1970-01-01T00:00:00Z (UTC epoch).
Use for: logging, event timestamps, database storage, comparing events,
measuring durations.

**LocalDateTime:** a date-time WITHOUT timezone information. Ambiguous
without knowing where.
Use for: representing schedule times in a specific local context,
birth dates where timezone doesn't matter, business hours, alarm times.

```java
// Logging (when did this happen): Instant
log.info("Request received at {}", Instant.now()); // UTC, unambiguous

// User birthday: LocalDate (no time, no timezone)
LocalDate birthday = LocalDate.of(1990, Month.JUNE, 15);
// Age calculation:
long age = ChronoUnit.YEARS.between(birthday, LocalDate.now());

// Meeting schedule: ZonedDateTime (timezone matters for DST)
ZonedDateTime meeting = ZonedDateTime.of(
    2024, 1, 15, 14, 30, 0, 0,
    ZoneId.of("America/New_York"));

// Store in DB: Instant -> TIMESTAMP
repository.save(event.withTimestamp(Instant.now()));
// Or: ZonedDateTime.toInstant() before storing
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The database storage decision is critical.
TIMESTAMP in SQL stores a moment in time (UTC-equivalent). Java's `Instant`
maps perfectly. `TIMESTAMP WITH TIME ZONE` in PostgreSQL also stores moments.
`TIMESTAMP WITHOUT TIME ZONE` stores "wall clock time" with no timezone -
matches `LocalDateTime`. A common production bug: storing `ZonedDateTime`
as text (with timezone string) in a VARCHAR. Later changes to timezone
rules (governments change DST rules) make old data display incorrectly.
Correct: store `Instant` (epoch seconds) + timezone ID string separately.

---

**Q2 (Timezone best practices): What are the best practices for
handling timezones in Java?**

A:
1. **Store as UTC/Instant:** database timestamps in UTC, expose as `Instant`
2. **Convert at the boundary:** convert to user timezone only in the UI layer
3. **Never assume system timezone:** `ZoneId.systemDefault()` changes based on deployment
4. **Use zone names, not offsets:** `Asia/Kolkata` not `+05:30` (offset changes with DST)
5. **Test DST transitions:** March/November in US, October/April in EU

```java
// Store user's timezone preference:
String userTimezone = "America/New_York"; // from user profile
ZoneId userZone = ZoneId.of(userTimezone); // validate at registration

// Convert for display:
Instant eventInstant = event.getTimestamp(); // UTC from DB
ZonedDateTime userTime = eventInstant.atZone(userZone);
String display = userTime.format(DateTimeFormatter
    .ofPattern("MMM d, yyyy h:mm a z")); // "Jan 15, 2024 9:00 AM EST"

// WRONG: storing timezone offset:
ZoneOffset offset = ZoneOffset.of("+05:30"); // India Standard Time
// Problem: India doesn't observe DST currently, but what if rules change?
// A zone NAME like "Asia/Kolkata" is future-proof; an offset is not.

// Time arithmetic: add 24 hours or 1 day?
ZonedDateTime now = ZonedDateTime.now(ZoneId.of("America/New_York"));
// "Same time tomorrow" in user's timezone (handles DST):
ZonedDateTime tomorrow = now.plusDays(1); // adds calendar day
// vs:
Instant plus24h = now.toInstant().plus(Duration.ofHours(24)); // adds 24h
// On DST "spring forward" day: plusDays(1) = 23h later in UTC!
// Most users expect "tomorrow 3pm" = same wall clock time tomorrow
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The `plusDays(1)` vs `plus(24h)` choice
is significant for user-facing scheduling. `ZonedDateTime.plusDays(1)` adds
a "calendar day" - the result is the same wall clock time tomorrow, even
if that's only 23 or 25 hours due to DST. `Instant.plus(Duration.ofHours(24))`
adds exactly 86400 seconds. Which is correct? For recurring alarms, calendar
events, "daily at 9am": use `plusDays(1)` (calendar semantics). For
monitoring cooldowns, retry delays, timeout windows: use Instant arithmetic
(exact seconds).

---

**Q3 (DateTimeFormatter thread safety): Why is DateTimeFormatter
thread-safe but SimpleDateFormat is not?**

A: `DateTimeFormatter` is immutable - all state (pattern, locale, zone)
is set at construction and never changes. Multiple threads can share one
instance safely.

`SimpleDateFormat` maintains mutable internal state during formatting
(calendar fields, format buffers) - shared access corrupts this state.

```java
// WRONG: shared SimpleDateFormat
private static final SimpleDateFormat SDF =
    new SimpleDateFormat("yyyy-MM-dd");
// Thread 1: sdf.format(date1) - modifies internal calendar
// Thread 2: sdf.format(date2) - corrupts Thread 1's in-progress format
// Result: garbled dates, wrong output, or exceptions

// FIX 1: ThreadLocal (one per thread, no sharing)
private static final ThreadLocal<SimpleDateFormat> TL_SDF =
    ThreadLocal.withInitial(() -> new SimpleDateFormat("yyyy-MM-dd"));
TL_SDF.get().format(date); // each thread has its own instance

// CORRECT: DateTimeFormatter is immutable, share freely
private static final DateTimeFormatter DTF =
    DateTimeFormatter.ofPattern("yyyy-MM-dd");
DTF.format(LocalDate.now()); // safe from any thread
DTF.format(LocalDate.now()); // same instance, concurrent calls OK

// Formatting:
LocalDate date = LocalDate.of(2024, 1, 15);
String s = date.format(DTF); // "2024-01-15"
String s = DTF.format(date); // same result, method on formatter

// Parsing:
LocalDate parsed = LocalDate.parse("2024-01-15", DTF);
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The `ThreadLocal<SimpleDateFormat>`
workaround was the pre-Java 8 standard for shared date formatting. With
Java 8+: use `DateTimeFormatter` - it's both correct and more convenient.
A code review flag: any static field of type `SimpleDateFormat` without
`ThreadLocal` wrapping is a concurrency bug waiting to surface under load.
This bug is often caught only in production when concurrent requests
corrupt each other's date formatting.

---

**Q4 (Duration vs Period): When do you use Duration vs Period?**

A: **Duration:** time-based amount (hours, minutes, seconds, nanoseconds).
Works with `Instant`, `LocalTime`, `LocalDateTime`, `ZonedDateTime`.

**Period:** date-based amount (years, months, days).
Works with `LocalDate` and `LocalDateTime`.

```java
// Duration: exact time difference
Instant start = Instant.parse("2024-01-15T10:00:00Z");
Instant end   = Instant.parse("2024-01-15T14:30:00Z");
Duration dur = Duration.between(start, end);
dur.toHours();        // 4
dur.toMinutes();      // 270 (TOTAL minutes, not the "minutes part"!)
dur.toMinutesPart();  // 30 (Java 9: the minutes component 0-59)
dur.toSecondsPart();  // 0  (Java 9: the seconds component 0-59)

// Period: calendar date difference
LocalDate d1 = LocalDate.of(2024, 1, 1);
LocalDate d2 = LocalDate.of(2025, 3, 15);
Period p = Period.between(d1, d2);
p.getYears();    // 1
p.getMonths();   // 2
p.getDays();     // 14
// "1 year, 2 months, and 14 days"

// ChronoUnit for total count:
long totalDays = ChronoUnit.DAYS.between(d1, d2); // 440

// Duration factory methods:
Duration.ofHours(3);
Duration.ofMinutes(90);
Duration.ofSeconds(3600);
Duration.parse("PT3H30M"); // ISO-8601 duration format

// Period factory:
Period.ofDays(7);
Period.ofMonths(3);
Period.of(1, 2, 3); // 1 year, 2 months, 3 days
Period.parse("P1Y2M3D"); // ISO-8601 period format
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The `Duration` vs `Period` distinction
matters in banking and finance: a loan with "3 month term" uses `Period.ofMonths(3)` (calendar months, different number of days). An SLA
of "72 hours" uses `Duration.ofHours(72)` (exact 72 * 3600 seconds).
Mixing them causes subtle bugs: "add 1 month" from Jan 31 = Feb 28
(Period) vs "+30 days" (Duration) = March 1 or 2. These are different
dates! `Period.addTo(LocalDate)` handles month-end correctly (Feb 28/29
on overflow).

---

**Q5 (DST handling): How do you handle daylight saving time transitions?**

A:
```java
// "Spring forward": clock skips 02:00-03:00 in America/New_York on 2024-03-10
ZoneId nyZone = ZoneId.of("America/New_York");
LocalDateTime gapTime = LocalDateTime.of(2024, 3, 10, 2, 30);

// LENIENT resolution (default): adjusts to next valid time
ZonedDateTime zdt = gapTime.atZone(nyZone);
System.out.println(zdt); // 2024-03-10T03:30-04:00[America/New_York]
// 02:30 became 03:30 (jumped forward)

// STRICT resolution: throws exception for invalid time
try {
    ZonedDateTime strict = ZonedDateTime.ofStrict(gapTime, ZoneOffset.of("-05:00"), nyZone);
} catch (DateTimeException e) {
    System.out.println("Time does not exist: " + e.getMessage());
}

// "Fall back": clock goes back at 02:00 in America/New_York on 2024-11-03
// 01:30 occurs twice (EST and EDT overlap)
LocalDateTime overlap = LocalDateTime.of(2024, 11, 3, 1, 30);
ZonedDateTime earlier = ZonedDateTime.of(overlap, ZoneOffset.of("-04:00"), nyZone); // EDT
ZonedDateTime later   = ZonedDateTime.of(overlap, ZoneOffset.of("-05:00"), nyZone); // EST

// Java chooses earlier occurrence by default with atZone()

// Best practice: work in UTC, convert only for display
// DST issues vanish when you store/compute in Instant:
Instant eventInstant = Instant.parse("2024-03-10T07:30:00Z");
// This is always 07:30 UTC, regardless of DST
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* DST bugs are the most common datetime
production issues. They manifest as: appointments shifted by 1 hour,
scheduler jobs running twice or not at all, SLA calculations off by
an hour. The architectural fix: all internal computation in UTC (Instant),
all display in user timezone. Never compute durations or time differences
using `ZonedDateTime` arithmetic (DST transitions make it unpredictable).
Use `Duration.between(instant1, instant2)` for exact elapsed time.

---

**Q6 (Database integration): How do you map java.time types to database columns?**

A:

| java.time Type | SQL Type | JDBC Method |
|---|---|---|
| `Instant` | `TIMESTAMP` | `setObject(n, instant)` (JDBC 4.2) |
| `LocalDate` | `DATE` | `setObject(n, localDate)` (JDBC 4.2) |
| `LocalTime` | `TIME` | `setObject(n, localTime)` (JDBC 4.2) |
| `LocalDateTime` | `TIMESTAMP` | `setObject(n, localDateTime)` (JDBC 4.2) |
| `ZonedDateTime` | `TIMESTAMP WITH TIME ZONE` | Via `OffsetDateTime` |

```java
// JPA / Hibernate (automatic mapping in Hibernate 5+):
@Entity
class Event {
    @Column(name = "created_at")
    private Instant createdAt; // maps to TIMESTAMP (UTC)

    @Column(name = "event_date")
    private LocalDate eventDate; // maps to DATE

    @Column(name = "start_time")
    private LocalDateTime startTime; // maps to TIMESTAMP (without TZ)
}

// Spring Data JPA: works out of the box with java.time types
// No @Temporal annotation needed (that was for java.util.Date/Calendar)

// Legacy java.util.Date ↔ java.time conversion:
Date legacyDate = Date.from(instant);          // Instant -> Date
Instant inst = legacyDate.toInstant();         // Date -> Instant

java.sql.Date sqlDate = java.sql.Date.valueOf(localDate); // LocalDate -> SQL Date
LocalDate localDate = sqlDate.toLocalDate();              // SQL Date -> LocalDate

java.sql.Timestamp ts = Timestamp.from(instant);  // Instant -> SQL Timestamp
Instant inst = ts.toInstant();                     // SQL Timestamp -> Instant
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* PostgreSQL stores TIMESTAMP WITH TIME ZONE
as UTC internally (converts from local time at insert). TIMESTAMP WITHOUT
TIME ZONE stores the literal values with no conversion. When querying
TIMESTAMP WITH TIME ZONE from JDBC 4.2: use `getObject(n, OffsetDateTime.class)`,
then convert to `Instant` or `ZonedDateTime`. Hibernate 5.x maps `Instant`
to `TIMESTAMP` (as UTC), which is correct. Older Hibernate versions
needed `@Type(type="instant")` or custom converters.

---

**Q7 (java.util.Date migration): How do you migrate from java.util.Date
and Calendar to java.time?**

A:
```java
// java.util.Date -> java.time:
Date d = new Date();
Instant instant = d.toInstant();                  // precise conversion
LocalDate localDate = instant.atZone(ZoneId.systemDefault())
    .toLocalDate();                               // requires timezone

// Calendar -> java.time:
Calendar cal = Calendar.getInstance();
ZonedDateTime zdt = cal.toInstant()
    .atZone(cal.getTimeZone().toZoneId());
LocalDateTime ldt = zdt.toLocalDateTime();

// java.time -> java.util.Date (for legacy APIs):
Date fromInstant = Date.from(instant);
Date fromLocal = Date.from(localDate.atStartOfDay()
    .atZone(ZoneId.systemDefault()).toInstant());

// SimpleDateFormat -> DateTimeFormatter:
// OLD: new SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
// NEW:
DateTimeFormatter newFmt =
    DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
// Parsing:
LocalDateTime ldt = LocalDateTime.parse(str, newFmt);
// Formatting:
String s = ldt.format(newFmt);

// Strategy for legacy code:
// 1. Convert to java.time at system boundaries (IO, DB, REST)
// 2. Process internally with java.time
// 3. Convert back to legacy types at output boundaries if needed
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The migration strategy is architectural:
don't mix `Date` and `java.time` in the same domain model. Define conversion
utilities at integration boundaries (DAO layer, REST controllers). Spring's
`@DateTimeFormat` and Jackson's `JavaTimeModule` (for JSON) automate
the conversion for web layer. For JDBC: ensure your driver supports JDBC 4.2
(all major drivers since 2014). The remaining `Date` usage after migration:
only in legacy library APIs that you can't change (`java.util.Timer`,
some old JMX APIs).

---

**Q8 (TemporalAdjusters): What is TemporalAdjusters and when do you use it?**

A: `TemporalAdjusters` provides factory methods for common date adjustments:
finding specific days (next Monday, last day of month, first business day).

```java
LocalDate today = LocalDate.now();

// Built-in adjusters:
LocalDate lastDayOfMonth = today.with(TemporalAdjusters.lastDayOfMonth());
LocalDate firstDayOfNextMonth = today.with(TemporalAdjusters.firstDayOfNextMonth());
LocalDate firstMondayOfMonth = today.with(TemporalAdjusters.firstInMonth(DayOfWeek.MONDAY));
LocalDate lastFridayOfMonth = today.with(TemporalAdjusters.lastInMonth(DayOfWeek.FRIDAY));
LocalDate nextMonday = today.with(TemporalAdjusters.next(DayOfWeek.MONDAY));
LocalDate nextOrSameMonday = today.with(TemporalAdjusters.nextOrSame(DayOfWeek.MONDAY));

// Custom adjuster (lambda):
TemporalAdjuster nextBusinessDay = temporal -> {
    LocalDate date = LocalDate.from(temporal);
    DayOfWeek dow = date.getDayOfWeek();
    int daysToAdd = switch (dow) {
        case FRIDAY -> 3;
        case SATURDAY -> 2;
        default -> 1;
    };
    return date.plusDays(daysToAdd);
};
LocalDate nextBD = today.with(nextBusinessDay);
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* `TemporalAdjusters` enables a clean,
composable way to express business date logic without raw date arithmetic.
The alternative (manual date loop checking day of week) is error-prone.
For proper business day calculations with holidays: use a library like
`jollyday` (reads holiday calendars from XML) or your company's own
business calendar service. `TemporalAdjusters` handles weekday logic;
public holidays require data.

---

**Q9 (Calendar vs java.time): Why was Calendar replaced by java.time?**

A: `java.util.Calendar` was problematic in multiple ways:

1. **Mutable:** shared Calendar instances cause thread-safety bugs
2. **Confusing month numbering:** months are 0-based (JANUARY=0)
3. **Mixed concerns:** Calendar handles both parsing AND date arithmetic
4. **Inconsistent API:** `get(Calendar.MONTH)` vs `get(Calendar.DAY_OF_MONTH)` 
5. **No date-only type:** Calendar always includes time (set time to midnight as workaround)
6. **Timezone handling:** `TimeZone` class with confusing DST support

```java
// Calendar's famous month bug:
Calendar cal = Calendar.getInstance();
cal.set(2024, 0, 15); // January! 0 = January, 11 = December
// java.time:
LocalDate date = LocalDate.of(2024, 1, 15); // 1 = January - intuitive!
LocalDate date = LocalDate.of(2024, Month.JANUARY, 15); // even better

// Calendar mutation bug:
Calendar cal = Calendar.getInstance();
processDate(cal); // might change cal's date!
cal.get(Calendar.DAY_OF_MONTH); // might return modified value

// java.time immutability:
LocalDate date = LocalDate.now();
LocalDate result = processDate(date); // original date unchanged
// processDate cannot modify date (immutable)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* `java.time` was designed by the same
team that wrote Joda-Time (the de facto replacement for Calendar before
Java 8). It incorporates lessons from 10+ years of Joda-Time usage. The
key design decisions: immutability (thread safety), separate types for
date vs time vs datetime vs timezone-aware datetime, and human-readable
month/day constants. The Joda-Time migration to java.time is almost
mechanical: `org.joda.time.LocalDate` -> `java.time.LocalDate`, etc.

---

### ⚖️ Comparison Table

| Type | Has Date | Has Time | Has Timezone | Use When |
|---|---|---|---|---|
| `LocalDate` | Yes | No | No | Birthdays, deadlines |
| `LocalTime` | No | Yes | No | Business hours, alarms |
| `LocalDateTime` | Yes | Yes | No | Schedule without TZ |
| `OffsetDateTime` | Yes | Yes | Fixed offset | DB with offset TZ |
| `ZonedDateTime` | Yes | Yes | Full TZ rules | User-facing events |
| `Instant` | UTC only | UTC only | UTC | Timestamps, storage |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: type hierarchy described adequately in Concept Explanation)*

---

---

## Records, Sealed Classes, and Pattern Matching

---

### 🎯 Model Answer

**30 seconds:**
> Java 16 Records: `record Point(int x, int y) {}` - a compact syntax for
> immutable data carriers. Auto-generates: constructor, accessors, `equals`,
> `hashCode`, `toString`. Java 17 Sealed Classes: `sealed interface Shape
> permits Circle, Square, Triangle {}` - restricts which classes can extend.
> Java 21 Pattern Matching for switch: `switch (shape) { case Circle c ->
> c.radius(); case Square s -> s.side(); }` - exhaustive matching on
> type hierarchies. Together: concise algebraic data types with compile-time
> exhaustiveness.

**3 minutes (Senior):**
> Records are ideal for DTOs, value objects, immutable domain concepts.
> Compact canonical constructor for validation: `record Range(int min, int max) {
> Range { if (min > max) throw new IllegalArgumentException(); } }`.
> Records can implement interfaces but cannot extend classes (implicitly
> extend Record). Can have static fields and methods, instance methods,
> but no instance state beyond components.
>
> Sealed types + records + pattern matching = algebraic data types in Java.
> Example: `sealed interface Expr permits Num, Add, Mul` with records for
> each case. Pattern matching evaluates exhaustively (compiler warns if
> case missed). This enables interpreter patterns without reflection.
> Java 21 `instanceof` pattern: `if (shape instanceof Circle c && c.radius() > 5)`.

**Framework:** WHAT → WHY → HOW → TRADE-OFF → EXAMPLE

**Blank Mind Recovery:**

**(1) Restate:** "Records, sealed classes, pattern matching - let me
cover records as immutable data carriers, sealed types for restricted
hierarchies, and pattern matching for exhaustive type-based switching."

**(2) First principles:** "From first principles: data transfer objects
need immutability and value-based equality. Records provide both with
minimal boilerplate. Sealed types express 'a Shape is either Circle, Square,
or Triangle - nothing else', enabling exhaustive handling in switch."

**(3) Bridge:** "Records are like named tuples with methods. Sealed types
are like enums for class hierarchies. Pattern matching switch is like
a type-aware switch/case that the compiler verifies is complete."

---

### 📘 Concept Explanation

**Records:**
```java
// Declaration: record Name(ComponentType name, ...) {}
record Point(double x, double y) {}

// Auto-generated:
// public Point(double x, double y) { this.x = x; this.y = y; }
// public double x() { return x; }  // accessor (not getX!)
// public double y() { return y; }
// public boolean equals(Object o) { ... }  // component-based
// public int hashCode() { ... }
// public String toString() { ... } // "Point[x=1.0, y=2.0]"

// Compact canonical constructor (for validation/normalization):
record Range(int min, int max) {
    Range { // no parameter list: implicit (min, max) params
        if (min > max)
            throw new IllegalArgumentException(
                "min " + min + " > max " + max);
    }
}

// Custom methods:
record Point(double x, double y) {
    static final Point ORIGIN = new Point(0, 0); // static OK
    double distanceTo(Point other) {
        return Math.hypot(x - other.x, y - other.y);
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Sealed types:**
```java
// Sealed interface: only listed subtypes allowed
sealed interface Shape permits Circle, Square, Triangle {}

record Circle(double radius) implements Shape {}
record Square(double side) implements Shape {}
record Triangle(double base, double height) implements Shape {}
// No other class can implement Shape (compile error)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

**Pattern matching:**
```java
// Switch expression with type patterns (Java 21):
double area(Shape shape) {
    return switch (shape) {
        case Circle c  -> Math.PI * c.radius() * c.radius();
        case Square s  -> s.side() * s.side();
        case Triangle t -> 0.5 * t.base() * t.height();
        // No default needed: exhaustive (sealed type)
    };
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

---

### 💻 Code Example

> **Code walkthrough:** The expression evaluator example shows records +
> sealed interface + pattern matching working together as algebraic data
> types. The compiler verifies exhaustiveness: if you add a new subtype to
> Expr without adding a case in eval(), it's a compile error. This is the
> correctness guarantee that makes this pattern superior to visitor pattern
> or instanceof chains.

```java
// Algebraic expression tree with records + sealed interface:
sealed interface Expr permits Num, Add, Mul, Neg {}
record Num(double value) implements Expr {}
record Add(Expr left, Expr right) implements Expr {}
record Mul(Expr left, Expr right) implements Expr {}
record Neg(Expr expr) implements Expr {}

// Pattern matching evaluator (compiler verifies exhaustiveness):
double eval(Expr expr) {
    return switch (expr) {
        case Num(double v) -> v;                    // record deconstruction (Java 21)
        case Add(Expr l, Expr r) -> eval(l) + eval(r);
        case Mul(Expr l, Expr r) -> eval(l) * eval(r);
        case Neg(Expr e) -> -eval(e);
        // No default: sealed Expr - compiler knows all cases covered!
    };
}
// Usage:
Expr expr = new Add(new Num(3), new Mul(new Num(4), new Num(5)));
double result = eval(expr); // 3 + (4 * 5) = 23

// instanceof pattern matching (Java 16):
Object obj = getObject();
// OLD:
if (obj instanceof String) {
    String s = (String) obj;
    if (s.length() > 5) process(s);
}
// NEW:
if (obj instanceof String s && s.length() > 5) {
    process(s); // s is scoped to this block
}

// Record as DTO:
record UserDTO(String name, String email, int age) {
    UserDTO { // validation
        Objects.requireNonNull(name, "name required");
        Objects.requireNonNull(email, "email required");
        if (age < 0 || age > 150) throw new IllegalArgumentException(
            "Invalid age: " + age);
    }
}
UserDTO user = new UserDTO("Alice", "alice@example.com", 30);
String json = """
    {"name":"%s","email":"%s","age":%d}
    """.formatted(user.name(), user.email(), user.age());
```

> **Code walkthrough:** Record deconstruction patterns (`case Num(double v)`)
> are Java 21 preview, stable in 21. They bind the record components
> directly in the case label without calling `expr.value()`. This makes
> recursive algorithms over expression trees extremely clean. The compiler
> verifies: if you add `case Div(Expr l, Expr r) implements Expr {}` to the
> sealed interface but don't add a case in `eval()`, the code won't compile.
> Exhaustiveness checking transforms runtime errors (unhandled case -> NPE
> or wrong result) into compile-time errors.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> Records are concise immutable data classes: `record Point(int x, int y) {}`
> auto-generates accessors (`.x()`, `.y()`), equals, hashCode, toString.
> Use compact canonical constructor for validation. Sealed types restrict
> class hierarchies. Pattern matching with `instanceof` eliminates cast after
> check: `if (s instanceof String str && str.length() > 5)`.

---

**Senior / Staff (5+ years):**
> Records + sealed interfaces + pattern matching enable algebraic data
> types (ADTs) in Java. ADTs are a core feature of Haskell/Scala/Rust.
> The pattern: sealed type defines the "sum type" (Shape is Circle OR Square
> OR Triangle), records define the "product types" (Circle has a radius).
> Pattern matching switch handles the cases exhaustively. This is superior
> to the visitor pattern (no more accept/visit boilerplate) and instanceof
> chains (no more casting, compiler-verified exhaustiveness). For Java
> architects: this enables compiler-verified business rule implementations
> where adding a new case to a domain type forces handling everywhere it's
> used.

---

### ⚠️ Common Misconceptions

**Misconception 1: "Records can be mutable."**
Records are explicitly designed for immutable data. Components are
`private final`. No setters are generated. You CAN add methods that
return modified copies (`withX()`), but the record itself is immutable.
Adding mutable fields (instance variables beyond components) is a design
violation even if technically possible.

**Misconception 2: "Sealed types are like final classes."**
`final` prevents any subclassing. `sealed` permits specific, enumerated
subclasses. The sealed type defines a closed, exhaustive set of subtypes
known at compile time. This enables exhaustive switch without default.
`final` would prevent extensibility entirely; `sealed` controls it.

---

### 🚨 Failure Modes and Diagnosis

**Failure: using records for mutable entities.**
```java
// WRONG: record for JPA entity (JPA requires mutable, no-arg constructor)
@Entity
record User(Long id, String name) {} // won't work with Hibernate!
// Records have no no-arg constructor and are immutable.
// JPA requires: no-arg constructor, mutable setters, non-final fields

// Use records for: DTOs, value objects, API responses
// Use regular classes for: JPA entities, mutable state

// Correct: record as DTO, class as entity
@Entity
class UserEntity { Long id; String name; /* getters/setters */ }
record UserDTO(Long id, String name) {} // immutable view
```
> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

Diagnosis: `InstantiationException` or `NoSuchMethodException` from Hibernate
when trying to use records as entities.

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| Records vs POJOs | 2 minutes |
| Sealed classes purpose | 2 minutes |
| Pattern matching exhaustiveness | 2 minutes |
| Records with validation | 90 seconds |
| Records limitations | 2 minutes |
| Algebraic data types | 2-3 minutes |
| Records vs Lombok | 2 minutes |
| Deconstruction patterns | 2 minutes |
| Switch expressions | 2 minutes |

---

**Q1 (Records vs POJOs): When do you use records vs regular classes?**

A: **Use records when:**
- The class is primarily a transparent data carrier
- Immutability is desired (value semantics)
- Equality should be based on all field values (component equality)
- Boilerplate reduction is valuable (DTOs, value objects, return types)

**Use regular classes when:**
- Mutable state is required (JPA entities, builder state)
- Extending another class is required (records implicitly extend Record)
- Hiding fields from equals/hashCode (password, internal cache)
- Complex construction logic beyond validation (factories, builders)
- Framework requirements (JPA, Jackson with no-arg constructor)

```java
// Record: perfect for coordinate
record GeoCoord(double lat, double lon) {}

// Record: HTTP response body (immutable, equality by content)
record ApiResponse<T>(int status, T data, String message) {}

// Regular class: JPA entity (mutable, no-arg constructor, partial equality)
@Entity
class Product {
    @Id Long id; // equality by id only, not all fields
    String name;
    BigDecimal price;
}

// Records work with Jackson 2.12+ without extra config:
// @JsonProperty auto-maps component names
record UserDTO(String name, String email) {}
// ObjectMapper.readValue(json, UserDTO.class) works!
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Records changed the "standard" for small
data classes. Before records: Lombok `@Value` (immutable) or `@Data` (mutable).
After records: use records for immutable data, plain classes with Lombok
`@Data` for mutable. The key difference from Lombok `@Value`: records
are a JVM concept (bytecode has RECORD attribute), not just boilerplate
generation. Reflection can inspect component names. Jackson's `RecordNamingStrategy`
knows about record components. IDE and tool support is first-class.

---

**Q2 (Sealed classes purpose): What problem do sealed classes solve?**

A: Sealed classes solve the "open world problem" for class hierarchies.
Without sealed: anyone can subclass your type, making exhaustive handling impossible.

```java
// Without sealed: unknown subtypes
interface Shape { double area(); }
// Caller:
double describe(Shape s) {
    if (s instanceof Circle c) return c.area();
    if (s instanceof Square sq) return sq.area();
    // Must have "else" - someone could add Triangle, Pentagon, etc.
    else throw new IllegalArgumentException("Unknown shape: " + s);
    // Runtime error for new subtypes - not caught at compile time!
}

// With sealed: exhaustive, compiler-verified
sealed interface Shape permits Circle, Square, Triangle {}
double describe(Shape s) {
    return switch (s) {
        case Circle c  -> c.area();
        case Square sq -> sq.area();
        case Triangle t -> t.area();
        // NO DEFAULT needed - compiler knows all cases!
        // Adding Square2 to Shape without handling it -> COMPILE ERROR
    };
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Sealed types are the Java equivalent of
Rust's enums with data, Haskell's ADTs, or Kotlin's sealed classes. They
enable "close the world" reasoning: you can prove that your switch handles
ALL possible cases. This matters for: error types (a `Result` is either
`Success` or `Failure`), state machines, AST nodes in compilers/interpreters,
protocol message types. The alternative before sealed: checked exceptions
(declare all failure types), but checked exceptions are for method signatures,
not type hierarchies.

---

**Q3 (Pattern matching exhaustiveness): How does the compiler verify
exhaustiveness in switch expressions?**

A: For a sealed type, the compiler knows all permitted subtypes at compile time.
A switch expression (not statement) must cover all cases or have a default.

```java
sealed interface Status permits Active, Inactive, Suspended {}
record Active() implements Status {}
record Inactive() implements Status {}
record Suspended(String reason) implements Status {}

// Exhaustive switch expression (no default needed):
String describe(Status s) {
    return switch (s) {
        case Active a    -> "Active user";
        case Inactive i  -> "Inactive user";
        case Suspended su -> "Suspended: " + su.reason();
    };
}
// If you remove the Suspended case: COMPILE ERROR
// "the switch expression does not cover all possible input values"

// Adding a new permitted type forces ALL switch expressions to handle it:
// sealed interface Status permits Active, Inactive, Suspended, PendingVerification {}
// -> All switches on Status fail to compile until PendingVerification is added!
// This is the compile-time safety guarantee.

// Switch statement (NOT expression) does NOT require exhaustiveness:
switch (s) {
    case Active a    -> System.out.println("active");
    // case Inactive i -> ... // missing case: compile WARNING, not error
} // statements can silently ignore cases - prefer expressions!
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The exhaustiveness checking is only
guaranteed for SWITCH EXPRESSIONS (not statements) and only when the
switched type is sealed. For non-sealed types: use `default` case or
accept the "missing cases" warning. The architectural value: when you
add a new domain concept (new `Status` type), the compiler forces all
processing code to acknowledge it. You can't accidentally miss a case
in a serializer, deserializer, or state machine handler.

---

**Q4 (Records with validation): How do you add validation to records?**

A:
```java
// Compact canonical constructor: runs after components are assigned
// Components are implicitly available (no param list needed)
record EmailAddress(String value) {
    EmailAddress { // compact constructor: no "(String value)" needed
        Objects.requireNonNull(value, "email required");
        if (!value.matches("[^@]+@[^@]+\\.[^@]+")) {
            throw new IllegalArgumentException(
                "Invalid email: " + value);
        }
        value = value.toLowerCase().strip(); // normalize (reassigns param)
    }
    // After compact constructor: this.value is normalized
}

// Explicit canonical constructor (more verbose but clearer):
record Range(int min, int max) {
    Range(int min, int max) {
        if (min > max) throw new IllegalArgumentException(
            "min " + min + " > max " + max);
        this.min = min;
        this.max = max;
    }
}

// Defensive copy for mutable components (rare in records - prefer immutable):
record Snapshot(List<String> items) {
    Snapshot {
        items = List.copyOf(items); // defensive copy + unmodifiable
    }
    // Accessor returns the unmodifiable copy:
    // List<String> items() { return items; } // auto-generated
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* The compact canonical constructor is
the preferred form: it's concise and makes the intent clear (validation/
normalization only). The `value = normalized(value)` assignment in the
compact constructor looks like it assigns a field, but it assigns the
PARAMETER - the framework then assigns the parameter to the final field.
This is the only place in Java where you can reassign a parameter that
"becomes" a final field. Understanding this mechanism is important for
correct validation code.

---

**Q5 (Records limitations): What can't you do with records?**

A:
1. **Cannot extend classes** (records implicitly extend `java.lang.Record`)
2. **Cannot declare instance variables** beyond components (only static)
3. **Cannot have mutable state** (all components are final)
4. **Cannot use as JPA entities** (no no-arg constructor, immutable)
5. **Cannot implement @FunctionalInterface** if it declares abstract methods beyond what records provide

```java
// Cannot extend a class:
record Point3D(int x, int y, int z) extends Point {} // COMPILE ERROR
// Can only extend java.lang.Record (implicit)

// Cannot add instance variables:
record Pair<A, B>(A first, B second) {
    private int count; // COMPILE ERROR: only static fields allowed!
    private static int instanceCount = 0; // OK: static
}

// CAN implement interfaces:
record Point(int x, int y) implements Comparable<Point> {
    @Override
    public int compareTo(Point other) {
        int xCmp = Integer.compare(x, other.x);
        return xCmp != 0 ? xCmp : Integer.compare(y, other.y);
    }
}

// CAN override component accessor:
record Name(String value) {
    public String value() { // override auto-generated accessor
        return value.strip(); // normalize on access
    }
}

// CAN have static factory methods:
record Color(int r, int g, int b) {
    static final Color RED = new Color(255, 0, 0);
    static Color of(String hex) {
        // parse hex color string
        return new Color(/* ... */);
    }
}
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Records being unable to extend other
classes is by design: they ARE the "product type" (all components, all
the time). Subclassing would allow adding components in a non-records way,
breaking the value semantics. If you need inheritance: use sealed interfaces
with records implementing them (as shown in the Expr example). The
interface approach gives you the polymorphism of inheritance without the
fragile base class problem.

---

**Q6 (Algebraic data types): Explain algebraic data types in Java.**

A: An ADT combines two primitives:
- **Sum type** ("or"): A value is ONE of several options (Circle OR Square OR Triangle)
- **Product type** ("and"): A value has ALL of its parts (Circle has a radius AND nothing else)

```java
// Sum type: sealed interface (A is B or C or D)
sealed interface Result<T> permits Success, Failure {}

// Product types: records (the concrete variants)
record Success<T>(T value) implements Result<T> {}
record Failure<T>(String error, Exception cause) implements Result<T> {}

// Pattern matching handles the sum type exhaustively:
<T, R> R fold(Result<T> result,
              Function<T, R> onSuccess,
              Function<String, R> onFailure) {
    return switch (result) {
        case Success<T> s -> onSuccess.apply(s.value());
        case Failure<T> f -> onFailure.apply(f.error());
    };
}

// Usage: type-safe error handling without exceptions:
Result<User> findUser(Long id) {
    try {
        return new Success<>(repo.findById(id));
    } catch (EntityNotFoundException e) {
        return new Failure<>("User not found: " + id, e);
    }
}

String display = fold(findUser(42L),
    user -> "Found: " + user.getName(),
    error -> "Error: " + error);
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* ADTs with sealed types and pattern
matching represent a fundamental shift in how Java handles heterogeneous
data. The `Result<T>` type shown is equivalent to Kotlin's `Result<T>`,
Rust's `Result<T, E>`, or Scala's `Either[A, B]`. It makes the "this can
fail" case explicit in the return type, forcing callers to handle both
success and failure. No more "returns null on failure" or "throws checked
exception" (which can be ignored). The compile-time exhaustiveness check
means: adding a third case (`Partial<T>`) forces all callers to handle it.

---

**Q7 (Records vs Lombok): When do you use records vs Lombok?**

A:

| Aspect | Records (Java 16+) | Lombok `@Value` |
|---|---|---|
| Immutability | Built-in (components final) | Via `@Value` |
| Extends classes | No (extends Record) | Yes |
| JVM concept | Yes (RECORD attribute) | No (compile-time codegen) |
| Deconstruction patterns | Yes (Java 21) | No |
| Sealed type compatibility | Yes | Limited |
| Build tool dependency | None | Lombok jar required |
| IDE support | Native | Plugin needed |
| Customization | Compact constructor | Lombok annotations |

**Decision:**
- New code, Java 16+: prefer records for immutable data carriers
- Need to extend a class: Lombok `@Data` or manual
- JPA entities: Lombok `@Data` or manual (not records)
- Complex validation/customization: compact constructor or Lombok `@Builder`

*What separates good from great:* Records and Lombok serve different needs.
Records are a language feature with JVM support - reflection, pattern matching,
and future features will first-class support records. Lombok is annotation
processing - works at compile time but tools need to understand it. For
new codebases on Java 17+: use records for data classes, eliminate Lombok
for this use case. For existing codebases with heavy Lombok usage: migrate
incrementally (Lombok `@Value` -> records is usually mechanical). Keep
Lombok `@Builder` for complex construction scenarios not covered by records.

---

**Q8 (Deconstruction patterns): How does record deconstruction work in
pattern matching?**

A: Record deconstruction (Java 21) allows binding record components
directly in case labels:

```java
record Point(int x, int y) {}
record Line(Point start, Point end) {}

void process(Object obj) {
    switch (obj) {
        // Deconstruct record:
        case Point(int x, int y) ->
            System.out.printf("Point at (%d, %d)%n", x, y);

        // Nested deconstruction:
        case Line(Point(int x1, int y1), Point(int x2, int y2)) ->
            System.out.printf("Line from (%d,%d) to (%d,%d)%n",
                x1, y1, x2, y2);

        // Guard (when clause):
        case Point(int x, int y) when x == y ->
            System.out.println("On diagonal: " + x);

        default -> System.out.println("Unknown: " + obj);
    }
}
// Note: when two Point cases: the specific (diagonal) guard must come first!

// For List (Java 21 preview):
// case List<Integer> list when list.isEmpty() -> ...
// Matching on list contents requires external iteration (no built-in list deconstruction yet)
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Deconstruction patterns eliminate the
common pattern of matching a record type then immediately extracting
components: `case Point p -> { int x = p.x(); int y = p.y(); }`.
With deconstruction: `case Point(int x, int y)` binds x and y directly.
Nested deconstruction for data trees is particularly powerful - compare
with the Expr evaluator example. The `when` guard (`when x == y`) adds
conditions beyond type matching. This is Java's approach to what Scala
and Haskell call "pattern matching" - the fundamental tool for structural
decomposition of algebraic data.

---

**Q9 (Switch expressions): How do switch expressions differ from
switch statements?**

A:

| Aspect | Switch Statement | Switch Expression |
|---|---|---|
| Returns value | No | Yes (entire switch yields a value) |
| Fall-through | Yes (needs `break`) | No (each branch is independent) |
| Exhaustiveness | Not required | Required (compiler error if incomplete) |
| Arrow form | Traditional with break | `case X -> expr` (no fall-through) |
| Colon form | `case X:` with break | `case X: yield value;` with `yield` |

```java
int numLetters = switch (day) { // switch EXPRESSION
    case MONDAY, FRIDAY, SUNDAY -> 6;
    case TUESDAY                -> 7;
    case THURSDAY, SATURDAY     -> 8;
    case WEDNESDAY              -> 9;
    // ALL DayOfWeek values covered -> no default needed!
};

// With blocks (arrow form):
String category = switch (score) {
    case int s when s >= 90 -> "A";
    case int s when s >= 80 -> "B";
    case int s when s >= 70 -> "C";
    default -> "F";
};

// With yield (colon form for multi-statement blocks):
String result = switch (status) {
    case ACTIVE: {
        auditLog("Access");
        yield "active";      // use yield, not return!
    }
    case INACTIVE -> "inactive"; // arrow form: no yield needed
    default -> "unknown";
};
```

> **Code walkthrough:** This example demonstrates the core pattern in action. The key mechanism shows how the concept works in practice. Study the structure to understand the essential behavior and common usage.

*What separates good from great:* Switch expressions (Java 14, standard)
are always preferred over switch statements for assignments - the compiler
enforces exhaustiveness and eliminates fall-through bugs (accidental omission
of `break` between cases is one of Java's most common bugs). The arrow form
(`->`) is cleaner for simple cases. The colon form (`case X: ... yield v;`)
is needed when the case requires multiple statements but should produce
a value. `yield` in a switch expression is analogous to `return` but
specific to switch blocks.

---

### ⚖️ Comparison Table

| Feature | Records | Sealed Classes | Pattern Matching |
|---|---|---|---|
| Java version | 16 | 17 | 16 (instanceof), 21 (switch) |
| Purpose | Immutable data carrier | Closed type hierarchy | Exhaustive type dispatch |
| Boilerplate reduction | High | Medium | Medium |
| Compiler enforcement | Component equality | Exhaustive permits | Exhaustive cases |
| Serialization | JSON: auto; Java: manual | N/A | N/A |
| JPA compatibility | No (no-arg ctor) | Yes | N/A |

---

### 🏛️ System Design

*(Omit: ★★☆ level - system design not required)*

---

### 📊 Diagram

*(Omit: non-visual concept)*

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



