/**
 * cockpit — a proper TUI for pi: a context-rich status footer + a medium-depth
 * modal (vim) prompt editor with system-clipboard yank/paste and external
 * neovide/neovim editing.
 *
 * On TUI startup this replaces:
 *   - the footer, with a status line showing tokens/cost, context-window usage
 *     (color-coded as it fills), model + thinking level, git branch, and any
 *     other extension statuses (see footer.ts);
 *   - the input editor, with a NORMAL/INSERT vim editor (see vim-editor.ts).
 *
 * It is guarded to `ctx.mode === "tui"` so print/rpc/json runs are untouched,
 * and both replacements are cleared on session_shutdown. The greeter's header is
 * left alone — only the footer and editor are replaced.
 *
 * Commands:
 *   /edit   open the current prompt in neovide (or the built-in editor)
 *
 * Personal extension: lives in ~/.pi/agent/extensions/. Hot-reload with /reload.
 * Zero external dependencies (node built-ins + pi runtime exports only).
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { TUI } from "@earendil-works/pi-tui";
import { makeFooter } from "./footer.ts";
import { VimEditor } from "./vim-editor.ts";

export default function (pi: ExtensionAPI) {
	let active: VimEditor | undefined;
	let activeTui: TUI | undefined;

	pi.on("session_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;

		ctx.ui.setFooter(
			makeFooter(pi, ctx, (tui) => {
				activeTui = tui;
			}),
		);

		ctx.ui.setEditorComponent((tui, theme, kb) => {
			active = new VimEditor(tui, theme, kb, { ctx });
			activeTui = tui;
			return active;
		});
	});

	pi.on("session_shutdown", () => {
		active = undefined;
		activeTui = undefined;
	});

	pi.registerCommand("edit", {
		description: "Edit the prompt in an external editor (neovide/nvim)",
		handler: async (_args, ctx) => {
			if (!active) {
				ctx.ui.notify("No active editor", "warning");
				return;
			}
			await active.openExternalEditor();
		},
	});

	// Keep the footer's token/cost/model/thinking figures fresh.
	const refresh = () => activeTui?.requestRender();
	pi.on("agent_end", refresh);
	pi.on("turn_end", refresh);
	pi.on("message_end", refresh);
	pi.on("model_select", refresh);
	pi.on("thinking_level_select", refresh);
}
