FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 \
    && rm -rf /var/lib/apt/lists/*

COPY fixture.html /opt/browser-tools-fixture/index.html
RUN chmod -R a+rX /opt/browser-tools-fixture
