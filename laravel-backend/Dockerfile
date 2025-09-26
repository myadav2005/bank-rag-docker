FROM php:8.2-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpq-dev \
    unzip \
    libzip-dev \
    && docker-php-ext-install pdo pdo_pgsql zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Create fresh Laravel project directly in working directory
RUN composer create-project laravel/laravel . --prefer-dist --no-interaction

# Verify Laravel structure was created correctly
RUN ls -la . && ls -la public/ || echo "Public directory missing - creating it"

# Create public directory and index.php if missing
RUN if [ ! -d "public" ]; then \
        mkdir -p public && \
        echo '<?php' > public/index.php && \
        echo 'define("LARAVEL_START", microtime(true));' >> public/index.php && \
        echo 'if (file_exists($maintenance = __DIR__."/../storage/framework/maintenance.php")) {' >> public/index.php && \
        echo '    require $maintenance;' >> public/index.php && \
        echo '}' >> public/index.php && \
        echo 'require_once __DIR__."/../vendor/autoload.php";' >> public/index.php && \
        echo '$app = require_once __DIR__."/../bootstrap/app.php";' >> public/index.php && \
        echo '$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);' >> public/index.php && \
        echo '$response = $kernel->handle(' >> public/index.php && \
        echo '    $request = Illuminate\Http\Request::capture()' >> public/index.php && \
        echo ');' >> public/index.php && \
        echo '$response->send();' >> public/index.php && \
        echo '$kernel->terminate($request, $response);' >> public/index.php; \
    fi

# Copy custom files (overwriting defaults)
COPY app/ ./app/
COPY routes/ ./routes/
COPY .env ./.env

# Copy bootstrap app.php (preserve Laravel's bootstrap structure)  
COPY bootstrap/app.php ./bootstrap/app.php

# Ensure all required directories exist with proper permissions
RUN mkdir -p bootstrap/cache \
    && mkdir -p storage/framework/cache/data \
    && mkdir -p storage/framework/sessions \
    && mkdir -p storage/framework/views \
    && mkdir -p storage/logs \
    && chmod -R 775 storage bootstrap/cache public \
    && chown -R www-data:www-data . \
    && php artisan key:generate --force

EXPOSE 8000

CMD ["php", "artisan", "serve", "--host=0.0.0.0", "--port=8000"]
