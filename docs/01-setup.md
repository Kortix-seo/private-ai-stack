# Setup: the host, the stack, the model keys, the sign-up lock

An open-source private AI stack is only private in the sense you can defend: the
data, the rules and the record sit on hardware you control, and the parts that
still run elsewhere are named out loud. This is the order to build it in — the
model and retrieval services first, then the platform, then the two settings
people skip.

## 1. The host

One Linux server is enough for a team. Size it for three things at once: the
platform's API and database, the model weights in memory, and the vector store.

| Resource | Minimum for a first install | Note |
| --- | --- | --- |
| CPU | 4 vCPU | The platform's services idle low; retrieval and embeddings are the busy part. |
| Memory | 16 GB | An 8B model at 4-bit fits beside the platform in this budget; a 30B model does not. |
| Disk | 100 GB | Model weights dominate. `ollama` keeps every model you pull. |
| Ports | 80 and 443 | Only the platform's Caddy publishes them. Every other published port binds `127.0.0.1`. |
| DNS | one A record, plus a wildcard | The wildcard serves the previews a change request opens. |

Install Docker and the Compose plugin before anything else. `kortix self-host
doctor` fails with `docker` or `docker-compose` when either is missing.

## 2. The model runner and the vector store

```bash
git clone https://github.com/Kortix-seo/private-ai-stack
cd private-ai-stack
cp .env.example .env
# set MODEL_NAME to a model your hardware can hold
docker compose up -d models vectors
./scripts/preflight.sh --pull
```

`preflight.sh` waits for both services, pulls `MODEL_NAME`, and creates the
`company-documents` collection with 768 dimensions (the size `nomic-embed-text`
returns). Change the size in the script if you embed with another model.

Both services bind to `127.0.0.1`. That is deliberate: nothing on the network can
reach the model endpoint until you decide how it should be reached.

## 3. The platform

```bash
curl -fsSL https://kortix.com/install | bash
kortix self-host init --domain kortix.example.com --admin-email you@example.com
kortix self-host start
```

`init` writes the instance `.env` and `docker-compose.yml`; `start` pulls the
images and runs the stack. To try it on a laptop with no domain, use a
Cloudflare tunnel instead:

```bash
kortix self-host init --tunnel cloudflare
kortix self-host start
```

The web app then opens at `http://localhost:13737`, and the API is published at a
random `https://<name>.trycloudflare.com` URL. That URL changes every time
`cloudflared` restarts, so a tunnel is for evaluation, not for a team.

## 4. Wiring the model endpoint

The model runner is a container in this repository's compose project; the
platform is a container in its own. A container on the default bridge cannot
reach the other project's `127.0.0.1`.

Pick one:

- **Publish the runner on the bridge.** Replace the port mapping in
  `docker-compose.yml` with `"11434:11434"` and firewall the host so only the
  platform's network can reach it. This is the fastest path and the one most
  first installs take.
- **One network for both.** Create an external network, attach both compose
  projects to it, and point the project at `http://models:11434/v1`.
- **A hosted endpoint.** Set the project's provider to any OpenAI-compatible
  endpoint with your own key. The stack still owns the rules and the record; the
  tokens leave your network.

In the project, open **Customize → Models → Providers** and add the endpoint with
the model id from `.env` (`llama3.1:8b` by default). Each project needs its own
key. A self-hosted instance has no Kortix-managed models.

## 5. Connect the project to this repository

1. Sign up at `https://<domain>` with an address in `KORTIX_PLATFORM_ADMIN_EMAILS`.
2. Open `/admin/git` and create a GitHub App (recommended). Until it is set,
   Kortix cannot create project repositories.
3. Create one project at `/new` on the account you signed up with, because the
   menu that creates accounts lives inside a project. In it, open the project
   menu → **Switch Project** → **Create an account…** to create the team account;
   your sign-up account is personal, so it cannot hold SAML SSO, and a project
   cannot move to another account. Then create the project your team will use in
   the team account, and point it at this repository (**Import an existing
   repository**).
4. `kortix validate`, then push. `kortix.yaml` becomes the project's rules.

## 6. Close sign-up once the admin and the team are in

This is the step people skip, and it is the one that matters. A new instance
confirms every sign-up without an email, so until you set one of these, anyone
who reaches the instance can create a confirmed account for any address — the
admin address included.

```bash
# send real mail, so sign-ups get verified
kortix self-host env set EMAIL_URL=smtp://user:password@smtp.example.com:587

# or close sign-up once your team is in
kortix self-host env set DISABLE_SIGNUP=true

kortix self-host start        # the auth service reads the new value
```

Then run the checks:

```bash
kortix self-host doctor
```

`doctor` exits 1 on `open-sign-up` while sign-up is open and email confirmation
is off, so a passing run is the proof that the door is closed.

## 7. What a backup has to contain

Stop the stack before copying, or the database is caught mid-write:

```bash
kortix self-host stop
# copy ~/.config/kortix/self-host and each Docker volume, plus the model and
# vector volumes from this repository
kortix self-host start
```

`API_KEY_SECRET`, in the instance `.env`, encrypts every stored secret,
connector credential and token. Lose it and they are unreadable; the Secrets page
marks them `Undecryptable`. Back up `.env` with the same care as the database.

## The limit, stated once

It is not air-gapped, and this repository does not pretend otherwise. Agent
sandboxes run on the compute provider you configure, and the instance has to be
reachable so they can call back. What you own outright is the data, the rules,
the memory and the record. The machine the agent works on is rented.

Next: [docs/02-approvals-and-the-record.md](02-approvals-and-the-record.md).
