# Scheduling Agent

Scheduling Agent is a minimal Plow Hermes agent skeleton. This repository fixes
the agent's identity, packages the runtime, documents installation, and preserves
the design brainstorm that may guide a future scheduling implementation.

## Current status

This repository is **not a functional scheduling agent yet**. It does not ship
custom skills, inspect calendars, place holds, send scheduling proposals, book
meetings, maintain relationship pipelines, run sweeps, or generate morning
briefs. Do not evaluate it as though those capabilities were implemented.

The proposed future behavior is recorded verbatim in
[`docs/SAM_SCHEDULING_AGENT_BRAINSTORM.md`](docs/SAM_SCHEDULING_AGENT_BRAINSTORM.md).
That document is design input, not a description of the current runtime.

## Run the skeleton

Follow [`docs/INSTALL.md`](docs/INSTALL.md) to connect a dedicated Plow line and
start the agent with Docker Compose.

```sh
docker compose up --build -d
docker compose ps
docker compose logs --tail=100 agent
```

When running, the agent can identify itself and explain its current status. Its
specialized scheduling behavior remains intentionally unimplemented.

## Repository layout

- `runtime/persona.md`: Scheduling Agent's minimal identity and capability boundary.
- `docs/SAM_SCHEDULING_AGENT_BRAINSTORM.md`: Sam's future-architecture brainstorm.
- `docs/INSTALL.md`: minimal local installation and verification.
- `image/`, `Dockerfile`, `compose.yml`: Plow Hermes packaging and Agent Index reporting.

There is deliberately no repository-owned `skills/` directory.

## Agent Index

The image includes the pinned official Agent Index reporting client. The
background reporter does not publish an unregistered agent automatically. The
repository owner registers `scheduling-agent` explicitly after validating the
skeleton; subsequent runs report usage under that identity.

## License

MIT — see [LICENSE](LICENSE).
