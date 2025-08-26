#!/bin/sh
set -e

mkdir -p storage/framework/views \
	storage/framework/cache \
	storage/framework/sessions \
	storage/logs \
	bootstrap/cache

chown -R www-data:www-data storage bootstrap/cache
chmod -R 775 storage bootstrap/cache
mkdir -p database
touch database/database.sqlite
chown -R www-data:www-data database
chmod -R 775 database

composer install --no-interaction --prefer-dist --optimize-autoloader

npm install && npm run build

[ -f .env ] || (cp .env.example .env && php artisan key:generate)

php artisan migrate --force || true
php artisan optimize:clear

if [ -f package.json ]; then
	(npm run dev -- --host 0.0.0.0 || echo "[entrypoint] Vite dev server failed to start" >&2) &
fi

exec php-fpm