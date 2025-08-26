#!/bin/bash

docker build -t laravessel-installer ./docker-installer > /dev/null 2>&1

docker run --rm -v "$PWD":/app -w /app laravessel-installer \
  laravel new example-app --vue --no-authentication --no-interaction > /dev/null 2>&1

sudo chown -R "$(id -u):$(id -g)" ./example-app

cp -r ./docker-project/* ./example-app

cd ./example-app && docker compose up -d