FROM alpine:3.7  as kafkaBuilder
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
FROM alpine:3.7 as builder
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
FROM alpine:3.7
RUN mkdir /opt && \
    wget https://github.com/knyar/nginx-lua-prometheus/archive/0.1-20170610.zip -O - | unzip -d /opt - && \
    apk --no-cache add \
        bash \
        gmp \
        libstdc++ \
        libuv \
        memcached \
        openssl \
        php7 \
        php7-ctype \
        php7-curl \
        php7-dom \
        php7-fpm \
        php7-intl \
        php7-json \
        php7-mbstring \
        php7-mysqli \
        php7-opcache \
        php7-pdo \
        php7-pdo_mysql \
        php7-posix \
        php7-redis \
        php7-xml \
        php7-xsl \
        nginx \
        nginx-mod-http-lua
# gmp, libstdc++, libuv, openssl: Required by PHP Cassandra driver

RUN apk --no-cache add ca-certificates openssl && \
        wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
        wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-2.28-r0.apk && \
        wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-bin-2.28-r0.apk && \
        wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.28-r0/glibc-i18n-2.28-r0.apk && \
        apk add glibc-2.28-r0.apk glibc-bin-2.28-r0.apk glibc-i18n-2.28-r0.apk
# create smylinks for all the bins in glibc to something already in the $PATH
RUN for n in /usr/glibc-compat/bin/*; do ln -s $n /usr/local/bin/${n##*/}; done
COPY ./etc/locale/locale.md /locale.md
RUN cat locale.md | xargs -i /usr/glibc-compat/bin/localedef -i {} -f UTF-8 {} && \
        # Our Japanese is mislabeled
        /usr/glibc-compat/bin/localedef -i ja_JP -f UTF-8 jp_JP && rm *.apk locale.md

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
