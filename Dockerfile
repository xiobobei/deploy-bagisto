FROM php:8.1-cli

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl libpng-dev libonig-dev libxml2-dev \
    libzip-dev libicu-dev libfreetype6-dev libjpeg62-turbo-dev \
    zip unzip default-mysql-client

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd intl zip opcache

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /app

# Copy everything
COPY . .

# Install dependencies
RUN composer install --no-dev --optimize-autoloader --ignore-platform-reqs

# Copy .env if not exists
RUN cp .env.example .env 2>/dev/null || true

# Set permissions
RUN chmod -R 777 storage bootstrap/cache

# Make start script executable
RUN chmod +x /app/start.sh

# Expose port
EXPOSE 8080

# Start command
CMD ["/app/start.sh"]
