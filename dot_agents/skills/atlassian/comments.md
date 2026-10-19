# Writing Jira comments

A comment is read by a teammate skimming the ticket weeks later. Write it so
the first two lines carry the news and the rest is scannable: headings, short
paragraphs, tables, lists, code formatting.

## Posting

Jira stores a plain-text `--body` as a single paragraph, so Markdown arrives as
literal `|`, `#` and `-` characters in one block of text. Write the comment in
Markdown, convert it to ADF, and post the ADF:

```sh
md2adf=~/.agents/skills/atlassian/scripts/md2adf.py
$md2adf --site https://wpengine.atlassian.net --project SK8RS < comment.md > comment.json
acli jira workitem comment create --key SK8RS-<number> --body-file comment.json
```

- **Edit** a comment in place with
  `acli jira workitem comment update --key SK8RS-<number> --id <id> --body-adf comment.json`.
  It notifies watchers only with `--notify`. Get the id from
  `acli jira workitem comment list --key SK8RS-<number> --json`.
- The script's docstring lists the supported Markdown. Mermaid, images and
  HTML are outside it; draw trees and call graphs in a fenced code block.
- Write ticket keys bare (`SK8RS-2710`); `--project` turns them into smart
  links that show the ticket's title and status. Pass `--project` once per
  project you reference.
- Ticket descriptions are ADF too: convert the same way and set the result as
  `description` in the create JSON
  (`jq --slurpfile d desc.json '.description = $d[0]' workitem.json`).

## Shape

Every comment opens with a **title line** and a **bottom line**:

```markdown
### <Kind>: <subject>

<One or two sentences: the result, decision, or state, and what it means for the ticket.>
```

Put the bottom line in a callout panel (`> [!INFO]`, `[!SUCCESS]`,
`[!WARNING]`, `[!ERROR]`) when it is a result or a blocker the reader must
see. Use at most one panel per comment.

Then add sections that fit the kind of comment. These are starting points; pick
the smallest set that makes the point, rename or merge sections as needed, and
drop any that would be empty.

| Kind | Sections |
| --- | --- |
| Status update | Bottom line · Changes (table: Repo, PR, State, Notes) · Merge order (numbered) · Next |
| Investigation | Bottom line · Setup · Method · Results (table) · Conclusion · Open questions · Next |
| Test or benchmark | Bottom line · Command (code block) · Results (table with a Change column) · Takeaways · Caveats |
| Decision or resolution | Decision · Accepted / Changed (table: Item, Decision, Why) · Follow-up tickets |
| Design summary | Approach · Diagram or tree (code block) · Sizing / limits · PRs · Out of scope |
| Context hand-off | Source ticket key, then two to five bullets of facts the reader needs. No heading. |
| Reply | Plain prose, no heading, for anything under about four sentences. |

## Formatting

- **Headings:** `###` for the title, `####` for sections. Larger levels render
  oversized in a comment.
- **Paragraphs:** one idea each, three sentences at most. Separate them with a
  blank line.
- **Tables:** whenever two or more items share two or more attributes
  (benchmarks, PRs per repo, before and after, options compared). Put the
  comparison's verdict in its own column (`Change`, `State`, `Verdict`).
- **Lists:** numbered for an order that matters (merge order, steps to
  reproduce), bullets otherwise. One fact per bullet; nest for detail instead
  of chaining clauses with semicolons.
- **Code formatting:** identifiers, resource names, file paths with line
  numbers, config keys and values, versions. Commands go in fenced code blocks
  with a language.
- **Links:** PRs as `[repo#123](url)`, tickets as bare keys, docs as
  `[title](url)`.
- **Certainty:** label claims you have not verified (`**Unconfirmed:**`) and
  keep them out of the bottom line.
- **Artifacts:** attach or link anything a reader needs (logs, manifests,
  samples). Mention only paths and resources the reader can open.

## Example

```markdown
### Status: literal constants implemented across three repos

> [!INFO]
> All three PRs are open. Merge in order: configurator, then WEO plus a release, then FCPO.

#### Changes

| Repo | PR | CI | Notes |
| --- | --- | --- | --- |
| fluid-wordpress-configurator | [#75](https://github.com/wpengine/fluid-wordpress-configurator/pull/75) | Red (unrelated) | Reads `WPE_LITERAL_*` alongside `WPE_SECRET_*`; rejects duplicate constant names |
| web-environment-operator | [#379](https://github.com/wpengine/web-environment-operator/pull/379) | Green | `literal` field; sets `WPE_LITERAL_<NAME>` on the configurator init container |
| fluid-control-plane-operator | [#457](https://github.com/wpengine/fluid-control-plane-operator/pull/457) | Green | Passes `literal` through to WEO |

#### Follow-ups

- Configurator CI fails only on the `golangci-lint` pre-commit hook: the v2.13.2 pin cannot read Go 1.27 export data. Dependabot PR #74 fails the same way. Bump it in its own PR.
- FCPO's `go.mod` pins the unmerged WEO commit. Swap to the release tag once #379 ships.
```
