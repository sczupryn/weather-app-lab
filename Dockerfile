# syntax = docker/dockerfile:1.7
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder

# Optymalizacja linkowania i pobierania
ENV UV_LINK_MODE=copy \
    UV_USE_SYSTEM_PYTHON=1 

# Instalacja openssh
RUN apt-get update && apt-get install -y git openssh-client && rm -rf /var/lib/apt/lists/*

# Konfiguracja SSH
RUN mkdir -p -m 0700 /root/.ssh && \
    ssh-keyscan github.com >> /root/.ssh/known_hosts

# Ustawienie katalogu roboczego
WORKDIR /app

# Pobranie kodu z Githuba
RUN --mount=type=ssh git clone git@github.com:sczupryn/weather-app-lab.git .

# Instalacja zależności
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-install-project --no-dev

# Synchronizacja projektu
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# Obraz finalny
FROM python:3.13-alpine

# OCI autor
LABEL org.opencontainers.image.authors="Sebastian Czupryn <s99516@pollub.edu.pl>"

WORKDIR /app

# Skopiowanie aplikacji z buildera
COPY --from=builder --chown=app:app /app /app

# Utworzenie użytkownika aplikacyjnego wraz z grupą
RUN addgroup -S app && adduser -S app -G app

# Ustawienie aktywnego użytkownika
USER app

# Dodanie wirtualnego środowiska do PATH
ENV PATH="/app/.venv/bin:$PATH"

# HEALTHCHECK
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:5000/ || exit 1

EXPOSE 5000

CMD ["python3", "app.py"]