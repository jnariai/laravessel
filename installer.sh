#!/bin/bash

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
  read -p "Enter your choice (1-2): " auth_choice

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

  cp -r ./docker-project/* "./${project_name}"

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