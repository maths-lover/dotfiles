# GitLab tool (pi extension)

A global, **read-only** pi extension that wraps the official GitLab CLI
([`glab`](https://gitlab.com/gitlab-org/cli)) so you can ask pi natural-language
questions about GitLab and it will call the `gitlab` tool for you.

No MCP server required — it simply shells out to `glab`.

## Prerequisites

- `glab` installed and on your `PATH`.
- Authenticated: `glab auth login` (the extension checks `glab auth status` and
  returns a clear error if not).

## Scope

- **Global**: lives in `~/.pi/agent/extensions/gitlab/`, so it's available in
  every project. Reload with `/reload`.
- Every action accepts an explicit `project` (path `group/subgroup/repo` or a
  numeric ID). If omitted, `glab` targets the repo detected in the current
  working directory.
- **Read-only.** No create/retry/cancel/mutate actions are reachable.

## The `gitlab` tool

Parameters:

| param     | description |
|-----------|-------------|
| `action`  | which lookup to run (see below) |
| `project` | `group/repo` path or numeric id (optional; recommended for cross-project use) |
| `ref`     | branch/tag (used by `pipeline_latest`, `pipeline_status`) |
| `id`      | pipeline id / job id / MR iid / issue iid, depending on action |
| `format`  | `human` (default) or `json` |
| `state`   | list filter, e.g. `opened`, `closed`, `merged`, `all` |
| `limit`   | max items for list actions (default 20) |
| `args`    | for `action: raw` only — raw argv passed straight to `glab` |

### Actions

| action            | needs        | what it does |
|-------------------|--------------|--------------|
| `pipeline_latest` | `project`,`ref?` | newest pipeline id/status/ref/sha/url |
| `pipeline_status` | `id?`/`ref?` | status/details of a pipeline (latest on ref if no id) |
| `pipeline_jobs`   | `project`,`id` | jobs of a pipeline (id, name, stage, status, url) |
| `job_trace`       | `id`         | job log/trace |
| `mr_list`         | —            | list merge requests (`state`, `limit`) |
| `mr_view`         | `id`         | view a merge request (iid) |
| `mr_diff`         | `id`         | diff/changes of a merge request (iid) |
| `issue_list`      | —            | list issues (`state`, `limit`) |
| `issue_view`      | `id`         | view an issue (iid) |
| `pages_status`    | `project`    | GitLab Pages URL and deployment state |
| `raw`             | `args`       | escape hatch: run any `glab` args verbatim |

`format: "json"` prefers `glab api` endpoints (always JSON). Some actions
(`pipeline_jobs`, `pages_status`) require `project` when `format: "json"` because
they build REST API paths.

## Examples (things you can ask pi)

- "What's the latest pipeline for `maths-lover/devsuraj.pro` and did it pass?"
- "Show me the jobs of pipeline 2708451173 in `maths-lover/devsuraj.pro`."
- "Get the trace for job 123456."
- "List the open MRs in `group/repo`."
- "Show the diff of MR !42 in `group/repo`."
- "Is GitLab Pages deployed for `maths-lover/devsuraj.pro`? What's the URL?"
- "Run `glab ci list -R group/repo`." (→ `raw`)

## Implementation

- `index.ts` — registers the `gitlab` tool, schema, prompt snippet/guidelines,
  and the up-front `glab auth status` check.
- `glab.ts` — `runGlab` / `glabApi` helpers using `execFile` (no shell,
  injection-safe), with a per-call timeout and `AbortSignal` support.

No `package.json`/`node_modules` needed — only `typebox`, `@earendil-works/pi-ai`
(`StringEnum`), `@earendil-works/pi-agent-core` (types), and `node:child_process`.
