# svc — Simple Service Manager for Linux

A single command to manage **all** your services — whether they run as systemd units or Docker containers. No menus, no GUIs, no 50-page manuals. Just `svc`.

```
$ svc
Services on my-server  14:32

Systemd Services
  NAME                         STATUS
  nginx                        running
  docker                       running
  fail2ban                     running
  my-app-backend               running
  my-app-frontend              running
  my-worker                    running

Docker Containers
  NAME                         STATUS     HEALTH
  postgresql                   running    healthy
  redis                        running    healthy
  elasticsearch                running    healthy
  grafana                      running    healthy
  n8n                          running
  nextcloud                    running

Usage: svc start|stop|restart|logs|status <name>
```

## Why svc?

Managing a Linux server with a mix of systemd services and Docker containers means constantly switching between two different mental models:

```bash
# Without svc — you need to remember which is which
systemctl status nginx
docker ps | grep redis
systemctl restart my-app-backend
docker restart n8n
journalctl -u my-worker -f
docker logs grafana -f
```

```bash
# With svc — one command, auto-detects the type
svc status nginx
svc status redis
svc restart my-app-backend
svc restart n8n
svc logs my-worker
svc logs grafana
```

**svc** auto-detects whether a service is a systemd unit or a Docker container and runs the right command. You never have to think about it.

## Installation

### Quick Install (recommended)

```bash
sudo curl -fsSL https://raw.githubusercontent.com/red777777/svc/main/svc -o /usr/local/bin/svc
sudo chmod +x /usr/local/bin/svc
```

### From Source

```bash
git clone https://github.com/red777777/svc.git
cd svc
sudo ./install.sh
```

### Manual

```bash
git clone https://github.com/red777777/svc.git
sudo cp svc/svc /usr/local/bin/svc
sudo chmod +x /usr/local/bin/svc
```

## Usage

### List all services

```bash
svc
```

Shows a clean dashboard of all your services with color-coded status:
- **Green** = running / healthy
- **Red** = stopped / unhealthy

Systemd services and Docker containers are listed in separate sections. The systemd section only shows **your** application and infrastructure services — not the hundreds of internal system units that `systemctl list-units` dumps on you.

### Start / Stop / Restart a service

```bash
svc start nginx
svc stop my-app-dev
svc restart n8n
```

Works the same regardless of whether the service is systemd or Docker. `svc` figures it out.

### View logs

```bash
svc logs grafana         # Tails Docker logs
svc logs nginx           # Tails journalctl
svc logs my-app-backend  # Tails journalctl
```

Automatically uses `journalctl -f` for systemd services and `docker logs -f` for containers. Shows the last 50 lines and follows new output. Press `Ctrl+C` to exit.

### Detailed status

```bash
svc status nginx
```

For systemd services, shows the full `systemctl status` output including memory, CPU, process tree, and recent log entries.

For Docker containers, shows a compact summary:

```
Name:    /redis
State:   running
Started: 2026-01-15T10:30:00Z
Image:   redis:7-alpine
Ports:   6379/tcp→127.0.0.1:6379
Health:  healthy
```

### Help

```bash
svc help
svc --help
svc -h
```

## Name Resolution

`svc` uses smart name resolution to find services:

1. **Exact systemd match** — `svc status nginx` finds `nginx.service`
2. **Exact Docker match** — `svc status redis` finds the `redis` container
3. **Fuzzy matching** — if no exact match, searches both systemd units and Docker containers for partial matches

If multiple services match a keyword, `svc` lists them and asks you to be more specific:

```bash
$ svc restart my-app
Multiple matches for 'my-app':
  my-app-backend (systemd)
  my-app-frontend (systemd)
  my-app-dev (systemd)
  my-app-postgres (docker)
  my-app-redis (docker)

Be more specific.
```

```bash
$ svc restart my-app-backend
Restarting my-app-backend (systemd)...
Done
```

## Customizing the Dashboard

The `svc` (no arguments) dashboard shows a curated list of systemd services defined in the `known_services` array near the top of the script. Docker containers are auto-discovered — all containers (running and stopped) are always shown.

To add or remove systemd services from the dashboard, edit the array:

```bash
sudo nano /usr/local/bin/svc
```

Find the `known_services` array and modify it:

```bash
local known_services=(
    # Infrastructure
    nginx docker fail2ban auditd tailscaled node-exporter

    # Your apps
    my-app-backend my-app-frontend
    my-new-service          # <-- add your services here
)
```

**Note:** This only affects the dashboard listing. The `start/stop/restart/logs/status` commands work with *any* systemd service or Docker container, whether it's in the list or not.

## Requirements

- **Bash** 4.0+
- **systemctl** (systemd-based Linux)
- **Docker** (optional — Docker sections are skipped if Docker isn't installed)
- **sudo** access (for start/stop/restart actions)

Works on Ubuntu, Debian, CentOS, RHEL, Fedora, Arch, and any systemd-based distribution.

## How It Works

`svc` is a single Bash script (~220 lines) with no dependencies beyond what's already on your server. It wraps:

| svc command | systemd equivalent | Docker equivalent |
|---|---|---|
| `svc` | `systemctl list-units --type=service` | `docker ps -a` |
| `svc start NAME` | `sudo systemctl start NAME` | `sudo docker start NAME` |
| `svc stop NAME` | `sudo systemctl stop NAME` | `sudo docker stop NAME` |
| `svc restart NAME` | `sudo systemctl restart NAME` | `sudo docker restart NAME` |
| `svc logs NAME` | `sudo journalctl -u NAME -f -n 50` | `sudo docker logs NAME -f --tail 50` |
| `svc status NAME` | `systemctl status NAME` | `docker inspect NAME` |

The resolution order is: exact systemd match → exact Docker match → fuzzy systemd search → fuzzy Docker search.

## Examples

```bash
# Morning check — what's running?
svc

# Something seems slow, check the database
svc status postgresql
svc logs postgresql

# Deploy a new version — restart the app
svc restart my-app-backend
svc restart my-app-frontend

# Debug a container issue
svc logs n8n

# Stop a dev service to free resources
svc stop my-app-dev

# Bring it back
svc start my-app-dev
```

## Comparison with Alternatives

| Tool | Scope | Complexity | Docker Support |
|---|---|---|---|
| `systemctl` | systemd only | Low | No |
| `docker` CLI | Docker only | Low | Yes |
| Portainer | Docker + Swarm | High (web UI) | Yes |
| Cockpit | Full system | Medium (web UI) | Partial |
| **svc** | systemd + Docker | **Minimal** | **Yes** |

`svc` is not a replacement for Portainer or Cockpit. It's for people who live in the terminal and want one command instead of two.

## Uninstall

```bash
sudo rm /usr/local/bin/svc
```

That's it. No config files, no databases, no daemons. It's a single script.

## License

MIT License. See [LICENSE](LICENSE).

## Contributing

Contributions are welcome. Keep it simple — the goal is a single file under 300 lines that does the basics well. If it needs a config file, a database, or a daemon, it's too complicated.

```bash
# Fork, clone, edit, test
git clone https://github.com/YOUR_USERNAME/svc.git
cd svc
# Edit svc
# Test on your server
sudo cp svc /usr/local/bin/svc
```

## Credits

Built for managing a production server running 30+ systemd services and 40+ Docker containers. Born out of frustration with switching between `systemctl` and `docker` dozens of times a day.
