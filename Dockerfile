# ==============================================================================
# MOSAIC HEALTHCARE CLOUD ARCHITECTURE & M&A GOVERNANCE PORTAL
# Multi-Stage Production Container Image
# Stage 1: Build static documentation via MkDocs Material & Python 3.11
# Stage 2: Serve hardened static portal via Nginx Alpine (Non-Root User)
# ==============================================================================

# ------------------------------------------------------------------------------
# STAGE 1: Documentation Site Builder
# ------------------------------------------------------------------------------
FROM python:3.11-slim AS builder

# Set build environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Install build dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy documentation sources and configuration
COPY mkdocs.yml pyproject.toml README.md ./
COPY docs/ ./docs/
COPY terraform/ ./terraform/

# Build static site artifacts
RUN mkdocs build --clean --site-dir /build/site

# ------------------------------------------------------------------------------
# STAGE 2: Hardened Nginx Production Web Server
# ------------------------------------------------------------------------------
FROM nginx:1.27-alpine AS runner

# Create non-root nginx runtime environment
RUN touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid /var/cache/nginx /var/log/nginx /etc/nginx

# Copy custom Nginx configuration with security headers
RUN echo 'server { \
    listen 8000; \
    server_name localhost; \
    root /usr/share/nginx/html; \
    index index.html; \
    \
    # Security Headers \
    add_header X-Frame-Options "SAMEORIGIN" always; \
    add_header X-Content-Type-Options "nosniff" always; \
    add_header X-XSS-Protection "1; mode=block" always; \
    add_header Referrer-Policy "strict-origin-when-cross-origin" always; \
    add_header Content-Security-Policy "default-src \x27self\x27 https: data: \x27unsafe-inline\x27 \x27unsafe-eval\x27;" always; \
    \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    \
    # Health Check Endpoint \
    location /healthz { \
        access_log off; \
        return 200 "healthy\n"; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Copy compiled documentation from builder stage
COPY --from=builder --chown=nginx:nginx /build/site /usr/share/nginx/html

# Run as unprivileged non-root user
USER nginx

# Expose HTTP port 8000
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8000/healthz || exit 1

# Start Nginx server in foreground
CMD ["nginx", "-g", "daemon off;"]
