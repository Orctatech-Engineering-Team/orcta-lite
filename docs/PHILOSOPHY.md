# Engineering Philosophy

The beliefs that anchor every decision in this codebase. Not rules — beliefs. Rules can be followed without understanding. Beliefs change how you see the problem.

---

## Simple Is Not Easy

Simple code is the hardest code to write. It requires you to fully understand the problem before you touch the keyboard, make real choices about what to leave out, and resist the pull of every interesting abstraction that presents itself along the way.

Complex code is easy. Every time you're uncertain, you add a layer. Every time requirements might change, you add an interface. Every time a pattern seems reusable, you generalize it. The result is a codebase that looks thorough and feels impressive — until you have to change something.

Simple systems scale. Not because they're small, but because they're honest. They say exactly what they do, do exactly what they say, and leave no hidden state for the next person to stumble into.

**The discipline:** before you add something, ask what it would cost to remove it. If you can't answer that, you don't understand it well enough to add it.

---

## Principles Over Tools

Tools change. The principles that make tools worth choosing don't.

Hono might be replaced. Drizzle might be replaced. The tools in this codebase are specific choices made at a specific time — they can and will be replaced. What doesn't change is the question we ask when choosing them: does this tool help the next person understand what's happening, or does it add machinery they have to learn before they can read the code?

The best tool is often the one that teaches you the least on the way to the thing you were actually trying to build.

---

## Progressive Abstraction

Start with the simplest implementation that solves the real problem in front of you.

Not the problem you might have in six months. Not the pattern you read about last week. The exact problem you have right now, in the simplest form that handles it correctly.

Abstractions earn their existence by appearing more than once. A `tryInfra` wrapper exists because every repository function needed to catch infrastructure errors and every one needed to do it the same way. Neither was designed upfront — they crystallized after the pattern repeated.

The danger of premature abstraction is that it looks like wisdom. It has interfaces and generics and thoughtful naming. It also locks in assumptions about how the system will be used before you know how it will be used.

**The discipline:** write it twice before you abstract it.

---

## Craftsmanship

Code is read far more than it is written. The primary audience for the code you're writing is not the computer — it's the person who reads it next, which will usually be you.

Craftsmanship is not cleverness. A clever solution is one that only the person who wrote it understands. A crafted solution is one where the next reader can see exactly what it does and why — where the variable names, the function boundaries, and the comment choices all reduce the cognitive load rather than increasing it.

This shows up in small things: naming a variable `userId` instead of `id`, writing a comment that says *why* instead of *what*. None of these changes are individually significant. Accumulated across a codebase, they're the difference between code that new teammates can navigate in a day and code that requires a guided tour.

---

## Human Experience First

Performance, reliability, and security are not engineering concerns — they're user concerns. Every millisecond of latency is a real person waiting. Every 500 error is a real person seeing a broken page. Every security gap is a real person's data at risk.

This doesn't mean premature optimization. It means holding onto the fact that the code is not the end product. The experience of the person using what you built is the end product.

Build with that person in mind. Not as an abstraction, but as a real person with limited time and zero patience for things that don't work.

---

## Influences

**[37signals / Jason Fried / DHH](https://37signals.com)** — the source of "simple is not easy". Constraints produce better software. Doing less, deliberately, is a form of quality.

**[The Primeagen](https://www.youtube.com/@ThePrimeagen)** — the performance-first mindset and the insistence on understanding what your code actually does.

**[Charity Majors](https://charity.wtf)** — observability and the idea that you're not done when it's deployed, you're done when you understand how it behaves in production. Earned opinions. Write from scar tissue.

**[Vercel](https://vercel.com)** — what great developer experience looks like. The best DX is the one that makes the right path the easy path.

---

## What This Means in Practice

Every decision in this codebase connects back to these beliefs:

- **The Result type** instead of exceptions — progressive abstraction. We own exactly what we need.
- **Pure Hono** instead of OpenAPI wrappers — bare metal when experimenting, add layers when needed.
- **Biome over ESLint + Prettier** — the simpler tool. One binary, one config.
- **`tryInfra` as the single catch boundary** — craftsmanship. One place where infrastructure errors are caught.
- **Flat module structure** — simple until complexity earns more.

When you're making a decision that isn't covered by existing patterns, come back to these beliefs.
