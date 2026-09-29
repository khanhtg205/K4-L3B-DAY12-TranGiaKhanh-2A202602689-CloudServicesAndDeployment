# ═══════════════════════════════════════════════════════════════════
# CP2 — Multi-stage Dockerfile
# ═══════════════════════════════════════════════════════════════════

# Stage 1: Builder
FROM python:3.11-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim AS runtime

WORKDIR /app

# Tạo non-root user
RUN useradd --create-home --uid 10001 appuser

# Copy dependencies từ stage builder
COPY --from=builder /install /usr/local

# Copy source code sau pip install để tận dụng Docker cache
COPY . .

# Cấp quyền cho appuser
RUN chown -R appuser:appuser /app

USER appuser

ENV PORT=8000

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request, os; port = os.getenv('PORT', '8000'); urllib.request.urlopen(f'http://127.0.0.1:{port}/health').read()" || exit 1

CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
