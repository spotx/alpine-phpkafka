FROM alpine:3.7  as kafkaBuilder
LABEL authors="joel@spotx.tv,jreeves@spotx.tv"
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
FROM alpine:3.7
RUN mkdir /opt && \
    apk --no-cache add \
        bash \
        openssl \
        php7 \
        php7-ctype \
        php7-curl \
        php7-dom \
        php7-intl \
        php7-json \
        php7-mbstring \
        php7-mysqli \
        php7-opcache \
        php7-pdo \
        php7-pdo_mysql \
        php7-posix

# Copy kafka build artifacts
COPY --from=kafkaBuilder /usr/local/include/*kafka* /usr/local/include/
COPY --from=kafkaBuilder /usr/lib/php7/modules/rdkafka.so /usr/lib/php7/modules/rdkafka.so
COPY --from=kafkaBuilder /etc/php7/conf.d/25_rdkafka.ini /etc/php7/conf.d/
COPY --from=kafkaBuilder /usr/local/lib/librdkafka* /usr/local/lib/
COPY --from=kafkaBuilder /usr/local/lib/pkgconfig/rdkafka* /usr/local/lib/pkgconfig/

# Copy conf
COPY etc/ /etc

# Copy executables
COPY bin/* /usr/local/bin/

CMD ["/usr/local/bin/entrypoint.sh"]
