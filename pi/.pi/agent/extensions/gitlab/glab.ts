/**
 * glab runner helpers.
 *
 * Thin, injection-safe wrappers around the official GitLab CLI (`glab`).
 * All invocations use execFile with an argv array (no shell) so user input
 * can never be interpreted by a shell.
 */

import { execFile } from "node:child_process";

const DEFAULT_TIMEOUT_MS = 30_000;
const MAX_BUFFER = 10 * 1024 * 1024; // 10 MB

export interface GlabResult {
	stdout: string;
	stderr: string;
	exitCode: number;
	/** True when glab could not be spawned at all (e.g. not installed). */
	spawnError: boolean;
}

/**
 * Run `glab` with the given argv array. Never throws for non-zero exits;
 * inspect the returned exitCode/stderr instead. Honors an AbortSignal and a
 * per-call timeout so a hung glab process cannot stall the agent.
 */
export function runGlab(
	args: string[],
	signal?: AbortSignal,
	timeoutMs: number = DEFAULT_TIMEOUT_MS,
): Promise<GlabResult> {
	return new Promise((resolve) => {
		execFile(
			"glab",
			args,
			{
				timeout: timeoutMs,
				maxBuffer: MAX_BUFFER,
				signal,
				shell: false,
				encoding: "utf8",
			},
			(error, stdout, stderr) => {
				if (error && (error as NodeJS.ErrnoException).code === "ENOENT") {
					resolve({
						stdout: "",
						stderr:
							"glab (GitLab CLI) was not found on PATH. Install it from https://gitlab.com/gitlab-org/cli and run `glab auth login`.",
						exitCode: 127,
						spawnError: true,
					});
					return;
				}

				// execFile sets error for non-zero exits and for timeouts/aborts.
				const exitCode =
					typeof (error as { code?: unknown })?.code === "number"
						? ((error as { code: number }).code as number)
						: error
							? 1
							: 0;

				let stderrText = stderr ?? "";
				if (error && (error as { killed?: boolean }).killed) {
					stderrText = `glab call timed out or was cancelled.\n${stderrText}`;
				}

				resolve({
					stdout: stdout ?? "",
					stderr: stderrText,
					exitCode,
					spawnError: false,
				});
			},
		);
	});
}

/**
 * Call a GitLab REST API path via `glab api <path>`. Always returns JSON text
 * from glab. Parsed result is returned on success; on failure the raw result
 * is surfaced so callers can craft an error message.
 */
export async function glabApi(
	apiPath: string,
	signal?: AbortSignal,
	extraArgs: string[] = [],
): Promise<GlabResult> {
	return runGlab(["api", apiPath, ...extraArgs], signal);
}

/** URL-encode a project path (`group/sub/repo`) for use in api paths. */
export function encodeProject(project: string): string {
	// Numeric IDs are passed through as-is; paths are fully encoded.
	if (/^\d+$/.test(project)) return project;
	return encodeURIComponent(project);
}

/** Check that glab is installed and authenticated. */
export async function checkGlab(signal?: AbortSignal): Promise<{ ok: boolean; message: string }> {
	const res = await runGlab(["auth", "status"], signal, 15_000);
	if (res.spawnError) {
		return { ok: false, message: res.stderr };
	}
	if (res.exitCode !== 0) {
		return {
			ok: false,
			message: `glab is installed but not authenticated. Run \`glab auth login\`.\n${res.stderr || res.stdout}`.trim(),
		};
	}
	return { ok: true, message: (res.stderr || res.stdout).trim() };
}
