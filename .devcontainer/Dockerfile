FROM mcr.microsoft.com/devcontainers/python:0-3.11

# Install GPG for signature verification scripts
RUN apt-get update && apt-get install -y gnupg --no-install-recommends && rm -rf /var/lib/apt/lists/*

# Install python requirements (best-effort; workspace mounted at /workspaces)
COPY ci/requirements.txt /tmp/ci-requirements.txt
RUN pip install --no-cache-dir -r /tmp/ci-requirements.txt || true
