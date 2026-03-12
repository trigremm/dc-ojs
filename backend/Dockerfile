FROM php:8.3-apache-bookworm

ARG OJS_VERSION=3.5.0-3
ARG OJS_URL=https://pkp.sfu.ca/ojs/download/ojs-${OJS_VERSION}.tar.gz

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

# Download and install OJS
RUN curl -fsSL "${OJS_URL}" -o /tmp/ojs.tar.gz \
    && tar -xzf /tmp/ojs.tar.gz -C /tmp \
    && rm -rf /var/www/html/* \
    && cp -r /tmp/ojs-${OJS_VERSION}/* /var/www/html/ \
    && cp -r /tmp/ojs-${OJS_VERSION}/.[!.]* /var/www/html/ 2>/dev/null || true \
    && rm -rf /tmp/ojs.tar.gz /tmp/ojs-${OJS_VERSION}

# Files directory (outside web root)
RUN mkdir -p /var/www/files \
    && chown -R www-data:www-data /var/www/html /var/www/files \
    && chmod -R 755 /var/www/html \
    && find /var/www/html -type f -exec chmod 644 {} +

# Apache vhost
COPY apache.conf /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html
EXPOSE 80

CMD ["apache2-foreground"]
