/**
 * save-session — durable, portable session bundles for pi
 *
 * Commands:
 *   /save-session [name]    Copy the current session verbatim into a durable
 *                           bundle under ~/.pi/agent/saved-sessions/<slug>/.
 *   /load-session [name]    Restore a saved bundle into the CURRENT directory as
 *                           a fresh fork (full history, saved copy stays pristine).
 *   /list-saved             Browse saved bundles and optionally load one.
 *   /delete-session [name]  Delete a saved bundle (with confirmation).
 *
 * Design notes (verified against pi 0.82.1):
 *  - A bundle is a byte-for-byte copy of the session .jsonl (whole tree: all
 *    branches, inline images, model/thinking changes) + a manifest.json sidecar.
 *    This survives even if the original live session is deleted.
 *  - Restore uses SessionManager.forkFrom(bundleJsonl, cwd): it copies all
 *    entries inline into a NEW in-project session file and sets that file's
 *    header.parentSession -> the bundle (native lineage). The saved bundle is
 *    only ever read, so repeated loads each yield an independent working copy —
 *    letting you try different strategies from the same starting point.
 *  - Chaining: because pi's fork/restore embeds a parent's full history into the
 *    child, a child bundle is already self-contained. On save we additionally
 *    walk header.parentSession to durably copy each ancestor as its own bundle
 *    (deduped by source session id) and record the lineage graph in the manifest,
 *    so ancestors like "session1" remain independently restorable and traceable.
 *
 * Zero external dependencies (node built-ins + pi runtime exports only).
 */

import * as fs from "node:fs";
import * as path from "node:path";
import {
	type ExtensionAPI,
	type ExtensionCommandContext,
	getAgentDir,
	SessionManager,
} from "@earendil-works/pi-coding-agent";
import type { AutocompleteItem } from "@earendil-works/pi-tui";

const SCHEMA_VERSION = 1 as const;
const SAVED_DIRNAME = "saved-sessions";
const SESSION_FILE = "session.jsonl";
const MANIFEST_FILE = "manifest.json";

interface AncestorRef {
	slug: string;
	sourceId: string;
	name: string;
}

interface SavedManifest {
	schemaVersion: number;
	name: string;
	slug: string;
	savedAt: string; // ISO timestamp
	/** true when auto-captured as an ancestor of an explicitly saved session. */
	auto: boolean;
	source: {
		sessionFile: string; // original live session file path at save time
		sessionId: string; // session header id (matches the copied .jsonl header)
		cwd: string;
		displayName?: string;
		messageCount: number;
	};
	lineage: {
		/** original path recorded in the source header (may dangle if lost). */
		parentSessionFile?: string;
		/** slug of the durable ancestor bundle for the immediate parent. */
		parentSlug?: string;
		/** source session id of the immediate parent. */
		parentSourceId?: string;
		/** full ancestor chain, root -> immediate-parent order. */
		ancestors: AncestorRef[];
	};
}

// ---------------------------------------------------------------------------
// Filesystem helpers
// ---------------------------------------------------------------------------

function savedDir(): string {
	return path.join(getAgentDir(), SAVED_DIRNAME);
}

function bundleDir(slug: string): string {
	return path.join(savedDir(), slug);
}

function slugify(name: string): string {
	const slug = name
		.trim()
		.toLowerCase()
		.replace(/[^a-z0-9._-]+/g, "-") // fs-unsafe -> dash
		.replace(/-+/g, "-") // collapse dashes
		.replace(/^[-._]+|[-._]+$/g, ""); // trim leading/trailing separators
	return slug || "session";
}

function fmtDate(iso: string): string {
	const d = new Date(iso);
	return Number.isNaN(d.getTime()) ? iso : d.toLocaleString();
}

function timestampSlug(): string {
	// e.g. 20240815-142530
	const d = new Date();
	const p = (n: number) => String(n).padStart(2, "0");
	return `${d.getFullYear()}${p(d.getMonth() + 1)}${p(d.getDate())}-${p(d.getHours())}${p(d.getMinutes())}${p(d.getSeconds())}`;
}

interface SessionInspection {
	header: { id: string; cwd: string; parentSession?: string } | null;
	messageCount: number;
	displayName?: string;
}

/** Read a session .jsonl once, returning its header, message count and latest name. */
function inspectSession(file: string): SessionInspection {
	const result: SessionInspection = { header: null, messageCount: 0 };
	let text: string;
	try {
		text = fs.readFileSync(file, "utf8");
	} catch {
		return result;
	}
	for (const line of text.split("\n")) {
		if (!line.trim()) continue;
		let entry: any;
		try {
			entry = JSON.parse(line);
		} catch {
			continue;
		}
		if (entry.type === "session") {
			result.header = { id: entry.id, cwd: entry.cwd, parentSession: entry.parentSession };
		} else if (entry.type === "message") {
			result.messageCount++;
		} else if (entry.type === "session_info" && typeof entry.name === "string" && entry.name) {
			result.displayName = entry.name; // last one wins
		}
	}
	return result;
}

function readManifest(slug: string): SavedManifest | null {
	const file = path.join(bundleDir(slug), MANIFEST_FILE);
	try {
		const parsed = JSON.parse(fs.readFileSync(file, "utf8"));
		if (parsed && typeof parsed.slug === "string" && typeof parsed.name === "string") {
			if (!parsed.lineage) parsed.lineage = { ancestors: [] };
			if (!Array.isArray(parsed.lineage.ancestors)) parsed.lineage.ancestors = [];
			return parsed as SavedManifest;
		}
	} catch {
		/* ignore malformed / missing */
	}
	return null;
}

function writeManifest(manifest: SavedManifest): void {
	const dir = bundleDir(manifest.slug);
	fs.mkdirSync(dir, { recursive: true });
	fs.writeFileSync(path.join(dir, MANIFEST_FILE), `${JSON.stringify(manifest, null, 2)}\n`);
}

/** All valid bundles (must have both manifest.json and session.jsonl), newest first. */
function listSaved(): SavedManifest[] {
	const root = savedDir();
	let dirents: fs.Dirent[];
	try {
		dirents = fs.readdirSync(root, { withFileTypes: true });
	} catch {
		return []; // dir does not exist yet
	}
	const out: SavedManifest[] = [];
	for (const de of dirents) {
		if (!de.isDirectory()) continue;
		const manifest = readManifest(de.name);
		if (!manifest) continue;
		if (!fs.existsSync(path.join(bundleDir(de.name), SESSION_FILE))) continue;
		// Trust the directory name as the canonical slug.
		manifest.slug = de.name;
		out.push(manifest);
	}
	out.sort((a, b) => (a.savedAt < b.savedAt ? 1 : a.savedAt > b.savedAt ? -1 : 0));
	return out;
}

function findBySourceId(id: string): SavedManifest | undefined {
	return listSaved().find((m) => m.source?.sessionId === id);
}

// ---------------------------------------------------------------------------
// Display + selection
// ---------------------------------------------------------------------------

/** Human-readable, GUARANTEED-UNIQUE row (slug suffix makes it unique). */
function rowLabel(m: SavedManifest): string {
	const parts = [m.name, `${m.source.messageCount} msg${m.source.messageCount === 1 ? "" : "s"}`, fmtDate(m.savedAt)];
	if (m.lineage.ancestors.length > 0) parts.push(`chain:${m.lineage.ancestors.length + 1}`);
	if (m.auto) parts.push("auto");
	return `${parts.join(" · ")}  (${m.slug})`;
}

function completionsFor(prefix: string): AutocompleteItem[] {
	const q = prefix.trim().toLowerCase();
	return listSaved()
		.filter((m) => !q || m.slug.toLowerCase().startsWith(q) || m.name.toLowerCase().includes(q))
		.map((m) => ({
			value: m.slug,
			label: m.name,
			description: `${m.source.messageCount} msgs · ${fmtDate(m.savedAt)}${m.auto ? " · auto" : ""}`,
		}));
}

/**
 * Resolve a bundle slug from a command argument, falling back to an interactive
 * picker. Returns undefined when nothing is chosen / found.
 */
async function resolveTargetSlug(args: string, ctx: ExtensionCommandContext, pickerTitle: string): Promise<string | undefined> {
	const saved = listSaved();
	if (saved.length === 0) return undefined;
	const q = args.trim();

	if (q) {
		const exact = saved.find((m) => m.slug === q) ?? saved.find((m) => m.name === q);
		if (exact) return exact.slug;
		const needle = q.toLowerCase();
		const fuzzy = saved.filter((m) => m.slug.includes(slugify(q)) || m.name.toLowerCase().includes(needle));
		if (fuzzy.length === 1) return fuzzy[0].slug;
		if (!ctx.hasUI) return undefined;
		const pool = fuzzy.length > 0 ? fuzzy : saved;
		const options = pool.map(rowLabel);
		const choice = await ctx.ui.select(pickerTitle, options);
		if (!choice) return undefined;
		return pool[options.indexOf(choice)]?.slug;
	}

	if (!ctx.hasUI) return undefined;
	const options = saved.map(rowLabel);
	const choice = await ctx.ui.select(pickerTitle, options);
	if (!choice) return undefined;
	return saved[options.indexOf(choice)]?.slug;
}

// ---------------------------------------------------------------------------
// Chained-session lineage capture (Phase 2)
// ---------------------------------------------------------------------------

/** Does a bundle dir already exist for `slug` but belong to a DIFFERENT source? */
function slugTakenByOther(slug: string, sourceId: string): boolean {
	const existing = readManifest(slug);
	return existing != null && existing.source?.sessionId !== sourceId;
}

/**
 * Walk source header's parentSession chain, durably copying each ancestor into
 * its own bundle (deduped by source session id) and recording the lineage graph
 * on `child`. Ancestors are stored root -> immediate-parent order.
 */
function captureAncestors(child: SavedManifest, firstParentRef: string | undefined): void {
	const chain: AncestorRef[] = []; // collected parent -> root, reversed at end
	const seen = new Set<string>(); // cycle guard by source id
	let parentRef = firstParentRef;
	let isImmediateParent = true;

	while (parentRef) {
		const resolved = path.resolve(parentRef);
		if (!fs.existsSync(resolved)) break; // ancestor lost; child stays self-contained
		const info = inspectSession(resolved);
		if (!info.header) break;
		const ancestorId = info.header.id;
		if (seen.has(ancestorId)) break;
		seen.add(ancestorId);

		let bundle = findBySourceId(ancestorId);
		if (!bundle) {
			const baseName = info.displayName || `ancestor-${ancestorId.slice(0, 8)}`;
			let slug = slugify(baseName);
			if (slugTakenByOther(slug, ancestorId)) slug = `${slug}-${ancestorId.slice(0, 8)}`;
			fs.mkdirSync(bundleDir(slug), { recursive: true });
			fs.copyFileSync(resolved, path.join(bundleDir(slug), SESSION_FILE));
			bundle = {
				schemaVersion: SCHEMA_VERSION,
				name: baseName,
				slug,
				savedAt: new Date().toISOString(),
				auto: true,
				source: {
					sessionFile: resolved,
					sessionId: ancestorId,
					cwd: info.header.cwd,
					displayName: info.displayName,
					messageCount: info.messageCount,
				},
				lineage: { parentSessionFile: info.header.parentSession, ancestors: [] },
			};
			writeManifest(bundle);
		}

		if (isImmediateParent) {
			child.lineage.parentSlug = bundle.slug;
			child.lineage.parentSourceId = ancestorId;
			child.lineage.parentSessionFile = resolved;
			isImmediateParent = false;
		}
		chain.push({ slug: bundle.slug, sourceId: ancestorId, name: bundle.name });
		parentRef = info.header.parentSession;
	}

	child.lineage.ancestors = chain.reverse();
}

// ---------------------------------------------------------------------------
// Load routine (shared by /load-session and /list-saved)
// ---------------------------------------------------------------------------

async function loadSlug(slug: string, ctx: ExtensionCommandContext): Promise<void> {
	const manifest = readManifest(slug);
	if (!manifest) {
		ctx.ui.notify(`Saved session not found: ${slug}`, "error");
		return;
	}
	const jsonl = path.join(bundleDir(slug), SESSION_FILE);
	if (!fs.existsSync(jsonl)) {
		ctx.ui.notify(`Bundle '${slug}' is missing its ${SESSION_FILE}`, "error");
		return;
	}

	// forkFrom copies the whole tree into a fresh in-project session file and
	// sets its header.parentSession -> the bundle (native lineage). The bundle
	// itself is never mutated.
	let forked: SessionManager;
	try {
		forked = SessionManager.forkFrom(jsonl, ctx.cwd);
	} catch (err) {
		ctx.ui.notify(`Failed to restore '${manifest.name}': ${(err as Error).message}`, "error");
		return;
	}

	// Set the display name on the detached manager BEFORE switching (persists
	// synchronously). Never touch the command ctx after a successful switch.
	forked.appendSessionInfo(`restored: ${manifest.name}`);
	const newPath = forked.getSessionFile();
	if (!newPath) {
		ctx.ui.notify("Restore failed: forked session has no file path", "error");
		return;
	}

	const chainNames = [...manifest.lineage.ancestors.map((a) => a.name), manifest.name];
	const chainNote = manifest.lineage.ancestors.length > 0 ? ` (chain: ${chainNames.join(" → ")})` : "";

	const res = await ctx.switchSession(newPath, {
		withSession: async (rctx) => {
			rctx.ui.notify(`Restored '${manifest.name}'${chainNote}`, "info");
		},
	});
	if (res.cancelled) {
		// No switch happened, so the original ctx is still valid here.
		ctx.ui.notify("Restore cancelled", "warning");
	}
}

// ---------------------------------------------------------------------------
// Extension entry point
// ---------------------------------------------------------------------------

export default function (pi: ExtensionAPI) {
	// /save-session [name]
	pi.registerCommand("save-session", {
		description: "Save the current session to a durable, portable bundle. Usage: /save-session [name]",
		handler: async (args, ctx) => {
			const sessionFile = ctx.sessionManager.getSessionFile();
			if (!sessionFile) {
				ctx.ui.notify("No persisted session to save (this session is ephemeral).", "warning");
				return;
			}

			// Ensure the live .jsonl is fully flushed before we copy it.
			await ctx.waitForIdle();

			const info = inspectSession(sessionFile);
			if (!info.header) {
				ctx.ui.notify("Could not read the current session file.", "error");
				return;
			}

			const fallback = `session-${info.header.id.slice(0, 8)}-${timestampSlug()}`;
			const name = args.trim() || ctx.sessionManager.getSessionName() || info.displayName || fallback;
			const slug = slugify(name);
			const dir = bundleDir(slug);

			if (fs.existsSync(dir)) {
				if (!ctx.hasUI) {
					ctx.ui.notify(`A saved session '${slug}' already exists (refusing to overwrite without UI).`, "warning");
					return;
				}
				const ok = await ctx.ui.confirm("Overwrite saved session?", `'${slug}' already exists. Replace it?`);
				if (!ok) {
					ctx.ui.notify("Save cancelled.", "info");
					return;
				}
				fs.rmSync(dir, { recursive: true, force: true });
			}

			fs.mkdirSync(dir, { recursive: true });
			fs.copyFileSync(sessionFile, path.join(dir, SESSION_FILE));

			const manifest: SavedManifest = {
				schemaVersion: SCHEMA_VERSION,
				name,
				slug,
				savedAt: new Date().toISOString(),
				auto: false,
				source: {
					sessionFile,
					sessionId: info.header.id,
					cwd: info.header.cwd,
					displayName: info.displayName,
					messageCount: info.messageCount,
				},
				lineage: { parentSessionFile: info.header.parentSession, ancestors: [] },
			};

			// Phase 2: durably capture the ancestor chain (if any).
			if (info.header.parentSession) {
				try {
					captureAncestors(manifest, info.header.parentSession);
				} catch (err) {
					ctx.ui.notify(`Saved, but ancestor capture failed: ${(err as Error).message}`, "warning");
				}
			}

			writeManifest(manifest);

			const chainNote =
				manifest.lineage.ancestors.length > 0
					? ` · captured ${manifest.lineage.ancestors.length} ancestor${manifest.lineage.ancestors.length === 1 ? "" : "s"}`
					: "";
			ctx.ui.notify(`Saved '${name}' (${info.messageCount} msgs)${chainNote} → ${dir}`, "info");
		},
	});

	// /load-session [name]
	pi.registerCommand("load-session", {
		description: "Restore a saved session into the current directory. Usage: /load-session [name]",
		getArgumentCompletions: (prefix) => completionsFor(prefix),
		handler: async (args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("/load-session requires interactive UI.", "warning");
				return;
			}
			const slug = await resolveTargetSlug(args, ctx, "Restore which saved session?");
			if (!slug) {
				ctx.ui.notify(args.trim() ? `No saved session matches '${args.trim()}'.` : "No saved sessions found.", "warning");
				return;
			}
			await loadSlug(slug, ctx);
		},
	});

	// /list-saved
	pi.registerCommand("list-saved", {
		description: "List saved sessions and optionally restore one.",
		handler: async (_args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("/list-saved requires interactive UI.", "warning");
				return;
			}
			const saved = listSaved();
			if (saved.length === 0) {
				ctx.ui.notify("No saved sessions yet. Use /save-session to create one.", "info");
				return;
			}
			const options = saved.map(rowLabel);
			const choice = await ctx.ui.select("Saved sessions", options);
			if (!choice) return;
			const picked = saved[options.indexOf(choice)];
			if (!picked) return;
			const ok = await ctx.ui.confirm("Restore session?", `Restore '${picked.name}' into ${ctx.cwd}?`);
			if (!ok) return;
			await loadSlug(picked.slug, ctx);
		},
	});

	// /delete-session [name]
	pi.registerCommand("delete-session", {
		description: "Delete a saved session bundle. Usage: /delete-session [name]",
		getArgumentCompletions: (prefix) => completionsFor(prefix),
		handler: async (args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("/delete-session requires interactive UI.", "warning");
				return;
			}
			const slug = await resolveTargetSlug(args, ctx, "Delete which saved session?");
			if (!slug) {
				ctx.ui.notify(args.trim() ? `No saved session matches '${args.trim()}'.` : "No saved sessions found.", "warning");
				return;
			}
			const manifest = readManifest(slug);
			const displayName = manifest?.name ?? slug;
			const dependents = listSaved().filter((m) => m.lineage.parentSlug === slug);
			const warn =
				dependents.length > 0
					? `\n\nNote: ${dependents.length} saved session(s) reference this as an ancestor (${dependents
							.map((d) => d.name)
							.join(", ")}). They stay restorable — their history is embedded — but lose this lineage node.`
					: "";
			const ok = await ctx.ui.confirm("Delete saved session?", `Delete '${displayName}'? This cannot be undone.${warn}`);
			if (!ok) return;
			fs.rmSync(bundleDir(slug), { recursive: true, force: true });
			ctx.ui.notify(`Deleted '${displayName}'.`, "info");
		},
	});
}
