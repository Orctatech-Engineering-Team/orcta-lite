# AGENTS.md

Instructions for AI agents working in this codebase. Read this before touching anything.

Also read: [`CLAUDE.md`](CLAUDE.md) for commands and architecture, [`docs/WRITING.md`](docs/WRITING.md) for documentation voice, [`docs/PHILOSOPHY.md`](docs/PHILOSOPHY.md) for the beliefs behind every decision.

---

## Philosophy

This codebase follows a simple principle: **simple is not easy, but it's the only thing that scales**.

Bias toward the boring solution. Complexity is a cost you pay with every future change. Don't add indirection that doesn't earn its keep. Don't build for hypothetical requirements. Don't make ten changes when one would do.

The principles are documented in [`docs/PHILOSOPHY.md`](docs/PHILOSOPHY.md). Read it once.

---

## The Core Rule: Work in Coherent Units

A coherent unit is one logical change with a clear boundary. It has a name. It could be described in a single sentence. It has tests. It gets a commit.

**A coherent unit is:**

- A new feature (`feat`)
- A bug fix (`fix`)
- A refactor that doesn't change behavior (`refactor`)
- A dependency update + any required code changes (`chore`)
- A documentation improvement (`docs`)

**A coherent unit is NOT:**

- A feature + an unrelated test fix + a renamed variable
- "All the things I noticed while looking at the file"
- Every change across the entire repo triggered by one small ask

When you find something adjacent that needs fixing, note it. Finish the current unit. Then address it separately.

---

## Branching

Never commit directly to `main` for anything beyond a typo fix. New work = new branch.

```bash
git checkout main
git pull origin main
git checkout -b <type>/<short-description>
```

Branch naming:

| Type | Pattern | Example |
|------|---------|---------|
| New feature | `feature/<name>` | `feature/post-pagination` |
| Bug fix | `fix/<name>` | `fix/validation-error` |
| Refactor | `refactor/<name>` | `refactor/error-handler` |
| Chore | `chore/<name>` | `chore/update-drizzle` |
| Documentation | `docs/<name>` | `docs/add-patterns` |

One branch = one coherent unit.

---

## Commits

Conventional commits. Always.

```
<type>(<scope>): <what changed>

<why it changed, if not obvious>
```

Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`

Scopes: `api`, `db`, `lib`, `modules`, `deps`

**Good:**

```
feat(api): add pagination to posts endpoint

Uses offset/limit pattern. Returns meta with total count.
```

**Bad:**

```
update stuff
fixed some things and also added the new feature
wip
```

Commit size: one concern per commit. If the message needs "and", it's probably two commits.

---

## Testing

Tests are part of the work unit, not an afterthought.

- Write or update tests **before committing**
- For new modules: at minimum, one passing test
- For logic that branches: test every branch
- For bug fixes: write the test that would have caught it first

```bash
pnpm test          # All tests
pnpm typecheck     # TypeScript
pnpm lint          # Biome
```

All three must pass before you commit.

---

## Scope Discipline

These are the failure modes to actively avoid:

**Don't batch unrelated changes.** If you're asked to add pagination, don't also fix the health handler, rename a variable you noticed, and update three docs files. Do the thing asked. Commit it. Note the rest.

**Don't refactor while adding a feature.** If the existing code is messy, open a refactor first, then build the feature on clean ground.

**Don't create summary documents.** Don't create `CHANGES.md`, `SUMMARY.md`, or `TODO.md` unless explicitly asked.

**Don't touch files you weren't asked to touch** unless they're directly load-bearing for the change.

**Don't leave the codebase in a half-done state.** Either complete the unit or don't start it.

---

## Code Patterns

The patterns are documented in [`docs/PATTERNS.md`](docs/PATTERNS.md). Use them.

**Error handling:** functions that can fail return `Result<T, E>`. No `throw` in repository code. Infrastructure catches go through `tryInfra`. Domain errors are typed.

**Module structure:** flat by default. `index.ts` contains routes and handlers. Add `*.repository.ts` when data access gets complex. Add `*.test.ts` for tests.

**Response format:** use `jsonSuccess` and `jsonError` from `@/lib/response`.

---

## What Good Work Looks Like

You're done with a unit when:

1. The feature, fix, or refactor works as intended
2. Tests cover the new behavior
3. Lint and typecheck pass
4. The commit message describes what changed and why
5. The branch is clean

Quality is not completeness. Finish what you start.
