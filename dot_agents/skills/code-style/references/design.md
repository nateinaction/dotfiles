# Design

## Logic lives in pure functions

- Organize logic as **namespaces of top-level pure functions** — a module, file,
  or package of functions that take data and return data. No classes, no
  methods carrying state, no `self`, no singletons, no ambient globals.
- A function's result must depend only on its arguments. Needing the clock, the
  filesystem, the network, an environment variable, or randomness is the signal
  that a decision belongs to the caller: take the value as an argument instead
  of reaching for it.
- Don't use classes as namespaces — that's what modules and packages are for.
  Reach for a class only where the language or framework requires one
  (exceptions, framework entrypoints, trait/protocol implementations), and keep
  it a thin data carrier or adapter. Logic must never hide inside one.
- **A closure may capture values; it must never capture a mutable binding.**
  Capturing a variable that something else can still write is the same hidden
  state as a field on an object, minus the name to grep for. A closure over
  immutable values is a partially applied function and is fine; a closure used
  as a place to keep a counter, a cache, or an accumulator is an object with
  the receiver hidden. If a captured thing needs to change, it belongs in the
  one managed reference at the edge.

## State is pushed to the edge

- Keep a thin imperative shell at the program boundary — `main`, request
  handlers, CLI entrypoints, job runners — that reads the world, calls a pure
  core, and writes the result back. Everything interesting happens in the core.
- A pure core needs no mocks to test. If a test needs heavy mocking, the design
  put state in the wrong place; fix the design, not the test.
- Where mutable state is unavoidable, make it explicit, singular, and visible:
  one managed reference updated by a pure transition function, not mutation
  scattered across call sites. No hidden caches; memoization is explicit and
  lives at the edge.
- Prefer immutable values. Construct new data rather than mutating in place.
  Pass values, not handles to things that can change underneath the callee.
- "Construct new data" is not "copy the whole structure." Use the language's
  persistent collections, which share their unchanged parts between versions —
  an update is a small allocation plus pointers to what didn't change, not an
  O(n) copy. Where only mutable collections exist, build the new value once in
  a local and hand it out immutably, rather than copying on every update.

## Effects are idempotent and deterministic

Purity is a property of the core. These are the two properties the shell owes
in exchange, and neither follows from the core being pure.

- **Every effect is safe to apply twice.** Retries, at-least-once delivery,
  resumed jobs, and replayed webhooks all mean an effect that runs once in the
  happy path will eventually run more than once. Write upserts keyed by an id
  the caller supplies, not blind inserts. Make transitions absorbing rather
  than relative — set the balance to a value, don't increment it; move to a
  state, don't advance one step. Where an effect genuinely can't be repeated —
  charging a card, sending mail, launching a job — give it an idempotency key
  and record that key in the same transaction as the effect itself, so the
  second attempt can see the first one landed.
- This is the other half of the retry ceilings in `loops.md`: a bound on
  attempts is only safe if the attempts are repeatable. Adding a retry to a
  non-idempotent effect converts a transient failure into a duplicate.
- **The program's output is reproducible, not just its functions.** A pure
  function is deterministic in its arguments; that alone doesn't make a run
  reproducible. Hash map and set iteration order, wall-clock timestamps,
  generated ids, unstable sorts, and the completion order of concurrent work
  all leak nondeterminism into output without a single impure call appearing
  in the code. Sort collections before emitting them, seed generators
  explicitly, use a stable sort wherever the result is compared, and take the
  clock and the id source as arguments — which the core already requires.
- The bar: anything a test, a diff, a log, or a cache key observes should be
  byte-identical across runs on the same input. This is the reproducibility
  Nix provides for the build, applied to what the program itself emits.

## Concurrency

- **Tasks are scoped.** A function that starts concurrent work waits for it
  before returning. No fire-and-forget, no task outliving the scope that
  spawned it with nobody holding the handle.
- **Cancellation and deadlines propagate.** A concurrent call takes the
  caller's cancellation signal or deadline and passes it down. A task that
  can't be cancelled is a leak with extra steps.
- **Share by communicating.** Tasks exchange immutable values over bounded
  channels or queues rather than writing to memory another task reads. Locks
  are the fallback where the language offers nothing better, and then one lock
  guards one named thing, taken in a documented order.
- Reach for concurrency to cut latency, not to decouple code. Decoupling is
  what functions and interfaces are for.
- Completion order is nondeterministic. Collect results and restore a
  deterministic order before emitting them — see *Effects* above.

## Logging

Logs are output, so the determinism bar above applies to them too.

- Log from the shell. A pure core doesn't log; it returns what happened and
  lets the edge decide whether that's worth recording.
- Structured key-value events, not interpolated prose. A log line is data for a
  query, not a sentence to skim.
- One event per outcome at the boundary, not a trace of every step. Record the
  decision and the inputs it turned on; the code already shows the steps.
- An error is logged once, where it's handled. Logging *and* returning the same
  error records one failure at every frame it passes through.
- Never log secrets, credentials, tokens, or personal data — see `rigor.md`.
  Log the id, not the record.

## Data over ceremony

- Model data as plain data: maps, records, sets, sequences. Data is
  inspectable, comparable, serializable, and manipulable by generic functions.
  Don't wrap it in a type that only exists to hold it.
- Where a language offers cheap immutable records for shape and type safety
  (`struct`, frozen dataclass, `type`/`interface`, `data class`), use them —
  but keep them dumb.
- Model alternatives with sum types, tagged unions, or enums plus exhaustive
  matching — never inheritance hierarchies or `isinstance`/type-switch chains.
  See `enums.md`.
- Prefer polymorphism à la carte — protocols, traits, typeclasses, interfaces
  defined by the consumer — over inheritance. Never use implementation
  inheritance.
- Express queries and transformations declaratively (data manipulation, SQL,
  pipelines) rather than through an ORM that complects schema, identity,
  mutation, and I/O.

## Composition

- Build behavior by composing small functions. Prefer map/filter/reduce or
  comprehensions to imperative accumulation loops — see `loops.md`.
- Use partial application to specialize a general function at the edge —
  binding configuration, a client, or a limit once and passing the narrowed
  function inward. Stop there. Point-free chains, curried-by-default
  signatures, and combinator towers optimize for writing over reading; a named
  function with named parameters is clearer at every later encounter.
- Treat errors as values (`Result`, `error`, tagged unions) and handle them
  where there's enough context to decide; keep the core total.
- Separate *what* from *how*: name the operation with a small interface,
  implement it behind that interface, and let callers depend only on the name.
  Define interfaces at the consumer, keep them one or two operations wide, and
  accept them as parameters.
- Decouple *when* and *where* with queues and channels rather than direct calls
  between components that shouldn't know about each other.
- Prefer rules and data-driven tables to sprawling conditionals.
