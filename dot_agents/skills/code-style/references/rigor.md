# Rigor: the Power of 10

Apply JPL's [Power of 10 rules for safety-critical
code](https://en.wikipedia.org/wiki/The_Power_of_10:_Rules_for_Developing_Safety-Critical_Code),
adapted below for modern languages. They exist so that a human or a tool can
check a program's behavior by reading it — every path bounded, every failure
handled, every assumption stated. That goal holds outside avionics.

1. **Keep control flow simple and analyzable.** No `goto`, no non-local jumps,
   no clever exception-as-control-flow. See `loops.md` for iteration and
   recursion.
2. **Bound every loop.** See `loops.md`.
3. **Bound resource use.** Allocate what you can up front, at the edge. No
   unbounded buffers, queues, caches, task fan-out, or response accumulation.
   Cap request bodies, use bounded channels, stream instead of slurping.
   Growth must be a function of input you have already limited.
4. **Keep functions short.** One screen, roughly 60 lines. A function does one
   thing at one level of abstraction. Length is a symptom — split by extracting
   meaningful named operations, not arbitrary chunks.
5. **Assert your invariants.** First make illegal states unrepresentable with
   types; assert what the type system can't express. An assertion states
   something the program believes can never be false, and a failure is a bug in
   the program. Anything that *can* be false at runtime — bad input, a missing
   file, a refused connection — is an error value instead; see *Composition* in
   `design.md`. Assertions are side-effect free, and a failed one has a defined
   outcome — never an empty `catch`.
6. **Declare at the smallest possible scope.** No package-level mutable
   variables, no reused scratch bindings, no values declared far from use.
   Narrow scope is the local form of pushing state to the edge.
7. **Check every return value; validate every parameter.** Never discard an
   error — no silently dropped results, no swallowed exceptions. If ignoring a
   result is truly correct, say why in a comment. Validate inputs at the
   boundary and parse them into types the core can trust, so the core doesn't
   re-check.
8. **Limit metaprogramming.** Macros, reflection, code generation,
   monkey-patching, and dynamic dispatch tricks defeat the reader and the
   analyzer. Prefer explicit code. Generated code is checked in and reviewed
   like any other.
9. **Limit indirection.** Dispatch should be traceable by reading: a named
   interface with a small, enumerable set of implementations, not an opaque
   callback table, a registry populated as a side effect of import, or a
   handler resolved from a string at runtime. This is not a bar on the
   consumer-defined interfaces in *Composition* — those name the indirection,
   which is the point. It's a bar on indirection the reader can't follow to its
   destinations.
10. **Compile and lint at maximum strictness from day one.** All warnings
    enabled, warnings as errors in CI, linters at their strictest setting,
    static analysis in the loop. Fix the warning; never silence it without a
    written reason.

## Untrusted input and secrets

- Everything crossing the boundary is untrusted until parsed — request bodies,
  CLI arguments, environment variables, file contents, and responses from
  services you don't own. Parse it into types the core can trust (rule 7) and
  bound its size before allocating for it (rule 3).
- Never assemble a query, a command line, a path, or a template by
  concatenating input. Parameterized queries, argument arrays rather than shell
  strings, path joins that reject traversal, escaping done by the library that
  owns the format.
- Secrets are read at the edge from the environment or a secret store and
  passed inward as values. Never committed, never a default in code, never in a
  fixture or a comment. A secret reaching a log, an error message, or a stack
  trace is a bug.
- Fail closed. When an authorization check, a signature verification, or a
  parse fails, the operation is denied — there is no path where the failure
  branch is the permissive one.
