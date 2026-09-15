# Install Scheduling Agent

This guide runs the Scheduling Agent skeleton locally in Docker and connects it
to a dedicated Plow assistant line. The current release has no custom scheduling
skills or automations.

## Requirements

- macOS with Docker Desktop running
- Git and Python 3
- a Plow account and a free assistant line

Check Docker before continuing:

```sh
docker info
docker compose version
```

The published Plow base image is currently `linux/amd64`. Compose selects that
platform explicitly; Docker Desktop uses emulation on Apple silicon Macs.

## Download the agent and credential runner

```sh
git clone https://github.com/Tiagohbello/plow-scheduling-agent.git
cd plow-scheduling-agent
git clone --depth 1 https://github.com/plow-pbc/plow-agents.git tools/plow-agents
```

The repository's `bin/plow-agents` wrapper delegates identity setup to the
official runner. The runner checkout is ignored by Git.

## Connect a dedicated Plow line

```sh
./bin/plow-agents login
./bin/plow-agents lines
```

If the account needs another assistant line, run
`./bin/plow-agents login --new-line`. Choose a line marked `free`, then mint the
agent credential:

```sh
./bin/plow-agents mint <line-uid>
```

Replace the placeholder with the real line ID. The command writes
`plow-credentials` in this directory. Never commit or share that file. Do not
reuse a line occupied by another agent.

## Build and start

```sh
docker compose up --build -d
docker compose ps
docker compose logs --tail=100 agent
```

Wait for `plow-init` to report that `scheduling-agent` is configured. Text the
selected assistant line and confirm that the reply identifies Scheduling Agent
as a skeleton without implemented scheduling capabilities.

## Verify the skeleton

```sh
docker compose exec agent grep -c 'You are Scheduling Agent' /var/lib/hermes/SOUL.md
docker compose exec agent test ! -d /opt/hermes/skills/scheduling-lifecycle
docker compose exec agent test ! -d /opt/hermes/skills/calendar-basics
docker compose exec --user hermes agent /opt/hermes/.venv/bin/python3 /opt/plow/agent-index-client.py --self-check
docker compose exec --user hermes -e HOME=/var/lib/hermes -e HERMES_HOME=/var/lib/hermes agent /opt/hermes/.venv/bin/python3 /opt/plow/agent-index-client.py --agent scheduling-agent --dry-run
```

The first command must print `1`. The next two commands succeed silently and
confirm this repository installed no scheduling skills. The Agent Index dry-run
does not register or publish anything.

## Repository owner: register the skeleton

After the validated changes are available on `main`, the repository owner can
publish the community listing once. This command loads the Plow credential
inside the container without putting it in the host command line:

```sh
docker compose exec agent \
  /command/s6-envdir /run/s6/container_environment \
  /command/s6-setuidgid hermes \
  env HOME=/var/lib/hermes HERMES_HOME=/var/lib/hermes \
  /opt/hermes/.venv/bin/python3 /opt/plow/agent-index-client.py \
  --register --agent scheduling-agent \
  --name "Scheduling Agent" \
  --blurb "A minimal Plow Hermes shell for the Scheduling Agent design; scheduling skills are not implemented yet." \
  --runtime Hermes \
  --repo https://github.com/Tiagohbello/plow-scheduling-agent \
  --install-url https://github.com/Tiagohbello/plow-scheduling-agent/blob/main/docs/INSTALL.md
```

Do not repeat registration to troubleshoot reporting and do not delete the
persistent volume. Check the Agent Index page and the supervised service logs.
This release is a community skeleton, not a verified or one-click agent.

## Stop

```sh
docker compose down
```

The named volume retains sessions and Agent Index install identity. Add `-v`
only when you intentionally want to erase that state.
