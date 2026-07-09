WORKDIR /app

COPY . .

RUN composer install \
    --no-dev \
    --prefer-dist \
    --optimize-autoloader \
    --no-interaction

COPY . .
RUN composer dump-autoload --optimize

# ---------- Stage 2: Build frontend assets ----------
FROM node:22 AS node

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# ---------- Stage 3: Production ----------
FROM php:8.4-fpm

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpq-dev \
    libzip-dev \
    zip \
    nginx \
    && docker-php-ext-install pdo pdo_pgsql zip

WORKDIR /var/www/html

COPY --from=composer /app ./
COPY --from=node /app/public/build ./public/build

COPY . .

RUN chown -R www-data:www-data storage bootstrap/cache

EXPOSE 8080

CMD php artisan serve --host=0.0.0.0 --port=8080
