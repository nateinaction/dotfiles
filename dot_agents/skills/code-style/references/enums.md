# Enums

An enum is the smallest closed set in the language: a named, enumerable list of
the states a thing can be in. Reach for one wherever the set of possibilities
is known and finite, and prefer it to the stand-ins — a string compared against
literals, an int with a comment, or a pair of booleans.

- **Two booleans are usually one enum.** A pair of flags admits four
  combinations when the domain has three; the fourth is a state nobody defined
  and everyone must still handle. Name the states instead.
- **Match exhaustively, and don't add a catch-all arm to quiet the compiler.**
  The missing-case error is the reason the enum exists — it's the tool that
  finds every site needing attention when a member is added. Where a default
  arm is unavoidable, make it fail loudly rather than silently pick a behavior.
- **Members name domain states, not implementation details or codes.**
  `RetryExhausted`, not `Error3`. The enum is often the clearest documentation
  of the domain in the codebase.
- **Keep them dumb.** An enum is data. Branch on it in functions rather than
  hanging per-member behavior off it, in the languages that allow that — it's
  the same rule as *Logic lives in pure functions*.
- **Never depend on ordinal position or the underlying integer.** Don't persist
  an ordinal, don't compare by it, don't derive one member from another by
  arithmetic. Persist and transmit the name; reordering members should be a
  no-op.
- **Adding a member is a breaking change, and that's correct.** Every
  exhaustive match is a site that has to decide about the new state. Don't
  design around this — it's the value being bought.

Where a language offers no enum, the equivalent is a sum type, a tagged union,
or a small set of singleton values used the same way. The rules are unchanged;
what varies is how much of the checking the compiler does for you.
