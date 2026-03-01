# CLAUDE.md

Quick reference for working with this codebase. Read [`AGENTS.md`](AGENTS.md) for work discipline, branching, and commit rules before starting any task.

## Docs

| Doc | What it covers |
|-----|----------------|
| `AGENTS.md` | **Work discipline, branching, commits — read first** |
| `docs/PHILOSOPHY.md` | The beliefs behind every decision |
| `docs/PATTERNS.md` | Code patterns and conventions |
| `docs/WRITING.md` | Writing voice and style guide |

## Commands

```bash
pnpm dev              # Run dev server (tsx watch, :3000)
pnpm build            # Build for production
pnpm start            # Run production build
pnpm typecheck        # Type check
pnpm lint             # Lint with Biome
pnpm test             # Run tests
pnpm db:generate      # Generate migration from schema changes
pnpm db:migrate       # Apply migrations
pnpm db:studio        # Open Drizzle Studio
pnpm new:module NAME  # Scaffold a new module
pnpm http FILE        # Run .http requests (e.g., pnpm http health)
```

## Architecture

Pure Hono + Zod. No OpenAPI layer. The key rule:

**Functions that can fail return `Result<T, E>`, not exceptions.**

```typescript
type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };
```

Handlers use `match` to map results to HTTP responses.

## File Locations

| What | Where |
|------|-------|
| Entry point | `src/index.ts` |
| App setup | `src/app.ts` |
| Modules | `src/modules/{name}/` |
| Database | `src/db/` |
| Utilities | `src/lib/` |

## Module Structure

```bash
modules/{name}/
  index.ts              # Routes + handlers
  {name}.repository.ts  # Data access (optional)
  {name}.test.ts        # Tests
```

Generate with `pnpm new:module <name>`. Auto-registers in `app.ts`.

Keep it flat until complexity demands otherwise.

## Common Patterns

### Adding a module

```bash
pnpm new:module posts              # creates + registers
pnpm new:module posts --with-repo  # includes repository file
pnpm new:module posts --no-register  # skip auto-registration
```

### Adding a route

```typescript
// src/modules/posts/index.ts
import { Hono } from "hono";
import { z } from "zod";
import { zValidator } from "@hono/zod-validator";
import { jsonSuccess, HttpStatus } from "@/lib/response";

const posts = new Hono();

const createPostSchema = z.object({
  title: z.string().min(1),
  content: z.string(),
});

posts.post("/posts", zValidator("json", createPostSchema), async (c) => {
  const input = c.req.valid("json");
  // ... logic
  return jsonSuccess(c, result, HttpStatus.CREATED);
});

export default posts;
```

Then register in `src/app.ts`:

```typescript
import posts from "@/modules/posts";
app.route("/", posts);
```

### Adding a database table

1. Add schema in `src/db/schema.ts`
2. Run `pnpm db:generate && pnpm db:migrate`

### Error handling

```typescript
import { ok, err, match, tryInfra } from "@/lib/result";

// Repository
async function findById(id: string) {
  return tryInfra(() => db.query.posts.findFirst({ where: eq(posts.id, id) }));
}

// Handler
const result = await findById(id);

return match(result, {
  ok: (post) => post ? jsonSuccess(c, post) : jsonError(c, "NOT_FOUND", "Post not found", 404),
  err: () => jsonError(c, "INTERNAL_ERROR", "Database error", 500),
});
```

## Environment

Required in `.env`:

- `DATABASE_URL` — Postgres connection string

Optional:

- `PORT` — Server port (default: 3000)
- `LOG_LEVEL` — Pino log level (default: info)
