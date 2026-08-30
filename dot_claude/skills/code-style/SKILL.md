---
name: code-style
description: The house style for writing or reviewing code in any language — a functional design (values and pure functions, state pushed to the edge, immutable data, errors as values) plus rigor rules adapted from JPL's Power of 10 (bounded loops, bounded resources, checked returns, minimal indirection). Use before writing new code, refactoring, or reviewing a diff, and when deciding how to name things, what to put in a comment, how to model alternatives with enums or sum types, how to shape an HTTP API, or how to structure iteration, recursion, concurrency, or logging.
---

# Code style

Two bodies of guidance govern the code: a functional style (*Design*) and a set
of rigor rules adapted from JPL's Power of 10 (*Rigor*). Where they pull against
each other, rigor wins — bounded laziness over unbounded streams, explicit
limits over "it terminates in practice." Where the functional style already
satisfies the intent, it satisfies it: immutable values and pure functions
remove whole classes of the aliasing and hidden-state failures those rules were
written to catch.

The guidance is language-agnostic; apply it through whatever the language at
hand offers.

**Scope.** In an existing codebase its conventions win: match the surrounding
style, and keep changes inside the scope of the task. Don't refactor toward this
document unless asked — a file half-converted to a style the rest of the repo
doesn't share is worse than either style alone. Where a framework requires a
shape these rules forbid — a model class, an inherited handler, a decorator that
registers something — write the shape the framework requires and keep the logic
out of it. Where following a rule would make the code worse, don't follow it:
name the rule and the reason in a comment at the site. A deviation you can point
at is fine; the unmarked ones are what these rules exist to catch.

## Design

Write functional code. The organizing principle is Rich Hickey's [Simple Made
Easy](https://github.com/matthiasn/talk-transcripts/blob/master/Hickey_Rich/SimpleMadeEasy.md):
*simple* means unentangled — one fold, one concern — and is objective. *Easy*
means familiar or close at hand, and is not a design goal. Prefer constructs
that keep independent things independent, even when a more entangled construct
is the idiomatic reflex.

- **Logic lives in pure functions.** Namespaces of top-level functions that take
  data and return data. No classes carrying state, no `self`, no singletons, no
  ambient globals. A closure may capture values, never a mutable binding.
- **State is pushed to the edge.** A thin imperative shell reads the world,
  calls a pure core, writes the result back. Where mutable state is
  unavoidable: one managed reference, updated by a pure transition function.
- **Effects are idempotent and deterministic.** Every effect is safe to apply
  twice; the program's *output* is reproducible, not just its functions.
- **Data over ceremony.** Plain data — maps, records, sets, sequences. Sum
  types and exhaustive matching over inheritance hierarchies. Never
  implementation inheritance. Declarative data manipulation over an ORM.
- **Compose small functions.** Errors as values, handled where there's context
  to decide. Interfaces defined at the consumer, one or two operations wide.
- **Concurrency is scoped.** Tasks are awaited by the scope that spawned them;
  cancellation and deadlines propagate; share by communicating over bounded
  channels. Reach for it to cut latency, not to decouple code.
- **Log from the shell**, structured key-value, one event per outcome, an error
  logged once where it's handled.

| Instead of | Reach for |
| --- | --- |
| Objects, methods | Values, functions |
| Inheritance, type switches | Protocols, traits, interfaces |
| Mutable variables | Immutable values, one managed reference |
| Imperative loops | Set/sequence functions |
| Actors, shared memory | Queues, channels |
| ORM | Declarative data manipulation |
| Config as globals | Config parsed at the edge, passed as data |
| Conditionals | Rules, data tables |
| Mocks | Pure functions and real values |

## Rigor: the Power of 10

JPL's [rules for safety-critical
code](https://en.wikipedia.org/wiki/The_Power_of_10:_Rules_for_Developing_Safety-Critical_Code),
adapted for modern languages. They exist so a human or a tool can check a
program's behavior by reading it — every path bounded, every failure handled,
every assumption stated.

1. **Keep control flow simple and analyzable.** No `goto`, no non-local jumps,
   no exception-as-control-flow.
2. **Bound every loop.** See `references/loops.md`.
3. **Bound resource use.** No unbounded buffers, queues, caches, fan-out, or
   response accumulation. Growth is a function of input you already limited.
4. **Keep functions short.** One screen, ~60 lines, one level of abstraction.
5. **Assert your invariants.** Make illegal states unrepresentable first;
   assert what types can't express. Anything that *can* be false at runtime is
   an error value, not an assertion. Never an empty `catch`.
6. **Declare at the smallest possible scope.** No package-level mutable
   variables, no reused scratch bindings, no values declared far from use.
7. **Check every return value; validate every parameter.** Never discard an
   error. Parse boundary input into types the core can trust.
8. **Limit metaprogramming.** Macros, reflection, monkey-patching, and dynamic
   dispatch tricks defeat the reader and the analyzer.
9. **Limit indirection.** Dispatch traceable by reading — not a registry
   populated as an import side effect or a handler resolved from a string.
10. **Compile and lint at maximum strictness from day one.** Warnings as errors
    in CI. Fix the warning; never silence it without a written reason.

**Iteration, in preference order:** a named `map`/`filter`/`fold` or
comprehension over a collection you hold → a bounded `for` → an iterator or
streaming pipeline → recursion, only when structural or guaranteed-tail.

**Untrusted input and secrets:** everything crossing the boundary is untrusted
until parsed. Never concatenate input into a query, command line, path, or
template. Secrets are read at the edge and passed inward as values, never
logged. Fail closed. Full text in `references/rigor.md`.

## References

Read these when the task touches them; don't load them speculatively.

| File | Read it when |
| --- | --- |
| `references/design.md` | designing a module: purity, the shell/core split, idempotent and deterministic effects, concurrency, logging, composition |
| `references/comments.md` | naming things, writing a doc comment or contract, deciding what a comment should say, laying out a file |
| `references/loops.md` | writing any loop, retry, poll, generator, stream, or recursion |
| `references/enums.md` | modeling a closed set of states, or putting an enum in a schema, proto, or wire format |
| `references/rest-aip.md` | designing or extending an HTTP API |
| `references/rigor.md` | the ten rules in full, plus untrusted input and secrets |
