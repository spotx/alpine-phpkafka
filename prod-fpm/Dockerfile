# use PECL to install the rdkafka extension
FROM php:7.4.3-alpine3.11 as rdkafkaBuilder
LABEL authors="joel@spotx.tv"
WORKDIR /root

RUN apk add --no-cache \
        librdkafka-dev \
        $PHPIZE_DEPS

RUN pecl install rdkafka-4.0.3 && \
	chmod 0755 /usr/local/lib/php/extensions/no-debug-non-zts-20190902/rdkafka.so && \
        docker-php-ext-enable rdkafka

# Sample PECL install rdkafka output:
#Build process completed successfully
#Installing '/usr/local/lib/php/extensions/no-debug-non-zts-20190902/rdkafka.so'
#install ok: channel://pecl.php.net/rdkafka-4.0.3
#configuration option "php_ini" is not set to php.ini location
#You should add "extension=rdkafka.so" to php.ini

#-------------------------------------------------------------------------------
FROM php:7.4.3-alpine3.11 as redisBuilder
LABEL authors="joel@spotx.tv"
WORKDIR /root

RUN apk add --no-cache \
        $PHPIZE_DEPS


RUN pecl install redis-4.3.0 && \
	chmod 0755 /usr/local/lib/php/extensions/no-debug-non-zts-20190902/redis.so && \
        docker-php-ext-enable redis

# Sample PECL install redis output:
#  Build process completed successfully
#  Installing '/usr/local/lib/php/extensions/no-debug-non-zts-20190902/redis.so'
#  install ok: channel://pecl.php.net/redis-4.3.0
#  configuration option "php_ini" is not set to php.ini location
#  You should add "extension=redis.so" to php.ini

#-------------------------------------------------------------------------------

FROM php:7.4.3-fpm-alpine3.11
# php extension names: https://gist.github.com/chronon/95911d21928cff786e306c23e7d1d3f3

# php-intl
RUN set -xe \
    && apk add --update \
        icu \
    && apk add --no-cache --virtual .php-deps \
        make \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        zlib-dev \
        icu-dev \
        g++ \
    && docker-php-ext-configure intl \
    && docker-php-ext-install \
        intl \
    && docker-php-ext-enable intl \
    && { find /usr/local/lib -type f -print0 | xargs -0r strip --strip-all -p 2>/dev/null || true; } \
    && apk del .build-deps \
    && rm -rf /tmp/* /usr/local/lib/php/doc/* /var/cache/apk/*

# php-xml
RUN set -xe \
    && apk add --no-cache\
        libxml2 libxml2-dev \
    && apk add --no-cache --virtual .php-deps \
        make \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        g++ \
    && docker-php-ext-configure xml \
    && docker-php-ext-install xml \
    && docker-php-ext-enable xml \
    && { find /usr/local/lib -type f -print0 | xargs -0r strip --strip-all -p 2>/dev/null || true; } \
    && apk del .build-deps \
    && rm -rf /tmp/* /usr/local/lib/php/doc/* /var/cache/apk/*

# php-xsl
RUN set -xe \
    && apk add --no-cache\
        libxml2 libxml2-dev libxslt-dev \
    && apk add --no-cache --virtual .php-deps \
        make \
    && apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        g++ \
    && docker-php-ext-configure xsl \
    && docker-php-ext-install xsl \
    && docker-php-ext-enable xsl \
    && { find /usr/local/lib -type f -print0 | xargs -0r strip --strip-all -p 2>/dev/null || true; } \
    && apk del .build-deps \
    && rm -rf /tmp/* /usr/local/lib/php/doc/* /var/cache/apk/*

RUN mkdir -p /opt && \
    wget https://github.com/knyar/nginx-lua-prometheus/archive/0.1-20170610.zip -O - | unzip -d /opt - && \
    apk --no-cache add \
        bash \
        gmp \
        librdkafka-dev \
        libstdc++ \
        libuv \
        memcached \
        openssl \
        nginx \
        nginx-mod-http-lua && \
	docker-php-ext-install mysqli && docker-php-ext-enable mysqli && \
	docker-php-ext-install opcache && docker-php-ext-enable opcache && \
	docker-php-ext-install pdo && docker-php-ext-enable pdo && \
	docker-php-ext-install pdo_mysql && docker-php-ext-enable pdo_mysql && \
	docker-php-ext-install pcntl
# gmp, libstdc++, libuv, openssl: Required by PHP Cassandra driver

# clean up anything unneeded
RUN rm /usr/local/bin/phpdbg && rm -rf /tmp/pear ~/.pearrc

# Copy kafka build artifacts
COPY --from=rdkafkaBuilder /usr/local/lib/php/extensions/no-debug-non-zts-20190902/rdkafka.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902/
COPY --from=rdkafkaBuilder /usr/local/etc/php/conf.d/docker-php-ext-rdkafka.ini /usr/local/etc/php/conf.d/docker-php-ext-rdkafka.ini

# Copy redis build artifacts
COPY --from=redisBuilder /usr/local/lib/php/extensions/no-debug-non-zts-20190902/redis.so /usr/local/lib/php/extensions/no-debug-non-zts-20190902/
COPY --from=redisBuilder /usr/local/etc/php/conf.d/docker-php-ext-redis.ini /usr/local/etc/php/conf.d/docker-php-ext-redis.ini

# Add application
RUN mkdir -p /var/www/html && chown nginx:root /var/www/html && chmod g+w /var/www/html && \
    mkdir -p /var/lib/nginx && chown -R nginx:root /var/lib/nginx && chmod -R g+w /var/lib/nginx && \
    mkdir -p /var/log/nginx && chown nginx:root /var/log/nginx && chmod g+wr /var/log/nginx && \
    mkdir -p /var/tmp/nginx && chown nginx:root /var/tmp/nginx && chmod g+wrx /var/tmp/nginx && \
    rm -f /etc/nginx/conf.d/*.conf && \
    chmod g+w /run && \
    rm -f /usr/local/etc/php-fpm.d/*

# Copy conf
COPY etc/ /etc
COPY usr/ /usr

# Copy executables
COPY bin/* /usr/local/bin/

WORKDIR /var/www/html

EXPOSE 8080 8081 8443
CMD ["/usr/local/bin/entrypoint.sh"]
