---
name: atlassian
description: How to interact with Atlassian Jira and Confluence through the `acli` CLI, including SK8RS ticket conventions and the wayfinding (map, claim, block) operations. Use for any Jira or Confluence action - creating, reading, searching, commenting on, labelling, transitioning, assigning, or linking tickets; reading Confluence pages or spaces; and whenever another skill says "publish to the issue tracker", "fetch the relevant ticket", or "wayfinding operations". Covers the acli quirks that silently produce wrong results (reversed blocking links, wrong terminal status, failing bulk reads).
---

# Atlassian (Jira and Confluence)

Issues and specs live in Jira, default project key **SK8RS**, managed with the
`acli` CLI. A repo's own `docs/agents/issue-tracker.md` overrides this skill.

Confirm flags against `acli <product> ... --help` if they differ; `acli`'s CLI
surface varies by version. Help text and success messages can be wrong (see
*Block*), so verify the result of any write you can't undo cheaply.

When another skill says "publish to the issue tracker", create a Jira issue.
When it says "fetch the relevant ticket", run `acli jira workitem view`. PRs
are not a triage surface.

## Jira

- **Create**: `acli jira workitem create --from-json workitem.json --json`.
  SK8RS requires the **Work Classifications** field (`customfield_14726`, e.g.
  `{"value": "Run the Business"}`) on every issue, which only the JSON form can
  set. Epics also require `customfield_19079`, `customfield_19080`,
  `customfield_19081` and `customfield_19185`; copy their shape from an existing
  Epic. Set an Epic parent with `"parent": {"key": "SK8RS-<number>"}` under
  `additionalAttributes`. The description must be Atlassian Document Format.
  `acli jira workitem create --generate-json` prints a template.
- **Read**: `acli jira workitem view SK8RS-<number>`.
- **List**: `acli jira workitem search --jql "project = SK8RS AND ..."`.
- **Comment**: `acli jira workitem comment --key SK8RS-<number> --body "..."`.
- **Labels**: `acli jira workitem edit --key SK8RS-<number> --labels "..."` /
  `--remove-labels "..."`.
- **Transition**: `acli jira workitem transition --key SK8RS-<number> --status "Closed"`
  (SK8RS's terminal status; there is no "Done" transition from Backlog).

**Triage labels** use the canonical role names verbatim: `needs-triage`,
`needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`.

### Wayfinding operations

- **Map**: an Epic labelled `wayfinder:map`; tickets are its children
  (`parent = SK8RS-<map>`).
- **Claim**: `acli jira workitem assign --key <key> --assignee "@me"`.
- **Block**: `acli jira workitem link create --out <blocked> --in <blocker> --type Blocks --yes`.
  acli's flag names and success message are the inverse of the result: wire one
  link, confirm it with `view <blocked> --fields '*all' --json | jq .fields.issuelinks`
  (blocked side shows "is blocked by"), then wire the rest. To reverse a link,
  `link delete --id` it first; creating over an existing pair is a silent no-op.
- **Read links**: only `view --fields '*all' --json` carries both directions;
  `search --fields` rejects `issuelinks` and `link list` omits inward keys.
  `search --fields key --json` returns nulls and `view --fields` with a
  comma list including `issuelinks` errors. To read a map's children, get the
  keys with `search --fields summary`, then `view --fields '*all' --json` each.

## Confluence

`acli confluence` offers `page`, `space`, and `blog` subcommands. `page` only
has `view`, so pages can be read but not created or edited from `acli`.

- **Read a page**: `acli confluence page view --id <id> --body-format storage`
  (also `atlas_doc_format` or `view`); add `--json` for machine output and
  `--include-labels`, `--include-direct-children`, `--include-version` as needed.
- **Spaces**: `acli confluence space list` / `view`.
