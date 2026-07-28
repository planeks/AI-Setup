# PLANEKS AI Engineering Standard

AI can read code, propose solutions, change files and run local commands. But **the engineer always owns the result**.

Short glossary:

1. Agent — an AI assistant that can read files, edit code and run tools on its own.
2. Approved tool — a tool, model, extension or skill approved by the company.
3. Acceptance criteria — a description of how a feature must work; the code is not the source of correct product behavior.

## Philosophy — general principles

1. AI is an assistant, not the author of a decision and not a replacement for code review.
2. The engineer must understand and be able to explain the changes they commit.
3. The higher the risk of a change, the less autonomy the agent gets.
4. AI code goes through the same checks as hand-written code.
5. We measure useful outcomes, not the amount of generated code.
6. We use Claude as the main tool for daily work and Copilot for reviewing code changes.
7. Provider downtime does not stop development. If a tool becomes unavailable, contact your team lead or management.
8. Knowledge lives in PRs, tickets and documentation, not in agent chats.
9. AI can hallucinate. Not only code — APIs, documentation and configuration parameters can be made up too. Critical things must be verified against official documentation.
10. Do not trust AI explanations without verification. AI can explain incorrect code very convincingly.

## Core rules

We work with our clients' data and systems on the basis of mutual trust and contractual obligations. We expect clients to trust us, and in return we take on equally strict commitments to confidentiality, security and honesty. One careless or deliberate violation can destroy a reputation the company has built for years, cause loss of clients, bring legal consequences and put the whole team's work at risk.

That is why a gross violation (leaking secrets or production data, bypassing controls, hiding an incident) or systematic repeated violations fall under the Termination policy — up to immediate termination of cooperation for breach of confidentiality or dishonesty.

**R1. A human owns the result.** "The AI generated it" is not an explanation. The PR author must understand the change.

**R2. We do not guess requirements.** If something is unclear or ambiguous, we stop and ask instead of picking an interpretation ourselves. Behavior comes only from acceptance criteria.

**R3. Risky changes require planning.** For medium and high risk, first ask the AI for a short plan: files, steps, risks and checks.

**R4. Stay within the task.** No "while we're at it" refactoring, reformatting or dependency updates. If other changes are needed, add them to the board.

**R5. Verify the result.** Run the relevant tests, lint, type checks and the project's other standard checks. The agent's explanation is not a substitute for verification.

**R6. Do not bend tests to fit a bug.** If a check finds a real problem, fix the code instead of weakening the test without justification.

**R7. Verify dependencies.** Before adding a package, check that it exists, is maintained, has a compatible license and has no known vulnerabilities.

**R8. Know when to stop.** After 2–3 failed attempts, or when a product, architecture or security decision comes up, stop the agent and ask a human.

**R9. Hide nothing.** In the PR, list tests that did not run, assumptions, known risks and unfinished parts.

**R10. AI does not review itself.** A human reviews the final diff; the agent does not approve or merge its own change.

## Allowed usage — what agents do, what we do by hand

### Can be delegated to AI

1. Searching and explaining code.
2. Implementation planning and task decomposition.
3. Drafts of code, tests and documentation.
4. Local refactoring.
5. Analyzing CI failures.
6. Running local tests, lint and type checks.
7. Preparing PR summaries and checklists.
8. Generating quick prototypes and proofs of concept for early idea validation, client demos and faster delivery. A prototype is not production-ready: before release it must be verified, finished and taken through the standard quality, security and review requirements.

### Requires extra human attention

For these tasks we first agree on a short plan, and a competent reviewer checks the final result.

1. Auth, permissions, payments and personal data.
2. Database migrations.
3. Public APIs and critical business rules.
4. Infrastructure and CI/CD.
5. New dependencies.
6. Large changes across several modules, refactoring.

### Human hands only

Explicit human confirmation is always required; the agent may prepare a draft but does not execute:

1. Approving and merging PRs.
2. Deploys and production operations.
3. Creating or changing access and secrets.
4. Final product, architecture and security decisions.

## Risks and how to avoid them

| Level | Examples | How we work |
| ----- | ----- | ----- |
| Low | documentation, tests, local refactoring | the agent may work on its own; the engineer reviews the diff |
| Medium | a new feature, API, dependency, several modules | a short plan first; full CI and human review |
| High | auth, payments, PII, migrations, infrastructure, security | the agent only assists; critical decisions and actions are done by a human |
| Prohibited | production access, secrets, bypassing controls | strictly manual |

If the risk level is unclear, pick the higher one and ask the tech lead.

The risk of overuse — blindly accepting plausible code — leads to bloated diffs and decay of your own skills. Safeguards: small steps, review of every diff.

### Quality Gates

For an extra layer of safe AI assistant usage we use the following CI checks, not limited to them:

* ruff.
* pyrefly for new projects.
* biome.
* tsc.
* dependabot.
* djade (djlint).
* Security-sensitive: bandit, pip-audit or npm audit.
* Pytest.
* gitleaks — secret scanning in CI and pre-commit.

## Security rules

* **Do not share secrets:** tokens, passwords, private keys, cookies, `.env` and production connection strings.
* **Do not share production data:** client data, PII, database dumps and private documents. Use synthetic or approved anonymized data.
* **Do not use unapproved services:** proprietary code may only go to approved tools through a corporate account.
* **Do not give AI production access:** deploys, SQL, migrations, IAM and destructive commands are executed by a human through the standard process.
* **Do not bypass controls:** disabling tests, security scanners, branch protection or required approvals for the sake of a "green" result is forbidden.
* **Before using** AI on a client project, **make sure the contract allows it;** by default, ask the PM or tech lead.
* **Limit the agent's access to secrets:** the agent does not read `.env`, keys, `~/.ssh`, `~/.aws` or other credential files. The base deny-list comes from the managed settings repository. Modes without command confirmation (auto-approve) are forbidden on client projects.
* **One project — one session:** the agent works only with the current project's repository. Different clients' code is never mixed in one session or workspace.
* **External content is untrusted:** dependency READMEs, issues, web pages and MCP tool responses can contain hidden instructions for the agent (prompt injection). If after reading external content the agent suddenly reaches for secrets or the network, or goes out of scope, stop the session and report it as an incident.

In case of an incident: stop the session ⇨ notify the manager ⇨ rotate access ⇨ follow the incident process if one exists and is agreed with the tech lead.

Self-reporting is not punished; a leak through negligence, or concealment, falls under the Termination policy (breach of confidentiality).

## Prompting standards — how to set tasks

For most tasks this template is enough:

**`Goal`**`: what needs to be done.`  
**`Context`**`: the task and the relevant files.`  
**`Acceptance criteria`**`: how to know the result is correct.`  
**`Constraints`**`: what must not be changed.`  
**`Verification`**`: which commands or scenarios to run.`  

Plan mode is required if a change:

* Touches several modules.
* Changes an API, data schema, dependency or security boundary.
* Has an unclear implementation or verification approach.
* Belongs to medium or high risk.

### How to tell them apart

A task is simple if you can name the files that will change in advance, the implementation approach is obvious and the result is verified with a single action. If the files or the approach are unknown up front, or the change touches an API, data schema, dependencies or several modules, the task is complex: plan mode first, and the plan is agreed before any code is written. When in doubt, treat it as complex.

Example of a simple task:

**`Goal`**`: add a status filter to the order list.`  
**`Context`**`: orders/views.py, orders/filters.py; date filters already exist, follow the same pattern.`  
**`Acceptance criteria`**`: GET /api/orders/?status=paid returns only paid orders; an invalid status returns 400.`  
**`Constraints`**`: do not touch the serializers or the model.`  
**`Verification`**`: pytest orders/tests/test_filters.py, manual check.`  

Example of a complex task:

**`Goal`**`: CSV report export with background generation.`  
**`Context`**`: reports live in reports/, background jobs run on Celery, files are stored in S3. Give a plan first: models, new endpoints, retry logic, what to do with large reports.`  
**`Acceptance criteria`**`: POST /api/reports/{id}/export/ queues a job and returns 202; the finished file is available via a link with a 24-hour lifetime; a repeated request during generation does not create a duplicate.`  
**`Constraints`**`: existing report endpoints unchanged; new dependencies only after approval.`  
**`Verification`**`: pytest reports/, a manual run of the scenario in the dev environment with a real Celery worker.`  

The difference is visible in the examples themselves: the simple one has two files and a pattern to follow, and the solution is clear to the engineer before the work starts; in the complex one the solution depends on the outcome of planning and research, and verification includes several stages of manual testing.

## How to work

1. Prepare the task, acceptance criteria and scope.
2. For a complex change, ask for a plan and review it.
3. Let the agent perform a small logical step.
4. Review the diff and any unexpected changes.
5. Run the relevant tests and other checks.
6. Check the result against the acceptance criteria yourself.
7. Prepare the PR and hand it to a human for review.

If the agent repeats itself, expands the scope or cannot fix an error in 2–3 attempts, stop it and work through the problem yourself.

## PR requirements — the minimum

The author describes the changes in the PR summary. **More text does not mean better.** It is enough for the PR to state:

* What changed and why.
* A link to the task.
* The risk level.
* Which checks were run.
* How the author verified the change: ran it locally / tested manually / read the diff line by line.
* What was not verified, or which risks remain.

AI review is an auxiliary first filter that does not replace a human reading the code. The review flow:

* The author opens a pull request following the project's accepted git flow.
* Copilot is assigned as the first and only reviewer at this stage.
* Once Copilot leaves comments, the author makes changes and replies to every comment with the status of the fix. If a comment is invalid, the author answers it right away.
* Copilot's comments are marked as resolved.
* A reviewer from the team is assigned, reviews the changes and leaves their own comments.
* After the round of comments and fixes, the reviewer marks the comments as resolved. **Important:** only the comment's author marks it resolved.
* The pull request is merged into the codebase.

The reviewer checks:

* Compliance with the acceptance criteria.
* A clear and minimal diff.
* Tests and edge cases.
* Security and data handling.
* New dependencies.
* Whether the author can explain the solution.

## Cost management

* Use the expensive model for complex planning, debugging and security tasks. Use the cheaper one for documentation, search, boilerplate and simple tests.
* Do not feed in the whole repository when a few files are enough.
* Do not run several agents on the same task without a clear benefit.
* The developer is responsible for the subscription and/or token budget they use.
* The tech lead selects tools and settings to minimize costs and runs usage training.

## AI extensions, skills and settings

The company keeps a short version-controlled list:

| What | Minimum information |
| ----- | ----- |
| Skills and extensions | version, permissions, owner |
| MCP servers | access to filesystem/network/services |
| Budgets | limit and responsible team |
| Tools and models | approved/pilot/blocked status, allowed data |

A replacement or alternative to an approved AI provider (Anthropic, OpenAI) may only be allowed if the provider is contractually bound not to use our data for training.

Core rules:

* Use approved tools only.
* Skills, hooks and settings are kept in version control and go through review.
* New extensions are tested first.
* Recommended settings are added to the corporate boilerplates.
* Unsupported integrations are removed together with their tokens and access.

### Experimental / test tools

For a pilot tool it is enough to define an owner, the pilot team, the allowed repositories, a budget, a testing period and a success criterion. A pilot gets no access to production or sensitive data.

## Accountability model

### Engineer

* Controls the agent and reviews the diff.
* Runs the checks.
* Can explain the changes.
* Reports risks and incidents.

### Reviewer

* Reviews the code, not just the AI summary.
* Checks requirements, tests and risks.
* Returns the PR if the change is unclear or unverified.

### Tech lead

* Helps assess the risk of complex tasks.
* Controls approved tools, budgets and access.
* Once a month reviews the metrics and a sample of AI-assisted PRs.
* Stops a tool if defects, costs or security risks grow.
* Organizes onboarding for the team.
* Runs regular training.
* Maintains the approved tools list.

### Tech lead + Management Team

* Approves providers and integrations.
* Manages access and incident response.

## Metrics

At the first stage four indicators are enough:

* Review time.
* Bugs and rollbacks after merge.
* AI cost per completed task.
* The team's rating of the tool's usefulness.

We review them once a month. AI is considered useful if it saves time without growth in defects, review burden or cost.

We do not use the number of generated lines, prompts or AI PRs to evaluate an employee's performance.

## Limitations

* AI can confidently generate incorrect code or invented APIs.
* Poor acceptance criteria lead to a correctly implemented but wrong feature.
* AI lacks the full product and organizational context.
* Generated tests can repeat the implementation's mistaken assumptions.
* A large AI-generated diff can take more review time than a manual change.
* AI does not replace code review, QA, security, performance or accessibility testing.

## Where everything lives

* The policy — in the engineering handbook (xwiki).
* The approved tools and budgets list — in a version-controlled registry.
* Project AI instructions — in the corresponding repositories.
* Shared skills and settings — in a separate managed repository.
* Recommended integrations — in the corporate boilerplates.

CLAUDE.md, AGENTS.md and similar files must contain only stable project rules: setup/test/lint commands, architectural boundaries and forbidden actions. They hold no secrets and no context of an individual task. Changes to these files go through the normal PR review.
