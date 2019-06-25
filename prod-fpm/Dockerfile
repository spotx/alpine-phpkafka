FROM php:7.3.6-alpine3.9  as kafkaBuilder
LABEL authors="joel@spotx.tv"
WORKDIR /root

RUN apk add --no-cache \
        $PHPIZE_DEPS \
        git alpine-sdk bash python

RUN git clone https://github.com/edenhill/librdkafka.git

WORKDIR /root/librdkafka
RUN /root/librdkafka/configure
RUN make && make install

RUN git clone https://github.com/arnaud-lb/php-rdkafka.git
RUN cd php-rdkafka && \
        phpize && \
        ./configure --enable-kafka --with-php-config=/usr/local/bin/php-config && \
        make all -j "$(nproc)" && \
        make install && \
        docker-php-ext-enable rdkafka


#-------------------------------------------------------------------------------
FROM php:7.3.6-alpine3.9 as cassandraBuilder
LABEL authors="joel@spotx.tv"
WORKDIR /root

RUN apk add --no-cache \
        $PHPIZE_DEPS \
        git \
        alpine-sdk \
        cmake\
        libuv-dev \
        openssl-dev gmp-dev

# No PHP cassandra driver module in Alpine. Building from source.
# PHP cassandra driver from pecl is limited to only working on php 7.1.*, not 7.3.
# master branch in github will allow builds on any version of 7.*.*
ARG CASSANDRA_PHP_DRIVER_GIT_TAG="master"
RUN git clone --depth 1 --single-branch \
        --branch ${CASSANDRA_PHP_DRIVER_GIT_TAG} \
        https://github.com/datastax/php-driver.git && \
    cd php-driver && \
    PHP_DRIVER_DIR=$(pwd) && \
    git submodule update --init && \
    mkdir /tmp/build && \
    cd /tmp/build && \
    cmake $PHP_DRIVER_DIR/lib/cpp-driver && \
    make && \
    make install && \
    cd $PHP_DRIVER_DIR/ext && \
    phpize && \
    ./configure && \
    make && \
    make install && \
    cp modules/cassandra.so /usr/local/lib/php/extensions/no-debug-non-zts-20180731/ && \
    docker-php-ext-enable cassandra && \
    cd / && \
    rm -rf /tmp/build && \
    rm -rf $PHP_DRIVER_DIR

#-------------------------------------------------------------------------------
FROM php:7.3.6-alpine3.9 as redisBuilder
LABEL authors="joel@spotx.tv"
WORKDIR /root

RUN apk add --no-cache \
        $PHPIZE_DEPS


RUN pecl install redis-4.3.0 && \
	chmod 0755 /usr/local/lib/php/extensions/no-debug-non-zts-20180731/redis.so && \
        docker-php-ext-enable redis

# Sample PECL install redis output:
#  Build process completed successfully
#  Installing '/usr/local/lib/php/extensions/no-debug-non-zts-20180731/redis.so'
#  install ok: channel://pecl.php.net/redis-4.3.0
#  configuration option "php_ini" is not set to php.ini location
#  You should add "extension=redis.so" to php.ini

#-------------------------------------------------------------------------------

FROM php:7.3.6-fpm-alpine3.9

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
        libstdc++ \
        libuv \
        memcached \
        openssl \
        nginx \
        nginx-mod-http-lua && \
	docker-php-ext-install mysqli && docker-php-ext-enable mysqli && \
	docker-php-ext-install opcache && docker-php-ext-enable opcache && \
	docker-php-ext-install pdo && docker-php-ext-enable pdo && \
	docker-php-ext-install pdo_mysql && docker-php-ext-enable pdo_mysql
# gmp, libstdc++, libuv, openssl: Required by PHP Cassandra driver

# Copy kafka build artifacts
COPY --from=kafkaBuilder /usr/local/include/*kafka* /usr/local/include/
COPY --from=kafkaBuilder /usr/local/lib/php/extensions/no-debug-non-zts-20180731/rdkafka.so /usr/local/lib/php/extensions/no-debug-non-zts-20180731/
COPY --from=kafkaBuilder /usr/local/etc/php/conf.d/docker-php-ext-rdkafka.ini /usr/local/etc/php/conf.d/docker-php-ext-rdkafka.ini
COPY --from=kafkaBuilder /usr/local/lib/librdkafka* /usr/local/lib/
COPY --from=kafkaBuilder /usr/local/lib/pkgconfig/rdkafka* /usr/local/lib/pkgconfig/

# Copy PECL build artifacts
COPY --from=cassandraBuilder /usr/local/lib/php/extensions/no-debug-non-zts-20180731/cassandra.so /usr/local/lib/php/extensions/no-debug-non-zts-20180731/
COPY --from=cassandraBuilder /usr/local/etc/php/conf.d/docker-php-ext-cassandra.ini /usr/local/etc/php/conf.d/docker-php-ext-cassandra.ini

# Copy Cassandra build artifacts
COPY --from=cassandraBuilder /usr/local/include/cassandra.h /usr/local/include/
COPY --from=cassandraBuilder /usr/local/lib/libcassandra.so* /usr/local/lib/
COPY --from=cassandraBuilder /usr/local/lib/pkgconfig/cassandra.pc /usr/local/lib/pkgconfig/

# Copy redis build artifacts
COPY --from=redisBuilder /usr/local/lib/php/extensions/no-debug-non-zts-20180731/redis.so /usr/local/lib/php/extensions/no-debug-non-zts-20180731/
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

EXPOSE 8080 8081
CMD ["/usr/local/bin/entrypoint.sh"]
