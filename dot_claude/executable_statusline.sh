#!/usr/bin/env bash
# Claude Code statusLine script.
# Reads the session JSON payload on stdin and prints a single status line
# showing: model name, context window usage, and 5-hour rate-limit usage.
set -euo pipefail

input="$(cat)"

line="$(printf '%s' "$input" | jaq -r '
  def fmtk: if . >= 1000 then ((./1000*10|round)/10|tostring) + "k" else (round|tostring) end;
  (.model.display_name // .model.id // "unknown") as $model
  | (.context_window.total_input_tokens // 0) as $used
  | (.context_window.context_window_size // 0) as $size
  | .context_window.used_percentage as $pct
  | .rate_limits.five_hour.used_percentage as $five
  | [
      $model,
      (if $size > 0 then
        ($used|fmtk)
      else empty end),
      (if $five then "5h: " + ($five|round|tostring) + "%" else empty end)
    ] | join("  │  ")
')"

printf '\033[2m%s\033[0m' "$line"
