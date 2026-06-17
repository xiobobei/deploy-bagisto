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

# Set production environment (debug ON for troubleshooting)
sed -i "s/APP_ENV=.*/APP_ENV=production/" /var/www/html/.env
sed -i "s/APP_DEBUG=.*/APP_DEBUG=true/" /var/www/html/.env

# Set APP_URL
if [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
    sed -i "s|APP_URL=.*|APP_URL=https://$RAILWAY_PUBLIC_DOMAIN|" /var/www/html/.env
fi

# Generate key
echo "Generating APP_KEY..."
php artisan key:generate --force 2>&1 || echo "Key generation failed (might already exist)"

# Run migrations
echo "Running migrations..."
php artisan migrate --force 2>&1 || echo "Migrations failed"

# Cache config
echo "Caching config..."
php artisan config:cache 2>&1 || echo "Config cache failed"
php artisan route:cache 2>&1 || echo "Route cache failed"
php artisan view:cache 2>&1 || echo "View cache failed"

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
