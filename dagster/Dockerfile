FROM debian:trixie-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir --break-system-packages --target=/site-packages \
    "dagster==1.13.11" \
    "dagster-webserver==1.13.11"

FROM gcr.io/distroless/python3-debian13

COPY --from=builder /site-packages /site-packages

ENV PYTHONPATH="/site-packages"
ENV PYTHONUNBUFFERED="1"
