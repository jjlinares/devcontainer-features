FROM mcr.microsoft.com/devcontainers/base:ubuntu

RUN mkdir -p /opt/chrome-for-testing/151.0.7922.76/chrome-linux64 \
    && printf '%s\n' '#!/bin/sh' 'printf "%s\\n" "Google Chrome for Testing 151.0.7922.76"' \
        > /opt/chrome-for-testing/151.0.7922.76/chrome-linux64/chrome \
    && chmod 0755 /opt/chrome-for-testing/151.0.7922.76/chrome-linux64/chrome \
    && cp /bin/true /opt/chrome-for-testing/151.0.7922.76/chrome-linux64/chrome_sandbox \
    && printf '%s\n' 'ca-certificates' \
        > /opt/chrome-for-testing/151.0.7922.76/chrome-linux64/deb.deps \
    && printf '%s\n' '151.0.7922.76' \
        > /opt/chrome-for-testing/151.0.7922.76/.version \
    && touch /opt/chrome-for-testing/151.0.7922.76/TAMPERED
