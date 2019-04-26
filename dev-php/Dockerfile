FROM spotx/alpine-phpkafka:7.1.28-fpm
LABEL authors="joel@spotx.tv"

RUN apk add --no-cache $PHPIZE_DEPS \
        && pecl install xdebug-2.5.0 \
        && docker-php-ext-enable xdebug

RUN apk add --no-cache \
	sudo \
	yarn

# Copy conf
COPY usr/ /usr

ADD .spocker-login-greeting.shinc /var/
ADD .bashrc_php7_dev /var/