#!/bin/bash

# Create .env from .env.example if not exists
if [ ! -f /app/.env ]; then
    cp /app/.env.example /app/.env
fi

# Update .env with database variables
sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" /app/.env
sed -i "s/DB_HOST=.*/DB_HOST=$DB_HOST/" /app/.env
sed -i "s/DB_PORT=.*/DB_PORT=$DB_PORT/" /app/.env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_DATABASE/" /app/.env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USERNAME/" /app/.env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" /app/.env
sed -i "s/APP_ENV=.*/APP_ENV=production/" /app/.env
sed -i "s/APP_DEBUG=.*/APP_DEBUG=false/" /app/.env

# Generate key
php artisan key:generate --force

# Wait for database
echo "Waiting for database..."
sleep 15

# Import database with SSL disabled
echo "Importing database..."
if [ -f /app/database.sql ]; then
    mysql --ssl-mode=DISABLED -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" < /app/database.sql 2>&1 || \
    mysql -h "thomas.proxy.rlwy.net" -P "39051" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" < /app/database.sql 2>&1 || \
    echo "Database import failed, continuing anyway..."
else
    echo "No database.sql found, skipping import"
fi

# Cache config
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Start server
php artisan serve --host=0.0.0.0 --port=8080
