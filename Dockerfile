FROM php:8.1-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev \
    libzip-dev libicu-dev libfreetype6-dev libjpeg62-turbo-dev \
    zip unzip default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd intl zip opcache

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy everything
COPY . .

# Install dependencies
RUN composer install --no-dev --optimize-autoloader --ignore-platform-reqs

# Copy .env if not exists
RUN cp .env.example .env 2>/dev/null || true

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Apache config for Laravel
COPY docker-apache.conf /etc/apache2/sites-available/000-default.conf

# Expose port
EXPOSE 8080

# Override Apache to listen on 8080
RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf

# Make start script executable
RUN chmod +x /var/www/html/start.sh

# Start command
CMD ["/var/www/html/start.sh"]
