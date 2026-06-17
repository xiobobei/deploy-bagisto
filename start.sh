#!/bin/bash
set -e

echo "=== Starting Bagisto ==="

# Create .env from .env.example if not exists
if [ ! -f /var/www/html/.env ]; then
    cp /var/www/html/.env.example /var/www/html/.env
    echo "Created .env from .env.example"
fi

# Set MySQL connection from Railway variables
if [ -n "$MYSQLHOST" ]; then
    echo "Setting MySQL connection..."
    sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" /var/www/html/.env
    sed -i "s/DB_HOST=.*/DB_HOST=$MYSQLHOST/" /var/www/html/.env
    sed -i "s/DB_PORT=.*/DB_PORT=${MYSQLPORT:-3306}/" /var/www/html/.env
    sed -i "s/DB_DATABASE=.*/DB_DATABASE=${MYSQLDATABASE:-railway}/" /var/www/html/.env
    sed -i "s/DB_USERNAME=.*/DB_USERNAME=$MYSQLUSER/" /var/www/html/.env
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$MYSQLPASSWORD/" /var/www/html/.env
fi

# Set production environment
sed -i "s/APP_ENV=.*/APP_ENV=production/" /var/www/html/.env
sed -i "s/APP_DEBUG=.*/APP_DEBUG=true/" /var/www/html/.env

# Set APP_URL
if [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
    sed -i "s|APP_URL=.*|APP_URL=https://$RAILWAY_PUBLIC_DOMAIN|" /var/www/html/.env
fi

# Remove ALL cache files first
echo "Clearing all caches..."
rm -rf /var/www/html/bootstrap/cache/*.php
rm -rf /var/www/html/storage/framework/cache/*
rm -rf /var/www/html/storage/framework/sessions/*
rm -rf /var/www/html/storage/framework/views/*

# APP_KEY - use Railway variable or generate if not set
if [ -n "$APP_KEY" ]; then
    echo "Using APP_KEY from Railway variable..."
    sed -i '/^APP_KEY=/d' /var/www/html/.env
    echo "APP_KEY=$APP_KEY" >> /var/www/html/.env
else
    echo "No APP_KEY set! Generating..."
    NEW_KEY=$(php artisan key:generate --show)
    sed -i '/^APP_KEY=/d' /var/www/html/.env
    echo "APP_KEY=$NEW_KEY" >> /var/www/html/.env
fi
echo "APP_KEY configured"

# Import database.sql if it exists and database is empty
echo "Checking for database.sql..."
if [ -f /var/www/html/database.sql ]; then
    TABLE_COUNT=$(mysql -h"$MYSQLHOST" -P"${MYSQLPORT:-3306}" -u"$MYSQLUSER" -p"$MYSQLPASSWORD" "$MYSQLDATABASE" -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$MYSQLDATABASE'" -sN 2>/dev/null || echo "0")
    if [ "$TABLE_COUNT" -eq "0" ]; then
        echo "Importing database.sql..."
        mysql -h"$MYSQLHOST" -P"${MYSQLPORT:-3306}" -u"$MYSQLUSER" -p"$MYSQLPASSWORD" "$MYSQLDATABASE" < /var/www/html/database.sql 2>&1 || echo "Database import failed"
        echo "Database imported"
    else
        echo "Database already has tables, skipping import"
    fi
fi

# Run migrations
echo "Running migrations..."
php artisan migrate --force 2>&1 || echo "Migrations failed"

# Cache config AFTER key is set
echo "Caching config..."
php artisan config:cache 2>&1 || echo "Config cache failed"
php artisan route:cache 2>&1 || echo "Route cache failed"
php artisan view:cache 2>&1 || echo "View cache failed"

# Create required storage directories
echo "Creating storage directories..."
mkdir -p /var/www/html/storage/app/db-blade-compiler/views
mkdir -p /var/www/html/storage/app/public
mkdir -p /var/www/html/storage/framework/cache
mkdir -p /var/www/html/storage/framework/sessions
mkdir -p /var/www/html/storage/framework/views
mkdir -p /var/www/html/storage/logs

# Create storage symlink for public assets
echo "Creating storage symlink..."
php artisan storage:link --force 2>&1 || true

# Publish vendor assets
echo "Publishing assets..."
php artisan vendor:publish --all --force 2>&1 || true

# Set permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true

# Fix MPM conflict - ensure only one MPM is loaded
rm -f /etc/apache2/mods-enabled/mpm_event.*
a2enmod mpm_prefork 2>/dev/null || true

# Update Apache to listen on correct port
PORT=${PORT:-8080}
sed -i "s/Listen 80/Listen $PORT/" /etc/apache2/ports.conf
sed -i "s/<VirtualHost \*:80>/<VirtualHost *:$PORT>/" /etc/apache2/sites-available/000-default.conf

echo "=== Starting Apache on port $PORT ==="
# Start Apache in foreground
exec apache2-foreground
