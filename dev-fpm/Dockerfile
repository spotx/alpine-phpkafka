FROM spotx/alpine-phpkafka:7.3.10-fpm
LABEL authors="joel@spotx.tv"

RUN apk add --no-cache $PHPIZE_DEPS \
        && pecl install xdebug-2.7.2 \
        && docker-php-ext-enable xdebug

RUN apk add --no-cache \
	sudo \
	yarn \
	curl

RUN curl -sSL https://phar.phpunit.de/phpunit.phar -o phpunit.phar && \
    chmod +x phpunit.phar && \
    mv phpunit.phar /usr/local/bin/phpunit

RUN apk del curl

# Copy conf
COPY usr/ /usr

ADD .spocker-login-greeting.shinc /var/
ADD .bashrc_php7_dev /var/
