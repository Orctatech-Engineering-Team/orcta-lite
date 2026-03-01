# Writing Style Guide

How we write — docs, READMEs, commit messages, comments. Everything a human reads.

---

## The Four Teachers

### William Zinsser — *On Writing Well*

Every sentence earns its place. Cut the word that restates what the previous word already said. No "in order to" when "to" works. No filler clause that delays the real sentence.

The reader's time is not yours to waste.

### Charity Majors — earned opinions, no hedging

Write from scar tissue, not authority. Don't say *"you should handle errors as values"* — say *"I've debugged enough midnight incidents where a thrown exception vanished into a catch-all to know: if it can fail, the type needs to say so."*

State opinions flatly. "It depends" is never a final answer — follow it with the actual answer for the context you're in.

### Casey Muratori — show the machine

Don't describe the pattern, show the actual code, then explain *why* the shape of it is right. Walk the reader through the thinking as it happened.

The tutorial that works is the one that never skips the step where things were confusing.

### Cal Newport — one claim per section

Each section has one argument. You know what the section argues before you read it. You know it's done when the argument lands. No meandering.

---

## The Rules

**Open with the real problem.** Make the reader feel the friction before you sell the solution.

**Use "I" and "you" freely.** This is knowledge transfer between two people, not a whitepaper.

**Show code early and let it do work.** Prose explains what the code alone can't — the *why*, the tradeoffs.

**Short paragraphs.** One idea. Three sentences max. Move on.

**No throat-clearing introductions.** The first sentence is already in the middle of the thought.

**Last sentence closes the claim.** Not "and that's why X matters" — that's a restatement.

---

## On Technical Writing

**Don't soften opinions you've earned.** If you've debugged it, built it, shipped it — state the view.

**Explain the tradeoff, not just the choice.** Readers trust writing that acknowledges what was given up.

**Real code from the real repo.** No pseudocode, no cleaned-up examples that don't compile.

**Name alternatives you rejected and say why.** "I chose X over Y because Z" is the useful part.

---

## What We're Not Going For

- Academic hedging ("one might argue", "it is worth noting")
- Filler transitions ("Now that we've covered X, let's look at Y")
- False balance ("both approaches have merit" with no follow-through)
- Enthusiasm as a substitute for argument ("this is really exciting!")
- SEO-optimized intros that delay the actual content

---

## Applied Here

When writing docs, comments, or commit messages:

- A good comment is a single sentence that says *why*, not *what*
- A good commit message opens with what changed, then why
- A good doc section makes one point and moves on
