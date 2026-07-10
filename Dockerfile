FROM docker/sandbox-templates:shell

USER root

# Install Ares (https://github.com/clout2buy/Ares) from the official .deb release, extracted to /opt/ares
ARG ARES_VERSION=0.28.2
ADD https://github.com/clout2buy/Ares/releases/download/v${ARES_VERSION}/Ares_${ARES_VERSION}_amd64.deb /tmp/ares.deb
RUN dpkg-deb -x /tmp/ares.deb /opt/ares && rm -f /tmp/ares.deb

# Wrapper script so `ares` works as a normal command (ares chat, ares doctor, etc.)
RUN ln -sf /opt/ares/usr/lib/Ares/runtime/bin/node /usr/local/bin/ares-node \
 && printf '#!/bin/bash\nexec /opt/ares/usr/lib/Ares/runtime/bin/node /opt/ares/usr/lib/Ares/runtime/cli/ares-cli.mjs "$@"\n' > /usr/local/bin/ares \
 && chmod +x /usr/local/bin/ares \
 && test -f /opt/ares/usr/lib/Ares/runtime/cli/ares-cli.mjs \
 && test -x /opt/ares/usr/lib/Ares/runtime/bin/node

# Fallback placeholder. Ares reads OLLAMA_API_KEY directly from the environment.
ENV OLLAMA_API_KEY="proxy-managed"

# Auto-launch `ares chat` when an interactive shell starts, then fall back to the
# shell once Ares exits. Guards prevent re-launching in nested/non-interactive shells.
# Set ARES_NO_AUTOSTART=1 to skip auto-launch and get a plain shell.
RUN printf '\n# Auto-launch Ares chat on interactive login\nif [ -z "$ARES_AUTOSTARTED" ] && [ -z "$ARES_NO_AUTOSTART" ] && [ -t 1 ]; then\n  export ARES_AUTOSTARTED=1\n  ares chat\nfi\n' >> /home/agent/.bashrc \
 && printf '\n# Ensure interactive login shells source .bashrc (auto-launch Ares)\nif [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then\n  . "$HOME/.bashrc"\nfi\n' >> /home/agent/.bash_profile \
 && chown agent:agent /home/agent/.bashrc /home/agent/.bash_profile

USER agent