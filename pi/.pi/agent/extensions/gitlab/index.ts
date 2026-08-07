/**
 * GitLab tool — a global, read-only pi extension that wraps the official
 * `glab` CLI so the LLM can inspect pipelines, jobs, job traces, merge
 * requests, issues, and Pages deployments across any GitLab project.
 *
 * Requirements: `glab` must be installed and authenticated (`glab auth login`).
 * MCP is not needed — this shells out to `glab` directly.
 *
 * All actions are read-only. No mutating glab command is reachable.
 */

import type { AgentToolResult } from "@earendil-works/pi-agent-core";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { StringEnum } from "@earendil-works/pi-ai";
import { Type } from "typebox";
import { checkGlab, encodeProject, glabApi, type GlabResult, runGlab } from "./glab.ts";

const ACTIONS = [
	"pipeline_latest",
	"pipeline_status",
	"pipeline_jobs",
	"job_trace",
	"mr_list",
	"mr_view",
	"mr_diff",
	"issue_list",
	"issue_view",
	"pages_status",
	"raw",
] as const;

type Action = (typeof ACTIONS)[number];

const GitlabParams = Type.Object({
	action: StringEnum(ACTIONS, {
		description:
			"Which read-only GitLab lookup to run. pipeline_latest: newest pipeline for a ref. pipeline_status: status of a pipeline (needs id, or latest on ref). pipeline_jobs: jobs of a pipeline (needs id). job_trace: log/trace of a job (needs id). mr_list/mr_view/mr_diff: merge requests (view/diff need id=iid). issue_list/issue_view: issues (view needs id=iid). pages_status: GitLab Pages URL and deployment state. raw: escape hatch, pass raw glab args.",
	}),
	project: Type.Optional(
		Type.String({
			description:
				"Target project as path 'group/subgroup/repo' or numeric ID. If omitted, glab uses the repo in the current directory. For global use across projects, provide this explicitly.",
		}),
	),
	ref: Type.Optional(
		Type.String({ description: "Branch or tag name. Used by pipeline_latest and pipeline_status." }),
	),
	id: Type.Optional(
		Type.String({
			description:
				"ID/IID for the action: pipeline id (pipeline_status/pipeline_jobs), job id (job_trace), MR iid (mr_view/mr_diff), issue iid (issue_view).",
		}),
	),
	format: Type.Optional(
		StringEnum(["human", "json"] as const, {
			description: "Output format. 'human' = glab's formatted output/summary. 'json' = raw JSON. Default 'human'.",
			default: "human",
		}),
	),
	state: Type.Optional(
		Type.String({ description: "Filter for list actions, e.g. 'opened', 'closed', 'merged', 'all'." }),
	),
	limit: Type.Optional(Type.Number({ description: "Max items for list actions. Default 20." })),
	args: Type.Optional(
		Type.Array(Type.String(), {
			description: "For action 'raw' only: raw argv passed straight to glab (e.g. ['ci','list','-R','group/repo']).",
		}),
	),
});

function textResult(text: string, isError = false): AgentToolResult {
	return { content: [{ type: "text", text }], details: {}, isError };
}

/** Build the -R flag array if a project is given (for glab subcommands). */
function repoFlag(project?: string): string[] {
	return project ? ["-R", project] : [];
}

/** Turn a glab result into a tool result, honoring format and error state. */
function resultFrom(res: GlabResult, opts: { json?: boolean } = {}): AgentToolResult {
	if (res.spawnError) return textResult(res.stderr, true);
	if (res.exitCode !== 0) {
		const msg = (res.stderr || res.stdout || "glab exited with a non-zero status.").trim();
		return textResult(msg, true);
	}
	const out = res.stdout.trim() || res.stderr.trim();
	if (opts.json) {
		try {
			const parsed = JSON.parse(out);
			return { content: [{ type: "text", text: JSON.stringify(parsed, null, 2) }], details: { json: parsed } };
		} catch {
			// Not JSON (e.g. a raw trace) — return as-is.
			return textResult(out || "(empty)");
		}
	}
	return textResult(out || "(empty)");
}

export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "gitlab",
		label: "GitLab",
		description:
			"Read-only GitLab lookups via the glab CLI: pipelines (latest id/status/jobs), job logs/traces, merge requests (list/view/diff), issues (list/view), and Pages deployment status. Works across any project via the 'project' parameter. Requires glab to be installed and authenticated.",
		promptSnippet:
			"gitlab: inspect GitLab pipelines, jobs, job logs, merge requests, issues, and Pages status across any project (read-only)",
		promptGuidelines: [
			"Use the gitlab tool when the user asks about GitLab pipelines, jobs, job logs/traces, merge requests, issues, or Pages deployments.",
			"For the gitlab tool, pass an explicit 'project' (group/repo path or numeric id) whenever the user names a project or when not clearly in that repo's directory; otherwise glab targets the current directory's repo.",
			"The gitlab tool is read-only — it cannot create, retry, cancel, or modify anything.",
		],
		parameters: GitlabParams,

		async execute(_toolCallId, params, signal) {
			const action = params.action as Action;
			const json = params.format === "json";
			const project = params.project;
			const limit = params.limit ?? 20;

			// Escape hatch first — still read-only by convention, passed verbatim.
			if (action === "raw") {
				if (!params.args || params.args.length === 0) {
					return textResult("action 'raw' requires 'args' (an argv array for glab).", true);
				}
				return resultFrom(await runGlab(params.args, signal), { json });
			}

			// Verify glab availability up front so failures are actionable.
			const check = await checkGlab(signal);
			if (!check.ok) return textResult(check.message, true);

			switch (action) {
				case "pipeline_latest": {
					if (!project) {
						// Without a project we can't build an api path reliably; use glab ci get.
						const args = ["ci", "get", ...(params.ref ? ["-b", params.ref] : [])];
						if (json) args.push("--output", "json");
						return resultFrom(await runGlab(args, signal), { json });
					}
					const enc = encodeProject(project);
					const query = new URLSearchParams({ per_page: "1", order_by: "id", sort: "desc" });
					if (params.ref) query.set("ref", params.ref);
					const res = await glabApi(`projects/${enc}/pipelines?${query.toString()}`, signal);
					if (res.exitCode !== 0 || res.spawnError) return resultFrom(res, { json });
					try {
						const arr = JSON.parse(res.stdout.trim());
						const latest = Array.isArray(arr) ? arr[0] : undefined;
						if (!latest) return textResult(`No pipelines found for ${project}${params.ref ? ` on ref ${params.ref}` : ""}.`);
						if (json) return { content: [{ type: "text", text: JSON.stringify(latest, null, 2) }], details: { json: latest } };
						return textResult(
							`Latest pipeline for ${project}${params.ref ? ` (${params.ref})` : ""}:\n` +
								`  id:      ${latest.id}\n` +
								`  status:  ${latest.status}\n` +
								`  ref:     ${latest.ref}\n` +
								`  sha:     ${latest.sha}\n` +
								`  created: ${latest.created_at}\n` +
								`  url:     ${latest.web_url}`,
						);
					} catch {
						return resultFrom(res, { json });
					}
				}

				case "pipeline_status": {
					if (json) {
						if (!project) return textResult("pipeline_status with format=json requires 'project'.", true);
						const enc = encodeProject(project);
						if (params.id) return resultFrom(await glabApi(`projects/${enc}/pipelines/${params.id}`, signal), { json: true });
						const query = new URLSearchParams({ per_page: "1", order_by: "id", sort: "desc" });
						if (params.ref) query.set("ref", params.ref);
						return resultFrom(await glabApi(`projects/${enc}/pipelines?${query.toString()}`, signal), { json: true });
					}
					// human
					const args = ["ci", "get", ...repoFlag(project)];
					if (params.id) args.push("-p", params.id);
					else if (params.ref) args.push("-b", params.ref);
					return resultFrom(await runGlab(args, signal));
				}

				case "pipeline_jobs": {
					if (!params.id) return textResult("pipeline_jobs requires 'id' (the pipeline id).", true);
					if (!project) return textResult("pipeline_jobs requires 'project'.", true);
					const enc = encodeProject(project);
					const res = await glabApi(`projects/${enc}/pipelines/${params.id}/jobs?per_page=100`, signal);
					if (res.exitCode !== 0 || res.spawnError) return resultFrom(res);
					if (json) return resultFrom(res, { json: true });
					try {
						const jobs = JSON.parse(res.stdout.trim());
						if (!Array.isArray(jobs) || jobs.length === 0) return textResult(`No jobs found for pipeline ${params.id}.`);
						const lines = jobs.map(
							(j: any) => `  [${j.id}] ${j.name} (${j.stage}) — ${j.status}${j.web_url ? `\n        ${j.web_url}` : ""}`,
						);
						return textResult(`Jobs for pipeline ${params.id} in ${project}:\n${lines.join("\n")}`);
					} catch {
						return resultFrom(res);
					}
				}

				case "job_trace": {
					if (!params.id) return textResult("job_trace requires 'id' (the job id).", true);
					if (json) {
						if (!project) return textResult("job_trace with format=json requires 'project'.", true);
						const enc = encodeProject(project);
						// Trace is plain text, not JSON — return as-is.
						return resultFrom(await glabApi(`projects/${enc}/jobs/${params.id}/trace`, signal));
					}
					return resultFrom(await runGlab(["ci", "trace", params.id, ...repoFlag(project)], signal));
				}

				case "mr_list": {
					const args = ["mr", "list", ...repoFlag(project), "-P", String(limit)];
					if (params.state) args.push(`--${params.state}`);
					if (json) args.push("--output", "json");
					return resultFrom(await runGlab(args, signal), { json });
				}

				case "mr_view": {
					if (!params.id) return textResult("mr_view requires 'id' (the MR iid).", true);
					const args = ["mr", "view", params.id, ...repoFlag(project)];
					if (json) args.push("--output", "json");
					return resultFrom(await runGlab(args, signal), { json });
				}

				case "mr_diff": {
					if (!params.id) return textResult("mr_diff requires 'id' (the MR iid).", true);
					// glab mr diff has no JSON; use api for json format.
					if (json) {
						if (!project) return textResult("mr_diff with format=json requires 'project'.", true);
						const enc = encodeProject(project);
						return resultFrom(await glabApi(`projects/${enc}/merge_requests/${params.id}/changes`, signal), { json: true });
					}
					return resultFrom(await runGlab(["mr", "diff", params.id, ...repoFlag(project)], signal));
				}

				case "issue_list": {
					const args = ["issue", "list", ...repoFlag(project), "-P", String(limit)];
					if (params.state) args.push(`--${params.state}`);
					if (json) args.push("--output", "json");
					return resultFrom(await runGlab(args, signal), { json });
				}

				case "issue_view": {
					if (!params.id) return textResult("issue_view requires 'id' (the issue iid).", true);
					const args = ["issue", "view", params.id, ...repoFlag(project)];
					if (json) args.push("--output", "json");
					return resultFrom(await runGlab(args, signal), { json });
				}

				case "pages_status": {
					if (!project) return textResult("pages_status requires 'project'.", true);
					const enc = encodeProject(project);
					const res = await glabApi(`projects/${enc}/pages`, signal);
					if (res.spawnError) return textResult(res.stderr, true);
					if (res.exitCode !== 0) {
						const err = (res.stderr || res.stdout).toLowerCase();
						if (err.includes("404") || err.includes("not found")) {
							return textResult(`GitLab Pages is not configured (or not accessible) for ${project}.`);
						}
						return resultFrom(res);
					}
					if (json) return resultFrom(res, { json: true });
					try {
						const p = JSON.parse(res.stdout.trim());
						const domains = Array.isArray(p.domains) ? p.domains.map((d: any) => d.url || d.domain).join(", ") : "";
						return textResult(
							`GitLab Pages for ${project}:\n` +
								`  url:            ${p.url ?? "(none)"}\n` +
								`  deployed:       ${p.deployed ?? "(unknown)"}\n` +
								`  https_only:     ${p.is_unique_domain ?? p.https_only ?? "(unknown)"}${domains ? `\n  custom domains: ${domains}` : ""}`,
						);
					} catch {
						return resultFrom(res);
					}
				}

				default:
					return textResult(`Unknown action: ${action}`, true);
			}
		},
	});
}
