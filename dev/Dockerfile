FROM spotx/alpine-phpkafka
LABEL authors="joel@spotx.tv"

ENV PHPIZE_DEPS \
		autoconf \
		dpkg-dev dpkg \
		file \
		g++ \
		gcc \
		libc-dev \
		make \
		pkgconf \
		re2c

RUN apk add --no-cache \
	$PHPIZE_DEPS \
        php7-dev \
        php7-pear && \
    pear config-set php_ini /etc/php7/php.ini && \
    pecl config-set php_ini /etc/php7/php.ini && \
    pecl install xdebug-2.5.0

RUN apk add --no-cache \
	sudo \
	yarn

ADD .spocker-login-greeting.shinc /var/
ADD .bashrc_php_dev /var/
ADD add-container-etc-hosts-entry /usr/local/bin/

