# REST APIs

Design HTTP APIs to Google's [API Improvement Proposals](https://google.aip.dev).
Where an AIP settles a question, follow it instead of inventing a local
convention — resource-oriented design ([AIP-121](https://google.aip.dev/121)),
the standard methods get, list, create, update, and delete
([AIP-131](https://google.aip.dev/131) through
[135](https://google.aip.dev/135)), pagination
([AIP-158](https://google.aip.dev/158)), field masks
([AIP-161](https://google.aip.dev/161)), and long-running operations
([AIP-151](https://google.aip.dev/151)).

The AIPs are written for Google's protobuf-first stack, so take the design and
leave the plumbing: resource names, method semantics, and payload shape carry
over to any HTTP API; the proto idioms don't have to. Where an existing API in
the repo has already settled something differently, stay consistent with the
repo — a service half-converted to AIP is worse than either convention alone.

Enum fields in a request or response body follow
[AIP-126](https://google.aip.dev/126) — see `enums.md`.
