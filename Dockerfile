FROM python:3.12-slim

WORKDIR /usr/app

# Install system deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    git gcc g++ unzip wget && \
    rm -rf /var/lib/apt/lists/*

# Install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy dbt profiles
COPY profiles.yml /root/.dbt/profiles.yml

WORKDIR /usr/app/taxi_rides_ny

# Keep the container running (useful for exec-ing into it)
# CMD ["tail", "-f", "/dev/null"]
# redundant since using tty: true in docker-compose.yml, but keeping it here for clarity

