#!/bin/bash

# Create .env from .env.example if not exists
if [ ! -f /app/.env ]; then
    cp /app/.env.example /app/.env
fi

# Create SQLite database
mkdir -p /app/database
touch /app/database/database.sqlite

# Update .env for SQLite
sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=sqlite/" /app/.env
sed -i "s/DB_HOST=.*/DB_HOST=/" /app/.env
sed -i "s/DB_PORT=.*/DB_PORT=/" /app/.env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=\/app\/database\/database.sqlite/" /app/.env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=/" /app/.env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=/" /app/.env
sed -i "s/APP_ENV=.*/APP_ENV=production/" /app/.env
sed -i "s/APP_DEBUG=.*/APP_DEBUG=false/" /app/.env

# Generate key
php artisan key:generate --force

# Run migrations
php artisan migrate --force

# Seed database
php artisan db:seed --force

# Cache config
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Start server
php artisan serve --host=0.0.0.0 --port=8080
