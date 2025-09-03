#!/bin/bash

USE_LOCAL=0
REMOTE_BASE="https://raw.githubusercontent.com/jnariai/laravessel/main/docker-project"

if [ "${1:-}" = "--local" ]; then
  USE_LOCAL=1
  shift
fi

choose_starter_kit() {
  echo "Choose a starter kit:"
  echo "1) Vue"
  echo "2) React"
  echo "3) Livewire"
  echo "4) None"
  read -r -p "Enter your choice (1-4): " choice

  case $choice in
    1) starter_kit="--vue" ;;
    2) starter_kit="--react" ;;
    3) starter_kit="--livewire-class-components" ;;
    4) starter_kit="" ;;
    *) echo "Invalid choice"; exit 1 ;;
  esac
}

choose_auth_option() {
  echo "Include Laravel authentication scaffolding?"
  echo "1) Yes"
  echo "2) No"
  read -r -p "Enter your choice (1-2): " auth_choice

  case $auth_choice in
    1) auth_flag="" ;;
    2) auth_flag="--no-authentication" ;;
    *) echo "Invalid choice"; exit 1 ;;
  esac
}

ask_project_name() {
  read -r -p "Project name (kebab-case) [example-app]: " input_name

  slug="$(echo "${input_name:-example-app}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9-]+/-/g; s/^-+|-+$//g; s/-+/-/g')"
  project_name="${slug:-example-app}"

  if [ -e "./${project_name}" ]; then
    read -r -p "Directory '${project_name}' exists. Overwrite? [y/N]: " overwrite
    case "${overwrite:-N}" in
      [yY]) rm -rf "./${project_name}" ;;
      *) echo "Aborted."; exit 1 ;;
    esac
  fi
}

main() {
  choose_starter_kit
  choose_auth_option
  ask_project_name

  docker build -t laravessel-installer ./docker-installer > /dev/null 2>&1

  docker run --rm -v "$PWD":/app -w /app laravessel-installer \
    laravel new "$project_name" $starter_kit $auth_flag --git --no-interaction > /dev/null 2>&1

  sudo chown -R "$(id -u):$(id -g)" "./${project_name}"

  if [ "$USE_LOCAL" -eq 1 ]; then
    cp -r ./docker-project/* "./${project_name}"
  else
    if ! command -v curl >/dev/null 2>&1; then
      echo "curl is required to fetch remote docker assets. Install curl or run with --local." >&2
      exit 1
    fi

    mkdir -p "./${project_name}/docker/app" "./${project_name}/docker/db" "./${project_name}/docker/nginx"

    if ! curl -fsSI "${REMOTE_BASE}/docker-compose.yml" >/dev/null; then
      echo "Failed to access remote assets at ${REMOTE_BASE}" >&2
      echo "You can override by running: LARAVESSEL_REMOTE_BASE=<url> $0 or use --local" >&2
      exit 1
    fi

    curl -fsSL "${REMOTE_BASE}/docker-compose.yml" -o "./${project_name}/docker-compose.yml"
    curl -fsSL "${REMOTE_BASE}/docker/app/dockerfile" -o "./${project_name}/docker/app/dockerfile"
    curl -fsSL "${REMOTE_BASE}/docker/app/entrypoint.sh" -o "./${project_name}/docker/app/entrypoint.sh"
    curl -fsSL "${REMOTE_BASE}/docker/db/dockerfile" -o "./${project_name}/docker/db/dockerfile"
    curl -fsSL "${REMOTE_BASE}/docker/nginx/nginx.conf" -o "./${project_name}/docker/nginx/nginx.conf"

    chmod +x "./${project_name}/docker/app/entrypoint.sh" || true
  fi

  if grep -Rq "example-app" "./${project_name}"; then
    find "./${project_name}" -maxdepth 2 -type f \( -name "docker-compose.yml" -o -path "./${project_name}/docker/*" \) -print0 \
      | xargs -0 sed -i "s/example-app/${project_name}/g"
  fi

  if [ -f "./${project_name}/.env" ]; then
    sed -i "s/^APP_NAME=.*/APP_NAME=\"${project_name}\"/g" "./${project_name}/.env"
  fi

  cd "./${project_name}" && docker compose up -d
}

main