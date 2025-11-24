# Hierarchical Catalogue API

A REST API for serving hierarchical catalogue data (e.g., restaurant menus) with nested relationships. Built with Ruby on Rails, optimized for high read traffic.

## Quick Start

```bash
bundle install
rails db:create db:migrate db:seed
bundle exec rspec
rails server
```

**Environment Variables:** `MAX_SECTION_DEPTH` (default: 5)

## API Endpoints

### GET /catalogs

Returns list of active catalogs (metadata only).

**Live Endpoint:** https://catalogue-service.fly.dev/catalogs

### GET /catalogs/:identifier

Returns single catalog with full nested hierarchy (sections → items → options).

**Live Endpoint:** https://catalogue-service.fly.dev/catalogs/atlas-kitchen-2024

**Example Response:**

```json
{
  "id": "1",
  "identifier": "atlas-kitchen-2024",
  "name": "2024 Menu",
  "sections": [
    {
      "id": "1",
      "identifier": "appetizers",
      "name": "Appetizers",
      "sub_sections": [],
      "items": [
        {
          "id": "1",
          "sku": "caesar-salad",
          "name": "Caesar Salad",
          "price": "12.50",
          "currency": "USD",
          "options": []
        }
      ]
    }
  ]
}
```

## Key Features

- Hierarchical structure: Catalog → Section (self-referential) → Item → Option
- Self-referential sections for flexible nesting
- Redis caching with automatic cache busting for performance
- Eager loading to prevent N+1 queries
- Read-only API (GET endpoints only)

For detailed design decisions, performance analysis, and architecture, see the [documentation](docs/).

## Assignment Questions

### What is the atomic unit?

**Answer:** The **Item** is the atomic unit.

Items are what customers ultimately select and purchase. Sections are organizational containers, options are enhancements to items, and catalogs are collections of sections.

**Analogy:** In a restaurant menu, the "Caesar Salad" (item) is what you order, even though it's organized under "Appetizers" (section) in the "Dinner Menu" (catalog).

### Trade-offs made

**1. Self-Referential Sections Only**

- ✅ Simpler, still demonstrates hierarchical concepts
- ❌ Less flexible if items need sub-items (unlikely for menus)

**2. Simple Integer Display Order**

- ✅ Simpler, faster, no dependency, sufficient for read-only API
- ❌ No automatic reordering (not needed for read-only)

### Failure modes anticipated

**1. Circular References**

**Problem:** Self-referential sections could create cycles (A → B → C → A)

**Mitigation:**

- Validation using Set to track all ancestor IDs (detects cycles at any depth)
- Depth limit (`MAX_SECTION_DEPTH`) prevents excessive nesting

**2. Deep Nesting Performance**

**Problem:** Very deep hierarchies cause slow queries and large JSON responses

**Mitigation:**

- Environment variable depth limit
- Eager loading prevents N+1 queries
- Caching provides massive speedup
- Gzip compression reduces payload size

### If you had an extra day, what would you improve?

1. **Comprehensive Monitoring:** Response times, cache hit rates, error rates, query counts
2. **Circuit Breaker Pattern:** Fallback to stale cache if database unavailable
3. **Request Rate Limiting:** Protect public API from abuse
4. **More Test Coverage:** Integration tests, performance tests, load tests

### What did you learn?

1. **Simplicity > Complexity:** Meeting requirements with simpler solutions shows better judgment
2. **Version-Based Cache Keys:** Automatic invalidation is elegant
3. **Eager Loading Is Critical:** Dramatically reduces database queries
4. **Hash Maps Make Tree Traversal Fast:** O(1) lookups vs O(n) scans
5. **Forward Compatibility Matters:** Design for future enhancements without breaking changes
6. **Production Thinking:** Consider caching, monitoring, resilience even in demos

For detailed learnings and insights, see [`docs/DESIGN_DECISIONS.md`](docs/DESIGN_DECISIONS.md).

## Additional Resources

- **System Architecture:** [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- **Design Decisions:** [`docs/DESIGN_DECISIONS.md`](docs/DESIGN_DECISIONS.md)
- **Complexity Analysis:** [`docs/COMPLEXITY_ANALYSIS.md`](docs/COMPLEXITY_ANALYSIS.md)
