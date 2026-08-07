/**
 * cockpit/vim-editor — a modal (vim) editor for pi's prompt input.
 *
 * Replaces pi's default input editor with a NORMAL / INSERT / VISUAL modal
 * editor. Extends CustomEditor so all app keybindings keep working (ctrl+c
 * abort, ctrl+d exit, ctrl+p model cycle, ctrl+g external editor, escape,
 * submit, shift+enter newline). INSERT mode delegates everything to
 * CustomEditor; NORMAL/VISUAL implement vim by manipulating the base Editor's
 * private buffer state ({ lines, cursorLine, cursorCol }) directly — the base
 * editor exposes no public cursor setter, so we cast to reach it and keep our
 * own undo stack.
 *
 * Clipboard is unified with the system clipboard ("unnamedplus"): every yank and
 * delete writes to the macOS clipboard via the exported copyToClipboard(); p/P
 * read the live clipboard each press via `pbpaste` (readClipboardText is not
 * exported). macOS-only by design.
 *
 * Big prompts: `E` (and the /edit command) open the text in neovide when it is on
 * PATH (spawned blocking on the GUI window), else delegate to pi's built-in
 * external-editor action (terminal $VISUAL/$EDITOR/nano) which handles the TTY.
 *
 * Supported vim (roughly the "full" everyday set):
 *   motions   h j k l 0 $ w b e gg G  f F t T ; ,  (+ counts on all, capped 999)
 *   inserts   i a A I o O
 *   edits     x s S D C dd cc yy  p P  u
 *   operators d c y  +  motion  (dw cw ce de db cb d0 c0 d$ y$ dj dk dG dgg …)
 *             cw is treated as ce (vim's classic special case)
 *   objects   {d,c,y}{i,a}{w " ' ` ( ) b [ ] { } B}   e.g. ciw di" ca( yi{
 *   visual    v (charwise) V (linewise) + motions + d c y x s
 *   submit    NORMAL/INSERT Enter submits; shift+enter newline
 * No dot-repeat, macros, marks, registers beyond the system clipboard, `:` command
 * line or `/` search — out of scope.
 *
 * NOTE: the VISUAL selection highlight is rendered by a self-contained renderer
 * (the base editor only highlights the single cursor cell). Its word-wrap is a
 * simple greedy wrap, so very long lines may reflow slightly versus NORMAL mode
 * while a selection is active; it reverts on exit. All editing math is buffer
 * based and unit-tested independently of rendering.
 *
 * Zero external dependencies (node built-ins + pi runtime exports only).
 */

import {
	CustomEditor,
	copyToClipboard,
	type ExtensionContext,
	type KeybindingsManager,
} from "@earendil-works/pi-coding-agent";
import { type EditorTheme, matchesKey, truncateToWidth, type TUI, visibleWidth } from "@earendil-works/pi-tui";
import { execFileSync, spawn, spawnSync } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

type Mode = "normal" | "insert" | "visual" | "vline";
type Operator = "d" | "c" | "y";

/** Shape of the base Editor's private buffer state (verified against source). */
interface Buf {
	lines: string[];
	cursorLine: number;
	cursorCol: number;
}

interface Snapshot {
	text: string;
	line: number;
	col: number;
}

/** A resolved motion/object span: charwise flat [a, b) or linewise [l1, l2]. */
type Range = { kind: "char"; a: number; b: number } | { kind: "line"; l1: number; l2: number };

const MAX_COUNT = 999;
const MAX_UNDO = 200;
const OPEN_BRACKETS: Record<string, string> = { "(": ")", "[": "]", "{": "}" };
const BRACKET_ALIAS: Record<string, string> = { b: "(", B: "{", ")": "(", "]": "[", "}": "{" };

export class VimEditor extends CustomEditor {
	private mode: Mode = "insert";
	private editing = false;
	private readonly ctx: ExtensionContext;

	// pending state machine
	private op: Operator | null = null;
	private count1 = ""; // count before an operator (or for a plain motion)
	private count2 = ""; // count after an operator
	private awaitingG = false; // saw `g`, waiting for the second `g`
	private awaitingObject: "i" | "a" | null = null; // saw text-object intro

	private vimUndoStack: Snapshot[] = [];
	private visualAnchor: { line: number; col: number } | null = null;
	private visualScroll = 0;

	// intra-line char search (f F t T), and the last search for ; and ,
	private pendingFind: { kind: "f" | "F" | "t" | "T"; n: number } | null = null;
	private lastFind: { kind: "f" | "F" | "t" | "T"; char: string } | null = null;

	constructor(tui: TUI, theme: EditorTheme, kb: KeybindingsManager, opts: { ctx: ExtensionContext }) {
		super(tui, theme, kb);
		this.ctx = opts.ctx;
	}

	// --- base-buffer access --------------------------------------------------

	/** Reach the base Editor's private buffer. Fails fast if the field moves. */
	private get buf(): Buf {
		const b = (this as unknown as { state?: Buf }).state;
		if (!b || !Array.isArray(b.lines)) {
			throw new Error("cockpit: base Editor buffer shape changed; update vim-editor.ts");
		}
		return b;
	}

	private lineAt(i: number): string {
		return this.buf.lines[i] ?? "";
	}

	private curLine(): string {
		return this.lineAt(this.buf.cursorLine);
	}

	private lastLine(): number {
		return this.buf.lines.length - 1;
	}

	private firstNonBlank(i: number): number {
		const m = this.lineAt(i).search(/\S/);
		return m === -1 ? 0 : m;
	}

	/** Clamp a column for the given line, honoring the normal-mode block cursor. */
	private clampCol(line: number, col: number): number {
		const len = this.lineAt(line).length;
		const max = this.mode === "normal" ? Math.max(0, len - 1) : len;
		return Math.min(Math.max(0, col), max);
	}

	/** Move the cursor with clamping and reset base sticky-column state. */
	private setCursor(line: number, col: number): void {
		const b = this.buf;
		const clampedLine = Math.min(Math.max(0, line), this.lastLine());
		b.cursorLine = clampedLine;
		b.cursorCol = this.clampCol(clampedLine, col);
		const sticky = this as unknown as {
			preferredVisualCol: number | null;
			snappedFromCursorCol: number | null;
		};
		sticky.preferredVisualCol = null;
		sticky.snappedFromCursorCol = null;
	}

	private setBufferText(text: string): void {
		const b = this.buf;
		b.lines = text.split("\n");
		if (b.lines.length === 0) b.lines.push("");
	}

	// --- render-loop helpers -------------------------------------------------

	private changed(): void {
		this.onChange?.(this.getText());
		this.tui.requestRender();
	}

	private redraw(): void {
		this.tui.requestRender();
	}

	private snapshot(): void {
		const b = this.buf;
		this.vimUndoStack.push({ text: this.getText(), line: b.cursorLine, col: b.cursorCol });
		if (this.vimUndoStack.length > MAX_UNDO) this.vimUndoStack.shift();
	}

	private resetPending(): void {
		this.op = null;
		this.count1 = "";
		this.count2 = "";
		this.awaitingG = false;
		this.awaitingObject = null;
	}

	private static num(s: string): number {
		return s ? Math.min(parseInt(s, 10) || 1, MAX_COUNT) : 0;
	}

	// --- clipboard (unnamedplus, macOS) -------------------------------------

	private writeClip(text: string): void {
		try {
			void copyToClipboard(text);
		} catch {
			/* ignore */
		}
	}

	private readClip(): string {
		try {
			return execFileSync("pbpaste", { encoding: "utf8" });
		} catch {
			return "";
		}
	}

	// --- flat-text conversion ------------------------------------------------

	private toFlat(line: number, col: number): number {
		const lines = this.buf.lines;
		let idx = 0;
		for (let i = 0; i < line; i++) idx += lines[i]!.length + 1;
		return idx + col;
	}

	private fromFlat(idx: number): { line: number; col: number } {
		const lines = this.buf.lines;
		let rem = Math.max(0, idx);
		for (let i = 0; i < lines.length; i++) {
			const len = lines[i]!.length;
			if (rem <= len) return { line: i, col: rem };
			rem -= len + 1;
		}
		return { line: this.lastLine(), col: lines[this.lastLine()]!.length };
	}

	private static charClass(ch: string | undefined): 0 | 1 | 2 {
		if (ch === undefined || /\s/.test(ch)) return 0; // whitespace (incl. \n)
		if (/[\w]/.test(ch)) return 1; // word char
		return 2; // punctuation
	}

	private static wordFwd(s: string, i: number, n: number): number {
		const cc = VimEditor.charClass;
		for (let step = 0; step < n; step++) {
			const c = cc(s[i]);
			if (c !== 0) while (i < s.length && cc(s[i]) === c) i++;
			while (i < s.length && cc(s[i]) === 0) i++;
		}
		return i;
	}

	private static wordBack(s: string, i: number, n: number): number {
		const cc = VimEditor.charClass;
		for (let step = 0; step < n; step++) {
			if (i <= 0) break;
			i--;
			while (i > 0 && cc(s[i]) === 0) i--;
			const c = cc(s[i]);
			while (i > 0 && cc(s[i - 1]) === c) i--;
		}
		return i;
	}

	private static wordEnd(s: string, i: number, n: number): number {
		const cc = VimEditor.charClass;
		for (let step = 0; step < n; step++) {
			if (i >= s.length - 1) break;
			i++;
			while (i < s.length && cc(s[i]) === 0) i++;
			if (i >= s.length) return s.length - 1;
			const c = cc(s[i]);
			while (i + 1 < s.length && cc(s[i + 1]) === c) i++;
		}
		return i;
	}

	// --- input routing -------------------------------------------------------

	override handleInput(data: string): void {
		if (this.editing) return; // external editor owns input

		// consume the target character for a pending f/F/t/T
		if (this.pendingFind) {
			const pf = this.pendingFind;
			this.pendingFind = null;
			if (data.length !== 1 || data.charCodeAt(0) < 32) {
				if (this.op) this.resetPending(); // esc/control cancels the (operator) find
				return;
			}
			this.lastFind = { kind: pf.kind, char: data };
			this.doFind(pf.kind, data, pf.n, false);
			return;
		}

		if (matchesKey(data, "escape")) {
			if (this.mode === "insert") {
				if (this.isShowingAutocomplete()) {
					super.handleInput(data);
					return;
				}
				this.mode = "normal";
				this.setCursor(this.buf.cursorLine, this.buf.cursorCol - 1);
				this.redraw();
				return;
			}
			if (this.mode === "visual" || this.mode === "vline") {
				this.exitVisual();
				return;
			}
			super.handleInput(data); // normal-mode escape aborts the agent
			return;
		}

		if (this.mode === "insert") {
			super.handleInput(data);
			return;
		}
		if (this.mode === "visual" || this.mode === "vline") {
			this.handleVisual(data);
			return;
		}
		this.handleNormal(data);
	}

	// --- NORMAL mode ---------------------------------------------------------

	private handleNormal(data: string): void {
		// text object after an operator (e.g. c i w)
		if (this.awaitingObject) {
			const kind = this.awaitingObject;
			const operator = this.op;
			this.awaitingObject = null;
			const range = this.resolveTextObject(kind, data);
			if (range && operator) this.applyOperator(operator, range);
			this.resetPending();
			return;
		}

		// second `g` of gg (possibly under an operator)
		if (this.awaitingG) {
			this.awaitingG = false;
			if (data === "g") {
				if (this.op) {
					this.applyOperator(this.op, { kind: "line", l1: 0, l2: this.buf.cursorLine });
					this.resetPending();
				} else {
					this.setCursor(0, this.firstNonBlank(0));
					this.redraw();
				}
			} else {
				this.resetPending();
			}
			return;
		}

		// count digits
		const hasCount = this.op ? this.count2 !== "" : this.count1 !== "";
		if ((data >= "1" && data <= "9") || (data === "0" && hasCount)) {
			if (this.op) this.count2 = (this.count2 + data).slice(0, 3);
			else this.count1 = (this.count1 + data).slice(0, 3);
			return;
		}

		if (this.op) {
			this.handleOperatorKey(data);
			return;
		}
		this.handleNormalKey(data);
	}

	private handleOperatorKey(data: string): void {
		const op = this.op!;
		// dd / cc / yy -> linewise on current line (+count)
		if (data === op) {
			const n = Math.max(1, (VimEditor.num(this.count1) || 1) * (VimEditor.num(this.count2) || 1));
			this.applyOperator(op, { kind: "line", l1: this.buf.cursorLine, l2: this.buf.cursorLine + n - 1 });
			this.resetPending();
			return;
		}
		if (data === "i" || data === "a") {
			this.awaitingObject = data;
			return;
		}
		if (data === "g") {
			this.awaitingG = true;
			return;
		}
		if (data === "f" || data === "F" || data === "t" || data === "T") {
			this.startFind(data);
			return;
		}
		if (data === ";" || data === ",") {
			if (!this.lastFind) {
				this.resetPending();
				return;
			}
			const m = Math.max(1, (VimEditor.num(this.count1) || 1) * (VimEditor.num(this.count2) || 1));
			const kind = data === ";" ? this.lastFind.kind : VimEditor.reverseFind(this.lastFind.kind);
			this.doFind(kind, this.lastFind.char, m, true);
			return;
		}
		const n = Math.max(1, (VimEditor.num(this.count1) || 1) * (VimEditor.num(this.count2) || 1));
		let key = data;
		if (op === "c" && key === "w") key = "e"; // classic cw == ce
		const range = this.resolveMotionRange(key, n);
		if (range) this.applyOperator(op, range);
		this.resetPending();
	}

	private handleNormalKey(data: string): void {
		const n = VimEditor.num(this.count1) || 1;
		// keep the count when starting an operator (2dw) or a find (3fx); else clear
		if (!"dcyfFtT;,".includes(data) || data.length !== 1) this.count1 = "";
		const b = this.buf;

		switch (data) {
			case "h":
			case "l":
			case "j":
			case "k":
			case "0":
			case "$":
			case "w":
			case "b":
			case "e":
			case "G":
				this.moveByKey(data, n);
				this.redraw();
				return;
			case "g":
				this.awaitingG = true;
				return;
			case "f":
			case "F":
			case "t":
			case "T":
				this.startFind(data);
				return;
			case ";":
			case ",":
				this.repeatFind(data);
				return;

			case "i":
				this.enterInsert(b.cursorLine, b.cursorCol);
				return;
			case "a":
				this.enterInsert(b.cursorLine, b.cursorCol + 1);
				return;
			case "A":
				this.enterInsert(b.cursorLine, this.curLine().length);
				return;
			case "I":
				this.enterInsert(b.cursorLine, this.firstNonBlank(b.cursorLine));
				return;
			case "o":
				this.openLine(true);
				return;
			case "O":
				this.openLine(false);
				return;

			case "x":
				this.deleteChars(n);
				return;
			case "s":
				this.deleteChars(n);
				this.enterInsert(b.cursorLine, b.cursorCol);
				return;
			case "D":
				this.deleteToEol();
				return;
			case "C":
				this.changeToEol();
				return;
			case "S":
				this.applyOperator("c", { kind: "line", l1: b.cursorLine, l2: b.cursorLine });
				return;

			case "d":
			case "c":
			case "y":
				this.op = data;
				return;

			case "p":
				this.paste(true);
				return;
			case "P":
				this.paste(false);
				return;
			case "u":
				this.undo();
				return;

			case "v":
				this.enterVisual("visual");
				return;
			case "V":
				this.enterVisual("vline");
				return;

			case "E":
				void this.openExternalEditor();
				return;
			case "\r":
			case "\n":
				this.submit();
				return;
			default:
				if (data.length !== 1 || data.charCodeAt(0) < 32) super.handleInput(data);
				return;
		}
	}

	/** Move the cursor for a motion key (shared by NORMAL and VISUAL). */
	private moveByKey(key: string, n: number): void {
		const b = this.buf;
		const s = this.buf.lines.join("\n");
		switch (key) {
			case "h":
				this.setCursor(b.cursorLine, b.cursorCol - n);
				return;
			case "l":
				this.setCursor(b.cursorLine, b.cursorCol + n);
				return;
			case "j":
				this.setCursor(b.cursorLine + n, b.cursorCol);
				return;
			case "k":
				this.setCursor(b.cursorLine - n, b.cursorCol);
				return;
			case "0":
				this.setCursor(b.cursorLine, 0);
				return;
			case "$":
				this.setCursor(b.cursorLine, this.curLine().length - 1);
				return;
			case "G":
				this.setCursor(this.lastLine(), this.firstNonBlank(this.lastLine()));
				return;
			case "w": {
				const pos = this.fromFlat(VimEditor.wordFwd(s, this.toFlat(b.cursorLine, b.cursorCol), n));
				this.setCursor(pos.line, pos.col);
				return;
			}
			case "b": {
				const pos = this.fromFlat(VimEditor.wordBack(s, this.toFlat(b.cursorLine, b.cursorCol), n));
				this.setCursor(pos.line, pos.col);
				return;
			}
			case "e": {
				const pos = this.fromFlat(VimEditor.wordEnd(s, this.toFlat(b.cursorLine, b.cursorCol), n));
				this.setCursor(pos.line, pos.col);
				return;
			}
		}
	}

	// --- intra-line char search (f F t T ; ,) --------------------------------

	private static reverseFind(k: "f" | "F" | "t" | "T"): "f" | "F" | "t" | "T" {
		return k === "f" ? "F" : k === "F" ? "f" : k === "t" ? "T" : "t";
	}

	/** Begin an f/F/t/T: capture the count now, wait for the target character. */
	private startFind(kind: "f" | "F" | "t" | "T"): void {
		const n = this.op
			? Math.max(1, (VimEditor.num(this.count1) || 1) * (VimEditor.num(this.count2) || 1))
			: VimEditor.num(this.count1) || 1;
		this.count1 = "";
		this.count2 = "";
		this.pendingFind = { kind, n };
	}

	/** Repeat the last f/F/t/T: `;` same direction, `,` reversed. */
	private repeatFind(data: string): void {
		if (!this.lastFind) {
			this.count1 = "";
			return;
		}
		const n = VimEditor.num(this.count1) || 1;
		this.count1 = "";
		const kind = data === ";" ? this.lastFind.kind : VimEditor.reverseFind(this.lastFind.kind);
		this.doFind(kind, this.lastFind.char, n, true);
	}

	/** Find the nth occurrence index of `char` on the current line, or -1. */
	private charIndex(kind: string, char: string, n: number, fromCol: number, forRepeat: boolean): number {
		const s = this.curLine();
		if (kind === "f" || kind === "t") {
			let i = fromCol + (kind === "t" && forRepeat ? 1 : 0);
			for (let k = 0; k < n; k++) {
				i = s.indexOf(char, i + 1);
				if (i < 0) return -1;
			}
			return i;
		}
		let i = fromCol - (kind === "T" && forRepeat ? 1 : 0);
		for (let k = 0; k < n; k++) {
			if (i - 1 < 0) return -1;
			i = s.lastIndexOf(char, i - 1);
			if (i < 0) return -1;
		}
		return i;
	}

	private charCursorCol(kind: string, idx: number): number {
		return kind === "t" ? idx - 1 : kind === "T" ? idx + 1 : idx; // f/F land on the char
	}

	private charOpRange(kind: string, idx: number, startFlat: number, line: number): Range {
		if (kind === "f") return { kind: "char", a: startFlat, b: this.toFlat(line, idx + 1) };
		if (kind === "t") return { kind: "char", a: startFlat, b: this.toFlat(line, idx) };
		if (kind === "F") return { kind: "char", a: this.toFlat(line, idx), b: startFlat };
		return { kind: "char", a: this.toFlat(line, idx + 1), b: startFlat }; // T
	}

	/** Resolve a find as a cursor move (normal/visual) or operator range. */
	private doFind(kind: "f" | "F" | "t" | "T", char: string, n: number, forRepeat: boolean): void {
		const line = this.buf.cursorLine;
		const idx = this.charIndex(kind, char, n, this.buf.cursorCol, forRepeat);
		if (idx < 0) {
			if (this.op) this.resetPending();
			return;
		}
		if (this.op) {
			const op = this.op;
			const range = this.charOpRange(kind, idx, this.toFlat(line, this.buf.cursorCol), line);
			this.applyOperator(op, range);
			this.resetPending();
			return;
		}
		this.setCursor(line, this.charCursorCol(kind, idx));
		this.redraw();
	}

	// --- motion / object ranges (for operators) ------------------------------

	private resolveMotionRange(key: string, n: number): Range | null {
		const b = this.buf;
		const line = b.cursorLine;
		const len = this.curLine().length;
		const start = this.toFlat(line, b.cursorCol);
		const lineStart = this.toFlat(line, 0);
		const lineEnd = this.toFlat(line, len); // exclusive (position after last char)
		const s = this.buf.lines.join("\n");

		switch (key) {
			case "l":
				return { kind: "char", a: start, b: Math.min(start + n, lineEnd) };
			case "h":
				return { kind: "char", a: Math.max(start - n, lineStart), b: start };
			case "0":
				return { kind: "char", a: lineStart, b: start };
			case "$":
				return { kind: "char", a: start, b: lineEnd };
			case "w": {
				let target = VimEditor.wordFwd(s, start, n);
				if (target > lineEnd) target = lineEnd; // dw stops at EOL, keeps newline
				return { kind: "char", a: start, b: Math.max(target, start) };
			}
			case "b":
				return { kind: "char", a: VimEditor.wordBack(s, start, n), b: start };
			case "e":
				return { kind: "char", a: start, b: VimEditor.wordEnd(s, start, n) + 1 };
			case "j":
				return { kind: "line", l1: line, l2: Math.min(line + n, this.lastLine()) };
			case "k":
				return { kind: "line", l1: Math.max(line - n, 0), l2: line };
			case "G":
				return { kind: "line", l1: line, l2: this.lastLine() };
			default:
				return null;
		}
	}

	private resolveTextObject(kind: "i" | "a", obj: string): Range | null {
		if (obj === "w") return this.wordObject(kind);
		if (obj === '"' || obj === "'" || obj === "`") return this.quoteObject(kind, obj);
		const open = OPEN_BRACKETS[obj] ? obj : BRACKET_ALIAS[obj];
		if (open && OPEN_BRACKETS[open]) return this.bracketObject(kind, open, OPEN_BRACKETS[open]!);
		return null;
	}

	private wordObject(kind: "i" | "a"): Range | null {
		const line = this.buf.cursorLine;
		const s = this.lineAt(line);
		if (s.length === 0) return { kind: "char", a: this.toFlat(line, 0), b: this.toFlat(line, 0) };
		const col = Math.min(this.buf.cursorCol, s.length - 1);
		const cc = VimEditor.charClass;
		const c = cc(s[col]);
		let a = col;
		let z = col;
		while (a > 0 && cc(s[a - 1]) === c) a--;
		while (z < s.length - 1 && cc(s[z + 1]) === c) z++;
		if (kind === "a") {
			// include trailing whitespace, else leading whitespace
			let e2 = z;
			while (e2 < s.length - 1 && cc(s[e2 + 1]) === 0) e2++;
			if (e2 === z) while (a > 0 && cc(s[a - 1]) === 0) a--;
			else z = e2;
		}
		return { kind: "char", a: this.toFlat(line, a), b: this.toFlat(line, z + 1) };
	}

	private quoteObject(kind: "i" | "a", q: string): Range | null {
		const line = this.buf.cursorLine;
		const s = this.lineAt(line);
		const idx: number[] = [];
		for (let i = 0; i < s.length; i++) if (s[i] === q) idx.push(i);
		if (idx.length < 2) return null;
		const col = this.buf.cursorCol;
		for (let p = 0; p + 1 < idx.length; p += 2) {
			const open = idx[p]!;
			const close = idx[p + 1]!;
			if (col <= close) {
				if (kind === "i") return { kind: "char", a: this.toFlat(line, open + 1), b: this.toFlat(line, close) };
				// a": include the quotes plus trailing whitespace, else leading whitespace
				let a = open;
				let z = close;
				let t = close + 1;
				while (t < s.length && /\s/.test(s[t]!)) t++;
				if (t > close + 1) z = t - 1;
				else {
					let l = open - 1;
					while (l >= 0 && /\s/.test(s[l]!)) l--;
					a = l + 1;
				}
				return { kind: "char", a: this.toFlat(line, a), b: this.toFlat(line, z + 1) };
			}
		}
		return null;
	}

	private bracketObject(kind: "i" | "a", open: string, close: string): Range | null {
		const s = this.buf.lines.join("\n");
		const start = this.toFlat(this.buf.cursorLine, this.buf.cursorCol);
		// find enclosing open bracket
		let depth = 0;
		let openIdx = -1;
		for (let i = start; i >= 0; i--) {
			if (s[i] === close && i !== start) depth++;
			else if (s[i] === open) {
				if (depth === 0) {
					openIdx = i;
					break;
				}
				depth--;
			}
		}
		if (openIdx === -1) return null;
		depth = 0;
		let closeIdx = -1;
		for (let i = openIdx + 1; i < s.length; i++) {
			if (s[i] === open) depth++;
			else if (s[i] === close) {
				if (depth === 0) {
					closeIdx = i;
					break;
				}
				depth--;
			}
		}
		if (closeIdx === -1) return null;
		if (kind === "i") return { kind: "char", a: openIdx + 1, b: closeIdx };
		return { kind: "char", a: openIdx, b: closeIdx + 1 };
	}

	// --- operators -----------------------------------------------------------

	private applyOperator(op: Operator, range: Range): void {
		if (range.kind === "char") {
			const a = Math.max(0, Math.min(range.a, range.b));
			const z = Math.max(range.a, range.b);
			const text = this.buf.lines.join("\n");
			const removed = text.slice(a, z);
			if (op === "y") {
				if (removed) this.writeClip(removed);
				const pos = this.fromFlat(a);
				this.mode = "normal";
				this.setCursor(pos.line, pos.col);
				this.redraw();
				return;
			}
			this.snapshot();
			if (removed) this.writeClip(removed);
			this.setBufferText(text.slice(0, a) + text.slice(z));
			const pos = this.fromFlat(a);
			this.mode = op === "c" ? "insert" : "normal";
			this.setCursor(pos.line, pos.col);
			this.changed();
			return;
		}

		// linewise
		const l1 = Math.max(0, Math.min(range.l1, range.l2));
		const l2 = Math.min(this.lastLine(), Math.max(range.l1, range.l2));
		const removed = `${this.buf.lines.slice(l1, l2 + 1).join("\n")}\n`;
		if (op === "y") {
			this.writeClip(removed);
			this.mode = "normal";
			this.setCursor(l1, this.firstNonBlank(l1));
			this.redraw();
			return;
		}
		this.snapshot();
		this.writeClip(removed);
		if (op === "c") {
			this.buf.lines.splice(l1, l2 - l1 + 1, "");
			this.mode = "insert";
			this.setCursor(l1, 0);
		} else {
			this.buf.lines.splice(l1, l2 - l1 + 1);
			if (this.buf.lines.length === 0) this.buf.lines.push("");
			const target = Math.min(l1, this.lastLine());
			this.mode = "normal";
			this.setCursor(target, this.firstNonBlank(target));
		}
		this.changed();
	}

	// --- simple inserts / edits ---------------------------------------------

	private enterInsert(line: number, col: number): void {
		this.snapshot();
		this.mode = "insert";
		this.setCursor(line, col);
		this.redraw();
	}

	private openLine(below: boolean): void {
		this.snapshot();
		const b = this.buf;
		const at = below ? b.cursorLine + 1 : b.cursorLine;
		b.lines.splice(at, 0, "");
		this.mode = "insert";
		this.setCursor(at, 0);
		this.changed();
	}

	private deleteChars(n: number): void {
		const b = this.buf;
		const s = this.curLine();
		if (s.length === 0) return;
		this.snapshot();
		const end = Math.min(s.length, b.cursorCol + n);
		this.writeClip(s.slice(b.cursorCol, end));
		b.lines[b.cursorLine] = s.slice(0, b.cursorCol) + s.slice(end);
		this.setCursor(b.cursorLine, b.cursorCol);
		this.changed();
	}

	private deleteToEol(): void {
		const b = this.buf;
		const s = this.curLine();
		if (b.cursorCol >= s.length) return;
		this.snapshot();
		this.writeClip(s.slice(b.cursorCol));
		b.lines[b.cursorLine] = s.slice(0, b.cursorCol);
		this.setCursor(b.cursorLine, b.cursorCol);
		this.changed();
	}

	private changeToEol(): void {
		const b = this.buf;
		const s = this.curLine();
		this.snapshot();
		if (b.cursorCol < s.length) {
			this.writeClip(s.slice(b.cursorCol));
			b.lines[b.cursorLine] = s.slice(0, b.cursorCol);
		}
		this.mode = "insert";
		this.setCursor(b.cursorLine, b.cursorCol);
		this.changed();
	}

	private paste(after: boolean): void {
		const text = this.readClip();
		if (!text) return;
		this.snapshot();
		const b = this.buf;

		// linewise paste: clipboard ending in a newline (e.g. from yy/dd) drops
		// whole lines below (p) or above (P) the current line, like vim.
		if (text.endsWith("\n")) {
			const newLines = text.slice(0, -1).split("\n");
			const at = after ? b.cursorLine + 1 : b.cursorLine;
			b.lines.splice(at, 0, ...newLines);
			this.setCursor(at, this.firstNonBlank(at));
			this.changed();
			return;
		}

		const s = this.curLine();
		const at = after && s.length > 0 ? b.cursorCol + 1 : b.cursorCol;
		const parts = text.split("\n");
		if (parts.length === 1) {
			b.lines[b.cursorLine] = s.slice(0, at) + parts[0] + s.slice(at);
			this.setCursor(b.cursorLine, at + parts[0]!.length - 1);
		} else {
			const before = s.slice(0, at);
			const afterText = s.slice(at);
			const merged = [before + parts[0], ...parts.slice(1, -1), parts[parts.length - 1] + afterText];
			b.lines.splice(b.cursorLine, 1, ...merged);
			const endLine = b.cursorLine + parts.length - 1;
			this.setCursor(endLine, Math.max(0, parts[parts.length - 1]!.length - 1));
		}
		this.changed();
	}

	private undo(): void {
		const snap = this.vimUndoStack.pop();
		if (!snap) return;
		this.setBufferText(snap.text);
		this.setCursor(snap.line, snap.col);
		this.changed();
	}

	private submit(): void {
		super.handleInput("\r");
		this.mode = "insert";
		this.vimUndoStack = [];
		this.visualAnchor = null;
		this.resetPending();
	}

	// --- VISUAL mode ---------------------------------------------------------

	private enterVisual(kind: "visual" | "vline"): void {
		this.mode = kind;
		this.visualAnchor = { line: this.buf.cursorLine, col: this.buf.cursorCol };
		this.redraw();
	}

	private exitVisual(): void {
		this.mode = "normal";
		this.visualAnchor = null;
		this.setCursor(this.buf.cursorLine, this.buf.cursorCol);
		this.redraw();
	}

	private handleVisual(data: string): void {
		// second `g` of gg
		if (this.awaitingG) {
			this.awaitingG = false;
			if (data === "g") {
				this.setCursor(0, this.firstNonBlank(0));
				this.redraw();
			}
			return;
		}
		const hasCount = this.count1 !== "";
		if ((data >= "1" && data <= "9") || (data === "0" && hasCount)) {
			this.count1 = (this.count1 + data).slice(0, 3);
			return;
		}
		const n = VimEditor.num(this.count1) || 1;

		switch (data) {
			case "v":
				if (this.mode === "visual") this.exitVisual();
				else {
					this.mode = "visual";
					this.redraw();
				}
				this.count1 = "";
				return;
			case "V":
				if (this.mode === "vline") this.exitVisual();
				else {
					this.mode = "vline";
					this.redraw();
				}
				this.count1 = "";
				return;
			case "d":
			case "x":
				this.operateVisual("d");
				return;
			case "c":
			case "s":
				this.operateVisual("c");
				return;
			case "y":
				this.operateVisual("y");
				return;
			case "h":
			case "l":
			case "j":
			case "k":
			case "0":
			case "$":
			case "w":
			case "b":
			case "e":
			case "G":
				this.moveByKey(data, n);
				this.count1 = "";
				this.redraw();
				return;
			case "g":
				this.awaitingG = true;
				this.count1 = "";
				return;
			case "f":
			case "F":
			case "t":
			case "T":
				this.startFind(data);
				return;
			case ";":
			case ",":
				this.repeatFind(data);
				return;
			default:
				this.count1 = "";
				return;
		}
	}

	private operateVisual(op: Operator): void {
		if (!this.visualAnchor) return;
		let range: Range;
		if (this.mode === "vline") {
			range = { kind: "line", l1: this.visualAnchor.line, l2: this.buf.cursorLine };
		} else {
			const a = this.toFlat(this.visualAnchor.line, this.visualAnchor.col);
			const c = this.toFlat(this.buf.cursorLine, this.buf.cursorCol);
			range = { kind: "char", a: Math.min(a, c), b: Math.max(a, c) + 1 }; // inclusive
		}
		this.visualAnchor = null;
		this.applyOperator(op, range);
	}

	// --- external editor -----------------------------------------------------

	private static has(cmd: string): boolean {
		try {
			return spawnSync("which", [cmd], { stdio: "ignore" }).status === 0;
		} catch {
			return false;
		}
	}

	async openExternalEditor(): Promise<void> {
		if (this.editing) return;

		if (!VimEditor.has("neovide")) {
			const handler = this.actionHandlers.get("app.editor.external");
			if (handler) handler();
			else this.ctx.ui.notify("No external editor found (neovide/nvim)", "warning");
			this.mode = "normal";
			return;
		}

		this.editing = true;
		this.mode = "normal";
		this.ctx.ui.setStatus("cockpit-edit", this.ctx.ui.theme.fg("accent", "● editing in neovide…"));
		this.redraw();

		const file = path.join(os.tmpdir(), `pi-prompt-${Date.now()}-${Math.random().toString(36).slice(2, 8)}.md`);
		try {
			fs.writeFileSync(file, this.getExpandedText(), "utf8");
			await new Promise<void>((resolve, reject) => {
				const child = spawn("neovide", ["--no-fork", file], { stdio: "ignore" });
				child.on("error", reject);
				child.on("close", () => resolve());
			});
			this.setText(fs.readFileSync(file, "utf8").replace(/\n$/, ""));
		} catch (err) {
			this.ctx.ui.notify(`External editor failed: ${(err as Error).message}`, "error");
		} finally {
			try {
				fs.unlinkSync(file);
			} catch {
				/* ignore */
			}
			this.editing = false;
			this.mode = "normal";
			this.ctx.ui.setStatus("cockpit-edit", undefined);
			this.redraw();
		}
	}

	// --- render --------------------------------------------------------------

	override render(width: number): string[] {
		const lines = this.mode === "visual" || this.mode === "vline" ? this.renderVisual(width) : super.render(width);
		if (lines.length === 0) return lines;
		const raw =
			this.mode === "normal"
				? " NORMAL "
				: this.mode === "insert"
					? " INSERT "
					: this.mode === "vline"
						? " V-LINE "
						: " VISUAL ";
		const color = this.mode === "insert" ? "success" : this.mode === "normal" ? "accent" : "warning";
		const label = this.ctx.ui.theme.fg(color, raw);
		const last = lines.length - 1;
		if (visibleWidth(lines[last]!) >= raw.length) {
			lines[last] = truncateToWidth(lines[last]!, width - raw.length, "") + label;
		}
		return lines;
	}

	/** Self-contained renderer for VISUAL/V-LINE that highlights the selection. */
	private renderVisual(width: number): string[] {
		const b = this.buf;
		const maxPadding = Math.max(0, Math.floor((width - 1) / 2));
		const paddingX = Math.min(this.getPaddingX(), maxPadding);
		const contentWidth = Math.max(1, width - paddingX * 2);
		const layoutWidth = Math.max(1, contentWidth - (paddingX ? 0 : 1));
		const pad = " ".repeat(paddingX);
		const hr = this.borderColor("─".repeat(width));

		// selection bounds
		const anchor = this.visualAnchor ?? { line: b.cursorLine, col: b.cursorCol };
		const lineMode = this.mode === "vline";
		const selA = Math.min(this.toFlat(anchor.line, anchor.col), this.toFlat(b.cursorLine, b.cursorCol));
		const selZ = Math.max(this.toFlat(anchor.line, anchor.col), this.toFlat(b.cursorLine, b.cursorCol));
		const selL1 = Math.min(anchor.line, b.cursorLine);
		const selL2 = Math.max(anchor.line, b.cursorLine);

		// wrap logical lines into visual rows
		type Row = { line: number; startCol: number; graphemes: string[] };
		const rows: Row[] = [];
		for (let li = 0; li < b.lines.length; li++) {
			const g = Array.from(b.lines[li]!);
			if (g.length === 0) {
				rows.push({ line: li, startCol: 0, graphemes: [] });
				continue;
			}
			let i = 0;
			while (i < g.length) {
				let w = 0;
				let j = i;
				while (j < g.length && w + visibleWidth(g[j]!) <= layoutWidth) {
					w += visibleWidth(g[j]!);
					j++;
				}
				if (j === i) j = i + 1;
				rows.push({ line: li, startCol: i, graphemes: g.slice(i, j) });
				i = j;
			}
		}

		// keep the cursor row visible
		const rows2 = this.tui.terminal?.rows ?? 40;
		const maxVisible = Math.max(5, Math.floor(rows2 * 0.3));
		let headRow = rows.findIndex(
			(r) => r.line === b.cursorLine && b.cursorCol >= r.startCol && b.cursorCol < r.startCol + r.graphemes.length,
		);
		if (headRow === -1) {
			headRow = rows.map((r) => r.line).lastIndexOf(b.cursorLine);
			if (headRow === -1) headRow = 0;
		}
		if (headRow < this.visualScroll) this.visualScroll = headRow;
		else if (headRow >= this.visualScroll + maxVisible) this.visualScroll = headRow - maxVisible + 1;
		this.visualScroll = Math.max(0, Math.min(this.visualScroll, Math.max(0, rows.length - maxVisible)));
		const visible = rows.slice(this.visualScroll, this.visualScroll + maxVisible);

		const out: string[] = [hr];
		for (const r of visible) {
			let text = "";
			let inRev = false;
			for (let k = 0; k < r.graphemes.length; k++) {
				const col = r.startCol + k;
				const flat = this.toFlat(r.line, col);
				const selected = lineMode ? r.line >= selL1 && r.line <= selL2 : flat >= selA && flat <= selZ;
				if (selected && !inRev) {
					text += "\x1b[7m";
					inRev = true;
				} else if (!selected && inRev) {
					text += "\x1b[27m";
					inRev = false;
				}
				text += r.graphemes[k];
			}
			if (inRev) text += "\x1b[27m";
			// linewise: mark the empty tail so empty selected lines still show
			if (lineMode && r.graphemes.length === 0 && r.line >= selL1 && r.line <= selL2) {
				text = "\x1b[7m \x1b[27m";
			}
			const w = visibleWidth(text);
			out.push(pad + text + " ".repeat(Math.max(0, contentWidth - w)) + pad);
		}
		out.push(hr);
		return out;
	}
}
