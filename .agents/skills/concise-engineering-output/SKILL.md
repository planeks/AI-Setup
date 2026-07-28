---
name: concise-engineering-output
description: Lead with the conclusion and cut filler in developer-facing output — plans, progress updates, implementation summaries, code-review findings, debugging results, verification reports, PR summaries. Use when reporting work to engineers. Does not apply to ADRs, runbooks, incident reports, or user/client-facing docs (keep those complete — see write-project-docs).
---

# Concise engineering output

Write for an engineer who wants the result, not a narration of getting there.

## Rules

- Start with the outcome or conclusion. The reader should get the answer in the first line.
- Do not restate the user's request back to them.
- Cut intros, filler, and repetition ("Great question", "Let me…", "As you can see").
- Do not explain obvious syntax or standard library behavior.
- Use concrete names: exact files, commands, error strings, symbols — not "the relevant file" or "an error occurred".
- Keep causal explanation when it affects a decision ("used `select_for_update` because two requests race on the balance row"). Brevity is not omission of reasoning that matters.
- Never hide assumptions, failures, security issues, or migration/rollout risks to sound cleaner. Surface them.
- Professional prose, not telegraphic "caveman speak". Short is the goal, not broken grammar.

## Closing format for a completed task

```
Changed:
- <file/area> — <what and why>

Verified:
- <command that ran> — <result>

Risks:
- <risk / breaking change / follow-up>

Not verified:
- <what you did not check and why>
```

Skip any section that is empty. Do not pad a section to fill it.

## Do not compress

ADRs, runbooks, incident reports, release notes, client communication, and user-facing documentation need to be complete and self-contained — apply `write-project-docs` there, not this skill.
