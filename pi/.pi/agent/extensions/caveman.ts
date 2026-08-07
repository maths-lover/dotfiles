/**
 * Caveman mode for pi — toggle terse "caveman-speak" to cut output tokens.
 *
 * Commands:
 *   /caveman                  toggle off <-> default level
 *   /caveman lite|full|ultra  set intensity level
 *   /caveman off|stop|disable turn off
 *   /caveman status|?         report current mode without changing it
 *
 * Default level resolves: CAVEMAN_DEFAULT_MODE env -> ~/.config/caveman/config.json
 *   ("defaultMode") -> "full". wenyan-* / commit / review / compress are out of
 *   scope in v1 and coerce to "full".
 * Ruleset source: CAVEMAN_SKILL_PATH env -> repo skills/caveman/SKILL.md ->
 *   built-in inline fallback (so caveman still works if the repo file moves).
 *
 * Personal extension: drop in ~/.pi/agent/extensions/. Hot-reload with /reload,
 * or quick-test with `pi -e ./caveman.ts`. No npm deps (node built-ins only).
 */

import { readFileSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type Mode = "off" | "lite" | "full" | "ultra";

const ENTRY_TYPE = "caveman-mode";
const STATUS_KEY = "caveman";

// Absolute path to this machine's caveman checkout (overridable via env).
const DEFAULT_SKILL_PATH = "/Users/surajp/Develop/open-source/caveman/skills/caveman/SKILL.md";

// Levels/examples that appear in SKILL.md. Used ONLY to decide which intensity
// rows/example bullets to strip. The whitelist guard means a normal bullet like
// "- Note: ..." is never mistaken for an intensity example and dropped.
const SKILL_LEVEL_TOKENS = new Set([
  "lite", "full", "ultra",
  "wenyan", "wenyan-lite", "wenyan-full", "wenyan-ultra",
]);

// Recognized caveman-ish values that mean "on-ish" but are out of v1 scope.
const RECOGNIZED_ON = new Set([
  "wenyan", "wenyan-lite", "wenyan-full", "wenyan-ultra",
  "commit", "review", "compress", "on", "true", "yes",
]);

function isMode(v: unknown): v is Mode {
  return v === "off" || v === "lite" || v === "full" || v === "ultra";
}

// Map a raw string to a v1 Mode. In-scope value -> itself; recognized but
// out-of-scope -> "full"; anything else -> null (ignored by the caller).
function coerceMode(raw: string | null | undefined): Mode | null {
  if (!raw) return null;
  const v = raw.trim().toLowerCase();
  if (!v) return null;
  if (isMode(v)) return v;
  return RECOGNIZED_ON.has(v) ? "full" : null;
}

function userConfigPath(): string {
  if (process.env.XDG_CONFIG_HOME) {
    return join(process.env.XDG_CONFIG_HOME, "caveman", "config.json");
  }
  if (process.platform === "win32") {
    const base = process.env.APPDATA || join(homedir(), "AppData", "Roaming");
    return join(base, "caveman", "config.json");
  }
  return join(homedir(), ".config", "caveman", "config.json");
}

function readUserConfigMode(): string | null {
  try {
    const parsed = JSON.parse(readFileSync(userConfigPath(), "utf8")) as { defaultMode?: unknown };
    return typeof parsed?.defaultMode === "string" ? parsed.defaultMode : null;
  } catch {
    return null; // missing/invalid config is fine
  }
}

// CAVEMAN_DEFAULT_MODE env -> user config -> "full".
function resolveDefaultMode(): Mode {
  return (
    coerceMode(process.env.CAVEMAN_DEFAULT_MODE) ??
    coerceMode(readUserConfigMode()) ??
    "full"
  );
}

function skillPath(): string {
  return process.env.CAVEMAN_SKILL_PATH || DEFAULT_SKILL_PATH;
}

// Keep only the active level's intensity table row + example bullets; drop the
// other levels (and all wenyan content). Any line that is not a recognized
// level row/example is preserved untouched.
function filterSkill(md: string, level: Mode): string {
  const body = md.replace(/^---[\s\S]*?---\s*/, ""); // strip YAML frontmatter
  const kept = body.split(/\r?\n/).filter((line) => {
    const row = line.match(/^\|\s*\*\*([\w-]+)\*\*\s*\|/); // | **lite** | ... |
    if (row) {
      const tok = row[1].toLowerCase();
      return SKILL_LEVEL_TOKENS.has(tok) ? tok === level : true;
    }
    const ex = line.match(/^-\s+([\w-]+):\s/); // - lite: "..."
    if (ex) {
      const tok = ex[1].toLowerCase();
      return SKILL_LEVEL_TOKENS.has(tok) ? tok === level : true;
    }
    return true;
  });
  return kept.join("\n").replace(/\n{3,}/g, "\n\n").trim();
}

// Self-contained ruleset used only when SKILL.md cannot be read.
function inlineFallback(level: Mode): string {
  return [
    `CAVEMAN MODE ACTIVE — level: ${level}`,
    "",
    "Respond terse like smart caveman. All technical substance stay. Only fluff die.",
    "",
    'Persistence: ACTIVE EVERY RESPONSE. No revert after many turns. No filler drift. Still active if unsure. Off only: "stop caveman" / "normal mode".',
    "",
    "Rules: drop articles (a/an/the), filler (just/really/basically/actually/simply), pleasantries (sure/certainly/of course/happy to), hedging. Fragments OK. Short synonyms (big not extensive, fix not \"implement a solution for\"). No tool-call narration, no decorative tables/emoji, no long raw error-log dumps unless asked. Standard acronyms OK (DB/API/HTTP); never invent new abbreviations. No causal arrows. Technical terms exact. Code blocks unchanged. Errors quoted exact. Preserve user's dominant language — compress the style, not the language.",
    "",
    "Pattern: [thing] [action] [reason]. [next step].",
    "",
    "Level:",
    "- lite: no filler/hedging; keep articles + full sentences; professional but tight.",
    "- full: drop articles, fragments OK, short synonyms; classic caveman.",
    "- ultra: strip conjunctions when cause/effect stays unambiguous; one word when one word enough; state each fact once.",
    "",
    "Auto-Clarity: drop caveman to normal prose for security warnings, irreversible-action confirmations, multi-step sequences where fragment order risks misread, or when user is confused/repeating. Resume after the clear part.",
    "",
    "Boundaries: code, commit messages, and PR descriptions written normal prose.",
  ].join("\n");
}

export default function cavemanExtension(pi: ExtensionAPI) {
  let currentMode: Mode = "off";
  let toggleOnLevel: Mode = "full"; // level bare /caveman turns on to

  // Read SKILL.md once per session instance; cache null on failure.
  let skillCache: string | null | undefined; // undefined = not yet read
  const loadSkillRaw = (): string | null => {
    if (skillCache === undefined) {
      try {
        skillCache = readFileSync(skillPath(), "utf8");
      } catch {
        skillCache = null;
      }
    }
    return skillCache;
  };

  const rulesetCache = new Map<Mode, string>();
  const buildRuleset = (level: Mode): string => {
    const cached = rulesetCache.get(level);
    if (cached !== undefined) return cached;
    const raw = loadSkillRaw();
    const text = raw
      ? `CAVEMAN MODE ACTIVE — level: ${level}\n\n${filterSkill(raw, level)}`
      : inlineFallback(level);
    rulesetCache.set(level, text);
    return text;
  };

  // Fire-and-forget UI, guarded for print/json mode (ctx.hasUI === false there).
  const note = (ctx: any, msg: string, level: "info" | "warning" | "error"): void => {
    if (ctx?.hasUI) ctx.ui.notify(msg, level);
  };

  const applyStatus = (ctx: any): void => {
    if (!ctx?.hasUI) return;
    if (currentMode === "off") {
      ctx.ui.setStatus(STATUS_KEY, undefined);
    } else {
      ctx.ui.setStatus(STATUS_KEY, ctx.ui.theme.fg("accent", `🦴 caveman:${currentMode}`));
    }
  };

  const setMode = (ctx: any, next: Mode, persist: boolean): void => {
    currentMode = next;
    applyStatus(ctx);
    if (persist) pi.appendEntry(ENTRY_TYPE, { mode: next });
  };

  // Most recent persisted mode on the active branch, if any.
  const restoreFromBranch = (ctx: any): Mode | null => {
    const sm = ctx?.sessionManager;
    const entries: any[] = sm?.getBranch?.() ?? sm?.getEntries?.() ?? [];
    for (let i = entries.length - 1; i >= 0; i -= 1) {
      const e = entries[i];
      if (e?.type === "custom" && e?.customType === ENTRY_TYPE && isMode(e?.data?.mode)) {
        return e.data.mode;
      }
    }
    return null;
  };

  pi.registerCommand("caveman", {
    description: "Toggle caveman terse mode — /caveman [lite|full|ultra|off|status]",
    getArgumentCompletions: (prefix: string) => {
      const opts = ["lite", "full", "ultra", "off", "status"];
      const p = prefix.trim().toLowerCase();
      const hits = opts.filter((o) => o.startsWith(p));
      return hits.length > 0 ? hits.map((o) => ({ value: o, label: o })) : null;
    },
    handler: async (args, ctx) => {
      const arg = String(args || "").trim().toLowerCase();
      let next: Mode;

      if (arg === "") {
        next = currentMode === "off" ? toggleOnLevel : "off";
      } else if (arg === "off" || arg === "stop" || arg === "disable") {
        next = "off";
      } else if (arg === "lite" || arg === "full" || arg === "ultra") {
        next = arg;
      } else if (arg === "status" || arg === "?") {
        note(
          ctx,
          `caveman: ${currentMode === "off" ? "off" : currentMode} • default ${resolveDefaultMode()}`,
          "info",
        );
        return;
      } else {
        note(ctx, `Unknown '${arg}'. Use /caveman [lite|full|ultra|off|status]`, "warning");
        return;
      }

      setMode(ctx, next, true);
      note(ctx, next === "off" ? "caveman off" : `caveman on: ${next}`, "info");
    },
  });

  // Rebuild state whenever a session starts/reloads/resumes/forks. A brand-new
  // session with no caveman entries falls back to the resolved default; a
  // resumed/forked/reloaded one restores its last persisted mode.
  pi.on("session_start", async (_event, ctx) => {
    const def = resolveDefaultMode();
    toggleOnLevel = def === "off" ? "full" : def;
    currentMode = restoreFromBranch(ctx) ?? def;
    applyStatus(ctx);
  });

  // Inject the ruleset every turn (resists mid-conversation drift + survives
  // compaction). No hasUI guard so `pi -p` / json also benefit.
  pi.on("before_agent_start", async (event) => {
    if (currentMode === "off") return undefined;
    return { systemPrompt: `${event.systemPrompt}\n\n${buildRuleset(currentMode)}` };
  });
}
