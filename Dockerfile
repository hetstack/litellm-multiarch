# syntax=docker/dockerfile:1.4

FROM --platform=$TARGETPLATFORM python:3.11-slim-bookworm AS builder

ARG TARGETPLATFORM

ENV CARGO_HOME=/root/.cargo
ENV RUSTUP_HOME=/root/.rustup
ENV PATH="/root/.cargo/bin:$PATH"
ENV PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libssl-dev \
    libffi-dev \
    pkg-config \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y \
        --default-toolchain stable \
        --profile minimal \
        --no-modify-path \
    && /root/.cargo/bin/rustc --version

RUN pip install --upgrade pip setuptools wheel

# Pre-instalacja bazowych zależności
RUN --mount=type=tmpfs,target=/root/.cargo/registry \
    --mount=type=tmpfs,target=/root/.cargo/git \
    pip install --no-cache-dir \
    --prefer-binary \
    "uuid_utils>=0.14.0" \
    "boto3==1.42.80" \
    "click==8.1.8" \
    "aiohttp==3.13.5"

# Stub packages - pełne metadane dla ARMv7
RUN sp="/usr/local/lib/python3.11/site-packages" && \
    mkdir -p "$sp/pyroscope" && echo "# stub" > "$sp/pyroscope/__init__.py" && \
    mkdir -p "$sp/pyroscope_io-0.8.16.dist-info" && \
    echo -e "Metadata-Version: 2.1\nName: pyroscope-io\nVersion: 0.8.16" > "$sp/pyroscope_io-0.8.16.dist-info/METADATA" && \
    echo "pip" > "$sp/pyroscope_io-0.8.16.dist-info/INSTALLER" && \
    touch "$sp/pyroscope_io-0.8.16.dist-info/RECORD" && \
    mkdir -p "$sp/polars_runtime_32" && echo "# stub" > "$sp/polars_runtime_32/__init__.py" && \
    mkdir -p "$sp/polars_runtime_32-1.39.3.dist-info" && \
    echo -e "Metadata-Version: 2.1\nName: polars-runtime-32\nVersion: 1.39.3" > "$sp/polars_runtime_32-1.39.3.dist-info/METADATA" && \
    echo "pip" > "$sp/polars_runtime_32-1.39.3.dist-info/INSTALLER" && \
    touch "$sp/polars_runtime_32-1.39.3.dist-info/RECORD"

# Instalacja litellm[proxy]
RUN --mount=type=tmpfs,target=/root/.cargo/registry \
    --mount=type=tmpfs,target=/root/.cargo/git \
    pip install --no-cache-dir \
    --prefer-binary \
    "litellm[proxy]==1.83.4"

# Weryfikacja
RUN pip show litellm \
    && python3 -c "import importlib.metadata; v = importlib.metadata.version('litellm'); print('litellm version:', v)" \
    && ls -la /usr/local/bin/litellm \
    && python3 -c "from litellm.proxy import proxy_server; print('proxy import OK')"

# ============================================================
FROM --platform=$TARGETPLATFORM python:3.11-slim-bookworm AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl3 \
    libffi8 \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -r -u 1001 -g root litellm

COPY --from=builder /usr/local/lib/python3.11/site-packages \
                    /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin/litellm \
                    /usr/local/bin/litellm

WORKDIR /app

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:4000/health || exit 1

USER litellm
EXPOSE 4000
CMD ["litellm", "--config", "/app/config.yaml", "--port", "4000", "--host", "0.0.0.0"]