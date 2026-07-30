#!/usr/bin/env bash
set -euo pipefail

PLATFORM="${1:?Missing platform}"
IMAGE="${2:?Missing image}"
PORT="${3:?Missing port}"
CONTAINER="bristroless-smoke-${PLATFORM//\//-}-$$"

cleanup() {
    docker rm -f "${CONTAINER}" >/dev/null 2>&1 || true
}

trap cleanup EXIT

docker run \
    --rm \
    --platform "${PLATFORM}" \
    --entrypoint /usr/bin/python3 \
    "${IMAGE}" \
    -c 'import dagster; import dagster_webserver'

docker run \
    --rm \
    --platform "${PLATFORM}" \
    --entrypoint /usr/bin/tail \
    "${IMAGE}" \
    --version \
    >/dev/null

docker run \
    --rm \
    --platform "${PLATFORM}" \
    --entrypoint /bin/sh \
    "${IMAGE}" \
    -c 'test -x /usr/bin/tail'

docker run \
    --detach \
    --name "${CONTAINER}" \
    --platform "${PLATFORM}" \
    --publish "127.0.0.1:${PORT}:3000" \
    "${IMAGE}" \
    --empty-workspace \
    -h 0.0.0.0 \
    -p 3000 \
    >/dev/null

for _ in $(seq 1 120); do
    if curl \
        --fail \
        --silent \
        "http://127.0.0.1:${PORT}/" \
        >/dev/null 2>&1; then
        exit 0
    fi

    if [[ "$(docker inspect --format '{{.State.Running}}' "${CONTAINER}")" != "true" ]]; then
        docker logs "${CONTAINER}"
        exit 1
    fi

    sleep 1
done

docker logs "${CONTAINER}"
exit 1
