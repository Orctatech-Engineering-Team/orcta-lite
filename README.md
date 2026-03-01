# orcta-lite

Minimal Hono + Drizzle template for rapid API experimentation.

Derived from [orcta-stack](../orcta-stack) — same philosophy, stripped to essentials.

## Philosophy

- **Simple is not easy** — understand before you abstract
- **Result types over exceptions** — explicit error handling
- **Progressive abstraction** — write it twice before you abstract

Read the full philosophy in [`docs/PHILOSOPHY.md`](docs/PHILOSOPHY.md).

## Documentation

| Doc | What it covers |
|-----|----------------|
| [`CLAUDE.md`](CLAUDE.md) | Quick reference for AI agents and developers |
| [`AGENTS.md`](AGENTS.md) | Work discipline, branching, commits |
| [`docs/PHILOSOPHY.md`](docs/PHILOSOPHY.md) | The beliefs behind every decision |
| [`docs/PATTERNS.md`](docs/PATTERNS.md) | Code patterns and conventions |
| [`docs/WRITING.md`](docs/WRITING.md) | Writing voice and style guide |

## Quick Start

```bash
# Install dependencies
pnpm install

# Copy environment file
cp .env.example .env

# Run migrations
pnpm db:migrate

# Start development server
pnpm dev
```

## Commands

```bash
pnpm dev              # Start dev server (tsx watch)
pnpm build            # Build for production
pnpm start            # Run production build
pnpm typecheck        # Type check
pnpm lint             # Lint with Biome
pnpm test             # Run tests
pnpm db:generate      # Generate migration from schema changes
pnpm db:migrate       # Apply migrations
pnpm db:studio        # Open Drizzle Studio
pnpm new:module NAME  # Scaffold a new module
pnpm http FILE        # Run .http requests
```

## Project Structure

```
src/
├── index.ts           # Entry point
├── app.ts             # Hono app setup
├── env.ts             # Environment config
├── db/
│   ├── index.ts       # Drizzle client
│   └── schema.ts      # Database schema
├── lib/
│   ├── result.ts      # Result<T, E> type
│   ├── infra.ts       # tryInfra wrapper
│   └── response.ts    # API response helpers
└── modules/
    └── health/        # Example module
        └── index.ts
```

## Adding a Module

Use the scaffolder (auto-registers in `app.ts`):

```bash
pnpm new:module posts              # creates + registers
pnpm new:module posts --with-repo  # with repository file
pnpm new:module posts --no-register  # skip auto-registration
```

Or create manually in `src/modules/`:

```typescript
// src/modules/posts/index.ts
import { Hono } from "hono";
import { z } from "zod";
import { zValidator } from "@hono/zod-validator";
import { jsonSuccess, jsonError, HttpStatus } from "@/lib/response";

const posts = new Hono();

const createPostSchema = z.object({
  title: z.string().min(1),
  content: z.string(),
});

posts.post("/posts", zValidator("json", createPostSchema), async (c) => {
  const input = c.req.valid("json");
  // ... create post logic
  return jsonSuccess(c, { id: "...", ...input }, HttpStatus.CREATED);
});

export default posts;
```

Then register in `src/app.ts`:

```typescript
import posts from "@/modules/posts";
app.route("/", posts);
```

## Error Handling Pattern

Use `Result<T, E>` for operations that can fail:

```typescript
import { ok, err, match, type Result } from "@/lib/result";
import { tryInfra, type InfrastructureError } from "@/lib/infra";

type NotFound = { type: "NOT_FOUND" };
type PostError = NotFound | InfrastructureError;

async function findPost(id: string): Promise<Result<Post, PostError>> {
  const result = await tryInfra(() =>
    db.query.posts.findFirst({ where: eq(posts.id, id) })
  );

  if (!result.ok) return result;
  if (!result.value) return err({ type: "NOT_FOUND" });

  return ok(result.value);
}

// In handler:
const result = await findPost(id);

return match(result, {
  ok: (post) => jsonSuccess(c, post),
  err: (e) => {
    if (e.type === "NOT_FOUND") {
      return jsonError(c, "NOT_FOUND", "Post not found", HttpStatus.NOT_FOUND);
    }
    return jsonError(c, "INTERNAL_ERROR", "Database error", HttpStatus.INTERNAL_SERVER_ERROR);
  },
});
```

## API Testing

Use `.http` files in the `requests/` directory:

```bash
pnpm http list              # List all request files
pnpm http health            # Run all requests in health.http
pnpm http health ping       # Run only requests matching "ping"
pnpm http posts create      # Run "create" request from posts.http
```

Files work in VSCode (REST Client extension) and terminal. Variables are defined in `requests/_base.http`:

```http
@base = http://localhost:3000
@contentType = application/json
```

Module scaffolder auto-generates `.http` files for new modules.

## License

[Polyform Noncommercial 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0)

Copyright (c) 2024 Bernard Kirk Katamanso

Free for personal, educational, and noncommercial use. Commercial use prohibited. See [LICENSE](LICENSE).
