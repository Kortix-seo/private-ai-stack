#!/usr/bin/env bash
# Checks that the two services this stack runs are up, that the model is
# present, and that the vector collection exists. Prints the two endpoints a
# Kortix project needs.
#
#   ./scripts/preflight.sh            # check
#   ./scripts/preflight.sh --pull     # pull MODEL_NAME from .env first
set -euo pipefail

cd "$(dirname "$0")/.."

MODEL_HOST="${MODEL_HOST:-http://127.0.0.1:11434}"
QDRANT_HOST="${QDRANT_HOST:-http://127.0.0.1:6333}"
COLLECTION="${COLLECTION:-company-documents}"

if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

MODEL_NAME="${MODEL_NAME:-llama3.1:8b}"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing: $1 — install it first" >&2
    exit 1
  }
}

wait_for() {
  local name="$1" url="$2" i
  for i in $(seq 1 60); do
    if curl -fsS --max-time 3 "$url" >/dev/null 2>&1; then
      echo "ok: $name"
      return 0
    fi
    sleep 2
  done
  echo "not ready: $name ($url)" >&2
  return 1
}

need docker
need curl

docker compose up -d models vectors
wait_for "model runner" "$MODEL_HOST/api/tags"
wait_for "vector store" "$QDRANT_HOST/healthz"

if [[ "${1:-}" == "--pull" ]]; then
  docker compose run --rm models-pull
fi

if ! curl -fsS --max-time 10 "$MODEL_HOST/api/tags" |
  grep -q "\"${MODEL_NAME%%:*}\""; then
  echo "note: $MODEL_NAME is not pulled yet — run: ./scripts/preflight.sh --pull" >&2
fi

# Create the collection if it is absent. 768 dimensions match
# nomic-embed-text; change it if you embed with another model.
if ! curl -fsS --max-time 5 "$QDRANT_HOST/collections/$COLLECTION" >/dev/null 2>&1; then
  curl -fsS --max-time 10 -X PUT "$QDRANT_HOST/collections/$COLLECTION" \
    -H 'content-type: application/json' \
    -d '{"vectors":{"size":768,"distance":"Cosine"}}' >/dev/null
  echo "created collection: $COLLECTION"
else
  echo "ok: collection $COLLECTION"
fi

cat <<EOF

Endpoints for a Kortix project (Customize -> Models -> Providers, and a connector):
  model   ${MODEL_HOST}/v1        model id: ${MODEL_NAME}
  vectors ${QDRANT_HOST}          collection: ${COLLECTION}

Next: docs/01-setup.md
EOF
