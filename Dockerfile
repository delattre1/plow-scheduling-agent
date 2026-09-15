# Minimal Scheduling Agent variant built on the official Plow Hermes image.
FROM public.ecr.aws/e1h7x4a2/plow-cloud-agents:base-4747960eaa8a44ac24424bf0cc6c22559af61f43@sha256:fe9b0f428f9ed2da1698ecf0b504c79eceb9e016e770291ff6b3418b9f65449d

# plow-init composes the home's SOUL.md from the base persona plus this file on
# every boot. This repository intentionally ships no custom skills.
COPY runtime/persona.md /opt/hermes/plow-seed/persona.md
RUN chmod 0644 /opt/hermes/plow-seed/persona.md

# Fetch only the reviewed immutable Agent Index client revision and verify it.
COPY vendor/client.pin /opt/plow/agent-index-client.pin
RUN set -eu; \
    sha="$(sed -n 's/^sha=//p' /opt/plow/agent-index-client.pin)"; \
    want="$(sed -n 's/^sha256=//p' /opt/plow/agent-index-client.pin)"; \
    path="$(sed -n 's/^path=//p' /opt/plow/agent-index-client.pin)"; \
    curl -fsS --max-time 60 -o /opt/plow/agent-index-client.py \
      "https://raw.githubusercontent.com/plow-pbc/agent-index-client/$sha/$path"; \
    got="$(sha256sum /opt/plow/agent-index-client.py | cut -d' ' -f1)"; \
    [ "$got" = "$want" ] || { echo "agent-index client is $got, pin says $want" >&2; exit 1; }; \
    chmod 0644 /opt/plow/agent-index-client.py

# Reporting starts only after plow-init. An unregistered install stands down;
# registration with public metadata is an explicit repository-owner action.
COPY image/s6-overlay/ /etc/s6-overlay/
RUN chmod 0755 /etc/s6-overlay/s6-rc.d/agent-index/run
