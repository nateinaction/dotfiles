#!/usr/bin/env python3
"""Convert a Markdown subset to Atlassian Document Format (ADF) JSON.

Usage:
  md2adf.py [--site https://example.atlassian.net --project KEY ...] < in.md > out.json

Blocks: ATX headings, paragraphs (single newlines become line breaks, as in
GitHub comments), bullet and ordered lists nested by indentation, pipe tables
(first row is the header), fenced code blocks (also inside list items), blockquotes, GitHub-style
callouts (`> [!INFO]`, NOTE, TIP, SUCCESS, IMPORTANT, WARNING, CAUTION, ERROR)
as panels, and `---` rules.

Inline: **bold**, _italic_, `code`, [text](url), bare http(s) URLs, and, when
--site and --project are given, issue keys of those projects as smart links.
"""

import argparse
import itertools
import json
import re
import sys

MAX_LIST_DEPTH = 6

PANEL_TYPES = {
    "NOTE": "note",
    "INFO": "info",
    "TIP": "success",
    "SUCCESS": "success",
    "IMPORTANT": "warning",
    "WARNING": "warning",
    "CAUTION": "error",
    "ERROR": "error",
}

# Block types each container accepts, per the ADF schema.
ALLOWED_CHILDREN = {
    "panel": {"paragraph", "heading", "bulletList", "orderedList", "codeBlock", "rule"},
    "blockquote": {"paragraph", "bulletList", "orderedList", "codeBlock"},
}

HEADING = re.compile(r"^(#{1,6})\s+(.*?)\s*#*\s*$")
RULE = re.compile(r"^\s*([-*_])(\s*\1){2,}\s*$")
FENCE = re.compile(r"^\s*```\s*([\w+-]*)\s*$")
LIST_ITEM = re.compile(r"^(\s*)([-*+]|\d+[.)])\s+(.*)$")
TABLE_SEPARATOR = re.compile(r"^\s*\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)*\|?\s*$")
CALLOUT = re.compile(r"^\[!(\w+)\]\s*$")


def inline_pattern(projects):
    keys = "|".join(re.escape(p) for p in projects)
    key_alt = rf"|(?P<key>\b(?:{keys})-\d+\b)" if keys else ""
    return re.compile(
        r"(?P<code>`[^`]+`)"
        r"|\*\*(?P<bold>.+?)\*\*"
        r"|(?<![\w*])_(?P<italic>[^_]+?)_(?!\w)"
        r"|\[(?P<link_text>[^\]]+)\]\((?P<link_url>[^)\s]+)\)"
        r"|(?P<url>https?://[^\s<>()]*[^\s<>().,;:!?'\"])"
        + key_alt
    )


def text_node(text, marks=()):
    node = {"type": "text", "text": text}
    if marks:
        node["marks"] = list(marks)
    return node


def add_mark(nodes, mark):
    # ADF forbids combining the code mark with formatting marks.
    def marked(node):
        existing = node.get("marks", [])
        if node["type"] != "text" or any(m["type"] == "code" for m in existing):
            return node
        return {**node, "marks": existing + [mark]}

    return [marked(n) for n in nodes]


def parse_inline(text, ctx):
    pattern, site = ctx
    nodes = []
    pos = 0
    for m in pattern.finditer(text):
        if m.start() > pos:
            nodes.append(text_node(text[pos:m.start()]))
        if m.group("code"):
            nodes.append(text_node(m.group("code")[1:-1], [{"type": "code"}]))
        elif m.group("bold"):
            nodes += add_mark(parse_inline(m.group("bold"), ctx), {"type": "strong"})
        elif m.group("italic"):
            nodes += add_mark(parse_inline(m.group("italic"), ctx), {"type": "em"})
        elif m.group("link_text"):
            link = {"type": "link", "attrs": {"href": m.group("link_url")}}
            nodes += add_mark(parse_inline(m.group("link_text"), ctx), link)
        elif m.group("url"):
            url = m.group("url")
            nodes.append(text_node(url, [{"type": "link", "attrs": {"href": url}}]))
        else:
            url = f"{site}/browse/{m.group('key')}"
            nodes.append({"type": "inlineCard", "attrs": {"url": url}})
        pos = m.end()
    if pos < len(text):
        nodes.append(text_node(text[pos:]))
    return nodes


def paragraph(lines, ctx):
    content = []
    for i, line in enumerate(lines):
        if i > 0:
            content.append({"type": "hardBreak"})
        content += parse_inline(line.strip(), ctx)
    return {"type": "paragraph", "content": content}


def split_row(line):
    """Split a table row on pipes that are neither escaped nor inside backticks."""
    body = line.strip()
    body = body[1:] if body.startswith("|") else body
    body = body[:-1] if body.endswith("|") and not body.endswith("\\|") else body
    cells, current, in_code, escaped = [], [], False, False
    for ch in body:
        if escaped:
            current.append(ch)
            escaped = False
        elif ch == "\\":
            escaped = True
        elif ch == "`":
            in_code = not in_code
            current.append(ch)
        elif ch == "|" and not in_code:
            cells.append("".join(current).strip())
            current = []
        else:
            current.append(ch)
    cells.append("".join(current).strip())
    return cells


def table(lines, ctx):
    header = split_row(lines[0])
    width = len(header)

    def row(cells, cell_type):
        padded = (cells + [""] * width)[:width]
        return {
            "type": "tableRow",
            "content": [
                {"type": cell_type, "content": [paragraph([c], ctx)]} for c in padded
            ],
        }

    body = [row(split_row(line), "tableCell") for line in lines[2:]]
    return {"type": "table", "content": [row(header, "tableHeader")] + body}


def indent_of(line):
    return len(line) - len(line.lstrip(" "))


def build_list(entries, depth, ctx):
    """Build a list node from (indent, marker, lines) entries; deeper entries nest."""
    if depth > MAX_LIST_DEPTH:
        raise ValueError(f"lists nest deeper than {MAX_LIST_DEPTH} levels")
    base, marker, _ = entries[0]
    groups = []
    for entry in entries:
        if entry[0] <= base or not groups:
            groups.append((entry, []))
        else:
            groups[-1][1].append(entry)

    def item(head, children):
        content = []
        for is_code, group in itertools.groupby(head[2], key=lambda part: isinstance(part, dict)):
            content += list(group) if is_code else [paragraph(list(group), ctx)]
        if children:
            content.append(build_list(children, depth + 1, ctx))
        return {"type": "listItem", "content": content}

    items = [item(head, children) for head, children in groups]
    if marker[0].isdigit():
        return {"type": "orderedList", "attrs": {"order": int(marker[:-1])}, "content": items}
    return {"type": "bulletList", "content": items}


def take_list(lines, start):
    """Collect list entries from `start`; return (entries, next index).

    Each entry is (indent, marker, parts); a part is a text line or a finished
    codeBlock node. A line indented past the list's base that is not an item
    continues the preceding item, and an indented fence adds a code block to it.
    """
    entries = []
    i = start
    base = indent_of(lines[start])
    ordered = LIST_ITEM.match(lines[start]).group(2)[0].isdigit()

    def continues_list(line):
        m = LIST_ITEM.match(line)
        if not m or indent_of(line) < base:
            return False
        return indent_of(line) > base or m.group(2)[0].isdigit() == ordered

    while i < len(lines):  # bounded: i advances every iteration
        line = lines[i]
        next_line = lines[i + 1] if i + 1 < len(lines) else ""
        next_continues = continues_list(next_line) or (
            bool(FENCE.match(next_line)) and indent_of(next_line) > base
        )
        if continues_list(line):
            m = LIST_ITEM.match(line)
            entries.append((len(m.group(1)), m.group(2), [m.group(3)]))
        elif FENCE.match(line) and indent_of(line) > base and entries:
            node, i = take_fence(lines, i)
            indent, marker, parts = entries[-1]
            entries[-1] = (indent, marker, parts + [node])
            continue
        elif line.strip() and indent_of(line) > base and not LIST_ITEM.match(line):
            indent, marker, parts = entries[-1]
            entries[-1] = (indent, marker, parts + [line.strip()])
        elif not line.strip() and next_continues:
            pass  # blank line inside a list item or between items
        else:
            break
        i += 1
    return entries, i


def take_fence(lines, start):
    """Parse the fenced code block opening at `start`; return (node, next index).

    Body lines lose the fence's own indentation, so a block nested in a list
    item keeps only the indentation it has relative to the fence.
    """
    fence = FENCE.match(lines[start])
    body, end = take_while(lines, start + 1, lambda l: not FENCE.match(l))
    if end == len(lines):
        raise ValueError(f"line {start + 1}: unclosed code fence")
    margin = indent_of(lines[start])
    body = [l[margin:] if indent_of(l) >= margin else l.lstrip(" ") for l in body]
    node = {"type": "codeBlock"}
    if fence.group(1):
        node["attrs"] = {"language": fence.group(1)}
    if body:
        node["content"] = [text_node("\n".join(body))]
    return node, end + 1


def container(node_type, attrs, inner_lines, ctx):
    content = parse_blocks(inner_lines, ctx)
    allowed = ALLOWED_CHILDREN[node_type]
    bad = sorted({n["type"] for n in content} - allowed)
    if bad:
        raise ValueError(f"{node_type} cannot contain: {', '.join(bad)}")
    node = {"type": node_type, "content": content}
    if attrs:
        node["attrs"] = attrs
    return node


def quote(lines, ctx):
    inner = [re.sub(r"^\s*> ?", "", line) for line in lines]
    callout = CALLOUT.match(inner[0].strip())
    if not callout:
        return container("blockquote", None, inner, ctx)
    kind = callout.group(1).upper()
    if kind not in PANEL_TYPES:
        raise ValueError(f"unknown callout [!{kind}]; use one of {', '.join(PANEL_TYPES)}")
    return container("panel", {"panelType": PANEL_TYPES[kind]}, inner[1:], ctx)


def starts_block(lines, i):
    line = lines[i]
    is_table = (
        line.lstrip().startswith("|")
        and i + 1 < len(lines)
        and TABLE_SEPARATOR.match(lines[i + 1])
    )
    return bool(
        HEADING.match(line)
        or FENCE.match(line)
        or RULE.match(line)
        or LIST_ITEM.match(line)
        or line.lstrip().startswith(">")
        or is_table
    )


def take_while(lines, start, keep):
    end = start
    while end < len(lines) and keep(lines[end]):  # bounded by len(lines)
        end += 1
    return lines[start:end], end


def parse_blocks(lines, ctx):
    blocks = []
    i = 0
    while i < len(lines):  # bounded: every branch advances i
        line = lines[i]
        fence = FENCE.match(line)
        heading = HEADING.match(line)
        if not line.strip():
            i += 1
        elif fence:
            node, i = take_fence(lines, i)
            blocks.append(node)
        elif heading:
            level = len(heading.group(1))
            content = parse_inline(heading.group(2), ctx)
            blocks.append({"type": "heading", "attrs": {"level": level}, "content": content})
            i += 1
        elif RULE.match(line):
            blocks.append({"type": "rule"})
            i += 1
        elif LIST_ITEM.match(line):
            entries, i = take_list(lines, i)
            blocks.append(build_list(entries, 1, ctx))
        elif line.lstrip().startswith(">"):
            body, i = take_while(lines, i, lambda l: l.lstrip().startswith(">"))
            blocks.append(quote(body, ctx))
        elif starts_block(lines, i):  # the only block left is a table
            body, i = take_while(lines, i, lambda l: l.lstrip().startswith("|"))
            blocks.append(table(body, ctx))
        else:
            start = i
            i += 1
            while i < len(lines) and lines[i].strip() and not starts_block(lines, i):
                i += 1  # bounded by len(lines)
            blocks.append(paragraph(lines[start:i], ctx))
    return blocks


def convert(markdown, site, projects):
    ctx = (inline_pattern(projects if site else []), site.rstrip("/") if site else "")
    return {"type": "doc", "version": 1, "content": parse_blocks(markdown.splitlines(), ctx)}


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--site", help="Atlassian site URL, for issue-key smart links")
    parser.add_argument("--project", action="append", default=[], help="project key to link (repeatable)")
    args = parser.parse_args()
    try:
        doc = convert(sys.stdin.read(), args.site, args.project)
    except ValueError as err:
        print(f"md2adf: {err}", file=sys.stderr)
        return 1
    json.dump(doc, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
