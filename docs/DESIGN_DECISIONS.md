# Design Decisions & Trade-offs

## What We Built

A hierarchical catalogue API with 3-4 levels: **Catalog → Section (self-referential) → Item → Option**

**Key choices:**

**Platform & Infrastructure:**

- Rails API-only mode (no views) since use case is API server only
- PostgreSQL for database efficiency and future-proofing
- Fly.io hosting with Singapore region for improved performance

**Data Model:**

- Self-referential sections only (not items)
- Identifier-based URLs (not ID-based) for better security and to decrease likelihood of predicting URLs
- `active` boolean flag (not soft deletes)
- `price` as DECIMAL + `currency` string
- Simple integer `display_order` (no positioning gem)

**API Design:**

- Read-only API (GET endpoints only)

**Implementation:**

- Thin controllers with service layer architecture
- Common methods offloaded to ApplicationController for reusability
- Complex catalog building logic in dedicated CatalogTreeBuilder service
- JSON API Serializer for performance and easier-to-read syntax
- Extensive query optimizations (eager loading, strategic indexing)

**Performance:**

- Automatic caching and cache busting with Redis

**Operational:**

- Basic error handling (production patterns documented, Sentry/Airbrake integration planned)

---

## Quick Reference: All Decisions

| Decision           | What We Chose              | What We Considered         | Why                                                                 |
| ------------------ | -------------------------- | -------------------------- | ------------------------------------------------------------------- |
| Rails Mode         | API-only                   | Full Rails with views      | Use case is API server only, no views needed                        |
| Database           | PostgreSQL                 | SQLite / MySQL             | Better efficiency, future-proofing, advanced features               |
| Hosting            | Fly.io (SG region)         | Heroku / AWS               | SG server improves loading speed for SG customers                   |
| Hierarchy          | 3-4 levels                 | Full Atlas complexity      | Simpler, meets requirements                                         |
| Self-Referential   | Sections only              | Sections + Items           | Demonstrates concept without over-complication                      |
| Identifiers        | Identifier only            | ID only                    | Better URLs, more flexible, decreases likelihood of predicting URLs |
| Active/Delete      | Boolean flag               | Soft delete timestamp      | Simpler, sufficient for read-only API                               |
| Price              | DECIMAL                    | Integer cents / Float      | Exact precision, supports any decimal places                        |
| Options            | Simple one-level           | Modifier groups            | Sufficient, extensible                                              |
| Display Order      | Simple integer             | Positioning gem            | Read-only API doesn't need reordering                               |
| Depth Limit        | Environment variable       | Hard-coded / DB constraint | Flexible, configurable per environment                              |
| Loading            | Single call                | Chunked loading            | Menus small enough, better UX                                       |
| Create/Update      | Skip                       | Full CRUD                  | Assignment focuses on retrieval                                     |
| Delete             | Skip, use active flag      | Hard/soft delete           | Active flag handles via filtering                                   |
| Authentication     | None (open API)            | JWT / API Keys / OAuth     | Assignment constraint, documented production approach               |
| Invalid Routes     | JSON 404 response          | Default HTML 404           | API consistency, proper error format                                |
| Controller Design  | Thin controllers           | Fat controllers            | Better separation of concerns, testability                          |
| Service Layer      | CatalogTreeBuilder service | Inline logic               | Complex logic isolated, reusable, testable                          |
| Serialization      | JSON API Serializer        | Jbuilder / AMS             | Faster performance, easier to read syntax                           |
| Query Optimization | Extensive optimizations    | Basic queries              | Prevents N+1 queries, dramatically improves performance             |
| Caching            | Redis with auto-busting    | No cache / Always cache    | Read-heavy APIs benefit, automatic invalidation                     |
| Cache Store        | Redis                      | Memory store / SolidCache  | Production-ready, future compatible with Sidekiq                    |
| Resilience         | Basic error handling       | Circuit breakers / Retries | Appropriate scope, documented production patterns                   |
| Forward Compatible | Yes                        | Breaking changes           | Standard Rails patterns, complete schema                            |

---

## Major Design Decisions

### Platform & Infrastructure

**Rails API-only mode:** Lighter footprint, faster boot times, clearer intent for JSON API. Trade-off: Cannot serve HTML views (aligns with use case).

**PostgreSQL:** Better efficiency, future-proofing with advanced features (JSONB, full-text search), industry standard. Trade-off: More complex than SQLite, but essential for production.

**Fly.io (Singapore region):** Improved loading speed for SG customers, managed PostgreSQL/Redis, cost-effective scaling. Trade-off: Less established than Heroku, but better regional performance.

### Data Model

**Self-referential sections only:** Simpler, demonstrates hierarchy. Items are typically flat lists. Trade-off: Less flexible if items need sub-items (unlikely for menus).

**Identifier-only URLs:** Better URLs, more secure (harder to predict). Trade-off: Requires unique identifier management.

**Active boolean flag:** Simpler queries, better performance for read-only API. Trade-off: No audit trail (can add `archived_at` later).

**DECIMAL price + currency:** Exact precision, supports any decimal places, no floating-point errors. Trade-off: Slightly larger storage than integer.

**Environment-based depth limit:** Configurable per environment, runtime adjustment. Trade-off: Requires environment configuration.

### Implementation

**Thin controllers + service layer:** Controllers focus on HTTP, business logic in services (`CatalogTreeBuilder`), common methods in ApplicationController. Better testability and maintainability.

**Invalid route handling:** `exceptions_app` configuration routes invalid URLs to `ExceptionsController` which returns JSON 404 response. Maintains API server consistency (no HTML 404 pages).

**JSON API Serializer:** Faster than Jbuilder/AMS, cleaner syntax, industry-standard format. Trade-off: Slightly more setup.

**Query optimizations:** Eager loading, strategic indexing, PostgreSQL features. Result: Reduced from 161+ queries to 4-5 (40-310x improvement).

**Redis caching with auto-busting:** Version-based keys (`catalog:{id}:{updated_at}`) provide automatic invalidation. Production-ready, future-compatible with Sidekiq. Key insight: Eliminates manual cache management.

### Operational

**Forward compatible:** Yes - standard Rails associations, complete schema, write-compatible JSON. Can add create/update, authentication, soft deletes without breaking changes.

**Error logging:** Planned integration with Sentry/Airbrake for production monitoring (real-time alerts, performance tracking).

---

## Failure Modes & Mitigations

**Circular References:** Validation using Set to track ancestor IDs (detects cycles), depth limit prevents excessive nesting.

**Deep Nesting Performance:** Environment depth limit, eager loading prevents N+1 queries, caching, gzip compression.

**Missing Data:** 404 response, filter inactive by default, clear error messages.

**Stack Overflow:** Depth tracking, respect `MAX_SECTION_DEPTH`, iterative tree building.

---

## Key Insights

1. **Simplicity > Complexity:** Simpler solutions show better judgment
2. **Version-Based Cache Keys:** Automatic invalidation (`catalog:{id}:{updated_at}`) eliminates manual cache management
3. **Eager Loading Is Critical:** 40-310x fewer queries (4-5 vs 161+)
4. **Hash Maps Make Tree Traversal Fast:** O(1) lookups vs O(n) scans
5. **Forward Compatibility Matters:** Design for future enhancements without breaking changes
6. **Thin Controllers, Fat Services:** Offload complexity to services for better maintainability
7. **Query Optimization Pays Off:** Strategic eager loading dramatically improves performance
8. **Regional Hosting Matters:** Infrastructure close to users significantly improves response times
9. **Redis for Future-Proofing:** Enables easy addition of Sidekiq without infrastructure changes

---

---

## Additional Resources

- **System Architecture:** [`ARCHITECTURE.md`](ARCHITECTURE.md)
- **Performance Analysis:** [`COMPLEXITY_ANALYSIS.md`](COMPLEXITY_ANALYSIS.md)
