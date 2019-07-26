FROM spotx/alpine-phpkafka:7.3.7
LABEL authors="joel@spotx.tv"

RUN apk add --no-cache $PHPIZE_DEPS \
        && pecl install xdebug-2.7.2 \
        && docker-php-ext-enable xdebug \
        && docker-php-ext-install pcntl

RUN apk add --no-cache \
	sudo \
	yarn \
	ffmpeg \
	git \
	docker \
	py-pip \
	python-dev libffi-dev openssl-dev gcc libc-dev make \
	curl && \
    curl -sSL https://phar.phpunit.de/phpunit-7.phar -o phpunit.phar && \
    chmod +x phpunit.phar && \
    mv phpunit.phar /usr/local/bin/phpunit && \
    curl -L https://github.com/squizlabs/PHP_CodeSniffer/releases/download/3.1.1/phpcs.phar > /usr/local/bin/phpcs && \
    chmod +x /usr/local/bin/phpcs && \
    pip install docker-compose && \
    apk del curl

# Copy conf
COPY usr/ /usr

ADD .spocker-login-greeting.shinc /var/
ADD .bashrc_php7_dev /var/
