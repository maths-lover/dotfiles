---
description: Draft Anki cards into the queue from what was just learned
argument-hint: "[topic or leave blank for the current session]"
---
Read ~/.pi/agent/skills/teacher/SKILL.md and follow it in CARDS mode.

Target: $@ (if empty, use the facts from this session). Enforce the card-making rules. Append cards to 00 - Meta/Automation/anki-queue.jsonl and push them if AnkiConnect is reachable.
