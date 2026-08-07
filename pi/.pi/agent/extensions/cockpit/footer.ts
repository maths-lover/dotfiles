/**
 * cockpit/footer — a context-rich status line that replaces pi's default footer.
 *
 * Shows, on a single logical line (wrapped to at most two rows on narrow
 * terminals): session input/output tokens and cost, context-window usage
 * (percent + used/window with warn/error color as it fills), the active model
 * and thinking level, and the git branch. Any other extension statuses set via
 * ctx.ui.setStatus() (e.g. caveman) are appended so nothing is clobbered.
 *
 * Token/cost totals are summed from ctx.sessionManager.getBranch() assistant
 * messages; context usage from ctx.getContextUsage(); model/thinking from
 * ctx/pi; branch + statuses from the footerData provider (reactive via
 * onBranchChange). Colors are read from the live theme each render so theme
 * switches apply immediately.
 *
 * Zero external dependencies (node built-ins + pi runtime exports only).
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext, ReadonlyFooterDataProvider, Theme, ThemeColor } from "@earendil-works/pi-coding-agent";
import { type Component, truncateToWidth, type TUI, wrapTextWithAnsi } from "@earendil-works/pi-tui";

const fmt = (n: number): string => (n < 1000 ? `${n}` : `${(n / 1000).toFixed(1)}k`);

/** Build the footer factory for ctx.ui.setFooter(). */
export function makeFooter(
	pi: ExtensionAPI,
	ctx: ExtensionContext,
	onTui: (tui: TUI) => void,
): (tui: TUI, theme: Theme, footerData: ReadonlyFooterDataProvider) => Component & { dispose?: () => void } {
	return (tui, theme, footerData) => {
		onTui(tui);
		const unsub = footerData.onBranchChange(() => tui.requestRender());

		return {
			dispose: unsub,
			invalidate() {},
			render(width: number): string[] {
				let input = 0;
				let output = 0;
				let cost = 0;
				for (const e of ctx.sessionManager.getBranch()) {
					if (e.type === "message" && e.message.role === "assistant") {
						const m = e.message as AssistantMessage;
						input += m.usage.input;
						output += m.usage.output;
						cost += m.usage.cost.total;
					}
				}

				const usage = ctx.getContextUsage();
				const pct = usage?.percent ?? null;
				const used = usage?.tokens ?? null;
				const win = usage?.contextWindow ?? ctx.model?.contextWindow ?? 0;

				let ctxColor: ThemeColor = "dim";
				if (pct !== null) ctxColor = pct >= 95 ? "error" : pct >= 80 ? "warning" : "muted";
				const ctxStr = pct === null ? "—" : `${Math.round(pct)}%`;
				const usedStr = used === null ? "—" : fmt(used);

				const sep = theme.fg("dim", " · ");
				const segs = [
					theme.fg("dim", `↑${fmt(input)} ↓${fmt(output)} $${cost.toFixed(3)}`),
					theme.fg(ctxColor, `${ctxStr} ${usedStr}/${fmt(win)}`),
					theme.fg("dim", `${ctx.model?.id ?? "no-model"} ${pi.getThinkingLevel()}`),
				];
				const branch = footerData.getGitBranch();
				if (branch) segs.push(theme.fg("dim", `(${branch})`));

				const statuses = [...footerData.getExtensionStatuses().values()];
				let line = segs.join(sep);
				if (statuses.length > 0) line += sep + statuses.join(sep);

				return wrapTextWithAnsi(line, width)
					.slice(0, 2)
					.map((l) => truncateToWidth(l, width));
			},
		};
	};
}
