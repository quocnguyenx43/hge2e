FROM python:3.8-slim

WORKDIR /app

# Install Postgres libs + compiler (for psycopg2)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Disable Python output buffering
ENV PYTHONUNBUFFERED=1

# No pycache folder
ENV PYTHONDONTWRITEBYTECODE=1

CMD ["python", "main.py"]
