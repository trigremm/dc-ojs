FROM php:8.3-apache-bookworm

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libxml2-dev \
    libzip-dev \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# PHP extensions required by OJS
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    bcmath \
    gd \
    intl \
    mysqli \
    opcache \
    xml \
    zip

# Apache modules
RUN a2enmod rewrite headers

# Prepare directories
RUN mkdir -p /var/www/files \
    && chown -R www-data:www-data /var/www/html /var/www/files

COPY apache.conf /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html
EXPOSE 80

CMD ["apache2-foreground"]
