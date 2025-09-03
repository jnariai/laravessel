# Laravessel

Dockerized Laravel starter that scaffolds a new Laravel app and brings up a full dev stack (PHP-FPM, Nginx, Vite) with a single script. Choose your frontend starter (Vue, React, or Livewire) and whether to include Laravel auth.

## Features
- One-step scaffold via `installer.sh` (builds a clean Laravel app using a tiny installer image)
- Starter kit selection: Vue, React, or Livewire (or none)
- Optional auth scaffolding (`--no-authentication` toggle)
- SQLite dev database (mounted to `./database`)
- Nginx reverse proxy + PHP-FPM app container + Vite dev server

## Prerequisites
- Docker and Docker Compose (v2)
- Linux shell (bash)
- Optional: docker-buildx-plugin (to silence Compose Bake warnings)

## Quick start
```bash
chmod +x ./installer.sh
./installer.sh
# Follow prompts:
# - Starter kit (1–4)
# - Include auth (1–2)
# - Project name (defaults to example-app)
```
The script:
- Builds a small installer image
- Runs `laravel new <project>` with your chosen options
- Copies Docker assets from `docker-project` into the new project
- Replaces any `example-app` placeholders with your project name
- Sets `APP_NAME` in `.env`
- Runs `docker compose up -d` inside the project

### One-liner (curl)
Run the installer directly without cloning:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/jnariai/laravessel/main/installer.sh)"
```

Access:
- App: http://localhost
- Vite dev server: http://localhost:5173
- PHP-FPM exposed on 9000 (internal; Nginx proxies HTTP)

## Generated project layout (key files)
```
<project-name>/
  docker-compose.yml
  docker/
    app/
      dockerfile
      entrypoint.sh
    db/
      dockerfile
    nginx/
      nginx.conf
  database/                 # SQLite file lives here (mounted)
  .env                      # APP_NAME updated by installer
  ...
```

## How it works
- `installer.sh` prompts for:
  - Starter kit: sets `--vue`, `--react`, `--livewire-class-components`, or empty
  - Auth: sets `--no-authentication` when “No” is selected
  - Project name: slugified, used everywhere
- The Docker assets come from `docker-project/`:
  - `docker-compose.yml` wires services:
    - app-dev (PHP-FPM + Vite), nginx-dev, db-dev (SQLite utility image)
  - `docker/app/entrypoint.sh`:
    - Ensures writable dirs (storage, bootstrap/cache, database)
    - Installs Composer deps and Node packages, builds assets
    - Generates `.env` and APP_KEY if missing
    - Runs migrations and starts Vite (background) + php-fpm
- SQLite is mounted at `./database` on host and at `/var/lib/sqlite/database.sqlite` in the container.
