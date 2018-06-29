FROM alpine:latest  as kafkaBuilder
LABEL authors="joel@spotx.tv"
WORKDIR /root

RUN apk add --no-cache \
        autoconf \
        cmake \
        g++ \
        gcc \
        gmp-dev \
        git \
        libuv-dev \
        make \
        openssl-dev \
        php7-dev \
        php7-pear && \
    pear config-set php_ini /etc/php7/php.ini && \
    pecl config-set php_ini /etc/php7/php.ini

RUN apk add --update --no-cache alpine-sdk bash python

RUN git clone https://github.com/edenhill/librdkafka.git

WORKDIR /root/librdkafka
RUN /root/librdkafka/configure
RUN make && make install

RUN git clone https://github.com/arnaud-lb/php-rdkafka.git
RUN cd php-rdkafka && \
	phpize7 && \
	./configure --enable-kafka --with-php-config=/usr/bin/php-config7 && \
	make all -j 5 && \
	make install && \
	echo "extension=rdkafka.so" > /etc/php7/conf.d/25_rdkafka.ini

#-------------------------------------------------------------------------------
FROM alpine:latest as builder
LABEL authors="rnagtalon@spotx.tv"
WORKDIR /root

RUN apk add --no-cache \
        autoconf \
        cmake \
        g++ \
        gcc \
        gmp-dev \
        git \
        libuv-dev \
        make \
        openssl-dev \
        php7-dev \
        php7-pear && \
    pear config-set php_ini /etc/php7/php.ini && \
    pecl config-set php_ini /etc/php7/php.ini

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
    chmod 755 /usr/lib/php7/modules/cassandra.so
# Sample PECL install cassandra output:
#    Build process completed successfully
#    Installing '/usr/lib/php7/modules/cassandra.so'
#    install ok: channel://pecl.php.net/cassandra-X.Y.Z
#    Extension cassandra enabled in php.ini

#-------------------------------------------------------------------------------
FROM alpine:latest
RUN apk --no-cache add \
        bash \
        gmp \
        libstdc++ \
        libuv \
        memcached \
        openssl \
        php7 \
        php7-fpm \
        php7-mbstring \
        php7-mysqli \
        php7-opcache \
        php7-pdo \
        php7-pdo_mysql \
        php7-posix \
        php7-redis \
        php7-xml \
        nginx supervisor curl \
        redis && \
    echo "extension=cassandra.so" > /etc/php7/conf.d/99_cassandra.ini
# gmp, libstdc++, libuv, openssl: Required by PHP Cassandra driver
# redis: Required for sync-conf replacement.

# Copy kafka build artifacts
COPY --from=kafkaBuilder /usr/local/include/*kafka* /usr/local/include/
COPY --from=kafkaBuilder /usr/lib/php7/modules/rdkafka.so /usr/lib/php7/modules/rdkafka.so
COPY --from=kafkaBuilder /etc/php7/conf.d/25_rdkafka.ini /etc/php7/conf.d/
COPY --from=kafkaBuilder /usr/local/lib/librdkafka* /usr/local/lib/
COPY --from=kafkaBuilder /usr/local/lib/pkgconfig/rdkafka* /usr/local/lib/pkgconfig/

# Copy PECL build artifacts
COPY --from=builder /usr/lib/php7/modules/cassandra.so /usr/lib/php7/modules/cassandra.so

# Copy Cassandra build artifacts
COPY --from=builder /usr/local/include/cassandra.h /usr/local/include/
COPY --from=builder /usr/local/lib/libcassandra.so* /usr/local/lib/
COPY --from=builder /usr/local/lib/pkgconfig/cassandra.pc /usr/local/lib/pkgconfig/


# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php7/php-fpm.d/zzz_custom.conf

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Add application
RUN mkdir -p /var/www/html
WORKDIR /var/www/html

EXPOSE 8080
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]