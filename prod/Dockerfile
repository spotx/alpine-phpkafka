FROM php:7.1.17-alpine  as kafkaBuilder
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
FROM php:7.1.17-alpine as cassandraBuilder
LABEL authors="joel@spotx.tv"
WORKDIR /root

RUN apk add --no-cache \
        $PHPIZE_DEPS \
        git \
        alpine-sdk \
        cmake\
        libuv-dev \
        openssl-dev gmp-dev

# No cassandra-cpp-driver in Alpine. Building from source.
ARG CASSANDRA_CPP_DRIVER_GIT_TAG="2.9.0"
RUN git clone --depth 1 --single-branch \
        --branch ${CASSANDRA_CPP_DRIVER_GIT_TAG} \
        https://github.com/datastax/cpp-driver.git && \
    mkdir cpp-driver/build && \
    cd cpp-driver/build && \
    cmake .. && \
    make && \
    make install && \
    cd ../.. && \
    rm -rf cpp-driver
# SAMPLE OUTPUT FILES:
#    -- Installing: /usr/local/include/cassandra.h
#    -- Installing: /usr/local/lib/libcassandra.so.X.Y.Z
#    -- Installing: /usr/local/lib/libcassandra.so.X
#    -- Installing: /usr/local/lib/libcassandra.so
#    -- Installing: /usr/local/lib/pkgconfig/cassandra.pc

# No PHP cassandra driver module in Alpine. Building from source, then make
# executable (not required, but makes it consistent with other .so files).
RUN pecl install cassandra && \
    chmod 755 /usr/local/lib/php/extensions/no-debug-non-zts-20160303/cassandra.so
# Sample PECL install cassandra output:
#    Build process completed successfully
#    Installing '/usr/lib/php7/modules/cassandra.so'
#    install ok: channel://pecl.php.net/cassandra-X.Y.Z
#    Extension cassandra enabled in php.ini

#-------------------------------------------------------------------------------
FROM php:7.1.17-alpine as redisBuilder
LABEL authors="joel@spotx.tv"
WORKDIR /root

RUN apk add --no-cache \
        $PHPIZE_DEPS


RUN pecl install redis-4.3.0 && \
	chmod 0755 /usr/local/lib/php/extensions/no-debug-non-zts-20160303/redis.so && \
        docker-php-ext-enable redis

# Sample PECL install redis output:
#  Build process completed successfully
#  Installing '/usr/local/lib/php/extensions/no-debug-non-zts-20160303/redis.so'
#  install ok: channel://pecl.php.net/redis-4.3.0
#  configuration option "php_ini" is not set to php.ini location
#  You should add "extension=redis.so" to php.ini

#-------------------------------------------------------------------------------

FROM php:7.1.17-fpm-alpine
RUN mkdir /opt && \
    wget https://github.com/knyar/nginx-lua-prometheus/archive/0.1-20170610.zip -O - | unzip -d /opt - && \
    apk --no-cache add \
        bash \
        gmp \
        libstdc++ \
        libuv \
        memcached \
        openssl \
        php7-intl \
        php7-mysqli \
        php7-opcache \
        php7-pdo \
        php7-pdo_mysql \
        php7-xml \
        php7-xsl \
        nginx \
        nginx-mod-http-lua
# gmp, libstdc++, libuv, openssl: Required by PHP Cassandra driver

# Copy kafka build artifacts
COPY --from=kafkaBuilder /usr/local/include/*kafka* /usr/local/include/
COPY --from=kafkaBuilder /usr/local/lib/php/extensions/no-debug-non-zts-20160303/rdkafka.so /usr/local/lib/php/extensions/no-debug-non-zts-20160303/rdkafka.so
COPY --from=kafkaBuilder /usr/local/etc/php/conf.d/docker-php-ext-rdkafka.ini /etc/php7/conf.d/25_rdkafka.ini
COPY --from=kafkaBuilder /usr/local/lib/librdkafka* /usr/local/lib/
COPY --from=kafkaBuilder /usr/local/lib/pkgconfig/rdkafka* /usr/local/lib/pkgconfig/

# Copy PECL build artifacts
COPY --from=cassandraBuilder /usr/local/lib/php/extensions/no-debug-non-zts-20160303/cassandra.so /usr/lib/php7/modules/cassandra.so

# Copy Cassandra build artifacts
COPY --from=cassandraBuilder /usr/local/include/cassandra.h /usr/local/include/
COPY --from=cassandraBuilder /usr/local/lib/libcassandra.so* /usr/local/lib/
COPY --from=cassandraBuilder /usr/local/lib/pkgconfig/cassandra.pc /usr/local/lib/pkgconfig/

# Copy redis build artifacts
COPY --from=redisBuilder /usr/local/lib/php/extensions/no-debug-non-zts-20160303/redis.so /usr/lib/php7/modules/redis.so
COPY --from=redisBuilder /usr/local/etc/php/conf.d/docker-php-ext-redis.ini /etc/php7/conf.d/25_redis.ini

# Add application
RUN mkdir -p /var/www/html && chown nginx:root /var/www/html && chmod g+w /var/www/html && \
    mkdir -p /var/lib/nginx && chown -R nginx:root /var/lib/nginx && chmod -R g+w /var/lib/nginx && \
    mkdir -p /var/log/nginx && chown nginx:root /var/log/nginx && chmod g+wr /var/log/nginx && \
    mkdir -p /var/tmp/nginx && chown nginx:root /var/tmp/nginx && chmod g+wrx /var/tmp/nginx && \
    rm -f /etc/nginx/conf.d/*.conf && \
    chmod g+w /run

# Copy conf
COPY etc/ /etc

# Copy executables
COPY bin/* /usr/local/bin/

WORKDIR /var/www/html

EXPOSE 8080 8081
CMD ["/usr/local/bin/entrypoint.sh"]
