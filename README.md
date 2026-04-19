<div align="center">

# 🤖 LiteLLM Multi-Arch Docker

### Unofficial multi-architecture Docker image for LiteLLM 1.83.4

[![Docker Hub](https://img.shields.io/docker/pulls/hetstack/litellm-multiarch?style=for-the-badge&logo=docker&logoColor=white)](https://hub.docker.com/r/hetstack/litellm-multiarch)
[![Docker Image Size](https://img.shields.io/docker/image-size/hetstack/litellm-multiarch/latest?style=for-the-badge&logo=docker)](https://hub.docker.com/r/hetstack/litellm-multiarch)
[![GitHub Actions](https://img.shields.io/github/actions/workflow/status/hetstack/litellm-multiarch/docker.yml?style=for-the-badge&logo=github)](https://github.com/hetstack/litellm-multiarch/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)
[![Architectures](https://img.shields.io/badge/arch-amd64%20%7C%20arm64%20%7C%20armv7-blue?style=for-the-badge)](#-supported-architectures)
[![LiteLLM](https://img.shields.io/badge/LiteLLM-1.83.4-green?style=for-the-badge)](https://github.com/BerriAI/litellm)

---

🌐 **Language / Język:** &nbsp; [🇬🇧 English](#english) &nbsp;|&nbsp; [🇵🇱 Polski](#polski)

</div>

---

<a name="english"></a>

## 📖 About

This project provides an **unofficial, multi-architecture Docker image** for
[LiteLLM](https://github.com/BerriAI/litellm) version **1.83.4** – a popular proxy
and unified API gateway for large language models (LLMs) such as OpenAI, Anthropic,
Ollama, Mistral, and many more.

The official LiteLLM Docker image is only available for `amd64`. This project bridges that gap
by providing fully functional images for ARM devices – including the **Raspberry Pi 2B on armv7**.

The key technical challenge solved here is the lack of native builds for `pyroscope-io`
and `polars` packages on 32-bit ARM. This project implements **stub packages** with full metadata,
allowing `litellm[proxy]` to install correctly on armv7 without any modifications to LiteLLM's
source code.

> ⚠️ **Disclaimer:** This is an unofficial project, unaffiliated with BerriAI.
> LiteLLM is an open-source project licensed under MIT. All rights to the original code
> belong to their respective authors.

---

## ✨ Key Features

- ✅ **Three-architecture support** – `linux/amd64`, `linux/arm64`, `linux/arm/v7`
- ✅ **Runs on Raspberry Pi 2B, 3, 4, 5** (including 32-bit armv7!)
- ✅ **LiteLLM 1.83.4 with proxy mode** (`litellm[proxy]`)
- ✅ **Multi-stage build** – smaller final image, no build tools included
- ✅ **Dedicated system user** – container runs as `litellm` (UID 1001), not root
- ✅ **Built-in healthcheck** – ready for Docker Swarm and Compose
- ✅ **Automated CI/CD** via GitHub Actions with GHA layer caching
- ✅ **Base: Python 3.11-slim-bookworm** – minimal, secure base image

---

## 🏗️ Supported Architectures

| Architecture | Devices |
|---|---|
| `linux/amd64` | x86_64 servers, PCs, VPS |
| `linux/arm64` | Raspberry Pi 4/5 (64-bit OS), Apple M1/M2 (via Docker), ARM64 servers |
| `linux/arm/v7` | **Raspberry Pi 2B, 3** (32-bit OS, armhf), other armv7 devices |

All architectures are available under the same `latest` tag – Docker automatically pulls
the correct variant for your platform.

---

## 🚀 Quick Start

### Requirements

- Docker Engine >= 20.10
- 512 MB free RAM *(minimum for Pi 2B)*
- A `config.yaml` file with your model configuration

### Basic Usage

```bash
docker run -d \
  --name litellm \
  -p 4000:4000 \
  -v $(pwd)/config.yaml:/app/config.yaml \
  --restart unless-stopped \
  hetstack/litellm-multiarch:latest
```

### Run with an API key (no config file)

```bash
docker run -d \
  --name litellm \
  -p 4000:4000 \
  -e OPENAI_API_KEY="sk-your-openai-key" \
  hetstack/litellm-multiarch:latest \
  --model openai/gpt-4o \
  --port 4000 \
  --host 0.0.0.0
```

---

## ⚙️ Configuration – `config.yaml`

The container loads `/app/config.yaml` by default. Create it locally and mount it as a volume.

### Sample `config.yaml`

```yaml
model_list:
  - model_name: gpt-4o
    litellm_params:
      model: openai/gpt-4o
      api_key: "sk-your-openai-key"

  - model_name: claude-3-sonnet
    litellm_params:
      model: anthropic/claude-3-sonnet-20240229
      api_key: "sk-ant-your-key"

  - model_name: llama3
    litellm_params:
      model: ollama/llama3
      api_base: "http://ollama:11434"

  - model_name: mistral
    litellm_params:
      model: mistral/mistral-tiny
      api_key: "your-mistral-key"

litellm_settings:
  drop_params: true
  set_verbose: false

general_settings:
  master_key: "sk-your-master-key"
  # Recommended for low-RAM devices (e.g. Pi 2B):
  disable_spend_logs: true
```

---

## 🐳 Docker Compose

```yaml
version: "3.9"

services:
  litellm:
    image: hetstack/litellm-multiarch:latest
    container_name: litellm
    ports:
      - "4000:4000"
    volumes:
      - ./config.yaml:/app/config.yaml:ro
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health"]
      interval: 30s
      timeout: 10s
      start_period: 60s
      retries: 3

  # Optional – with PostgreSQL database
  litellm-with-db:
    image: hetstack/litellm-multiarch:latest
    container_name: litellm-db
    ports:
      - "4000:4000"
    volumes:
      - ./config.yaml:/app/config.yaml:ro
    environment:
      - DATABASE_URL=postgresql://litellm:password@db:5432/litellm
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: litellm
      POSTGRES_PASSWORD: password
      POSTGRES_DB: litellm
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U litellm"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

---

## 🐝 Docker Swarm

The image includes a built-in `HEALTHCHECK`, making it fully compatible with Docker Swarm.

### Example Stack (`docker-stack.yml`)

```yaml
version: "3.9"

services:
  litellm:
    image: hetstack/litellm-multiarch:latest
    ports:
      - target: 4000
        published: 4000
        protocol: tcp
        mode: ingress
    volumes:
      - ./config.yaml:/app/config.yaml:ro
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        delay: 15s
        order: start-first
        failure_action: rollback
      restart_policy:
        condition: on-failure
        delay: 10s
        max_attempts: 3
      placement:
        constraints:
          - node.role == worker
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
    networks:
      - litellm_net

networks:
  litellm_net:
    driver: overlay
    attachable: true
```

```bash
# Deploy the stack
docker stack deploy -c docker-stack.yml litellm

# Check status
docker stack ps litellm
docker service logs -f litellm_litellm
```

---

## 🍓 Raspberry Pi Setup

### Raspberry Pi 2B / 3 (armv7 – 32-bit OS)

```bash
# 1. Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# 2. Verify architecture (should return armv7l)
uname -m

# 3. Pull the image (armv7 variant is pulled automatically)
docker pull hetstack/litellm-multiarch:latest

# 4. Run
docker run -d \
  --name litellm \
  -p 4000:4000 \
  -v $(pwd)/config.yaml:/app/config.yaml:ro \
  --restart unless-stopped \
  hetstack/litellm-multiarch:latest
```

> ⚠️ **Note for Pi 2B (1 GB RAM):**
> - Container startup can take **up to 60 seconds** – this is normal behavior on armv7
> - We recommend increasing swap to at least 1 GB (see [Troubleshooting](#-troubleshooting))
> - Use `disable_spend_logs: true` in `config.yaml` to reduce memory usage

### Raspberry Pi Swarm Cluster

```bash
# On the Manager node (recommended: Pi 4 or Pi 5):
docker swarm init --advertise-addr <MANAGER_IP>
# The command will output a join token for workers

# On Worker nodes (Pi 2B, Pi 3, etc.):
docker swarm join --token <SWARM_TOKEN> <MANAGER_IP>:2377

# On the manager – verify nodes:
docker node ls

# Deploy the LiteLLM stack:
docker stack deploy -c docker-stack.yml litellm
```

---

## 📦 Tags & Versioning

| Tag | Description |
|---|---|
| `latest` | Latest stable build from the `main` branch |
| `main` | Alias for `latest` |
| `1.83.4` | Specific LiteLLM version (from a GitHub release) |
| `1.83` | Major.Minor – latest patch for this version |
| `1` | Major – latest minor for this version |

---

## 🔧 Environment Variables

| Variable | Description |
|---|---|
| `OPENAI_API_KEY` | OpenAI API key |
| `ANTHROPIC_API_KEY` | Anthropic API key |
| `AZURE_API_KEY` | Azure OpenAI API key |
| `HUGGINGFACE_API_KEY` | HuggingFace API key |
| `MISTRAL_API_KEY` | Mistral API key |
| `DATABASE_URL` | PostgreSQL connection URL (optional) |
| `LITELLM_LOG` | Log level: `DEBUG`, `INFO`, `WARNING` |
| `LITELLM_MASTER_KEY` | Proxy master API key |

---

## 🔍 Technical Details

### How the image is built

The image uses a **multi-stage build** to keep the final image as small as possible:

**Stage 1 – `builder`:**
- Based on `python:3.11-slim-bookworm`
- Installs Rust toolchain (required to compile cryptographic dependencies)
- Pre-installs base dependencies: `uuid_utils`, `boto3`, `click`, `aiohttp`
- Creates **stub packages** for `pyroscope-io` and `polars-runtime-32` – packages unavailable as native wheels on armv7
- Installs `litellm[proxy]==1.83.4` using `--prefer-binary`

**Stage 2 – `runtime`:**
- Clean `python:3.11-slim-bookworm` base (no Rust, no build tools)
- Copies only the compiled packages from the `builder` stage
- Runs as a dedicated `litellm` user (UID 1001) – **not as root**
- Built-in `HEALTHCHECK` polling the `/health` endpoint every 30 seconds

### Why stub packages?

`pyroscope-io` (a profiler) and `polars` (a DataFrame library) do not ship native wheels
for `linux/arm/v7`. Compiling them from source is either impossible or highly unstable on this
architecture. Since LiteLLM uses these packages as **optional dependencies** (they are not
required for the proxy to function), we replace them with empty Python modules that include
complete package metadata, satisfying pip's dependency resolver without breaking anything.

---

## 🧪 Testing

```bash
# Check container status
docker ps
docker logs litellm

# Health check
curl http://localhost:4000/health

# List available models
curl http://localhost:4000/v1/models \
  -H "Authorization: Bearer sk-your-master-key"

# Test chat completion
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-your-master-key" \
  -d '{
    "model": "gpt-4o",
    "messages": [
      {"role": "user", "content": "Hello! How are you?"}
    ]
  }'
```

---

## 🔄 GitHub Actions – CI/CD

Automated builds are triggered on:
- **Push to `main` branch** → `latest` tag
- **GitHub release published** → semantic tags (`v1.2.3`, `1.2`, `1`)

The pipeline uses:
- `docker/setup-qemu-action` – ARM emulation on x86 runners
- `docker/setup-buildx-action` – multi-arch build support
- `docker/metadata-action` – automatic tag generation
- `docker/build-push-action` – build and push with GHA layer cache

Required repository secrets:

| Secret | Description |
|---|---|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token (not your password!) |

---

## 🐛 Troubleshooting

### Container exits with OOM (Out of Memory)

```bash
# Monitor memory usage
docker stats litellm

# Increase swap on Raspberry Pi
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
free -h
```

### Healthcheck fails on first startup

This is expected on armv7 – LiteLLM takes longer to initialize.
The healthcheck has a `start_period: 60s` grace period, so Docker won't restart
the container within the first minute.

```bash
# Watch logs during startup
docker logs -f litellm
```

### Database / Prisma error

Run without a database by adding to `config.yaml`:

```yaml
general_settings:
  disable_spend_logs: true
  disable_master_key_hash: true
```

### `docker pull` downloads wrong architecture

```bash
# Force a specific platform
docker pull --platform linux/arm/v7 hetstack/litellm-multiarch:latest

# Inspect the pulled image
docker inspect hetstack/litellm-multiarch:latest | grep Architecture
```

---

## 🤝 Contributing

Bug reports and feature requests are welcome!

1. Fork the repository
2. Create your branch: `git checkout -b fix/issue-description`
3. Commit your changes: `git commit -m 'fix: description of fix'`
4. Push the branch: `git push origin fix/issue-description`
5. Open a Pull Request

---

## 📜 License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.

Copyright (c) 2026 **hetstack**

LiteLLM is an open-source project by [BerriAI](https://github.com/BerriAI/litellm), licensed under MIT.
This Docker image is an unofficial community project.

---

<div align="center">

If this project helped you, please leave a ⭐ on GitHub!

**[🐳 Docker Hub](https://hub.docker.com/r/hetstack/litellm-multiarch)** •
**[🐛 Report a Bug](https://github.com/hetstack/litellm-multiarch/issues)** •
**[💬 Discussions](https://github.com/hetstack/litellm-multiarch/discussions)**

</div>

---
---

<a name="polski"></a>

<div align="center">

# 🤖 LiteLLM Multi-Arch Docker

### Nieoficjalny wieloarchitekturowy obraz Docker dla LiteLLM 1.83.4

</div>

---

## 📖 O projekcie

Ten projekt dostarcza **nieoficjalny, wieloarchitekturowy obraz Docker** dla [LiteLLM](https://github.com/BerriAI/litellm)
w wersji **1.83.4** – popularnego proxy i unified API gateway dla dużych modeli językowych (LLM),
takich jak OpenAI, Anthropic, Ollama, Mistral i wielu innych.

Oficjalny obraz LiteLLM dostępny jest wyłącznie dla architektury `amd64`. Ten projekt wypełnia tę lukę,
dostarczając w pełni funkcjonalne obrazy dla urządzeń ARM – w tym **Raspberry Pi 2B z armv7**.

Kluczowe wyzwanie techniczne, które zostało tutaj rozwiązane, to brak natywnych buildów dla
paczek `pyroscope-io` oraz `polars` na architekturze 32-bitowej ARM. Projekt implementuje
**stub packages** z pełnymi metadanymi, co pozwala na poprawną instalację `litellm[proxy]` na armv7
bez modyfikacji kodu źródłowego LiteLLM.

> ⚠️ **Zastrzeżenie:** Jest to projekt nieoficjalny, niezwiązany z firmą BerriAI.
> LiteLLM jest projektem open-source na licencji MIT. Wszelkie prawa do oryginalnego kodu należą do ich autorów.

---

## ✨ Główne cechy

- ✅ **Wsparcie dla 3 architektur** – `linux/amd64`, `linux/arm64`, `linux/arm/v7`
- ✅ **Działa na Raspberry Pi 2B, 3, 4, 5** (w tym armv7 32-bit!)
- ✅ **LiteLLM 1.83.4 z trybem proxy** (`litellm[proxy]`)
- ✅ **Multi-stage build** – mniejszy obraz końcowy, bez narzędzi buildowych
- ✅ **Dedykowany użytkownik systemowy** – kontener działa jako `litellm` (UID 1001), nie jako root
- ✅ **Wbudowany healthcheck** – gotowy do użycia w Docker Swarm i Compose
- ✅ **Automatyczne buildy CI/CD** przez GitHub Actions z cache GHA
- ✅ **Baza: Python 3.11-slim-bookworm** – mała, bezpieczna baza

---

## 🏗️ Obsługiwane architektury

| Architektura | Urządzenia |
|---|---|
| `linux/amd64` | Serwery x86_64, PC, VPS |
| `linux/arm64` | Raspberry Pi 4/5 (64-bit OS), Apple M1/M2 (via Docker), serwery ARM64 |
| `linux/arm/v7` | **Raspberry Pi 2B, 3** (32-bit OS, armhf), inne urządzenia armv7 |

Wszystkie architektury są dostępne pod tym samym tagiem `latest` – Docker automatycznie pobierze
właściwy wariant dla Twojej platformy.

---

## 🚀 Szybki start

### Wymagania

- Docker Engine >= 20.10
- 512 MB RAM wolnej pamięci *(minimum dla Pi 2B)*
- Plik `config.yaml` z konfiguracją modeli

### Podstawowe uruchomienie

```bash
docker run -d \
  --name litellm \
  -p 4000:4000 \
  -v $(pwd)/config.yaml:/app/config.yaml \
  --restart unless-stopped \
  hetstack/litellm-multiarch:latest
```

### Uruchomienie z własnym kluczem API (bez pliku config)

```bash
docker run -d \
  --name litellm \
  -p 4000:4000 \
  -e OPENAI_API_KEY="sk-twoj-klucz-openai" \
  hetstack/litellm-multiarch:latest \
  --model openai/gpt-4o \
  --port 4000 \
  --host 0.0.0.0
```

---

## ⚙️ Konfiguracja – plik `config.yaml`

Kontener domyślnie ładuje plik `/app/config.yaml`. Utwórz go lokalnie i podmontuj jako volume.

### Przykładowy `config.yaml`

```yaml
model_list:
  - model_name: gpt-4o
    litellm_params:
      model: openai/gpt-4o
      api_key: "sk-twoj-klucz-openai"

  - model_name: claude-3-sonnet
    litellm_params:
      model: anthropic/claude-3-sonnet-20240229
      api_key: "sk-ant-twoj-klucz"

  - model_name: llama3
    litellm_params:
      model: ollama/llama3
      api_base: "http://ollama:11434"

  - model_name: mistral
    litellm_params:
      model: mistral/mistral-tiny
      api_key: "twoj-klucz-mistral"

litellm_settings:
  drop_params: true
  set_verbose: false

general_settings:
  master_key: "sk-twoj-master-key"
  # Zalecane dla urządzeń z małą ilością RAM (np. Pi 2B):
  disable_spend_logs: true
```

---

## 🐳 Docker Compose

```yaml
version: "3.9"

services:
  litellm:
    image: hetstack/litellm-multiarch:latest
    container_name: litellm
    ports:
      - "4000:4000"
    volumes:
      - ./config.yaml:/app/config.yaml:ro
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:4000/health"]
      interval: 30s
      timeout: 10s
      start_period: 60s
      retries: 3

  # Opcjonalnie – z bazą danych PostgreSQL
  litellm-with-db:
    image: hetstack/litellm-multiarch:latest
    container_name: litellm-db
    ports:
      - "4000:4000"
    volumes:
      - ./config.yaml:/app/config.yaml:ro
    environment:
      - DATABASE_URL=postgresql://litellm:haslo@db:5432/litellm
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: litellm
      POSTGRES_PASSWORD: haslo
      POSTGRES_DB: litellm
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U litellm"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

---

## 🐝 Docker Swarm

Obraz zawiera wbudowany `HEALTHCHECK`, co czyni go w pełni kompatybilnym z Docker Swarm.

### Przykładowy stack (`docker-stack.yml`)

```yaml
version: "3.9"

services:
  litellm:
    image: hetstack/litellm-multiarch:latest
    ports:
      - target: 4000
        published: 4000
        protocol: tcp
        mode: ingress
    volumes:
      - ./config.yaml:/app/config.yaml:ro
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        delay: 15s
        order: start-first
        failure_action: rollback
      restart_policy:
        condition: on-failure
        delay: 10s
        max_attempts: 3
      placement:
        constraints:
          - node.role == worker
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
    networks:
      - litellm_net

networks:
  litellm_net:
    driver: overlay
    attachable: true
```

```bash
# Wdrożenie stacka
docker stack deploy -c docker-stack.yml litellm

# Sprawdzenie statusu
docker stack ps litellm
docker service logs -f litellm_litellm
```

---

## 🍓 Instalacja na Raspberry Pi

### Raspberry Pi 2B / 3 (armv7 – 32-bit OS)

```bash
# 1. Instalacja Dockera
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# 2. Weryfikacja architektury (powinno zwrócić armv7l)
uname -m

# 3. Pobranie obrazu (automatycznie pobierze wariant armv7)
docker pull hetstack/litellm-multiarch:latest

# 4. Uruchomienie
docker run -d \
  --name litellm \
  -p 4000:4000 \
  -v $(pwd)/config.yaml:/app/config.yaml:ro \
  --restart unless-stopped \
  hetstack/litellm-multiarch:latest
```

> ⚠️ **Uwaga dla Pi 2B (1 GB RAM):**
> - Start kontenera może trwać **do 60 sekund** – jest to normalne zachowanie na armv7
> - Zalecamy zwiększenie swapu do co najmniej 1 GB (patrz sekcja [Rozwiązywanie problemów](#-rozwiązywanie-problemów))
> - Użyj `disable_spend_logs: true` w `config.yaml` aby wyłączyć zapis logów kosztów

### Klaster Swarm na Raspberry Pi

```bash
# Na węźle Manager (zalecane: Pi 4 lub Pi 5):
docker swarm init --advertise-addr <IP_MANAGERA>
# Polecenie zwróci token dla workerów

# Na węzłach Worker (Pi 2B, Pi 3 itd.):
docker swarm join --token <SWARM_TOKEN> <IP_MANAGERA>:2377

# Na managerze – sprawdzenie węzłów:
docker node ls

# Wdrożenie stacka z LiteLLM:
docker stack deploy -c docker-stack.yml litellm
```

---

## 📦 Tagi i wersjonowanie

| Tag | Opis |
|---|---|
| `latest` | Najnowszy stabilny build z gałęzi `main` |
| `main` | Alias dla `latest` (build z gałęzi main) |
| `1.83.4` | Konkretna wersja LiteLLM (z release GitHub) |
| `1.83` | Major.Minor – najnowszy patch dla danej wersji |
| `1` | Major – najnowszy minor dla danej wersji |

---

## 🔧 Zmienne środowiskowe

| Zmienna | Opis |
|---|---|
| `OPENAI_API_KEY` | Klucz API OpenAI |
| `ANTHROPIC_API_KEY` | Klucz API Anthropic |
| `AZURE_API_KEY` | Klucz API Azure OpenAI |
| `HUGGINGFACE_API_KEY` | Klucz API HuggingFace |
| `MISTRAL_API_KEY` | Klucz API Mistral |
| `DATABASE_URL` | URL bazy danych PostgreSQL (opcjonalnie) |
| `LITELLM_LOG` | Poziom logowania: `DEBUG`, `INFO`, `WARNING` |
| `LITELLM_MASTER_KEY` | Główny klucz API proxy |

---

## 🔍 Szczegóły techniczne

### Jak zbudowany jest obraz?

Obraz używa **wieloetapowego buildu** (multi-stage build):

**Etap 1 – `builder`:**
- Bazuje na `python:3.11-slim-bookworm`
- Instaluje Rust (wymagany do kompilacji zależności kryptograficznych)
- Instaluje wstępne zależności: `uuid_utils`, `boto3`, `click`, `aiohttp`
- Tworzy **stub packages** dla `pyroscope-io` i `polars-runtime-32` – paczek niedostępnych natywnie na armv7
- Instaluje `litellm[proxy]==1.83.4` z flagą `--prefer-binary`

**Etap 2 – `runtime`:**
- Czysta baza `python:3.11-slim-bookworm` (bez Rust, bez narzędzi buildowych)
- Kopiuje tylko skompilowane paczki z etapu `builder`
- Uruchamia się jako dedykowany użytkownik `litellm` (UID 1001) – **nie jako root**
- Wbudowany `HEALTHCHECK` sprawdzający endpoint `/health` co 30 sekund

### Dlaczego stub packages?

`pyroscope-io` (profiler) i `polars` (biblioteka DataFrame) nie udostępniają kół (wheels)
dla architektury `linux/arm/v7`. Kompilacja ze źródeł jest niemożliwa lub niestabilna.
Ponieważ LiteLLM używa tych paczek jako **opcjonalnych zależności** (nie są wymagane do działania proxy),
zastępujemy je pustymi modułami z kompletem metadanych, które zaspokajają resolver `pip`.

---

## 🧪 Testowanie działania

```bash
# Sprawdzenie stanu kontenera
docker ps
docker logs litellm

# Health check
curl http://localhost:4000/health

# Lista dostępnych modeli
curl http://localhost:4000/v1/models \
  -H "Authorization: Bearer sk-twoj-master-key"

# Testowe zapytanie do modelu
curl http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-twoj-master-key" \
  -d '{
    "model": "gpt-4o",
    "messages": [
      {"role": "user", "content": "Cześć! Powiedz coś po polsku."}
    ]
  }'
```

---

## 🔄 GitHub Actions – CI/CD

Automatyczne buildy uruchamiają się przy:
- **Push do gałęzi `main`** → tag `latest`
- **Opublikowaniu release'u** → tagi semantyczne (`v1.2.3`, `1.2`, `1`)

Pipeline używa:
- `docker/setup-qemu-action` – emulacja ARM na runners x86
- `docker/setup-buildx-action` – budowanie multi-arch
- `docker/metadata-action` – automatyczne tagowanie
- `docker/build-push-action` – build i push z cache GHA

Sekrety wymagane w ustawieniach repozytorium:

| Sekret | Opis |
|---|---|
| `DOCKERHUB_USERNAME` | Login do Docker Hub |
| `DOCKERHUB_TOKEN` | Token API Docker Hub (nie hasło!) |

---

## 🐛 Rozwiązywanie problemów

### Problem: Kontener się nie startuje – brak pamięci (OOM)

```bash
# Sprawdź użycie pamięci
docker stats litellm

# Zwiększ swap na Raspberry Pi
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
free -h
```

### Problem: Healthcheck failuje przez pierwsze minuty

To normalne na armv7 – start LiteLLM trwa dłużej.
Healthcheck ma ustawiony `start_period: 60s`, więc Docker nie będzie restartował kontenera przez pierwszą minutę.

```bash
# Obserwuj logi podczas startu
docker logs -f litellm
```

### Problem: Błąd związany z bazą danych / Prisma

Uruchom bez bazy danych, dodając do `config.yaml`:

```yaml
general_settings:
  disable_spend_logs: true
  disable_master_key_hash: true
```

### Problem: `docker pull` pobiera zły wariant architektury

```bash
# Wymuś konkretną platformę
docker pull --platform linux/arm/v7 hetstack/litellm-multiarch:latest

# Sprawdź co jest uruchomione
docker inspect hetstack/litellm-multiarch:latest | grep Architecture
```

---

## 🤝 Współpraca

Wszelkie zgłoszenia błędów i propozycje ulepszeń są mile widziane!

1. Sforkuj repozytorium
2. Utwórz branch: `git checkout -b fix/opis-problemu`
3. Zatwierdź zmiany: `git commit -m 'fix: opis naprawy'`
4. Wypchnij: `git push origin fix/opis-problemu`
5. Otwórz Pull Request

---

## 📜 Licencja

Ten projekt jest dostępny na licencji **MIT** – szczegóły w pliku [LICENSE](LICENSE).

Copyright (c) 2026 **hetstack**

LiteLLM jest projektem open-source firmy [BerriAI](https://github.com/BerriAI/litellm), licencjonowanym na MIT.
Ten obraz Docker jest nieoficjalnym projektem społeczności.

---

<div align="center">

Jeśli ten projekt Ci pomógł, zostaw ⭐ na GitHubie!

**[🐳 Docker Hub](https://hub.docker.com/r/hetstack/litellm-multiarch)** •
**[🐛 Zgłoś błąd](https://github.com/hetstack/litellm-multiarch/issues)** •
**[💬 Dyskusje](https://github.com/hetstack/litellm-multiarch/discussions)**

</div>
