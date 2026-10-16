#!/bin/sh
# Expose the skills listed in the mattpocock plugin manifest to every agent
# that reads ~/.agents/skills (opencode). Idempotent: ln -sfn.
set -eu

repo="$HOME/.agents/vendor/mattpocock-skills"
dest="$HOME/.agents/skills"
manifest="$repo/.claude-plugin/plugin.json"

[ -f "$manifest" ] || { echo "missing $manifest" >&2; exit 1; }
mkdir -p "$dest"

jaq -r '.skills[]' "$manifest" | while IFS= read -r rel; do
  src="$repo/${rel#./}"
  [ -f "$src/SKILL.md" ] || { echo "missing $src/SKILL.md" >&2; exit 1; }
  ln -sfn "$src" "$dest/$(basename "$src")"
done
