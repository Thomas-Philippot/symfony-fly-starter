FROM alpine:3.14

LABEL fly_launch_runtime="Symfony"

RUN apk update

# add useful utilities
RUN apk add curl \
    zip \
    unzip \
    ssmtp \
    tzdata \
    openssl

# php, with assorted extensions we likely need
RUN apk add --no-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --allow-untrusted gnu-libiconv \
    && apk add -U --no-cache \
    # Packages
    tini \
    php7 \
    php7-amqp \
    php7-dev \
    php7-common \
    php7-apcu \
    php7-gd \
    php7-xmlreader \
    php7-bcmath \
    php7-ctype \
    php7-curl \
    php7-exif \
    php7-iconv \
    php7-intl \
    php7-json \
    php7-mbstring \
    php7-opcache \
    php7-openssl \
    php7-pcntl \
    php7-pdo \
    php7-mysqlnd \
    php7-pdo_mysql \
    php7-pdo_pgsql \
    php7-phar \
    php7-posix \
    php7-session \
    php7-xml \
    php7-xsl \
    php7-zip \
    php7-zlib \
    php7-dom \
    php7-redis \
    php7-fpm \
    php7-sodium \
    php7-tokenizer

# supervisor, to support running multiple processes in a single app
RUN apk add supervisor

# nginx (https://wiki.alpinelinux.org/wiki/Nginx)
RUN apk add nginx
# ... with custom conf
RUN cp /etc/nginx/nginx.conf /etc/nginx/nginx.old.conf && rm -rf /etc/nginx/http.d/default.conf

# htop, which is useful if need to SSH in to the vm
RUN apk add htop

# composer, to install Laravel's dependencies
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# add users (see https://www.getpagespeed.com/server-setup/nginx-and-php-fpm-what-my-permissions-should-be)
# 1. a user for the app and php-fpm to interact with it (execute)
RUN adduser -D -u 1000 -g 'app' app
# 2. a user for nginx is not needed because already have one
# ... and add the nginx user TO the app group else it won't have permission to access web files (as can see in /var/log/nginx/error.log)
RUN addgroup nginx app

# use a socket not port for php-fpm so php-fpm needs permission to write to thay folder (make sure the same .sock is in nginx.conf and in php-fpm's app.conf)
RUN mkdir /var/run/php && chown -R app:app /var/run/php

# working directory
RUN mkdir /var/www/html
WORKDIR /var/www/html

# copy app code across, skipping files based on .dockerignore
COPY . /var/www/html
# ... install Laravel dependencies
RUN composer install
# ... and make all files owned by app, including the just added /vendor
RUN chown -R app:app /var/www/html

# move the docker-related conf files out of the app folder to where on the vm they need to be
RUN rm -rf /etc/php7/php-fpm.conf
RUN rm -rf /etc/php7/php-fpm.d/www.conf
RUN mv docker/supervisor.conf /etc/supervisord.conf
RUN mv docker/nginx.conf /etc/nginx/nginx.conf
RUN mv docker/php.ini /etc/php7/conf.d/php.ini
RUN mv docker/php-fpm.conf /etc/php7/php-fpm.conf
RUN mv docker/app.conf /etc/php7/php-fpm.d/app.conf

# make sure can execute php files (since php-fpm runs as app, it needs permission e.g for /storage/framework/views for caching views)
RUN chmod -R 755 /var/www/html

# the same port nginx.conf is set to listen on and fly.toml references (standard is 8080)
EXPOSE 8080

# off we go (since no docker-compose, keep both nginx and php-fpm running in the same container by using supervisor) ...
ENTRYPOINT ["supervisord", "-c", "/etc/supervisord.conf"]