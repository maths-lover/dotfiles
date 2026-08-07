/**
 * greeter — a fast, no-LLM startup banner + /kit inventory for pi
 *
 * On startup (TUI) it replaces the header with a small ASCII-art banner and a
 * COMPACT summary of what you have available: prompts, agents, extensions and
 * skills (counts + a few names). To keep startup uncluttered when a category
 * grows, the banner only lists a handful of names inline and collapses the rest
 * into "+N more".
 *
 * For the full picture, run `/kit`: it opens a scrollable overlay listing every
 * prompt / agent / extension / skill with descriptions. It reads only the
 * filesystem — no LLM call — so it is instant.
 *
 * The `commands` category is sourced from pi's live command registry
 * (pi.getCommands()), so it lists the slash commands extensions expose
 * (e.g. /save-session, /load-session, /list-saved), not just the extension files.
 *
 * Discovery mirrors pi's own locations:
 *   prompts    : <base>/prompts/*.md            (frontmatter: description, argument-hint)
 *   agents     : <base>/agents/*.md             (frontmatter: name, description, model, tools)
 *   extensions : <base>/extensions/*.ts or <dir>/  (single file or directory)
 *   skills     : <base>/skills/<dir>/SKILL.md    (frontmatter: name, description)
 * where <base> is the global agent dir and the project-local config dir (.pi).
 *
 * Zero external dependencies (node built-ins + pi runtime exports only).
 */

import * as fs from "node:fs";
import * as path from "node:path";
import {
	CONFIG_DIR_NAME,
	type ExtensionAPI,
	type ExtensionCommandContext,
	getAgentDir,
	type SlashCommandInfo,
	type Theme,
	VERSION,
} from "@earendil-works/pi-coding-agent";
import { type Focusable, matchesKey, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const MAX_INLINE = 5; // names shown inline in the compact banner per category

type Source = "user" | "project";

interface Item {
	name: string;
	description?: string;
	meta?: string; // e.g. model/tools for agents, argument-hint for prompts
	source: Source;
}

interface Category {
	key: string;
	label: string;
	items: Item[];
}

// ---------------------------------------------------------------------------
// Small filesystem + frontmatter helpers
// ---------------------------------------------------------------------------

function readText(file: string, maxBytes = 64 * 1024): string {
	try {
		const buf = fs.readFileSync(file);
		return buf.subarray(0, maxBytes).toString("utf8");
	} catch {
		return "";
	}
}

function listDir(dir: string): fs.Dirent[] {
	try {
		return fs.readdirSync(dir, { withFileTypes: true });
	} catch {
		return [];
	}
}

function stripQuotes(s: string): string {
	const t = s.trim();
	if ((t.startsWith('"') && t.endsWith('"')) || (t.startsWith("'") && t.endsWith("'"))) {
		return t.slice(1, -1);
	}
	return t;
}

function parseFrontmatter(text: string): { fm: Record<string, string>; body: string } {
	const fm: Record<string, string> = {};
	if (!text.startsWith("---")) return { fm, body: text };
	const end = text.indexOf("\n---", 3);
	if (end < 0) return { fm, body: text };
	const raw = text.slice(3, end);
	const body = text.slice(end + 4).replace(/^[^\n]*\n/, ""); // drop remainder of closing --- line
	for (const line of raw.split("\n")) {
		const m = line.match(/^([A-Za-z0-9_-]+)\s*:\s*(.*)$/);
		if (m) fm[m[1].toLowerCase()] = stripQuotes(m[2]);
	}
	return { fm, body };
}

function firstMeaningfulLine(body: string, cap = 160): string {
	for (const raw of body.split("\n")) {
		const line = raw.trim();
		if (!line || line === "---") continue;
		return line.length > cap ? `${line.slice(0, cap - 1)}…` : line;
	}
	return "";
}

/** Best-effort one-line description for a .ts extension (first JSDoc content line). */
function sniffTsDescription(file: string): string {
	const text = readText(file, 4096);
	const lines = text.split("\n").slice(0, 40);
	let inBlock = false;
	for (const raw of lines) {
		const line = raw.trim();
		if (!inBlock && line.startsWith("/**")) {
			inBlock = true;
			const rest = line.replace(/^\/\*\*+/, "").trim();
			if (rest && rest !== "*/") return firstMeaningfulLine(rest);
			continue;
		}
		if (inBlock) {
			if (line.startsWith("*/")) break;
			const content = line.replace(/^\*+\s?/, "").trim();
			if (content) return firstMeaningfulLine(content);
		}
	}
	return "";
}

// ---------------------------------------------------------------------------
// Discovery per category
// ---------------------------------------------------------------------------

function discoverPrompts(base: string, source: Source): Item[] {
	const dir = path.join(base, "prompts");
	const out: Item[] = [];
	for (const de of listDir(dir)) {
		if (!de.isFile() || !de.name.endsWith(".md")) continue;
		const { fm, body } = parseFrontmatter(readText(path.join(dir, de.name)));
		out.push({
			name: de.name.slice(0, -3),
			description: fm.description || firstMeaningfulLine(body),
			meta: fm["argument-hint"] || undefined,
			source,
		});
	}
	return out;
}

function discoverAgents(base: string, source: Source): Item[] {
	const dir = path.join(base, "agents");
	const out: Item[] = [];
	for (const de of listDir(dir)) {
		if (!de.isFile() || !de.name.endsWith(".md")) continue;
		const { fm, body } = parseFrontmatter(readText(path.join(dir, de.name)));
		const metaBits = [fm.model, fm.tools ? `tools: ${fm.tools}` : ""].filter(Boolean);
		out.push({
			name: fm.name || de.name.slice(0, -3),
			description: fm.description || firstMeaningfulLine(body),
			meta: metaBits.join(" · ") || undefined,
			source,
		});
	}
	return out;
}

function discoverSkills(base: string, source: Source): Item[] {
	const dir = path.join(base, "skills");
	const out: Item[] = [];
	for (const de of listDir(dir)) {
		if (!de.isDirectory()) continue;
		const skillFile = path.join(dir, de.name, "SKILL.md");
		if (!fs.existsSync(skillFile)) continue;
		const { fm, body } = parseFrontmatter(readText(skillFile));
		out.push({
			name: fm.name || de.name,
			description: fm.description || firstMeaningfulLine(body),
			source,
		});
	}
	return out;
}

function discoverExtensions(base: string, source: Source): Item[] {
	const dir = path.join(base, "extensions");
	const out: Item[] = [];
	for (const de of listDir(dir)) {
		if (de.name.startsWith(".")) continue;
		if (de.isFile()) {
			if (!de.name.endsWith(".ts") || de.name.endsWith(".d.ts")) continue;
			out.push({ name: de.name.slice(0, -3), description: sniffTsDescription(path.join(dir, de.name)), source });
		} else if (de.isDirectory()) {
			const extDir = path.join(dir, de.name);
			let description = "";
			const pkg = path.join(extDir, "package.json");
			if (fs.existsSync(pkg)) {
				try {
					description = JSON.parse(readText(pkg)).description || "";
				} catch {
					/* ignore */
				}
			}
			if (!description && fs.existsSync(path.join(extDir, "README.md"))) {
				const { body } = parseFrontmatter(readText(path.join(extDir, "README.md")));
				description = firstMeaningfulLine(body.replace(/^#+\s*/gm, ""));
			}
			if (!description) {
				for (const entry of ["index.ts", "main.ts"]) {
					const f = path.join(extDir, entry);
					if (fs.existsSync(f)) {
						description = sniffTsDescription(f);
						if (description) break;
					}
				}
			}
			out.push({ name: de.name, description, source });
		}
	}
	return out;
}

/** Derive a readable extension name from a command's source metadata. */
function extNameFromSource(si: SlashCommandInfo["sourceInfo"] | undefined): string {
	const p = si?.path ?? "";
	let base = path.basename(p);
	if (/^index\.(ts|js|mjs|cjs)$/.test(base)) base = path.basename(path.dirname(p));
	base = base.replace(/\.(ts|js|mjs|cjs)$/, "");
	return base || si?.source || "extension";
}

/** Slash commands registered by extensions (as `/name`), with providing extension. */
function discoverCommands(commands: SlashCommandInfo[]): Item[] {
	return commands
		.filter((c) => c.source === "extension")
		.map((c) => ({
			name: `/${c.name}`,
			description: c.description,
			meta: `from ${extNameFromSource(c.sourceInfo)}`,
			source: (c.sourceInfo?.scope === "project" ? "project" : "user") as Source,
		}))
		.sort((a, b) => a.name.localeCompare(b.name));
}

/** Merge user + project items, sorted by name (project entries kept distinct). */
function mergeSorted(user: Item[], project: Item[]): Item[] {
	return [...user, ...project].sort((a, b) => a.name.localeCompare(b.name));
}

function discoverInventory(cwd: string, commands: SlashCommandInfo[]): Category[] {
	const userBase = getAgentDir();
	const projectBase = path.join(cwd, CONFIG_DIR_NAME);
	const hasProject = fs.existsSync(projectBase) && path.resolve(projectBase) !== path.resolve(userBase);

	const build = (fn: (base: string, src: Source) => Item[]) =>
		mergeSorted(fn(userBase, "user"), hasProject ? fn(projectBase, "project") : []);

	return [
		{ key: "commands", label: "commands", items: discoverCommands(commands) },
		{ key: "prompts", label: "prompts", items: build(discoverPrompts) },
		{ key: "agents", label: "agents", items: build(discoverAgents) },
		{ key: "extensions", label: "extensions", items: build(discoverExtensions) },
		{ key: "skills", label: "skills", items: build(discoverSkills) },
	];
}

/** Query pi's live command registry, tolerating any mode where it is unavailable. */
function safeGetCommands(pi: ExtensionAPI): SlashCommandInfo[] {
	try {
		return pi.getCommands() ?? [];
	} catch {
		return [];
	}
}

// ---------------------------------------------------------------------------
// ASCII art + banner (compact) rendering
// ---------------------------------------------------------------------------

function asciiArt(theme: Theme): string[] {
	const sun = (s: string) => theme.fg("warning", s); // rising sun + rays
	const rock = (s: string) => theme.fg("accent", s); // mountain rock
	const snow = (s: string) => theme.fg("text", s); // snow caps
	return [
		"",
		sun("         \\    |    /"),
		sun("       '-.  .---.  .-'"),
		sun("          ( █████ )"),
		snow("       /\\") + sun("  `-----'  ") + snow("/\\"),
		rock("      /  \\   ") + snow("/\\") + rock("    /  \\"),
		rock("     /    \\ /  \\  /    \\"),
		rock("    /______V____\\/______\\"),
	];
}

/** Compact banner lines for the header (clipped to width). */
function bannerLines(theme: Theme, width: number, inv: Category[]): string[] {
	const lines = asciiArt(theme);
	lines.push("");
	lines.push(`  ${theme.fg("accent", "π  your pi loadout")}  ${theme.fg("dim", `v${VERSION}`)}`);

	for (const cat of inv) {
		const names = cat.items.map((i) => i.name);
		const shown = names.slice(0, MAX_INLINE);
		const more = names.length - shown.length;
		const label = theme.fg("muted", `  ${cat.label} (${cat.items.length})`);
		if (names.length === 0) {
			lines.push(`${label}${theme.fg("dim", " —")}`);
		} else {
			const value = theme.fg("text", shown.join(", ")) + (more > 0 ? theme.fg("dim", ` +${more} more`) : "");
			lines.push(`${label}${theme.fg("muted", ": ")}${value}`);
		}
	}

	lines.push("");
	lines.push(theme.fg("dim", "  /kit — full list · Ctrl+P model · Ctrl+C exit"));
	return lines.map((l) => truncateToWidth(l, Math.max(1, width)));
}

// ---------------------------------------------------------------------------
// Full /kit listing (used by overlay + text fallback)
// ---------------------------------------------------------------------------

function wrapPlain(text: string, width: number): string[] {
	if (!text) return [];
	const words = text.split(/\s+/);
	const out: string[] = [];
	let cur = "";
	for (const w of words) {
		if (!cur) cur = w;
		else if (visibleWidth(cur) + 1 + visibleWidth(w) <= width) cur += ` ${w}`;
		else {
			out.push(cur);
			cur = w;
		}
	}
	if (cur) out.push(cur);
	return out;
}

/** Rich, colored lines for the overlay. contentWidth = max visible width per line. */
function kitLines(theme: Theme, contentWidth: number, inv: Category[]): string[] {
	const lines: string[] = [];
	const total = inv.reduce((n, c) => n + c.items.length, 0);
	lines.push(`${theme.fg("accent", "π  your pi loadout")}  ${theme.fg("dim", `v${VERSION} · ${total} items`)}`);
	lines.push("");

	for (const cat of inv) {
		lines.push(theme.fg("toolTitle", `▸ ${cat.label}  `) + theme.fg("dim", `(${cat.items.length})`));
		if (cat.items.length === 0) {
			lines.push(theme.fg("dim", "    (none)"));
		} else {
			for (const item of cat.items) {
				const tag = item.source === "project" ? theme.fg("warning", " ·project") : "";
				lines.push(`  ${theme.fg("success", "•")} ${theme.fg("text", item.name)}${tag}`);
				for (const wl of wrapPlain(item.description ?? "", contentWidth - 6)) {
					lines.push(theme.fg("muted", `      ${wl}`));
				}
				if (item.meta) lines.push(theme.fg("dim", `      ${item.meta}`));
			}
		}
		lines.push("");
	}
	if (lines[lines.length - 1] === "") lines.pop();
	return lines;
}

/** Plain (uncolored) text used for the non-TUI fallback via notify. */
function kitPlainText(inv: Category[]): string {
	const parts: string[] = ["π your pi loadout"];
	for (const cat of inv) {
		parts.push(`\n${cat.label} (${cat.items.length}):`);
		if (cat.items.length === 0) parts.push("  (none)");
		else for (const item of cat.items) parts.push(`  • ${item.name}${item.description ? ` — ${item.description}` : ""}`);
	}
	return parts.join("\n");
}

// ---------------------------------------------------------------------------
// Scrollable overlay component
// ---------------------------------------------------------------------------

class KitOverlay implements Focusable {
	focused = false;
	readonly width: number;
	private readonly innerW: number;
	private readonly viewport: number;
	private scrollTop = 0;

	private readonly lines: string[];

	constructor(
		private readonly theme: Theme,
		inv: Category[],
		private readonly done: () => void,
	) {
		const cols = process.stdout.columns || 100;
		const rows = process.stdout.rows || 30;
		this.width = Math.max(40, Math.min(cols - 4, 100));
		this.innerW = this.width - 2;
		// Build wrapped content to match the real inner width (leading space + margin).
		this.lines = kitLines(theme, this.innerW - 2, inv);
		// leave room for top/title/sep/footer/bottom borders (~5 rows)
		this.viewport = Math.max(6, Math.min(this.lines.length, rows - 8));
	}

	private get maxTop(): number {
		return Math.max(0, this.lines.length - this.viewport);
	}

	handleInput(data: string): void {
		if (matchesKey(data, "escape") || matchesKey(data, "return") || data === "q") {
			this.done();
			return;
		}
		if (matchesKey(data, "up") || data === "k") this.scrollTop = Math.max(0, this.scrollTop - 1);
		else if (matchesKey(data, "down") || data === "j") this.scrollTop = Math.min(this.maxTop, this.scrollTop + 1);
		else if (matchesKey(data, "pageup")) this.scrollTop = Math.max(0, this.scrollTop - this.viewport);
		else if (matchesKey(data, "pagedown") || data === " ")
			this.scrollTop = Math.min(this.maxTop, this.scrollTop + this.viewport);
		else if (matchesKey(data, "home") || data === "g") this.scrollTop = 0;
		else if (matchesKey(data, "end") || data === "G") this.scrollTop = this.maxTop;
	}

	render(_width: number): string[] {
		const th = this.theme;
		const border = (s: string) => th.fg("border", s);
		const pad = (s: string) => {
			const clipped = truncateToWidth(s, this.innerW);
			return clipped + " ".repeat(Math.max(0, this.innerW - visibleWidth(clipped)));
		};
		const row = (content: string) => border("│") + pad(content) + border("│");

		const out: string[] = [];
		out.push(border(`╭${"─".repeat(this.innerW)}╮`));
		out.push(row(` ${th.fg("accent", "🎒 /kit")}${th.fg("dim", "  what you have at your disposal")}`));
		out.push(border(`├${"─".repeat(this.innerW)}┤`));

		const window = this.lines.slice(this.scrollTop, this.scrollTop + this.viewport);
		for (let i = 0; i < this.viewport; i++) out.push(row(` ${window[i] ?? ""}`));

		out.push(border(`├${"─".repeat(this.innerW)}┤`));
		const first = this.lines.length === 0 ? 0 : this.scrollTop + 1;
		const last = Math.min(this.lines.length, this.scrollTop + this.viewport);
		const canScroll = this.maxTop > 0;
		const pos = th.fg("dim", `${first}–${last}/${this.lines.length}`);
		const hint = th.fg("dim", canScroll ? "↑↓/jk · PgUp/PgDn · g/G · Esc" : "Esc to close");
		out.push(row(` ${pos}   ${hint}`));
		out.push(border(`╰${"─".repeat(this.innerW)}╯`));
		return out;
	}

	invalidate(): void {}
	dispose(): void {}
}

// ---------------------------------------------------------------------------
// Extension entry point
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
	// Startup banner (TUI only): replace the header with ASCII art + compact list.
	pi.on("session_start", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		const inv = discoverInventory(ctx.cwd, safeGetCommands(pi)); // cheap fs + registry reads, no LLM
		ctx.ui.setHeader((_tui, theme) => ({
			render: (width: number) => bannerLines(theme, width, inv),
			invalidate() {},
		}));
	});

	// /kit — full, instant, no-LLM inventory.
	pi.registerCommand("kit", {
		description: "Show all prompts, agents, extensions and skills at your disposal (no LLM).",
		handler: async (_args, ctx: ExtensionCommandContext) => {
			const inv = discoverInventory(ctx.cwd, safeGetCommands(pi));

			if (ctx.mode !== "tui") {
				// print / json / rpc: emit a compact text summary.
				ctx.ui.notify(kitPlainText(inv), "info");
				return;
			}

			await ctx.ui.custom<void>(
				(_tui, theme, _keybindings, done) => new KitOverlay(theme, inv, () => done()),
				{ overlay: true },
			);
		},
	});
}
