# ---------------------------------------------------------
# Base Image
# ---------------------------------------------------------
FROM python:3.11-slim

# ---------------------------------------------------------
# Install system deps
# ---------------------------------------------------------
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------
# Install Google Cloud SDK (provides gsutil)
# ---------------------------------------------------------
RUN curl -sSL https://sdk.cloud.google.com | bash
ENV PATH="/root/google-cloud-sdk/bin:${PATH}"

# ---------------------------------------------------------
# Workdir
# ---------------------------------------------------------
WORKDIR /app

# ---------------------------------------------------------
# Copy requirements only, install deps
# ---------------------------------------------------------
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# ---------------------------------------------------------
# Copy backend folder
# ---------------------------------------------------------
COPY backend /app/backend

WORKDIR /app/backend

# ---------------------------------------------------------
# Create entrypoint.sh (download embeddings → run backend)
# ---------------------------------------------------------
RUN echo '#!/bin/bash\n\
set -e\n\
echo "[ENTRYPOINT] Downloading embeddings.sqlite from GCS..."\n\
gsutil cp gs://groceryshopperai-embeddings/embeddings.sqlite /tmp/embeddings.sqlite || echo "[WARN] Could not download embeddings.sqlite"\n\
echo "[ENTRYPOINT] Starting FastAPI..."\n\
exec uvicorn app:app --host 0.0.0.0 --port ${PORT:-8080}\n' \
> /app/backend/entrypoint.sh

RUN chmod +x /app/backend/entrypoint.sh

# ---------------------------------------------------------
# Cloud Run expects container to listen on $PORT
# ---------------------------------------------------------
EXPOSE 8080

# ---------------------------------------------------------
# Use entrypoint.sh instead of direct uvicorn
# ---------------------------------------------------------
ENTRYPOINT ["/app/backend/entrypoint.sh"]
