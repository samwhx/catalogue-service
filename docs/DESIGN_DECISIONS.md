# Design Decisions & Trade-offs

## What We Built

A hierarchical catalogue API with 3-4 levels: **Catalog → Section (self-referential) → Item → Option**

**Key choices:**

- Self-referential sections only (not items)
- Simple integer `display_order` (no positioning gem)
- `active` boolean flag (not soft deletes)
- `price` as DECIMAL + `currency` string
- Read-only API (GET endpoints only)
- Caching with version-based keys
- Basic error handling (production patterns documented)

---

## Quick Reference: All Decisions

| Decision           | What We Chose           | What We Considered         | Why                                                   |
| ------------------ | ----------------------- | -------------------------- | ----------------------------------------------------- |
| Hierarchy          | 3-4 levels              | Full Atlas complexity      | Simpler, meets requirements                           |
| Self-Referential   | Sections only           | Sections + Items           | Demonstrates concept without over-complication        |
| Depth Limit        | Environment variable    | Hard-coded / DB constraint | Flexible, configurable per environment                |
| Active/Delete      | Boolean flag            | Soft delete timestamp      | Simpler, sufficient for read-only API                 |
| Price              | DECIMAL                 | Integer cents / Float      | Exact precision, supports any decimal places          |
| Identifiers        | ID + identifier         | ID only                    | Better URLs, more flexible                            |
| Options            | Simple one-level        | Modifier groups            | Sufficient, extensible                                |
| Caching            | Implemented             | No cache / Always cache    | Demonstrates capability, read-heavy APIs benefit      |
| Loading            | Single call             | Chunked loading            | Menus small enough, better UX                         |
| Create/Update      | Skip                    | Full CRUD                  | Assignment focuses on retrieval                       |
| Delete             | Skip, use active flag   | Hard/soft delete           | Active flag handles via filtering                     |
| Display Order      | Simple integer          | Positioning gem            | Read-only API doesn't need reordering                 |
| Authentication     | None (open API)         | JWT / API Keys / OAuth     | Assignment constraint, documented production approach |
| Resilience         | Basic error handling    | Circuit breakers / Retries | Appropriate scope, documented production patterns     |
| Offline Mode       | Frontend responsibility | Backend cache headers      | Standard pattern, backend supports via HTTP           |
| Forward Compatible | Yes                     | Breaking changes           | Standard Rails patterns, complete schema              |

---

## Major Design Decisions

### Self-Referential Relationships

**Chose:** Self-referential for **sections only**

**Why:** Simpler, still demonstrates hierarchical concepts. Items are typically flat lists within sections.

**Trade-off:** Less flexible if items need sub-items later (unlikely for menu/catalogue use cases).

### Depth Limiting

**Chose:** `MAX_SECTION_DEPTH` environment variable (default: 5)

**Why:** Configurable per environment, runtime adjustment, clear safety mechanism.

**Trade-off:** Requires environment configuration, but provides flexibility.

### Active Flag vs Soft Deletes

**Chose:** `active` boolean flag

**Why:** Simpler queries, better performance, sufficient for read-only API.

**Trade-off:** No audit trail (can add `archived_at` later if needed).

### Price Representation

**Chose:** `price` as DECIMAL + `currency` string

**Why:** Exact precision, supports any decimal places (USD=2, BHD=3, JPY=0), no floating-point errors.

**Considered:** Integer cents (requires knowing smallest unit per currency), Float (precision errors).

**Trade-off:** Slightly larger storage than integer, but flexibility is worth it.

### Caching Strategy

**Chose:** Implement caching with version-based keys (`catalog:{id}:{updated_at}`)

**Why:** Read-heavy APIs (1000:1 read-to-write ratio) benefit significantly. Version-based keys provide automatic invalidation.

**Implementation:** Rails memory store (can upgrade to Redis). TTL fallback: 24 hours.

**Key insight:** When any related entity updates, timestamp changes and cache key becomes invalid automatically.

### Loading Strategy

**Chose:** Single call (complete structure)

**Why:** Typical menus are 20-200 items (5-20 KB compressed, <100ms download). Better UX, simpler API, enables offline caching.

**Trade-off:** Chunked loading would give smaller payloads but breaks hierarchical context.

### Forward Compatibility

**Answer:** **Yes, 100% forward-compatible**

**Why:** Standard Rails associations, complete schema, write-compatible JSON structure. Can add create/update, authentication, soft deletes, positioning gem without breaking changes.

---

## Failure Modes & Mitigations

### Circular References

**Problem:** Self-referential sections could create cycles (A → B → C → A)

**Mitigation:** Validation using Set to track all ancestor IDs (detects cycles at any depth), depth limit prevents excessive nesting.

### Deep Nesting Performance

**Problem:** Very deep hierarchies cause slow queries and large JSON responses

**Mitigation:** Environment variable depth limit, eager loading prevents N+1 queries, caching provides speedup, gzip compression.

### Missing Data

**Problem:** Requesting non-existent catalog or inactive items

**Mitigation:** 404 response, filter inactive by default, clear error messages.

### Stack Overflow in Serialization

**Problem:** Recursive serialization could overflow stack

**Mitigation:** Depth tracking, respect `MAX_SECTION_DEPTH`, iterative tree building.

---

## Key Insights

1. **Simplicity > Complexity:** Meeting requirements with simpler solutions shows better judgment
2. **Version-Based Cache Keys:** Automatic invalidation via `catalog:{id}:{updated_at}` is elegant
3. **Eager Loading Is Critical:** 40-310x fewer queries (4-5 vs 161+)
4. **Hash Maps Make Tree Traversal Fast:** O(1) lookups vs O(n) scans
5. **Forward Compatibility Matters:** Design for future enhancements without breaking changes
6. **Production Thinking:** Consider caching, monitoring, resilience even in demos

---

---

## Additional Resources

- **System Architecture:** [`ARCHITECTURE.md`](ARCHITECTURE.md)
- **Performance Analysis:** [`COMPLEXITY_ANALYSIS.md`](COMPLEXITY_ANALYSIS.md)
