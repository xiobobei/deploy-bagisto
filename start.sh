#!/bin/bash

# Wait for database to be ready
echo "Waiting for database..."
sleep 10

# Import database
echo "Importing database..."
if [ -f /app/database.sql ]; then
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" < /app/database.sql
    if [ $? -eq 0 ]; then
        echo "Database imported successfully!"
    else
        echo "Database import failed, trying to continue..."
    fi
fi

# Generate key if not set
if [ -z "$APP_KEY" ]; then
    php artisan key:generate --force
fi

# Cache config
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Start server
php artisan serve --host=0.0.0.0 --port=8080
