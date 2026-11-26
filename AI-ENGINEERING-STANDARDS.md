# PLANEKS AI Engineering Standards

AI can read code, propose solutions, change files and run local commands. But the engineer always owns the result.
 
General principle: we keep strict control over data, secrets, environments and merges, and trust the engineer with the process of working with the agent in between.
 
**Short glossary:**
 
- **Agent** — an AI assistant that can read files, edit code and run tools on its own.
- **Acceptance criteria** — a description of how a feature must work; the code is not the source of correct product behavior.
- **Sandbox** — an isolated environment (devcontainer, VM or the tool's own sandbox) with no access to the host's credential files, real .env files or production networks.
## Philosophy — general principles
 
- AI is an assistant, not the author of a decision and not a replacement for code review.
- The engineer must understand and be able to explain the changes they commit.
- The higher the risk of a change, the less autonomy the agent gets.
- AI code goes through the same checks as hand-written code.
- We measure useful outcomes, not the amount of generated code.
- Provider downtime does not stop development. If a tool becomes unavailable, contact your team lead or management.
- Knowledge lives in PRs, tickets and documentation, not in agent chats.
- AI can hallucinate. Not only code — APIs, documentation and configuration parameters can be made up too. Critical things must be verified against official documentation.
- Do not trust AI explanations without verification. AI can explain incorrect code very convincingly.
## Core rules
 
We work with our clients' data and systems on the basis of mutual trust and contractual obligations. We expect clients to trust us, and in return we take on equally strict commitments to confidentiality, security and honesty. One careless or deliberate violation can destroy a reputation the company has built for years, cause loss of clients, bring legal consequences and put the whole team's work at risk.
 
That is why a gross violation (leaking secrets or production data, bypassing controls, hiding an incident) or systematic repeated violations fall under the Termination policy — up to immediate termination of cooperation for breach of confidentiality or dishonesty. Honest mistakes within the rules, including in a sandbox, are not punished; penalties apply to gross violations, negligent leaks and concealment.
 
**R1. A human owns the result.** "The AI generated it" is not an explanation. The PR author must understand the change, unless the client has agreed otherwise.
 
**R2. We do not guess requirements.** If something is unclear or ambiguous, we stop and ask instead of picking an interpretation ourselves. Behavior comes only from acceptance criteria.
 
**R3. Risky changes require planning.** For medium and high risk, first ask the AI for a short plan (files, steps, risks, checks), and the engineer approves it before any code is written.
 
**R4. Stay within the task.** No "while we're at it" refactoring outside the task.
 
**R5. Verify the result.** Run the relevant tests, lint, type checks and the project's other standard checks. The agent's explanation is not a substitute for verification.
 
**R6. Do not bend tests to fit a bug.** If a check finds a real problem, fix the code instead of weakening the test without justification.
 
**R7. Verify dependencies.** Before adding a package, check that it exists, is maintained, has a compatible license and has no known vulnerabilities.
 
**R8. Know when to stop.** Stop the agent if it goes in circles (repeats the same fixes without new information), expands the scope or runs into a product, architecture or security decision, and ask a human. Rule of thumb: 20–30 minutes without progress.
 
**R9. Hide nothing.** In the PR, list tests that did not run, assumptions, known risks and unfinished parts.
 
**R10. The agent does not approve or merge.** AI review before opening a PR (in a separate session or with another model) is encouraged as an extra filter, but it does not replace human review.
 
## Allowed usage — what agents do, what we do by hand
 
### Requires extra human attention
 
The agent may write code for these tasks, but we first agree on a short plan, and a competent reviewer checks the final result:
 
- Auth, permissions, payments and personal data.
- Database migrations.
- Public APIs and critical business rules.
- Infrastructure and CI/CD.
- New dependencies.
- Large changes across several modules, refactoring.
### Human hands only
 
A human is always required; the agent may prepare a draft but does not execute:
 
- Moving a PR to ready for review, approving and merging.
- Deploys and production operations.
- Any actions on real environments: migrate on stage/prod, terraform apply, IAM changes.
- Creating or changing access and secrets.
- Final product, architecture and security decisions.
The agent handles git work on its own: it creates branches, commits, pushes to a feature branch and opens a draft PR.
 
### Sandbox mode for prototypes
 
A separate mode for prototypes, PoCs and internal tools with no client code or data. In this mode the following are allowed:
 
- auto-approve;
- working without an upfront plan;
- several agents in parallel;
- pilot tools and models.
A prototype is not production-ready. Code moves into a client project only through the standard process, with its quality, security and review requirements.
 
## Risks and how to avoid them
 
| Level | Examples | How we work |
| --- | --- | --- |
| Low | documentation, tests, local refactoring | the agent works on its own; the engineer reviews the diff |
| Medium | a new feature, API, dependency, several modules | a short plan approved by the engineer before coding; full CI and human review |
| High | auth, payments, PII, migrations, infrastructure, security | the agent may write code; an approved plan, review by a competent reviewer and human execution of everything that touches real environments are mandatory |
| Prohibited | production access, secrets, bypassing controls | strictly manual |
 
If the risk level is unclear, pick the higher one and ask the tech lead.
 
The risk of overuse — blindly accepting plausible code — leads to bloated diffs and decay of your own skills. Safeguards: small steps, review of every diff.
 
## Quality Gates
 
For an extra layer of safe AI assistant usage we use the following CI checks, not limited to them:
 
- ruff.
- pyrefly for new projects.
- biome.
- tsc.
- dependabot.
- djade (djlint).
- Security-sensitive: bandit, pip-audit or npm audit.
- Pytest.
- gitleaks — secret scanning in CI and pre-commit.
## Security rules
 
- **Do not share secrets:** tokens, passwords, private keys, cookies, .env and production connection strings.
- **Do not share production data:** client data, PII, database dumps and private documents. Use synthetic or approved anonymized data.
- **Do not use unapproved services:** proprietary code may only go to the tools listed in "AI tools" or ones agreed with the team lead, through a corporate account.
- **Do not give AI production access:** deploys, SQL, migrations on real environments, IAM and destructive commands are executed by a human through the standard process.
- **Do not bypass controls:** disabling tests, security scanners, branch protection or required approvals for the sake of a "green" result is forbidden.
- **Client contract:** before using AI on a client project, make sure the contract allows it; by default, ask the PM or tech lead.
- **Limit the agent's access to secrets:** the agent does not read .env, keys, `~/.ssh`, `~/.aws` or other credential files. The base deny-list comes from the managed settings repository.
- **Auto-approve only in an isolated environment:** devcontainer, VM or the tool's sandbox. Conditions: no access to the host's credential files, real .env files or production networks; egress limited by an allowlist (package registries, GitHub, documentation). On a host machine with real access, auto-approve is forbidden. The base sandbox configuration lives in the managed settings repository.
- **One project, one session:** the agent works only with the current project's repository. Different clients' code is never mixed in one session or workspace.
- **External content is untrusted:** dependency READMEs, issues, web pages and MCP tool responses can contain hidden instructions for the agent (prompt injection). If after reading external content the agent suddenly reaches for secrets or the network, or goes out of scope, stop the session and report it as an incident.
- **In case of an incident:** stop the session ⇨ notify the manager ⇨ rotate access ⇨ follow the incident process if one exists and is agreed with the tech lead.
Self-reporting is not punished; a leak through negligence, or concealment, falls under the Termination policy (breach of confidentiality).
 
## Prompting standards — how to set tasks
 
The example below shows a sufficient level of detail for a task given to an agent.
 
- **Goal:** CSV report export with background generation.
- **Context:** reports live in reports/, background jobs run on Celery, files are stored in S3. Give a plan first: models, new endpoints, retry logic, what to do with large reports.
- **Acceptance criteria:** POST /api/reports/{id}/export/ queues a job and returns 202; the finished file is available via a link with a 24-hour lifetime; a repeated request during generation does not create a duplicate.
- **Constraints:** existing report endpoints unchanged; new dependencies only after approval.
- **Verification:** pytest reports/, a manual run of the scenario in the dev environment with a real Celery worker.
## PR requirements — the minimum
 
The author describes the changes in the PR summary. More text does not mean better. It is enough for the PR to state:
 
- What changed and why.
- A link to the task.
- The risk level.
- Which checks were run.
- How the author verified the change: ran it locally / tested manually / read the diff line by line.
- What was not verified, or which risks remain.
Expected PR size: up to 1,500 lines.
 
AI review is an auxiliary first filter that does not replace a human reading the code. The review flow:
 
1. The author opens a pull request following the project's git flow, or moves a draft PR opened by the agent to ready for review.
2. The AI agent is assigned as the first reviewer. A team reviewer may work in parallel without waiting for the AI review to finish.
3. The author does not have to reply to the agent's comments one by one: they resolve fixed and invalid comments themselves.
4. A team reviewer reviews the changes and leaves their own comments.
5. After the round of comments and fixes, the reviewer marks their comments as resolved. A human's comment is marked resolved only by its author.
6. A human approves and merges the pull request into the codebase.
The reviewer checks:
 
- Compliance with the acceptance criteria.
- A clear and minimal diff.
- Tests and edge cases.
- Security and data handling.
- New dependencies.
- Whether the author can explain the solution.
## Cost management
 
- The developer works within a monthly budget and is responsible for the subscription and/or token budget they use.
- Choosing a model per task is a recommendation, not a rule. If the remaining tokens before the next limit reset allow it, there is no need to artificially restrict yourself to a cheaper model.
- If a developer accidentally runs out of limits, they should have a plan B (for example, a personal subscription they can switch to for a while) and let the tech lead know.
- Do not feed in the whole repository when a few files are enough.
- Outside sandbox mode, do not run several agents on the same task without a clear benefit.
- The tech lead selects tools and settings to minimize costs and runs usage training.
## AI tools, extensions and settings
 
Tools we use:
 
| Tool | Used for |
| --- | --- |
| Claude (Claude Code) | the main tool for daily work |
 
All other tools, extensions, MCP servers and questions about them are settled directly with the team lead. Experimenting with new tools is encouraged — in sandbox mode, without client code or data.
 
- A replacement or alternative to an AI provider (Anthropic, OpenAI) is allowed only if the provider is contractually bound not to use our data for training.
- Skills, hooks and settings are kept in version control and go through review.
- Recommended settings are added to the corporate boilerplates.
- Unsupported integrations are removed together with their tokens and access.
## Accountability model
 
### Engineer
 
- Controls the agent and reviews the diff.
- Approves the plan for medium- and high-risk tasks.
- Runs the checks.
- Can explain the changes.
- Reports risks and incidents.
### Reviewer
 
- Reviews the code, not just the AI summary.
- Checks requirements, tests and risks.
- Returns the PR if the change is unclear or unverified.
### Tech lead
 
- Helps assess the risk of complex tasks.
- Controls tools, budgets and access.
- Once a month reviews the metrics and a sample of AI-assisted PRs.
- Stops a tool if defects, costs or security risks grow.
- Organizes onboarding and regular training for the team.
- Maintains the tools list and the base sandbox configuration.
### Tech lead + Management Team
 
- Approves providers and integrations.
- Manages access and incident response.
## Metrics
 
At the first stage four indicators are enough:
 
- Review time.
- Bugs and rollbacks after merge.
- AI cost per completed task.
- The team's rating of the tool's usefulness.
We review them once a month. AI is considered useful if it saves time without growth in defects, review burden or cost.
 
We do not use the number of generated lines, prompts or AI PRs to evaluate an employee's performance.
 
## Limitations
 
- AI can confidently generate incorrect code or invented APIs.
- Poor acceptance criteria lead to a correctly implemented but wrong feature.
- AI lacks the full product and organizational context.
- Generated tests can repeat the implementation's mistaken assumptions.
- A large AI-generated diff can take more review time than a manual change.
- AI does not replace code review, QA, security, performance or accessibility testing.
