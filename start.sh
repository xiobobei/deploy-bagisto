#!/bin/bash

# Create .env from .env.example if not exists
if [ ! -f /app/.env ]; then
    cp /app/.env.example /app/.env
fi

# Parse DATABASE_URL if set
if [ ! -z "$DATABASE_URL" ]; then
    # Parse: mysql://user:pass@host:port/database
    DB_USERNAME=$(echo $DATABASE_URL | sed -n 's|.*://\([^:]*\):.*|\1|p')
    DB_PASSWORD=$(echo $DATABASE_URL | sed -n 's|.*://[^:]*:\([^@]*\)@.*|\1|p')
    DB_HOST=$(echo $DATABASE_URL | sed -n 's|.*@\([^:]*\):.*|\1|p')
    DB_PORT=$(echo $DATABASE_URL | sed -n 's|.*:\([0-9]*\)/.*|\1|p')
    DB_DATABASE=$(echo $DATABASE_URL | sed -n 's|.*/\([^?]*\).*|\1|p')
fi

# Update .env
sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" /app/.env
sed -i "s/DB_HOST=.*/DB_HOST=$DB_HOST/" /app/.env
sed -i "s/DB_PORT=.*/DB_PORT=$DB_PORT/" /app/.env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_DATABASE/" /app/.env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USERNAME/" /app/.env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" /app/.env
sed -i "s/APP_ENV=.*/APP_ENV=production/" /app/.env
sed -i "s/APP_DEBUG=.*/APP_DEBUG=false/" /app/.env

echo "DB: $DB_HOST:$DB_PORT/$DB_DATABASE"

# Generate key
php artisan key:generate --force

# Wait for database
echo "Waiting for database..."
sleep 15

# Import database - try without SSL options
echo "Importing database..."
if [ -f /app/database.sql ]; then
    mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" < /app/database.sql 2>&1
    if [ $? -eq 0 ]; then
        echo "Database imported successfully!"
    else
        echo "Database import failed, continuing anyway..."
    fi
fi

# Cache config
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Start server
php artisan serve --host=0.0.0.0 --port=8080
