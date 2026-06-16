#!/bin/bash

# Create .env from .env.example if not exists
if [ ! -f /app/.env ]; then
    cp /app/.env.example /app/.env
    echo "Created .env from .env.example"
fi

# Update .env with Railway environment variables
if [ ! -z "$DB_HOST" ]; then
    sed -i "s/DB_HOST=.*/DB_HOST=$DB_HOST/" /app/.env
fi
if [ ! -z "$DB_PORT" ]; then
    sed -i "s/DB_PORT=.*/DB_PORT=$DB_PORT/" /app/.env
fi
if [ ! -z "$DB_DATABASE" ]; then
    sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_DATABASE/" /app/.env
fi
if [ ! -z "$DB_USERNAME" ]; then
    sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USERNAME/" /app/.env
fi
if [ ! -z "$DB_PASSWORD" ]; then
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" /app/.env
fi

# Generate key
php artisan key:generate --force

# Wait for database to be ready
echo "Waiting for database..."
sleep 15

# Import database
echo "Importing database..."
if [ -f /app/database.sql ] && [ ! -z "$DB_HOST" ]; then
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" < /app/database.sql
    if [ $? -eq 0 ]; then
        echo "Database imported successfully!"
    else
        echo "Database import failed, trying to continue..."
    fi
else
    echo "Skipping database import (no DB_HOST set or no database.sql)"
fi

# Cache config
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Start server
php artisan serve --host=0.0.0.0 --port=8080
