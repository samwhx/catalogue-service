# System Architecture

## Overview

A REST API for serving hierarchical catalogue data (e.g., restaurant menus) with nested relationships. Optimized for high read traffic with minimal write operations.

**Key Characteristics:**

- Read-heavy workload (1000:1 read-to-write ratio)
- Hierarchical data structure (3-4 levels deep)
- Self-referential relationships (sections can have sub-sections)
- Fast response times (<100ms for typical catalogs)

---

## High-Level Architecture

```
┌─────────────────┐
│   API Clients   │
└────────┬────────┘
         │ HTTP/REST
┌────────▼─────────────────────────────────────┐
│         Rails API Application                 │
│  Controllers → Services → Serializers → Cache │
└─────────────────┬─────────────────────────────┘
         ┌────────┴────────┐
    ┌────▼────┐    ┌──────▼──────┐
    │PostgreSQL│    │   Redis     │
    └─────────┘    └──────────────┘
```

### Request Flow

1. **Client Request** → `GET /catalogs/:identifier`
2. **Controller** → Checks cache, handles routing
3. **Service Layer** → Builds hierarchical tree structure
4. **Serializers** → Converts to JSON
5. **Cache** → Stores/retrieves responses
6. **Database** → Eager loads data (4-5 queries)

**Performance:** See [`COMPLEXITY_ANALYSIS.md`](COMPLEXITY_ANALYSIS.md) for detailed metrics.

---

## Core Components

### 1. Data Model Layer

**Models:** Catalog → Section (self-ref) → Item → Option

**Design Patterns:**

- Self-Referential Association (sections can have parent sections)
- Active Record Pattern (Rails ORM)
- Active Flag Pattern (boolean `active` for filtering)

### 2. Service Layer

**Key Service:** `CatalogTreeBuilder` - Constructs hierarchical tree from flat records

**Design Patterns:**

- Service Object Pattern (encapsulates complex logic)
- Hash Map Optimization (O(1) parent lookups)
- Depth Limiting (respects `MAX_SECTION_DEPTH`)

**Why Separate:** Keeps controllers thin, makes logic testable, enables reuse

### 3. Serialization Layer

**Technology:** Fast JSON API (jsonapi-serializer)

**Why:** High performance, declarative syntax, supports conditional attributes

### 4. Caching Layer

**Strategy:** Version-based cache keys (`catalog:{id}:{updated_at}`)

**Patterns:**

- Cache-Aside Pattern
- Version-Based Invalidation (automatic)
- TTL Safety Net (24 hours)

**Current:** Redis cache store

### 5. Controller Layer

**Patterns:**

- RESTful Routing
- Thin Controllers (delegates to services)
- Centralized Error Handling (`rescue_from`)
- Caching Abstraction (`render_with_cache`)

**Endpoints:**

- `GET /catalogs` - List catalogs (metadata only)
- `GET /catalogs/:identifier` - Full nested hierarchy (cached)

### 6. Database Layer

**Technology:** PostgreSQL

**Optimizations:**

- Eager Loading (4-5 queries vs 161+ without)
- Strategic Indexing (foreign keys, unique fields, composite keys)
- Active Filtering (database-level `WHERE active = true`)

---

## Design Patterns & Principles

1. **Separation of Concerns:** Controllers (HTTP), Services (business logic), Models (data), Serializers (presentation)
2. **Single Responsibility:** Each component has one clear purpose
3. **DRY:** Common logic extracted to helpers (`render_with_cache`, `active_sorted`)
4. **Convention Over Configuration:** Standard Rails patterns
5. **Performance by Design:** Eager loading, hash maps, caching, indexes

---

## Data Flow

```
Request → Controller → Cache Check
  ├─ Cache Hit → Return (<1ms)
  └─ Cache Miss → Continue
      ↓
Load from Database (eager load)
  ↓
CatalogTreeBuilder.build()
  ├─ Load sections (1 query)
  ├─ Group by parent_id (hash map)
  ├─ Build tree (respect MAX_SECTION_DEPTH)
  └─ Serialize nodes
      ↓
Serialize to JSON (Fast JSON API)
  ↓
Store in cache → Return response
```

---

## Scalability

**Architecture supports:**

- Horizontal scaling (multiple app servers, shared Redis cache, read replicas)
- Vertical scaling (connection pooling handles concurrency)
- Caching strategy (Redis cache store)

For detailed scalability metrics and performance analysis, see [`COMPLEXITY_ANALYSIS.md`](COMPLEXITY_ANALYSIS.md).

---

## Technology Stack

- **Framework:** Ruby on Rails (API mode)
- **Database:** PostgreSQL
- **ORM:** ActiveRecord
- **Cache:** Redis
- **Serialization:** Fast JSON API (jsonapi-serializer)
- **Testing:** RSpec, FactoryBot, Shoulda Matchers
- **Server:** Puma (multi-threaded)

---

## Security

### Current (Interview Demo)

- No authentication (public API)
- CORS enabled for all origins

### Production (Documented)

- JWT for write operations
- API keys for rate limiting
- HTTPS enforced
- CORS restricted to specific origins

---

## Failure Handling

**Error Scenarios:** 404 for missing resources, 500 for server errors, graceful cache degradation

**Resilience Patterns (Production):** Circuit breakers, stale cache fallback, retry logic, health checks

For detailed failure modes and mitigations, see [`DESIGN_DECISIONS.md`](DESIGN_DECISIONS.md).

---

## Forward Compatibility

**100% forward-compatible** - Can add create/update, authentication, soft deletes, positioning gem, Redis cache without breaking changes.

**Why:** Standard Rails patterns, complete schema, write-compatible JSON structure.

For detailed forward compatibility analysis, see [`DESIGN_DECISIONS.md`](DESIGN_DECISIONS.md).

---

## Key Architectural Decisions

1. **Service Layer for Tree Building:** Keeps controllers thin, logic testable
2. **Hash Map Optimization:** O(1) lookups for tree traversal (vs O(n) scans)
3. **Version-Based Cache Keys:** Automatic invalidation without manual management
4. **Fast JSON API:** High performance serialization with declarative syntax
5. **Eager Loading:** Prevents N+1 queries (4-5 queries vs 161+)
6. **Redis Cache:** Production-ready, future-compatible with Sidekiq
7. **Self-Referential Sections:** Flexible hierarchy without fixed-depth models

---

## References

- **Design Decisions:** [`DESIGN_DECISIONS.md`](DESIGN_DECISIONS.md)
- **Performance Analysis:** [`COMPLEXITY_ANALYSIS.md`](COMPLEXITY_ANALYSIS.md)
