# Research tools (pi extension)

A global, **read-only** pi extension that gives the agent web access, plus a
`researcher` subagent and a `/research` command for deep, cited reports.

**Keyless by default** — it works with no API key at all. Adding a key only
improves reliability.

## What you get

| Piece | Where | What it does |
|-------|-------|--------------|
| `web_search` tool | this extension | Search the web, returns ranked title/URL/snippet |
| `web_fetch` tool | this extension | Read a page as clean markdown |
| `researcher` subagent | `~/.pi/agent/agents/researcher.md` | Bounded multi-source research on `claude-sonnet-4-5`, writes a cited report |
| `/research <topic>` | `~/.pi/agent/prompts/research.md` | Dispatches the researcher and relays the report |

The main agent auto-calls `web_search` / `web_fetch` for quick inline lookups.
Use `/research` when you want a real report (specs, comparison table, verdict).

## Backends

**Search**, in order — first one that works wins:

1. **Tavily** — used when `TAVILY_API_KEY` is set. Structured, LLM-tuned, reliable.
2. **DuckDuckGo** (`html.duckduckgo.com`) — keyless HTML scrape. No signup, but
   fragile and rate-limited.
3. **s.jina.ai** — keyless secondary fallback.

**Page content**, in order:

1. **r.jina.ai** — reader service, returns clean markdown. Keyless.
2. **Direct GET** — raw HTML with tags stripped. Last resort.

## Optional keys

```bash
# Better search. Free tier ~1000 req/month: https://tavily.com
export TAVILY_API_KEY=tvly-...

# Optional — only raises r.jina.ai / s.jina.ai rate limits: https://jina.ai
export JINA_API_KEY=jina_...
```

Put these in your shell profile. Nothing else changes — the extension picks
Tavily up automatically, and subagents inherit the exported env from the parent
process, so the researcher gets it too.

## The `web_search` tool

| param | description |
|-------|-------------|
| `query` | the search query (be specific — model numbers, versions, years) |
| `max_results` | how many results, default 6, capped at 20 |
| `topic` | `general` (default) or `news` (biases recent) |

Output notes which backend answered, so you can tell keyless from Tavily.

## The `web_fetch` tool

| param | description |
|-------|-------------|
| `url` | absolute http(s) URL |
| `max_chars` | truncate extracted text, default 40 000, capped at 200 000 |

## Safety

- **Read-only.** GET requests only (the single exception is Tavily's POST to its
  own API). No form submission, no auth forwarding, no login-walled scraping.
- **SSRF guarded.** `localhost`, `127.*`, `0.0.0.0`, `10.*`, `192.168.*`,
  `172.16–31.*`, `169.254.*`, `::1`, link-local/unique-local IPv6, and
  `.local`/`.internal` hosts are all blocked.
- **Bounded.** 15 s timeouts (30 s for the reader), 40 KB default page cap, and
  every request honors the AbortSignal — Esc cancels in-flight work.
- **Budgeted.** The researcher prompt enforces ≤5 searches and ≤8 page fetches
  per run.
- Secrets come from env vars only, never hardcoded.

## Scope

Global: lives in `~/.pi/agent/extensions/research/`, so it's available in every
project. Reload with `/reload`.

## Known limits

- JS-only or paywalled pages may yield little text — the tool returns a clear
  error and the agent moves on.
- The DuckDuckGo scrape breaks if their HTML layout changes; s.jina.ai covers
  that, and `TAVILY_API_KEY` removes the risk entirely.
- Keyless backends rate-limit under heavy use. A failed search says so.
