---
description: Run the planner subagent in a clarification loop until every doubt is cleared, then present the final plan
---
You will produce a plan for the following problem by running the `planner`
subagent in a loop. Do NOT implement anything. Do NOT plan it yourself — the
`planner` agent does the planning. Your job is to drive the loop and relay
questions between the planner and the user.

Problem: $@

Follow this loop exactly:

1. Call the `subagent` tool in single mode with `agent: "planner"` and `task`
   set to the full accumulated context. On the first round the task is just the
   problem above. On every later round, the task MUST include:
   - the original problem,
   - every question the planner asked so far,
   - and the user's exact answers to those questions.
   The planner is stateless, so you must re-send the entire transcript each round.

2. Read the first line of the planner's output:
   - If it starts with `STATUS: NEEDS_CLARIFICATION`: present the planner's
     "Open questions" (and any assumptions) to the user verbatim, clearly and
     numbered. Then STOP and wait for the user's answers. Do not guess answers
     yourself. Once the user replies, go back to step 1 with the answers appended
     to the accumulated context.
   - If it starts with `STATUS: PLAN_READY`: present the full plan to the user and
     stop. The task is complete.

3. Repeat until the planner returns `STATUS: PLAN_READY`. There is no round limit
   — keep clarifying as long as the planner has doubts.

Never produce a plan on your own and never start implementing. Only relay
questions, collect answers, and surface the planner's final plan.
