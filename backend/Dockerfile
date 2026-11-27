FROM php:8.3-apache-bookworm

# Runtime system dependencies — these stay in the final image:
#   curl                          — container healthcheck + `make ojs-install` download
#   poppler-utils, antiword, catdoc — full-text extraction for OJS search indexing
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    poppler-utils \
    antiword \
    catdoc \
    && rm -rf /var/lib/apt/lists/*

# PHP extensions required by OJS.
# The -dev build libraries (and unzip) are only needed to compile the extensions,
# so they are installed, used, then purged — leaving the runtime image with just
# the shared libraries the compiled extensions actually link against (auto-detected
# via ldd). This mirrors the official php/docker-library build-deps pattern.
RUN set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libfreetype6-dev \
        libicu-dev \
        libjpeg62-turbo-dev \
        libonig-dev \
        libpng-dev \
        libxml2-dev \
        libzip-dev \
        unzip \
    ; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j"$(nproc)" \
        bcmath \
        calendar \
        exif \
        ftp \
        gd \
        intl \
        mbstring \
        mysqli \
        opcache \
        pdo_mysql \
        xml \
        zip \
    ; \
    # reset apt-mark so `apt-get purge --auto-remove` drops the build deps,
    # then re-mark (as manual) the shared libs the extensions link against so
    # they survive the purge.
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
        | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); printf "*%s\n", so }' \
        | sort -u \
        | xargs -r dpkg-query --search \
        | cut -d: -f1 \
        | sort -u \
        | xargs -r apt-mark manual \
    ; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    rm -rf /var/lib/apt/lists/*

# Apache modules
RUN a2enmod rewrite headers deflate expires

# Prepare directories
RUN mkdir -p /var/www/files \
    && chown -R www-data:www-data /var/www/html /var/www/files

COPY apache.conf /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html
EXPOSE 80

CMD ["apache2-foreground"]
