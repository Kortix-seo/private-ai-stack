# FAQ: the questions this open-source private AI stack gets asked

Short answers, and the limit each one leaves in place.

## Is this stack really private?

The parts that decide privacy are on hardware you control: the model runner, the
vector store, the platform's database and files, the rules and the record. Two
things still leave: tokens go to whichever model endpoint you configure, and
agent sandboxes run on the compute provider you set. Check where those two sit
before you call a deployment private.

## Do I need the model runner in this repository?

No. `MODEL_BASE_URL` can point at anything OpenAI-compatible: vLLM on a GPU box,
LM Studio on a workstation, or a hosted endpoint with your own key. The runner is
here so a first install has one path that works without a GPU purchase.

## Why is the platform not in `docker-compose.yml`?

Because Kortix installs itself as its own compose project, with its own `.env`,
its own volume names and its own updater:

```bash
kortix self-host init --domain kortix.example.com --admin-email you@example.com
kortix self-host start
```

Keeping the two projects apart means an update to one does not restart the
other's containers mid-session.

## What does the platform cost?

Self-hosting is free. The paid plan is credits: 25 tiers from $50 a month (5,000
credits) to $50,000 a month (5,000,000 credits), at 100 credits per dollar.
Members are unlimited and free, and the account shares one credit pool. A
self-hosted instance has no Kortix-managed models, so model spend is whatever
your provider charges or whatever your hardware already cost.

## Can an agent merge its own work?

No by default. Session work reaches `main` through a change request, and merge is
default-deny for agents unless an admin granted the merge capability
(`project.gitops.merge`).

## Are the approval gates on?

"Approval gates you set. Off until you set them." The manifest default is
`allow_all`; this repository sets `default_mode: risk` so a write or a delete
waits for a person. That line is the change you review.

## What about SSO and an audit log?

SAML 2.0 single sign-on and SCIM 2.0 are part of the platform. Every action is
recorded; reading, exporting and streaming the audit log depend on the plan.

## Is it air-gapped?

No, and this repository will not pretend otherwise. The instance pulls images
from a registry, and sandboxes call back to it. What you own is the data, the
rules, the memory and the record; the machine the agent works on is rented.

## Which projects does the stack build on?

`docker-compose.yml` runs Ollama (MIT) and Qdrant. The projects a team usually
adds beside them — Open WebUI, AnythingLLM, Onyx, LibreChat, Dify, n8n — each
publish their own licence, and each is worth reading before you ship it. The
boundary none of them crosses is the one this repository fills: the rules, the
approvals, the memory and the record as files.

## More

- [Setup](01-setup.md)
- [Approvals and the record](02-approvals-and-the-record.md)
- <https://privateaiforcompanies.com>
