# Naming, comments, and layout

Adapted from the [MIT Comm Lab guide on coding and comment
style](https://mitcommlab.mit.edu/broad/commkit/coding-and-comment-style/).
Code is the primary documentation. Write clear code first, then comment only
what the code itself cannot say.

## Naming

- Names are descriptive and straightforward, and say what the thing actually
  is. Cleverness in a name is a cost paid by every later reader.
- Variables and types are nouns; functions and methods are verbs. Predicates
  read as questions — `isValid`, `hasNext`.
- Names are pronounceable. If you can't say it out loud in a review, rename it.
- Name length is proportional to scope: `i` inside a three-line loop,
  `retryBudgetPerHost` at package scope. This is the naming half of declaring
  at the smallest scope.
- No abbreviations unless they're universally self-explanatory (`id`, `url`,
  `http`). Anything domain-specific or ambiguous gets spelled out, or defined
  in plain language in a comment at its declaration.
- Follow the language's typographic conventions rather than a personal one —
  `snake_case`, `camelCase`, `PascalCase` as the language dictates.
- Use surrounding context to avoid redundancy. Inside a catch block,
  `invalidArgument` beats `argumentException`; inside a `user` module,
  `user.create` beats `user.createUser`.

## Comments

Two kinds of comment earn their place, and they live in different positions: a
**contract** above a definition, and a **phase header** inside a body. Anything
that is neither is usually a comment restating the code, and should be deleted
or fixed by renaming the thing it was compensating for.

**Contracts** are complete sentences above the definition. They say what the
function does and, more importantly, the part of the deal the signature can't
express: what's true on success versus failure, what an out-parameter or error
return means, the units and expected shape of an argument, what the caller must
guarantee. Refer to parameters by name. Exported APIs get this in the
language's doc convention, covering purpose, inputs, outputs, and failure
modes. Unexported helpers get the same thing in plain prose whenever the
signature alone doesn't tell the story.

**Phase headers** turn a function body into an outline. Most functions worth
commenting divide into a handful of phases; put a short fragment above each one
and a blank line between them, and the comments become a table of contents for
the algorithm:

```text
// ImportHMACKey loads a hex-encoded key into the keystore and returns its
// opaque id. The key material is wiped before returning, on every path.
function ImportHMACKey(hexKey) -> (KeyID, error):

    // Decode the hex key into raw bytes
    ...

    // Describe the key's type and permitted uses to the keystore
    ...

    // Import, then wipe the plaintext regardless of outcome
    ...
```

The test: delete everything but the comments and you should be left with a
readable summary of what the function does. If that summary is confusing, the
function is doing too much.

- **The unit is the phase, not the line.** Never annotate individual
  statements. A phase is a group of statements that accomplishes one step,
  fenced off by blank lines.
- **Once a body has phase headers, every phase gets one** — including the
  obvious ones. The regularity is what makes an uncommented block mean "still
  the same phase" rather than "too obvious to mention."
- **A single-phase function gets no in-body comments at all.** A small helper
  whose contract is stated above it should have a bare body.
- **Write the *why* wherever it's the non-obvious thing**, outline or not.
  Ordering that looks arbitrary but isn't, a tradeoff taken deliberately, what
  bounds a loop or a recursion, a workaround with a link to the underlying
  issue, an invariant the type system can't state. These are worth more than
  any phase header — the reader can reconstruct *what* from the code, but never
  *why*.
- **Keep comments current.** An outdated comment is worse than no comment. When
  you change code, update or delete the comment above it — and be suspicious of
  comments obligated by convention rather than written on purpose, since those
  are the ones nobody remembers to maintain.
- **Address TODOs to a person** and give them enough to act on:
  `TODO(@nate): replace the linear scan with a prefix index — it's O(n) per
  request and dominates p99 past ~10k keys.` A bare `TODO` is noise.
- **Match the project's markers.** Where a codebase distinguishes doc comments
  from ordinary ones, use the doc marker for interface documentation and the
  plain one for implementation notes, and stay consistent across files.

Mechanically: contracts are complete sentences and end in periods; phase
headers are fragments and don't.

## Layout

- One statement per line, even where the language allows several.
- Group related declarations together and separate unrelated ones; vertical
  grouping should show what belongs with what.
- Delegate everything else to the language's canonical formatter, and don't
  fight it — including on tabs versus spaces and on where operators fall when
  an expression breaks across lines. Formatting is not worth attention that
  could go to design.
