# Approvals and the record: the four questions an auditor asks

This is the open-source answer to the part of a private AI stack that the
projects in `docker-compose.yml` do not cover. Four questions come up in every
security review of an agent deployment, and each one is answered by a file in
this repository rather than by a screenshot of a settings page.

## 1. Which instructions was the agent given?

The prompt is `agents/private-ai-ops.md`. The agent block in `kortix.yaml` grants
it tools, connectors, skills and secrets by name. Both are files, so:

```bash
git log -p agents/private-ai-ops.md      # every version of the prompt
git show <sha>:kortix.yaml               # the grants as they were that day
```

A prompt typed into a form and stored in a database cannot answer "what did this
say in March". A file can, and the diff is the review.

## 2. What was it allowed to touch, and who could change that?

`kortix.yaml` resolves every connector call in a fixed order: the project
policies, then the calling agent's policy set, then the connector's own base
rules. The first matching rule decides.

```yaml
policy:
  default_mode: risk
  policies:
    - match: "*.delete_*"
      action: block
approvals:
  ttl: 4h
```

- `default_mode: risk` runs a read and holds a write or a delete for approval.
  The platform default is `allow_all`, so this is a deliberate setting and it
  shows up in the diff like any other change.
- `match` is a glob over `<connector-slug>.<tool>` — `crm.update_*`,
  `*.delete_*`, `gmail.send_*`.
- `action` is `always_run`, `require_approval` or `block`.
- `conditions` narrow a rule to arguments: `{ arg: to, match: "*@example.com",
  negate: true }` holds every send that leaves the company domain.
- `approvals.ttl` bounds the wait. A held call that nobody decides within the
  window expires; it does not run.

Because the rules are in the repository, "who can change this" is the same
question as "who can merge to `main`". Session work reaches `main` through a
change request, and merge is default-deny for agents unless an admin granted
`project.gitops.merge`.

## 3. What actually ran, on which machine, approved by whom?

Every action is recorded. Reading, exporting and streaming the audit log depend
on the plan. Each session has its own isolated sandbox and its own branch, so the
record can say which machine ran the work and which branch it landed on.

Two halves make the answer readable:

- **The session record** — the session log holds the turns, the tool calls and
  the results.
- **The change record** — the change request holds the diff, the reviewer's
  comments and the merge. `approvals` holds the decisions on held calls.

The audit question — *which agent, holding which instructions, on whose machine,
approved by whom, at what time* — is answered by joining those three, and all
three are exportable from an instance you run.

## 4. Can I take it away?

Yes, and this is the test worth running before you sign anything:

1. Run one workflow the business already runs.
2. Ask for the instructions the agent was given, and the record of what it did.
3. Open both on a laptop that is not connected to the vendor.

If the instructions come back as a screenshot of a settings page, the stack is a
rental with a private address. If the record comes back as a support ticket, it
will still be a support ticket at the next audit.

In this repository the instructions are `agents/*.md` and `kortix.yaml`; the
record is the instance's session log, the change requests and the audit log; the
memory is `memory/`. `git clone` is the export.

## What the stack still leaves to you

Three duties do not go away when the software is open source:

- **The updater.** An instance that stops pulling images collects last year's
  bugs. `kortix-updater` runs daily by default; check `kortix self-host status`
  for its last outcome.
- **The secrets.** `API_KEY_SECRET` encrypts everything else. A backup that
  misses it is not a backup.
- **The gates.** `default_mode` starts at `allow_all`. Nobody sets `risk` for
  you, and a gate nobody reviewed is not a control.
