/**
 * Web access helpers for the research extension.
 *
 * Dependency-free: uses the global `fetch` (Node 18+). All requests are
 * read-only GETs (Tavily is the single POST, to its own API) with a timeout
 * and AbortSignal support so Esc cancels in-flight work.
 *
 * Search backends, in order of preference:
 *   1. Tavily      — when TAVILY_API_KEY is set (structured, LLM-tuned)
 *   2. DuckDuckGo  — keyless HTML endpoint, scraped
 *   3. s.jina.ai   — keyless secondary fallback
 *
 * Page content backends:
 *   1. r.jina.ai   — reader, returns clean markdown (keyless; JINA_API_KEY optional)
 *   2. direct GET  — raw HTML with a crude tag strip, last resort
 */

const DEFAULT_TIMEOUT_MS = 15_000;
const UA =
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36";

export interface SearchHit {
	title: string;
	url: string;
	snippet: string;
}

export interface SearchOutcome {
	backend: "tavily" | "duckduckgo" | "s.jina.ai";
	hits: SearchHit[];
	/** Tavily's synthesized answer, when available. */
	answer?: string;
}

export interface FetchOutcome {
	backend: "r.jina.ai" | "direct";
	url: string;
	text: string;
}

export function hasTavily(): boolean {
	return !!process.env.TAVILY_API_KEY;
}

function jinaHeaders(extra: Record<string, string> = {}): Record<string, string> {
	const headers: Record<string, string> = { "User-Agent": UA, ...extra };
	if (process.env.JINA_API_KEY) headers.Authorization = `Bearer ${process.env.JINA_API_KEY}`;
	return headers;
}

/**
 * fetch with a hard timeout, chained to the caller's AbortSignal.
 * Throws on non-2xx so callers can fall through to the next backend.
 */
async function httpGet(
	url: string,
	init: RequestInit & { timeoutMs?: number } = {},
	signal?: AbortSignal,
): Promise<Response> {
	const { timeoutMs = DEFAULT_TIMEOUT_MS, ...rest } = init;
	const controller = new AbortController();
	const timer = setTimeout(() => controller.abort(new Error(`Timed out after ${timeoutMs}ms`)), timeoutMs);
	const onAbort = () => controller.abort(signal?.reason);
	if (signal) {
		if (signal.aborted) onAbort();
		else signal.addEventListener("abort", onAbort, { once: true });
	}
	try {
		const res = await fetch(url, { redirect: "follow", ...rest, signal: controller.signal });
		if (!res.ok) throw new Error(`HTTP ${res.status} ${res.statusText} for ${url}`);
		return res;
	} finally {
		clearTimeout(timer);
		signal?.removeEventListener("abort", onAbort);
	}
}

/* ------------------------------------------------------------------ */
/* SSRF guard                                                          */
/* ------------------------------------------------------------------ */

const PRIVATE_HOST_PATTERNS: RegExp[] = [
	/^localhost$/i,
	/^127\./,
	/^0\.0\.0\.0$/,
	/^10\./,
	/^192\.168\./,
	/^172\.(1[6-9]|2\d|3[01])\./,
	/^169\.254\./,
	/\.local$/i,
	/\.internal$/i,
];

/** Allow only public http(s) targets. Returns null when safe, else the reason. */
export function isSafeUrl(raw: string): string | null {
	let u: URL;
	try {
		u = new URL(raw);
	} catch {
		return `Not a valid URL: ${raw}`;
	}
	if (u.protocol !== "http:" && u.protocol !== "https:") {
		return `Blocked protocol '${u.protocol}'. Only http and https are allowed.`;
	}
	const host = u.hostname.replace(/^\[|\]$/g, "");
	if (host === "::1" || host === "::" || host.toLowerCase().startsWith("fe80:") || host.toLowerCase().startsWith("fc") || host.toLowerCase().startsWith("fd")) {
		return `Blocked host '${host}' (loopback/link-local/unique-local address).`;
	}
	for (const re of PRIVATE_HOST_PATTERNS) {
		if (re.test(host)) return `Blocked host '${host}' (localhost or private network address).`;
	}
	return null;
}

/* ------------------------------------------------------------------ */
/* Search backends                                                     */
/* ------------------------------------------------------------------ */

export async function tavilySearch(
	query: string,
	maxResults: number,
	topic: "general" | "news",
	signal?: AbortSignal,
): Promise<SearchOutcome> {
	const res = await httpGet(
		"https://api.tavily.com/search",
		{
			method: "POST",
			headers: { "Content-Type": "application/json", Authorization: `Bearer ${process.env.TAVILY_API_KEY}` },
			body: JSON.stringify({
				api_key: process.env.TAVILY_API_KEY,
				query,
				max_results: maxResults,
				search_depth: "basic",
				topic,
				include_answer: true,
			}),
		},
		signal,
	);
	const data = (await res.json()) as {
		answer?: string;
		results?: Array<{ title?: string; url?: string; content?: string }>;
	};
	const hits: SearchHit[] = (data.results ?? [])
		.filter((r) => r.url)
		.map((r) => ({ title: r.title?.trim() || r.url!, url: r.url!, snippet: (r.content ?? "").trim() }));
	return { backend: "tavily", hits, answer: data.answer?.trim() || undefined };
}

function decodeEntities(s: string): string {
	return s
		.replace(/&amp;/g, "&")
		.replace(/&lt;/g, "<")
		.replace(/&gt;/g, ">")
		.replace(/&quot;/g, '"')
		.replace(/&#x27;|&#39;/g, "'")
		.replace(/&nbsp;/g, " ")
		.replace(/&#(\d+);/g, (_m, d) => String.fromCharCode(Number(d)));
}

function stripTags(html: string): string {
	return decodeEntities(html.replace(/<[^>]*>/g, "")).replace(/\s+/g, " ").trim();
}

/** True for DuckDuckGo's sponsored/tracking redirect URLs, which are not real results. */
function isAdUrl(url: string): boolean {
	return (
		/(^|\/\/)(duckduckgo\.com)\/y\.js/.test(url) ||
		/[?&](ad_provider|ad_domain|ad_type)=/.test(url) ||
		/^https?:\/\/(www\.)?bing\.com\/aclick/.test(url)
	);
}

/**
 * DuckDuckGo's keyless HTML endpoint, scraped. Fragile by nature — hence fallbacks.
 * Parsed per result block so sponsored entries can be dropped without
 * desynchronising titles from snippets.
 */
export async function ddgSearch(query: string, maxResults: number, signal?: AbortSignal): Promise<SearchOutcome> {
	const res = await httpGet(
		`https://html.duckduckgo.com/html/?q=${encodeURIComponent(query)}`,
		{ headers: { "User-Agent": UA, Accept: "text/html", "Accept-Language": "en-US,en;q=0.9" } },
		signal,
	);
	const html = await res.text();

	const hits: SearchHit[] = [];
	const linkRe = /<a[^>]+class="[^"]*result__a[^"]*"[^>]+href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/;
	const snippetRe = /<a[^>]+class="[^"]*result__snippet[^"]*"[^>]*>([\s\S]*?)<\/a>/;

	// Each result lives in its own <div class="result ..."> block; ads carry result--ad.
	const blocks = html.split(/<div[^>]+class="[^"]*\bresult\b/i).slice(1);
	for (const block of blocks) {
		if (hits.length >= maxResults) break;
		if (/result--ad|badge--ad/i.test(block)) continue;

		const link = linkRe.exec(block);
		if (!link) continue;

		let href = decodeEntities(link[1]);
		if (href.startsWith("//")) href = `https:${href}`;
		// DuckDuckGo wraps results in /l/?uddg=<encoded target>
		const wrapped = href.match(/[?&]uddg=([^&]+)/);
		if (wrapped) href = decodeURIComponent(wrapped[1]);
		if (!/^https?:\/\//.test(href) || isAdUrl(href)) continue;
		if (hits.some((h) => h.url === href)) continue;

		const snip = snippetRe.exec(block);
		hits.push({ title: stripTags(link[2]) || href, url: href, snippet: snip ? stripTags(snip[1]) : "" });
	}

	if (hits.length === 0) throw new Error("DuckDuckGo returned no parseable results (layout change or rate limit).");
	return { backend: "duckduckgo", hits };
}

/** s.jina.ai — keyless search returning markdown; parsed for Title/URL/Description triples. */
export async function jinaSearch(query: string, maxResults: number, signal?: AbortSignal): Promise<SearchOutcome> {
	const res = await httpGet(
		`https://s.jina.ai/${encodeURIComponent(query)}`,
		{ headers: jinaHeaders({ Accept: "text/plain" }) },
		signal,
	);
	const text = await res.text();

	const hits: SearchHit[] = [];
	const blockRe = /\[\d+\]\s*Title:\s*(.*?)\s*\n\[\d+\]\s*URL Source:\s*(\S+)\s*\n(?:\[\d+\]\s*Description:\s*([\s\S]*?)\n)?/g;
	for (let m = blockRe.exec(text); m && hits.length < maxResults; m = blockRe.exec(text)) {
		hits.push({ title: m[1].trim(), url: m[2].trim(), snippet: (m[3] ?? "").trim() });
	}

	if (hits.length === 0) {
		// Loose fallback: any bare URLs in the response.
		const urls = [...new Set(text.match(/https?:\/\/[^\s)"'\]]+/g) ?? [])].slice(0, maxResults);
		for (const url of urls) hits.push({ title: url, url, snippet: "" });
	}
	if (hits.length === 0) throw new Error("s.jina.ai returned no parseable results.");
	return { backend: "s.jina.ai", hits };
}

/** Run search across backends, falling through on failure. */
export async function search(
	query: string,
	maxResults: number,
	topic: "general" | "news",
	signal?: AbortSignal,
): Promise<{ outcome: SearchOutcome; notes: string[] }> {
	const notes: string[] = [];
	const attempts: Array<() => Promise<SearchOutcome>> = [];

	if (hasTavily()) attempts.push(() => tavilySearch(query, maxResults, topic, signal));
	attempts.push(() => ddgSearch(query, maxResults, signal));
	attempts.push(() => jinaSearch(query, maxResults, signal));

	let lastError = "";
	for (const attempt of attempts) {
		try {
			const outcome = await attempt();
			if (outcome.hits.length > 0) return { outcome, notes };
			lastError = "backend returned zero results";
			notes.push(`${outcome.backend}: zero results, trying next backend`);
		} catch (err) {
			if (signal?.aborted) throw err;
			lastError = err instanceof Error ? err.message : String(err);
			notes.push(`fallback: ${lastError}`);
		}
	}
	throw new Error(`All search backends failed. Last error: ${lastError}`);
}

/* ------------------------------------------------------------------ */
/* Page fetch backends                                                 */
/* ------------------------------------------------------------------ */

export async function jinaFetch(url: string, signal?: AbortSignal): Promise<FetchOutcome> {
	const res = await httpGet(
		`https://r.jina.ai/${url}`,
		{ headers: jinaHeaders({ "X-Return-Format": "markdown", Accept: "text/plain" }), timeoutMs: 30_000 },
		signal,
	);
	const text = (await res.text()).trim();
	if (!text) throw new Error("r.jina.ai returned an empty document.");
	return { backend: "r.jina.ai", url, text };
}

export async function directFetch(url: string, signal?: AbortSignal): Promise<FetchOutcome> {
	const res = await httpGet(
		url,
		{ headers: { "User-Agent": UA, Accept: "text/html,application/xhtml+xml,text/plain;q=0.9" } },
		signal,
	);
	const raw = await res.text();
	const body = raw
		.replace(/<script[\s\S]*?<\/script>/gi, " ")
		.replace(/<style[\s\S]*?<\/style>/gi, " ")
		.replace(/<noscript[\s\S]*?<\/noscript>/gi, " ")
		.replace(/<!--[\s\S]*?-->/g, " ");
	const text = stripTags(body).replace(/ {2,}/g, " ").trim();
	if (!text) throw new Error("Direct fetch produced no extractable text.");
	return { backend: "direct", url, text };
}

/** Fetch page content, r.jina.ai first, raw GET as last resort. */
export async function fetchPage(
	url: string,
	signal?: AbortSignal,
): Promise<{ outcome: FetchOutcome; notes: string[] }> {
	const notes: string[] = [];
	try {
		return { outcome: await jinaFetch(url, signal), notes };
	} catch (err) {
		if (signal?.aborted) throw err;
		notes.push(`r.jina.ai failed (${err instanceof Error ? err.message : String(err)}); trying direct fetch`);
	}
	return { outcome: await directFetch(url, signal), notes };
}
