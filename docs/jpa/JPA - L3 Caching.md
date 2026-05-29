---
layout: default
title: "JPA - L3 Caching"
parent: "JPA"
grand_parent: "SK Interview"
nav_order: 8
permalink: /jpa/l3-caching/
---

# JPA - L3 Caching

## First-Level Cache: Persistence Context as Cache

### 🎯 Model Answer

**30 seconds:**
> First-level (L1) cache: the persistence context (session/EntityManager). Within a single
> transaction, the same entity loaded twice returns the same Java object from memory (no second
> SQL). Scope: transaction. Cleared on transaction end. Cannot be disabled. Benefit: no duplicate
> selects within a transaction. Risk: stale data if bulk updates bypass it.

**3 minutes (Senior):**
> L1 cache details:
>
> 1. **Scope**: the current `EntityManager` (one per transaction in typical Spring usage).
>    After transaction commit: persistence context is closed, all entities are detached, L1
>    cache is cleared.
>
> 2. **Guarantee**: within one transaction, `em.find(Product.class, 1L)` called twice: second
>    call returns the SAME Java object (identity guarantee). No SELECT for the second call.
>
> 3. **Cannot be disabled**: unlike L2 cache. Calling `em.clear()` manually: flushes the
>    context and clears the cache (all entities become detached). Useful in batch operations
>    to free memory.
>
> 4. **Stale read issue**: `@Modifying @Query("UPDATE ...")` bypasses the persistence context.
>    An entity already loaded in the current transaction is NOT refreshed by the bulk update.
>    Call `em.clear()` or use `@Modifying(clearAutomatically=true)` to clear stale L1 cache.
>
> 5. **L1 vs L2**: L1: per transaction, always on. L2: shared across transactions and sessions,
>    optional, must be explicitly configured.

**Blank Mind Recovery:**

**(1) Restate:** "L1 cache = persistence context. Same transaction: same entity by ID = same Java object, no SQL. Scope: transaction. Not shared. Cleared on commit. Bypass: em.clear(). Stale after bulk update: use clearAutomatically=true."

**(2) First principles:** "Within a unit of work: you should see a consistent view. L1 cache ensures: if you load order 42 twice in the same transaction, you see the same state both times. No intermediate state from other transactions (isolation)."

**(3) Bridge:** "L1 cache is like your clipboard. Within a session: you paste the same copied text multiple times without re-copying it (no network call). When you close the session: clipboard cleared."

---

### 📘 Concept Explanation

**L1 cache identity guarantee and stale data scenarios:**
```
IDENTITY GUARANTEE DEMONSTRATION:

  @Transactional
  public void identityDemo() {
      Product p1 = productRepository.findById(42L).orElseThrow();
      // SQL: SELECT * FROM products WHERE id = 42
      
      Product p2 = productRepository.findById(42L).orElseThrow();
      // NO SQL: returned from L1 cache.
      
      System.out.println(p1 == p2);  // true: same Java object
      
      // Modify p1:
      p1.setName("Updated");
      System.out.println(p2.getName());  // "Updated": p1 and p2 are THE SAME OBJECT
  }
  // Transaction ends: L1 cache cleared. p1 and p2 are now detached.

STALE L1 CACHE AFTER BULK UPDATE:

  @Transactional
  public void bulkUpdateWithStaleCache() {
      // Load Product(id=42, price=9.99) into L1 cache:
      Product p = productRepository.findById(42L).orElseThrow();
      System.out.println(p.getPrice());  // 9.99
      
      // Bulk update bypasses persistence context:
      productRepository.increasePriceByCategory("ELECTRONICS");
      // SQL: UPDATE products SET price=price*1.1 WHERE category='ELECTRONICS'
      // Product 42 is in ELECTRONICS. DB price is now 10.99.
      // But L1 cache: still has Product(id=42, price=9.99).
      
      // Re-read from repository:
      Product pAgain = productRepository.findById(42L).orElseThrow();
      // L1 cache hit: returns the SAME cached object. price=9.99 (STALE).
      System.out.println(pAgain.getPrice());  // 9.99. WRONG.
  }
  
  // Fix option 1: clearAutomatically=true on @Modifying:
  @Modifying(clearAutomatically = true)
  @Query("UPDATE Product p SET p.price = p.price * 1.1 WHERE ...")
  int increasePriceByCategory(String category);
  // Clears L1 cache after bulk update.
  // Next findById: SELECT (no L1 cache entry). Returns fresh data.
  
  // Fix option 2: manual em.clear():
  @Transactional
  public void safeUpdate() {
      productRepository.increasePriceByCategory("ELECTRONICS");
      em.clear();  // clear L1 cache. All entities detached.
      // Subsequent loads: fresh from DB.
  }
  
  // Fix option 3: em.refresh(entity):
  @Transactional
  public void refreshSpecific() {
      Product p = productRepository.findById(42L).orElseThrow();
      productRepository.increasePriceByCategory("ELECTRONICS");
      em.refresh(p);  // re-execute SELECT for this entity. Updates L1 cache.
      System.out.println(p.getPrice());  // 10.99. Correct.
  }

L1 CACHE IN BATCH OPERATIONS (memory management):

  @Transactional
  public void batchProcess(List<Long> ids) {
      int processed = 0;
      for (Long id : ids) {
          Product p = productRepository.findById(id).orElseThrow();
          p.setStatus(ProductStatus.PROCESSED);
          processed++;
          
          if (processed % 500 == 0) {
              // L1 cache now holds 500 Product entities.
              em.flush();   // send UPDATEs to DB
              em.clear();   // clear L1 cache: free memory
              // Next 500 start fresh.
          }
      }
      em.flush();  // final flush
  }
```

---

### 💻 Code Example

> **Code walkthrough:** The refresh pattern is the surgical fix when you need fresh data for a
> specific entity after a bulk operation, while `em.clear()` is the sledgehammer that clears
> everything (use in batch processing).

```java
// DEMONSTRATING L1 CACHE BEHAVIOR AND WORKING AROUND STALE DATA:

@Service
public class InventoryService {
    
    @PersistenceContext EntityManager em;
    private final InventoryRepository inventoryRepo;
    
    // L1 cache working correctly (no issues):
    @Transactional
    public BigDecimal calculateTotalValue() {
        // First load: SQL SELECT.
        List<Product> products = productRepo.findAll();
        
        BigDecimal total = products.stream()
            .map(p -> p.getPrice().multiply(BigDecimal.valueOf(p.getQuantity())))
            .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        // Second access to same products:
        for (Product p : products) {
            // L1 cache: no SQL. Same objects.
            log.info("Product {} price: {}", p.getId(), p.getPrice());
        }
        return total;
    }
    
    // Handling stale L1 after bulk adjustment:
    @Transactional
    public void adjustAndReportPrices(String category) {
        // Get products BEFORE bulk update:
        List<Product> before = productRepo.findByCategory(category);
        BigDecimal avgBefore = average(before);
        
        // Bulk update (bypasses L1 cache):
        inventoryRepo.increasePriceByCategory(category);
        // Note: @Modifying(clearAutomatically=true) automatically clears L1 cache.
        
        // Re-query: L1 cache was cleared, fresh SELECT:
        List<Product> after = productRepo.findByCategory(category);
        BigDecimal avgAfter = average(after);
        
        log.info("Price adjustment: {}", avgAfter.subtract(avgBefore));
    }
}
```

> **Code walkthrough:** `calculateTotalValue` shows L1 cache benefiting repeated reads within the
> same transaction: the `for` loop accesses the same product objects loaded earlier without any
> additional SQL. `adjustAndReportPrices` shows the correct pattern after a bulk update: because
> `increasePriceByCategory` uses `@Modifying(clearAutomatically=true)`, the L1 cache is cleared
> after the bulk UPDATE, and the subsequent `findByCategory` executes a fresh SELECT from the DB.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> L1 cache: persistence context. Same entity twice in a transaction: one SELECT, same object.
> Cleared after transaction. Cannot disable. After bulk UPDATE: use `@Modifying(clearAutomatically=true)`
> or `em.clear()` to prevent stale reads.

---

### ⚠️ Common Misconceptions

**Misconception: "L1 cache is shared across requests."**
L1 cache lives in the `EntityManager`/session, which is transaction-scoped in Spring applications
(default: one per `@Transactional` method). A second HTTP request: different thread, different
transaction, different `EntityManager`, different L1 cache. The two requests do NOT share L1 cache.
The shared cache in JPA is the second-level (L2) cache. Developers sometimes assume that loading
an entity in one transaction "warms up the cache" for another request. It does not. L2 cache (if
configured) provides cross-transaction caching. L1 cache is strictly per-transaction.

---

### 🚨 Failure Modes and Diagnosis

**Failure: findById returns stale entity after @Modifying bulk update.**
```
Symptom: service updates all product prices via @Modifying query,
  then reads a specific product. Price shows old value in the return object.

Diagnosis:
  spring.jpa.show-sql=true.
  Check: does findById after the bulk update execute a SELECT?
  If NO SELECT: L1 cache returning stale entity.
  If YES SELECT: L2 cache or other issue.

Fix:
  Add clearAutomatically=true to @Modifying annotation:
  @Modifying(clearAutomatically = true)
  @Query("UPDATE Product p SET p.price = p.price * :factor")
  int updateAllPrices(@Param("factor") BigDecimal factor);
  
  Or: em.refresh(specificEntity) after the bulk update.
  Or: em.clear() to clear all cached entities.
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| L1 cache scope and lifetime | 1 minute |
| Identity guarantee | 1 minute |
| Stale data after bulk update | 2 minutes |
| clearAutomatically purpose | 1 minute |
| L1 vs L2 differences | 2 minutes |
| em.clear() in batch processing | 1 minute |
| em.refresh() use case | 1 minute |

---

**Q1 (stale): What happens to the L1 cache when you execute a `@Modifying` JPQL update, and how do you handle it?**

A: `@Modifying` JPQL update: executes `UPDATE SQL` directly in the DB. The persistence context
(L1 cache) is NOT updated. Entities already loaded in the current transaction retain their old
field values. Subsequent `findById` for a loaded entity: L1 cache hit, returns the stale object
(no new SELECT). Three fix strategies: (1) `@Modifying(clearAutomatically=true)`: Hibernate
automatically calls `em.clear()` after the query. All L1 cache entries evicted. Next entity access:
fresh SELECT from DB. Side effect: all currently managed entities become detached (references held
by the caller now point to detached objects). (2) `em.refresh(entity)`: re-executes SELECT for one
specific entity. Updates L1 cache for that entity only. Other entities unaffected. (3) `em.clear()`:
same as clearAutomatically=true but called manually. Use when you know the scope of stale entities.

*What separates good from great:* The `clearAutomatically=true` side effect: all entities detached.
If a method loads entity X, calls a bulk update with clearAutomatically=true, then continues working
with entity X, the reference to X now points to a detached object. Modifications to X after this
point: NOT tracked. A subtle, hard-to-find bug. Pattern to avoid it: (1) don't mix bulk updates
and entity manipulation in the same transaction, OR (2) use `em.refresh(x)` instead of
clearAutomatically (refreshes X only, keeps X managed), OR (3) re-load X after the clear:
`x = productRepository.findById(x.getId()).orElseThrow()`.

---

---

## Second-Level Cache: EhCache, Caffeine, and Cache Region Strategy

### 🎯 Model Answer

**30 seconds:**
> Second-level (L2) cache: shared across all transactions and sessions in the same JVM. Stores
> entity state by ID. Cache hit: no DB SELECT, data from memory. Must opt-in per entity with
> `@Cache`. Popular providers: EhCache, Caffeine (via JCache), Redis. Use for: rarely-changed
> reference data (countries, categories). Avoid for: frequently-updated data (current balance).

**3 minutes (Senior):**
> L2 cache mechanics:
>
> 1. **Store format**: stores entity state as a key-value map. Key: entity class + ID. Value:
>    serialized field values (not a live Java entity). On cache hit: reconstructs the entity
>    from the cached values (no SQL).
>
> 2. **Cache regions**: each entity type has its own region (named cache). TTL, eviction policy,
>    max size configured per region. Collection caches (for `@OneToMany`): separate region from
>    the entity region.
>
> 3. **Cache modes**: `READ_ONLY` (no updates possible, best performance), `READ_WRITE` (updates
>    propagate to cache), `NONSTRICT_READ_WRITE` (updates may be slightly stale, higher performance),
>    `TRANSACTIONAL` (JTA required, full transactional cache).
>
> 4. **Invalidation on update**: when an entity is updated via `save()`: Hibernate invalidates
>    (removes) the L2 cache entry for that entity. Next access: SELECT from DB, re-cache.
>    Bulk `@Modifying` UPDATE: does NOT invalidate L2 cache (bypasses Hibernate's lifecycle).
>    `@Modifying(flushAutomatically=true, clearAutomatically=true)` or programmatic cache eviction
>    needed.

**Blank Mind Recovery:**

**(1) Restate:** "L2 cache: shared across sessions. @Cache on entity. Hit: no SQL. Providers: EhCache, Caffeine. Regions: per entity type. READ_ONLY: best for reference data. UPDATE via save(): invalidates cache. Bulk @Modifying: does NOT invalidate."

**(2) First principles:** "Database reads are slower than memory reads (10ms vs microseconds). Cache frequently-read, rarely-changed data in memory. Invalidate on write. Simple correctness: load on miss, evict on update."

**(3) Bridge:** "L2 cache is the office reference shelf. Country list: same every time, pulled from the shelf (memory). Employee salary: changes often, checked with HR (DB) each time."

---

### 📘 Concept Explanation

**L2 cache configuration and cache regions:**
```
ENABLING L2 CACHE (Spring Boot + Caffeine via JCache):

  # application.properties:
  spring.jpa.properties.hibernate.cache.use_second_level_cache=true
  spring.jpa.properties.hibernate.cache.region.factory_class=\
    org.hibernate.cache.jcache.JCacheRegionFactory
  spring.cache.jcache.provider=\
    com.github.benmanes.caffeine.jcache.spi.CaffeineCachingProvider
  spring.jpa.properties.hibernate.cache.use_query_cache=true
  
  # pom.xml:
  # hibernate-jcache + caffeine-jcache

ENTITY CACHE ANNOTATION:

  @Entity
  @Cache(usage = CacheConcurrencyStrategy.READ_WRITE)
  public class Country {
      @Id Long id;
      String code;
      String name;
      // Changed rarely. Good L2 cache candidate.
  }
  
  @Entity
  @Cache(usage = CacheConcurrencyStrategy.READ_ONLY)
  public class Currency {
      // READ_ONLY: allows Hibernate to optimize (no lock management).
      // Cannot modify cached entities. Suitable for truly immutable data.
  }
  
  // Collection cache (separate region from entity):
  @Entity
  @Cache(usage = CacheConcurrencyStrategy.READ_WRITE)
  public class ProductCategory {
      @Id Long id;
      String name;
      
      @OneToMany(mappedBy = "category")
      @Cache(usage = CacheConcurrencyStrategy.READ_WRITE)
      // Caches the list of product IDs in this category.
      // Separate region: ProductCategory.products
      private List<Product> products;
  }

CACHE REGIONS AND CONFIGURATION:

  // Caffeine cache config per region:
  @Bean
  public CacheManager cacheManager() {
      CaffeineCacheManager cacheManager = new CaffeineCacheManager();
      
      // Per-region config:
      cacheManager.registerCustomCache("Country",
          Caffeine.newBuilder()
              .expireAfterWrite(1, TimeUnit.HOURS)
              .maximumSize(500)
              .build());
      
      cacheManager.registerCustomCache("ProductCategory",
          Caffeine.newBuilder()
              .expireAfterWrite(10, TimeUnit.MINUTES)
              .maximumSize(1000)
              .build());
      
      // Default for unmapped regions:
      cacheManager.setCaffeine(
          Caffeine.newBuilder()
              .expireAfterWrite(5, TimeUnit.MINUTES)
              .maximumSize(10000));
      
      return cacheManager;
  }

L2 CACHE INVALIDATION:

  // Via save(): automatic invalidation.
  @Transactional
  public Country updateCountryName(Long id, String newName) {
      Country c = countryRepository.findById(id).orElseThrow();
      c.setName(newName);
      return countryRepository.save(c);
      // Hibernate: on commit, removes cache entry for Country(id).
      // Next findById(id): L2 miss -> SELECT from DB -> re-cache.
  }
  
  // Via @Modifying: L2 NOT automatically invalidated.
  @Modifying
  @Query("UPDATE Country c SET c.name = :name WHERE c.id = :id")
  void updateNameDirect(@Param("id") Long id, @Param("name") String name);
  // After this: L2 cache for Country(id) still has OLD name.
  // Next findById: L2 HIT -> returns stale name.
  
  // Fix: programmatic eviction:
  @Transactional
  public void updateAndEvict(Long id, String name) {
      countryRepository.updateNameDirect(id, name);
      em.getEntityManagerFactory()
          .getCache()           // JPA Cache interface
          .evict(Country.class, id);  // remove this entity from L2 cache
  }
```

---

### 💻 Code Example

> **Code walkthrough:** The query cache is a common source of stale data bugs. The query result
> cache stores the IDs, not the entities. Entity data comes from L1/L2 cache or DB.

```java
// WRONG: caching a frequently-updated entity:
@Entity
@Cache(usage = CacheConcurrencyStrategy.READ_WRITE)
public class UserBalance {
    @Id Long userId;
    BigDecimal balance;
    // BAD: balance changes with every transaction.
    // Cache: constantly invalidated and re-loaded.
    // Net effect: extra cache management overhead with no benefit.
    // READ_WRITE adds lock contention to maintain cache consistency.
}

// RIGHT: cache only reference/configuration data:
@Entity
@Cache(usage = CacheConcurrencyStrategy.READ_ONLY)
public class Country {
    @Id Long id;
    String code;
    String name;
    // GOOD: changes at most once per year (when a country is renamed).
    // READ_ONLY: no lock overhead. Perfect for reference data.
}

// QUERY CACHE for repeated queries:
@Repository
public interface CountryRepository extends JpaRepository<Country, Long> {
    
    @QueryHints(@QueryHint(name = "org.hibernate.cacheable", value = "true"))
    @Query("SELECT c FROM Country c ORDER BY c.name")
    List<Country> findAllSorted();
    // Query cache: stores the result IDs, not the full entities.
    // Cache key: query string + parameters.
    // Cache value: list of IDs [1, 2, 3, ...].
    // Hit: Hibernate looks up each entity from L2 cache or DB.
    // For this to help: entities themselves must also be in L2 cache.
}
```

> **Code walkthrough:** `UserBalance` is a bad L2 cache candidate because it changes on every
> transaction - the cache is constantly invalidated, adding overhead with no benefit. `Country`
> is an ideal candidate: rarely changes, frequently read (every address form, shipping calculation,
> etc.). The query cache on `findAllSorted` caches the list of country IDs. On a cache hit:
> Hibernate retrieves the individual entities from the entity L2 cache (or DB on L2 miss). Both
> the query cache and the entity cache should be enabled together.

---

### 🎓 Answers by Seniority

**Junior / Mid (0-5 years):**
> L2 cache: shared cache for entities and query results. Enable: add `@Cache` to entity class.
> Use for reference data (countries, categories, config). Bad for: entities that change frequently.
> Configure TTL and max size per entity type. UPDATE via `save()`: auto-invalidates. Bulk updates:
> require manual eviction.

---

**Senior / Staff (5+ years):**
> L2 cache invalidation in a cluster: each node has its own L2 cache. Update on node A: invalidates
> node A's cache. Node B: still serves stale data until its TTL expires. For distributed systems:
> use Hazelcast or Infinispan as a distributed L2 cache provider (invalidation broadcast to all nodes).
> Or: use short TTLs (accept eventual consistency). Alternatively: move L2 cache to Redis (shared
> across nodes, centralized invalidation). Hazelcast + Hibernate: full distributed L2 cache with
> cross-node invalidation.

---

### ⚠️ Common Misconceptions

**Misconception: "`@Cache` on an entity caches the collection too."**
`@Cache` on the entity class caches the entity row. Collections mapped with `@OneToMany` or
`@ManyToMany` have their own cache region. To cache a collection: add a SECOND `@Cache` annotation
on the collection field: `@OneToMany ... @Cache(usage = CacheConcurrencyStrategy.READ_WRITE) private
List<...>`. Without the second `@Cache`: the collection is fetched from DB on every access (even
if the parent entity is in L2 cache). Result: the "cached" entity still causes a SQL query for
each collection access. This is a common performance surprise after adding L2 cache - the expected
reduction in SQL doesn't materialize for relationships.

---

### 🚨 Failure Modes and Diagnosis

**Failure: L2 cache serving stale data after bulk update.**
```
Symptom: country names updated via batch script (direct SQL).
  Application continues serving old country names for hours.
  Restarting the application fixes it (clears the L2 cache).

Root cause: direct SQL or @Modifying update bypasses Hibernate lifecycle.
  L2 cache entries not invalidated. TTL is 1 hour.

Diagnosis:
  Enable hibernate cache statistics:
    spring.jpa.properties.hibernate.generate_statistics=true
  Monitor: L2 hit/miss ratio, eviction count.
  Check: is the entity cached? Verify with em.getEntityManagerFactory().getCache().contains(Country.class, id).

Fix:
  After bulk update: evict affected entries:
    Cache jpaCache = em.getEntityManagerFactory().getCache();
    jpaCache.evict(Country.class);  // evict ALL Country entries
    // Or specific ID: jpaCache.evict(Country.class, id);
  
  Add programmatic eviction to the batch update service.
  Or: set short TTL on Country cache region (accept small staleness window).
  Or: @Modifying(flushAutomatically=true, clearAutomatically=true) is
    not sufficient for L2 cache. Must evict explicitly.
```

---

### 🎯 Interview Deep-Dive

| Question Category | Time to Answer |
|---|---|
| L1 vs L2 differences | 2 minutes |
| L2 cache configuration | 2 minutes |
| Cache concurrency strategies | 2 minutes |
| Bulk update invalidation | 2 minutes |
| Query cache | 1 minute |
| Distributed L2 cache | 1 minute |
| When NOT to use L2 cache | 1 minute |

---

**Q1 (design): How do you decide which entities to put in the L2 cache?**

A: L2 cache is beneficial for entities with these characteristics: (1) read-heavy: loaded frequently
across many transactions (country list, currency list, product categories). (2) Rarely written:
write traffic is low relative to read traffic. High write rate = constant cache invalidation =
overhead with no benefit. (3) Acceptable staleness: slight staleness between write and cache eviction
is acceptable (for `READ_WRITE` strategy, Hibernate manages this, but for distributed caches: brief
staleness window exists). (4) Moderate result set: large entities (with many fields or LOBs) in
L2 cache: high memory usage, may evict more useful entries. Balance: cache the summary or use a
DTO cache instead. Anti-candidates: user sessions, account balances, order statuses (change on every
operation), audit logs (write-once, read-rarely).

*What separates good from great:* The "query cache trap" - enabling query cache without entity L2
cache. Query cache: stores list of IDs. On query cache hit: Hibernate fetches each ID individually
from... the DB (if not also in entity L2 cache). For a query returning 100 countries: 1 query cache
hit + 100 individual SELECT by ID (SELECT N+1, caused by the cache). Correct setup: both query
cache AND entity L2 cache enabled. Then: query cache hit -> entity L2 cache hit for each ID -> 0
DB queries. Wrong setup (query cache only): potentially WORSE than no cache at all. Diagnosis:
`spring.jpa.properties.hibernate.generate_statistics=true` and watch the query execution count.
If it rises after adding query cache: you have this bug.

