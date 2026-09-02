---
description: Research a topic on the web and produce a cited report
argument-hint: "<topic> [--save | path/to/report.md]"
---
Research this topic on the web: $@

Do NOT research it yourself in this context. Dispatch the `researcher` subagent:
call the `subagent` tool in single mode with `agent: "researcher"` and `task`
set to the full topic above, including any `--save` flag or output path the user
gave (if a path was given, tell the researcher to write the report there;
otherwise it stays chat-only).

When the subagent returns, relay its report **verbatim** — full Markdown,
comparison table, inline citations, and the numbered Sources list intact. Do not
summarize it, do not re-order sections, do not drop citations. Add your own
commentary only if the user asked a follow-up question the report leaves open,
and keep it clearly separated below the report.

If the researcher asks a clarifying question instead of returning a report,
relay that question to the user and stop.
