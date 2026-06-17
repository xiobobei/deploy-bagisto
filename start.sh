#!/bin/bash

# Create .env from .env.example if not exists
if [ ! -f /var/www/html/.env ]; then
    cp /var/www/html/.env.example /var/www/html/.env
fi

# Railway MySQL provides individual env vars
# Or parse from DATABASE_URL if available
if [ -n "$MYSQLHOST" ]; then
    # Use Railway MySQL environment variables directly
    sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" /var/www/html/.env
    sed -i "s/DB_HOST=.*/DB_HOST=$MYSQLHOST/" /var/www/html/.env
    sed -i "s/DB_PORT=.*/DB_PORT=${MYSQLPORT:-3306}/" /var/www/html/.env
    sed -i "s/DB_DATABASE=.*/DB_DATABASE=${MYSQLDATABASE:-railway}/" /var/www/html/.env
    sed -i "s/DB_USERNAME=.*/DB_USERNAME=$MYSQLUSER/" /var/www/html/.env
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$MYSQLPASSWORD/" /var/www/html/.env
elif [ -n "$DATABASE_URL" ]; then
    # Parse DATABASE_URL: mysql://user:password@host:port/database
    # Remove protocol
    URL_NO_PROTO="${DATABASE_URL#mysql://}"
    # Extract user:password
    USER_PASS="${URL_NO_PROTO%%@*}"
    # Extract host:port/database
    HOST_PORT_DB="${URL_NO_PROTO#*@}"
    # Extract user
    DB_USER="${USER_PASS%%:*}"
    # Extract password
    DB_PASS="${USER_PASS#*:}"
    # Extract host:port
    HOST_PORT="${HOST_PORT_DB%%/*}"
    # Extract database
    DB_NAME="${HOST_PORT_DB#*/}"
    # Extract host
    DB_HOST="${HOST_PORT%%:*}"
    # Extract port
    DB_PORT="${HOST_PORT#*:}"

    sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" /var/www/html/.env
    sed -i "s/DB_HOST=.*/DB_HOST=$DB_HOST/" /var/www/html/.env
    sed -i "s/DB_PORT=.*/DB_PORT=${DB_PORT:-3306}/" /var/www/html/.env
    sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" /var/www/html/.env
    sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" /var/www/html/.env
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASS/" /var/www/html/.env
fi

# Set production environment
sed -i "s/APP_ENV=.*/APP_ENV=production/" /var/www/html/.env
sed -i "s/APP_DEBUG=.*/APP_DEBUG=false/" /var/www/html/.env

# Set APP_URL from Railway
if [ -n "$RAILWAY_PUBLIC_DOMAIN" ]; then
    sed -i "s|APP_URL=.*|APP_URL=https://$RAILWAY_PUBLIC_DOMAIN|" /var/www/html/.env
fi

# Generate key if not set
php artisan key:generate --force

# Import database.sql on first run (if exists and MySQL is available)
if [ -n "$MYSQLHOST" ] && [ -f /var/www/html/database.sql ] && [ ! -f /var/www/html/storage/.imported ]; then
    echo "Importing database.sql..."
    mysql -h "$MYSQLHOST" -P "${MYSQLPORT:-3306}" -u "$MYSQLUSER" -p"$MYSQLPASSWORD" "$MYSQLDATABASE" < /var/www/html/database.sql
    touch /var/www/html/storage/.imported
    echo "Database imported!"
fi

# Run migrations
php artisan migrate --force

# Seed database (only first time)
if [ ! -f /var/www/html/storage/.seeded ]; then
    php artisan db:seed --force
    touch /var/www/html/storage/.seeded
fi

# Cache config
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Start Apache
apache2-foreground
