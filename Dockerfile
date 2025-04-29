# syntax = docker/dockerfile:1.5
FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim AS builder

# Optymalizacja linkowania i pobierania
ENV UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0

# Ustawienie katalogu roboczego
WORKDIR /app

# Instalacja zależności
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev

# Kopiowanie projektu
COPY . /app

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