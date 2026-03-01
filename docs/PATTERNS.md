# Code Patterns

The patterns used in this codebase. Use them consistently. Don't invent new ones without documenting them here.

---

## Error Handling

Functions that can fail return `Result<T, E>`. No exceptions for expected failures.

### The Result Type

```typescript
type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };
```

Constructors:

```typescript
import { ok, err } from "@/lib/result";

return ok(user);                           // Success
return err({ type: "NOT_FOUND" });         // Domain error
```

### Infrastructure vs Domain Errors

**Infrastructure errors** are system failures — database down, network timeout, external service unavailable. Use `tryInfra` to catch these:

```typescript
import { tryInfra } from "@/lib/infra";

async function findById(id: string) {
  return tryInfra(() => db.query.posts.findFirst({ where: eq(posts.id, id) }));
}
// Returns Result<Post | undefined, InfrastructureError>
```

**Domain errors** are expected failures — not found, validation failed, conflict. Define them as discriminated unions:

```typescript
type NotFound = { type: "NOT_FOUND" };
type AlreadyExists = { type: "ALREADY_EXISTS"; email: string };
type PostError = NotFound | AlreadyExists | InfrastructureError;
```

### Handling Results

Use `match` for exhaustive handling at boundaries:

```typescript
import { match } from "@/lib/result";

return match(result, {
  ok: (post) => jsonSuccess(c, post),
  err: (e) => {
    switch (e.type) {
      case "NOT_FOUND":
        return jsonError(c, "NOT_FOUND", "Post not found", 404);
      case "INFRASTRUCTURE_ERROR":
        return jsonError(c, "INTERNAL_ERROR", "Service unavailable", 500);
    }
  },
});
```

Use `andThen` for chaining operations:

```typescript
import { andThenAsync } from "@/lib/result";

const result = await andThenAsync(
  await findUser(userId),
  (user) => createPost({ authorId: user.id, ...input })
);
```

---

## Module Structure

Start flat. Add structure when complexity demands it.

### Minimal Module

```
modules/posts/
  index.ts        # Routes + handlers
  posts.test.ts   # Tests
```

```typescript
// modules/posts/index.ts
import { Hono } from "hono";
import { jsonSuccess } from "@/lib/response";

const posts = new Hono();

posts.get("/posts", async (c) => {
  const posts = await db.query.posts.findMany();
  return jsonSuccess(c, posts);
});

export default posts;
```

### With Repository

When data access logic gets complex, extract it:

```
modules/posts/
  index.ts
  posts.repository.ts
  posts.test.ts
```

```typescript
// modules/posts/posts.repository.ts
import { tryInfra } from "@/lib/infra";
import { db, posts } from "@/db";
import { eq } from "drizzle-orm";

export async function findById(id: string) {
  return tryInfra(() =>
    db.query.posts.findFirst({ where: eq(posts.id, id) })
  );
}

export async function create(data: NewPost) {
  return tryInfra(async () => {
    const [post] = await db.insert(posts).values(data).returning();
    return post;
  });
}
```

### With Use Cases

When business logic needs isolation (rare in a lite template), add use cases:

```
modules/posts/
  index.ts
  posts.repository.ts
  posts.usecases.ts
  posts.errors.ts
  posts.test.ts
```

Only add this structure when you have logic worth testing in isolation.

---

## Validation

Use Zod with `@hono/zod-validator`:

```typescript
import { z } from "zod";
import { zValidator } from "@hono/zod-validator";

const createPostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string(),
  published: z.boolean().default(false),
});

posts.post("/posts", zValidator("json", createPostSchema), async (c) => {
  const input = c.req.valid("json");
  // input is typed: { title: string; content: string; published: boolean }
});
```

For query params:

```typescript
const listSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
});

posts.get("/posts", zValidator("query", listSchema), async (c) => {
  const { page, limit } = c.req.valid("query");
});
```

---

## Response Format

All responses follow a consistent shape:

```typescript
// Success
{ success: true, data: T }

// Error
{ success: false, error: { code: string, message: string, details?: object } }
```

Use helpers from `@/lib/response`:

```typescript
import { jsonSuccess, jsonError, HttpStatus } from "@/lib/response";

// Success
return jsonSuccess(c, post);
return jsonSuccess(c, post, HttpStatus.CREATED);

// Error
return jsonError(c, "NOT_FOUND", "Post not found", HttpStatus.NOT_FOUND);
return jsonError(c, "VALIDATION_ERROR", "Invalid input", HttpStatus.BAD_REQUEST, {
  fields: { title: "Required" }
});
```

---

## Testing

Use Hono's built-in `app.request()` for integration tests:

```typescript
import { describe, it, expect } from "vitest";
import app from "@/app";

describe("Posts", () => {
  it("GET /posts returns empty list", async () => {
    const res = await app.request("/posts");
    expect(res.status).toBe(200);

    const body = await res.json();
    expect(body).toEqual({
      success: true,
      data: [],
    });
  });

  it("POST /posts creates a post", async () => {
    const res = await app.request("/posts", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title: "Test", content: "Content" }),
    });
    expect(res.status).toBe(201);

    const body = await res.json();
    expect(body.success).toBe(true);
    expect(body.data.title).toBe("Test");
  });
});
```

For testing with database, use a test database and clean up between tests.

---

## Database

### Schema Definition

```typescript
// src/db/schema.ts
import { pgTable, text, timestamp, uuid, boolean } from "drizzle-orm/pg-core";

export const posts = pgTable("posts", {
  id: uuid("id").primaryKey().defaultRandom(),
  title: text("title").notNull(),
  content: text("content").notNull(),
  published: boolean("published").notNull().default(false),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
});

export type Post = typeof posts.$inferSelect;
export type NewPost = typeof posts.$inferInsert;
```

### Queries

```typescript
import { db, posts } from "@/db";
import { eq, desc } from "drizzle-orm";

// Find one
const post = await db.query.posts.findFirst({
  where: eq(posts.id, id),
});

// Find many
const allPosts = await db.query.posts.findMany({
  orderBy: desc(posts.createdAt),
  limit: 20,
});

// Insert
const [newPost] = await db.insert(posts).values(data).returning();

// Update
const [updated] = await db
  .update(posts)
  .set({ title: "New Title", updatedAt: new Date() })
  .where(eq(posts.id, id))
  .returning();

// Delete
await db.delete(posts).where(eq(posts.id, id));
```

Always wrap in `tryInfra` when used in repositories.
