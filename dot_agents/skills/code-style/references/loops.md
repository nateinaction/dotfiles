# Loop semantics

Iteration is where the functional style and the Power of 10 pull against each
other, so the rules for it are collected here.

**Default: don't use recursion.** Reach for it only when the alternative is
materially worse — walking a genuinely tree-shaped structure is the usual case
— and then only when the recursion is structural (each call consumes part of a
finite input) or tail-recursive in a language that guarantees tail calls. Never
write recursion whose depth is a function of untrusted input. Where you do
recurse, say in a comment what bounds the depth.

**Prefer, in order:**

1. A named set/sequence operation — `map`, `filter`, `fold`/`reduce`, or a
   comprehension — over a collection you already hold.
2. A bounded `for` over a finite collection or an explicit count.
3. An iterator or streaming pipeline, when the data shouldn't be materialized
   at once.
4. Recursion, under the constraints above.

**Generating a sequence is a loop too.** Producing values from a seed — paging
an API, expanding a frontier, retrying with backoff — gets the same treatment
as consuming one: prefer a named unfold or generator that yields values and
lets the caller bound the take, over a `while` loop pushing into a list the
body also owns. The generator states how the next value is derived; the caller
states how many it wants. Neither hides the other's job.

**Laziness defers work, not the bound.** A lazy sequence, generator, or stream
is the right tool when the data shouldn't be materialized at once — but it
moves the moment of evaluation away from the code that reads like it does the
work, which is where unbounded consumption hides. So: force at a boundary you
can name. Take a bounded prefix before collecting, and never let a lazy value
escape the scope that owns its resources — a stream over an open file or
connection is consumed and closed in the function that opened it, never
returned to a caller who can't see what it holds. Infinite sequences are fine
as definitions and never as values you hand across an interface.

**Every loop needs a visible bound.** Iterating a finite collection is bounded
and fine. Any loop that isn't — retry, poll, reconnect, consume, converge —
carries an explicit ceiling at the loop itself: max attempts, a deadline, or a
cancellation signal. No `for {}` or `while (true)` without an exit condition a
reader can point at. "It always terminates" is not a bound; a number is.

A bound on attempts is only safe if the attempts are repeatable. Adding a retry
to a non-idempotent effect converts a transient failure into a duplicate — see
the idempotency rules in `design.md`.

**Keep the bound and the state out of the body.** No mutation of anything
declared outside the loop, no accumulating into a shared buffer, no
`break`-to-a-label control flow. A loop that computes a value should look like
one — build the result and return it.
