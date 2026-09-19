# Minimal Scheduling Agent variant built on the official Plow Hermes image,
# which also ships the supervised Agent Index reporter and its client.
FROM public.ecr.aws/e1h7x4a2/plow-cloud-agents:base-ef0019372ff8bca593611b31ebd2e08f9f1458ff@sha256:a8a2f97ad78b8192d80a984dce81d3bf5a9a883d18cb7b677704913a09b56aee

# plow-init composes the home's SOUL.md from the base persona plus this file on
# every boot. This repository intentionally ships no custom skills.
COPY runtime/persona.md /opt/hermes/plow-seed/persona.md
RUN chmod 0644 /opt/hermes/plow-seed/persona.md
