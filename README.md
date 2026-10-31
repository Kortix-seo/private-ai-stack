# A private AI stack you can actually run: the open-source parts, one compose file, one manifest

This repository is the open-source reference stack behind
[privateaiforcompanies.com](https://privateaiforcompanies.com): the parts a
business runs on its own hardware beside Kortix, the model and retrieval
services they need, and the Kortix manifest that owns the rules, the approvals
and the record as files in a git repository you control.

It exists because of one finding. The open-source private AI stack is five
parts — a chat front end, a model runner, retrieval, workflow automation and an
execution agent — and none of those projects claims to police what an agent
may touch or to keep a record that survives an audit. Those two things have to
live somewhere. Here they live in `kortix.yaml`.

Kortix is the open-source CompanyOS: your agents, their skills, your
company memory, and every connector in one git repo you own, with the agents
working on real cloud computers. Self-hosting is free, and the platform installs
as one Docker Compose stack on a server you control.

## What runs where

| Job | Runs here | What the job leaves to you |
| --- | --- | --- |
| Model runner | `ollama` in `docker-compose.yml` (or point `MODEL_BASE_URL` at vLLM, LM Studio or a hosted endpoint) | Tokens only. No tools, no memory, no record. |
| Retrieval | `qdrant` in `docker-compose.yml` | Documents and vectors. Nothing gates an action. |
| Rules, approvals, memory and the record | `kortix.yaml` at the root of this repo, installed as a Kortix project | You set the gates, and you approve the work that reaches `main`. |
| Agent work | Kortix sessions, each on its own isolated sandbox | The sandbox runs on the compute provider you configure, so the machine is rented even when the CompanyOS is not. |
| Chat | The Kortix web app, or any front end you keep (Open WebUI, LibreChat) | A window is a window. The repository is where the work lives. |

## Quickstart

```bash
git clone https://github.com/Kortix-seo/private-ai-stack
cd private-ai-stack
cp .env.example .env          # set MODEL_NAME and a model key if you use a hosted endpoint
docker compose up -d          # the model runner and the vector store
./scripts/preflight.sh        # waits for both, creates the collection, prints the endpoints
```

Then install the platform on the same host, or on a host the model runner can
reach:

```bash
curl -fsSL https://kortix.com/install | bash
kortix self-host init --domain kortix.example.com --admin-email you@example.com
kortix self-host start
```

`init` writes the instance `.env` and compose file and `start` pulls and runs
them. Open `https://kortix.example.com`, sign up with the admin address, connect
a model provider in the project, and close sign-up once your team is in:

```bash
kortix self-host env set DISABLE_SIGNUP=true
kortix self-host start
```

The full sequence, including what to do before the instance is reachable, is in
[docs/01-setup.md](docs/01-setup.md).

## The manifest is the point

`kortix.yaml` in this repository is a working manifest. The manifest format has
no version line, so a `kortix_version` line left in an older project is dropped
with a warning. Two keys in it do the work no project in the stack does:

```yaml
policy:
  default_mode: risk          # a read runs; a write or a delete waits for a person
  policies:
    - match: "crm.update_*"
      action: require_approval
approvals:
  ttl: 4h
```

- `default_mode: risk` makes a write or a delete wait for approval. The platform
  default is `allow_all`, so this line is the change you make on purpose, and it
  is a diff a reviewer can read.
- `policies` matches `<connector>.<tool>` globs and decides `always_run`,
  `require_approval` or `block`. Conditions narrow a rule to arguments.
- `approvals.ttl` bounds how long a held call waits before it expires.

Agents are files too: `agents/private-ai-ops.md` holds the prompt, and the
`agents.private-ai-ops` block in the manifest grants exactly the tools,
connectors and secrets it needs. A prompt change arrives as a change request,
and `git show` answers "what did this say in March".

## What this repository does not claim

- It is not air-gapped. Agent sandboxes run on the compute provider you
  configure, and the instance has to be reachable so they can call back.
- It does not replace the open-source projects in the table. It owns the layer
  they leave out: the rules, the approvals, the memory and the record, as files.
- The model runner here holds weights you choose. It is not a private model
  service, and no licence is implied for any model you download.

## Layout

```
docker-compose.yml        the model runner and the vector store, bound to localhost
.env.example              the two values the compose file reads
scripts/preflight.sh      waits for both services, creates the vector collection
kortix.yaml               the project manifest: agents, grants, policy, approvals
agents/private-ai-ops.md  the agent prompt, as a file
docs/01-setup.md          the host, the stack, the model keys, the sign-up lock
docs/02-approvals-and-the-record.md  the four questions an auditor asks, answered in files
docs/03-faq.md            the questions this stack gets asked
```

## Read more

- [What private AI means for a business](https://privateaiforcompanies.com/what-is-private-ai-for-business)
- [The open-source private AI stack and who owns its rules](https://privateaiforcompanies.com/open-source-private-ai-tools)
- [Running AI agents privately](https://privateaiforcompanies.com/run-ai-agents-privately)
- [Picking a private AI platform by its control plane](https://privateaiforcompanies.com/private-ai-platform)
- [An open source private AI platform comparison you can test yourself](https://privateaiforcompanies.com/private-ai-platform-comparison)
- [Private AI with approvals and an audit trail](https://privateaiforcompanies.com/private-ai-with-approvals-and-audit)
- [Self-hosting Kortix](https://privateaiforcompanies.com/self-hosting-kortix)
- Kortix documentation: <https://kortix.com/docs/developers>

Kortix is open source. Read it, fork it, audit it.
