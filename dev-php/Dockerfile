FROM spotx/alpine-phpkafka:7.1.28
LABEL authors="joel@spotx.tv"

RUN apk add --no-cache $PHPIZE_DEPS \
        && pecl install xdebug-2.5.0 \
        && docker-php-ext-enable xdebug \
        && docker-php-ext-install pcntl

RUN apk add --no-cache \
	sudo \
	yarn \
	ffmpeg \
	curl && \
    curl -sSL https://phar.phpunit.de/phpunit-7.phar -o phpunit.phar && \
    chmod +x phpunit.phar && \
    mv phpunit.phar /usr/local/bin/phpunit && \
    apk del curl

# Copy conf
COPY usr/ /usr

ADD .spocker-login-greeting.shinc /var/
ADD .bashrc_php7_dev /var/
