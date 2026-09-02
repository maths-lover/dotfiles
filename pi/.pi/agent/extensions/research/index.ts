/**
 * Research tools — a global pi extension giving the agent web access.
 *
 * Registers two read-only tools:
 *   web_search — find pages (Tavily when TAVILY_API_KEY is set, else keyless
 *                DuckDuckGo, else s.jina.ai)
 *   web_fetch  — read a page as clean text (r.jina.ai, else raw GET)
 *
 * Keyless by default: works with no API key at all. Exporting TAVILY_API_KEY
 * upgrades search quality with no code change. JINA_API_KEY is optional and
 * only raises the reader's rate limits.
 *
 * All network access is read-only GET (plus Tavily's own POST), guarded
 * against localhost/private addresses, with timeouts and Esc-abort support.
 */

import type { AgentToolResult } from "@earendil-works/pi-agent-core";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { StringEnum } from "@earendil-works/pi-ai";
import { Type } from "typebox";
import { fetchPage, hasTavily, isSafeUrl, search } from "./web.ts";

/** Hard cap on returned page text, so one fetch cannot blow up the context. */
const MAX_PAGE_CHARS = 40_000;

const SearchParams = Type.Object({
	query: Type.String({
		description: "The search query. Be specific — include model numbers, versions, or years when relevant.",
	}),
	max_results: Type.Optional(
		Type.Number({ description: "How many results to return. Default 6.", default: 6 }),
	),
	topic: Type.Optional(
		StringEnum(["general", "news"] as const, {
			description: "Search topic. 'news' biases toward recent articles. Default 'general'.",
			default: "general",
		}),
	),
});

const FetchParams = Type.Object({
	url: Type.String({ description: "Absolute http(s) URL of the page to read." }),
	max_chars: Type.Optional(
		Type.Number({ description: `Truncate the extracted text to this many characters. Default ${MAX_PAGE_CHARS}.` }),
	),
});

function textResult(text: string, details: Record<string, unknown> = {}, isError = false): AgentToolResult {
	return { content: [{ type: "text", text }], details, isError };
}

function errMessage(err: unknown): string {
	return err instanceof Error ? err.message : String(err);
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "web_search",
		label: "Web search",
		description:
			"Search the web and return ranked results (title, URL, snippet). Uses Tavily when TAVILY_API_KEY is set, otherwise keyless DuckDuckGo/s.jina.ai. Read-only. Follow up with web_fetch to read the most promising results.",
		promptSnippet: "web_search: search the web for current facts, specs, prices, comparisons, docs (read-only)",
		promptGuidelines: [
			"Use web_search when the user asks to look up specs, prices, comparisons, release dates, documentation, or any current fact you are not certain about — do not answer from memory alone for fast-moving topics.",
			"After web_search, call web_fetch on the most relevant results to read the actual page before answering; snippets alone are not enough for specs or comparisons.",
			"Prefer primary/official sources (manufacturer spec pages, official docs, arXiv, GitHub repos) over aggregators and SEO spam, and cite the URLs you used in your answer.",
			"For deep multi-source research, dispatch the 'researcher' subagent (or use /research) instead of doing many searches inline.",
		],
		parameters: SearchParams,

		async execute(_toolCallId, params, signal) {
			const query = params.query?.trim();
			if (!query) return textResult("web_search requires a non-empty 'query'.", {}, true);

			const maxResults = Math.max(1, Math.min(params.max_results ?? 6, 20));
			const topic = (params.topic ?? "general") as "general" | "news";

			try {
				const { outcome, notes } = await search(query, maxResults, topic, signal);
				const lines = outcome.hits
					.slice(0, maxResults)
					.map((h, i) => `${i + 1}. ${h.title}\n   ${h.url}${h.snippet ? `\n   ${h.snippet}` : ""}`);

				const header = `Search: ${query}  [backend: ${outcome.backend}${hasTavily() ? "" : ", keyless"}]`;
				const answer = outcome.answer ? `\n\nSuggested answer (unverified): ${outcome.answer}` : "";
				const noteText = notes.length ? `\n\nNotes: ${notes.join("; ")}` : "";

				return textResult(`${header}\n\n${lines.join("\n\n")}${answer}${noteText}`, {
					backend: outcome.backend,
					query,
					results: outcome.hits,
				});
			} catch (err) {
				if (signal?.aborted) return textResult("Search aborted.", {}, true);
				return textResult(
					`Search failed: ${errMessage(err)}\n\nHint: set TAVILY_API_KEY for a reliable search backend (free tier at https://tavily.com), or retry — the keyless backends rate-limit.`,
					{ query },
					true,
				);
			}
		},
	});

	pi.registerTool({
		name: "web_fetch",
		label: "Web fetch",
		description:
			"Fetch a web page and return its readable text as markdown. Uses the r.jina.ai reader, falling back to a raw GET with tags stripped. Read-only GET; localhost and private network addresses are blocked.",
		promptSnippet: "web_fetch: read a web page as clean text/markdown (read-only)",
		promptGuidelines: [
			"Use web_fetch to read a specific URL — the user's link, a search result, an official spec sheet, or a documentation page.",
			"web_fetch is GET-only and cannot log in, submit forms, or reach localhost/private addresses. If a page is paywalled or JS-only it may return little text; move on to another source instead of retrying.",
		],
		parameters: FetchParams,

		async execute(_toolCallId, params, signal) {
			const url = params.url?.trim();
			if (!url) return textResult("web_fetch requires a 'url'.", {}, true);

			const blocked = isSafeUrl(url);
			if (blocked) return textResult(blocked, { url }, true);

			const limit = Math.max(1_000, Math.min(params.max_chars ?? MAX_PAGE_CHARS, 200_000));

			try {
				const { outcome, notes } = await fetchPage(url, signal);
				const truncated = outcome.text.length > limit;
				const body = truncated
					? `${outcome.text.slice(0, limit)}\n\n[...truncated ${outcome.text.length - limit} chars]`
					: outcome.text;
				const noteText = notes.length ? ` — ${notes.join("; ")}` : "";

				return textResult(`Fetched ${outcome.url} [reader: ${outcome.backend}]${noteText}\n\n${body}`, {
					url: outcome.url,
					backend: outcome.backend,
					chars: outcome.text.length,
					truncated,
				});
			} catch (err) {
				if (signal?.aborted) return textResult("Fetch aborted.", { url }, true);
				return textResult(
					`Could not read ${url}: ${errMessage(err)}\n\nThe page may be paywalled, JS-only, or blocking bots. Try a different source.`,
					{ url },
					true,
				);
			}
		},
	});
}
